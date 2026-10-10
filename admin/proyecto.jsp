<%-- Un proyecto visto por el comité (el administrador), ?id=...: sus fases, sus datos,
     la revisión del recibo de pago (RF32, con observación obligatoria, RF34) y la
     asignación del director y del evaluador (RF11; un docente nunca evalúa el proyecto
     que dirige). Cuando el pago está aprobado (o no aplica) y tiene director, el
     proyecto pasa a la fase 2 (avanzar-fase-2.jspf). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<c:set var="titulo" value="Proyecto" />
<c:set var="seccion" value="proyectos" />

<sql:query var="consulta">
    SELECT p.id, p.codigo, p.titulo, p.descripcion, p.estado, p.director_id, p.evaluador_id, p.fecha_inicio, p.modalidad_id,
           f.orden AS fase, f.nombre AS nombre_fase, m.nombre AS modalidad, n.nombre AS nivel,
           pr.nombre AS periodo, pr.fecha_limite_pago, ${sqlEstadoPago} AS estado_pago
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

<sql:query var="integrantes">
    SELECT u.nombre, u.correo, u.carrera, u.plan_estudios FROM proyecto_estudiantes pe JOIN usuarios u ON u.id = pe.estudiante_id
    WHERE pe.proyecto_id = ? AND pe.vigente = 1 ORDER BY u.nombre
    <sql:param value="${p.id}" />
</sql:query>
<%-- Recibos, del más reciente al más antiguo, con la revisión del comité si la tienen --%>
<sql:query var="recibos">
    SELECT e.id, e.nombre_archivo, e.subido_en, r.decision, r.observacion, r.revisado_en, u.nombre AS revisor
    FROM entregas e
    LEFT JOIN revisiones r ON r.entrega_id = e.id AND r.rol = 'Comité' AND r.estado = 'Enviada'
    LEFT JOIN usuarios u ON u.id = r.revisor_id
    WHERE e.proyecto_id = ? AND e.tipo = 'Recibo de pago'
    ORDER BY e.id DESC
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

<c:if test="${p.fase == 1}">
    <c:set var="pagoListo" value="${p.estado_pago == 'Aprobado' or p.estado_pago == 'No aplica'}" />
    <div class="app-tarjeta mb-4">
        <h2 class="app-tarjeta-titulo">Para pasar a la fase 2</h2>
        <ul class="app-lista">
            <li>
                <span><span class="app-lista-dato">Pago aprobado por el comité</span><span class="app-lista-nota">En los planes nuevos lo cubre la matrícula, salvo en Seminario.</span></span>
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
    </div>
</c:if>

<div class="row g-4">
    <div class="col-lg-6">
        <div class="app-tarjeta h-100">
            <h2 class="app-tarjeta-titulo">Datos del proyecto</h2>
            <c:if test="${not empty p.descripcion}"><p class="text-secondary"><c:out value="${p.descripcion}" /></p></c:if>
            <dl class="app-datos">
                <dt>Código</dt><dd><c:out value="${empty p.codigo ? 'Sin asignar' : p.codigo}" /></dd>
                <dt>Fase</dt><dd><c:choose><c:when test="${p.fase == 6}">Fase final</c:when><c:otherwise>Fase <c:out value="${p.fase}" /></c:otherwise></c:choose>: <c:out value="${p.nombre_fase}" /></dd>
                <dt>Estado</dt><dd><c:out value="${p.estado}" /></dd>
                <c:if test="${not empty p.fecha_inicio}"><dt>Inicio</dt><dd><fmt:formatDate value="${p.fecha_inicio}" pattern="dd/MM/yyyy" /></dd></c:if>
                <dt>Integrantes</dt>
                <dd>
                    <c:forEach var="i" items="${integrantes.rows}">
                        <span class="d-block"><c:out value="${i.nombre}" /> <span class="app-lista-nota d-inline">· <c:out value="${i.correo}" /> · plan <c:out value="${empty i.plan_estudios ? 'sin registrar' : fn:toLowerCase(i.plan_estudios)}" /></span></span>
                    </c:forEach>
                </dd>
            </dl>
        </div>
    </div>

    <div class="col-lg-6">
        <div class="app-tarjeta h-100">
            <h2 class="app-tarjeta-titulo">Pago de la modalidad (fase 1)</h2>
            <c:choose>
                <c:when test="${p.estado_pago == 'No aplica'}">
                    <p class="mb-0">Plan posterior al decreto 1330: el pago lo cubre la matrícula del Seminario de Grado. No hay recibo que revisar.</p>
                </c:when>
                <c:when test="${recibos.rowCount == 0}">
                    <p class="app-vacio mt-0">El estudiante todavía no ha subido el recibo.<c:if test="${not empty p.fecha_limite_pago}"> Tiene plazo hasta el <fmt:formatDate value="${p.fecha_limite_pago}" pattern="dd/MM/yyyy" />.</c:if></p>
                </c:when>
                <c:otherwise>
                    <c:forEach var="r" items="${recibos.rows}" varStatus="s">
                        <div class="app-archivo">
                            <span>
                                <span class="app-lista-dato"><c:out value="${r.nombre_archivo}" /></span>
                                <span class="app-lista-nota">Subido el <fmt:formatDate value="${r.subido_en}" pattern="dd/MM/yyyy HH:mm" /></span>
                            </span>
                            <span class="app-acciones">
                                <span class="app-estado ${r.decision == 'Aprobado' ? 'activo' : 'inactivo'}">${empty r.decision ? (s.first ? 'Por revisar' : 'Reemplazado') : r.decision}</span>
                                <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/archivos/ver.jsp?id=${r.id}" target="_blank" rel="noopener">Ver</a>
                            </span>
                        </div>
                        <c:if test="${not empty r.decision}">
                            <p class="app-observacion mb-3"><strong>Observación del comité:</strong> <c:out value="${r.observacion}" />
                                <span class="app-lista-nota"><c:out value="${r.revisor}" />, <fmt:formatDate value="${r.revisado_en}" pattern="dd/MM/yyyy HH:mm" /></span></p>
                        </c:if>
                    </c:forEach>
                    <c:if test="${p.fase == 1 and p.estado_pago == 'Por revisar'}">
                        <form class="app-revision" method="post" action="${ctx}/admin/pago-revisar.jsp">
                            <input type="hidden" name="id" value="${recibos.rows[0].id}">
                            <textarea class="form-control" name="observacion" placeholder="Observación del comité (obligatoria)" aria-label="Observación" required></textarea>
                            <button type="submit" name="decision" value="aprobar" class="btn btn-sm btn-primary rounded-pill">Aprobar pago</button>
                            <button type="submit" name="decision" value="devolver" class="btn btn-sm btn-outline-dark rounded-pill">Devolver al estudiante</button>
                        </form>
                    </c:if>
                    <c:if test="${p.estado_pago == 'Devuelto'}">
                        <p class="app-total">El estudiante debe subir el recibo otra vez.</p>
                    </c:if>
                </c:otherwise>
            </c:choose>
        </div>
    </div>

    <div class="col-12">
        <form class="app-tarjeta app-formulario" method="post" action="${ctx}/admin/proyecto-asignar.jsp">
            <input type="hidden" name="id" value="${p.id}">
            <h2 class="app-tarjeta-titulo">Director y evaluador</h2>
            <p class="text-secondary">Los asigna el comité. Un docente nunca evalúa el proyecto que dirige. El estudiante ve a su director, pero no a su evaluador.</p>
            <div class="row g-3">
                <div class="col-md-6">
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
                <div class="col-md-6">
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
            </div>
            <button type="submit" class="btn btn-primary rounded-pill app-boton mt-3">Guardar</button>
        </form>
    </div>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
