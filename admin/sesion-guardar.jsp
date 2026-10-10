<%-- Agrega una sesión del comité al calendario de un periodo (RF3, RF16), por POST.
     Fecha obligatoria (aaaa-mm-dd); hora (hh:mm) y lugar opcionales. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.periodo}">
    <c:redirect url="/admin/periodos.jsp" />
</c:if>

<%-- Fecha y hora reales (MariaDB de XAMPP no está en modo estricto) --%>
<c:set var="valida" value="${not empty param.fecha}" />
<c:if test="${valida}">
    <c:catch var="errorFecha"><fmt:parseDate var="fechaLeida" value="${param.fecha}" pattern="yyyy-MM-dd" parseLocale="en_US" /></c:catch>
    <c:set var="fechaDeNuevo"><fmt:formatDate value="${fechaLeida}" pattern="yyyy-MM-dd" /></c:set>
    <c:set var="valida" value="${empty errorFecha and fechaDeNuevo == param.fecha}" />
</c:if>
<c:if test="${valida and not empty param.hora}">
    <c:catch var="errorHora"><fmt:parseDate var="horaLeida" value="${param.hora}" pattern="HH:mm" parseLocale="en_US" /></c:catch>
    <c:set var="horaDeNuevo"><fmt:formatDate value="${horaLeida}" pattern="HH:mm" /></c:set>
    <c:set var="valida" value="${empty errorHora and horaDeNuevo == param.hora}" />
</c:if>
<c:if test="${not valida}">
    <c:redirect url="/admin/sesiones.jsp">
        <c:param name="periodo" value="${param.periodo}" />
        <c:param name="error" value="sesion-invalida" />
    </c:redirect>
</c:if>

<c:catch var="errorGuardar">
    <sql:update>
        INSERT INTO sesiones_comite (periodo_id, fecha, hora, lugar) VALUES (?, ?, NULLIF(?, ''), NULLIF(?, ''))
        <sql:param value="${param.periodo}" />
        <sql:param value="${param.fecha}" />
        <sql:param value="${param.hora}" />
        <sql:param value="${fn:trim(param.lugar)}" />
    </sql:update>
</c:catch>

<c:redirect url="/admin/sesiones.jsp">
    <c:param name="periodo" value="${param.periodo}" />
    <c:param name="${empty errorGuardar ? 'ok' : 'error'}"
             value="${empty errorGuardar ? 'sesion-creada' : (fn:contains(errorGuardar.message, 'uq_sesiones_comite_fecha') ? 'sesion-duplicada' : 'general')}" />
</c:redirect>
