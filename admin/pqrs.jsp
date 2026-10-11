<%-- PQR para el comité (RNF1): las responde (la respuesta es obligatoria) y ve el
     reporte con la cantidad por tipo y por estado. Filtros: ?estado= y ?tipo=. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:set var="titulo" value="PQR" />
<c:set var="seccion" value="pqrs" />
<c:set var="fEstado" value="${param.estado == 'Respondida' or param.estado == 'Todas' ? param.estado : 'Pendiente'}" />
<c:set var="fTipo" value="${fn:trim(param.tipo)}" />

<sql:query var="pqrs">
    SELECT q.id, q.tipo, q.comentario, q.estado, q.respuesta, q.creado_en, q.respondida_en,
           u.nombre AS autor, u.correo, p.id AS proyecto_id, p.titulo AS proyecto, r.nombre AS respondio
    FROM pqrs q
    JOIN usuarios u ON u.id = q.usuario_id
    LEFT JOIN proyectos p ON p.id = q.proyecto_id
    LEFT JOIN usuarios r ON r.id = q.respondida_por
    WHERE (? = 'Todas' OR q.estado = ?) AND (? = '' OR q.tipo = ?)
    ORDER BY q.creado_en DESC, q.id DESC
    <sql:param value="${fEstado}" /><sql:param value="${fEstado}" />
    <sql:param value="${fTipo}" /><sql:param value="${fTipo}" />
</sql:query>
<sql:query var="reporte">
    SELECT tipo, SUM(estado = 'Pendiente') AS pendientes, SUM(estado = 'Respondida') AS respondidas, COUNT(*) AS total
    FROM pqrs GROUP BY tipo ORDER BY tipo
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <h1>PQR</h1>
    <p>Peticiones, quejas y reclamos de los usuarios. Al responder, le llega un aviso a quien la escribió.</p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="app-tarjeta mb-4">
    <h2 class="app-tarjeta-titulo">Reporte</h2>
    <c:choose>
        <c:when test="${reporte.rowCount == 0}"><p class="app-vacio mt-0">Todavía no hay PQR.</p></c:when>
        <c:otherwise>
            <div class="table-responsive">
                <table class="table app-tabla align-middle mb-0">
                    <thead><tr><th>Tipo</th><th>Pendientes</th><th>Respondidas</th><th>Total</th></tr></thead>
                    <tbody>
                        <c:forEach var="t" items="${reporte.rows}">
                            <tr><td><c:out value="${t.tipo}" /></td><td><c:out value="${t.pendientes}" /></td><td><c:out value="${t.respondidas}" /></td><td><c:out value="${t.total}" /></td></tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<div class="app-tarjeta">
    <form class="app-filtros" method="get" action="${ctx}/admin/pqrs.jsp">
        <select class="form-select" name="estado" aria-label="Estado" onchange="this.form.submit()">
            <option value="Pendiente" ${fEstado == 'Pendiente' ? 'selected' : ''}>Pendientes</option>
            <option value="Respondida" ${fEstado == 'Respondida' ? 'selected' : ''}>Respondidas</option>
            <option value="Todas" ${fEstado == 'Todas' ? 'selected' : ''}>Todas</option>
        </select>
        <select class="form-select" name="tipo" aria-label="Tipo" onchange="this.form.submit()">
            <option value="">Todos los tipos</option>
            <c:forEach var="t" items="Petición,Queja,Reclamo,Cambio de director,Cambio de evaluador">
                <option value="${t}" ${fTipo == t ? 'selected' : ''}><c:out value="${t}" /></option>
            </c:forEach>
        </select>
        <noscript><button type="submit" class="btn btn-outline-dark rounded-pill">Filtrar</button></noscript>
    </form>
    <c:choose>
        <c:when test="${pqrs.rowCount == 0}"><p class="app-vacio">No hay PQR con ese filtro.</p></c:when>
        <c:otherwise>
            <ul class="app-lista">
                <c:forEach var="q" items="${pqrs.rows}">
                    <li class="d-block">
                        <span class="d-flex justify-content-between gap-2">
                            <span class="app-lista-dato"><c:out value="${q.tipo}" /> · <c:out value="${q.autor}" /></span>
                            <span class="app-estado ${q.estado == 'Respondida' ? 'activo' : 'inactivo'}"><c:out value="${q.estado}" /></span>
                        </span>
                        <span class="app-lista-nota">
                            <c:out value="${q.correo}" /> · <fmt:formatDate value="${q.creado_en}" pattern="dd/MM/yyyy HH:mm" />
                            <c:if test="${not empty q.proyecto}"> · <a href="${ctx}/admin/proyecto.jsp?id=${q.proyecto_id}"><c:out value="${q.proyecto}" /></a></c:if>
                        </span>
                        <p class="mb-0 mt-2"><c:out value="${q.comentario}" /></p>
                        <c:choose>
                            <c:when test="${q.estado == 'Respondida'}">
                                <p class="app-observacion"><strong>Respuesta:</strong> <c:out value="${q.respuesta}" />
                                    <span class="app-lista-nota"><c:out value="${q.respondio}" />, <fmt:formatDate value="${q.respondida_en}" pattern="dd/MM/yyyy HH:mm" /></span></p>
                            </c:when>
                            <c:otherwise>
                                <form class="app-revision" method="post" action="${ctx}/admin/pqr-responder.jsp">
                                    <input type="hidden" name="id" value="${q.id}">
                                    <textarea class="form-control" name="respuesta" placeholder="Respuesta del comité (obligatoria)" aria-label="Respuesta" required></textarea>
                                    <button type="submit" class="btn btn-sm btn-primary rounded-pill">Responder</button>
                                </form>
                            </c:otherwise>
                        </c:choose>
                    </li>
                </c:forEach>
            </ul>
        </c:otherwise>
    </c:choose>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
