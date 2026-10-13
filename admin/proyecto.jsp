<%-- Un proyecto visto por el comité (el administrador), ?id=...: sus fases, sus datos,
     la revisión del recibo de pago (RF32, con observación obligatoria, RF34) y la
     asignación del director y del evaluador (RF11; un docente nunca evalúa el proyecto
     que dirige). Cuando el pago está aprobado (o no aplica) y tiene director, el
     proyecto pasa a la fase 2 (avanzar-fase-2.jspf). En la fase 4 el comité ve la
     evaluación y da la decisión final sobre la propuesta con su acta (RF14,
     propuesta-decidir.jsp); aprobada, ve los seguimientos y el informe final. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
<c:set var="titulo" value="Proyecto" />
<c:set var="seccion" value="proyectos" />

<sql:query var="consulta">
    SELECT p.id, p.codigo, p.titulo, p.descripcion, p.estado, p.director_id, p.evaluador_id, p.fecha_inicio, p.modalidad_id,
           p.interdisciplinario, p.nota_final, ${sqlDocumentosFaltantes} AS documentos_faltantes,
           f.orden AS fase, f.nombre AS nombre_fase, m.nombre AS modalidad, n.nombre AS nivel,
           pr.nombre AS periodo, pr.fecha_limite_pago, pr.fecha_limite_propuestas, ${sqlEstadoPago} AS estado_pago,
           (SELECT e.fecha_limite_revision FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124'
            ORDER BY e.version DESC LIMIT 1) AS limite_director,
           (SELECT e.fecha_limite_revision < CURDATE() FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124'
            ORDER BY e.version DESC LIMIT 1) AS director_vencido,
           ${sqlUltimaRevision} AS ultima, p.fecha_aprobacion_124, p.fecha_limite,
           p.fecha_aprobacion_124 + INTERVAL 90 DAY AS informe_desde, CURDATE() AS hoy,
           ${sqlUltimaRevisionInforme} AS ultima_informe,
           (SELECT e.fecha_limite_revision FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125'
            ORDER BY e.version DESC LIMIT 1) AS limite_informe,
           (SELECT e.fecha_limite_revision < CURDATE() FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125'
            ORDER BY e.version DESC LIMIT 1) AS informe_vencido
    FROM proyectos p
    JOIN modalidades m ON m.id = p.modalidad_id
    JOIN niveles n ON n.id = p.nivel_id
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN periodos pr ON pr.id = p.periodo_id
    WHERE p.id = ?
    <sql:param value="${empty param.id ? 0 : param.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/admin/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="faseActual" value="${p.fase}" />
<c:set var="esSeminario" value="${p.modalidad_id == 5}" />
<c:set var="estadoProyecto" value="${p.estado}" />

<%-- Recibos de los estudiantes vigentes (cada uno sube el suyo), agrupados por estudiante
     y del más reciente al más antiguo, con la revisión del comité si la tienen --%>
<sql:query var="recibos">
    SELECT e.id, e.subido_por, est.nombre AS estudiante, e.nombre_archivo, e.subido_en,
           r.decision, r.observacion, r.revisado_en, u.nombre AS revisor
    FROM entregas e
    JOIN proyecto_estudiantes px ON px.proyecto_id = e.proyecto_id AND px.estudiante_id = e.subido_por AND px.vigente = 1
    JOIN usuarios est ON est.id = e.subido_por
    LEFT JOIN revisiones r ON r.entrega_id = e.id AND r.rol = 'Comité' AND r.estado = 'Enviada'
    LEFT JOIN usuarios u ON u.id = r.revisor_id
    WHERE e.proyecto_id = ? AND e.tipo = 'Recibo de pago'
    ORDER BY est.nombre, e.subido_por, e.id DESC
    <sql:param value="${p.id}" />
</sql:query>
<%-- Docentes activos con rol Director (3) y con rol Evaluador (4) --%>
<sql:query var="directores">
    SELECT u.id, u.nombre FROM usuarios u JOIN usuario_roles ur ON ur.usuario_id = u.id
    WHERE ur.rol_id = 3 AND u.activo = 1 ORDER BY u.nombre
</sql:query>
<sql:query var="evaluadores">
    SELECT u.id, u.nombre FROM usuarios u JOIN usuario_roles ur ON ur.usuario_id = u.id
    WHERE ur.rol_id = 4 AND u.activo = 1 ORDER BY u.nombre
</sql:query>
<%-- Codirectores actuales (RF13), como "|id|id|" --%>
<sql:query var="codirectoresActuales">
    SELECT docente_id FROM proyecto_codirectores WHERE proyecto_id = ? ORDER BY docente_id
    <sql:param value="${p.id}" />
</sql:query>
<c:set var="idCodirector1">${codirectoresActuales.rowCount > 0 ? codirectoresActuales.rows[0].docente_id : ''}</c:set>
<c:set var="idCodirector2">${codirectoresActuales.rowCount > 1 ? codirectoresActuales.rows[1].docente_id : ''}</c:set>
<c:set var="idDirector">${p.director_id}</c:set>
<c:set var="idEvaluador">${p.evaluador_id}</c:set>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <a class="app-volver" href="${ctx}/admin/proyectos.jsp">← Volver a proyectos</a>
    <h1><c:out value="${p.titulo}" /></h1>
    <p><c:out value="${p.modalidad}" /> · <c:out value="${p.nivel}" /><c:if test="${not empty p.periodo}"> · Periodo <c:out value="${p.periodo}" /></c:if></p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<%@ include file="/WEB-INF/jspf/fases-proyecto.jspf" %>

<%-- Solicitudes por decidir: cambio de modalidad (RF12) y exoneración (RNF14) --%>
<sql:query var="cambiosPendientes">
    SELECT c.id, c.motivo, c.solicitado_en, ma.nombre AS anterior, mn.nombre AS nueva, u.nombre AS solicitante
    FROM cambios_modalidad c
    JOIN modalidades ma ON ma.id = c.modalidad_anterior_id
    JOIN modalidades mn ON mn.id = c.modalidad_nueva_id
    JOIN usuarios u ON u.id = c.solicitado_por
    WHERE c.proyecto_id = ? AND c.estado = 'Pendiente'
    <sql:param value="${p.id}" />
</sql:query>
<sql:query var="exoneraciones">
    SELECT x.id, x.puntaje, x.estado, x.observacion, x.entrega_id, u.nombre AS estudiante, pe.renuncia_exoneracion,
           CASE WHEN x.puntaje >= 171 THEN '5.0 y 100 % de beca' WHEN x.puntaje >= 151 THEN '4.7 y 50 % de beca' ELSE '4.5' END AS estimulo
    FROM exoneraciones x
    JOIN usuarios u ON u.id = x.estudiante_id
    LEFT JOIN proyecto_estudiantes pe ON pe.proyecto_id = x.proyecto_id AND pe.estudiante_id = x.estudiante_id
    WHERE x.proyecto_id = ?
    ORDER BY x.id DESC
    <sql:param value="${p.id}" />
</sql:query>

<%-- Prórrogas del plazo del informe final (RF38) --%>
<sql:query var="prorrogas">
    SELECT x.id, x.numero, x.estado, x.fecha_solicitud, x.nueva_fecha_limite, x.motivo, x.observacion, x.entrega_id, u.nombre AS solicitante
    FROM prorrogas x LEFT JOIN usuarios u ON u.id = x.solicitada_por
    WHERE x.proyecto_id = ? ORDER BY x.id
    <sql:param value="${p.id}" />
</sql:query>

<c:if test="${p.estado == 'Finalizado'}">
    <div class="app-resultado cumple">
        <h2>Proyecto terminado</h2>
        <p>Estado: Finalizado. Revisa el historial para ver cómo terminó.</p>
    </div>
</c:if>

<c:if test="${cambiosPendientes.rowCount > 0}">
    <div class="app-tarjeta mb-4">
        <h2 class="app-tarjeta-titulo">Cambio de modalidad por decidir</h2>
        <c:forEach var="cm" items="${cambiosPendientes.rows}">
            <p class="mb-1"><strong><c:out value="${cm.solicitante}" /></strong> pide pasar de <c:out value="${cm.anterior}" /> a <strong><c:out value="${cm.nueva}" /></strong>.</p>
            <p class="app-observacion mt-0">Motivo: <c:out value="${cm.motivo}" /> <span class="app-lista-nota"><fmt:formatDate value="${cm.solicitado_en}" pattern="dd/MM/yyyy HH:mm" /></span></p>
            <form class="app-revision" method="post" action="${ctx}/admin/modalidad-decidir.jsp">
                <input type="hidden" name="id" value="${cm.id}">
                <textarea class="form-control" name="observacion" placeholder="Observación del comité (obligatoria)" aria-label="Observación sobre el cambio de modalidad" required></textarea>
                <button type="submit" name="decision" value="aprobar" class="btn btn-sm btn-primary rounded-pill">Aprobar el cambio</button>
                <button type="submit" name="decision" value="rechazar" class="btn btn-sm btn-outline-dark rounded-pill">Rechazar</button>
            </form>
        </c:forEach>
    </div>
</c:if>

<c:if test="${prorrogas.rowCount > 0}">
    <div class="app-tarjeta mb-4">
        <h2 class="app-tarjeta-titulo">Prórrogas del informe final</h2>
        <c:forEach var="pr" items="${prorrogas.rows}">
            <div class="app-archivo">
                <span>
                    <span class="app-lista-dato"><c:choose><c:when test="${pr.estado == 'Aprobada'}">Prórroga <c:out value="${pr.numero}" /> de 3</c:when><c:otherwise>Solicitud de prórroga</c:otherwise></c:choose> · <c:out value="${pr.solicitante}" /></span>
                    <span class="app-lista-nota">Pedida el <fmt:formatDate value="${pr.fecha_solicitud}" pattern="dd/MM/yyyy" /> · nueva fecha límite: <fmt:formatDate value="${pr.nueva_fecha_limite}" pattern="dd/MM/yyyy" /> · Motivo: <c:out value="${pr.motivo}" /></span>
                </span>
                <span class="app-acciones">
                    <span class="app-estado ${pr.estado == 'Aprobada' ? 'activo' : 'inactivo'}"><c:out value="${pr.estado}" /></span>
                    <c:if test="${not empty pr.entrega_id}"><a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/archivos/ver.jsp?id=${pr.entrega_id}" target="_blank" rel="noopener">Soporte</a></c:if>
                </span>
            </div>
            <c:choose>
                <c:when test="${pr.estado == 'Pendiente' and p.estado != 'Finalizado' and p.estado != 'Cancelado'}">
                    <form class="app-revision mb-3" method="post" action="${ctx}/admin/prorroga-decidir.jsp">
                        <input type="hidden" name="id" value="${pr.id}">
                        <textarea class="form-control" name="observacion" placeholder="Observación del comité (obligatoria)" aria-label="Observación sobre la prórroga" required></textarea>
                        <button type="submit" name="decision" value="aprobar" class="btn btn-sm btn-primary rounded-pill">Aprobar la prórroga</button>
                        <button type="submit" name="decision" value="rechazar" class="btn btn-sm btn-outline-dark rounded-pill">Rechazar</button>
                    </form>
                </c:when>
                <c:when test="${not empty pr.observacion}">
                    <p class="app-observacion mb-3"><strong>Observación del comité:</strong> <c:out value="${pr.observacion}" /></p>
                </c:when>
            </c:choose>
        </c:forEach>
    </div>
</c:if>

<c:if test="${exoneraciones.rowCount > 0}">
    <div class="app-tarjeta mb-4">
        <h2 class="app-tarjeta-titulo">Exoneraciones por Saber TyT</h2>
        <c:forEach var="xo" items="${exoneraciones.rows}">
            <div class="app-archivo">
                <span>
                    <span class="app-lista-dato"><c:out value="${xo.estudiante}" /> · <c:out value="${xo.puntaje}" /> puntos</span>
                    <span class="app-lista-nota">Estímulo: <c:out value="${xo.estimulo}" /><c:if test="${xo.estado == 'Aprobada' and xo.renuncia_exoneracion == true}"> · renunció a la exoneración</c:if></span>
                </span>
                <span class="app-acciones">
                    <span class="app-estado ${xo.estado == 'Aprobada' ? 'activo' : 'inactivo'}"><c:out value="${xo.estado}" /></span>
                    <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/archivos/ver.jsp?id=${xo.entrega_id}" target="_blank" rel="noopener">Certificado</a>
                </span>
            </div>
            <c:choose>
                <c:when test="${xo.estado == 'Pendiente' and p.estado != 'Finalizado'}">
                    <form class="app-revision mb-3" method="post" action="${ctx}/admin/exoneracion-revisar.jsp">
                        <input type="hidden" name="id" value="${xo.id}">
                        <textarea class="form-control" name="observacion" placeholder="Observación del comité (obligatoria)" aria-label="Observación sobre la exoneración" required></textarea>
                        <button type="submit" name="decision" value="aprobar" class="btn btn-sm btn-primary rounded-pill">Aprobar la exoneración</button>
                        <button type="submit" name="decision" value="rechazar" class="btn btn-sm btn-outline-dark rounded-pill">Rechazar</button>
                    </form>
                </c:when>
                <c:when test="${not empty xo.observacion}">
                    <p class="app-observacion mb-3"><strong>Observación del comité:</strong> <c:out value="${xo.observacion}" /></p>
                </c:when>
            </c:choose>
        </c:forEach>
    </div>
</c:if>

<c:if test="${p.fase == 3 and not empty p.limite_director and p.estado != 'Cancelado'}">
    <div class="${p.director_vencido == 1 ? 'alert alert-warning app-aviso' : 'app-resultado'}" role="status">
        <c:choose>
            <c:when test="${p.director_vencido == 1}">Se venció el plazo del director para revisar la propuesta (<fmt:formatDate value="${p.limite_director}" pattern="dd/MM/yyyy" />). No hay aprobación automática.</c:when>
            <c:otherwise>El director tiene hasta el <fmt:formatDate value="${p.limite_director}" pattern="dd/MM/yyyy" /> para revisar la propuesta (5 días hábiles).</c:otherwise>
        </c:choose>
    </div>
</c:if>
<c:if test="${p.fase == 4 and p.ultima == 'Director:Aprobado' and not empty p.limite_director and p.estado != 'Cancelado'}">
    <div class="${p.director_vencido == 1 ? 'alert alert-warning app-aviso' : 'app-resultado'}" role="status">
        <c:choose>
            <c:when test="${p.director_vencido == 1}">Se venció el plazo del evaluador para evaluar la propuesta (<fmt:formatDate value="${p.limite_director}" pattern="dd/MM/yyyy" />). No hay aprobación automática.</c:when>
            <c:otherwise>El evaluador tiene hasta el <fmt:formatDate value="${p.limite_director}" pattern="dd/MM/yyyy" /> para evaluar la propuesta (3 días hábiles).</c:otherwise>
        </c:choose>
    </div>
</c:if>

<%-- Seminario (RF17): inscripción (documentos y validación) y nota final --%>
<c:if test="${esSeminario}">
    <sql:query var="documentosSeminario">
        SELECT e.id, e.tipo, e.nombre_archivo, e.subido_en, u.nombre AS estudiante
        FROM entregas e JOIN usuarios u ON u.id = e.subido_por
        JOIN proyecto_estudiantes x ON x.proyecto_id = e.proyecto_id AND x.estudiante_id = e.subido_por AND x.vigente = 1
        WHERE e.proyecto_id = ? AND e.tipo IN ('Formato F-AM-04', 'Documento de identidad')
          AND e.id = (SELECT MAX(e2.id) FROM entregas e2 WHERE e2.proyecto_id = e.proyecto_id AND e2.subido_por = e.subido_por AND e2.tipo = e.tipo)
        ORDER BY u.nombre, e.tipo DESC
        <sql:param value="${p.id}" />
    </sql:query>
    <div class="app-tarjeta mb-4">
        <h2 class="app-tarjeta-titulo">Inscripción al seminario</h2>
        <c:choose>
            <c:when test="${p.estado == 'Pendiente'}">
                <c:set var="pagoListoSeminario" value="${p.estado_pago == 'Aprobado' or p.estado_pago == 'No aplica'}" />
                <ul class="app-lista mb-3">
                    <li><span class="app-lista-dato">Pago de todos aprobado</span><span class="app-requisito ${pagoListoSeminario ? 'cumple' : ''}">${pagoListoSeminario ? 'Listo' : 'Pendiente'}</span></li>
                    <li><span class="app-lista-dato">Formato F-AM-04 y cédula de todos</span><span class="app-requisito ${p.documentos_faltantes == 0 ? 'cumple' : ''}">${p.documentos_faltantes == 0 ? 'Listo' : 'Pendiente'}</span></li>
                    <li><span class="app-lista-dato">Docente del seminario (director)</span><span class="app-requisito ${empty p.director_id ? '' : 'cumple'}">${empty p.director_id ? 'Pendiente' : 'Listo'}</span></li>
                </ul>
            </c:when>
            <c:when test="${p.estado == 'En curso'}"><p class="text-secondary">Inscripción validada: el seminario está en curso. La nota final la registra el docente.</p></c:when>
            <c:when test="${not empty p.nota_final}"><p class="mb-3">Nota final: <strong><fmt:formatNumber value="${p.nota_final}" minFractionDigits="1" maxFractionDigits="1" /></strong> (${p.estado == 'Finalizado' ? 'aprobado' : 'reprobado'}).</p></c:when>
        </c:choose>
        <c:forEach var="dc" items="${documentosSeminario.rows}">
            <div class="app-archivo">
                <span><span class="app-lista-dato"><c:out value="${dc.estudiante}" /> · <c:out value="${dc.tipo}" /></span>
                    <span class="app-lista-nota"><c:out value="${dc.nombre_archivo}" /> · <fmt:formatDate value="${dc.subido_en}" pattern="dd/MM/yyyy HH:mm" /></span></span>
                <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/archivos/ver.jsp?id=${dc.id}" target="_blank" rel="noopener">Ver</a>
            </div>
        </c:forEach>
        <c:if test="${p.estado == 'Pendiente'}">
            <form class="app-revision" method="post" action="${ctx}/admin/inscripcion-validar.jsp">
                <input type="hidden" name="id" value="${p.id}">
                <textarea class="form-control" name="observacion" placeholder="Observación del comité (obligatoria)" aria-label="Observación sobre la inscripción" required></textarea>
                <button type="submit" name="decision" value="aprobar" class="btn btn-sm btn-primary rounded-pill">Validar la inscripción</button>
                <button type="submit" name="decision" value="devolver" class="btn btn-sm btn-outline-dark rounded-pill">Devolver a los estudiantes</button>
            </form>
        </c:if>
    </div>
</c:if>

<c:if test="${p.fase == 1 and not esSeminario}">
    <c:set var="pagoListo" value="${p.estado_pago == 'Aprobado' or p.estado_pago == 'No aplica'}" />
    <div class="app-tarjeta mb-4">
        <h2 class="app-tarjeta-titulo">Para pasar a la fase 2</h2>
        <ul class="app-lista">
            <li>
                <span><span class="app-lista-dato">Pago de todos los estudiantes aprobado</span><span class="app-lista-nota">Cada estudiante paga el suyo. En los planes nuevos lo cubre la matrícula, salvo en Seminario.</span></span>
                <span class="app-requisito ${pagoListo ? 'cumple' : ''}">${pagoListo ? 'Listo' : 'Pendiente'}</span>
            </li>
            <li>
                <span><span class="app-lista-dato">Director asignado</span></span>
                <span class="app-requisito ${empty p.director_id ? '' : 'cumple'}">${empty p.director_id ? 'Pendiente' : 'Listo'}</span>
            </li>
        </ul>
    </div>
</c:if>

<c:if test="${p.fase >= 2 and p.modalidad_id != 5}">
    <div class="app-tarjeta mb-4">
        <h2 class="app-tarjeta-titulo">Propuesta (FDC-124)</h2>
        <c:set var="idProyectoPropuesta" value="${p.id}" />
        <%@ include file="/WEB-INF/jspf/propuesta-versiones.jspf" %>
        <sql:query var="reportesTurnitin">
            SELECT id, nombre_archivo, subido_en FROM entregas WHERE proyecto_id = ? AND tipo = 'Reporte Turnitin' ORDER BY id DESC
            <sql:param value="${p.id}" />
        </sql:query>
        <c:if test="${reportesTurnitin.rowCount > 0}">
            <h3 class="h6 fw-bold mt-4 mb-2">Reportes de Turnitin</h3>
            <c:forEach var="t" items="${reportesTurnitin.rows}">
                <div class="app-archivo">
                    <span>
                        <span class="app-lista-dato"><c:out value="${t.nombre_archivo}" /></span>
                        <span class="app-lista-nota">Subido por el director el <fmt:formatDate value="${t.subido_en}" pattern="dd/MM/yyyy HH:mm" /></span>
                    </span>
                    <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/archivos/ver.jsp?id=${t.id}" target="_blank" rel="noopener">Ver</a>
                </div>
            </c:forEach>
        </c:if>
        <c:set var="idProyectoEvaluacion" value="${p.id}" />
        <c:set var="evaluacionConEvaluador" value="true" />
        <c:set var="evaluacionInforme" value="false" />
        <%@ include file="/WEB-INF/jspf/evaluacion-propuesta.jspf" %>
    </div>

    <%-- Fase 4: decisión final del comité sobre la propuesta, con su acta (RF14) --%>
    <c:if test="${p.fase == 4 and fn:startsWith(p.ultima, 'Evaluador:') and p.ultima != 'Evaluador:Devuelto' and p.estado != 'Finalizado' and p.estado != 'Cancelado'}">
        <form class="app-tarjeta app-formulario mb-4" method="post" action="${ctx}/admin/propuesta-decidir.jsp">
            <input type="hidden" name="id" value="${p.id}">
            <h2 class="app-tarjeta-titulo">Decisión del comité sobre la propuesta</h2>
            <p class="text-secondary">
                El evaluador ya dio su concepto. La decisión final es del comité, sea cual sea ese concepto, y queda con su acta.
                Aprobada, empiezan a correr los 180 días del informe final. Aplazada, el estudiante sube una versión corregida (vuelve a la fase 2).
                No aprobada, el proyecto se cancela y la idea vuelve al banco. Si falta algo, devuélvela al director (fase 3).
            </p>
            <div class="row g-3">
                <div class="col-sm-4">
                    <label class="form-label" for="acta">Número del acta *</label>
                    <input class="form-control" type="number" id="acta" name="acta" min="1" step="1" required>
                </div>
                <div class="col-sm-4">
                    <label class="form-label" for="fechaActa">Fecha del acta *</label>
                    <input class="form-control" type="date" id="fechaActa" name="fecha_acta" required
                           value="<fmt:formatDate value='${p.hoy}' pattern='yyyy-MM-dd' />" max="<fmt:formatDate value='${p.hoy}' pattern='yyyy-MM-dd' />">
                </div>
                <div class="col-12">
                    <label class="form-label" for="observacionComite">Observación del comité *</label>
                    <textarea class="form-control" id="observacionComite" name="observacion" required></textarea>
                </div>
            </div>
            <div class="d-flex flex-wrap gap-2 mt-3">
                <button type="submit" name="decision" value="aprobar" class="btn btn-primary rounded-pill app-boton">Aprobar la propuesta</button>
                <button type="submit" name="decision" value="aplazar" class="btn btn-outline-dark rounded-pill">Aplazar</button>
                <button type="submit" name="decision" value="devolver" class="btn btn-outline-dark rounded-pill">Devolver al director</button>
                <button type="submit" name="decision" value="no-aprobar" class="btn btn-outline-danger rounded-pill"
                        onclick="return confirm('¿No aprobar la propuesta? El proyecto se cancela y la idea vuelve al banco.');">No aprobar</button>
            </div>
        </form>
    </c:if>

    <%-- Con el FDC-124 aprobado: plazos, seguimientos e informe final (RF20, RF31); en la
         fase 5, la evaluación con la rejilla del F-DC-129 y la decisión del comité (RF14) --%>
    <c:if test="${not empty p.fecha_aprobacion_124}">
        <c:set var="informeAbierto" value="${p.estado != 'Finalizado' and p.estado != 'Cancelado'}" />
        <c:if test="${p.fase == 5 and informeAbierto and not empty p.limite_informe and (empty p.ultima_informe or p.ultima_informe == 'Comité:Devuelto' or p.ultima_informe == 'Director:Aprobado')}">
            <div class="${p.informe_vencido == 1 ? 'alert alert-warning app-aviso' : 'app-resultado'}" role="status">
                ${p.ultima_informe == 'Director:Aprobado' ? 'El evaluador' : 'El director'}
                <c:choose>
                    <c:when test="${p.informe_vencido == 1}">tenía hasta el <fmt:formatDate value="${p.limite_informe}" pattern="dd/MM/yyyy" /> para ${p.ultima_informe == 'Director:Aprobado' ? 'evaluar' : 'revisar'} el informe final: el plazo se venció. No hay aprobación automática.</c:when>
                    <c:otherwise>tiene hasta el <fmt:formatDate value="${p.limite_informe}" pattern="dd/MM/yyyy" /> para ${p.ultima_informe == 'Director:Aprobado' ? 'evaluar' : 'revisar'} el informe final (5 días hábiles).</c:otherwise>
                </c:choose>
            </div>
        </c:if>
        <div class="app-tarjeta mb-4">
            <h2 class="app-tarjeta-titulo">Informe final (FDC-125)</h2>
            <dl class="app-pares">
                <div><dt>Propuesta aprobada</dt><dd><fmt:formatDate value="${p.fecha_aprobacion_124}" pattern="dd/MM/yyyy" /></dd></div>
                <div><dt>Se entrega desde</dt><dd><fmt:formatDate value="${p.informe_desde}" pattern="dd/MM/yyyy" /></dd></div>
                <div><dt>Fecha límite</dt><dd><fmt:formatDate value="${p.fecha_limite}" pattern="dd/MM/yyyy" /></dd></div>
            </dl>
            <c:set var="idProyectoInforme" value="${p.id}" />
            <%@ include file="/WEB-INF/jspf/informe-final.jspf" %>
            <c:set var="idProyectoEvaluacion" value="${p.id}" />
            <c:set var="evaluacionConEvaluador" value="true" />
            <c:set var="evaluacionInforme" value="true" />
            <%@ include file="/WEB-INF/jspf/evaluacion-propuesta.jspf" %>
        </div>

        <c:if test="${p.fase == 5 and fn:startsWith(p.ultima_informe, 'Evaluador:') and informeAbierto}">
            <form class="app-tarjeta app-formulario mb-4" method="post" action="${ctx}/admin/informe-decidir.jsp">
                <input type="hidden" name="id" value="${p.id}">
                <h2 class="app-tarjeta-titulo">Decisión del comité sobre el informe final</h2>
                <p class="text-secondary">
                    El evaluador ya dio su concepto con la rejilla del F-DC-129. La decisión final es del comité y queda con su acta.
                    Aprobado, el proyecto pasa a la fase final para programar la sustentación. Aplazado o no aprobado, vuelve al estudiante para corregirlo (fase 4).
                    Si falta algo, devuélvelo al director.
                </p>
                <div class="row g-3">
                    <div class="col-sm-4">
                        <label class="form-label" for="actaInforme">Número del acta *</label>
                        <input class="form-control" type="number" id="actaInforme" name="acta" min="1" step="1" required>
                    </div>
                    <div class="col-sm-4">
                        <label class="form-label" for="fechaActaInforme">Fecha del acta *</label>
                        <input class="form-control" type="date" id="fechaActaInforme" name="fecha_acta" required
                               value="<fmt:formatDate value='${p.hoy}' pattern='yyyy-MM-dd' />" max="<fmt:formatDate value='${p.hoy}' pattern='yyyy-MM-dd' />">
                    </div>
                    <div class="col-12">
                        <label class="form-label" for="observacionInforme">Observación del comité *</label>
                        <textarea class="form-control" id="observacionInforme" name="observacion" required></textarea>
                    </div>
                </div>
                <div class="d-flex flex-wrap gap-2 mt-3">
                    <button type="submit" name="decision" value="aprobar" class="btn btn-primary rounded-pill app-boton">Aprobar el informe</button>
                    <button type="submit" name="decision" value="aplazar" class="btn btn-outline-dark rounded-pill">Aplazar</button>
                    <button type="submit" name="decision" value="devolver" class="btn btn-outline-dark rounded-pill">Devolver al director</button>
                    <button type="submit" name="decision" value="no-aprobar" class="btn btn-outline-danger rounded-pill"
                            onclick="return confirm('¿No aprobar el informe? Vuelve al estudiante para corregirlo.');">No aprobar</button>
                </div>
            </form>
        </c:if>
    </c:if>
</c:if>

<div class="row g-4">
    <div class="col-lg-6">
        <div class="app-tarjeta h-100">
            <%@ include file="/WEB-INF/jspf/datos-proyecto.jspf" %>
        </div>
    </div>

    <div class="col-lg-6">
        <div class="app-tarjeta h-100">
            <h2 class="app-tarjeta-titulo">Estudiantes</h2>
            <c:set var="idProyectoIntegrantes" value="${p.id}" />
            <c:set var="integrantesDetalle" value="true" />
            <%@ include file="/WEB-INF/jspf/integrantes.jspf" %>
        </div>
    </div>

    <div class="col-lg-6">
        <div class="app-tarjeta h-100">
            <h2 class="app-tarjeta-titulo">Pagos de la modalidad</h2>
            <c:choose>
                <c:when test="${p.estado_pago == 'No aplica'}">
                    <p class="mb-0">Planes posteriores al decreto 1330: el pago lo cubre la matrícula del Seminario de Grado. No hay recibos que revisar.</p>
                </c:when>
                <c:when test="${recibos.rowCount == 0}">
                    <p class="app-vacio mt-0">Ningún estudiante ha subido su recibo.<c:if test="${not empty p.fecha_limite_pago}"> Tienen plazo hasta el <fmt:formatDate value="${p.fecha_limite_pago}" pattern="dd/MM/yyyy" />.</c:if></p>
                </c:when>
                <c:otherwise>
                    <p class="text-secondary">Cada estudiante sube su propio recibo; el estado de cada uno sale en "Estudiantes".</p>
                    <c:set var="estudianteAnterior" value="" />
                    <c:forEach var="r" items="${recibos.rows}">
                        <c:set var="idSubio">${r.subido_por}</c:set>
                        <c:set var="esUltimo" value="${idSubio != estudianteAnterior}" />
                        <c:if test="${esUltimo}"><h3 class="h6 fw-bold mt-3 mb-2"><c:out value="${r.estudiante}" /></h3></c:if>
                        <div class="app-archivo">
                            <span>
                                <span class="app-lista-dato"><c:out value="${r.nombre_archivo}" /></span>
                                <span class="app-lista-nota">Subido el <fmt:formatDate value="${r.subido_en}" pattern="dd/MM/yyyy HH:mm" /></span>
                            </span>
                            <span class="app-acciones">
                                <span class="app-estado ${r.decision == 'Aprobado' ? 'activo' : 'inactivo'}">${empty r.decision ? (esUltimo ? 'Por revisar' : 'Reemplazado') : r.decision}</span>
                                <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/archivos/ver.jsp?id=${r.id}" target="_blank" rel="noopener">Ver</a>
                            </span>
                        </div>
                        <c:if test="${not empty r.decision}">
                            <p class="app-observacion mb-3"><strong>Observación del comité:</strong> <c:out value="${r.observacion}" />
                                <span class="app-lista-nota"><c:out value="${r.revisor}" />, <fmt:formatDate value="${r.revisado_en}" pattern="dd/MM/yyyy HH:mm" /></span></p>
                        </c:if>
                        <c:if test="${esUltimo and empty r.decision and (p.fase == 1 or p.fase == 2)}">
                            <form class="app-revision mb-3" method="post" action="${ctx}/admin/pago-revisar.jsp">
                                <input type="hidden" name="id" value="${r.id}">
                                <textarea class="form-control" name="observacion" placeholder="Observación del comité (obligatoria)" aria-label="Observación sobre el recibo de ${fn:escapeXml(r.estudiante)}" required></textarea>
                                <button type="submit" name="decision" value="aprobar" class="btn btn-sm btn-primary rounded-pill">Aprobar pago</button>
                                <button type="submit" name="decision" value="devolver" class="btn btn-sm btn-outline-dark rounded-pill">Devolver al estudiante</button>
                            </form>
                        </c:if>
                        <c:set var="estudianteAnterior" value="${idSubio}" />
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>
    </div>

    <div class="col-lg-6">
        <form class="app-tarjeta app-formulario h-100" method="post" action="${ctx}/admin/proyecto-asignar.jsp">
            <input type="hidden" name="id" value="${p.id}">
            <h2 class="app-tarjeta-titulo">Director y evaluador</h2>
            <p class="text-secondary">Los asigna el comité. Un docente nunca evalúa el proyecto que dirige. El estudiante ve a su director, pero no a su evaluador.</p>
            <div class="row g-3">
                <div class="col-12">
                    <label class="form-label" for="director">Director *</label>
                    <select class="form-select" id="director" name="director" required>
                        <option value="">Escoge el director</option>
                        <c:forEach var="d" items="${directores.rows}">
                            <c:set var="idOpcion">${d.id}</c:set>
                            <option value="${d.id}" ${idOpcion == idDirector ? 'selected' : ''}><c:out value="${d.nombre}" /></option>
                        </c:forEach>
                    </select>
                    <c:if test="${directores.rowCount == 0}"><div class="form-text">No hay docentes activos con el rol Director. Asígnalo en Usuarios.</div></c:if>
                </div>
                <div class="col-12">
                    <label class="form-label" for="evaluador">Evaluador</label>
                    <select class="form-select" id="evaluador" name="evaluador">
                        <option value="">Sin asignar todavía</option>
                        <c:forEach var="e" items="${evaluadores.rows}">
                            <c:set var="idOpcion">${e.id}</c:set>
                            <option value="${e.id}" ${idOpcion == idEvaluador ? 'selected' : ''}><c:out value="${e.nombre}" /></option>
                        </c:forEach>
                    </select>
                    <div class="form-text">Se puede asignar después: la propuesta le llega cuando el director la envía (fase 3).</div>
                </div>
                <%-- RF13: solo Proyecto de investigación (1) y Desarrollo tecnológico (2) --%>
                <c:if test="${p.modalidad_id == 1 or p.modalidad_id == 2}">
                    <div class="col-12">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" role="switch" id="interdisciplinario" name="interdisciplinario" ${p.interdisciplinario == true ? 'checked' : ''}>
                            <label class="form-check-label" for="interdisciplinario">Proyecto interdisciplinario (hasta 4 estudiantes y 2 codirectores)</label>
                        </div>
                    </div>
                    <c:forEach var="numero" begin="1" end="2">
                        <c:set var="idCodirectorElegido" value="${numero == 1 ? idCodirector1 : idCodirector2}" />
                        <div class="col-md-6">
                            <label class="form-label" for="codirector${numero}">Codirector ${numero}</label>
                            <select class="form-select" id="codirector${numero}" name="codirector${numero}">
                                <option value="">Sin codirector</option>
                                <c:forEach var="d" items="${directores.rows}">
                                    <c:set var="idOpcion">${d.id}</c:set>
                                    <option value="${d.id}" ${idOpcion == idCodirectorElegido ? 'selected' : ''}><c:out value="${d.nombre}" /></option>
                                </c:forEach>
                            </select>
                        </div>
                    </c:forEach>
                    <div class="col-12"><div class="form-text mt-0">Los codirectores solo se guardan si el proyecto es interdisciplinario. Ven el proyecto y dejan observaciones; decide el director.</div></div>
                </c:if>
            </div>
            <button type="submit" class="btn btn-primary rounded-pill app-boton mt-3">Guardar</button>
        </form>
    </div>
</div>

<c:set var="idProyectoHistorial" value="${p.id}" />
<%@ include file="/WEB-INF/jspf/historial-proyecto.jspf" %>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
