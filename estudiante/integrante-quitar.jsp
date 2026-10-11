<%-- Un estudiante del proyecto quita a un compañero, por POST (RF36). Solo en la fase 1
     o 2 (al enviar la propuesta, el grupo se cierra) y nunca a sí mismo. El compañero
     queda "Excluido" y sin vigencia (no se borra: queda el historial), así que puede
     empezar otro proyecto (RF35). --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.estado, p.titulo, f.orden AS fase, u.nombre AS companero
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    LEFT JOIN fases f ON f.id = p.fase_id
    JOIN proyecto_estudiantes otro ON otro.proyecto_id = p.id AND otro.vigente = 1 AND otro.estudiante_id = ?
    JOIN usuarios u ON u.id = otro.estudiante_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1 AND otro.estudiante_id <> pe.estudiante_id
    <sql:param value="${empty param.estudiante ? 0 : param.estudiante}" />
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${consulta.rowCount == 0}"><c:set var="motivo" value="no-encontrado" /></c:when>
    <c:when test="${consulta.rows[0].estado == 'Finalizado' or consulta.rows[0].estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${consulta.rows[0].fase != 1 and consulta.rows[0].fase != 2}"><c:set var="motivo" value="integrantes-cerrados" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/estudiante/proyecto.jsp">
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />

<sql:transaction>
    <sql:update>
        UPDATE proyecto_estudiantes SET estado = 'Excluido', vigente = NULL
        WHERE proyecto_id = ? AND estudiante_id = ? AND vigente = 1
        <sql:param value="${p.id}" />
        <sql:param value="${param.estudiante}" />
    </sql:update>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Estado', ?)
        <sql:param value="${p.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${sessionScope.usuario.nombre} quitó a ${p.companero} del proyecto." />
    </sql:update>
    <c:set var="avisoProyecto" value="${p.id}" />
    <c:set var="avisoMensaje">${sessionScope.usuario.nombre} te quitó del proyecto «${p.titulo}». Ya puedes tomar otra idea del banco.</c:set>
    <c:set var="avisoPara" value="usuario" />
    <c:set var="avisoUsuario" value="${param.estudiante}" />
    <c:set var="avisoEnlace" value="/ideas/banco.jsp" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
</sql:transaction>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="ok" value="integrante-quitado" />
</c:redirect>
