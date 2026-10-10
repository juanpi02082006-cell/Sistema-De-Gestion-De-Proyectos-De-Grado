<%-- Lista de roles del administrador (punto 3). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:set var="titulo" value="Roles" />
<c:set var="seccion" value="roles" />

<sql:query var="roles">
    SELECT r.id, r.nombre, r.descripcion, COUNT(ur.usuario_id) AS usuarios
    FROM roles r
    LEFT JOIN usuario_roles ur ON ur.rol_id = r.id
    GROUP BY r.id, r.nombre, r.descripcion
    ORDER BY r.id
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado app-encabezado-acciones">
    <div>
        <h1>Roles</h1>
        <p>Los 4 roles base (Administrador, Director, Evaluador y Estudiante) no se pueden eliminar. El administrador es el comité de trabajos de grado.</p>
    </div>
    <a class="btn btn-primary rounded-pill app-boton" href="${ctx}/admin/rol-form.jsp">Nuevo rol</a>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="app-tarjeta">
    <div class="table-responsive">
        <table class="table app-tabla align-middle">
            <thead>
                <tr>
                    <th>Rol</th>
                    <th>Descripción</th>
                    <th>Usuarios</th>
                    <th class="text-end">Acciones</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach var="r" items="${roles.rows}">
                    <tr>
                        <td class="fw-semibold">
                            <c:out value="${r.nombre}" />
                            <c:if test="${r.id <= 5}"><span class="app-etiqueta">Base</span></c:if>
                        </td>
                        <td><c:out value="${r.descripcion}" /></td>
                        <td><c:out value="${r.usuarios}" /></td>
                        <td class="text-end app-acciones">
                            <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/admin/rol-form.jsp?id=${r.id}">Editar</a>
                            <c:if test="${r.id > 5}">
                                <form method="post" action="${ctx}/admin/rol-eliminar.jsp" class="d-inline"
                                      onsubmit="return confirm('¿Eliminar este rol? Esta acción no se puede deshacer.');">
                                    <input type="hidden" name="id" value="${r.id}">
                                    <button type="submit" class="btn btn-sm btn-outline-danger rounded-pill">Eliminar</button>
                                </form>
                            </c:if>
                        </td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>
    </div>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
