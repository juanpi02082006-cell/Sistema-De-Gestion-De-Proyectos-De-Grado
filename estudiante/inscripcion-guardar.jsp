<%-- Recibe un documento de inscripción al Seminario (RF17; proceso entregado por el
     equipo el 2026-10-10), por POST multipart: el formato F-AM-04 (solicitud de trabajo
     de grado, con la opción Seminario) o la cédula ampliada al 150 %, en PDF de hasta
     15 MB. Solo para proyectos de Seminario en la fase 1 cuya inscripción todavía no
     validó el comité. Si sube otro, cuenta el último. El recibo de pago va aparte
     (pago-guardar.jsp). --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.estado, p.modalidad_id, f.orden AS fase, f.id AS fase_id
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="tipoDocumento" value="${param.documento == 'f-am-04' ? 'Formato F-AM-04' : (param.documento == 'cedula' ? 'Documento de identidad' : '')}" />

<c:catch var="errorArchivo">
    <c:set var="parte" value="${pageContext.request.getPart('archivo')}" />
</c:catch>
<c:set var="nombreOriginal" value="${empty parte ? '' : fn:trim(parte.submittedFileName)}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado != 'Pendiente'}"><c:set var="motivo" value="inscripcion-cerrada" /></c:when>
    <c:when test="${p.modalidad_id != 5 or p.fase != 1}"><c:set var="motivo" value="inscripcion-no-aplica" /></c:when>
    <c:when test="${empty tipoDocumento}"><c:set var="motivo" value="general" /></c:when>
    <c:when test="${not empty errorArchivo}"><c:set var="motivo" value="archivo-grande" /></c:when>
    <c:when test="${empty parte or parte.size == 0 or empty nombreOriginal}"><c:set var="motivo" value="archivo-requerido" /></c:when>
    <c:when test="${parte.size > 15728640}"><c:set var="motivo" value="archivo-grande" /></c:when>
    <c:when test="${not fn:endsWith(fn:toLowerCase(nombreOriginal), '.pdf')}"><c:set var="motivo" value="archivo-invalido" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/estudiante/proyecto.jsp">
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<c:set var="nombreGuardado" value="${param.documento}-p${p.id}-u${sessionScope.usuario.id}-${System.currentTimeMillis()}.pdf" />
<c:set var="carpeta" value="${pageContext.servletContext.getRealPath('/WEB-INF/archivos')}" />

<c:catch var="errorGuardar">
    <c:set var="rutaGuardada">${carpeta}/${nombreGuardado}</c:set>
    <c:set var="escrito" value="${parte.write(rutaGuardada)}" />
    <sql:transaction>
        <sql:update>
            INSERT INTO entregas (proyecto_id, fase_id, tipo, nombre_archivo, ruta_archivo, subido_por)
            VALUES (?, ?, ?, ?, ?, ?)
            <sql:param value="${p.id}" />
            <sql:param value="${p.fase_id}" />
            <sql:param value="${tipoDocumento}" />
            <sql:param value="${fn:substring(nombreOriginal, 0, 255)}" />
            <sql:param value="${nombreGuardado}" />
            <sql:param value="${sessionScope.usuario.id}" />
        </sql:update>
        <sql:update>
            INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Documento', ?)
            <sql:param value="${p.id}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="${sessionScope.usuario.nombre} subió ${tipoDocumento == 'Formato F-AM-04' ? 'el formato F-AM-04' : 'su documento de identidad'} para la inscripción al seminario." />
        </sql:update>
    </sql:transaction>
</c:catch>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="${empty errorGuardar ? 'ok' : 'error'}" value="${empty errorGuardar ? 'inscripcion-documento' : 'general'}" />
</c:redirect>
