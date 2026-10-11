<%-- Proyectos (RF9), para el comité (el administrador): la fase de cada uno, el estado
     del pago (RF32) y el director. Desde aquí se abre cada proyecto para revisar el
     pago y asignar director y evaluador (RF11). Filtros: ?filtro=pago (pagos por
     revisar), ?filtro=director (sin director) o ?filtro=evaluador (sin evaluador en las
     fases 2 a 4: el director no puede enviarle la propuesta), ?filtro=propuestas
     (propuestas con el concepto del evaluador, esperando la decisión del comité, RF14)
     o ?filtro=vencidos (plazo del director o del evaluador vencido, RF21). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
<c:set var="titulo" value="Proyectos" />
<c:set var="seccion" value="proyectos" />
<c:set var="filtro" value="${param.filtro == 'pago' or param.filtro == 'director' or param.filtro == 'evaluador'
                               or param.filtro == 'modalidad' or param.filtro == 'exoneracion' or param.filtro == 'vencidos'
                               or param.filtro == 'seminario' or param.filtro == 'propuestas' or param.filtro == 'prorrogas' ? param.filtro : ''}" />

<sql:query var="proyectos">
    SELECT * FROM (
        SELECT p.id, p.codigo, p.titulo, p.estado, p.evaluador_id, p.modalidad_id, f.orden AS fase,
               (SELECT COUNT(*) FROM cambios_modalidad c WHERE c.proyecto_id = p.id AND c.estado = 'Pendiente') AS cambios,
               (SELECT COUNT(*) FROM exoneraciones x WHERE x.proyecto_id = p.id AND x.estado = 'Pendiente') AS exoneraciones,
               (SELECT COUNT(*) FROM prorrogas x WHERE x.proyecto_id = p.id AND x.estado = 'Pendiente') AS prorrogas,
               ${sqlUltimaRevision} AS ultima, ${sqlUltimaRevisionInforme} AS ultima_informe,
               (f.orden = 5 AND COALESCE(${sqlUltimaRevisionInforme}, 'Comité:Devuelto') IN ('Comité:Devuelto', 'Director:Aprobado')
                AND EXISTS (SELECT 1 FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125'
                    AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = 'FDC-125')
                    AND e.fecha_limite_revision < CURDATE())) AS informe_vencido,
               ((f.orden = 3 OR (f.orden = 4 AND ${sqlUltimaRevision} = 'Director:Aprobado')) AND EXISTS (SELECT 1 FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124'
                   AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = 'FDC-124')
                   AND e.fecha_limite_revision < CURDATE())) AS director_vencido, f.nombre AS nombre_fase,
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
           OR (? = 'evaluador' AND evaluador_id IS NULL AND fase BETWEEN 2 AND 4)
           OR (? = 'modalidad' AND cambios > 0) OR (? = 'exoneracion' AND exoneraciones > 0)
           OR (? = 'prorrogas' AND prorrogas > 0)
           OR (? = 'vencidos' AND (director_vencido = 1 OR informe_vencido = 1) AND estado NOT IN ('Finalizado', 'Cancelado'))
           OR (? = 'propuestas' AND ((fase = 4 AND ultima LIKE 'Evaluador:%' AND ultima <> 'Evaluador:Devuelto') OR (fase = 5 AND ultima_informe LIKE 'Evaluador:%'))
               AND estado NOT IN ('Finalizado', 'Cancelado'))
           OR (? = 'seminario' AND modalidad_id = 5 AND estado = 'Pendiente'))
    ORDER BY fase, titulo
    <sql:param value="${filtro}" />
    <sql:param value="${filtro}" />
    <sql:param value="${filtro}" />
    <sql:param value="${filtro}" />
    <sql:param value="${filtro}" />
    <sql:param value="${filtro}" />
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
            <option value="modalidad" ${filtro == 'modalidad' ? 'selected' : ''}>Cambios de modalidad por decidir</option>
            <option value="exoneracion" ${filtro == 'exoneracion' ? 'selected' : ''}>Exoneraciones por verificar</option>
            <option value="prorrogas" ${filtro == 'prorrogas' ? 'selected' : ''}>Prórrogas por decidir</option>
            <option value="propuestas" ${filtro == 'propuestas' ? 'selected' : ''}>Propuestas e informes por decidir (comité)</option>
            <option value="vencidos" ${filtro == 'vencidos' ? 'selected' : ''}>Plazos vencidos (director o evaluador)</option>
            <option value="seminario" ${filtro == 'seminario' ? 'selected' : ''}>Seminario: inscripciones por validar</option>
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
                                    <c:if test="${not empty p.codigo}"><span class="app-lista-nota"><c:out value="${p.codigo}" /></span></c:if>
                                    <c:if test="${p.cambios > 0}"><span class="app-etiqueta ms-0">Cambio de modalidad por decidir</span></c:if>
                                    <c:if test="${p.exoneraciones > 0}"><span class="app-etiqueta ms-0">Exoneración por verificar</span></c:if>
                                    <c:if test="${p.prorrogas > 0}"><span class="app-etiqueta ms-0">Prórroga por decidir</span></c:if>
                                    <c:if test="${p.director_vencido == 1 and p.estado != 'Cancelado'}"><span class="app-etiqueta ms-0">Plazo del ${p.fase == 3 ? 'director' : 'evaluador'} vencido</span></c:if>
                                    <c:if test="${p.fase == 4 and fn:startsWith(p.ultima, 'Evaluador:') and p.ultima != 'Evaluador:Devuelto' and p.estado != 'Cancelado'}"><span class="app-etiqueta ms-0">Propuesta por decidir</span></c:if>
                                    <c:if test="${p.fase == 5 and fn:startsWith(p.ultima_informe, 'Evaluador:') and p.estado != 'Cancelado'}"><span class="app-etiqueta ms-0">Informe por decidir</span></c:if>
                                    <c:if test="${p.informe_vencido == 1 and p.estado != 'Cancelado'}"><span class="app-etiqueta ms-0">Plazo del ${p.ultima_informe == 'Director:Aprobado' ? 'evaluador' : 'director'} vencido (informe)</span></c:if>
                                    <c:if test="${p.modalidad_id == 5 and p.estado == 'Pendiente'}"><span class="app-etiqueta ms-0">Seminario: inscripción por validar</span></c:if>
                                    <c:if test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><span class="app-etiqueta ms-0"><c:out value="${p.estado}" /></span></c:if>
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
