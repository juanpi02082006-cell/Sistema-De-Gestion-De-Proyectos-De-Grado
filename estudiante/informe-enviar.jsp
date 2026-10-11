<%-- El estudiante envía el informe final (la última versión del FDC-125) a su director,
     por POST: el proyecto pasa de la fase 4 (Informe I) a la 5 (Informe II), donde el
     director lo revisa y lo envía al evaluador y al comité (Anexo H, RF31). Reglas:
     proyecto vigente en la fase 4 con el FDC-124 aprobado por el comité; desde el día 90
     y hasta la fecha límite (180 días, RF31, RF38); con al menos 2 seguimientos del
     director (RF20) y con al menos una versión subida. Si la última versión ya se revisó
     (el director la devolvió o el comité la aplazó o no la aprobó), hay que subir una
     corregida; si el comité la aplazó, se envía dentro del plazo que indicó el
     evaluador (RF22). El director tiene 5 días hábiles para revisarla (RF21). --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.estado, p.titulo, p.fecha_aprobacion_124, f.orden AS fase,
           (CURDATE() >= p.fecha_aprobacion_124 + INTERVAL 90 DAY) AS abierto,
           (CURDATE() > p.fecha_limite) AS vencido,
           (SELECT COUNT(*) FROM seguimientos s WHERE s.proyecto_id = p.id) AS seguimientos,
           (SELECT MAX(e.version) FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125') AS version,
           (SELECT COUNT(*) FROM entregas e JOIN revisiones r ON r.entrega_id = e.id
            WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125' AND r.estado = 'Enviada' AND r.rol <> 'Codirector'
              AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = 'FDC-125')) AS revisada,
           (SELECT r.decision FROM entregas e JOIN revisiones r ON r.entrega_id = e.id
            WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125' AND r.rol = 'Comité' AND r.estado = 'Enviada'
            ORDER BY r.id DESC LIMIT 1) AS decision_comite,
           (SELECT CURDATE() > r.plazo_correccion FROM entregas e JOIN revisiones r ON r.entrega_id = e.id
            WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125' AND r.rol = 'Evaluador' AND r.estado = 'Enviada'
            ORDER BY r.id DESC LIMIT 1) AS plazo_vencido
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.fase != 4 or empty p.fecha_aprobacion_124}"><c:set var="motivo" value="informe-no-aplica" /></c:when>
    <c:when test="${empty p.version}"><c:set var="motivo" value="informe-requerido" /></c:when>
    <c:when test="${p.revisada > 0}"><c:set var="motivo" value="informe-ya-revisado" /></c:when>
    <c:when test="${p.decision_comite == 'Aplazado' and p.plazo_vencido == 1}"><c:set var="motivo" value="plazo-correccion-vencido" /></c:when>
    <c:when test="${p.abierto != 1}"><c:set var="motivo" value="informe-antes-de-90" /></c:when>
    <c:when test="${p.vencido == 1}"><c:set var="motivo" value="informe-vencido" /></c:when>
    <c:when test="${p.seguimientos < 2}"><c:set var="motivo" value="faltan-seguimientos" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/estudiante/proyecto.jsp">
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<c:set var="diasHabiles" value="5" />
<%@ include file="/WEB-INF/jspf/plazo-habil.jspf" %>

<sql:transaction>
    <sql:update var="cambiados">
        UPDATE proyectos SET fase_id = (SELECT id FROM fases WHERE orden = 5)
        WHERE id = ? AND fase_id = (SELECT id FROM fases WHERE orden = 4)
        <sql:param value="${p.id}" />
    </sql:update>
    <c:if test="${cambiados == 1}">
        <sql:update>
            INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Fase', ?)
            <sql:param value="${p.id}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="El estudiante envió la versión ${p.version} del FDC-125 (informe final) al director. El proyecto pasó a la fase 5 (Informe II)." />
        </sql:update>
        <sql:update>
            UPDATE entregas SET fecha_limite_revision = ? WHERE proyecto_id = ? AND tipo = 'FDC-125' AND version = ?
            <sql:dateParam value="${fechaPlazo}" type="date" />
            <sql:param value="${p.id}" />
            <sql:param value="${p.version}" />
        </sql:update>
        <c:set var="avisoProyecto" value="${p.id}" />
        <c:set var="avisoMensaje">Te enviaron la versión ${p.version} del informe final de «${p.titulo}» para revisarla. Tienes hasta el <fmt:formatDate value="${fechaPlazo}" pattern="dd/MM/yyyy" />.</c:set>
        <c:set var="avisoPara" value="director,codirectores" />
        <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
        <c:set var="avisoMensaje">Se envió la versión ${p.version} del informe final al director.</c:set>
        <c:set var="avisoPara" value="estudiantes,comite" />
        <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
    </c:if>
</sql:transaction>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="${cambiados == 1 ? 'ok' : 'error'}" value="${cambiados == 1 ? 'informe-enviado' : 'informe-no-aplica'}" />
</c:redirect>
