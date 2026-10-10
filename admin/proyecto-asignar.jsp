<%-- El comité (el administrador) asigna el director y el evaluador de un proyecto
     (RF11), por POST. El director es obligatorio y debe tener el rol Director (3); el
     evaluador es opcional y debe tener el rol Evaluador (4). Un docente nunca evalúa el
     proyecto que dirige (también lo impide la base). Si el pago ya está aprobado (o no
     aplica), el proyecto pasa a la fase 2 (avanzar-fase-2.jspf). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/admin/proyectos.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT id, estado FROM proyectos WHERE id = ?
    <sql:param value="${param.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/admin/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="idProyecto" value="${consulta.rows[0].id}" />

<%-- Docente activo con el rol pedido (si el id no es un número, no encuentra a nadie) --%>
<sql:query var="director">
    SELECT u.nombre FROM usuarios u JOIN usuario_roles ur ON ur.usuario_id = u.id
    WHERE u.id = ? AND ur.rol_id = 3 AND u.activo = 1
    <sql:param value="${empty param.director ? 0 : param.director}" />
</sql:query>
<sql:query var="evaluador">
    SELECT u.nombre FROM usuarios u JOIN usuario_roles ur ON ur.usuario_id = u.id
    WHERE u.id = ? AND ur.rol_id = 4 AND u.activo = 1
    <sql:param value="${empty param.evaluador ? 0 : param.evaluador}" />
</sql:query>

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${consulta.rows[0].estado == 'Finalizado' or consulta.rows[0].estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${director.rowCount == 0}"><c:set var="motivo" value="director-invalido" /></c:when>
    <c:when test="${not empty param.evaluador and evaluador.rowCount == 0}"><c:set var="motivo" value="evaluador-invalido" /></c:when>
    <c:when test="${not empty param.evaluador and param.evaluador == param.director}"><c:set var="motivo" value="director-evaluador" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/admin/proyecto.jsp">
        <c:param name="id" value="${idProyecto}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<%-- En el historial va el nombre del director, pero no el del evaluador: el estudiante
     no debe saber quién lo evalúa (RF27). --%>
<c:catch var="errorGuardar">
    <sql:transaction>
        <sql:update>
            UPDATE proyectos SET director_id = ?, evaluador_id = NULLIF(?, '') WHERE id = ?
            <sql:param value="${param.director}" />
            <sql:param value="${empty param.evaluador ? '' : param.evaluador}" />
            <sql:param value="${idProyecto}" />
        </sql:update>
        <sql:update>
            INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion)
            VALUES (?, ?, 'Decisión', ?)
            <sql:param value="${idProyecto}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="${'El comité asignó como director a '.concat(director.rows[0].nombre).concat(empty param.evaluador ? '.' : ' y asignó el evaluador.')}" />
        </sql:update>
    </sql:transaction>
</c:catch>
<c:if test="${not empty errorGuardar}">
    <c:redirect url="/admin/proyecto.jsp">
        <c:param name="id" value="${idProyecto}" />
        <c:param name="error" value="general" />
    </c:redirect>
</c:if>

<%@ include file="/WEB-INF/jspf/avanzar-fase-2.jspf" %>

<c:redirect url="/admin/proyecto.jsp">
    <c:param name="id" value="${idProyecto}" />
    <c:param name="ok" value="${avanzoFase2 ? 'asignacion-fase-2' : 'asignacion-guardada'}" />
</c:redirect>
