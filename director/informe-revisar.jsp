<%-- El director revisa el informe final en la fase 5 (Informe II), por POST multipart
     (RF14, RF18, RF31, RF34; Anexo H: "el director envía el informe al evaluador y al
     comité"). Siempre sobre la última versión del FDC-125 y con observación obligatoria:
       devolver  la versión queda "Devuelto" y el proyecto vuelve a la fase 4, donde el
                 estudiante sube una versión corregida y la envía otra vez.
       aprobar   el director da su aval (la firma, RF31), sube el reporte de Turnitin (PDF)
                 y lo envía al evaluador y al comité; sigue en la fase 5. El evaluador
                 tiene 5 días hábiles para evaluarlo con la rejilla del F-DC-129 (RF21).
     Si el comité se lo devuelve porque le falta algo, lo revisa otra vez. Solo el
     director del proyecto (no los codirectores) toma esta decisión. --%>
<%@ include file="/WEB-INF/jspf/solo-director.jspf" %>
<%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/director/proyectos.jsp" />
</c:if>

<%-- En multipart, los campos de texto también llegan como param --%>
<sql:query var="consulta">
    SELECT p.id, p.estado, p.titulo, p.evaluador_id, f.orden AS fase, f.id AS fase_id,
           e.id AS entrega_id, e.version, ${sqlUltimaRevisionInforme} AS ultima
    FROM proyectos p
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN entregas e ON e.proyecto_id = p.id AND e.tipo = 'FDC-125'
         AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = 'FDC-125')
    WHERE p.id = ? AND p.director_id = ?
    <sql:param value="${empty param.id ? 0 : param.id}" />
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/director/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="observacion" value="${fn:trim(param.observacion)}" />
<c:set var="aprobar" value="${param.decision == 'aprobar'}" />

<c:if test="${aprobar}">
    <c:catch var="errorArchivo">
        <c:set var="parte" value="${pageContext.request.getPart('turnitin')}" />
    </c:catch>
    <c:set var="nombreOriginal" value="${empty parte ? '' : fn:trim(parte.submittedFileName)}" />
</c:if>

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.fase != 5 or empty p.entrega_id or not (empty p.ultima or p.ultima == 'Comité:Devuelto')}"><c:set var="motivo" value="informe-no-revisable" /></c:when>
    <c:when test="${param.decision != 'aprobar' and param.decision != 'devolver'}"><c:set var="motivo" value="general" /></c:when>
    <c:when test="${empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
    <c:when test="${aprobar and empty p.evaluador_id}"><c:set var="motivo" value="sin-evaluador" /></c:when>
    <c:when test="${aprobar and not empty errorArchivo}"><c:set var="motivo" value="archivo-grande" /></c:when>
    <c:when test="${aprobar and (empty parte or parte.size == 0 or empty nombreOriginal)}"><c:set var="motivo" value="turnitin-requerido" /></c:when>
    <c:when test="${aprobar and parte.size > 15728640}"><c:set var="motivo" value="archivo-grande" /></c:when>
    <c:when test="${aprobar and not fn:endsWith(fn:toLowerCase(nombreOriginal), '.pdf')}"><c:set var="motivo" value="archivo-invalido" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/director/proyecto.jsp">
        <c:param name="id" value="${p.id}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<c:choose>
    <c:when test="${aprobar}"><c:set var="textoHistorial">El director aprobó la versión ${p.version} del FDC-125 (informe final), subió el reporte de Turnitin y la envió al evaluador y al comité.</c:set></c:when>
    <c:otherwise><c:set var="textoHistorial">El director devolvió la versión ${p.version} del FDC-125 (informe final) con observaciones. El proyecto volvió a la fase 4 (Informe I).</c:set></c:otherwise>
</c:choose>
<c:if test="${aprobar}">
    <c:set var="nombreGuardado" value="turnitin-informe-p${p.id}-v${p.version}-${System.currentTimeMillis()}.pdf" />
    <c:set var="carpeta" value="${pageContext.servletContext.getRealPath('/WEB-INF/archivos')}" />
    <c:set var="diasHabiles" value="5" />
    <%@ include file="/WEB-INF/jspf/plazo-habil.jspf" %>
</c:if>

<c:catch var="errorGuardar">
    <c:if test="${aprobar}">
        <c:set var="rutaGuardada">${carpeta}/${nombreGuardado}</c:set>
        <c:set var="escrito" value="${parte.write(rutaGuardada)}" />
    </c:if>
    <sql:transaction>
        <sql:update>
            INSERT INTO revisiones (entrega_id, revisor_id, rol, estado, decision, observacion)
            VALUES (?, ?, 'Director', 'Enviada', ?, ?)
            <sql:param value="${p.entrega_id}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="${aprobar ? 'Aprobado' : 'Devuelto'}" />
            <sql:param value="${observacion}" />
        </sql:update>
        <c:choose>
            <c:when test="${aprobar}">
                <sql:update>
                    INSERT INTO entregas (proyecto_id, fase_id, tipo, nombre_archivo, ruta_archivo, subido_por)
                    VALUES (?, ?, 'Reporte Turnitin', ?, ?, ?)
                    <sql:param value="${p.id}" />
                    <sql:param value="${p.fase_id}" />
                    <sql:param value="${fn:substring(nombreOriginal, 0, 255)}" />
                    <sql:param value="${nombreGuardado}" />
                    <sql:param value="${sessionScope.usuario.id}" />
                </sql:update>
                <sql:update>
                    UPDATE entregas SET fecha_limite_revision = ? WHERE id = ?
                    <sql:dateParam value="${fechaPlazo}" type="date" />
                    <sql:param value="${p.entrega_id}" />
                </sql:update>
            </c:when>
            <c:otherwise>
                <sql:update>
                    UPDATE proyectos SET fase_id = (SELECT id FROM fases WHERE orden = 4) WHERE id = ?
                    <sql:param value="${p.id}" />
                </sql:update>
            </c:otherwise>
        </c:choose>
        <sql:update>
            INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, ?, ?)
            <sql:param value="${p.id}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="${aprobar ? 'Documento' : 'Fase'}" />
            <sql:param value="${textoHistorial}" />
        </sql:update>
        <c:set var="avisoProyecto" value="${p.id}" />
        <c:choose>
            <c:when test="${aprobar}">
                <c:set var="avisoMensaje">El director aprobó la versión ${p.version} del informe final y la envió al evaluador y al comité. Observación: ${observacion}</c:set>
                <c:set var="avisoPara" value="estudiantes,codirectores,comite" />
                <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
                <c:set var="avisoMensaje">Te enviaron el informe final de «${p.titulo}» para evaluarlo con la rejilla del F-DC-129. Tienes hasta el <fmt:formatDate value="${fechaPlazo}" pattern="dd/MM/yyyy" /> (5 días hábiles).</c:set>
                <c:set var="avisoPara" value="evaluador" />
                <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
            </c:when>
            <c:otherwise>
                <c:set var="avisoMensaje">El director devolvió la versión ${p.version} del informe final: revisa sus observaciones y sube una versión corregida. Observación: ${observacion}</c:set>
                <c:set var="avisoPara" value="estudiantes,codirectores" />
                <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
            </c:otherwise>
        </c:choose>
    </sql:transaction>
</c:catch>

<c:redirect url="/director/proyecto.jsp">
    <c:param name="id" value="${p.id}" />
    <c:param name="${empty errorGuardar ? 'ok' : 'error'}" value="${empty errorGuardar ? (aprobar ? 'informe-aprobado-director' : 'informe-devuelto-director') : 'general'}" />
</c:redirect>
