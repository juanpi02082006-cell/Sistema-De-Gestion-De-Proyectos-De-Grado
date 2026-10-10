<%-- Guarda la descripción y el máximo de integrantes de una modalidad (RF4). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/panel/modalidades.jsp" />
</c:if>

<c:set var="maximo" value="${param.max_integrantes}" />
<c:if test="${maximo != '1' and maximo != '2' and maximo != '3' and maximo != '4'}">
    <jsp:forward page="modalidad-form.jsp"><jsp:param name="error" value="maximo" /></jsp:forward>
</c:if>

<sql:update var="cambiados">
    UPDATE modalidades SET descripcion = NULLIF(?, ''), max_integrantes = ? WHERE id = ?
    <sql:param value="${fn:trim(param.descripcion)}" />
    <sql:param value="${maximo}" />
    <sql:param value="${param.id}" />
</sql:update>

<c:redirect url="/panel/modalidades.jsp">
    <c:param name="${cambiados == 0 ? 'error' : 'ok'}" value="${cambiados == 0 ? 'no-encontrado' : 'modalidad-actualizada'}" />
</c:redirect>
