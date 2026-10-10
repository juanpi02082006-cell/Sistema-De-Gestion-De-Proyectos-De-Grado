<%-- Guarda un usuario nuevo o editado (RF7) junto con sus roles y, si es
     estudiante, sus datos académicos. Si algo falla, vuelve al formulario con el
     error y los datos escritos. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/admin/usuarios.jsp" />
</c:if>

<c:set var="editando" value="${not empty param.id}" />
<c:set var="idSesion">${sessionScope.usuario.id}</c:set>
<c:set var="esUsuarioPropio" value="${editando and param.id == idSesion}" />

<%-- Qué roles se marcaron --%>
<c:set var="tieneAdmin" value="false" />
<c:set var="esEstudiante" value="false" />
<c:forEach var="x" items="${paramValues.roles}">
    <c:if test="${x == '1'}"><c:set var="tieneAdmin" value="true" /></c:if>
    <c:if test="${x == '5'}"><c:set var="esEstudiante" value="true" /></c:if>
</c:forEach>

<%-- Correo en minúsculas; debe ser institucional (A-10) --%>
<c:set var="correo" value="${fn:toLowerCase(fn:trim(param.correo))}" />
<c:set var="esInstitucional" value="${fn:endsWith(correo, '@uts.edu.co') or fn:endsWith(correo, '@correo.uts.edu.co')}" />

<%-- % de créditos aprobados del estudiante (punto 38, A-07): vacío o entero de 0 a 100 --%>
<c:set var="creditosTexto" value="${fn:trim(param.porcentaje_creditos)}" />
<c:set var="creditosValidos" value="true" />
<c:if test="${esEstudiante and not empty creditosTexto}">
    <c:catch var="errorCreditos">
        <fmt:parseNumber var="creditosNumero" value="${creditosTexto}" integerOnly="true" parseLocale="en_US" />
    </c:catch>
    <c:set var="creditosNormalizado">${creditosNumero}</c:set>
    <c:if test="${not empty errorCreditos or creditosNormalizado != creditosTexto
                  or creditosNumero < 0 or creditosNumero > 100}">
        <c:set var="creditosValidos" value="false" />
    </c:if>
</c:if>

<%-- Validaciones --%>
<c:choose>
    <c:when test="${empty fn:trim(param.nombre) or empty param.tipo_documento
                    or empty fn:trim(param.numero_documento) or empty fn:trim(param.correo)}">
        <jsp:forward page="usuario-form.jsp"><jsp:param name="error" value="faltan-datos" /></jsp:forward>
    </c:when>
    <c:when test="${not esInstitucional}">
        <jsp:forward page="usuario-form.jsp"><jsp:param name="error" value="correo-no-institucional" /></jsp:forward>
    </c:when>
    <c:when test="${empty paramValues.roles}">
        <jsp:forward page="usuario-form.jsp"><jsp:param name="error" value="sin-roles" /></jsp:forward>
    </c:when>
    <c:when test="${not creditosValidos}">
        <jsp:forward page="usuario-form.jsp"><jsp:param name="error" value="creditos-invalidos" /></jsp:forward>
    </c:when>
    <c:when test="${esEstudiante and not empty param.plan_estudios and param.plan_estudios != 'Anterior' and param.plan_estudios != 'Nuevo'}">
        <jsp:forward page="usuario-form.jsp"><jsp:param name="error" value="general" /></jsp:forward>
    </c:when>
    <c:when test="${not editando and empty param.clave}">
        <jsp:forward page="usuario-form.jsp"><jsp:param name="error" value="clave-requerida" /></jsp:forward>
    </c:when>
    <c:when test="${esUsuarioPropio and (not tieneAdmin or param.activo != 'on')}">
        <jsp:forward page="usuario-form.jsp"><jsp:param name="error" value="admin-propio" /></jsp:forward>
    </c:when>
</c:choose>

<%-- Los datos académicos solo se guardan si el usuario es estudiante --%>
<c:set var="nivel" value="${esEstudiante ? param.nivel : ''}" />
<c:set var="carrera" value="${esEstudiante ? fn:trim(param.carrera) : ''}" />
<c:set var="creditos" value="${esEstudiante ? creditosTexto : ''}" />
<c:set var="plan" value="${esEstudiante ? param.plan_estudios : ''}" />
<c:set var="metodologia" value="${esEstudiante ? (param.metodologia == 'on' ? '1' : '0') : ''}" />

<c:catch var="errorGuardar">
    <sql:transaction>
        <c:choose>
            <c:when test="${not editando}">
                <sql:update>
                    INSERT INTO usuarios (nombre, tipo_documento_id, numero_documento, correo, contrasena, celular, nivel_id, carrera,
                                          porcentaje_creditos, plan_estudios, metodologia_aprobada)
                    VALUES (?, ?, ?, ?, SHA2(?, 256), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''))
                    <sql:param value="${fn:trim(param.nombre)}" />
                    <sql:param value="${param.tipo_documento}" />
                    <sql:param value="${fn:trim(param.numero_documento)}" />
                    <sql:param value="${correo}" />
                    <sql:param value="${param.clave}" />
                    <sql:param value="${fn:trim(param.celular)}" />
                    <sql:param value="${nivel}" />
                    <sql:param value="${carrera}" />
                    <sql:param value="${creditos}" />
                    <sql:param value="${plan}" />
                    <sql:param value="${metodologia}" />
                </sql:update>
                <sql:query var="nuevo">SELECT LAST_INSERT_ID() AS id</sql:query>
                <c:set var="idUsuario" value="${nuevo.rows[0].id}" />
            </c:when>
            <c:otherwise>
                <sql:update>
                    UPDATE usuarios
                    SET nombre = ?, tipo_documento_id = ?, numero_documento = ?, correo = ?,
                        celular = NULLIF(?, ''), nivel_id = NULLIF(?, ''), carrera = NULLIF(?, ''),
                        porcentaje_creditos = NULLIF(?, ''), plan_estudios = NULLIF(?, ''),
                        metodologia_aprobada = NULLIF(?, ''), activo = ?
                    WHERE id = ?
                    <sql:param value="${fn:trim(param.nombre)}" />
                    <sql:param value="${param.tipo_documento}" />
                    <sql:param value="${fn:trim(param.numero_documento)}" />
                    <sql:param value="${correo}" />
                    <sql:param value="${fn:trim(param.celular)}" />
                    <sql:param value="${nivel}" />
                    <sql:param value="${carrera}" />
                    <sql:param value="${creditos}" />
                    <sql:param value="${plan}" />
                    <sql:param value="${metodologia}" />
                    <sql:param value="${param.activo == 'on' ? 1 : 0}" />
                    <sql:param value="${param.id}" />
                </sql:update>
                <c:if test="${not empty param.clave}">
                    <sql:update>
                        UPDATE usuarios SET contrasena = SHA2(?, 256) WHERE id = ?
                        <sql:param value="${param.clave}" />
                        <sql:param value="${param.id}" />
                    </sql:update>
                </c:if>
                <sql:update>
                    DELETE FROM usuario_roles WHERE usuario_id = ?
                    <sql:param value="${param.id}" />
                </sql:update>
                <c:set var="idUsuario" value="${param.id}" />
            </c:otherwise>
        </c:choose>

        <c:forEach var="rolId" items="${paramValues.roles}">
            <sql:update>
                INSERT INTO usuario_roles (usuario_id, rol_id) VALUES (?, ?)
                <sql:param value="${idUsuario}" />
                <sql:param value="${rolId}" />
            </sql:update>
        </c:forEach>
    </sql:transaction>
</c:catch>

<c:if test="${not empty errorGuardar}">
    <c:choose>
        <c:when test="${fn:contains(errorGuardar.message, 'uq_usuarios_correo')}">
            <jsp:forward page="usuario-form.jsp"><jsp:param name="error" value="correo-duplicado" /></jsp:forward>
        </c:when>
        <c:when test="${fn:contains(errorGuardar.message, 'uq_usuarios_documento')}">
            <jsp:forward page="usuario-form.jsp"><jsp:param name="error" value="documento-duplicado" /></jsp:forward>
        </c:when>
        <%-- Por si algo pasa la validación de la página, la base también lo revisa --%>
        <c:when test="${fn:contains(errorGuardar.message, 'chk_usuarios_correo_institucional')}">
            <jsp:forward page="usuario-form.jsp"><jsp:param name="error" value="correo-no-institucional" /></jsp:forward>
        </c:when>
        <c:when test="${fn:contains(errorGuardar.message, 'chk_usuarios_porcentaje_creditos')}">
            <jsp:forward page="usuario-form.jsp"><jsp:param name="error" value="creditos-invalidos" /></jsp:forward>
        </c:when>
        <c:otherwise>
            <jsp:forward page="usuario-form.jsp"><jsp:param name="error" value="general" /></jsp:forward>
        </c:otherwise>
    </c:choose>
</c:if>

<%-- Si el administrador se editó a sí mismo, actualizar su nombre en la sesión --%>
<c:if test="${esUsuarioPropio}">
    <sql:query var="actualizado">
        SELECT id, nombre, correo FROM usuarios WHERE id = ?
        <sql:param value="${param.id}" />
    </sql:query>
    <c:set var="usuario" scope="session" value="${actualizado.rows[0]}" />
</c:if>

<c:redirect url="/admin/usuarios.jsp">
    <c:param name="ok" value="${editando ? 'usuario-actualizado' : 'usuario-creado'}" />
</c:redirect>
