<%-- Un proyecto visto por su director o codirector, ?id=...: sus fases, la información
     de los estudiantes (RF19) y las versiones de la propuesta FDC-124 (RF18, RF43).
     El director no ve aquí quién es el evaluador. --%>
<%@ include file="/WEB-INF/jspf/solo-director.jspf" %>
<c:set var="titulo" value="Proyecto" />
<c:set var="seccion" value="dirigidos" />

<sql:query var="consulta">
    SELECT p.id, p.codigo, p.titulo, p.descripcion, p.estado, p.fecha_inicio, p.modalidad_id,
           f.orden AS fase, f.nombre AS nombre_fase, m.nombre AS modalidad, n.nombre AS nivel,
           pr.nombre AS periodo, pr.fecha_limite_propuestas
    FROM proyectos p
    JOIN modalidades m ON m.id = p.modalidad_id
    JOIN niveles n ON n.id = p.nivel_id
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN periodos pr ON pr.id = p.periodo_id
    WHERE p.id = ?
      AND (p.director_id = ? OR EXISTS (SELECT 1 FROM proyecto_codirectores pc WHERE pc.proyecto_id = p.id AND pc.docente_id = ?))
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
            <c:when test="${p.fase == 3}"><p class="text-secondary">El estudiante te envió la propuesta para revisarla. La versión que debes revisar es la más reciente.</p></c:when>
        </c:choose>
        <c:set var="idProyectoPropuesta" value="${p.id}" />
        <%@ include file="/WEB-INF/jspf/propuesta-versiones.jspf" %>
    </div>
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
