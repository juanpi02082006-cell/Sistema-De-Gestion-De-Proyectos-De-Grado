<%-- Un codirector deja una observación sobre la última versión de la propuesta, en la
     fase 3, por POST (RF13: los codirectores ven el proyecto y comentan; decide el
     director, decisión del equipo del 2026-10-10). Queda en revisiones con rol
     Codirector y sin decisión. La ven el director, los estudiantes y el comité. --%>
<%@ include file="/WEB-INF/jspf/solo-director.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/director/proyectos.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.estado, p.titulo, f.orden AS fase, e.id AS entrega_id, e.version
    FROM proyectos p
    JOIN proyecto_codirectores pc ON pc.proyecto_id = p.id AND pc.docente_id = ?
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN entregas e ON e.proyecto_id = p.id AND e.tipo = 'FDC-124'
         AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = 'FDC-124')
    WHERE p.id = ?
    <sql:param value="${sessionScope.usuario.id}" />
    <sql:param value="${empty param.id ? 0 : param.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/director/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="observacion" value="${fn:trim(param.observacion)}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.fase != 3 or empty p.entrega_id}"><c:set var="motivo" value="propuesta-no-revisable" /></c:when>
    <c:when test="${empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/director/proyecto.jsp">
        <c:param name="id" value="${p.id}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<sql:transaction>
    <sql:update>
        INSERT INTO revisiones (entrega_id, revisor_id, rol, estado, decision, observacion)
        VALUES (?, ?, 'Codirector', 'Enviada', NULL, ?)
        <sql:param value="${p.entrega_id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${observacion}" />
    </sql:update>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Evaluación', ?)
        <sql:param value="${p.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="Un codirector dejó una observación sobre la versión ${p.version} del FDC-124." />
    </sql:update>
    <c:set var="avisoProyecto" value="${p.id}" />
    <c:set var="avisoMensaje">El codirector ${sessionScope.usuario.nombre} dejó una observación sobre la versión ${p.version} de la propuesta.</c:set>
    <c:set var="avisoPara" value="director,estudiantes,codirectores" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
</sql:transaction>

<c:redirect url="/director/proyecto.jsp">
    <c:param name="id" value="${p.id}" />
    <c:param name="ok" value="observacion-codirector" />
</c:redirect>
