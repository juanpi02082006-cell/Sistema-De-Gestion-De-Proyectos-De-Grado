<%-- El comité (el administrador) aprueba o devuelve el recibo de pago de la fase 1
     (RF32), por POST. Solo se revisa el último recibo del proyecto, una vez, y con
     observación obligatoria (RF34). Si queda aprobado y el proyecto ya tiene director,
     pasa a la fase 2 (avanzar-fase-2.jspf). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/admin/proyectos.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT e.id, e.proyecto_id, f.orden AS fase,
           (e.id = (SELECT MAX(e2.id) FROM entregas e2 WHERE e2.proyecto_id = e.proyecto_id AND e2.tipo = 'Recibo de pago')) AS ultimo,
           (SELECT COUNT(*) FROM revisiones r WHERE r.entrega_id = e.id) AS revisiones
    FROM entregas e
    JOIN proyectos p ON p.id = e.proyecto_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE e.id = ? AND e.tipo = 'Recibo de pago'
    <sql:param value="${param.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/admin/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="recibo" value="${consulta.rows[0]}" />
<c:set var="idProyecto" value="${recibo.proyecto_id}" />

<c:set var="observacion" value="${fn:trim(param.observacion)}" />
<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${recibo.fase != 1 or recibo.ultimo != 1 or recibo.revisiones > 0}"><c:set var="motivo" value="pago-ya-revisado" /></c:when>
    <c:when test="${param.decision != 'aprobar' and param.decision != 'devolver'}"><c:set var="motivo" value="general" /></c:when>
    <c:when test="${empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/admin/proyecto.jsp">
        <c:param name="id" value="${idProyecto}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>
<c:set var="aprobar" value="${param.decision == 'aprobar'}" />

<sql:transaction>
    <sql:update>
        INSERT INTO revisiones (entrega_id, revisor_id, rol, estado, decision, observacion)
        VALUES (?, ?, 'Comité', 'Enviada', ?, ?)
        <sql:param value="${recibo.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${aprobar ? 'Aprobado' : 'Devuelto'}" />
        <sql:param value="${observacion}" />
    </sql:update>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion)
        VALUES (?, ?, 'Decisión', ?)
        <sql:param value="${idProyecto}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${aprobar ? 'El comité aprobó el recibo de pago.' : 'El comité devolvió el recibo de pago.'}" />
    </sql:update>
</sql:transaction>

<c:if test="${aprobar}">
    <%@ include file="/WEB-INF/jspf/avanzar-fase-2.jspf" %>
</c:if>

<c:redirect url="/admin/proyecto.jsp">
    <c:param name="id" value="${idProyecto}" />
    <c:param name="ok" value="${not aprobar ? 'pago-devuelto' : (avanzoFase2 ? 'pago-aprobado-fase-2' : 'pago-aprobado')}" />
</c:redirect>
