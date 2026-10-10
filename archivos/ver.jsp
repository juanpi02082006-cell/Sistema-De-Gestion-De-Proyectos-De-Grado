<%-- Muestra un archivo subido (?id= de la entrega). Los archivos están en
     WEB-INF/archivos, que no se abre desde el navegador; aquí se revisa el permiso y
     se reenvía la petición al archivo. Pueden verlo: el administrador (comité), los
     estudiantes del proyecto y su director, codirectores o evaluador. --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>

<c:set var="rol" value="${sessionScope.rolActivo.id}" />
<sql:query var="consulta">
    SELECT e.ruta_archivo
    FROM entregas e
    JOIN proyectos p ON p.id = e.proyecto_id
    WHERE e.id = ?
      AND (? = 1
           OR (? = 5 AND EXISTS (SELECT 1 FROM proyecto_estudiantes pe WHERE pe.proyecto_id = p.id AND pe.estudiante_id = ?))
           OR (? = 3 AND (p.director_id = ? OR EXISTS (SELECT 1 FROM proyecto_codirectores pc WHERE pc.proyecto_id = p.id AND pc.docente_id = ?)))
           OR (? = 4 AND p.evaluador_id = ?))
    <sql:param value="${empty param.id ? 0 : param.id}" />
    <sql:param value="${rol}" />
    <sql:param value="${rol}" />
    <sql:param value="${sessionScope.usuario.id}" />
    <sql:param value="${rol}" />
    <sql:param value="${sessionScope.usuario.id}" />
    <sql:param value="${sessionScope.usuario.id}" />
    <sql:param value="${rol}" />
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>

<c:set var="ruta" value="${consulta.rowCount == 0 ? '' : consulta.rows[0].ruta_archivo}" />
<%-- Las rutas las genera el sistema (recibo-p12-1760000000000.pdf); por si acaso,
     nada de "/", ":" ni "..", para no salir de WEB-INF/archivos. --%>
<c:if test="${empty ruta or fn:contains(ruta, '/') or fn:contains(ruta, ':') or fn:contains(ruta, '..')}">
    <c:redirect url="/panel/inicio.jsp">
        <c:param name="error" value="denegado" />
    </c:redirect>
</c:if>

<%-- La JSP ya dejó el tipo text/html: se cambia por el del archivo (application/pdf…) --%>
<c:set var="tipo" value="${pageContext.servletContext.getMimeType(ruta)}" />
<c:set var="sinUso" value="${pageContext.response.setContentType(empty tipo ? 'application/octet-stream' : tipo)}" />
<jsp:forward page="/WEB-INF/archivos/${ruta}" />
