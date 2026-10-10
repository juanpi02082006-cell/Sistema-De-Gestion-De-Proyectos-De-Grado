<%-- Crear (sin id) o editar (con ?id=) un rol (punto 3). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>

<c:set var="editando" value="${not empty param.id}" />
<c:set var="reintento" value="${not empty param.error}" />

<c:if test="${editando}">
    <sql:query var="consultaRol">
        SELECT id, nombre, descripcion FROM roles WHERE id = ?
        <sql:param value="${param.id}" />
    </sql:query>
    <c:if test="${consultaRol.rowCount == 0}">
        <c:redirect url="/admin/roles.jsp">
            <c:param name="error" value="no-encontrado" />
        </c:redirect>
    </c:if>
    <c:set var="rol" value="${consultaRol.rows[0]}" />
</c:if>

<c:set var="vNombre" value="${reintento ? param.nombre : rol.nombre}" />
<c:set var="vDescripcion" value="${reintento ? param.descripcion : rol.descripcion}" />

<c:set var="titulo" value="${editando ? 'Editar rol' : 'Nuevo rol'}" />
<c:set var="seccion" value="roles" />
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <a class="app-volver" href="${ctx}/admin/roles.jsp">← Volver a roles</a>
    <h1><c:out value="${titulo}" /></h1>
</section>

<c:if test="${reintento}">
    <div class="alert alert-danger app-aviso" role="alert">
        <c:choose>
            <c:when test="${param.error == 'faltan-datos'}">Escribe el nombre del rol.</c:when>
            <c:when test="${param.error == 'nombre-duplicado'}">Ya existe un rol con ese nombre.</c:when>
            <c:otherwise>No se pudo guardar el rol. Inténtalo de nuevo.</c:otherwise>
        </c:choose>
    </div>
</c:if>

<form class="app-tarjeta app-formulario" method="post" action="${ctx}/admin/rol-guardar.jsp">
    <c:if test="${editando}">
        <input type="hidden" name="id" value="${fn:escapeXml(param.id)}">
    </c:if>
    <div class="row g-3">
        <div class="col-md-6">
            <label class="form-label" for="nombre">Nombre *</label>
            <input class="form-control" type="text" id="nombre" name="nombre" maxlength="30" value="${fn:escapeXml(vNombre)}" required>
        </div>
        <div class="col-12">
            <label class="form-label" for="descripcion">Descripción</label>
            <input class="form-control" type="text" id="descripcion" name="descripcion" maxlength="255" value="${fn:escapeXml(vDescripcion)}">
        </div>
    </div>
    <div class="app-formulario-botones">
        <a class="btn btn-outline-dark rounded-pill app-boton" href="${ctx}/admin/roles.jsp">Cancelar</a>
        <button type="submit" class="btn btn-primary rounded-pill app-boton">Guardar</button>
    </div>
</form>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
