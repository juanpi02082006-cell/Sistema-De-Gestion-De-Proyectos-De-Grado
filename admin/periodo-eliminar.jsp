<%-- Elimina un periodo (por POST). Si tiene ideas o proyectos, la base no deja
     borrarlo y se sugiere cerrarlo. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/admin/periodos.jsp" />
</c:if>

<c:catch var="errorEliminar">
    <sql:update var="borrados">
        DELETE FROM periodos WHERE id = ?
        <sql:param value="${param.id}" />
    </sql:update>
</c:catch>

<c:choose>
    <c:when test="${not empty errorEliminar}">
        <c:redirect url="/admin/periodos.jsp">
            <c:param name="error" value="${fn:contains(fn:toLowerCase(errorEliminar.message), 'foreign key') ? 'periodo-con-registros' : 'general'}" />
        </c:redirect>
    </c:when>
    <c:when test="${borrados == 0}">
        <c:redirect url="/admin/periodos.jsp">
            <c:param name="error" value="no-encontrado" />
        </c:redirect>
    </c:when>
    <c:otherwise>
        <c:redirect url="/admin/periodos.jsp">
            <c:param name="ok" value="periodo-eliminado" />
        </c:redirect>
    </c:otherwise>
</c:choose>
