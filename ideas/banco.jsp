<%-- Banco de ideas (RF10, RF25). Según el rol activo:
     - Administrador (el comité): revisa las ideas y las propuestas, y las aprueba o
       las rechaza con observación obligatoria (RF34).
     - Director o Evaluador (docentes): registran ideas y ven cómo van.
     - Estudiante: ve las ideas aprobadas de su nivel y las toma antes del cierre del
       banco (RF25); también puede formular su propia propuesta (RF10). --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<c:set var="titulo" value="Banco de ideas" />
<c:set var="seccion" value="ideas" />
<c:set var="rol" value="${sessionScope.rolActivo.id}" />
<c:set var="esAdmin" value="${rol == 1}" />
<c:set var="esDocente" value="${rol == 3 or rol == 4}" />
<c:set var="esEstudiante" value="${rol == 5}" />
<c:set var="idUsuario" value="${sessionScope.usuario.id}" />

<sql:query var="periodoActivo">
    SELECT id, nombre, fecha_cierre_banco,
           (fecha_cierre_banco IS NULL OR CURDATE() <= fecha_cierre_banco) AS abierto
    FROM periodos WHERE estado = 'Activo' LIMIT 1
</sql:query>
<c:set var="hayPeriodo" value="${periodoActivo.rowCount > 0}" />
<c:set var="bancoAbierto" value="${hayPeriodo and periodoActivo.rows[0].abierto == 1}" />

<%-- ---------- Administrador ---------- --%>
<c:if test="${esAdmin}">
    <c:set var="estadoFiltro" value="${empty param.estado ? 'Pendiente' : param.estado}" />
    <sql:query var="ideas">
        SELECT i.id, i.titulo, i.descripcion, i.origen, i.estado, i.observacion_revision, i.creado_en,
               n.nombre AS nivel, m.nombre AS modalidad, l.nombre AS linea, p.nombre AS periodo,
               u.nombre AS autor
        FROM ideas i
        JOIN niveles n ON n.id = i.nivel_id
        JOIN usuarios u ON u.id = i.propuesta_por
        LEFT JOIN modalidades m ON m.id = i.modalidad_id
        LEFT JOIN lineas_investigacion l ON l.id = i.linea_investigacion_id
        LEFT JOIN periodos p ON p.id = i.periodo_id
        WHERE (? = 'Todas' OR i.estado = ?)
        ORDER BY i.creado_en DESC
        <sql:param value="${estadoFiltro}" />
        <sql:param value="${estadoFiltro}" />
    </sql:query>
</c:if>

<%-- ---------- Docente ---------- --%>
<c:if test="${esDocente or esEstudiante}">
    <sql:query var="misIdeas">
        SELECT i.id, i.titulo, i.descripcion, i.estado, i.observacion_revision,
               n.nombre AS nivel, m.nombre AS modalidad, l.nombre AS linea
        FROM ideas i
        JOIN niveles n ON n.id = i.nivel_id
        LEFT JOIN modalidades m ON m.id = i.modalidad_id
        LEFT JOIN lineas_investigacion l ON l.id = i.linea_investigacion_id
        WHERE i.propuesta_por = ? AND i.origen = ?
        ORDER BY i.creado_en DESC
        <sql:param value="${idUsuario}" />
        <sql:param value="${esEstudiante ? 'Estudiante' : 'Docente'}" />
    </sql:query>
</c:if>

<%-- ---------- Estudiante ---------- --%>
<c:if test="${esEstudiante}">
    <c:set var="idEstudiante" value="${idUsuario}" />
    <%@ include file="/WEB-INF/jspf/habilitacion.jspf" %>
    <sql:query var="proyectoVigente">
        SELECT p.id, p.titulo, p.estado, f.orden AS fase, f.nombre AS nombre_fase, m.nombre AS modalidad
        FROM proyecto_estudiantes pe
        JOIN proyectos p ON p.id = pe.proyecto_id
        JOIN modalidades m ON m.id = p.modalidad_id
        LEFT JOIN fases f ON f.id = p.fase_id
        WHERE pe.estudiante_id = ? AND pe.vigente = 1
        <sql:param value="${idUsuario}" />
    </sql:query>
    <c:set var="tieneProyecto" value="${proyectoVigente.rowCount > 0}" />
    <%-- Ideas aprobadas de su nivel: las de los docentes y sus propias propuestas --%>
    <sql:query var="disponibles">
        SELECT i.id, i.titulo, i.descripcion, i.origen, i.modalidad_id,
               m.nombre AS modalidad, l.nombre AS linea, u.nombre AS autor
        FROM ideas i
        JOIN usuarios u ON u.id = i.propuesta_por
        LEFT JOIN modalidades m ON m.id = i.modalidad_id
        LEFT JOIN lineas_investigacion l ON l.id = i.linea_investigacion_id
        WHERE i.estado = 'Aprobada' AND i.nivel_id = ?
          AND (i.origen = 'Docente' OR i.propuesta_por = ?)
        ORDER BY i.titulo
        <sql:param value="${est.nivel_id}" />
        <sql:param value="${idUsuario}" />
    </sql:query>
    <sql:query var="modalidades">SELECT id, nombre FROM modalidades ORDER BY id</sql:query>
    <c:set var="puedeTomar" value="${habilitado and bancoAbierto and not tieneProyecto}" />
</c:if>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado app-encabezado-acciones">
    <div>
        <h1>Banco de ideas</h1>
        <p>
            <c:choose>
                <c:when test="${not hayPeriodo}">No hay un periodo activo: el banco está cerrado.</c:when>
                <c:when test="${bancoAbierto}">
                    Periodo <c:out value="${periodoActivo.rows[0].nombre}" />. El banco está abierto<c:if test="${not empty periodoActivo.rows[0].fecha_cierre_banco}"> hasta el <fmt:formatDate value="${periodoActivo.rows[0].fecha_cierre_banco}" pattern="dd/MM/yyyy" /></c:if>.
                </c:when>
                <c:otherwise>Periodo <c:out value="${periodoActivo.rows[0].nombre}" />. El banco cerró el <fmt:formatDate value="${periodoActivo.rows[0].fecha_cierre_banco}" pattern="dd/MM/yyyy" />.</c:otherwise>
            </c:choose>
        </p>
    </div>
    <c:if test="${esDocente}">
        <a class="btn btn-primary rounded-pill app-boton" href="${ctx}/ideas/idea-form.jsp">Registrar idea</a>
    </c:if>
    <c:if test="${esEstudiante}">
        <a class="btn btn-primary rounded-pill app-boton" href="${ctx}/ideas/idea-form.jsp">Formular mi propuesta</a>
    </c:if>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<%-- =================== Administrador: revisión del comité =================== --%>
<c:if test="${esAdmin}">
    <div class="app-tarjeta">
        <form class="app-filtros" method="get" action="${ctx}/ideas/banco.jsp">
            <select class="form-select" name="estado" aria-label="Filtrar por estado" onchange="this.form.submit()">
                <option value="Pendiente" ${estadoFiltro == 'Pendiente' ? 'selected' : ''}>Pendientes de revisión</option>
                <option value="Aprobada" ${estadoFiltro == 'Aprobada' ? 'selected' : ''}>Aprobadas</option>
                <option value="Rechazada" ${estadoFiltro == 'Rechazada' ? 'selected' : ''}>Rechazadas</option>
                <option value="Tomada" ${estadoFiltro == 'Tomada' ? 'selected' : ''}>Tomadas</option>
                <option value="Todas" ${estadoFiltro == 'Todas' ? 'selected' : ''}>Todas</option>
            </select>
            <noscript><button type="submit" class="btn btn-dark rounded-pill">Filtrar</button></noscript>
        </form>

        <c:choose>
            <c:when test="${ideas.rowCount == 0}">
                <p class="app-vacio">No hay ideas en este estado.</p>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table app-tabla align-middle">
                        <thead>
                            <tr>
                                <th>Idea</th>
                                <th>Propuesta por</th>
                                <th>Nivel</th>
                                <th>Estado</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="i" items="${ideas.rows}">
                                <tr>
                                    <td>
                                        <span class="fw-semibold"><c:out value="${i.titulo}" /></span>
                                        <c:if test="${not empty i.modalidad}"><span class="app-etiqueta"><c:out value="${i.modalidad}" /></span></c:if>
                                        <c:if test="${not empty i.linea}"><span class="app-etiqueta"><c:out value="${i.linea}" /></span></c:if>
                                        <c:if test="${not empty i.descripcion}"><span class="app-lista-nota"><c:out value="${i.descripcion}" /></span></c:if>
                                        <c:if test="${not empty i.observacion_revision}">
                                            <p class="app-observacion"><strong>Observación del comité:</strong> <c:out value="${i.observacion_revision}" /></p>
                                        </c:if>
                                        <c:if test="${i.estado == 'Pendiente'}">
                                            <form class="app-revision" method="post" action="${ctx}/ideas/idea-revisar.jsp">
                                                <input type="hidden" name="id" value="${i.id}">
                                                <textarea class="form-control" name="observacion" placeholder="Observación del comité (obligatoria)" aria-label="Observación" required></textarea>
                                                <button type="submit" name="decision" value="aprobar" class="btn btn-sm btn-primary rounded-pill">Aprobar</button>
                                                <button type="submit" name="decision" value="rechazar" class="btn btn-sm btn-outline-dark rounded-pill">Rechazar</button>
                                            </form>
                                        </c:if>
                                    </td>
                                    <td>
                                        <c:out value="${i.autor}" />
                                        <span class="app-lista-nota">${i.origen == 'Docente' ? 'Docente' : 'Estudiante (propuesta propia)'}</span>
                                    </td>
                                    <td><c:out value="${i.nivel}" /></td>
                                    <td><span class="app-estado ${i.estado == 'Aprobada' ? 'activo' : 'inactivo'}"><c:out value="${i.estado}" /></span></td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
                <p class="app-total">${ideas.rowCount} ${ideas.rowCount == 1 ? 'idea' : 'ideas'}</p>
            </c:otherwise>
        </c:choose>
    </div>
</c:if>

<%-- =================== Estudiante: ideas disponibles =================== --%>
<c:if test="${esEstudiante}">
    <c:if test="${tieneProyecto}">
        <c:set var="pv" value="${proyectoVigente.rows[0]}" />
        <div class="app-resultado cumple">
            <h2>Tu proyecto: <c:out value="${pv.titulo}" /></h2>
            <p><c:out value="${pv.modalidad}" /> · Fase <c:out value="${pv.fase}" />: <c:out value="${pv.nombre_fase}" /> · Estado: <c:out value="${pv.estado}" />. Solo puedes tener un proyecto a la vez.</p>
        </div>
    </c:if>
    <c:if test="${not tieneProyecto and not habilitado}">
        <div class="alert alert-warning app-aviso" role="status">
            Todavía no cumples los requisitos para tomar una idea. <a href="${ctx}/estudiante/habilitacion.jsp">Revisa tu habilitación</a>.
        </div>
    </c:if>

    <h2 class="app-seccion-titulo">Ideas disponibles para tu nivel</h2>
    <c:choose>
        <c:when test="${disponibles.rowCount == 0}">
            <div class="app-tarjeta"><p class="app-vacio mt-0">No hay ideas aprobadas para tu nivel por ahora.</p></div>
        </c:when>
        <c:otherwise>
            <div class="row g-4">
                <c:forEach var="i" items="${disponibles.rows}">
                    <div class="col-md-6">
                        <div class="app-ficha">
                            <h3><c:out value="${i.titulo}" /></h3>
                            <div class="app-ficha-datos">
                                <c:if test="${not empty i.modalidad}"><span class="app-etiqueta ms-0"><c:out value="${i.modalidad}" /></span></c:if>
                                <c:if test="${not empty i.linea}"><span class="app-etiqueta ms-0"><c:out value="${i.linea}" /></span></c:if>
                                <c:if test="${i.origen == 'Estudiante'}"><span class="app-etiqueta ms-0">Tu propuesta</span></c:if>
                            </div>
                            <p><c:out value="${i.descripcion}" /></p>
                            <p class="app-lista-nota">Propuesta por <c:out value="${i.autor}" /></p>
                            <c:if test="${puedeTomar}">
                                <form class="app-ficha-pie app-formulario" method="post" action="${ctx}/ideas/idea-tomar.jsp"
                                      onsubmit="return confirm('¿Tomar esta idea? Se crea tu proyecto y solo puedes tener uno a la vez.');">
                                    <input type="hidden" name="id" value="${i.id}">
                                    <c:if test="${empty i.modalidad_id}">
                                        <label class="form-label" for="modalidad${i.id}">Modalidad de tu proyecto *</label>
                                        <select class="form-select mb-2" id="modalidad${i.id}" name="modalidad" required>
                                            <option value="">Escoge la modalidad</option>
                                            <c:forEach var="m" items="${modalidades.rows}">
                                                <option value="${m.id}"><c:out value="${m.nombre}" /></option>
                                            </c:forEach>
                                        </select>
                                    </c:if>
                                    <button type="submit" class="btn btn-primary rounded-pill">Tomar esta idea</button>
                                </form>
                            </c:if>
                        </div>
                    </div>
                </c:forEach>
            </div>
        </c:otherwise>
    </c:choose>
</c:if>

<%-- =================== Docente y estudiante: lo que registró =================== --%>
<c:if test="${esDocente or esEstudiante}">
    <h2 class="app-seccion-titulo">${esDocente ? 'Mis ideas' : 'Mis propuestas'}</h2>
    <div class="app-tarjeta">
        <c:choose>
            <c:when test="${misIdeas.rowCount == 0}">
                <p class="app-vacio mt-0">${esDocente ? 'Todavía no has registrado ideas.' : 'Todavía no has formulado propuestas.'}</p>
            </c:when>
            <c:otherwise>
                <div class="table-responsive">
                    <table class="table app-tabla align-middle">
                        <thead>
                            <tr>
                                <th>Idea</th>
                                <th>Nivel</th>
                                <th>Estado</th>
                                <th class="text-end">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="i" items="${misIdeas.rows}">
                                <tr>
                                    <td>
                                        <span class="fw-semibold"><c:out value="${i.titulo}" /></span>
                                        <c:if test="${not empty i.modalidad}"><span class="app-etiqueta"><c:out value="${i.modalidad}" /></span></c:if>
                                        <c:if test="${not empty i.observacion_revision}">
                                            <p class="app-observacion"><strong>Observación del comité:</strong> <c:out value="${i.observacion_revision}" /></p>
                                        </c:if>
                                    </td>
                                    <td><c:out value="${i.nivel}" /></td>
                                    <td><span class="app-estado ${i.estado == 'Aprobada' ? 'activo' : 'inactivo'}"><c:out value="${i.estado}" /></span></td>
                                    <td class="text-end app-acciones">
                                        <c:if test="${i.estado == 'Pendiente' or i.estado == 'Rechazada'}">
                                            <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/ideas/idea-form.jsp?id=${i.id}">Editar</a>
                                            <form method="post" action="${ctx}/ideas/idea-eliminar.jsp" class="d-inline"
                                                  onsubmit="return confirm('¿Eliminar esta idea?');">
                                                <input type="hidden" name="id" value="${i.id}">
                                                <button type="submit" class="btn btn-sm btn-outline-danger rounded-pill">Eliminar</button>
                                            </form>
                                        </c:if>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </c:otherwise>
        </c:choose>
    </div>
</c:if>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
