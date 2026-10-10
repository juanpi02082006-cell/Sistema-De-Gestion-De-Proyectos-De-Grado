<%-- Elimina un rol (por POST). Los 4 roles base (ids 1, 3, 4 y 5; el 2 ya no se usa) no se pueden eliminar, y la base
     no deja borrar un rol que tenga usuarios asignados. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/admin/roles.jsp" />
</c:if>

<sql:query var="consultaRol">
    SELECT id FROM roles WHERE id = ?
    <sql:param value="${param.id}" />
</sql:query>
<c:if test="${consultaRol.rowCount == 0}">
    <c:redirect url="/admin/roles.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:if test="${consultaRol.rows[0].id <= 5}">
    <c:redirect url="/admin/roles.jsp">
        <c:param name="error" value="rol-base" />
    </c:redirect>
</c:if>

<c:catch var="errorEliminar">
    <sql:update>
        DELETE FROM roles WHERE id = ?
        <sql:param value="${param.id}" />
    </sql:update>
</c:catch>

<c:choose>
    <c:when test="${not empty errorEliminar}">
        <c:redirect url="/admin/roles.jsp">
            <c:param name="error" value="${fn:contains(fn:toLowerCase(errorEliminar.message), 'foreign key') ? 'rol-con-usuarios' : 'general'}" />
        </c:redirect>
    </c:when>
    <c:otherwise>
        <c:redirect url="/admin/roles.jsp">
            <c:param name="ok" value="rol-eliminado" />
        </c:redirect>
    </c:otherwise>
</c:choose>
