<%-- Mis proyectos (director): los proyectos que dirige o codirige, con su fase y la
     última versión de la propuesta (RF18, RF19). Los que están en la fase 3 (propuesta)
     o en la 5 sin revisar (informe final) son los que el estudiante ya le envió. --%>
<%@ include file="/WEB-INF/jspf/solo-director.jspf" %>
<%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
<c:set var="titulo" value="Mis proyectos" />
<c:set var="seccion" value="dirigidos" />

<sql:query var="proyectos">
    SELECT * FROM (
    SELECT p.id, p.titulo, p.estado, f.orden AS fase, ${sqlUltimaRevisionInforme} AS ultima_informe,
           (SELECT MAX(e.version) FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125') AS version_informe, f.nombre AS nombre_fase, m.nombre AS modalidad, n.nombre AS nivel,
           (p.director_id = ?) AS es_director,
           (SELECT GROUP_CONCAT(u.nombre ORDER BY u.nombre SEPARATOR ', ')
            FROM proyecto_estudiantes pe JOIN usuarios u ON u.id = pe.estudiante_id
            WHERE pe.proyecto_id = p.id AND pe.vigente = 1) AS estudiantes,
           (SELECT MAX(e.version) FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124') AS version_propuesta
    FROM proyectos p
    JOIN modalidades m ON m.id = p.modalidad_id
    JOIN niveles n ON n.id = p.nivel_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE p.director_id = ? OR EXISTS (SELECT 1 FROM proyecto_codirectores pc WHERE pc.proyecto_id = p.id AND pc.docente_id = ?)
    ) t
    ORDER BY (fase = 3 OR (fase = 5 AND COALESCE(ultima_informe, 'Comité:Devuelto') = 'Comité:Devuelto')) DESC, fase, titulo
    <sql:param value="${sessionScope.usuario.id}" />
    <sql:param value="${sessionScope.usuario.id}" />
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <h1>Mis proyectos</h1>
    <p>Los proyectos que diriges. Los que están en la fase 3 tienen una propuesta para revisar.</p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="app-tarjeta">
    <c:choose>
        <c:when test="${proyectos.rowCount == 0}">
            <p class="app-vacio">Todavía no diriges ningún proyecto. El comité te los asigna.</p>
        </c:when>
        <c:otherwise>
            <div class="table-responsive">
                <table class="table app-tabla align-middle">
                    <thead>
                        <tr>
                            <th>Proyecto</th>
                            <th>Estudiantes</th>
                            <th>Fase</th>
                            <th>Documento</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="p" items="${proyectos.rows}">
                            <c:set var="informePorRevisar" value="${p.fase == 5 and (empty p.ultima_informe or p.ultima_informe == 'Comité:Devuelto')}" />
                            <tr>
                                <td>
                                    <span class="fw-semibold"><c:out value="${p.titulo}" /></span>
                                    <span class="app-lista-nota"><c:out value="${p.modalidad}" /> · <c:out value="${p.nivel}" />${p.es_director == 1 ? '' : ' · Codirector'}</span>
                                </td>
                                <td><c:out value="${p.estudiantes}" /></td>
                                <td class="text-nowrap">
                                    <c:choose><c:when test="${p.fase == 6}">Fase final</c:when><c:otherwise>Fase <c:out value="${p.fase}" /></c:otherwise></c:choose>
                                    <span class="app-lista-nota"><c:out value="${p.nombre_fase}" /></span>
                                </td>
                                <td class="text-nowrap">
                                    <c:choose>
                                        <c:when test="${p.fase == 3}"><span class="app-estado activo">Por revisar · v<c:out value="${p.version_propuesta}" /></span></c:when>
                                        <c:when test="${informePorRevisar}"><span class="app-estado activo">Informe por revisar · v<c:out value="${p.version_informe}" /></span></c:when>
                                        <c:when test="${p.fase >= 4 and not empty p.version_informe}">Informe · versión <c:out value="${p.version_informe}" /></c:when>
                                        <c:when test="${not empty p.version_propuesta}">Versión <c:out value="${p.version_propuesta}" /></c:when>
                                        <c:otherwise><span class="app-lista-nota d-inline">Sin versiones</span></c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="text-end app-acciones">
                                    <a class="btn btn-sm ${p.fase == 3 or informePorRevisar ? 'btn-primary' : 'btn-outline-dark'} rounded-pill" href="${ctx}/director/proyecto.jsp?id=${p.id}">${p.fase == 3 or informePorRevisar ? 'Revisar' : 'Ver'}</a>
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
