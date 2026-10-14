<%-- Guarda una PQR (RNF1), por POST, y avisa al comité (RF5). Si el usuario es
     estudiante con un proyecto vigente, queda ligada a ese proyecto. El administrador
     (el comité) no envía PQR: las responde. --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<c:if test="${sessionScope.rolActivo.id == 1}">
    <c:redirect url="/admin/pqrs.jsp">
        <c:param name="error" value="denegado" />
    </c:redirect>
</c:if>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/panel/pqr.jsp" />
</c:if>
<c:set var="comentario" value="${fn:trim(param.comentario)}" />
<c:set var="tipoValido" value="${param.tipo == 'Petición' or param.tipo == 'Queja' or param.tipo == 'Reclamo'
                                 or param.tipo == 'Cambio de director' or param.tipo == 'Cambio de evaluador'}" />
<c:if test="${not tipoValido or empty comentario}">
    <c:redirect url="/panel/pqr.jsp">
        <c:param name="error" value="pqr-incompleta" />
    </c:redirect>
</c:if>

<sql:query var="vigente">
    SELECT proyecto_id FROM proyecto_estudiantes WHERE estudiante_id = ? AND vigente = 1
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:set var="idProyectoPqr">${vigente.rowCount > 0 ? vigente.rows[0].proyecto_id : ''}</c:set>

<sql:transaction>
    <sql:update>
        INSERT INTO pqrs (usuario_id, proyecto_id, tipo, comentario) VALUES (?, NULLIF(?, ''), ?, ?)
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${idProyectoPqr}" />
        <sql:param value="${param.tipo}" />
        <sql:param value="${fn:substring(comentario, 0, 2000)}" />
    </sql:update>
    <%-- Aviso a cada administrador (comité) --%>
    <sql:update>
        INSERT INTO avisos (usuario_id, proyecto_id, mensaje, enlace)
        SELECT u.id, NULLIF(?, ''), ?, '/admin/pqrs.jsp'
        FROM usuarios u JOIN usuario_roles ur ON ur.usuario_id = u.id AND ur.rol_id = 1
        WHERE u.activo = 1 AND u.id <> ?
        <sql:param value="${idProyectoPqr}" />
        <sql:param value="Nueva PQR (${param.tipo}) de ${sessionScope.usuario.nombre}." />
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:update>
</sql:transaction>

<c:redirect url="/panel/pqr.jsp">
    <c:param name="ok" value="pqr-enviada" />
</c:redirect>
