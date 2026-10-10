<%-- El estudiante envía la propuesta (la última versión del FDC-124) a su director, por
     POST: el proyecto pasa de la fase 2 (Propuesta I) a la 3 (Propuesta II), donde el
     director la revisa (RF18, RF37). Reglas: proyecto vigente en la fase 2, con director
     y con al menos una versión subida; si el director devolvió la última versión, hay
     que subir una nueva antes de volver a enviarla (RF43). --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<c:set var="idEstudiante" value="${sessionScope.usuario.id}" />
<sql:query var="consulta">
    SELECT p.id, p.modalidad_id, p.director_id, f.orden AS fase,
           (SELECT MAX(e.version) FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124') AS version,
           (SELECT COUNT(*) FROM entregas e JOIN revisiones r ON r.entrega_id = e.id
            WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124' AND r.estado = 'Enviada' AND r.decision = 'Devuelto'
              AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = 'FDC-124')) AS devuelta
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${idEstudiante}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.modalidad_id == 5}"><c:set var="motivo" value="seminario-sin-124" /></c:when>
    <c:when test="${p.fase != 2}"><c:set var="motivo" value="fase-no-permite-propuesta" /></c:when>
    <c:when test="${empty p.director_id}"><c:set var="motivo" value="sin-director" /></c:when>
    <c:when test="${empty p.version}"><c:set var="motivo" value="propuesta-requerida" /></c:when>
    <c:when test="${p.devuelta > 0}"><c:set var="motivo" value="propuesta-devuelta" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/estudiante/proyecto.jsp">
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<sql:transaction>
    <sql:update var="cambiados">
        UPDATE proyectos SET fase_id = (SELECT id FROM fases WHERE orden = 3)
        WHERE id = ? AND fase_id = (SELECT id FROM fases WHERE orden = 2)
        <sql:param value="${p.id}" />
    </sql:update>
    <c:if test="${cambiados == 1}">
        <sql:update>
            INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion)
            VALUES (?, ?, 'Fase', ?)
            <sql:param value="${p.id}" />
            <sql:param value="${idEstudiante}" />
            <sql:param value="El estudiante envió la versión ${p.version} del FDC-124 al director. El proyecto pasó a la fase 3 (Propuesta II)." />
        </sql:update>
    </c:if>
</sql:transaction>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="${cambiados == 1 ? 'ok' : 'error'}" value="${cambiados == 1 ? 'propuesta-enviada' : 'fase-no-permite-propuesta'}" />
</c:redirect>
