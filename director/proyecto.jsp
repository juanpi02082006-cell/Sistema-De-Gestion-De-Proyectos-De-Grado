<%-- Un proyecto visto por su director o codirector, ?id=...: sus fases, la información
     de los estudiantes (RF19) y las versiones de la propuesta FDC-124 (RF18, RF43).
     En la fase 3 el director la revisa: la devuelve o la aprueba con el reporte de
     Turnitin y la envía al evaluador y al comité (propuesta-revisar.jsp). Aquí solo se
     dice si ya hay evaluador, no quién es. --%>
<%@ include file="/WEB-INF/jspf/solo-director.jspf" %>
<c:set var="titulo" value="Proyecto" />
<c:set var="seccion" value="dirigidos" />

<sql:query var="consulta">
    SELECT p.id, p.codigo, p.titulo, p.descripcion, p.estado, p.fecha_inicio, p.modalidad_id,
           f.orden AS fase, f.nombre AS nombre_fase, m.nombre AS modalidad, n.nombre AS nivel,
           pr.nombre AS periodo, pr.fecha_limite_propuestas,
           (p.director_id = ?) AS es_director, (p.evaluador_id IS NOT NULL) AS tiene_evaluador,
           (SELECT MAX(e.version) FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124') AS version_propuesta
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

<sql:query var="integrantes">
    SELECT u.nombre, u.correo, u.celular, u.carrera, n.nombre AS nivel, u.plan_estudios, u.porcentaje_creditos
    FROM proyecto_estudiantes pe
    JOIN usuarios u ON u.id = pe.estudiante_id
    LEFT JOIN niveles n ON n.id = u.nivel_id
    WHERE pe.proyecto_id = ? AND pe.vigente = 1 ORDER BY u.nombre
    <sql:param value="${p.id}" />
</sql:query>
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

<c:if test="${p.modalidad_id != 5 and p.fase >= 2}">
    <div class="app-tarjeta mb-4">
        <h2 class="app-tarjeta-titulo">Propuesta (FDC-124)</h2>
        <c:choose>
            <c:when test="${p.fase == 2}"><p class="text-secondary">El estudiante está diligenciando la propuesta; te llega cuando te la envíe.</p></c:when>
            <c:when test="${p.fase == 3}"><p class="text-secondary">El estudiante te envió la versión <c:out value="${p.version_propuesta}" /> para revisarla.</p></c:when>
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

    <%-- Fase 3: la revisión del director (solo el director, no los codirectores) --%>
    <c:if test="${p.fase == 3 and p.es_director == 1}">
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
            <div class="app-acciones mt-3">
                <button type="submit" name="decision" value="devolver" class="btn btn-outline-dark rounded-pill">Devolver al estudiante</button>
                <button type="submit" name="decision" value="aprobar" class="btn btn-primary rounded-pill app-boton" ${p.tiene_evaluador == 1 ? '' : 'disabled'}>Aprobar y enviar al evaluador y al comité</button>
            </div>
        </form>
    </c:if>
</c:if>

<div class="row g-4">
    <div class="col-lg-5">
        <div class="app-tarjeta h-100">
            <h2 class="app-tarjeta-titulo">Datos del proyecto</h2>
            <c:if test="${not empty p.descripcion}"><p class="text-secondary"><c:out value="${p.descripcion}" /></p></c:if>
            <dl class="app-datos">
                <dt>Código</dt><dd><c:out value="${empty p.codigo ? 'Sin asignar' : p.codigo}" /></dd>
                <dt>Estado</dt><dd><c:out value="${p.estado}" /></dd>
                <c:if test="${not empty p.fecha_inicio}"><dt>Inicio</dt><dd><fmt:formatDate value="${p.fecha_inicio}" pattern="dd/MM/yyyy" /></dd></c:if>
                <c:if test="${not empty p.fecha_limite_propuestas}"><dt>Aprobar la propuesta antes del</dt><dd><fmt:formatDate value="${p.fecha_limite_propuestas}" pattern="dd/MM/yyyy" /></dd></c:if>
            </dl>
        </div>
    </div>
    <div class="col-lg-7">
        <div class="app-tarjeta h-100">
            <h2 class="app-tarjeta-titulo">Estudiantes</h2>
            <ul class="app-lista">
                <c:forEach var="i" items="${integrantes.rows}">
                    <li>
                        <span>
                            <span class="app-lista-dato"><c:out value="${i.nombre}" /></span>
                            <span class="app-lista-nota"><c:out value="${i.correo}" /><c:if test="${not empty i.celular}"> · <c:out value="${i.celular}" /></c:if></span>
                            <span class="app-lista-nota"><c:out value="${i.carrera}" /> · <c:out value="${i.nivel}" /> · plan <c:out value="${empty i.plan_estudios ? 'sin registrar' : fn:toLowerCase(i.plan_estudios)}" /><c:if test="${not empty i.porcentaje_creditos}"> · <c:out value="${i.porcentaje_creditos}" /> % de créditos</c:if></span>
                        </span>
                    </li>
                </c:forEach>
            </ul>
        </div>
    </div>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
