<%-- Mi proyecto (estudiante): los datos del proyecto vigente, su avance por fases
     (RF2, RF37) y el pago de la fase 1 (RF29, RF32), con la revisión del comité. El
     estudiante no ve a su evaluador (RF27). --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<c:set var="titulo" value="Mi proyecto" />
<c:set var="seccion" value="proyecto" />
<c:set var="idEstudiante" value="${sessionScope.usuario.id}" />

<sql:query var="consulta">
    SELECT p.id, p.codigo, p.titulo, p.descripcion, p.estado, p.modalidad_id, f.orden AS fase,
           m.nombre AS modalidad, n.nombre AS nivel, pe2.nombre AS periodo, pe2.id AS periodo_id,
           pe2.fecha_limite_pago, (pe2.fecha_limite_pago IS NULL OR CURDATE() <= pe2.fecha_limite_pago) AS pago_a_tiempo,
           d.nombre AS director, ${sqlEstadoPago} AS estado_pago
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    JOIN modalidades m ON m.id = p.modalidad_id
    JOIN niveles n ON n.id = p.nivel_id
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN periodos pe2 ON pe2.id = p.periodo_id
    LEFT JOIN usuarios d ON d.id = p.director_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${idEstudiante}" />
</sql:query>
<c:set var="tieneProyecto" value="${consulta.rowCount > 0}" />

<c:if test="${tieneProyecto}">
    <c:set var="p" value="${consulta.rows[0]}" />
    <sql:query var="integrantes">
        SELECT u.nombre, u.correo FROM proyecto_estudiantes pe JOIN usuarios u ON u.id = pe.estudiante_id
        WHERE pe.proyecto_id = ? AND pe.vigente = 1 ORDER BY u.nombre
        <sql:param value="${p.id}" />
    </sql:query>
    <%-- Recibos, del más reciente al más antiguo, con la revisión del comité si la tienen --%>
    <sql:query var="recibos">
        SELECT e.id, e.nombre_archivo, e.subido_en, r.decision, r.observacion
        FROM entregas e
        LEFT JOIN revisiones r ON r.entrega_id = e.id AND r.rol = 'Comité' AND r.estado = 'Enviada'
        WHERE e.proyecto_id = ? AND e.tipo = 'Recibo de pago' ORDER BY e.id DESC
        <sql:param value="${p.id}" />
    </sql:query>
    <%-- RF32: en los planes nuevos el pago lo cubre la matrícula del Seminario de Grado,
         salvo en la modalidad Seminario (estado-pago.jspf). --%>
    <c:set var="pagoCubierto" value="${p.estado_pago == 'No aplica'}" />
    <c:set var="pagoListo" value="${pagoCubierto or p.estado_pago == 'Aprobado'}" />
    <c:set var="faseActual" value="${p.fase}" />
</c:if>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <h1>Mi proyecto</h1>
    <p>Avance de tu trabajo de grado por fases.</p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<c:choose>
    <c:when test="${not tieneProyecto}">
        <div class="app-tarjeta">
            <p class="app-vacio mt-0">Todavía no tienes un proyecto. Se crea cuando tomas una idea aprobada del <a href="${ctx}/ideas/banco.jsp">banco de ideas</a>.</p>
        </div>
    </c:when>
    <c:otherwise>
        <%@ include file="/WEB-INF/jspf/fases-proyecto.jspf" %>

        <c:if test="${p.fase == 1}">
            <div class="app-tarjeta mb-4">
                <h2 class="app-tarjeta-titulo">Para pasar a la fase 2</h2>
                <ul class="app-lista">
                    <li>
                        <span><span class="app-lista-dato">El comité aprueba tu pago</span>
                            <span class="app-lista-nota">${pagoCubierto ? 'Lo cubre tu matrícula.' : (p.estado_pago == 'Por revisar' ? 'Tu recibo está en revisión.' : (p.estado_pago == 'Devuelto' ? 'El comité devolvió tu recibo: revisa la observación y súbelo otra vez.' : 'Sube tu recibo de pago.'))}</span></span>
                        <span class="app-requisito ${pagoListo ? 'cumple' : ''}">${pagoListo ? 'Listo' : 'Pendiente'}</span>
                    </li>
                    <li>
                        <span><span class="app-lista-dato">El comité te asigna un director</span></span>
                        <span class="app-requisito ${empty p.director ? '' : 'cumple'}">${empty p.director ? 'Pendiente' : 'Listo'}</span>
                    </li>
                </ul>
            </div>
        </c:if>

        <div class="row g-4">
            <div class="col-lg-6">
                <div class="app-tarjeta h-100">
                    <h2 class="app-tarjeta-titulo"><c:out value="${p.titulo}" /></h2>
                    <c:if test="${not empty p.descripcion}"><p class="text-secondary"><c:out value="${p.descripcion}" /></p></c:if>
                    <dl class="app-datos">
                        <dt>Código</dt><dd><c:out value="${empty p.codigo ? 'Sin asignar' : p.codigo}" /></dd>
                        <dt>Modalidad</dt><dd><c:out value="${p.modalidad}" /></dd>
                        <dt>Nivel</dt><dd><c:out value="${p.nivel}" /></dd>
                        <dt>Periodo</dt><dd><c:out value="${empty p.periodo ? 'Sin periodo' : p.periodo}" /></dd>
                        <dt>Estado</dt><dd><c:out value="${p.estado}" /></dd>
                        <dt>Director</dt><dd><c:out value="${empty p.director ? 'Por asignar' : p.director}" /></dd>
                        <dt>Integrantes</dt>
                        <dd><c:forEach var="i" items="${integrantes.rows}" varStatus="s"><c:out value="${i.nombre}" />${s.last ? '' : ', '}</c:forEach></dd>
                    </dl>
                </div>
            </div>

            <div class="col-lg-6">
                <div class="app-tarjeta h-100 app-formulario">
                    <h2 class="app-tarjeta-titulo">Pago de la modalidad (fase 1)</h2>
                    <c:choose>
                        <c:when test="${pagoCubierto}">
                            <p>Tu plan de estudios es posterior al decreto 1330: el pago lo cubre la matrícula del Seminario de Grado. No necesitas subir un recibo.</p>
                        </c:when>
                        <c:otherwise>
                            <p class="text-secondary">
                                Sube el recibo de pago con la marca "pagado", en PDF y de hasta 15 MB. El pago solo vale para el periodo <c:out value="${p.periodo}" />.
                                <c:if test="${not empty p.fecha_limite_pago}">Límite: <fmt:formatDate value="${p.fecha_limite_pago}" pattern="dd/MM/yyyy" />.</c:if>
                            </p>
                            <c:forEach var="r" items="${recibos.rows}" varStatus="s">
                                <div class="app-archivo">
                                    <span>
                                        <span class="app-lista-dato"><c:out value="${r.nombre_archivo}" /></span>
                                        <span class="app-lista-nota">Subido el <fmt:formatDate value="${r.subido_en}" pattern="dd/MM/yyyy HH:mm" /></span>
                                    </span>
                                    <span class="app-acciones">
                                        <span class="app-estado ${r.decision == 'Aprobado' ? 'activo' : 'inactivo'}">${empty r.decision ? (s.first ? 'En revisión' : 'Reemplazado') : r.decision}</span>
                                        <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/archivos/ver.jsp?id=${r.id}" target="_blank" rel="noopener">Ver</a>
                                    </span>
                                </div>
                                <c:if test="${not empty r.decision}">
                                    <p class="app-observacion mb-3"><strong>Observación del comité:</strong> <c:out value="${r.observacion}" /></p>
                                </c:if>
                            </c:forEach>
                            <c:choose>
                                <c:when test="${p.estado_pago == 'Aprobado'}">
                                    <p class="app-total">El comité aprobó tu pago.</p>
                                </c:when>
                                <c:when test="${p.fase != 1}">
                                    <p class="app-total">El pago se sube en la fase 1.</p>
                                </c:when>
                                <c:when test="${p.pago_a_tiempo != 1}">
                                    <div class="alert alert-warning app-aviso mb-0" role="status">Ya pasó la fecha límite de pago de este periodo.</div>
                                </c:when>
                                <c:otherwise>
                                    <form method="post" action="${ctx}/estudiante/pago-guardar.jsp" enctype="multipart/form-data">
                                        <label class="form-label" for="recibo">${recibos.rowCount == 0 ? 'Recibo de pago (PDF) *' : 'Volver a subir el recibo (PDF)'}</label>
                                        <input class="form-control" type="file" id="recibo" name="recibo" accept="application/pdf,.pdf" required>
                                        <button type="submit" class="btn btn-primary rounded-pill app-boton mt-3">Subir recibo</button>
                                    </form>
                                </c:otherwise>
                            </c:choose>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>
    </c:otherwise>
</c:choose>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
