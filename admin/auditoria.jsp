<%-- Auditoría (RNF12): todos los movimientos de los proyectos, del más reciente al más
     antiguo, con filtros por usuario (nombre o correo), proyecto (título o código), tipo
     de acción y rango de fechas (aaaa-mm-dd). Muestra hasta 300 movimientos. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:set var="titulo" value="Auditoría" />
<c:set var="seccion" value="auditoria" />

<c:set var="fUsuario" value="${fn:trim(param.usuario)}" />
<c:set var="fProyecto" value="${fn:trim(param.proyecto)}" />
<c:set var="fAccion" value="${fn:trim(param.accion)}" />
<c:set var="fDesde" value="${fn:trim(param.desde)}" />
<c:set var="fHasta" value="${fn:trim(param.hasta)}" />

<sql:query var="movimientos">
    SELECT h.fecha, h.accion, h.descripcion, u.nombre AS usuario, u.correo, p.id AS proyecto_id, p.titulo, p.codigo
    FROM historial h
    JOIN proyectos p ON p.id = h.proyecto_id
    LEFT JOIN usuarios u ON u.id = h.usuario_id
    WHERE (? = '' OR u.nombre LIKE CONCAT('%', ?, '%') OR u.correo LIKE CONCAT('%', ?, '%'))
      AND (? = '' OR p.titulo LIKE CONCAT('%', ?, '%') OR p.codigo LIKE CONCAT('%', ?, '%'))
      AND (? = '' OR h.accion = ?)
      AND (? = '' OR DATE(h.fecha) >= ?)
      AND (? = '' OR DATE(h.fecha) <= ?)
    ORDER BY h.fecha DESC, h.id DESC
    LIMIT 300
    <sql:param value="${fUsuario}" /><sql:param value="${fUsuario}" /><sql:param value="${fUsuario}" />
    <sql:param value="${fProyecto}" /><sql:param value="${fProyecto}" /><sql:param value="${fProyecto}" />
    <sql:param value="${fAccion}" /><sql:param value="${fAccion}" />
    <sql:param value="${fDesde}" /><sql:param value="${fDesde}" />
    <sql:param value="${fHasta}" /><sql:param value="${fHasta}" />
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <h1>Auditoría</h1>
    <p>Quién hizo cada movimiento de los proyectos, qué y cuándo.</p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="app-tarjeta">
    <form class="app-filtros" method="get" action="${ctx}/admin/auditoria.jsp">
        <input type="search" class="form-control" name="usuario" value="${fn:escapeXml(fUsuario)}" placeholder="Usuario (nombre o correo)" aria-label="Usuario">
        <input type="search" class="form-control" name="proyecto" value="${fn:escapeXml(fProyecto)}" placeholder="Proyecto (título o código)" aria-label="Proyecto">
        <select class="form-select" name="accion" aria-label="Tipo de acción">
            <option value="">Todas las acciones</option>
            <c:forEach var="x" items="Estado,Fase,Documento,Evaluación,Decisión,Modalidad,Otro">
                <option value="${x}" ${fAccion == x ? 'selected' : ''}><c:out value="${x}" /></option>
            </c:forEach>
        </select>
        <input type="date" class="form-control" name="desde" value="${fn:escapeXml(fDesde)}" aria-label="Desde">
        <input type="date" class="form-control" name="hasta" value="${fn:escapeXml(fHasta)}" aria-label="Hasta">
        <button type="submit" class="btn btn-primary rounded-pill">Filtrar</button>
    </form>

    <c:choose>
        <c:when test="${movimientos.rowCount == 0}">
            <p class="app-vacio">No hay movimientos con esos filtros.</p>
        </c:when>
        <c:otherwise>
            <div class="table-responsive">
                <table class="table app-tabla align-middle">
                    <thead>
                        <tr><th>Fecha</th><th>Usuario</th><th>Proyecto</th><th>Acción</th><th>Movimiento</th></tr>
                    </thead>
                    <tbody>
                        <c:forEach var="m" items="${movimientos.rows}">
                            <tr>
                                <td class="text-nowrap"><fmt:formatDate value="${m.fecha}" pattern="dd/MM/yyyy HH:mm" /></td>
                                <td><c:out value="${empty m.usuario ? 'Sistema' : m.usuario}" /></td>
                                <td>
                                    <a href="${ctx}/admin/proyecto.jsp?id=${m.proyecto_id}"><c:out value="${m.titulo}" /></a>
                                    <c:if test="${not empty m.codigo}"><span class="app-lista-nota"><c:out value="${m.codigo}" /></span></c:if>
                                </td>
                                <td><c:out value="${m.accion}" /></td>
                                <td><c:out value="${m.descripcion}" /></td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
            <p class="app-total">${movimientos.rowCount} ${movimientos.rowCount == 1 ? 'movimiento' : 'movimientos'}${movimientos.rowCount == 300 ? ' (los 300 más recientes)' : ''}</p>
        </c:otherwise>
    </c:choose>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
