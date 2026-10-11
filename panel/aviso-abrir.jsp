<%-- Abre un aviso (?id=): lo marca como leído y lleva a su página. Solo los avisos del
     usuario de la sesión. El enlace guardado es una ruta dentro del sistema. --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<sql:query var="aviso">
    SELECT id, enlace FROM avisos WHERE id = ? AND usuario_id = ?
    <sql:param value="${empty param.id ? 0 : param.id}" />
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${aviso.rowCount == 0}">
    <c:redirect url="/panel/avisos.jsp" />
</c:if>
<sql:update>
    UPDATE avisos SET leido = 1 WHERE id = ?
    <sql:param value="${aviso.rows[0].id}" />
</sql:update>
<%-- Solo rutas internas (empiezan por "/" y no por "//") --%>
<c:set var="destino" value="${aviso.rows[0].enlace}" />
<c:redirect url="${not empty destino and fn:startsWith(destino, '/') and not fn:startsWith(destino, '//') ? destino : '/panel/avisos.jsp'}" />
