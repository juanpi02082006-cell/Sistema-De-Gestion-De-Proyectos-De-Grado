<%-- Mi proyecto (estudiante): los datos del proyecto vigente, su avance por fases
     (RF2, RF37), los integrantes (en las fases 1 y 2 se agregan o se quitan, RF36), el
     pago de la fase 1 (RF29, RF32; cada estudiante sube el suyo y el comité lo revisa) y
     la propuesta de la fase 2 (FDC-124 con sus versiones, RF26, RF30, RF43), que envía a
     su director. El estudiante no ve a su evaluador (RF27). --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<c:set var="titulo" value="Mi proyecto" />
<c:set var="seccion" value="proyecto" />
<c:set var="idEstudiante" value="${sessionScope.usuario.id}" />

<sql:query var="consulta">
    SELECT p.id, p.codigo, p.titulo, p.descripcion, p.estado, p.modalidad_id, f.orden AS fase,
           m.nombre AS modalidad, n.nombre AS nivel, pe2.nombre AS periodo, pe2.id AS periodo_id,
           pe2.fecha_limite_pago, (pe2.fecha_limite_pago IS NULL OR CURDATE() <= pe2.fecha_limite_pago) AS pago_a_tiempo,
           d.nombre AS director, ${sqlEstadoPago} AS estado_pago, ${sqlEstadoPagoEstudiante} AS mi_pago,
           pe2.fecha_limite_propuestas,
           CASE WHEN p.interdisciplinario = 1 THEN 4 ELSE m.max_integrantes END AS maximo,
           (SELECT COUNT(*) FROM proyecto_estudiantes x WHERE x.proyecto_id = p.id AND x.vigente = 1) AS integrantes,
           (SELECT MAX(e.version) FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124') AS version_propuesta,
           (SELECT COUNT(*) FROM entregas e JOIN revisiones r ON r.entrega_id = e.id
            WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124' AND r.estado = 'Enviada' AND r.decision = 'Devuelto'
              AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = 'FDC-124')) AS propuesta_devuelta
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    JOIN usuarios ue ON ue.id = pe.estudiante_id
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
    <%-- Mis recibos (cada estudiante sube el suyo), del más reciente al más antiguo, con
         la revisión del comité si la tienen --%>
    <sql:query var="recibos">
        SELECT e.id, e.nombre_archivo, e.subido_en, r.decision, r.observacion
        FROM entregas e
        LEFT JOIN revisiones r ON r.entrega_id = e.id AND r.rol = 'Comité' AND r.estado = 'Enviada'
        WHERE e.proyecto_id = ? AND e.tipo = 'Recibo de pago' AND e.subido_por = ? ORDER BY e.id DESC
        <sql:param value="${p.id}" />
        <sql:param value="${idEstudiante}" />
    </sql:query>
    <%-- RF32: en los planes nuevos el pago lo cubre la matrícula del Seminario de Grado,
         salvo en la modalidad Seminario (estado-pago.jspf). mi_pago es el del estudiante;
         estado_pago, el de todo el grupo. --%>
    <c:set var="pagoCubierto" value="${p.mi_pago == 'No aplica'}" />
    <c:set var="miPagoListo" value="${pagoCubierto or p.mi_pago == 'Aprobado'}" />
    <c:set var="pagoListo" value="${p.estado_pago == 'No aplica' or p.estado_pago == 'Aprobado'}" />
    <c:set var="integrantesAbiertos" value="${p.fase == 1 or p.fase == 2}" />
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
                        <span><span class="app-lista-dato">${p.integrantes > 1 ? 'El comité aprueba el pago de todos los integrantes' : 'El comité aprueba tu pago'}</span>
                            <span class="app-lista-nota">${pagoCubierto ? 'El tuyo lo cubre tu matrícula.' : (p.mi_pago == 'Aprobado' ? 'El tuyo ya está aprobado.' : (p.mi_pago == 'Por revisar' ? 'Tu recibo está en revisión.' : (p.mi_pago == 'Devuelto' ? 'El comité devolvió tu recibo: revisa la observación y súbelo otra vez.' : 'Sube tu recibo de pago.')))}${p.integrantes > 1 and miPagoListo and not pagoListo ? ' Falta el de algún compañero.' : ''}</span></span>
                        <span class="app-requisito ${pagoListo ? 'cumple' : ''}">${pagoListo ? 'Listo' : 'Pendiente'}</span>
                    </li>
                    <li>
                        <span><span class="app-lista-dato">El comité te asigna un director</span></span>
                        <span class="app-requisito ${empty p.director ? '' : 'cumple'}">${empty p.director ? 'Pendiente' : 'Listo'}</span>
                    </li>
                </ul>
            </div>
        </c:if>

        <%-- Propuesta (FDC-124): desde la fase 2. Seminario no usa el F-DC-124 (RF17). --%>
        <c:if test="${p.fase >= 2}">
            <div class="app-tarjeta mb-4 app-formulario">
                <h2 class="app-tarjeta-titulo">Propuesta (FDC-124)</h2>
                <c:choose>
                    <c:when test="${p.modalidad_id == 5}">
                        <p class="mb-0">La modalidad Seminario no usa el F-DC-124.</p>
                    </c:when>
                    <c:otherwise>
                        <c:choose>
                            <c:when test="${p.fase == 2}">
                                <p class="text-secondary">
                                    Diligencia el FDC-124 en Word (.doc o .docx, hasta 15 MB) y súbelo. Cada vez que lo subes queda una versión nueva;
                                    cuando esté lista, envíasela a tu director: él la revisa en la fase 3.
                                    <c:if test="${not empty p.fecha_limite_propuestas}">La propuesta debe quedar aprobada a más tardar el <fmt:formatDate value="${p.fecha_limite_propuestas}" pattern="dd/MM/yyyy" />.</c:if>
                                </p>
                                <c:if test="${p.propuesta_devuelta > 0}">
                                    <div class="alert alert-warning app-aviso" role="status">Tu director devolvió la última versión. Revisa sus observaciones y sube una versión corregida antes de enviarla otra vez.</div>
                                </c:if>
                                <c:if test="${not pagoListo}">
                                    <div class="alert alert-warning app-aviso" role="status">Antes de enviarla, todos los integrantes deben tener el pago aprobado por el comité. Revisa el pago de cada uno en "Integrantes".</div>
                                </c:if>
                            </c:when>
                            <c:when test="${p.fase == 3}">
                                <p class="text-secondary">Enviaste la versión <c:out value="${p.version_propuesta}" /> a tu director. Está en revisión.</p>
                            </c:when>
                            <c:when test="${p.fase == 4}">
                                <p class="text-secondary">Tu director aprobó la versión <c:out value="${p.version_propuesta}" />, la pasó por Turnitin y la envió al evaluador y al comité.</p>
                            </c:when>
                        </c:choose>

                        <c:set var="idProyectoPropuesta" value="${p.id}" />
                        <%@ include file="/WEB-INF/jspf/propuesta-versiones.jspf" %>

                        <c:if test="${p.fase == 2}">
                            <div class="row g-3 align-items-end mt-1">
                                <form class="col-lg-8" method="post" action="${ctx}/estudiante/propuesta-guardar.jsp" enctype="multipart/form-data">
                                    <label class="form-label" for="propuesta">${empty p.version_propuesta ? 'FDC-124 (Word) *' : 'Subir una versión nueva (Word)'}</label>
                                    <input class="form-control" type="file" id="propuesta" name="propuesta" required
                                           accept=".doc,.docx,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document">
                                    <button type="submit" class="btn btn-outline-dark rounded-pill mt-3">Subir versión</button>
                                </form>
                                <c:if test="${not empty p.version_propuesta and p.propuesta_devuelta == 0}">
                                    <form class="col-lg-4 text-lg-end" method="post" action="${ctx}/estudiante/propuesta-enviar.jsp"
                                          onsubmit="return confirm('¿Enviar la versión ${p.version_propuesta} a tu director? Mientras la revisa no podrás subir otra.');">
                                        <button type="submit" class="btn btn-primary rounded-pill app-boton">Enviar versión <c:out value="${p.version_propuesta}" /> al director</button>
                                    </form>
                                </c:if>
                            </div>
                        </c:if>
                    </c:otherwise>
                </c:choose>
            </div>
        </c:if>

        <div class="row g-4">
            <div class="col-lg-6">
                <div class="app-tarjeta h-100">
                    <c:set var="datosTitulo" value="${p.titulo}" />
                    <c:set var="datosConDirector" value="true" />
                    <%@ include file="/WEB-INF/jspf/datos-proyecto.jspf" %>
                    <h3 class="h6 fw-bold mt-4 mb-3">Integrantes <span class="text-secondary fw-normal">· <c:out value="${p.integrantes}" /> de <c:out value="${p.maximo}" /></span></h3>
                    <c:set var="idProyectoIntegrantes" value="${p.id}" />
                    <c:set var="integrantesDetalle" value="false" />
                    <c:set var="integrantesQuitar" value="${integrantesAbiertos}" />
                    <%@ include file="/WEB-INF/jspf/integrantes.jspf" %>
                    <c:choose>
                        <c:when test="${integrantesAbiertos and p.integrantes < p.maximo}">
                            <form class="mt-4" method="post" action="${ctx}/estudiante/integrante-agregar.jsp">
                                <label class="form-label" for="correoCompanero">Agregar un compañero</label>
                                <div class="d-flex flex-wrap gap-2">
                                    <input class="form-control flex-grow-1 w-auto" type="email" id="correoCompanero" name="correo" required
                                           placeholder="correo@correo.uts.edu.co" pattern=".+@(uts\.edu\.co|correo\.uts\.edu\.co)">
                                    <button type="submit" class="btn btn-outline-dark rounded-pill">Agregar</button>
                                </div>
                                <div class="form-text">Debe tener cuenta, estar habilitado, ser de tu mismo nivel y no tener otro proyecto. Después sube su propio recibo de pago.</div>
                            </form>
                        </c:when>
                        <c:when test="${integrantesAbiertos}">
                            <p class="app-total mt-3">El proyecto ya tiene el máximo de integrantes de su modalidad.</p>
                        </c:when>
                    </c:choose>
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
                                <c:when test="${p.mi_pago == 'Aprobado'}">
                                    <p class="app-total">El comité aprobó tu pago.</p>
                                </c:when>
                                <c:when test="${not integrantesAbiertos}">
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
