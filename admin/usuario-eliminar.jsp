<%-- Elimina un usuario (por POST). Sus roles se borran solos (ON DELETE CASCADE).
     Si tiene proyectos, ideas u otra información asociada, la base no deja
     borrarlo y se sugiere desactivarlo. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/admin/usuarios.jsp" />
</c:if>

<c:set var="idSesion">${sessionScope.usuario.id}</c:set>
<c:if test="${param.id == idSesion}">
    <c:redirect url="/admin/usuarios.jsp">
        <c:param name="error" value="eliminar-propio" />
    </c:redirect>
</c:if>

<c:catch var="errorEliminar">
    <sql:update var="borrados">
        DELETE FROM usuarios WHERE id = ?
        <sql:param value="${param.id}" />
    </sql:update>
</c:catch>

<c:choose>
    <c:when test="${not empty errorEliminar}">
        <c:redirect url="/admin/usuarios.jsp">
            <c:param name="error" value="${fn:contains(fn:toLowerCase(errorEliminar.message), 'foreign key') ? 'usuario-con-registros' : 'general'}" />
        </c:redirect>
    </c:when>
    <c:when test="${borrados == 0}">
        <c:redirect url="/admin/usuarios.jsp">
            <c:param name="error" value="no-encontrado" />
        </c:redirect>
    </c:when>
    <c:otherwise>
        <c:redirect url="/admin/usuarios.jsp">
            <c:param name="ok" value="usuario-eliminado" />
        </c:redirect>
    </c:otherwise>
</c:choose>
