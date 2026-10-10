<%-- Cierra la sesión y vuelve al inicio de sesión. --%>
<c:set var="cerrada" value="${pageContext.session.invalidate()}" />
<c:redirect url="/index.jsp">
    <c:param name="aviso" value="salida" />
</c:redirect>
