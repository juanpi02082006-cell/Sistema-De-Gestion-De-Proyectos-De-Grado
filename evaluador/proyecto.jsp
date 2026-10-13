<%-- Un proyecto visto por su evaluador, ?id=... (RF23, RF-56 a RF-62 de la lista del otro
     equipo): los datos, las versiones del FDC-124 con sus anexos, los reportes de
     Turnitin y, después, las versiones del informe final.
     Fase 4: cuando el director le envía la propuesta, la evalúa con la rejilla del
     F-DC-124 (3 días hábiles, RF21) o la devuelve al director (fase 3) para arreglos.
     Fase 5: cuando el director le envía el informe final, lo evalúa con la rejilla del
     F-DC-129, con N/A (5 días hábiles); si lo aplaza, indica el plazo para las
     correcciones (RF22). En los dos casos puede guardar en borrador; al enviar da su
     concepto y pasa al comité (rejilla-formulario.jspf, evaluacion-guardar.jsp).
     Fase final: programa la sustentación con los estudiantes y el director (RF39,
     sustentacion.jspf). --%>
<%@ include file="/WEB-INF/jspf/solo-evaluador.jspf" %>
<%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
<c:set var="titulo" value="Evaluar" />
<c:set var="seccion" value="evaluaciones" />

<sql:query var="consulta">
    SELECT p.id, p.codigo, p.titulo, p.descripcion, p.estado, p.fecha_inicio, p.modalidad_id, p.fecha_aprobacion_124, p.fecha_limite,
           f.orden AS fase, m.nombre AS modalidad, n.nombre AS nivel, pr.nombre AS periodo,
           ${sqlUltimaRevision} AS ultima, ${sqlUltimaRevisionInforme} AS ultima_informe,
           e.id AS entrega_id, e.version, e.fecha_limite_revision AS limite, (e.fecha_limite_revision < CURDATE()) AS vencido,
           ei.id AS informe_id, ei.version AS version_informe, ei.fecha_limite_revision AS limite_informe,
           (ei.fecha_limite_revision < CURDATE()) AS informe_vencido
    FROM proyectos p
    JOIN modalidades m ON m.id = p.modalidad_id
    JOIN niveles n ON n.id = p.nivel_id
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN periodos pr ON pr.id = p.periodo_id
    LEFT JOIN entregas e ON e.proyecto_id = p.id AND e.tipo = 'FDC-124'
         AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = 'FDC-124')
    LEFT JOIN entregas ei ON ei.proyecto_id = p.id AND ei.tipo = 'FDC-125'
         AND ei.version = (SELECT MAX(e3.version) FROM entregas e3 WHERE e3.proyecto_id = p.id AND e3.tipo = 'FDC-125')
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
<c:set var="estadoProyecto" value="${p.estado}" />
<c:set var="cerrado" value="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}" />
<c:set var="porEvaluar" value="${p.fase == 4 and p.ultima == 'Director:Aprobado' and not cerrado}" />
<c:set var="informePorEvaluar" value="${p.fase == 5 and p.ultima_informe == 'Director:Aprobado' and not cerrado}" />

<sql:query var="reportesTurnitin">
    SELECT t.id, t.nombre_archivo, t.subido_en, f.orden AS fase FROM entregas t LEFT JOIN fases f ON f.id = t.fase_id
    WHERE t.proyecto_id = ? AND t.tipo = 'Reporte Turnitin' ORDER BY t.id DESC
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

<%-- Fase final (RF39): la sustentación, que el evaluador también programa --%>
<c:if test="${p.fase == 6 and p.modalidad_id != 5}">
    <c:set var="idProyectoSustentacion" value="${p.id}" />
    <c:set var="sustentacionProgramar" value="${not cerrado}" />
    <%@ include file="/WEB-INF/jspf/sustentacion.jspf" %>
</c:if>

<%-- Informe final (fase 5 en adelante) --%>
<c:if test="${not empty p.informe_id and p.fase >= 5}">
    <div class="app-tarjeta mb-4">
        <h2 class="app-tarjeta-titulo">Informe final (FDC-125)</h2>
        <c:choose>
            <c:when test="${informePorEvaluar}">
                <p class="text-secondary">El director aprobó la versión <c:out value="${p.version_informe}" /> del informe final y te la envió.
                    <c:if test="${not empty p.limite_informe}">Tienes hasta el <fmt:formatDate value="${p.limite_informe}" pattern="dd/MM/yyyy" /> (5 días hábiles).</c:if></p>
                <c:if test="${p.informe_vencido == 1}"><div class="alert alert-warning app-aviso" role="status">Se venció el plazo para evaluar este informe. No hay aprobación automática: evalúalo cuanto antes.</div></c:if>
            </c:when>
            <c:when test="${p.fase == 6}"><p class="text-secondary">${p.estado == 'Finalizado' ? 'El comité aprobó el informe final y, después de la sustentación, registró la aprobación final del proyecto.' : 'El comité aprobó el informe final: el proyecto está en la fase final (sustentación).'}</p></c:when>
            <c:when test="${fn:startsWith(p.ultima_informe, 'Evaluador:')}"><p class="text-secondary">Enviaste tu evaluación. La decisión final es del comité.</p></c:when>
            <c:otherwise><p class="text-secondary">El director está revisando el informe; te llega cuando lo apruebe.</p></c:otherwise>
        </c:choose>
        <c:set var="idProyectoInforme" value="${p.id}" />
        <%@ include file="/WEB-INF/jspf/informe-final.jspf" %>
        <c:if test="${not informePorEvaluar}">
            <c:set var="idProyectoEvaluacion" value="${p.id}" />
            <c:set var="evaluacionConEvaluador" value="false" />
            <c:set var="evaluacionInforme" value="true" />
            <%@ include file="/WEB-INF/jspf/evaluacion-propuesta.jspf" %>
        </c:if>
    </div>
    <c:if test="${informePorEvaluar}">
        <c:set var="rejillaEntrega" value="${p.informe_id}" />
        <c:set var="rejillaInforme" value="true" />
        <%@ include file="/WEB-INF/jspf/rejilla-formulario.jspf" %>
    </c:if>
</c:if>

<%-- Mientras se evalúa va abierta; aprobada por el comité, queda plegada para consultar --%>
<details class="app-tarjeta app-historial mb-4" ${empty p.fecha_aprobacion_124 ? 'open' : ''}>
    <summary>Propuesta (FDC-124)<c:if test="${not empty p.fecha_aprobacion_124}"><span class="text-secondary fw-normal"> · aprobada el <fmt:formatDate value="${p.fecha_aprobacion_124}" pattern="dd/MM/yyyy" /></span></c:if></summary>
    <div class="mt-3"></div>
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
                    <span class="app-lista-nota">${t.fase == 5 ? 'Del informe final' : 'De la propuesta'} · subido por el director el <fmt:formatDate value="${t.subido_en}" pattern="dd/MM/yyyy HH:mm" /></span>
                </span>
                <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/archivos/ver.jsp?id=${t.id}" target="_blank" rel="noopener">Ver</a>
            </div>
        </c:forEach>
    </c:if>
    <c:if test="${not porEvaluar}">
        <c:set var="idProyectoEvaluacion" value="${p.id}" />
        <c:set var="evaluacionConEvaluador" value="false" />
        <c:set var="evaluacionInforme" value="false" />
        <%@ include file="/WEB-INF/jspf/evaluacion-propuesta.jspf" %>
    </c:if>
</details>

<c:if test="${porEvaluar}">
    <c:set var="rejillaEntrega" value="${p.entrega_id}" />
    <c:set var="rejillaInforme" value="false" />
    <%@ include file="/WEB-INF/jspf/rejilla-formulario.jspf" %>

    <form class="app-tarjeta app-formulario mb-4" method="post" action="${ctx}/evaluador/evaluacion-guardar.jsp">
        <input type="hidden" name="id" value="${p.id}">
        <input type="hidden" name="documento" value="propuesta">
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
            <c:set var="datosOcultarLimite" value="${cerrado or not empty p.fecha_aprobacion_124}" />
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
