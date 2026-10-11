<%-- El comité (el administrador, que hace de coordinación) valida o devuelve la
     inscripción al Seminario de un proyecto (RF17; proceso entregado por el equipo el
     2026-10-10), por POST, con observación obligatoria (RF34).
       aprobar   exige el pago de todos aprobado, los documentos de inscripción de todos
                 (F-AM-04 y documento de identidad) y el docente del seminario asignado
                 como director: el proyecto queda "En curso" (seminario en curso).
       devolver  los estudiantes ven la observación y corrigen sus documentos. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/admin/proyectos.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.titulo, p.estado, p.modalidad_id, p.director_id, f.orden AS fase,
           ${sqlEstadoPago} AS estado_pago, ${sqlDocumentosFaltantes} AS documentos_faltantes
    FROM proyectos p LEFT JOIN fases f ON f.id = p.fase_id
    WHERE p.id = ?
    <sql:param value="${param.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/admin/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="observacion" value="${fn:trim(param.observacion)}" />
<c:set var="aprobar" value="${param.decision == 'aprobar'}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.modalidad_id != 5}"><c:set var="motivo" value="inscripcion-no-aplica" /></c:when>
    <c:when test="${p.estado != 'Pendiente'}"><c:set var="motivo" value="inscripcion-cerrada" /></c:when>
    <c:when test="${param.decision != 'aprobar' and param.decision != 'devolver'}"><c:set var="motivo" value="general" /></c:when>
    <c:when test="${empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
    <c:when test="${aprobar and p.estado_pago != 'Aprobado' and p.estado_pago != 'No aplica'}"><c:set var="motivo" value="pagos-pendientes" /></c:when>
    <c:when test="${aprobar and p.documentos_faltantes > 0}"><c:set var="motivo" value="inscripcion-incompleta" /></c:when>
    <c:when test="${aprobar and empty p.director_id}"><c:set var="motivo" value="sin-director" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/admin/proyecto.jsp">
        <c:param name="id" value="${p.id}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<sql:transaction>
    <c:if test="${aprobar}">
        <sql:update>
            UPDATE proyectos SET estado = 'En curso', fecha_inicio = CURDATE() WHERE id = ? AND estado = 'Pendiente'
            <sql:param value="${p.id}" />
        </sql:update>
    </c:if>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Decisión', ?)
        <sql:param value="${p.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${aprobar ? 'El comité validó la inscripción al seminario: el seminario está en curso.' : 'El comité devolvió la inscripción al seminario para corregir los documentos.'}" />
    </sql:update>
    <c:set var="avisoProyecto" value="${p.id}" />
    <c:set var="avisoMensaje">${aprobar ? 'El comité validó tu inscripción al seminario: ya está en curso.' : 'El comité devolvió tu inscripción al seminario: revisa tus documentos.'} Observación: ${observacion}</c:set>
    <c:set var="avisoPara" value="estudiantes" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
    <c:if test="${aprobar}">
        <c:set var="avisoMensaje">El comité validó la inscripción al seminario «${p.titulo}». Al terminar, registra la nota final.</c:set>
        <c:set var="avisoPara" value="director" />
        <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
    </c:if>
</sql:transaction>

<c:redirect url="/admin/proyecto.jsp">
    <c:param name="id" value="${p.id}" />
    <c:param name="ok" value="${aprobar ? 'inscripcion-validada' : 'inscripcion-devuelta'}" />
</c:redirect>
