<%-- El comité (el administrador) da la decisión final sobre la propuesta, por POST (RF14,
     RF22, RF34; RF-70 y RF-71 de la lista del otro equipo). Solo en la fase 4, cuando el
     evaluador ya envió su concepto; el comité decide sea cual sea ese concepto. Siempre
     con observación y con el número y la fecha del acta.
       aprobar     la versión queda como la oficial (RF43); se guarda la fecha de
                   aprobación (la del acta): desde ahí corren los 180 días para entregar el
                   informe final (RF31, RF38), que se envía desde el día 90. El proyecto
                   sigue en la fase 4: el estudiante prepara el FDC-125.
       aplazar     el proyecto vuelve a la fase 2: el estudiante sube una versión corregida,
                   que pasa otra vez por el director y el evaluador (decisión del equipo,
                   2026-10-11).
       no-aprobar  el proyecto se cancela, los estudiantes quedan libres para presentar
                   otra propuesta y la idea vuelve al banco (decisión del equipo, 2026-10-11).
       devolver    si falta algo (por ejemplo la firma), vuelve al director (fase 3), que
                   tiene otra vez 5 días hábiles. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/admin/proyectos.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.titulo, p.estado, p.idea_id, f.orden AS fase, ${sqlUltimaRevision} AS ultima,
           e.id AS entrega_id, e.version
    FROM proyectos p
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN entregas e ON e.proyecto_id = p.id AND e.tipo = 'FDC-124'
         AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = 'FDC-124')
    WHERE p.id = ?
    <sql:param value="${empty param.id ? 0 : param.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/admin/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="observacion" value="${fn:trim(param.observacion)}" />
<c:set var="decision" value="${param.decision}" />

<%-- Acta: número entero positivo y fecha válida que no sea futura --%>
<sql:query var="datosActa">
    SELECT (? REGEXP '^[1-9][0-9]{0,8}$') AS numero_valido,
           (? REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') AND STR_TO_DATE(?, '%Y-%m-%d') IS NOT NULL
               AND STR_TO_DATE(?, '%Y-%m-%d') <= CURDATE() AS fecha_valida,
           STR_TO_DATE(?, '%Y-%m-%d') + INTERVAL 180 DAY AS limite,
           STR_TO_DATE(?, '%Y-%m-%d') + INTERVAL 90 DAY AS desde
    <sql:param value="${fn:trim(param.acta)}" />
    <sql:param value="${fn:trim(param.fecha_acta)}" />
    <sql:param value="${fn:trim(param.fecha_acta)}" />
    <sql:param value="${fn:trim(param.fecha_acta)}" />
    <sql:param value="${fn:trim(param.fecha_acta)}" />
    <sql:param value="${fn:trim(param.fecha_acta)}" />
</sql:query>
<c:set var="acta" value="${datosActa.rows[0]}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.fase != 4 or not fn:startsWith(p.ultima, 'Evaluador:') or p.ultima == 'Evaluador:Devuelto'}"><c:set var="motivo" value="decision-no-disponible" /></c:when>
    <c:when test="${decision != 'aprobar' and decision != 'aplazar' and decision != 'no-aprobar' and decision != 'devolver'}"><c:set var="motivo" value="general" /></c:when>
    <c:when test="${empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
    <c:when test="${acta.numero_valido != 1 or acta.fecha_valida != 1}"><c:set var="motivo" value="acta-invalida" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/admin/proyecto.jsp">
        <c:param name="id" value="${p.id}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<c:set var="decisionGuardada" value="${decision == 'aprobar' ? 'Aprobado' : (decision == 'aplazar' ? 'Aplazado' : (decision == 'no-aprobar' ? 'No aprobado' : 'Devuelto'))}" />
<c:set var="numeroActa" value="${fn:trim(param.acta)}" />
<fmt:formatDate var="limiteTexto" value="${acta.limite}" pattern="dd/MM/yyyy" />
<fmt:formatDate var="desdeTexto" value="${acta.desde}" pattern="dd/MM/yyyy" />
<c:if test="${decision == 'devolver'}">
    <c:set var="diasHabiles" value="5" />
    <%@ include file="/WEB-INF/jspf/plazo-habil.jspf" %>
</c:if>
<c:choose>
    <c:when test="${decision == 'aprobar'}"><c:set var="textoDecision">El comité aprobó la versión ${p.version} del FDC-124 (acta ${numeroActa}). Empieza el informe final (FDC-125): se entrega desde el ${desdeTexto} y a más tardar el ${limiteTexto}.</c:set></c:when>
    <c:when test="${decision == 'aplazar'}"><c:set var="textoDecision">El comité aplazó la versión ${p.version} del FDC-124 (acta ${numeroActa}): el estudiante sube una versión corregida. El proyecto volvió a la fase 2 (Propuesta I).</c:set></c:when>
    <c:when test="${decision == 'no-aprobar'}"><c:set var="textoDecision">El comité no aprobó la propuesta (versión ${p.version}, acta ${numeroActa}): el proyecto se canceló y la idea vuelve al banco.</c:set></c:when>
    <c:otherwise><c:set var="textoDecision">El comité devolvió la versión ${p.version} del FDC-124 al director (acta ${numeroActa}) porque le falta algo. El proyecto volvió a la fase 3 (Propuesta II).</c:set></c:otherwise>
</c:choose>

<sql:transaction>
    <sql:update>
        INSERT INTO revisiones (entrega_id, revisor_id, rol, estado, decision, observacion)
        VALUES (?, ?, 'Comité', 'Enviada', ?, ?)
        <sql:param value="${p.entrega_id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${decisionGuardada}" />
        <sql:param value="${observacion}" />
    </sql:update>
    <sql:query var="decisionNueva">SELECT LAST_INSERT_ID() AS id</sql:query>
    <sql:update>
        INSERT INTO actas (proyecto_id, revision_id, numero, fecha, descripcion) VALUES (?, ?, ?, STR_TO_DATE(?, '%Y-%m-%d'), ?)
        <sql:param value="${p.id}" />
        <sql:param value="${decisionNueva.rows[0].id}" />
        <sql:param value="${numeroActa}" />
        <sql:param value="${fn:trim(param.fecha_acta)}" />
        <sql:param value="Propuesta (FDC-124, versión ${p.version}): ${decisionGuardada}. ${observacion}" />
    </sql:update>
    <c:set var="avisoProyecto" value="${p.id}" />
    <c:choose>
        <c:when test="${decision == 'aprobar'}">
            <sql:update>
                UPDATE entregas SET oficial = 1 WHERE id = ?
                <sql:param value="${p.entrega_id}" />
            </sql:update>
            <sql:update>
                UPDATE proyectos SET fecha_aprobacion_124 = STR_TO_DATE(?, '%Y-%m-%d'), fecha_notificacion = CURDATE(),
                       fecha_limite = STR_TO_DATE(?, '%Y-%m-%d') + INTERVAL 180 DAY
                WHERE id = ?
                <sql:param value="${fn:trim(param.fecha_acta)}" />
                <sql:param value="${fn:trim(param.fecha_acta)}" />
                <sql:param value="${p.id}" />
            </sql:update>
            <c:set var="avisoMensaje">${textoDecision} Observación: ${observacion}</c:set>
            <c:set var="avisoPara" value="estudiantes,director,codirectores,evaluador" />
            <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
        </c:when>
        <c:when test="${decision == 'aplazar' or decision == 'devolver'}">
            <sql:update>
                UPDATE proyectos SET fase_id = (SELECT id FROM fases WHERE orden = ?) WHERE id = ?
                <sql:param value="${decision == 'aplazar' ? 2 : 3}" />
                <sql:param value="${p.id}" />
            </sql:update>
            <c:if test="${decision == 'devolver'}">
                <sql:update>
                    UPDATE entregas SET fecha_limite_revision = ? WHERE id = ?
                    <sql:dateParam value="${fechaPlazo}" type="date" />
                    <sql:param value="${p.entrega_id}" />
                </sql:update>
            </c:if>
            <c:set var="avisoMensaje">${textoDecision} Observación: ${observacion}</c:set>
            <c:set var="avisoPara" value="estudiantes,director,codirectores,evaluador" />
            <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
        </c:when>
        <c:otherwise>
            <%-- Avisos antes de liberar a los estudiantes --%>
            <c:set var="avisoMensaje">${textoDecision} Puedes presentar otra propuesta. Observación: ${observacion}</c:set>
            <c:set var="avisoPara" value="estudiantes,director,codirectores,evaluador" />
            <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
            <sql:update>
                UPDATE proyectos SET estado = 'Cancelado' WHERE id = ?
                <sql:param value="${p.id}" />
            </sql:update>
            <sql:update>
                UPDATE proyecto_estudiantes SET vigente = NULL WHERE proyecto_id = ? AND vigente = 1
                <sql:param value="${p.id}" />
            </sql:update>
            <c:if test="${not empty p.idea_id}">
                <sql:update>
                    UPDATE ideas SET estado = 'Aprobada' WHERE id = ? AND estado = 'Tomada'
                    <sql:param value="${p.idea_id}" />
                </sql:update>
            </c:if>
        </c:otherwise>
    </c:choose>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Decisión', ?)
        <sql:param value="${p.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${fn:substring(textoDecision, 0, 255)}" />
    </sql:update>
</sql:transaction>

<c:redirect url="/admin/proyecto.jsp">
    <c:param name="id" value="${p.id}" />
    <c:param name="ok" value="propuesta-${decision}-comite" />
</c:redirect>
