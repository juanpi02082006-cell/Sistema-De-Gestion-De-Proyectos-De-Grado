<%-- Quita una sesión del calendario del comité (por POST). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/admin/periodos.jsp" />
</c:if>

<sql:update var="borrados">
    DELETE FROM sesiones_comite WHERE id = ?
    <sql:param value="${param.id}" />
</sql:update>

<c:redirect url="/admin/sesiones.jsp">
    <c:param name="periodo" value="${param.periodo}" />
    <c:param name="${borrados == 1 ? 'ok' : 'error'}" value="${borrados == 1 ? 'sesion-eliminada' : 'no-encontrado'}" />
</c:redirect>
