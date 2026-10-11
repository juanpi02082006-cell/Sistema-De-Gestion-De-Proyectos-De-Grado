<%-- Un proyecto visto por su evaluador, ?id=... (RF23, RF-56 a RF-62 de la lista del otro
     equipo): los datos, las versiones del FDC-124 con sus anexos y el reporte de Turnitin.
     En la fase 4, cuando el director ya le envió la propuesta, el evaluador la evalúa con
     la rejilla del F-DC-124: solo los criterios que aplican a la modalidad (el estado del
     arte, solo en investigación y desarrollo tecnológico), Cumple Sí o No en cada
     indicador, con observación opcional, y una observación general obligatoria. Puede
     guardarla en borrador; al enviarla da su concepto (Aprobado, Aplazado o No aprobado)
     y pasa al comité. También puede devolverla al director (fase 3) para arreglos.
     Tiene 3 días hábiles (RF21). Lo guarda evaluacion-guardar.jsp. --%>
<%@ include file="/WEB-INF/jspf/solo-evaluador.jspf" %>
<%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
<c:set var="titulo" value="Evaluar propuesta" />
<c:set var="seccion" value="evaluaciones" />

<sql:query var="consulta">
    SELECT p.id, p.codigo, p.titulo, p.descripcion, p.estado, p.fecha_inicio, p.modalidad_id, p.fecha_aprobacion_124,
           f.orden AS fase, m.nombre AS modalidad, n.nombre AS nivel, pr.nombre AS periodo, ${sqlUltimaRevision} AS ultima,
           e.id AS entrega_id, e.version, e.fecha_limite_revision AS limite, (e.fecha_limite_revision < CURDATE()) AS vencido
    FROM proyectos p
    JOIN modalidades m ON m.id = p.modalidad_id
    JOIN niveles n ON n.id = p.nivel_id
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN periodos pr ON pr.id = p.periodo_id
    LEFT JOIN entregas e ON e.proyecto_id = p.id AND e.tipo = 'FDC-124'
         AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = 'FDC-124')
    WHERE p.id = ? AND p.evaluador_id = ?
    <sql:param value="${empty param.id ? 0 : param.id}" />
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/evaluador/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="faseActual" value="${p.fase}" />
<c:set var="porEvaluar" value="${p.fase == 4 and p.ultima == 'Director:Aprobado' and p.estado != 'Finalizado' and p.estado != 'Cancelado'}" />

<c:if test="${porEvaluar}">
    <%-- Borrador guardado de esta versión, si lo hay --%>
    <sql:query var="borrador">
        SELECT id, decision, observacion FROM revisiones
        WHERE entrega_id = ? AND revisor_id = ? AND rol = 'Evaluador' AND estado = 'Borrador'
        ORDER BY id DESC LIMIT 1
        <sql:param value="${p.entrega_id}" />
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
    <c:set var="idBorrador" value="${borrador.rowCount > 0 ? borrador.rows[0].id : 0}" />
    <%-- Indicadores de los criterios que aplican a la modalidad, con lo que tenga el borrador --%>
    <sql:query var="indicadores">
        SELECT c.nombre AS criterio, i.id, i.pregunta,
               (SELECT ri.cumple FROM revision_indicadores ri WHERE ri.revision_id = ? AND ri.indicador_id = i.id) AS cumple,
               (SELECT ri.observacion FROM revision_indicadores ri WHERE ri.revision_id = ? AND ri.indicador_id = i.id) AS observacion
        FROM criterios_rejilla c
        JOIN criterio_modalidades cm ON cm.criterio_id = c.id AND cm.modalidad_id = ?
        JOIN indicadores_rejilla i ON i.criterio_id = c.id
        WHERE c.formato = 'FDC-124'
        ORDER BY c.orden, i.orden
        <sql:param value="${idBorrador}" />
        <sql:param value="${idBorrador}" />
        <sql:param value="${p.modalidad_id}" />
    </sql:query>
</c:if>

<sql:query var="reportesTurnitin">
    SELECT id, nombre_archivo, subido_en FROM entregas WHERE proyecto_id = ? AND tipo = 'Reporte Turnitin' ORDER BY id DESC
    <sql:param value="${p.id}" />
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <a class="app-volver" href="${ctx}/evaluador/proyectos.jsp">← Volver a mis evaluaciones</a>
    <h1><c:out value="${p.titulo}" /></h1>
    <p><c:out value="${p.modalidad}" /> · <c:out value="${p.nivel}" /><c:if test="${not empty p.periodo}"> · Periodo <c:out value="${p.periodo}" /></c:if></p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<%@ include file="/WEB-INF/jspf/fases-proyecto.jspf" %>

<div class="app-tarjeta mb-4">
    <h2 class="app-tarjeta-titulo">Propuesta (FDC-124)</h2>
    <c:choose>
        <c:when test="${porEvaluar}">
            <p class="text-secondary">El director aprobó la versión <c:out value="${p.version}" /> y te la envió.
                <c:if test="${not empty p.limite}">Tienes hasta el <fmt:formatDate value="${p.limite}" pattern="dd/MM/yyyy" /> (3 días hábiles).</c:if></p>
            <c:if test="${p.vencido == 1}"><div class="alert alert-warning app-aviso" role="status">Se venció el plazo para evaluar esta propuesta. No hay aprobación automática: evalúala cuanto antes.</div></c:if>
        </c:when>
        <c:when test="${not empty p.fecha_aprobacion_124}"><p class="text-secondary">El comité aprobó la propuesta.</p></c:when>
        <c:when test="${p.ultima == 'Evaluador:Devuelto'}"><p class="text-secondary">Devolviste la propuesta al director para arreglos.</p></c:when>
        <c:when test="${fn:startsWith(p.ultima, 'Evaluador:')}"><p class="text-secondary">Enviaste tu evaluación. La decisión final es del comité.</p></c:when>
        <c:when test="${p.fase < 4}"><p class="text-secondary">La propuesta todavía no te llega: el director te la envía cuando la apruebe.</p></c:when>
    </c:choose>
    <c:set var="idProyectoPropuesta" value="${p.id}" />
    <%@ include file="/WEB-INF/jspf/propuesta-versiones.jspf" %>
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
    <c:if test="${not porEvaluar}">
        <c:set var="idProyectoEvaluacion" value="${p.id}" />
        <c:set var="evaluacionConEvaluador" value="false" />
        <%@ include file="/WEB-INF/jspf/evaluacion-propuesta.jspf" %>
    </c:if>
</div>

<c:if test="${porEvaluar}">
    <form class="app-tarjeta app-formulario mb-4" method="post" action="${ctx}/evaluador/evaluacion-guardar.jsp">
        <input type="hidden" name="id" value="${p.id}">
        <h2 class="app-tarjeta-titulo">Rejilla de evaluación (F-DC-124)</h2>
        <p class="text-secondary">
            Marca si cumple cada indicador. Para dar el concepto "Aprobado" deben cumplirse todos.
            Puedes guardar en borrador y seguir después; al enviarla ya no se puede cambiar y pasa al comité, que da la decisión final.
            <c:if test="${p.modalidad_id == 3 or p.modalidad_id == 4}">En <c:out value="${p.modalidad}" /> no se evalúa el estado del arte.</c:if>
        </p>
        <c:if test="${idBorrador != 0}"><div class="alert alert-success app-aviso" role="status">Tienes un borrador guardado de esta evaluación.</div></c:if>
        <c:set var="criterioAnterior" value="" />
        <c:forEach var="ind" items="${indicadores.rows}">
            <c:if test="${ind.criterio != criterioAnterior}">
                <c:if test="${not empty criterioAnterior}"></ul></c:if>
                <h3 class="h6 fw-bold mt-4 mb-0"><c:out value="${ind.criterio}" /></h3>
                <ul class="app-lista app-rejilla">
            </c:if>
            <li>
                <span class="app-rejilla-pregunta" id="pregunta${ind.id}"><c:out value="${ind.pregunta}" /></span>
                <span class="app-casillas" role="radiogroup" aria-labelledby="pregunta${ind.id}">
                    <label class="app-casilla"><input type="radio" name="r${ind.id}" value="si" ${ind.cumple == 'Sí' ? 'checked' : ''}><span>Sí</span></label>
                    <label class="app-casilla"><input type="radio" name="r${ind.id}" value="no" ${ind.cumple == 'No' ? 'checked' : ''}><span>No</span></label>
                </span>
                <input class="form-control form-control-sm app-rejilla-observacion" type="text" name="o${ind.id}" maxlength="500"
                       value="${fn:escapeXml(ind.observacion)}" placeholder="Observación (opcional)" aria-label="Observación del indicador">
            </li>
            <c:set var="criterioAnterior" value="${ind.criterio}" />
        </c:forEach>
        <c:if test="${not empty criterioAnterior}"></ul></c:if>

        <div class="row g-3 mt-2">
            <div class="col-md-4">
                <label class="form-label" for="concepto">Concepto</label>
                <c:set var="conceptoBorrador" value="${idBorrador != 0 ? borrador.rows[0].decision : ''}" />
                <select class="form-select" id="concepto" name="concepto">
                    <option value="">Escoge el concepto</option>
                    <c:forEach var="co" items="Aprobado,Aplazado,No aprobado">
                        <option value="${co}" ${co == conceptoBorrador ? 'selected' : ''}>${co}</option>
                    </c:forEach>
                </select>
            </div>
            <div class="col-md-8">
                <label class="form-label" for="observacionGeneral">Observaciones generales (obligatorias para enviar)</label>
                <textarea class="form-control" id="observacionGeneral" name="observacion"><c:out value="${idBorrador != 0 ? borrador.rows[0].observacion : ''}" /></textarea>
            </div>
        </div>
        <div class="d-flex flex-wrap gap-2 mt-3">
            <button type="submit" name="accion" value="borrador" class="btn btn-outline-dark rounded-pill">Guardar borrador</button>
            <button type="submit" name="accion" value="enviar" class="btn btn-primary rounded-pill app-boton"
                    onclick="return confirm('¿Enviar la evaluación al comité? Ya no podrás cambiarla.');">Enviar evaluación al comité</button>
        </div>
    </form>

    <form class="app-tarjeta app-formulario mb-4" method="post" action="${ctx}/evaluador/evaluacion-guardar.jsp">
        <input type="hidden" name="id" value="${p.id}">
        <input type="hidden" name="accion" value="devolver">
        <h2 class="app-tarjeta-titulo">Devolver al director</h2>
        <p class="text-secondary">Si a la propuesta le falta algo antes de evaluarla (por ejemplo la firma o el reporte de Turnitin), devuélvesela al director: el proyecto vuelve a la fase 3.</p>
        <label class="form-label" for="observacionDevolver">Qué falta *</label>
        <textarea class="form-control" id="observacionDevolver" name="observacion" required></textarea>
        <button type="submit" class="btn btn-outline-dark rounded-pill mt-3">Devolver al director</button>
    </form>
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
            <c:set var="integrantesDetalle" value="false" />
            <%@ include file="/WEB-INF/jspf/integrantes.jspf" %>
        </div>
    </div>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
