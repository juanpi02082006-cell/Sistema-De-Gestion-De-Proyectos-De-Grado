<%-- El estudiante se sale de su proyecto, por POST (RF36; decisión del equipo del
     2026-10-19: nadie quita a otro, cada uno se sale por su cuenta). Solo en la fase 1 o 2
     (al enviar la propuesta, el grupo se cierra) y nunca el único integrante, para que el
     proyecto no quede sin estudiantes. Queda "Excluido" y sin vigencia (no se borra: queda
     el historial), así que puede empezar otro proyecto (RF35). El proyecto sigue con los
     demás, que reciben el aviso; si el que se fue era el único que faltaba por pagar y ya
     hay director, el proyecto pasa a la fase 2. --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.estado, p.titulo, p.modalidad_id, f.orden AS fase,
           (SELECT COUNT(*) FROM proyecto_estudiantes x WHERE x.proyecto_id = p.id AND x.vigente = 1) AS integrantes
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${consulta.rowCount == 0}"><c:set var="motivo" value="no-encontrado" /></c:when>
    <c:when test="${consulta.rows[0].estado == 'Finalizado' or consulta.rows[0].estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${(consulta.rows[0].fase != 1 and consulta.rows[0].fase != 2) or (consulta.rows[0].modalidad_id == 5 and consulta.rows[0].estado != 'Pendiente')}"><c:set var="motivo" value="integrantes-cerrados" /></c:when>
    <c:when test="${consulta.rows[0].integrantes < 2}"><c:set var="motivo" value="unico-integrante" /></c:when>
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
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:update>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Estado', ?)
        <sql:param value="${p.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${sessionScope.usuario.nombre} se salió del proyecto." />
    </sql:update>
    <%-- Ya no está vigente: el aviso les llega solo a los que se quedan --%>
    <c:set var="avisoProyecto" value="${p.id}" />
    <c:set var="avisoMensaje">${sessionScope.usuario.nombre} se salió del proyecto «${p.titulo}». El proyecto sigue con ustedes.</c:set>
    <c:set var="avisoPara" value="estudiantes" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
</sql:transaction>

<%-- Si era el único que faltaba por pagar y ya hay director, el proyecto pasa a la fase 2 --%>
<c:set var="idProyecto" value="${p.id}" />
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<%@ include file="/WEB-INF/jspf/avanzar-fase-2.jspf" %>

<c:redirect url="/ideas/banco.jsp">
    <c:param name="ok" value="saliste-del-proyecto" />
</c:redirect>
