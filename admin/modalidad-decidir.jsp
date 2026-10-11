<%-- El comité (el administrador) aprueba o rechaza una solicitud de cambio de modalidad
     (RF12), por POST, con observación obligatoria (RF34). Solo mientras el proyecto
     siga antes de la aprobación del FDC-124 (fases 1 a 3). Si la aprueba, el proyecto
     queda con la nueva modalidad sin perder el proceso; si la nueva no es de
     investigación ni de desarrollo tecnológico, deja de ser interdisciplinario y se
     quitan los codirectores (RF13). Queda registro de quién decidió y cuándo. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/admin/proyectos.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT c.id, c.proyecto_id, c.modalidad_nueva_id, c.estado AS estado_solicitud, m.nombre AS nueva, m.max_integrantes,
           p.estado, p.titulo, p.interdisciplinario, f.orden AS fase,
           (SELECT COUNT(*) FROM proyecto_estudiantes x WHERE x.proyecto_id = p.id AND x.vigente = 1) AS integrantes
    FROM cambios_modalidad c
    JOIN proyectos p ON p.id = c.proyecto_id
    JOIN modalidades m ON m.id = c.modalidad_nueva_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE c.id = ?
    <sql:param value="${param.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/admin/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="s" value="${consulta.rows[0]}" />
<c:set var="observacion" value="${fn:trim(param.observacion)}" />
<c:set var="aprobar" value="${param.decision == 'aprobar'}" />
<c:set var="sigueInterdisciplinario" value="${s.interdisciplinario == true and (s.modalidad_nueva_id == 1 or s.modalidad_nueva_id == 2)}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${s.estado_solicitud != 'Pendiente'}"><c:set var="motivo" value="modalidad-ya-decidida" /></c:when>
    <c:when test="${s.estado == 'Finalizado' or s.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${param.decision != 'aprobar' and param.decision != 'rechazar'}"><c:set var="motivo" value="general" /></c:when>
    <c:when test="${empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
    <c:when test="${aprobar and (s.fase < 1 or s.fase > 3)}"><c:set var="motivo" value="modalidad-fuera-de-tiempo" /></c:when>
    <c:when test="${aprobar and s.integrantes > (sigueInterdisciplinario ? 4 : s.max_integrantes)}"><c:set var="motivo" value="modalidad-integrantes" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/admin/proyecto.jsp">
        <c:param name="id" value="${s.proyecto_id}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<sql:transaction>
    <sql:update>
        UPDATE cambios_modalidad SET estado = ?, decidido_por = ?, decidido_en = NOW(), observacion = ?
        WHERE id = ? AND estado = 'Pendiente'
        <sql:param value="${aprobar ? 'Aprobada' : 'Rechazada'}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${observacion}" />
        <sql:param value="${s.id}" />
    </sql:update>
    <c:if test="${aprobar}">
        <sql:update>
            UPDATE proyectos SET modalidad_id = ?, interdisciplinario = ? WHERE id = ?
            <sql:param value="${s.modalidad_nueva_id}" />
            <sql:param value="${sigueInterdisciplinario ? 1 : 0}" />
            <sql:param value="${s.proyecto_id}" />
        </sql:update>
        <c:if test="${not sigueInterdisciplinario}">
            <sql:update>
                DELETE FROM proyecto_codirectores WHERE proyecto_id = ?
                <sql:param value="${s.proyecto_id}" />
            </sql:update>
        </c:if>
    </c:if>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Modalidad', ?)
        <sql:param value="${s.proyecto_id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="El comité ${aprobar ? 'aprobó' : 'rechazó'} el cambio de modalidad a ${s.nueva}." />
    </sql:update>
    <c:set var="avisoProyecto" value="${s.proyecto_id}" />
    <c:set var="avisoMensaje">El comité ${aprobar ? 'aprobó' : 'rechazó'} el cambio de modalidad del proyecto a ${s.nueva}. Observación: ${observacion}</c:set>
    <c:set var="avisoPara" value="estudiantes,director,codirectores" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
</sql:transaction>

<c:redirect url="/admin/proyecto.jsp">
    <c:param name="id" value="${s.proyecto_id}" />
    <c:param name="ok" value="${aprobar ? 'modalidad-aprobada' : 'modalidad-rechazada'}" />
</c:redirect>
