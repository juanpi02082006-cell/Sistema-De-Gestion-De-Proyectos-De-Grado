<%-- Crear (sin id) o editar (con ?id=) un usuario (RF7). Solo correos
     institucionales (RF1). El administrador registra a los docentes; de los
     estudiantes (que se registran solos, RF24) actualiza los datos académicos:
     carrera (del catálogo; el nivel sale de ella), plan de estudios, % de créditos y
     Metodología (RF29).
     Si usuario-guardar.jsp encuentra un error, vuelve aquí con ?error=... y con
     los datos que se habían escrito. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>

<c:set var="editando" value="${not empty param.id}" />
<c:set var="reintento" value="${not empty param.error}" />

<c:if test="${editando}">
    <sql:query var="consultaUsuario">
        SELECT id, nombre, tipo_documento_id, numero_documento, correo, celular, nivel_id, carrera_id,
               plan_estudios, porcentaje_creditos, metodologia_aprobada, activo
        FROM usuarios WHERE id = ?
        <sql:param value="${param.id}" />
    </sql:query>
    <c:if test="${consultaUsuario.rowCount == 0}">
        <c:redirect url="/admin/usuarios.jsp">
            <c:param name="error" value="no-encontrado" />
        </c:redirect>
    </c:if>
    <c:set var="u" value="${consultaUsuario.rows[0]}" />
    <sql:query var="rolesActuales">
        SELECT rol_id FROM usuario_roles WHERE usuario_id = ?
        <sql:param value="${param.id}" />
    </sql:query>
</c:if>

<sql:query var="tiposDocumento">SELECT id, nombre FROM tipos_documentos ORDER BY id</sql:query>
<sql:query var="listaRoles">SELECT id, nombre FROM roles ORDER BY id</sql:query>

<%-- Valores del formulario: los que se escribieron (si hubo error) o los guardados --%>
<c:set var="vNombre"    value="${reintento ? param.nombre : u.nombre}" />
<c:set var="vTipoDoc"   value="${reintento ? param.tipo_documento : u.tipo_documento_id}" />
<c:set var="vDocumento" value="${reintento ? param.numero_documento : u.numero_documento}" />
<c:set var="vCorreo"    value="${reintento ? param.correo : u.correo}" />
<c:set var="vCelular"   value="${reintento ? param.celular : u.celular}" />
<c:set var="vCarrera">${reintento ? param.carrera : u.carrera_id}</c:set>
<c:set var="vCreditos"  value="${reintento ? param.porcentaje_creditos : u.porcentaje_creditos}" />
<c:set var="vPlan"      value="${reintento ? param.plan_estudios : u.plan_estudios}" />
<c:set var="vMetodologia" value="${reintento ? param.metodologia == 'on' : u.metodologia_aprobada == true}" />
<c:set var="vActivo"    value="${reintento ? param.activo == 'on' : (editando ? u.activo : true)}" />

<%-- Roles marcados, como texto "|1|3|" para revisar cada casilla --%>
<c:set var="rolesMarcados" value="|" />
<c:choose>
    <c:when test="${reintento}">
        <c:forEach var="x" items="${paramValues.roles}">
            <c:set var="rolesMarcados" value="${rolesMarcados}${x}|" />
        </c:forEach>
    </c:when>
    <c:when test="${editando}">
        <c:forEach var="x" items="${rolesActuales.rows}">
            <c:set var="rolesMarcados" value="${rolesMarcados}${x.rol_id}|" />
        </c:forEach>
    </c:when>
</c:choose>

<c:set var="titulo" value="${editando ? 'Editar usuario' : 'Nuevo usuario'}" />
<c:set var="seccion" value="usuarios" />
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <a class="app-volver" href="${ctx}/admin/usuarios.jsp">← Volver a usuarios</a>
    <h1><c:out value="${titulo}" /></h1>
</section>

<c:if test="${reintento}">
    <div class="alert alert-danger app-aviso" role="alert">
        <c:choose>
            <c:when test="${param.error == 'faltan-datos'}">Completa todos los campos obligatorios.</c:when>
            <c:when test="${param.error == 'sin-roles'}">Escoge al menos un rol.</c:when>
            <c:when test="${param.error == 'clave-requerida'}">Escribe una contraseña para el usuario nuevo.</c:when>
            <c:when test="${param.error == 'correo-duplicado'}">Ya existe un usuario con ese correo.</c:when>
            <c:when test="${param.error == 'correo-no-institucional'}">El correo debe ser institucional: @uts.edu.co o @correo.uts.edu.co.</c:when>
            <c:when test="${param.error == 'creditos-invalidos'}">El porcentaje de créditos debe ser un número entero entre 0 y 100.</c:when>
            <c:when test="${param.error == 'documento-duplicado'}">Ya existe un usuario con ese número de documento.</c:when>
            <c:when test="${param.error == 'admin-propio'}">No puedes quitarte el rol de Administrador ni desactivar tu propio usuario.</c:when>
            <c:otherwise>No se pudo guardar el usuario. Revisa los datos e inténtalo de nuevo.</c:otherwise>
        </c:choose>
    </div>
</c:if>

<form class="app-tarjeta app-formulario" method="post" action="${ctx}/admin/usuario-guardar.jsp">
    <c:if test="${editando}">
        <input type="hidden" name="id" value="${fn:escapeXml(param.id)}">
    </c:if>

    <h2 class="app-tarjeta-titulo">Datos personales</h2>
    <div class="row g-3">
        <div class="col-12">
            <label class="form-label" for="nombre">Nombre completo *</label>
            <input class="form-control" type="text" id="nombre" name="nombre" maxlength="150" value="${fn:escapeXml(vNombre)}" required>
        </div>
        <div class="col-md-5">
            <label class="form-label" for="tipo_documento">Tipo de documento *</label>
            <select class="form-select" id="tipo_documento" name="tipo_documento" required>
                <c:forEach var="t" items="${tiposDocumento.rows}">
                    <c:set var="idTipo">${t.id}</c:set>
                    <c:set var="tipoElegido">${vTipoDoc}</c:set>
                    <option value="${t.id}" ${idTipo == tipoElegido ? 'selected' : ''}><c:out value="${t.nombre}" /></option>
                </c:forEach>
            </select>
        </div>
        <div class="col-md-7">
            <label class="form-label" for="numero_documento">Número de documento *</label>
            <input class="form-control" type="text" id="numero_documento" name="numero_documento" maxlength="20" value="${fn:escapeXml(vDocumento)}" required>
        </div>
        <div class="col-md-7">
            <label class="form-label" for="correo">Correo *</label>
            <input class="form-control" type="email" id="correo" name="correo" maxlength="150" value="${fn:escapeXml(vCorreo)}"
                   pattern=".+@(uts\.edu\.co|correo\.uts\.edu\.co)" title="Debe ser un correo @uts.edu.co o @correo.uts.edu.co" required>
            <div class="form-text">Correo institucional (@uts.edu.co o @correo.uts.edu.co). Con este correo inicia sesión.</div>
        </div>
        <div class="col-md-5">
            <label class="form-label" for="celular">Celular</label>
            <input class="form-control" type="tel" id="celular" name="celular" maxlength="20" value="${fn:escapeXml(vCelular)}">
        </div>
        <div class="col-md-7">
            <label class="form-label" for="clave">Contraseña ${editando ? '' : '*'}</label>
            <input class="form-control" type="password" id="clave" name="clave" autocomplete="new-password" ${editando ? '' : 'required'}>
            <c:if test="${editando}">
                <div class="form-text">Déjala vacía para no cambiarla.</div>
            </c:if>
        </div>
    </div>

    <h2 class="app-tarjeta-titulo mt-4">Roles *</h2>
    <div class="app-casillas">
        <c:forEach var="r" items="${listaRoles.rows}">
            <c:set var="marca">|${r.id}|</c:set>
            <label class="app-casilla">
                <input type="checkbox" name="roles" value="${r.id}" ${fn:contains(rolesMarcados, marca) ? 'checked' : ''} ${r.id == 5 ? 'data-estudiante="true"' : ''}>
                <span><c:out value="${r.nombre}" /></span>
            </label>
        </c:forEach>
    </div>

    <div id="datosEstudiante" class="mt-4">
        <h2 class="app-tarjeta-titulo">Datos del estudiante</h2>
        <div class="row g-3">
            <div class="col-12">
                <label class="form-label" for="carrera">Carrera</label>
                <c:set var="carreraElegida" value="${vCarrera}" />
                <c:set var="carreraRequerida" value="false" />
                <%@ include file="/WEB-INF/jspf/selector-carrera.jspf" %>
                <div class="form-text">El nivel (tecnológico o universitario) sale de la carrera.</div>
            </div>
            <div class="col-md-5">
                <label class="form-label" for="porcentaje_creditos">Créditos aprobados (%)</label>
                <input class="form-control" type="number" id="porcentaje_creditos" name="porcentaje_creditos" min="0" max="100" step="1" value="${fn:escapeXml(vCreditos)}">
                <div class="form-text">Para la fase 1, en los planes anteriores: 75 % y Metodología aprobada.</div>
            </div>
            <div class="col-md-7">
                <label class="form-label" for="plan_estudios">Plan de estudios</label>
                <select class="form-select" id="plan_estudios" name="plan_estudios">
                    <option value="">Sin plan</option>
                    <option value="Anterior" ${vPlan == 'Anterior' ? 'selected' : ''}>Anterior al decreto 1330 de 2019</option>
                    <option value="Nuevo" ${vPlan == 'Nuevo' ? 'selected' : ''}>Posterior al decreto 1330 de 2019</option>
                </select>
            </div>
            <div class="col-12">
                <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" role="switch" id="metodologia" name="metodologia" ${vMetodologia ? 'checked' : ''}>
                    <label class="form-check-label" for="metodologia">Aprobó Metodología de la investigación (o un curso equivalente)</label>
                </div>
            </div>
        </div>
    </div>

    <c:if test="${editando}">
        <div class="form-check form-switch mt-4">
            <input class="form-check-input" type="checkbox" role="switch" id="activo" name="activo" ${vActivo ? 'checked' : ''}>
            <label class="form-check-label" for="activo">Usuario activo (si está inactivo, no puede iniciar sesión)</label>
        </div>
    </c:if>

    <div class="app-formulario-botones">
        <a class="btn btn-outline-dark rounded-pill app-boton" href="${ctx}/admin/usuarios.jsp">Cancelar</a>
        <button type="submit" class="btn btn-primary rounded-pill app-boton">Guardar</button>
    </div>
</form>

<script>
    // Muestra los datos del estudiante solo si está marcado el rol Estudiante
    (function () {
        var casilla = document.querySelector('input[data-estudiante]');
        var bloque = document.getElementById('datosEstudiante');
        if (!casilla || !bloque) { return; }
        function actualizar() { bloque.hidden = !casilla.checked; }
        casilla.addEventListener('change', actualizar);
        actualizar();
    })();
</script>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
