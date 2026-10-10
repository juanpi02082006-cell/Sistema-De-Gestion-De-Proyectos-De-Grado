<%-- Proyectos (RF9), para el comité (el administrador): la fase de cada uno, el estado
     del pago (RF32) y el director. Desde aquí se abre cada proyecto para revisar el
     pago y asignar director y evaluador (RF11). Filtros: ?filtro=pago (pagos por
     revisar), ?filtro=director (sin director) o ?filtro=evaluador (sin evaluador en las
     fases 2 a 4: el director no puede enviarle la propuesta). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<c:set var="titulo" value="Proyectos" />
<c:set var="seccion" value="proyectos" />
<c:set var="filtro" value="${param.filtro == 'pago' or param.filtro == 'director' or param.filtro == 'evaluador' ? param.filtro : ''}" />

<sql:query var="proyectos">
    SELECT * FROM (
        SELECT p.id, p.titulo, p.estado, p.evaluador_id, f.orden AS fase, f.nombre AS nombre_fase,
               m.nombre AS modalidad, n.nombre AS nivel, pr.nombre AS periodo, d.nombre AS director,
               (SELECT GROUP_CONCAT(u.nombre ORDER BY u.nombre SEPARATOR ', ')
                FROM proyecto_estudiantes pe JOIN usuarios u ON u.id = pe.estudiante_id
                WHERE pe.proyecto_id = p.id AND pe.vigente = 1) AS estudiantes,
               ${sqlEstadoPago} AS estado_pago
        FROM proyectos p
        JOIN modalidades m ON m.id = p.modalidad_id
        JOIN niveles n ON n.id = p.nivel_id
        LEFT JOIN fases f ON f.id = p.fase_id
        LEFT JOIN periodos pr ON pr.id = p.periodo_id
        LEFT JOIN usuarios d ON d.id = p.director_id
    ) t
    WHERE (? = '' OR (? = 'pago' AND estado_pago = 'Por revisar') OR (? = 'director' AND director IS NULL)
           OR (? = 'evaluador' AND evaluador_id IS NULL AND fase BETWEEN 2 AND 4))
    ORDER BY fase, titulo
    <sql:param value="${filtro}" />
    <sql:param value="${filtro}" />
    <sql:param value="${filtro}" />
    <sql:param value="${filtro}" />
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <h1>Proyectos</h1>
    <p>Revisa el pago de la fase 1 y asigna el director y el evaluador de cada proyecto.</p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="app-tarjeta">
    <form class="app-filtros" method="get" action="${ctx}/admin/proyectos.jsp">
        <select class="form-select" name="filtro" aria-label="Filtrar proyectos" onchange="this.form.submit()">
            <option value="">Todos los proyectos</option>
            <option value="pago" ${filtro == 'pago' ? 'selected' : ''}>Pagos por revisar</option>
            <option value="director" ${filtro == 'director' ? 'selected' : ''}>Sin director</option>
            <option value="evaluador" ${filtro == 'evaluador' ? 'selected' : ''}>Sin evaluador (fases 2 a 4)</option>
        </select>
        <noscript><button type="submit" class="btn btn-outline-dark rounded-pill">Filtrar</button></noscript>
    </form>

    <c:choose>
        <c:when test="${proyectos.rowCount == 0}">
            <p class="app-vacio">${empty filtro ? 'Todavía no hay proyectos. Se crean cuando un estudiante toma una idea aprobada del banco.' : 'No hay proyectos con ese filtro.'}</p>
        </c:when>
        <c:otherwise>
            <div class="table-responsive">
                <table class="table app-tabla align-middle">
                    <thead>
                        <tr>
                            <th>Proyecto</th>
                            <th>Estudiantes</th>
                            <th>Fase</th>
                            <th>Pago</th>
                            <th>Director</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="p" items="${proyectos.rows}">
                            <tr>
                                <td>
                                    <span class="fw-semibold"><c:out value="${p.titulo}" /></span>
                                    <span class="app-lista-nota"><c:out value="${p.modalidad}" /> · <c:out value="${p.nivel}" /><c:if test="${not empty p.periodo}"> · <c:out value="${p.periodo}" /></c:if></span>
                                </td>
                                <td><c:out value="${p.estudiantes}" /></td>
                                <td class="text-nowrap">
                                    <c:choose><c:when test="${p.fase == 6}">Fase final</c:when><c:otherwise>Fase <c:out value="${p.fase}" /></c:otherwise></c:choose>
                                    <span class="app-lista-nota"><c:out value="${p.nombre_fase}" /></span>
                                </td>
                                <td class="text-nowrap"><span class="app-estado ${p.estado_pago == 'Aprobado' or p.estado_pago == 'Por revisar' ? 'activo' : 'inactivo'}"><c:out value="${p.estado_pago}" /></span></td>
                                <td><c:out value="${empty p.director ? 'Sin asignar' : p.director}" /></td>
                                <td class="text-end app-acciones">
                                    <a class="btn btn-sm ${p.estado_pago == 'Por revisar' or empty p.director ? 'btn-primary' : 'btn-outline-dark'} rounded-pill" href="${ctx}/admin/proyecto.jsp?id=${p.id}">${p.estado_pago == 'Por revisar' ? 'Revisar pago' : (empty p.director ? 'Asignar director' : 'Ver')}</a>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
            <p class="app-total">${proyectos.rowCount} ${proyectos.rowCount == 1 ? 'proyecto' : 'proyectos'}</p>
        </c:otherwise>
    </c:choose>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
