<%-- Valida el inicio de sesión (punto 1). Recibe correo y clave por POST.
     - Si son correctos, guarda en la sesión: usuario, roles y rolActivo.
     - Con un solo rol entra directo al panel; con varios, elige el rol primero. --%>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/index.jsp" />
</c:if>

<%-- A-10: solo se entra con correo institucional (@uts.edu.co o @correo.uts.edu.co) --%>
<c:set var="correoIngresado" value="${fn:toLowerCase(fn:trim(param.correo))}" />
<c:if test="${not (fn:endsWith(correoIngresado, '@uts.edu.co') or fn:endsWith(correoIngresado, '@correo.uts.edu.co'))}">
    <c:redirect url="/index.jsp">
        <c:param name="error" value="dominio" />
        <c:param name="correo" value="${param.correo}" />
    </c:redirect>
</c:if>

<sql:query var="consulta">
    SELECT id, nombre, correo
    FROM usuarios
    WHERE correo = ? AND contrasena = SHA2(?, 256) AND activo = 1
    <sql:param value="${correoIngresado}" />
    <sql:param value="${param.clave}" />
</sql:query>

<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/index.jsp">
        <c:param name="error" value="credenciales" />
        <c:param name="correo" value="${param.correo}" />
    </c:redirect>
</c:if>

<c:set var="usuarioValido" value="${consulta.rows[0]}" />

<sql:query var="rolesUsuario">
    SELECT r.id, r.nombre
    FROM roles r
    JOIN usuario_roles ur ON ur.rol_id = r.id
    WHERE ur.usuario_id = ?
    ORDER BY r.id
    <sql:param value="${usuarioValido.id}" />
</sql:query>

<c:if test="${rolesUsuario.rowCount == 0}">
    <c:redirect url="/index.jsp">
        <c:param name="error" value="sin-rol" />
    </c:redirect>
</c:if>

<%-- Nuevo identificador de sesión al entrar (evita que se reuse una sesión anterior) --%>
<c:set var="idNuevo" value="${pageContext.request.changeSessionId()}" />

<c:set var="usuario" scope="session" value="${usuarioValido}" />
<c:set var="roles" scope="session" value="${rolesUsuario.rows}" />

<c:choose>
    <c:when test="${rolesUsuario.rowCount == 1}">
        <c:set var="rolActivo" scope="session" value="${rolesUsuario.rows[0]}" />
        <c:redirect url="/panel/inicio.jsp" />
    </c:when>
    <c:otherwise>
        <c:remove var="rolActivo" scope="session" />
        <c:redirect url="/acceso/elegir-rol.jsp" />
    </c:otherwise>
</c:choose>
