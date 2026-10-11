<%-- Lista de usuarios del administrador (RF7): búsqueda por nombre, correo, documento
     o carrera, y filtros por rol, nivel, plan de estudios y estado. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:set var="titulo" value="Usuarios" />
<c:set var="seccion" value="usuarios" />

<c:set var="texto" value="${fn:trim(param.q)}" />
<c:set var="rolFiltro" value="${fn:trim(param.rol)}" />
<c:set var="nivelFiltro" value="${fn:trim(param.nivel)}" />
<c:set var="planFiltro" value="${fn:trim(param.plan)}" />
<c:set var="estadoFiltro" value="${fn:trim(param.estado)}" />
<c:set var="hayFiltros" value="${not empty texto or not empty rolFiltro or not empty nivelFiltro or not empty planFiltro or not empty estadoFiltro}" />

<sql:query var="listaRoles">SELECT id, nombre FROM roles ORDER BY id</sql:query>
<sql:query var="listaNiveles">SELECT id, nombre FROM niveles ORDER BY id</sql:query>

<sql:query var="usuarios">
    SELECT u.id, u.nombre, u.correo, u.numero_documento, td.sigla, u.activo,
           GROUP_CONCAT(r.nombre ORDER BY r.id SEPARATOR ', ') AS roles
    FROM usuarios u
    JOIN tipos_documentos td ON td.id = u.tipo_documento_id
    LEFT JOIN carreras ca ON ca.id = u.carrera_id
    LEFT JOIN usuario_roles ur ON ur.usuario_id = u.id
    LEFT JOIN roles r ON r.id = ur.rol_id
    WHERE (? = '' OR u.nombre LIKE CONCAT('%', ?, '%') OR u.correo LIKE CONCAT('%', ?, '%')
           OR u.numero_documento LIKE CONCAT('%', ?, '%') OR ca.nombre LIKE CONCAT('%', ?, '%'))
      AND (? = '' OR u.id IN (SELECT usuario_id FROM usuario_roles WHERE rol_id = ?))
      AND (? = '' OR u.nivel_id = ?)
      AND (? = '' OR u.plan_estudios = ?)
      AND (? = '' OR u.activo = (? = 'activo'))
    GROUP BY u.id, u.nombre, u.correo, u.numero_documento, td.sigla, u.activo
    ORDER BY u.nombre
    <sql:param value="${texto}" />
    <sql:param value="${texto}" />
    <sql:param value="${texto}" />
    <sql:param value="${texto}" />
    <sql:param value="${texto}" />
    <sql:param value="${rolFiltro}" />
    <sql:param value="${rolFiltro}" />
    <sql:param value="${nivelFiltro}" />
    <sql:param value="${nivelFiltro}" />
    <sql:param value="${planFiltro}" />
    <sql:param value="${planFiltro}" />
    <sql:param value="${estadoFiltro}" />
    <sql:param value="${estadoFiltro}" />
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado app-encabezado-acciones">
    <div>
        <h1>Usuarios</h1>
        <p>Aquí se registran los docentes. Los estudiantes se registran solos; aquí se actualizan sus datos académicos.</p>
    </div>
    <a class="btn btn-primary rounded-pill app-boton" href="${ctx}/admin/usuario-form.jsp">Nuevo usuario</a>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="app-tarjeta">
    <form class="app-filtros" method="get" action="${ctx}/admin/usuarios.jsp">
        <input type="search" class="form-control" name="q" value="${fn:escapeXml(texto)}" placeholder="Buscar por nombre, correo, documento o carrera" aria-label="Buscar">
        <select class="form-select" name="rol" aria-label="Filtrar por rol">
            <option value="">Todos los roles</option>
            <c:forEach var="r" items="${listaRoles.rows}">
                <c:set var="idRol">${r.id}</c:set>
                <option value="${r.id}" ${idRol == rolFiltro ? 'selected' : ''}><c:out value="${r.nombre}" /></option>
            </c:forEach>
        </select>
        <select class="form-select" name="nivel" aria-label="Filtrar por nivel">
            <option value="">Todos los niveles</option>
            <c:forEach var="n" items="${listaNiveles.rows}">
                <c:set var="idNivel">${n.id}</c:set>
                <option value="${n.id}" ${idNivel == nivelFiltro ? 'selected' : ''}><c:out value="${n.nombre}" /></option>
            </c:forEach>
        </select>
        <select class="form-select" name="plan" aria-label="Filtrar por plan de estudios">
            <option value="">Todos los planes</option>
            <option value="Anterior" ${planFiltro == 'Anterior' ? 'selected' : ''}>Plan anterior</option>
            <option value="Nuevo" ${planFiltro == 'Nuevo' ? 'selected' : ''}>Plan nuevo</option>
        </select>
        <select class="form-select" name="estado" aria-label="Filtrar por estado">
            <option value="">Activos e inactivos</option>
            <option value="activo" ${estadoFiltro == 'activo' ? 'selected' : ''}>Activos</option>
            <option value="inactivo" ${estadoFiltro == 'inactivo' ? 'selected' : ''}>Inactivos</option>
        </select>
        <button type="submit" class="btn btn-dark rounded-pill">Buscar</button>
        <c:if test="${hayFiltros}">
            <a class="app-limpiar" href="${ctx}/admin/usuarios.jsp">Limpiar</a>
        </c:if>
    </form>

    <c:choose>
        <c:when test="${usuarios.rowCount == 0}">
            <p class="app-vacio">No se encontraron usuarios.</p>
        </c:when>
        <c:otherwise>
            <div class="table-responsive">
                <table class="table app-tabla align-middle">
                    <thead>
                        <tr>
                            <th>Nombre</th>
                            <th>Correo</th>
                            <th>Documento</th>
                            <th>Roles</th>
                            <th>Estado</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="u" items="${usuarios.rows}">
                            <tr>
                                <td class="fw-semibold"><c:out value="${u.nombre}" /></td>
                                <td><c:out value="${u.correo}" /></td>
                                <td><c:out value="${u.sigla}" /> <c:out value="${u.numero_documento}" /></td>
                                <td><c:out value="${empty u.roles ? 'Sin rol' : u.roles}" /></td>
                                <td>
                                    <c:choose>
                                        <c:when test="${u.activo}"><span class="app-estado activo">Activo</span></c:when>
                                        <c:otherwise><span class="app-estado inactivo">Inactivo</span></c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="text-end app-acciones">
                                    <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/admin/usuario-form.jsp?id=${u.id}">Editar</a>
                                    <c:if test="${u.id != sessionScope.usuario.id}">
                                        <form method="post" action="${ctx}/admin/usuario-eliminar.jsp" class="d-inline"
                                              onsubmit="return confirm('¿Eliminar este usuario? Esta acción no se puede deshacer.');">
                                            <input type="hidden" name="id" value="${u.id}">
                                            <button type="submit" class="btn btn-sm btn-outline-danger rounded-pill">Eliminar</button>
                                        </form>
                                    </c:if>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
            <p class="app-total">${usuarios.rowCount} ${usuarios.rowCount == 1 ? 'usuario' : 'usuarios'}</p>
        </c:otherwise>
    </c:choose>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
