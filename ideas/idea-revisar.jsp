<%-- El comité (el administrador) aprueba o rechaza una idea o propuesta pendiente
     (RF10), por POST. La observación es obligatoria (RF34). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/ideas/banco.jsp" />
</c:if>

<c:set var="observacion" value="${fn:trim(param.observacion)}" />
<c:if test="${empty observacion}">
    <c:redirect url="/ideas/banco.jsp">
        <c:param name="error" value="observacion-requerida" />
    </c:redirect>
</c:if>
<c:if test="${param.decision != 'aprobar' and param.decision != 'rechazar'}">
    <c:redirect url="/ideas/banco.jsp" />
</c:if>
<c:set var="aprobar" value="${param.decision == 'aprobar'}" />
<sql:query var="consultaIdea">
    SELECT titulo, propuesta_por FROM ideas WHERE id = ?
    <sql:param value="${param.id}" />
</sql:query>

<sql:update var="cambiados">
    UPDATE ideas SET estado = ?, revisada_por = ?, observacion_revision = ?
    WHERE id = ? AND estado = 'Pendiente'
    <sql:param value="${aprobar ? 'Aprobada' : 'Rechazada'}" />
    <sql:param value="${sessionScope.usuario.id}" />
    <sql:param value="${observacion}" />
    <sql:param value="${param.id}" />
</sql:update>

<%-- Aviso a quien propuso la idea (RF5) --%>
<c:if test="${cambiados == 1}">
    <c:set var="avisoProyecto" value="" />
    <c:set var="avisoMensaje">El comité ${aprobar ? 'aprobó' : 'rechazó'} la idea «${consultaIdea.rows[0].titulo}». Observación: ${observacion}</c:set>
    <c:set var="avisoPara" value="usuario" />
    <c:set var="avisoUsuario" value="${consultaIdea.rows[0].propuesta_por}" />
    <c:set var="avisoEnlace" value="/ideas/banco.jsp" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
</c:if>

<c:redirect url="/ideas/banco.jsp">
    <c:param name="${cambiados == 1 ? 'ok' : 'error'}" value="${cambiados == 1 ? (aprobar ? 'idea-aprobada' : 'idea-rechazada') : 'no-encontrado'}" />
</c:redirect>
