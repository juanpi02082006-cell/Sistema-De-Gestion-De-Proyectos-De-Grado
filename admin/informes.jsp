<%-- Informes del comité (RF15; reglamento, art. 26): por periodo (el activo, si no se escoge
     otro, o todos), cuántos proyectos y estudiantes hay en cada modalidad y cómo van (en
     curso, finalizados, cancelados), cuántos proyectos tienen 1, 2, 3 o 4 estudiantes, y los
     listados de los estudiantes que aprobaron y de los que no (decisión del 2026-10-17):
       aprobados     proyecto finalizado (informe final aprobado y aprobación final, Seminario
                     con 3.0 o más) o exonerados por Saber TyT sin renuncia;
       no aprobados  proyecto cancelado (propuesta no aprobada, semana 12, plazo del informe
                     vencido o Seminario reprobado), con el último movimiento del historial.
     Cuenta a los estudiantes que siguen en el proyecto, aunque esté cancelado; no a los que
     quitaron. Se puede imprimir (estilo.css oculta el menú y los filtros). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:set var="titulo" value="Informes" />
<c:set var="seccion" value="informes" />

<sql:query var="periodos">SELECT id, nombre, estado FROM periodos ORDER BY fecha_inicio_semestre DESC, id DESC</sql:query>
<%-- Periodo: el que llegue si existe; sin ?periodo, el activo; si no, todos --%>
<c:set var="fPeriodo" value="todos" />
<c:set var="nombrePeriodo" value="Todos los periodos" />
<c:if test="${param.periodo != 'todos'}">
    <c:forEach var="o" items="${periodos.rows}">
        <c:set var="x">${o.id}</c:set>
        <c:if test="${(empty param.periodo and o.estado == 'Activo') or x == param.periodo}">
            <c:set var="fPeriodo" value="${x}" />
            <c:set var="nombrePeriodo" value="Periodo ${o.nombre}" />
        </c:if>
    </c:forEach>
</c:if>

<sql:query var="resumen">
    SELECT COUNT(*) AS proyectos,
           COALESCE(SUM(p.estado IN ('Pendiente', 'En curso')), 0) AS en_curso,
           COALESCE(SUM(p.estado = 'Finalizado'), 0) AS finalizados,
           COALESCE(SUM(p.estado = 'Cancelado'), 0) AS cancelados,
           (SELECT COUNT(DISTINCT pe.estudiante_id) FROM proyecto_estudiantes pe JOIN proyectos p2 ON p2.id = pe.proyecto_id
            WHERE pe.estado = 'Activo' AND (? = 'todos' OR p2.periodo_id = ?)) AS estudiantes
    FROM proyectos p
    WHERE ? = 'todos' OR p.periodo_id = ?
    <sql:param value="${fPeriodo}" /><sql:param value="${fPeriodo}" />
    <sql:param value="${fPeriodo}" /><sql:param value="${fPeriodo}" />
</sql:query>
<c:set var="r" value="${resumen.rows[0]}" />

<sql:query var="porModalidad">
    SELECT m.nombre, COUNT(p.id) AS proyectos,
           COALESCE(SUM(p.estado IN ('Pendiente', 'En curso')), 0) AS en_curso,
           COALESCE(SUM(p.estado = 'Finalizado'), 0) AS finalizados,
           COALESCE(SUM(p.estado = 'Cancelado'), 0) AS cancelados,
           (SELECT COUNT(*) FROM proyecto_estudiantes pe JOIN proyectos p2 ON p2.id = pe.proyecto_id
            WHERE p2.modalidad_id = m.id AND pe.estado = 'Activo' AND (? = 'todos' OR p2.periodo_id = ?)) AS estudiantes
    FROM modalidades m
    LEFT JOIN proyectos p ON p.modalidad_id = m.id AND (? = 'todos' OR p.periodo_id = ?)
    GROUP BY m.id, m.nombre
    ORDER BY m.id
    <sql:param value="${fPeriodo}" /><sql:param value="${fPeriodo}" />
    <sql:param value="${fPeriodo}" /><sql:param value="${fPeriodo}" />
</sql:query>

<sql:query var="porCantidad">
    SELECT t.n AS estudiantes, COUNT(*) AS proyectos FROM (
        SELECT (SELECT COUNT(*) FROM proyecto_estudiantes pe WHERE pe.proyecto_id = p.id AND pe.estado = 'Activo') AS n
        FROM proyectos p WHERE ? = 'todos' OR p.periodo_id = ?
    ) t
    GROUP BY t.n ORDER BY t.n
    <sql:param value="${fPeriodo}" /><sql:param value="${fPeriodo}" />
</sql:query>

<sql:query var="aprobados">
    SELECT u.nombre, u.correo, td.sigla, u.numero_documento, c.nombre AS carrera, p.codigo, p.titulo,
           m.nombre AS modalidad, p.modalidad_id, p.nota_final, pe.exonerado, pe.renuncia_exoneracion, p.estado
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    JOIN usuarios u ON u.id = pe.estudiante_id
    JOIN modalidades m ON m.id = p.modalidad_id
    LEFT JOIN tipos_documentos td ON td.id = u.tipo_documento_id
    LEFT JOIN carreras c ON c.id = u.carrera_id
    WHERE pe.estado = 'Activo' AND (p.estado = 'Finalizado' OR (pe.exonerado = 1 AND pe.renuncia_exoneracion = 0))
      AND (? = 'todos' OR p.periodo_id = ?)
    ORDER BY u.nombre
    <sql:param value="${fPeriodo}" /><sql:param value="${fPeriodo}" />
</sql:query>

<sql:query var="noAprobados">
    SELECT u.nombre, u.correo, td.sigla, u.numero_documento, c.nombre AS carrera, p.codigo, p.titulo, m.nombre AS modalidad,
           p.modalidad_id, f.orden AS fase,
           (SELECT h.descripcion FROM historial h WHERE h.proyecto_id = p.id ORDER BY h.id DESC LIMIT 1) AS motivo
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    JOIN usuarios u ON u.id = pe.estudiante_id
    JOIN modalidades m ON m.id = p.modalidad_id
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN tipos_documentos td ON td.id = u.tipo_documento_id
    LEFT JOIN carreras c ON c.id = u.carrera_id
    WHERE pe.estado = 'Activo' AND p.estado = 'Cancelado' AND (? = 'todos' OR p.periodo_id = ?)
    ORDER BY u.nombre
    <sql:param value="${fPeriodo}" /><sql:param value="${fPeriodo}" />
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <h1>Informes</h1>
    <p>Estadísticas de las modalidades de grado y listados de los estudiantes que aprobaron y de los que no. <c:out value="${nombrePeriodo}" />.</p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="app-tarjeta mb-4 no-imprimir">
    <form class="app-filtros mb-0" method="get" action="${ctx}/admin/informes.jsp">
        <select class="form-select" name="periodo" aria-label="Periodo" onchange="this.form.submit()">
            <option value="todos" ${fPeriodo == 'todos' ? 'selected' : ''}>Todos los periodos</option>
            <c:forEach var="o" items="${periodos.rows}">
                <c:set var="x">${o.id}</c:set>
                <option value="${o.id}" ${x == fPeriodo ? 'selected' : ''}>Periodo <c:out value="${o.nombre}" />${o.estado == 'Activo' ? ' (activo)' : ''}</option>
            </c:forEach>
        </select>
        <noscript><button type="submit" class="btn btn-outline-dark rounded-pill">Ver</button></noscript>
        <button type="button" class="btn btn-outline-dark rounded-pill" onclick="window.print()">Imprimir</button>
    </form>
</div>

<div class="app-tarjeta mb-4">
    <h2 class="app-tarjeta-titulo">Resumen · <c:out value="${nombrePeriodo}" /></h2>
    <dl class="app-pares">
        <div><dt>Proyectos</dt><dd><c:out value="${r.proyectos}" /></dd></div>
        <div><dt>Estudiantes</dt><dd><c:out value="${r.estudiantes}" /></dd></div>
        <div><dt>En curso</dt><dd><c:out value="${r.en_curso}" /></dd></div>
        <div><dt>Finalizados</dt><dd><c:out value="${r.finalizados}" /></dd></div>
        <div><dt>Cancelados</dt><dd><c:out value="${r.cancelados}" /></dd></div>
        <div><dt>Estudiantes que aprobaron</dt><dd><c:out value="${aprobados.rowCount}" /></dd></div>
    </dl>
</div>

<div class="row g-4 mb-4">
    <div class="col-xl-8">
        <div class="app-tarjeta h-100">
            <h2 class="app-tarjeta-titulo">Por modalidad</h2>
            <div class="table-responsive">
                <table class="table app-tabla align-middle mb-0">
                    <thead>
                        <tr><th>Modalidad</th><th class="text-end">Proyectos</th><th class="text-end">Estudiantes</th><th class="text-end">En curso</th><th class="text-end">Finalizados</th><th class="text-end">Cancelados</th></tr>
                    </thead>
                    <tbody>
                        <c:forEach var="m" items="${porModalidad.rows}">
                            <tr>
                                <td><c:out value="${m.nombre}" /></td>
                                <td class="text-end"><c:out value="${m.proyectos}" /></td>
                                <td class="text-end"><c:out value="${m.estudiantes}" /></td>
                                <td class="text-end"><c:out value="${m.en_curso}" /></td>
                                <td class="text-end"><c:out value="${m.finalizados}" /></td>
                                <td class="text-end"><c:out value="${m.cancelados}" /></td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <div class="col-xl-4">
        <div class="app-tarjeta h-100">
            <h2 class="app-tarjeta-titulo">Por cantidad de estudiantes</h2>
            <c:choose>
                <c:when test="${porCantidad.rowCount == 0}"><p class="app-vacio mt-0">No hay proyectos en este periodo.</p></c:when>
                <c:otherwise>
                    <ul class="app-lista">
                        <c:forEach var="c" items="${porCantidad.rows}">
                            <li><span class="app-lista-dato">${c.estudiantes == 0 ? 'Sin estudiantes' : c.estudiantes}${c.estudiantes == 1 ? ' estudiante' : (c.estudiantes == 0 ? '' : ' estudiantes')}</span>
                                <span>${c.proyectos} ${c.proyectos == 1 ? 'proyecto' : 'proyectos'}</span></li>
                        </c:forEach>
                    </ul>
                </c:otherwise>
            </c:choose>
        </div>
    </div>
</div>

<div class="app-tarjeta mb-4">
    <h2 class="app-tarjeta-titulo">Estudiantes que aprobaron <span class="text-secondary fw-normal">· <c:out value="${aprobados.rowCount}" /></span></h2>
    <c:choose>
        <c:when test="${aprobados.rowCount == 0}"><p class="app-vacio mt-0">Todavía no hay estudiantes que hayan aprobado en este periodo.</p></c:when>
        <c:otherwise>
            <div class="table-responsive">
                <table class="table app-tabla align-middle mb-0">
                    <thead><tr><th>Estudiante</th><th>Carrera</th><th>Proyecto</th><th>Cómo aprobó</th></tr></thead>
                    <tbody>
                        <c:forEach var="a" items="${aprobados.rows}">
                            <tr>
                                <td><span class="fw-semibold"><c:out value="${a.nombre}" /></span>
                                    <span class="app-lista-nota"><c:out value="${a.sigla}" /> <c:out value="${a.numero_documento}" /> · <c:out value="${a.correo}" /></span></td>
                                <td><c:out value="${empty a.carrera ? '—' : a.carrera}" /></td>
                                <td><c:out value="${a.titulo}" /><span class="app-lista-nota"><c:out value="${a.codigo}" /> · <c:out value="${a.modalidad}" /></span></td>
                                <td>
                                    <c:choose>
                                        <c:when test="${a.exonerado == true}">Exonerado por Saber TyT</c:when>
                                        <c:when test="${a.modalidad_id == 5}">Seminario aprobado<c:if test="${not empty a.nota_final}"> con <fmt:formatNumber value="${a.nota_final}" minFractionDigits="1" maxFractionDigits="1" /></c:if></c:when>
                                        <c:otherwise>Informe final aprobado y sustentado</c:otherwise>
                                    </c:choose>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<div class="app-tarjeta mb-4">
    <h2 class="app-tarjeta-titulo">Estudiantes que no aprobaron <span class="text-secondary fw-normal">· <c:out value="${noAprobados.rowCount}" /></span></h2>
    <c:choose>
        <c:when test="${noAprobados.rowCount == 0}"><p class="app-vacio mt-0">No hay estudiantes con el proyecto cancelado en este periodo.</p></c:when>
        <c:otherwise>
            <div class="table-responsive">
                <table class="table app-tabla align-middle mb-0">
                    <thead><tr><th>Estudiante</th><th>Carrera</th><th>Proyecto</th><th>Motivo</th></tr></thead>
                    <tbody>
                        <c:forEach var="a" items="${noAprobados.rows}">
                            <tr>
                                <td><span class="fw-semibold"><c:out value="${a.nombre}" /></span>
                                    <span class="app-lista-nota"><c:out value="${a.sigla}" /> <c:out value="${a.numero_documento}" /> · <c:out value="${a.correo}" /></span></td>
                                <td><c:out value="${empty a.carrera ? '—' : a.carrera}" /></td>
                                <td><c:out value="${a.titulo}" /><span class="app-lista-nota"><c:out value="${a.codigo}" /> · <c:out value="${a.modalidad}" /><c:if test="${a.modalidad_id != 5}"> · se canceló en la ${a.fase == 6 ? 'fase final' : 'fase '}${a.fase == 6 ? '' : a.fase}</c:if></span></td>
                                <td><c:out value="${empty a.motivo ? 'Proyecto cancelado' : a.motivo}" /></td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
