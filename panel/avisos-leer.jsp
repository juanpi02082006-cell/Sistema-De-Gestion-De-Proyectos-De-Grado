<%-- Marca como leídos todos los avisos del usuario de la sesión, por POST. --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<c:if test="${pageContext.request.method == 'POST'}">
    <sql:update>
        UPDATE avisos SET leido = 1 WHERE usuario_id = ? AND leido = 0
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:update>
</c:if>
<c:redirect url="/panel/avisos.jsp" />
