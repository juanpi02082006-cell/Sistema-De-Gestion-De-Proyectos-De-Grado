<%-- Quita un entregable de la modalidad (RF26), por POST: solo quien lo subió y mientras el
     proyecto siga en la fase 4 (al enviar el informe final, los entregables van con él). El
     registro se borra; el archivo queda en WEB-INF/archivos, que no se abre desde el
     navegador. --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT e.id, e.proyecto_id, e.tipo, e.nombre_archivo, f.orden AS fase, p.estado
    FROM entregas e
    JOIN proyectos p ON p.id = e.proyecto_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE e.id = ? AND e.tipo IN ('Evidencia', 'Manual de usuario', 'Código fuente') AND e.subido_por = ?
    <sql:param value="${empty param.id ? 0 : param.id}" />
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:choose>
    <c:when test="${consulta.rowCount == 0}"><c:set var="motivo" value="no-encontrado" /></c:when>
    <c:when test="${consulta.rows[0].estado == 'Finalizado' or consulta.rows[0].estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${consulta.rows[0].fase != 4}"><c:set var="motivo" value="fase-no-permite-entregable" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/estudiante/proyecto.jsp">
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>
<c:set var="entregable" value="${consulta.rows[0]}" />

<sql:transaction>
    <sql:update>
        DELETE FROM entregas WHERE id = ?
        <sql:param value="${entregable.id}" />
    </sql:update>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Documento', ?)
        <sql:param value="${entregable.proyecto_id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="El estudiante quitó el entregable «${fn:substring(entregable.nombre_archivo, 0, 150)}» (${entregable.tipo})." />
    </sql:update>
</sql:transaction>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="ok" value="entregable-quitado" />
</c:redirect>
