<%-- Guarda un rol nuevo o editado (punto 3). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/admin/roles.jsp" />
</c:if>

<c:set var="editando" value="${not empty param.id}" />

<c:if test="${empty fn:trim(param.nombre)}">
    <jsp:forward page="rol-form.jsp"><jsp:param name="error" value="faltan-datos" /></jsp:forward>
</c:if>

<c:catch var="errorGuardar">
    <c:choose>
        <c:when test="${not editando}">
            <sql:update>
                INSERT INTO roles (nombre, descripcion) VALUES (?, NULLIF(?, ''))
                <sql:param value="${fn:trim(param.nombre)}" />
                <sql:param value="${fn:trim(param.descripcion)}" />
            </sql:update>
        </c:when>
        <c:otherwise>
            <sql:update>
                UPDATE roles SET nombre = ?, descripcion = NULLIF(?, '') WHERE id = ?
                <sql:param value="${fn:trim(param.nombre)}" />
                <sql:param value="${fn:trim(param.descripcion)}" />
                <sql:param value="${param.id}" />
            </sql:update>
        </c:otherwise>
    </c:choose>
</c:catch>

<c:if test="${not empty errorGuardar}">
    <jsp:forward page="rol-form.jsp">
        <jsp:param name="error" value="${fn:contains(errorGuardar.message, 'uq_roles_nombre') ? 'nombre-duplicado' : 'general'}" />
    </jsp:forward>
</c:if>

<%-- Si se renombró el rol con el que está el administrador, actualizarlo en la sesión --%>
<c:set var="idRolActivo">${sessionScope.rolActivo.id}</c:set>
<c:if test="${editando and param.id == idRolActivo}">
    <sql:query var="rolesUsuario">
        SELECT r.id, r.nombre FROM roles r JOIN usuario_roles ur ON ur.rol_id = r.id
        WHERE ur.usuario_id = ? ORDER BY r.id
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
    <c:set var="roles" scope="session" value="${rolesUsuario.rows}" />
    <c:forEach var="r" items="${rolesUsuario.rows}">
        <c:set var="idRol">${r.id}</c:set>
        <c:if test="${idRol == idRolActivo}"><c:set var="rolActivo" scope="session" value="${r}" /></c:if>
    </c:forEach>
</c:if>

<c:redirect url="/admin/roles.jsp">
    <c:param name="ok" value="${editando ? 'rol-actualizado' : 'rol-creado'}" />
</c:redirect>
