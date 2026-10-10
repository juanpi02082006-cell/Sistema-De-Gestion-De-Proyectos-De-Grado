<%-- Elimina una idea propia (por POST), solo si está pendiente o rechazada. --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/ideas/banco.jsp" />
</c:if>

<c:set var="rol" value="${sessionScope.rolActivo.id}" />
<c:catch var="errorEliminar">
    <sql:update var="borrados">
        DELETE FROM ideas
        WHERE id = ? AND propuesta_por = ? AND origen = ? AND estado IN ('Pendiente', 'Rechazada')
        <sql:param value="${param.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${rol == 5 ? 'Estudiante' : 'Docente'}" />
    </sql:update>
</c:catch>

<c:redirect url="/ideas/banco.jsp">
    <c:param name="${empty errorEliminar and borrados == 1 ? 'ok' : 'error'}" value="${empty errorEliminar and borrados == 1 ? 'idea-eliminada' : 'idea-no-editable'}" />
</c:redirect>
