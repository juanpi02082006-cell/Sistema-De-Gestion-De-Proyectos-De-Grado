<%-- Página de inicio después de iniciar sesión, para todos los roles, con accesos
     a lo que puede hacer cada uno. --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<c:set var="titulo" value="Inicio" />
<c:set var="seccion" value="inicio" />
<c:set var="rol" value="${sessionScope.rolActivo.id}" />

<sql:query var="periodoActivo">SELECT nombre FROM periodos WHERE estado = 'Activo' LIMIT 1</sql:query>

<c:if test="${rol == 1}">
    <sql:query var="totalUsuarios">SELECT COUNT(*) AS total FROM usuarios</sql:query>
    <sql:query var="totalRoles">SELECT COUNT(*) AS total FROM roles</sql:query>
    <sql:query var="totalPeriodos">SELECT COUNT(*) AS total FROM periodos</sql:query>
    <sql:query var="ideasPendientes">SELECT COUNT(*) AS total FROM ideas WHERE estado = 'Pendiente'</sql:query>
    <%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
    <sql:query var="pagosPendientes">SELECT COUNT(*) AS total FROM proyectos p WHERE (${sqlEstadoPago}) = 'Por revisar'</sql:query>
    <sql:query var="solicitudesPendientes">
        SELECT (SELECT COUNT(*) FROM cambios_modalidad WHERE estado = 'Pendiente')
             + (SELECT COUNT(*) FROM exoneraciones WHERE estado = 'Pendiente')
             + (SELECT COUNT(*) FROM prorrogas WHERE estado = 'Pendiente') AS total
    </sql:query>
    <sql:query var="pqrsPendientes">SELECT COUNT(*) AS total FROM pqrs WHERE estado = 'Pendiente'</sql:query>
    <%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
    <%-- Propuestas con el concepto del evaluador, esperando la decisión del comité (RF14) --%>
    <sql:query var="propuestasPorDecidir">
        SELECT COUNT(*) AS total FROM (
            SELECT f.orden AS fase, ${sqlUltimaRevision} AS ultima, ${sqlUltimaRevisionInforme} AS ultima_informe
            FROM proyectos p JOIN fases f ON f.id = p.fase_id
            WHERE f.orden IN (4, 5) AND p.estado NOT IN ('Finalizado', 'Cancelado')
        ) t WHERE (fase = 4 AND ultima LIKE 'Evaluador:%' AND ultima <> 'Evaluador:Devuelto')
               OR (fase = 5 AND ultima_informe LIKE 'Evaluador:%')
    </sql:query>
    <%-- Fase final con la sustentación ya hecha: falta la aprobación final del comité (RF39) --%>
    <sql:query var="aprobacionesFinales">
        SELECT COUNT(*) AS total FROM proyectos p
        JOIN fases f ON f.id = p.fase_id
        JOIN sustentaciones s ON s.proyecto_id = p.id
        WHERE f.orden = 6 AND p.estado NOT IN ('Finalizado', 'Cancelado') AND s.fecha_hora <= NOW()
    </sql:query>
</c:if>
<c:if test="${rol == 4}">
    <%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
    <%-- Propuestas (fase 4) e informes finales (fase 5) que el director ya le envió --%>
    <sql:query var="porEvaluar">
        SELECT COUNT(*) AS total FROM (
            SELECT f.orden AS fase, ${sqlUltimaRevision} AS ultima, ${sqlUltimaRevisionInforme} AS ultima_informe
            FROM proyectos p JOIN fases f ON f.id = p.fase_id
            WHERE f.orden IN (4, 5) AND p.evaluador_id = ? AND p.estado NOT IN ('Finalizado', 'Cancelado')
        ) t WHERE (fase = 4 AND ultima = 'Director:Aprobado') OR (fase = 5 AND ultima_informe = 'Director:Aprobado')
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
</c:if>
<c:if test="${rol == 3 or rol == 4}">
    <sql:query var="misIdeas">
        SELECT COUNT(*) AS total FROM ideas WHERE propuesta_por = ? AND origen = 'Docente'
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
</c:if>
<c:if test="${rol == 3}">
    <%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
    <%-- Propuestas (fase 3) e informes finales (fase 5) que esperan su revisión --%>
    <sql:query var="porRevisar">
        SELECT COUNT(*) AS total FROM proyectos p JOIN fases f ON f.id = p.fase_id
        WHERE p.estado NOT IN ('Finalizado', 'Cancelado')
          AND (f.orden = 3 OR (f.orden = 5 AND COALESCE(${sqlUltimaRevisionInforme}, 'Comité:Devuelto') = 'Comité:Devuelto'))
          AND (p.director_id = ? OR EXISTS (SELECT 1 FROM proyecto_codirectores pc WHERE pc.proyecto_id = p.id AND pc.docente_id = ?))
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
</c:if>
<c:if test="${rol == 5}">
    <c:set var="idEstudiante" value="${sessionScope.usuario.id}" />
    <%@ include file="/WEB-INF/jspf/habilitacion.jspf" %>
    <sql:query var="proyectoVigente">
        SELECT p.titulo, p.estado, p.modalidad_id, f.orden AS fase, f.nombre AS nombre_fase
        FROM proyecto_estudiantes pe
        JOIN proyectos p ON p.id = pe.proyecto_id
        LEFT JOIN fases f ON f.id = p.fase_id
        WHERE pe.estudiante_id = ? AND pe.vigente = 1
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
</c:if>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<section class="app-encabezado">
    <h1>Hola, <c:out value="${sessionScope.usuario.nombre}" /></h1>
    <p>
        Entraste como <strong><c:out value="${sessionScope.rolActivo.nombre}" /></strong>.
        <c:choose>
            <c:when test="${periodoActivo.rowCount > 0}">Periodo vigente: <c:out value="${periodoActivo.rows[0].nombre}" />.</c:when>
            <c:otherwise>No hay un periodo activo.</c:otherwise>
        </c:choose>
    </p>
</section>

<c:if test="${rol == 1}">
    <c:set var="columnaComite" value="col-md-6 col-xl-4" />
    <div class="row g-4">
        <div class="${columnaComite}">
            <a class="app-acceso" href="${ctx}/admin/proyectos.jsp?filtro=pago">
                <span class="app-acceso-numero"><c:out value="${pagosPendientes.rows[0].total}" /></span>
                <span class="app-acceso-titulo">Pagos por revisar</span>
                <span class="app-acceso-texto">Revisar los recibos y asignar director y evaluador a cada proyecto.</span>
            </a>
        </div>
        <div class="${columnaComite}">
            <a class="app-acceso" href="${ctx}/admin/proyectos.jsp?filtro=modalidad">
                <span class="app-acceso-numero"><c:out value="${solicitudesPendientes.rows[0].total}" /></span>
                <span class="app-acceso-titulo">Solicitudes por decidir</span>
                <span class="app-acceso-texto">Cambios de modalidad, exoneraciones por Saber TyT y prórrogas.</span>
            </a>
        </div>
        <div class="${columnaComite}">
            <a class="app-acceso" href="${ctx}/admin/proyectos.jsp?filtro=propuestas">
                <span class="app-acceso-numero"><c:out value="${propuestasPorDecidir.rows[0].total}" /></span>
                <span class="app-acceso-titulo">Propuestas e informes por decidir</span>
                <span class="app-acceso-texto">Ya tienen el concepto del evaluador: falta la decisión del comité.</span>
            </a>
        </div>
        <div class="${columnaComite}">
            <a class="app-acceso" href="${ctx}/admin/proyectos.jsp?filtro=sustentacion">
                <span class="app-acceso-numero"><c:out value="${aprobacionesFinales.rows[0].total}" /></span>
                <span class="app-acceso-titulo">Aprobaciones finales</span>
                <span class="app-acceso-texto">Proyectos que ya sustentaron: falta registrar la aprobación final.</span>
            </a>
        </div>
        <div class="${columnaComite}">
            <a class="app-acceso" href="${ctx}/admin/pqrs.jsp">
                <span class="app-acceso-numero"><c:out value="${pqrsPendientes.rows[0].total}" /></span>
                <span class="app-acceso-titulo">PQR pendientes</span>
                <span class="app-acceso-texto">Peticiones, quejas y reclamos por responder.</span>
            </a>
        </div>
        <div class="${columnaComite}">
            <a class="app-acceso" href="${ctx}/admin/usuarios.jsp">
                <span class="app-acceso-numero"><c:out value="${totalUsuarios.rows[0].total}" /></span>
                <span class="app-acceso-titulo">Usuarios</span>
                <span class="app-acceso-texto">Registrar docentes y actualizar los datos de los estudiantes.</span>
            </a>
        </div>
        <div class="${columnaComite}">
            <a class="app-acceso" href="${ctx}/admin/roles.jsp">
                <span class="app-acceso-numero"><c:out value="${totalRoles.rows[0].total}" /></span>
                <span class="app-acceso-titulo">Roles</span>
                <span class="app-acceso-texto">Crear, ver, editar y eliminar los roles.</span>
            </a>
        </div>
        <div class="${columnaComite}">
            <a class="app-acceso" href="${ctx}/admin/periodos.jsp">
                <span class="app-acceso-numero"><c:out value="${totalPeriodos.rows[0].total}" /></span>
                <span class="app-acceso-titulo">Periodos</span>
                <span class="app-acceso-texto">Calendario de cada semestre: crear, activar y cerrar.</span>
            </a>
        </div>
        <div class="${columnaComite}">
            <a class="app-acceso" href="${ctx}/ideas/banco.jsp">
                <span class="app-acceso-numero"><c:out value="${ideasPendientes.rows[0].total}" /></span>
                <span class="app-acceso-titulo">Ideas por revisar</span>
                <span class="app-acceso-texto">Aprobar o rechazar las ideas y las propuestas.</span>
            </a>
        </div>
    </div>
</c:if>

<c:if test="${rol == 3 or rol == 4}">
    <c:set var="columnaDocente" value="col-md-6 col-xl-4" />
    <div class="row g-4">
        <c:if test="${rol == 4}">
            <div class="${columnaDocente}">
                <a class="app-acceso" href="${ctx}/evaluador/proyectos.jsp">
                    <span class="app-acceso-numero"><c:out value="${porEvaluar.rows[0].total}" /></span>
                    <span class="app-acceso-titulo">Por evaluar</span>
                    <span class="app-acceso-texto">Las propuestas y los informes finales que te envió el director, para evaluarlos con su rejilla.</span>
                </a>
            </div>
        </c:if>
        <c:if test="${rol == 3}">
            <div class="${columnaDocente}">
                <a class="app-acceso" href="${ctx}/director/proyectos.jsp">
                    <span class="app-acceso-numero"><c:out value="${porRevisar.rows[0].total}" /></span>
                    <span class="app-acceso-titulo">Por revisar</span>
                    <span class="app-acceso-texto">Los proyectos que diriges, y las propuestas y los informes finales que te enviaron.</span>
                </a>
            </div>
        </c:if>
        <div class="${columnaDocente}">
            <a class="app-acceso" href="${ctx}/ideas/banco.jsp">
                <span class="app-acceso-numero"><c:out value="${misIdeas.rows[0].total}" /></span>
                <span class="app-acceso-titulo">Mis ideas</span>
                <span class="app-acceso-texto">Registrar ideas para el banco y ver si el comité las aprobó.</span>
            </a>
        </div>
        <div class="${columnaDocente}">
            <a class="app-acceso" href="${ctx}/panel/calendario.jsp">
                <span class="app-acceso-numero"><svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/></svg></span>
                <span class="app-acceso-titulo">Calendario</span>
                <span class="app-acceso-texto">Fechas del periodo vigente.</span>
            </a>
        </div>
    </div>
</c:if>

<c:if test="${rol == 5}">
    <c:choose>
        <c:when test="${proyectoVigente.rowCount > 0}">
            <c:set var="pv" value="${proyectoVigente.rows[0]}" />
            <div class="app-resultado cumple">
                <h2>Tu proyecto: <c:out value="${pv.titulo}" /></h2>
                <p><c:choose><c:when test="${pv.modalidad_id == 5}">Seminario · ${pv.estado == 'Pendiente' ? 'Inscripción' : (pv.estado == 'En curso' ? 'En curso' : pv.estado)}</c:when><c:otherwise>${pv.fase == 6 ? 'Fase final' : 'Fase '}<c:if test="${pv.fase != 6}"><c:out value="${pv.fase}" /></c:if>: <c:out value="${pv.nombre_fase}" /> · Estado: <c:out value="${pv.estado}" /></c:otherwise></c:choose> · <a href="${ctx}/estudiante/proyecto.jsp">Ver mi proyecto</a></p>
            </div>
            <c:set var="faseActual" value="${pv.fase}" />
            <c:set var="esSeminario" value="${pv.modalidad_id == 5}" />
            <c:set var="estadoProyecto" value="${pv.estado}" />
            <%@ include file="/WEB-INF/jspf/fases-proyecto.jspf" %>
        </c:when>
        <c:otherwise>
            <div class="app-resultado ${habilitado ? 'cumple' : ''}">
                <h2>${habilitado ? 'Estás habilitado para empezar tu trabajo de grado' : 'Todavía no estás habilitado'}</h2>
                <p>${habilitado ? 'Escoge una idea del banco o formula tu propia propuesta.' : 'Revisa qué requisito te falta.'}</p>
            </div>
        </c:otherwise>
    </c:choose>
    <div class="row g-4">
        <div class="col-md-4">
            <a class="app-acceso" href="${ctx}/estudiante/habilitacion.jsp">
                <span class="app-acceso-numero">${habilitado ? '✓' : '!'}</span>
                <span class="app-acceso-titulo">Habilitación</span>
                <span class="app-acceso-texto">Tus requisitos para la fase 1.</span>
            </a>
        </div>
        <div class="col-md-4">
            <a class="app-acceso" href="${ctx}/ideas/banco.jsp">
                <span class="app-acceso-numero"><svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24" aria-hidden="true"><path d="M9 18h6M10 22h4"/><path d="M12 2a7 7 0 0 0-4 12.7c.6.5 1 1.3 1 2.1V18h6v-1.2c0-.8.4-1.6 1-2.1A7 7 0 0 0 12 2z"/></svg></span>
                <span class="app-acceso-titulo">Banco de ideas</span>
                <span class="app-acceso-texto">Toma una idea de tu nivel o formula tu propuesta.</span>
            </a>
        </div>
        <div class="col-md-4">
            <a class="app-acceso" href="${ctx}/panel/calendario.jsp">
                <span class="app-acceso-numero"><svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/></svg></span>
                <span class="app-acceso-titulo">Calendario</span>
                <span class="app-acceso-texto">Fechas del periodo vigente.</span>
            </a>
        </div>
    </div>
</c:if>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
