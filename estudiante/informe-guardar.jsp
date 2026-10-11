<%-- Recibe el informe final (FDC-125) en la fase 4, por POST multipart (RF26, RF31).
     web.xml le da multipart-config a esta página. Cada archivo es una versión nueva
     (RF43). Reglas: proyecto vigente en la fase 4 con el FDC-124 aprobado por el comité;
     en Word (.doc o .docx), de hasta 15 MB (RF30, RNF15). Se puede subir antes del día
     90: lo que se controla es el envío al director (informe-enviar.jsp). --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<c:set var="idEstudiante" value="${sessionScope.usuario.id}" />
<sql:query var="consulta">
    SELECT p.id, p.estado, p.fecha_aprobacion_124, f.orden AS fase, f.id AS fase_id,
           (SELECT COALESCE(MAX(e.version), 0) + 1 FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125') AS version
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${idEstudiante}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />

<%-- El archivo: si es demasiado grande, getPart lanza una excepción --%>
<c:catch var="errorArchivo">
    <c:set var="parte" value="${pageContext.request.getPart('informe')}" />
</c:catch>
<c:set var="nombreOriginal" value="${empty parte ? '' : fn:trim(parte.submittedFileName)}" />
<c:set var="nombreMinusculas" value="${fn:toLowerCase(nombreOriginal)}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.fase != 4 or empty p.fecha_aprobacion_124}"><c:set var="motivo" value="informe-no-aplica" /></c:when>
    <c:when test="${not empty errorArchivo}"><c:set var="motivo" value="archivo-grande" /></c:when>
    <c:when test="${empty parte or parte.size == 0 or empty nombreOriginal}"><c:set var="motivo" value="archivo-requerido" /></c:when>
    <c:when test="${parte.size > 15728640}"><c:set var="motivo" value="archivo-grande" /></c:when>
    <c:when test="${not fn:endsWith(nombreMinusculas, '.docx') and not fn:endsWith(nombreMinusculas, '.doc')}"><c:set var="motivo" value="informe-no-word" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/estudiante/proyecto.jsp">
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<%-- Nombre con el que se guarda: no depende del nombre que mandó el usuario --%>
<c:set var="extension" value="${fn:endsWith(nombreMinusculas, '.docx') ? '.docx' : '.doc'}" />
<c:set var="nombreGuardado" value="fdc125-p${p.id}-v${p.version}-${System.currentTimeMillis()}${extension}" />
<c:set var="carpeta" value="${pageContext.servletContext.getRealPath('/WEB-INF/archivos')}" />

<c:catch var="errorGuardar">
    <c:set var="rutaGuardada">${carpeta}/${nombreGuardado}</c:set>
    <c:set var="escrito" value="${parte.write(rutaGuardada)}" />
    <sql:transaction>
        <sql:update>
            INSERT INTO entregas (proyecto_id, fase_id, tipo, version, nombre_archivo, ruta_archivo, subido_por)
            VALUES (?, ?, 'FDC-125', ?, ?, ?, ?)
            <sql:param value="${p.id}" />
            <sql:param value="${p.fase_id}" />
            <sql:param value="${p.version}" />
            <sql:param value="${fn:substring(nombreOriginal, 0, 255)}" />
            <sql:param value="${nombreGuardado}" />
            <sql:param value="${idEstudiante}" />
        </sql:update>
        <sql:update>
            INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion)
            VALUES (?, ?, 'Documento', ?)
            <sql:param value="${p.id}" />
            <sql:param value="${idEstudiante}" />
            <sql:param value="El estudiante subió la versión ${p.version} del FDC-125 (informe final)." />
        </sql:update>
    </sql:transaction>
</c:catch>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="${empty errorGuardar ? 'ok' : 'error'}" value="${empty errorGuardar ? 'informe-subido' : 'general'}" />
</c:redirect>
