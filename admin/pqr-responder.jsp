<%-- El comité responde una PQR (RNF1), por POST: la respuesta es obligatoria y le llega
     un aviso a quien la escribió (RF5). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/admin/pqrs.jsp" />
</c:if>
<c:set var="respuesta" value="${fn:trim(param.respuesta)}" />
<c:if test="${empty respuesta}">
    <c:redirect url="/admin/pqrs.jsp">
        <c:param name="error" value="respuesta-requerida" />
    </c:redirect>
</c:if>
<sql:query var="consulta">
    SELECT id, usuario_id, proyecto_id, tipo FROM pqrs WHERE id = ? AND estado = 'Pendiente'
    <sql:param value="${param.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/admin/pqrs.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="q" value="${consulta.rows[0]}" />

<sql:transaction>
    <sql:update>
        UPDATE pqrs SET estado = 'Respondida', respuesta = ?, respondida_por = ?, respondida_en = NOW()
        WHERE id = ? AND estado = 'Pendiente'
        <sql:param value="${fn:substring(respuesta, 0, 2000)}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${q.id}" />
    </sql:update>
    <c:set var="avisoProyecto">${q.proyecto_id}</c:set>
    <c:set var="avisoMensaje">El comité respondió tu PQR (${q.tipo}): ${respuesta}</c:set>
    <c:set var="avisoPara" value="usuario" />
    <c:set var="avisoUsuario" value="${q.usuario_id}" />
    <c:set var="avisoEnlace" value="/panel/pqr.jsp" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
</sql:transaction>

<c:redirect url="/admin/pqrs.jsp">
    <c:param name="ok" value="pqr-respondida" />
</c:redirect>
