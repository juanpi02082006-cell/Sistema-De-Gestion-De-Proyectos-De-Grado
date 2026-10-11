<%-- El estudiante envía la propuesta (la última versión del FDC-124) a su director, por
     POST: el proyecto pasa de la fase 2 (Propuesta I) a la 3 (Propuesta II), donde el
     director la revisa (RF18, RF37). Reglas: proyecto vigente en la fase 2, con director
     y con al menos una versión subida; si la última versión ya se revisó (el director
     la devolvió o el comité la aplazó), hay que subir una nueva antes de volver a
     enviarla (RF43). Antes de enviarla se revisa
     el grupo (RF36): que no pase del máximo de integrantes, que todos tengan el pago al
     día (RF32) y que todos sigan habilitados (RF33). Al enviarla, el grupo se cierra. --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.estado, p.titulo, p.modalidad_id, p.director_id, f.orden AS fase, ${sqlEstadoPago} AS estado_pago,
           CASE WHEN p.interdisciplinario = 1 THEN 4 ELSE m.max_integrantes END AS maximo,
           (SELECT COUNT(*) FROM proyecto_estudiantes x WHERE x.proyecto_id = p.id AND x.vigente = 1) AS integrantes,
           (SELECT MAX(e.version) FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124') AS version,
           (SELECT COUNT(*) FROM entregas e JOIN revisiones r ON r.entrega_id = e.id
            WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124' AND r.estado = 'Enviada' AND r.rol <> 'Codirector'
              AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = 'FDC-124')) AS devuelta
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    JOIN modalidades m ON m.id = p.modalidad_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />

<%-- ¿Todos los integrantes siguen habilitados? (habilitacion.jspf deja "habilitado") --%>
<sql:query var="grupo">
    SELECT estudiante_id FROM proyecto_estudiantes WHERE proyecto_id = ? AND vigente = 1
    <sql:param value="${p.id}" />
</sql:query>
<c:set var="todosHabilitados" value="true" />
<c:forEach var="g" items="${grupo.rows}">
    <c:set var="idEstudiante" value="${g.estudiante_id}" />
    <%@ include file="/WEB-INF/jspf/habilitacion.jspf" %>
    <c:if test="${not habilitado}"><c:set var="todosHabilitados" value="false" /></c:if>
</c:forEach>

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.modalidad_id == 5}"><c:set var="motivo" value="seminario-sin-124" /></c:when>
    <c:when test="${p.fase != 2}"><c:set var="motivo" value="fase-no-permite-propuesta" /></c:when>
    <c:when test="${empty p.director_id}"><c:set var="motivo" value="sin-director" /></c:when>
    <c:when test="${empty p.version}"><c:set var="motivo" value="propuesta-requerida" /></c:when>
    <c:when test="${p.devuelta > 0}"><c:set var="motivo" value="propuesta-devuelta" /></c:when>
    <c:when test="${p.integrantes > p.maximo}"><c:set var="motivo" value="demasiados-integrantes" /></c:when>
    <c:when test="${p.estado_pago != 'Aprobado' and p.estado_pago != 'No aplica'}"><c:set var="motivo" value="pagos-pendientes" /></c:when>
    <c:when test="${not todosHabilitados}"><c:set var="motivo" value="integrante-no-habilitado" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/estudiante/proyecto.jsp">
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<%-- El director tiene 5 días hábiles para revisarla (RF21; confirmado por el equipo) --%>
<c:set var="diasHabiles" value="5" />
<%@ include file="/WEB-INF/jspf/plazo-habil.jspf" %>

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
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="El estudiante envió la versión ${p.version} del FDC-124 al director. El proyecto pasó a la fase 3 (Propuesta II)." />
        </sql:update>
        <sql:update>
            UPDATE entregas SET fecha_limite_revision = ? WHERE proyecto_id = ? AND tipo = 'FDC-124' AND version = ?
            <sql:dateParam value="${fechaPlazo}" type="date" />
            <sql:param value="${p.id}" />
            <sql:param value="${p.version}" />
        </sql:update>
        <c:set var="avisoProyecto" value="${p.id}" />
        <c:set var="avisoMensaje">Te enviaron la versión ${p.version} de la propuesta de «${p.titulo}» para revisarla. Tienes hasta el <fmt:formatDate value="${fechaPlazo}" pattern="dd/MM/yyyy" />.</c:set>
        <c:set var="avisoPara" value="director,codirectores" />
        <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
        <c:set var="avisoMensaje">Se envió la versión ${p.version} de la propuesta al director. Está en revisión.</c:set>
        <c:set var="avisoPara" value="estudiantes" />
        <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
    </c:if>
</sql:transaction>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="${cambiados == 1 ? 'ok' : 'error'}" value="${cambiados == 1 ? 'propuesta-enviada' : 'fase-no-permite-propuesta'}" />
</c:redirect>
