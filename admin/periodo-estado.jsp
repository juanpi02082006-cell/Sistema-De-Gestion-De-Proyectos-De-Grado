<%-- Activa o cierra un periodo (RF3), por POST. Solo puede haber un periodo
     activo: para activar otro, primero se cierra el que está activo. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/admin/periodos.jsp" />
</c:if>

<c:choose>
    <c:when test="${param.accion == 'activar'}">
        <sql:query var="otros">
            SELECT COUNT(*) AS total FROM periodos WHERE estado = 'Activo' AND id <> ?
            <sql:param value="${param.id}" />
        </sql:query>
        <c:if test="${otros.rows[0].total > 0}">
            <c:redirect url="/admin/periodos.jsp">
                <c:param name="error" value="otro-periodo-activo" />
            </c:redirect>
        </c:if>
        <sql:update var="cambiados">
            UPDATE periodos SET estado = 'Activo' WHERE id = ?
            <sql:param value="${param.id}" />
        </sql:update>
        <c:set var="aviso" value="periodo-activado" />
    </c:when>
    <c:when test="${param.accion == 'cerrar'}">
        <sql:update var="cambiados">
            UPDATE periodos SET estado = 'Cerrado' WHERE id = ?
            <sql:param value="${param.id}" />
        </sql:update>
        <c:set var="aviso" value="periodo-cerrado" />
    </c:when>
    <c:otherwise>
        <c:redirect url="/admin/periodos.jsp" />
    </c:otherwise>
</c:choose>

<c:choose>
    <c:when test="${cambiados == 0}">
        <c:redirect url="/admin/periodos.jsp">
            <c:param name="error" value="no-encontrado" />
        </c:redirect>
    </c:when>
    <c:otherwise>
        <c:redirect url="/admin/periodos.jsp">
            <c:param name="ok" value="${aviso}" />
        </c:redirect>
    </c:otherwise>
</c:choose>
