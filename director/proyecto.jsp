<%-- Un proyecto visto por su director o codirector, ?id=...: sus fases, la información
     de los estudiantes (RF19) y las versiones de la propuesta FDC-124 (RF18, RF43).
     En la fase 3 el director la revisa: la devuelve o la aprueba con el reporte de
     Turnitin y la envía al evaluador y al comité (propuesta-revisar.jsp). Aquí solo se
     dice si ya hay evaluador, no quién es. --%>
<%@ include file="/WEB-INF/jspf/solo-director.jspf" %>
<c:set var="titulo" value="Proyecto" />
<c:set var="seccion" value="dirigidos" />

<sql:query var="consulta">
    SELECT p.id, p.codigo, p.titulo, p.descripcion, p.estado, p.fecha_inicio, p.modalidad_id, p.nota_final,
           f.orden AS fase, f.nombre AS nombre_fase, m.nombre AS modalidad, n.nombre AS nivel,
           pr.nombre AS periodo, pr.fecha_limite_propuestas,
           (p.director_id = ?) AS es_director, (p.evaluador_id IS NOT NULL) AS tiene_evaluador,
           (SELECT MAX(e.version) FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124') AS version_propuesta,
           (SELECT e.fecha_limite_revision FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124'
            ORDER BY e.version DESC LIMIT 1) AS limite_director,
           (SELECT e.fecha_limite_revision < CURDATE() FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124'
            ORDER BY e.version DESC LIMIT 1) AS director_vencido,
           DATEDIFF(pr.fecha_limite_propuestas, CURDATE()) AS dias_semana12
    FROM proyectos p
    JOIN modalidades m ON m.id = p.modalidad_id
    JOIN niveles n ON n.id = p.nivel_id
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN periodos pr ON pr.id = p.periodo_id
    WHERE p.id = ?
      AND (p.director_id = ? OR EXISTS (SELECT 1 FROM proyecto_codirectores pc WHERE pc.proyecto_id = p.id AND pc.docente_id = ?))
    <sql:param value="${sessionScope.usuario.id}" />
    <sql:param value="${empty param.id ? 0 : param.id}" />
    <sql:param value="${sessionScope.usuario.id}" />
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/director/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="faseActual" value="${p.fase}" />
<c:set var="esSeminario" value="${p.modalidad_id == 5}" />
<c:set var="estadoSeminario" value="${p.estado}" />

<sql:query var="reportesTurnitin">
    SELECT id, nombre_archivo, subido_en FROM entregas WHERE proyecto_id = ? AND tipo = 'Reporte Turnitin' ORDER BY id DESC
    <sql:param value="${p.id}" />
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <a class="app-volver" href="${ctx}/director/proyectos.jsp">← Volver a mis proyectos</a>
    <h1><c:out value="${p.titulo}" /></h1>
    <p><c:out value="${p.modalidad}" /> · <c:out value="${p.nivel}" /><c:if test="${not empty p.periodo}"> · Periodo <c:out value="${p.periodo}" /></c:if></p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<%@ include file="/WEB-INF/jspf/fases-proyecto.jspf" %>

<%-- Seminario (RF17): el docente del seminario (el director) registra la nota final --%>
<c:if test="${esSeminario}">
    <c:choose>
        <c:when test="${p.estado == 'Pendiente'}">
            <div class="app-resultado mb-4"><h2>Inscripción en trámite</h2><p>El comité todavía no valida la inscripción al seminario.</p></div>
        </c:when>
        <c:when test="${p.estado == 'En curso' and p.es_director == 1}">
            <form class="app-tarjeta app-formulario mb-4" method="post" action="${ctx}/director/nota-registrar.jsp">
                <input type="hidden" name="id" value="${p.id}">
                <h2 class="app-tarjeta-titulo">Nota final del seminario</h2>
                <p class="text-secondary">Al terminar las clases y el entregable, registra la nota final (de 0.0 a 5.0). Con 3.0 o más el requisito queda cumplido y el proyecto termina; con menos, el proyecto se cancela.</p>
                <div class="row g-3">
                    <div class="col-sm-3">
                        <label class="form-label" for="nota">Nota *</label>
                        <input class="form-control" type="number" id="nota" name="nota" min="0" max="5" step="0.1" required>
                    </div>
                    <div class="col-sm-9">
                        <label class="form-label" for="observacionNota">Observación *</label>
                        <textarea class="form-control" id="observacionNota" name="observacion" required></textarea>
                    </div>
                </div>
                <button type="submit" class="btn btn-primary rounded-pill app-boton mt-3">Registrar la nota</button>
            </form>
        </c:when>
        <c:when test="${not empty p.nota_final}">
            <div class="app-resultado ${p.estado == 'Finalizado' ? 'cumple' : ''} mb-4">
                <h2>Nota final: <fmt:formatNumber value="${p.nota_final}" minFractionDigits="1" maxFractionDigits="1" /></h2>
                <p>${p.estado == 'Finalizado' ? 'Aprobado: el proyecto terminó.' : 'Reprobado: el proyecto se canceló.'}</p>
            </div>
        </c:when>
    </c:choose>
</c:if>

<c:if test="${p.modalidad_id != 5 and p.fase >= 2}">
    <div class="app-tarjeta mb-4">
        <h2 class="app-tarjeta-titulo">Propuesta (FDC-124)</h2>
        <c:choose>
            <c:when test="${p.fase == 2}"><p class="text-secondary">El estudiante está diligenciando la propuesta; te llega cuando te la envíe.</p></c:when>
            <c:when test="${p.fase == 3}">
                <p class="text-secondary">El estudiante te envió la versión <c:out value="${p.version_propuesta}" /> para revisarla.
                    <c:if test="${not empty p.limite_director}">Tienes hasta el <fmt:formatDate value="${p.limite_director}" pattern="dd/MM/yyyy" /> (5 días hábiles).</c:if>
                    <c:if test="${not empty p.dias_semana12 and p.dias_semana12 >= 0}">Faltan <c:out value="${p.dias_semana12}" /> días para el límite de la semana 12.</c:if></p>
                <c:if test="${p.director_vencido == 1}"><div class="alert alert-warning app-aviso" role="status">Se venció el plazo para revisar esta propuesta. No hay aprobación automática: revísala cuanto antes.</div></c:if>
            </c:when>
            <c:when test="${p.fase == 4}"><p class="text-secondary">Aprobaste la propuesta y la enviaste al evaluador y al comité.</p></c:when>
        </c:choose>
        <c:set var="idProyectoPropuesta" value="${p.id}" />
        <%@ include file="/WEB-INF/jspf/propuesta-versiones.jspf" %>

        <c:if test="${reportesTurnitin.rowCount > 0}">
            <h3 class="h6 fw-bold mt-4 mb-2">Reportes de Turnitin</h3>
            <c:forEach var="t" items="${reportesTurnitin.rows}">
                <div class="app-archivo">
                    <span>
                        <span class="app-lista-dato"><c:out value="${t.nombre_archivo}" /></span>
                        <span class="app-lista-nota">Subido el <fmt:formatDate value="${t.subido_en}" pattern="dd/MM/yyyy HH:mm" /></span>
                    </span>
                    <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/archivos/ver.jsp?id=${t.id}" target="_blank" rel="noopener">Ver</a>
                </div>
            </c:forEach>
        </c:if>
    </div>

    <%-- Fase 3: los codirectores dejan observaciones; decide el director (RF13) --%>
    <c:if test="${p.fase == 3 and p.es_director != 1 and p.estado != 'Finalizado' and p.estado != 'Cancelado'}">
        <form class="app-tarjeta app-formulario mb-4" method="post" action="${ctx}/director/propuesta-observar.jsp">
            <input type="hidden" name="id" value="${p.id}">
            <h2 class="app-tarjeta-titulo">Observación de codirector sobre la versión <c:out value="${p.version_propuesta}" /></h2>
            <p class="text-secondary">Como codirector puedes dejar observaciones de forma y contenido. La decisión de devolverla o aprobarla es del director.</p>
            <label class="form-label" for="observacionCodirector">Observación *</label>
            <textarea class="form-control" id="observacionCodirector" name="observacion" required></textarea>
            <button type="submit" class="btn btn-primary rounded-pill app-boton mt-3">Enviar observación</button>
        </form>
    </c:if>

    <%-- Fase 3: la revisión del director (solo el director, no los codirectores) --%>
    <c:if test="${p.fase == 3 and p.es_director == 1 and p.estado != 'Finalizado' and p.estado != 'Cancelado'}">
        <form class="app-tarjeta app-formulario mb-4" method="post" action="${ctx}/director/propuesta-revisar.jsp" enctype="multipart/form-data">
            <input type="hidden" name="id" value="${p.id}">
            <h2 class="app-tarjeta-titulo">Revisar la versión <c:out value="${p.version_propuesta}" /></h2>
            <p class="text-secondary">
                Deja tus observaciones de forma y contenido (obligatorias). Si falta algo, devuélvela al estudiante: el proyecto vuelve a la fase 2.
                Si está lista, pásala por Turnitin (similitud máxima del 10 %), sube el reporte y envíala al evaluador y al comité: el proyecto pasa a la fase 4.
            </p>
            <c:if test="${p.tiene_evaluador != 1}">
                <div class="alert alert-warning app-aviso" role="status">El comité todavía no asigna el evaluador de este proyecto: puedes devolver la propuesta, pero no enviarla.</div>
            </c:if>
            <div class="row g-3">
                <div class="col-12">
                    <label class="form-label" for="observacion">Observaciones *</label>
                    <textarea class="form-control" id="observacion" name="observacion" required></textarea>
                </div>
                <div class="col-lg-7">
                    <label class="form-label" for="turnitin">Reporte de Turnitin (PDF, solo para aprobar)</label>
                    <input class="form-control" type="file" id="turnitin" name="turnitin" accept="application/pdf,.pdf">
                </div>
            </div>
            <div class="d-flex flex-wrap gap-2 mt-3">
                <button type="submit" name="decision" value="devolver" class="btn btn-outline-dark rounded-pill">Devolver al estudiante</button>
                <button type="submit" name="decision" value="aprobar" class="btn btn-primary rounded-pill app-boton text-wrap" ${p.tiene_evaluador == 1 ? '' : 'disabled'}>Aprobar y enviar al evaluador y al comité</button>
            </div>
        </form>
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
</div>

<c:set var="idProyectoHistorial" value="${p.id}" />
<%@ include file="/WEB-INF/jspf/historial-proyecto.jspf" %>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
