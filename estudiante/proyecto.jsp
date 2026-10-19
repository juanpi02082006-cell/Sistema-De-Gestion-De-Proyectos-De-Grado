<%-- Mi proyecto (estudiante): los datos del proyecto vigente, su avance por fases
     (RF2, RF37), los integrantes (en las fases 1 y 2 se agregan o se quitan, RF36), el
     pago de la fase 1 (RF29, RF32; cada estudiante sube el suyo y el comité lo revisa) y
     la propuesta de la fase 2 (FDC-124 con sus versiones, RF26, RF30, RF43), que envía a
     su director, con sus anexos en PDF. También: el código del proyecto (RF40), el
     plazo de la semana 12 (RF30) y el del director (RF21), el cambio de modalidad
     (RF12), la exoneración por Saber TyT (RNF14) y el historial (RNF12). El estudiante
     no ve a su evaluador (RF27), pero sí su concepto y sus observaciones (RF23). En la
     fase 4, con el FDC-124 aprobado por el comité, sube el informe final (FDC-125) por
     versiones y lo envía a su director desde el día 90 hasta el 180 (RF31), con al
     menos 2 seguimientos del director (RF20), y sube los entregables de su modalidad
     (manual, código fuente y evidencias, RF26). En la fase final ve la sustentación que
     programa el comité (sustentacion.jspf) y la presenta; después, el comité registra la
     aprobación final y el proyecto queda "Finalizado" (RF39). --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
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
            WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124' AND r.estado = 'Enviada' AND r.rol <> 'Codirector'
              AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = 'FDC-124')) AS propuesta_devuelta,
           ${sqlUltimaRevision} AS ultima, p.fecha_aprobacion_124, p.fecha_limite,
           p.fecha_aprobacion_124 + INTERVAL 90 DAY AS informe_desde,
           (CURDATE() >= p.fecha_aprobacion_124 + INTERVAL 90 DAY) AS informe_abierto,
           (CURDATE() > p.fecha_limite) AS informe_vencido,
           (SELECT COUNT(*) FROM seguimientos s WHERE s.proyecto_id = p.id) AS seguimientos,
           (SELECT MAX(e.version) FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125') AS version_informe,
           ${sqlUltimaRevisionInforme} AS ultima_informe,
           (SELECT COUNT(*) FROM prorrogas x WHERE x.proyecto_id = p.id AND x.estado = 'Aprobada') AS prorrogas_aprobadas,
           (SELECT COUNT(*) FROM prorrogas x WHERE x.proyecto_id = p.id AND x.estado = 'Pendiente') AS prorrogas_pendientes,
           EXISTS (SELECT 1 FROM proyecto_estudiantes y JOIN usuarios uy ON uy.id = y.estudiante_id
                   WHERE y.proyecto_id = p.id AND y.vigente = 1 AND (uy.plan_estudios IS NULL OR uy.plan_estudios <> 'Nuevo')) AS plan_anterior,
           (SELECT r.plazo_correccion FROM entregas e JOIN revisiones r ON r.entrega_id = e.id
            WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125' AND r.rol = 'Evaluador' AND r.estado = 'Enviada'
            ORDER BY r.id DESC LIMIT 1) AS plazo_correccion,
           (SELECT r.decision FROM entregas e JOIN revisiones r ON r.entrega_id = e.id
            WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125' AND r.rol = 'Comité' AND r.estado = 'Enviada'
            ORDER BY r.id DESC LIMIT 1) AS decision_comite_informe,
           DATEDIFF(pe2.fecha_limite_propuestas, CURDATE()) AS dias_semana12,
           (SELECT e.fecha_limite_revision FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124'
            ORDER BY e.version DESC LIMIT 1) AS limite_director,
           ue.nivel_id AS mi_nivel, pe.exonerado, pe.renuncia_exoneracion, p.nota_final,
           ${sqlDocumentosFaltantes} AS documentos_faltantes
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
    <c:set var="terminado" value="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}" />
    <c:set var="esSeminario" value="${p.modalidad_id == 5}" />
    <c:set var="estadoProyecto" value="${p.estado}" />
    <%-- En Seminario los integrantes se cierran cuando el comité valida la inscripción --%>
    <c:set var="integrantesAbiertos" value="${(p.fase == 1 or p.fase == 2) and not terminado and not (esSeminario and p.estado != 'Pendiente')}" />
    <%-- Solo se muestran las tarjetas que le sirven al estudiante en su fase: el pago, mientras
         tenga que subirlo, corregirlo o esperar la revisión (aprobado, su estado queda en
         "Integrantes"); el cambio de modalidad, en las fases 1 a 3 --%>
    <c:set var="mostrarPago" value="${integrantesAbiertos and not pagoCubierto and p.mi_pago != 'Aprobado'}" />
    <c:set var="mostrarModalidad" value="${not terminado and p.fase >= 1 and p.fase <= 3 and not (esSeminario and p.estado != 'Pendiente')}" />
    <c:if test="${esSeminario}">
        <%-- Mis documentos de inscripción al seminario (el último de cada tipo) --%>
        <sql:query var="misDocumentos">
            SELECT e.id, e.tipo, e.nombre_archivo, e.subido_en FROM entregas e
            WHERE e.proyecto_id = ? AND e.subido_por = ? AND e.tipo IN ('Formato F-AM-04', 'Documento de identidad')
              AND e.id = (SELECT MAX(e2.id) FROM entregas e2 WHERE e2.proyecto_id = e.proyecto_id AND e2.subido_por = e.subido_por AND e2.tipo = e.tipo)
            ORDER BY e.tipo DESC
            <sql:param value="${p.id}" />
            <sql:param value="${idEstudiante}" />
        </sql:query>
        <c:set var="tengoFormato" value="false" /><c:set var="tengoCedula" value="false" />
        <c:forEach var="dc" items="${misDocumentos.rows}">
            <c:if test="${dc.tipo == 'Formato F-AM-04'}"><c:set var="tengoFormato" value="true" /></c:if>
            <c:if test="${dc.tipo == 'Documento de identidad'}"><c:set var="tengoCedula" value="true" /></c:if>
        </c:forEach>
    </c:if>
    <%-- Cambio de modalidad (RF12): la última solicitud del proyecto y las modalidades --%>
    <sql:query var="ultimoCambio">
        SELECT c.estado, c.motivo, c.observacion, c.solicitado_en, m.nombre AS nueva
        FROM cambios_modalidad c JOIN modalidades m ON m.id = c.modalidad_nueva_id
        WHERE c.proyecto_id = ? ORDER BY c.id DESC LIMIT 1
        <sql:param value="${p.id}" />
    </sql:query>
    <sql:query var="otrasModalidades">
        SELECT id, nombre, max_integrantes FROM modalidades WHERE id <> ? ORDER BY id
        <sql:param value="${p.modalidad_id}" />
    </sql:query>
    <%-- Exoneración por Saber TyT (RNF14): mi última solicitud, con el estímulo --%>
    <sql:query var="miExoneracion">
        SELECT x.estado, x.puntaje, x.observacion,
               CASE WHEN x.puntaje >= 171 THEN '5.0 y 100 % de beca en los derechos de grado'
                    WHEN x.puntaje >= 151 THEN '4.7 y 50 % de beca en los derechos de grado'
                    ELSE '4.5' END AS estimulo
        FROM exoneraciones x WHERE x.proyecto_id = ? AND x.estudiante_id = ? ORDER BY x.id DESC LIMIT 1
        <sql:param value="${p.id}" />
        <sql:param value="${idEstudiante}" />
    </sql:query>
    <%-- La exoneración se muestra cuando se puede pedir (fase 4 con la propuesta aprobada) o
         cuando ya hay algo que contar (pendiente, exonerado o renuncia); si el proyecto
         terminó, el resultado ya sale arriba --%>
    <c:set var="ex" value="${miExoneracion.rowCount > 0 ? miExoneracion.rows[0] : null}" />
    <c:set var="mostrarExoneracion" value="${p.mi_nivel == 1 and not terminado and (p.exonerado == true or p.renuncia_exoneracion == true
                                            or (not empty ex and ex.estado == 'Pendiente') or (p.fase == 4 and not empty p.fecha_aprobacion_124))}" />
    <%-- En un proyecto terminado o con la propuesta aprobada, el límite de la propuesta ya no importa --%>
    <c:set var="datosOcultarLimite" value="${terminado or not empty p.fecha_aprobacion_124}" />
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
        <c:set var="idProyectoFases" value="${p.id}" />
        <%@ include file="/WEB-INF/jspf/fases-proyecto.jspf" %>

        <c:if test="${esSeminario and p.estado == 'Finalizado'}">
            <div class="app-resultado cumple">
                <h2>Aprobaste el seminario con nota <fmt:formatNumber value="${p.nota_final}" minFractionDigits="1" maxFractionDigits="1" /></h2>
                <p>El requisito de trabajo de grado quedó cumplido.</p>
            </div>
        </c:if>
        <c:if test="${not esSeminario and p.estado == 'Finalizado'}">
            <div class="app-resultado cumple">
                <c:choose>
                    <%-- Fase final: el comité registró la aprobación final después de la sustentación (RF39) --%>
                    <c:when test="${p.fase == 6}">
                        <h2>Tu trabajo de grado quedó finalizado</h2>
                        <p>El comité registró la aprobación final después de la sustentación: ya puedes radicar los papeles de grado.</p>
                    </c:when>
                    <c:otherwise>
                        <h2>Tu proyecto terminó con concepto Aprobado</h2>
                        <p>Todos los integrantes quedaron exonerados por Saber TyT: se exime el informe final.<c:if test="${miExoneracion.rowCount > 0 and miExoneracion.rows[0].estado == 'Aprobada'}"> Tu estímulo: <c:out value="${miExoneracion.rows[0].estimulo}" />.</c:if></p>
                    </c:otherwise>
                </c:choose>
            </div>
        </c:if>

        <%-- Fase final (RF39): la sustentación, que programa el comité --%>
        <c:if test="${p.fase == 6 and not esSeminario}">
            <c:set var="idProyectoSustentacion" value="${p.id}" />
            <c:set var="sustentacionProgramar" value="false" />
            <%@ include file="/WEB-INF/jspf/sustentacion.jspf" %>
        </c:if>

        <%-- Seminario (RF17): inscripción y seminario en curso --%>
        <c:if test="${esSeminario and p.estado == 'Pendiente'}">
            <div class="app-tarjeta mb-4 app-formulario">
                <h2 class="app-tarjeta-titulo">Inscripción al seminario</h2>
                <p class="text-secondary">El pago por sí solo no te inscribe: sube también el formato F-AM-04 (solicitud de trabajo de grado, con la opción Seminario) y tu cédula ampliada al 150 %, en PDF escaneado. El comité revisa los soportes y valida tu inscripción.</p>
                <ul class="app-lista mb-3">
                    <li><span class="app-lista-dato">${p.integrantes > 1 ? 'Pago de todos aprobado' : 'Tu pago aprobado'}</span><span class="app-requisito ${pagoListo ? 'cumple' : ''}">${pagoListo ? 'Listo' : 'Pendiente'}</span></li>
                    <li><span class="app-lista-dato">Formato F-AM-04</span><span class="app-requisito ${tengoFormato ? 'cumple' : ''}">${tengoFormato ? 'Subido' : 'Pendiente'}</span></li>
                    <li><span class="app-lista-dato">Cédula ampliada al 150 %</span><span class="app-requisito ${tengoCedula ? 'cumple' : ''}">${tengoCedula ? 'Subida' : 'Pendiente'}</span></li>
                    <li><span class="app-lista-dato">Docente del seminario asignado</span><span class="app-requisito ${empty p.director ? '' : 'cumple'}">${empty p.director ? 'Pendiente' : 'Listo'}</span></li>
                    <li><span class="app-lista-dato">Validación del comité</span><span class="app-requisito">Pendiente</span></li>
                </ul>
                <c:forEach var="dc" items="${misDocumentos.rows}">
                    <div class="app-archivo">
                        <span><span class="app-lista-dato"><c:out value="${dc.tipo == 'Formato F-AM-04' ? 'Formato F-AM-04' : 'Cédula'}" /> · <c:out value="${dc.nombre_archivo}" /></span>
                            <span class="app-lista-nota">Subido el <fmt:formatDate value="${dc.subido_en}" pattern="dd/MM/yyyy HH:mm" /></span></span>
                        <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/archivos/ver.jsp?id=${dc.id}" target="_blank" rel="noopener">Ver</a>
                    </div>
                </c:forEach>
                <form class="mt-2" method="post" action="${ctx}/estudiante/inscripcion-guardar.jsp" enctype="multipart/form-data">
                    <div class="row g-3 align-items-end">
                        <div class="col-sm-5">
                            <label class="form-label" for="documentoInscripcion">Documento *</label>
                            <select class="form-select" id="documentoInscripcion" name="documento" required>
                                <option value="f-am-04">Formato F-AM-04</option>
                                <option value="cedula">Cédula ampliada al 150 %</option>
                            </select>
                        </div>
                        <div class="col-sm-7">
                            <label class="form-label" for="archivoInscripcion">Archivo (PDF) *</label>
                            <input class="form-control" type="file" id="archivoInscripcion" name="archivo" accept="application/pdf,.pdf" required>
                        </div>
                    </div>
                    <button type="submit" class="btn btn-outline-dark rounded-pill mt-3">Subir documento</button>
                </form>
            </div>
        </c:if>
        <c:if test="${esSeminario and p.estado == 'En curso'}">
            <div class="app-resultado">
                <h2>Seminario en curso</h2>
                <p>El comité validó tu inscripción. Las clases y el entregable van con tu docente${empty p.director ? '' : ' ('}<c:out value="${p.director}" />${empty p.director ? '' : ')'} en Atena; al terminar, el docente registra aquí tu nota final.</p>
            </div>
        </c:if>

        <c:set var="mostrarRequisitosFase2" value="${p.fase == 1 and not terminado and not esSeminario}" />
        <c:if test="${mostrarRequisitosFase2 or mostrarPago}">
        <div class="row g-4 mb-4">
        <c:if test="${mostrarRequisitosFase2}">
            <div class="col-lg">
            <div class="app-tarjeta h-100">
                <h2 class="app-tarjeta-titulo">Para pasar a la fase 2</h2>
                <ul class="app-lista">
                    <li>
                        <span><span class="app-lista-dato">${p.integrantes > 1 ? 'El comité aprueba el pago de todos los integrantes' : 'El comité aprueba tu pago'}</span>
                            <span class="app-lista-nota">${pagoCubierto ? 'El tuyo lo cubre la matrícula del Seminario de Grado.' : (p.mi_pago == 'Aprobado' ? 'El comité aprobó tu pago.' : (p.mi_pago == 'Por revisar' ? 'Tu recibo está en revisión.' : (p.mi_pago == 'Devuelto' ? 'El comité devolvió tu recibo: revisa la observación y súbelo otra vez.' : 'Sube tu recibo de pago.')))}${p.integrantes > 1 and miPagoListo and not pagoListo ? ' Falta el de algún compañero.' : ''}</span></span>
                        <span class="app-requisito ${pagoListo ? 'cumple' : ''}">${pagoListo ? 'Listo' : 'Pendiente'}</span>
                    </li>
                    <li>
                        <span><span class="app-lista-dato">El comité te asigna un director</span></span>
                        <span class="app-requisito ${empty p.director ? '' : 'cumple'}">${empty p.director ? 'Pendiente' : 'Listo'}</span>
                    </li>
                </ul>
            </div>
            </div>
        </c:if>
        <c:if test="${mostrarPago}">
            <div class="col-lg">
                <div class="app-tarjeta h-100 app-formulario">
                    <h2 class="app-tarjeta-titulo">Pago de la modalidad</h2>
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

        </c:if>
        </div>
        </c:if>

        <%-- Propuesta (FDC-124): desde la fase 2. Seminario no usa el F-DC-124 (RF17). --%>
        <c:if test="${p.fase >= 2}">
            <%-- Mientras se trabaja va abierta; aprobada por el comité, queda plegada para consultar --%>
            <details class="app-tarjeta app-historial mb-4 app-formulario" ${empty p.fecha_aprobacion_124 ? 'open' : ''}>
                <summary>Propuesta (FDC-124)<c:if test="${not empty p.fecha_aprobacion_124}"><span class="text-secondary fw-normal"> · aprobada el <fmt:formatDate value="${p.fecha_aprobacion_124}" pattern="dd/MM/yyyy" /></span></c:if></summary>
                <div class="mt-3"></div>
                <c:choose>
                    <c:when test="${p.modalidad_id == 5}">
                        <p class="mb-0">La modalidad Seminario no usa el F-DC-124. El siguiente paso de tu seminario lo define el comité.</p>
                    </c:when>
                    <c:otherwise>
                        <c:choose>
                            <c:when test="${p.fase == 2}">
                                <p class="text-secondary">
                                    Diligencia el FDC-124 en Word (.doc o .docx, hasta 15 MB) y súbelo. Cada vez que lo subes queda una versión nueva;
                                    cuando esté lista, envíasela a tu director: él la revisa en la fase 3.
                                    <c:if test="${not empty p.fecha_limite_propuestas}">La propuesta debe quedar aprobada a más tardar el <fmt:formatDate value="${p.fecha_limite_propuestas}" pattern="dd/MM/yyyy" /> (semana 12)${p.dias_semana12 >= 0 ? ': faltan ' : ''}${p.dias_semana12 >= 0 ? p.dias_semana12 : ''}${p.dias_semana12 >= 0 ? ' días' : ''}.</c:if>
                                </p>
                                <c:if test="${p.propuesta_devuelta > 0}">
                                    <div class="alert alert-warning app-aviso" role="status">${p.ultima == 'Comité:Aplazado' ? 'El comité aplazó' : 'Tu director devolvió'} la última versión. Revisa las observaciones y sube una versión corregida antes de enviarla otra vez.</div>
                                </c:if>
                                <c:if test="${not pagoListo}">
                                    <div class="alert alert-warning app-aviso" role="status">Antes de enviarla, todos los integrantes deben tener el pago aprobado por el comité. Revisa el pago de cada uno en "Integrantes".</div>
                                </c:if>
                            </c:when>
                            <c:when test="${p.fase == 3}">
                                <p class="text-secondary">Enviaste la versión <c:out value="${p.version_propuesta}" /> a tu director. Está en revisión<c:if test="${not empty p.limite_director}">: tiene hasta el <fmt:formatDate value="${p.limite_director}" pattern="dd/MM/yyyy" /> para revisarla</c:if>.</p>
                            </c:when>
                            <c:when test="${not empty p.fecha_aprobacion_124}">
                                <p class="text-secondary">El comité aprobó tu propuesta<c:if test="${not empty p.version_propuesta}">: la versión oficial es la <c:out value="${p.version_propuesta}" /></c:if>.</p>
                            </c:when>
                            <c:when test="${p.fase == 4 and p.ultima == 'Director:Aprobado'}">
                                <p class="text-secondary">Tu director aprobó la versión <c:out value="${p.version_propuesta}" />, la pasó por Turnitin y la envió al evaluador y al comité. El evaluador la está evaluando.</p>
                            </c:when>
                            <c:when test="${p.fase == 4}">
                                <p class="text-secondary">El evaluador ya dio su concepto. Falta la decisión final del comité.</p>
                            </c:when>
                        </c:choose>

                        <c:set var="idProyectoPropuesta" value="${p.id}" />
                        <c:set var="anexosQuitar" value="${p.fase == 2 and not terminado}" />
                        <%@ include file="/WEB-INF/jspf/propuesta-versiones.jspf" %>
                        <c:set var="idProyectoEvaluacion" value="${p.id}" />
                        <c:set var="evaluacionConEvaluador" value="false" />
                        <c:set var="evaluacionInforme" value="false" />
                        <%@ include file="/WEB-INF/jspf/evaluacion-propuesta.jspf" %>

                        <c:if test="${p.fase == 2 and not terminado}">
                            <form class="mt-3" method="post" action="${ctx}/estudiante/anexo-guardar.jsp" enctype="multipart/form-data">
                                <label class="form-label" for="anexo">Agregar un anexo (PDF, opcional)</label>
                                <div class="d-flex flex-wrap gap-2">
                                    <input class="form-control campo-en-linea" type="file" id="anexo" name="anexo" accept="application/pdf,.pdf" required>
                                    <button type="submit" class="btn btn-outline-dark rounded-pill">Subir anexo</button>
                                </div>
                            </form>
                        </c:if>

                        <c:if test="${p.fase == 2 and not terminado}">
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
            </details>
        </c:if>

        <%-- Informe final (FDC-125): desde que el comité aprueba el FDC-124 (RF20, RF31) --%>
        <%-- Si el proyecto terminó sin informe (todos exonerados), la tarjeta no aplica --%>
        <c:if test="${not empty p.fecha_aprobacion_124 and not esSeminario and not (terminado and empty p.version_informe)}">
            <div class="app-tarjeta mb-4 app-formulario">
                <h2 class="app-tarjeta-titulo">Informe final (FDC-125)</h2>
                <dl class="app-pares">
                    <div><dt>Propuesta aprobada</dt><dd><fmt:formatDate value="${p.fecha_aprobacion_124}" pattern="dd/MM/yyyy" /></dd></div>
                    <div><dt>Se entrega desde</dt><dd><fmt:formatDate value="${p.informe_desde}" pattern="dd/MM/yyyy" /></dd></div>
                    <div><dt>Fecha límite</dt><dd><fmt:formatDate value="${p.fecha_limite}" pattern="dd/MM/yyyy" /></dd></div>
                </dl>
                <%-- La última versión ya se revisó y volvió (devuelta, aplazada o no aprobada): hay que subir otra --%>
                <c:set var="informeEnCorreccion" value="${p.fase == 4 and not empty p.ultima_informe}" />
                <c:choose>
                    <c:when test="${p.fase == 4 and not terminado}">
                        <c:if test="${informeEnCorreccion}">
                            <div class="alert alert-warning app-aviso mt-3" role="status">
                                ${p.ultima_informe == 'Director:Devuelto' ? 'Tu director devolvió' : (p.ultima_informe == 'Comité:Aplazado' ? 'El comité aplazó' : 'El comité no aprobó')} la versión <c:out value="${p.version_informe}" /> del informe final.
                                Revisa las observaciones y sube una versión corregida<c:if test="${p.ultima_informe == 'Comité:Aplazado' and not empty p.plazo_correccion}"> a más tardar el <fmt:formatDate value="${p.plazo_correccion}" pattern="dd/MM/yyyy" /></c:if><c:if test="${p.ultima_informe != 'Comité:Aplazado'}"> antes del <fmt:formatDate value="${p.fecha_limite}" pattern="dd/MM/yyyy" /></c:if>.
                            </div>
                        </c:if>
                        <p class="text-secondary mt-3">
                            Desarrolla tu trabajo con tu director y diligencia el FDC-125 en Word (.doc o .docx, hasta 15 MB); cada archivo que subes queda como una versión nueva.
                            Lo envías a tu director desde el día 90 y hasta el día 180 después de la aprobación de la propuesta.
                        </p>
                        <ul class="app-lista mb-3">
                            <li><span class="app-lista-dato">Pasaron 90 días desde la aprobación</span><span class="app-requisito ${p.informe_abierto == 1 ? 'cumple' : ''}">${p.informe_abierto == 1 ? 'Listo' : 'Pendiente'}</span></li>
                            <li><span class="app-lista-dato">Tu director registró al menos 2 seguimientos</span><span class="app-requisito ${p.seguimientos >= 2 ? 'cumple' : ''}">${p.seguimientos >= 2 ? 'Listo' : 'Pendiente'}</span></li>
                            <li><span class="app-lista-dato">Subiste el FDC-125</span><span class="app-requisito ${empty p.version_informe ? '' : 'cumple'}">${empty p.version_informe ? 'Pendiente' : 'Listo'}</span></li>
                        </ul>
                        <c:if test="${p.informe_vencido == 1}">
                            <div class="alert alert-warning app-aviso" role="status">Se venció el plazo para entregar el informe final.${p.prorrogas_pendientes > 0 ? ' Tu solicitud de prórroga está esperando la decisión del comité.' : ''}</div>
                        </c:if>
                    </c:when>
                    <c:when test="${p.fase == 5 and p.ultima_informe == 'Director:Aprobado'}">
                        <p class="text-secondary mt-3">Tu director aprobó la versión <c:out value="${p.version_informe}" /> del informe final, la pasó por Turnitin y la envió al evaluador y al comité. El evaluador la está evaluando.</p>
                    </c:when>
                    <c:when test="${p.fase == 5 and fn:startsWith(p.ultima_informe, 'Evaluador:')}">
                        <p class="text-secondary mt-3">El evaluador ya dio su concepto sobre el informe final. Falta la decisión del comité.</p>
                    </c:when>
                    <c:when test="${p.fase == 5}">
                        <p class="text-secondary mt-3">Enviaste la versión <c:out value="${p.version_informe}" /> del informe final a tu director (fase 5, Informe II). Está en revisión.</p>
                    </c:when>
                    <c:when test="${p.fase == 6}">
                        <p class="text-secondary mt-3">El comité aprobó tu informe final<c:if test="${not empty p.version_informe}">: la versión oficial es la <c:out value="${p.version_informe}" /></c:if>.${terminado ? '' : ' La fecha de la sustentación la programa el comité: sale arriba.'}</p>
                    </c:when>
                </c:choose>
                <c:set var="informeOcultarVacios" value="${p.fase == 4 and not terminado}" />
                <c:set var="entregablesQuitar" value="${p.fase == 4 and not terminado}" />
                <c:set var="idProyectoInforme" value="${p.id}" />
                <%@ include file="/WEB-INF/jspf/informe-final.jspf" %>
                <c:set var="idProyectoEvaluacion" value="${p.id}" />
                <c:set var="evaluacionConEvaluador" value="false" />
                <c:set var="evaluacionInforme" value="true" />
                <%@ include file="/WEB-INF/jspf/evaluacion-propuesta.jspf" %>
                <c:if test="${p.fase == 4 and not terminado}">
                    <div class="row g-3 align-items-end mt-1">
                        <form class="col-lg-8" method="post" action="${ctx}/estudiante/informe-guardar.jsp" enctype="multipart/form-data">
                            <label class="form-label" for="informe">${empty p.version_informe ? 'FDC-125 (Word) *' : 'Subir una versión nueva (Word)'}</label>
                            <input class="form-control" type="file" id="informe" name="informe" required
                                   accept=".doc,.docx,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document">
                            <button type="submit" class="btn btn-outline-dark rounded-pill mt-3">Subir versión</button>
                        </form>
                        <c:if test="${not empty p.version_informe and not informeEnCorreccion and p.informe_abierto == 1 and p.seguimientos >= 2 and p.informe_vencido != 1}">
                            <form class="col-lg-4 text-lg-end" method="post" action="${ctx}/estudiante/informe-enviar.jsp"
                                  onsubmit="return confirm('¿Enviar la versión ${p.version_informe} del informe final a tu director?');">
                                <button type="submit" class="btn btn-primary rounded-pill app-boton">Enviar versión <c:out value="${p.version_informe}" /> al director</button>
                            </form>
                        </c:if>
                    </div>

                    <%-- Entregables de la modalidad (RF26): opcionales, van con el informe final --%>
                    <form class="mt-4" method="post" action="${ctx}/estudiante/entregable-guardar.jsp" enctype="multipart/form-data">
                        <h3 class="h6 fw-bold mb-2">Entregables de la modalidad</h3>
                        <p class="text-secondary">
                            Sube lo que pida tu modalidad: el manual de usuario (PDF o Word), el código fuente (ZIP, RAR o 7Z) y las evidencias del desarrollo
                            (PDF, imagen PNG o JPG, o ZIP), de hasta 15 MB cada uno. Van con el informe final a tu director y al evaluador.
                        </p>
                        <div class="row g-3 align-items-end">
                            <div class="col-sm-5">
                                <label class="form-label" for="tipoEntregable">Entregable *</label>
                                <select class="form-select" id="tipoEntregable" name="tipo" required>
                                    <option value="">Escoge el entregable</option>
                                    <option value="manual">Manual de usuario</option>
                                    <option value="codigo">Código fuente</option>
                                    <option value="evidencia">Evidencia del desarrollo</option>
                                </select>
                            </div>
                            <div class="col-sm-7">
                                <label class="form-label" for="entregable">Archivo *</label>
                                <input class="form-control" type="file" id="entregable" name="archivo" required
                                       accept=".pdf,.doc,.docx,.zip,.rar,.7z,.png,.jpg,.jpeg">
                            </div>
                        </div>
                        <button type="submit" class="btn btn-outline-dark rounded-pill mt-3">Subir entregable</button>
                    </form>
                </c:if>

                <%-- Prórrogas del plazo del informe final (RF38): solo planes anteriores --%>
                <sql:query var="misProrrogas">
                    SELECT x.numero, x.estado, x.fecha_solicitud, x.nueva_fecha_limite, x.motivo, x.observacion
                    FROM prorrogas x WHERE x.proyecto_id = ? ORDER BY x.id
                    <sql:param value="${p.id}" />
                </sql:query>
                <c:if test="${p.plan_anterior == 1 and (misProrrogas.rowCount > 0 or (p.fase == 4 and not terminado))}">
                    <c:if test="${misProrrogas.rowCount > 0}">
                        <h3 class="h6 fw-bold mt-4 mb-2">Prórrogas <span class="text-secondary fw-normal">· <c:out value="${p.prorrogas_aprobadas}" /> de 3</span></h3>
                        <ul class="app-lista">
                            <c:forEach var="pr" items="${misProrrogas.rows}">
                                <li>
                                    <span><span class="app-lista-dato">${pr.estado == 'Aprobada' ? 'Prórroga ' : 'Solicitud del '}<c:choose><c:when test="${pr.estado == 'Aprobada'}"><c:out value="${pr.numero}" /> · hasta el <fmt:formatDate value="${pr.nueva_fecha_limite}" pattern="dd/MM/yyyy" /></c:when><c:otherwise><fmt:formatDate value="${pr.fecha_solicitud}" pattern="dd/MM/yyyy" /></c:otherwise></c:choose></span>
                                        <span class="app-lista-nota">Motivo: <c:out value="${pr.motivo}" /><c:if test="${not empty pr.observacion}"> · Comité: <c:out value="${pr.observacion}" /></c:if></span></span>
                                    <span class="app-requisito ${pr.estado == 'Aprobada' ? 'cumple' : ''}"><c:out value="${pr.estado}" /></span>
                                </li>
                            </c:forEach>
                        </ul>
                    </c:if>
                    <c:if test="${p.fase == 4 and not terminado and p.informe_vencido != 1 and p.prorrogas_aprobadas < 3 and p.prorrogas_pendientes == 0}">
                        <%-- Plegado: solo lo abre quien lo necesita --%>
                        <details class="app-historial mt-4">
                        <summary>¿No alcanzas a entregar el informe? Pide una prórroga <span class="text-secondary fw-normal">· <c:out value="${p.prorrogas_aprobadas}" /> de 3 usadas</span></summary>
                        <p class="text-secondary mt-3">
                            Si no alcanzas a entregar el informe, pide una prórroga de 180 días antes del <fmt:formatDate value="${p.fecha_limite}" pattern="dd/MM/yyyy" /> (mejor unos 8 días antes).
                            Adjunta el recibo del nuevo pago del derecho pecuniario<c:if test="${p.modalidad_id == 1 or p.modalidad_id == 2}"> o el aval de la Dirección de Investigaciones y Extensión</c:if>. Si se vence el plazo sin prórroga, se cancela la modalidad.
                        </p>
                        <form method="post" action="${ctx}/estudiante/prorroga-solicitar.jsp" enctype="multipart/form-data">
                            <div class="row g-3">
                                <div class="col-lg-7">
                                    <label class="form-label" for="motivoProrroga">Motivo *</label>
                                    <textarea class="form-control" id="motivoProrroga" name="motivo" required></textarea>
                                </div>
                                <div class="col-lg-5">
                                    <label class="form-label" for="soporteProrroga">Soporte (PDF) *</label>
                                    <input class="form-control" type="file" id="soporteProrroga" name="soporte" accept="application/pdf,.pdf" required>
                                </div>
                            </div>
                            <button type="submit" class="btn btn-outline-dark rounded-pill mt-3">Pedir la prórroga</button>
                        </form>
                        </details>
                    </c:if>
                </c:if>
            </div>
        </c:if>

        <div class="row g-4">
            <div class="col-lg-6">
                <div class="app-tarjeta h-100">
                    <c:set var="datosTitulo" value="${p.titulo}" />
                    <c:set var="datosConDirector" value="true" />
                    <%@ include file="/WEB-INF/jspf/datos-proyecto.jspf" %>
                </div>
            </div>
            <div class="col-lg-6">
                <div class="app-tarjeta h-100">
                    <h2 class="app-tarjeta-titulo">Integrantes <span class="text-secondary fw-normal">· <c:out value="${p.integrantes}" /> (hasta <c:out value="${p.maximo}" /> en esta modalidad)</span></h2>
                    <c:set var="idProyectoIntegrantes" value="${p.id}" />
                    <c:set var="integrantesDetalle" value="false" />
                    <c:set var="integrantesSalir" value="${integrantesAbiertos}" />
                    <%@ include file="/WEB-INF/jspf/integrantes.jspf" %>
                    <c:choose>
                        <c:when test="${integrantesAbiertos and p.integrantes < p.maximo}">
                            <form class="mt-4" method="post" action="${ctx}/estudiante/integrante-agregar.jsp">
                                <label class="form-label" for="companero">Agregar un compañero</label>
                                <div class="d-flex flex-wrap gap-2">
                                    <input class="form-control campo-en-linea" type="text" id="companero" name="companero" required
                                           maxlength="120" autocomplete="off" placeholder="Correo institucional o número de documento">
                                    <button type="submit" class="btn btn-outline-dark rounded-pill">Agregar</button>
                                </div>
                                <div class="form-text">Escribe su correo institucional o su número de documento. Debe tener cuenta, estar habilitado, ser de tu mismo nivel y no tener otro proyecto. Después sube su propio recibo de pago.</div>
                            </form>
                        </c:when>
                        <c:when test="${integrantesAbiertos}">
                            <p class="app-total mt-3">El proyecto ya tiene el máximo de integrantes de su modalidad.</p>
                        </c:when>
                    </c:choose>
                </div>
            </div>
        </div>

        <%-- Trámites que no son del día a día: solo cuando se pueden usar --%>
        <c:if test="${mostrarModalidad or mostrarExoneracion}">
        <div class="row g-4 mt-0">


            <%-- Cambio de modalidad (RF12): antes de que se apruebe el FDC-124 --%>
            <%-- Es un trámite poco usado: va plegado y se abre solo si hay una solicitud pendiente --%>
            <c:if test="${mostrarModalidad}">
            <div class="col-lg">
                <c:set var="hayCambioPendiente" value="${ultimoCambio.rowCount > 0 and ultimoCambio.rows[0].estado == 'Pendiente'}" />
                <details class="app-tarjeta app-historial app-formulario h-100" ${hayCambioPendiente ? 'open' : ''}>
                    <summary>Cambio de modalidad<span class="text-secondary fw-normal">${hayCambioPendiente ? ' · solicitud pendiente' : ' · si necesitas otra modalidad'}</span></summary>
                    <div class="mt-3"></div>
                    <c:if test="${ultimoCambio.rowCount > 0}">
                        <c:set var="uc" value="${ultimoCambio.rows[0]}" />
                        <p class="app-observacion mt-0 mb-3">
                            <strong>Última solicitud:</strong> pasar a <c:out value="${uc.nueva}" /> · <c:out value="${uc.estado}" />
                            <span class="app-lista-nota">Motivo: <c:out value="${uc.motivo}" /><c:if test="${not empty uc.observacion}"> · Comité: <c:out value="${uc.observacion}" /></c:if></span>
                        </p>
                    </c:if>
                    <c:choose>
                        <c:when test="${terminado or p.fase > 3 or (esSeminario and p.estado != 'Pendiente')}">
                            <p class="app-total mt-0">${esSeminario ? 'En Seminario, la modalidad solo se cambia antes de que el comité valide la inscripción.' : 'La modalidad solo se cambia antes de que se apruebe el FDC-124.'}</p>
                        </c:when>
                        <c:when test="${hayCambioPendiente}">
                            <p class="app-total mt-0">Tu solicitud está esperando la decisión del comité.</p>
                        </c:when>
                        <c:otherwise>
                            <p class="text-secondary">Puedes pedir cambiar de modalidad sin perder lo que llevas; lo decide el comité.</p>
                            <form method="post" action="${ctx}/estudiante/modalidad-solicitar.jsp">
                                <label class="form-label" for="modalidadNueva">Nueva modalidad *</label>
                                <select class="form-select" id="modalidadNueva" name="modalidad" required>
                                    <option value="">Escoge la modalidad</option>
                                    <c:forEach var="mo" items="${otrasModalidades.rows}">
                                        <option value="${mo.id}"><c:out value="${mo.nombre}" /> (hasta <c:out value="${mo.max_integrantes}" />)</option>
                                    </c:forEach>
                                </select>
                                <label class="form-label mt-3" for="motivoCambio">Motivo *</label>
                                <textarea class="form-control" id="motivoCambio" name="motivo" required></textarea>
                                <button type="submit" class="btn btn-outline-dark rounded-pill mt-3">Pedir el cambio</button>
                            </form>
                        </c:otherwise>
                    </c:choose>
                </details>
            </div>
            </c:if>

            <%-- Exoneración por Saber TyT (RNF14): solo nivel tecnológico --%>
            <c:if test="${mostrarExoneracion}">
                <div class="col-lg">
                    <div class="app-tarjeta h-100 app-formulario">
                        <h2 class="app-tarjeta-titulo">Exoneración por Saber TyT</h2>
                        <c:choose>
                            <c:when test="${p.renuncia_exoneracion == true}">
                                <p class="mb-0">Renunciaste a la exoneración y sigues con el proyecto. La renuncia no tiene vuelta atrás.</p>
                            </c:when>
                            <c:when test="${p.exonerado == true}">
                                <p>Estás exonerado del informe final con <strong><c:out value="${ex.estimulo}" /></strong> (<c:out value="${ex.puntaje}" /> puntos).${p.integrantes > 1 ? ' Tus compañeros siguen con el proyecto.' : ''}</p>
                                <c:if test="${not terminado}">
                                    <form method="post" action="${ctx}/estudiante/exoneracion-renunciar.jsp"
                                          onsubmit="return confirm('¿Renunciar a la exoneración? Seguirás con el proyecto y no podrás volver a pedirla.');">
                                        <button type="submit" class="btn btn-outline-danger rounded-pill">Renunciar a la exoneración</button>
                                    </form>
                                </c:if>
                            </c:when>
                            <c:when test="${not empty ex and ex.estado == 'Pendiente'}">
                                <p class="mb-0">Pediste la exoneración con <c:out value="${ex.puntaje}" /> puntos. El comité está verificando tu certificado.</p>
                            </c:when>
                            <c:when test="${terminado or p.fase >= 5}">
                                <p class="mb-0">La exoneración se pide antes de entregar el informe final.</p>
                            </c:when>
                            <c:when test="${p.fase < 4 or empty p.fecha_aprobacion_124}">
                                <p class="mb-0">Si obtuviste 120 puntos o más en Saber TyT, podrás pedir que te exoneren del informe final cuando el comité apruebe tu propuesta (fase 4): 120–150, nota 4.5; 151–170, 4.7 y 50 % de beca; 171 o más, 5.0 y 100 % de beca (Acuerdo 01-009).</p>
                            </c:when>
                            <c:otherwise>
                                <c:if test="${not empty ex and ex.estado == 'Rechazada'}">
                                    <p class="app-observacion mt-0 mb-3"><strong>El comité rechazó tu solicitud:</strong> <c:out value="${ex.observacion}" /></p>
                                </c:if>
                                <p class="text-secondary">Si obtuviste 120 puntos o más en Saber TyT, quedas exento del informe final: 120–150, nota 4.5; 151–170, 4.7 y 50 % de beca; 171 o más, 5.0 y 100 % de beca (Acuerdo 01-009).</p>
                                <form method="post" action="${ctx}/estudiante/exoneracion-solicitar.jsp" enctype="multipart/form-data">
                                    <div class="row g-3">
                                        <div class="col-sm-4">
                                            <label class="form-label" for="puntaje">Puntaje *</label>
                                            <input class="form-control" type="number" id="puntaje" name="puntaje" min="120" max="300" step="1" required>
                                        </div>
                                        <div class="col-sm-8">
                                            <label class="form-label" for="certificado">Certificado (PDF) *</label>
                                            <input class="form-control" type="file" id="certificado" name="certificado" accept="application/pdf,.pdf" required>
                                        </div>
                                    </div>
                                    <button type="submit" class="btn btn-outline-dark rounded-pill mt-3">Pedir la exoneración</button>
                                </form>
                            </c:otherwise>
                        </c:choose>
                    </div>
                </div>
            </c:if>
        </div>
        </c:if>

        <c:set var="idProyectoHistorial" value="${p.id}" />
        <%@ include file="/WEB-INF/jspf/historial-proyecto.jspf" %>
    </c:otherwise>
</c:choose>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
