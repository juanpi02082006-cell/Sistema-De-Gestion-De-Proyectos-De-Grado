<%-- Guarda un periodo nuevo o editado (RF3). Un periodo nuevo queda "Planeado"
     hasta que se active. Si algo falla, vuelve al formulario con el error. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/admin/periodos.jsp" />
</c:if>

<c:set var="editando" value="${not empty param.id}" />
<c:set var="nombre" value="${fn:trim(param.nombre)}" />

<%-- Cada fecha es opcional; si viene, debe ser una fecha real en formato aaaa-mm-dd
     (MariaDB de XAMPP no está en modo estricto y guardaría 0000-00-00). --%>
<c:set var="campos" value="fecha_inicio_semestre,fecha_cierre_banco,fecha_limite_pago,fecha_limite_propuestas,fecha_inicio_informe_final,fecha_fin_informe_final" />
<c:set var="fechaInvalida" value="false" />
<c:forTokens var="campo" items="${campos}" delims=",">
    <c:if test="${not empty param[campo]}">
        <c:remove var="fechaLeida" />
        <c:catch var="errorFecha">
            <fmt:parseDate var="fechaLeida" value="${param[campo]}" pattern="yyyy-MM-dd" parseLocale="en_US" />
        </c:catch>
        <c:set var="fechaDeNuevo"><fmt:formatDate value="${fechaLeida}" pattern="yyyy-MM-dd" /></c:set>
        <c:if test="${not empty errorFecha or fechaDeNuevo != param[campo]}">
            <c:set var="fechaInvalida" value="true" />
        </c:if>
    </c:if>
</c:forTokens>

<c:choose>
    <c:when test="${empty nombre}">
        <jsp:forward page="periodo-form.jsp"><jsp:param name="error" value="faltan-datos" /></jsp:forward>
    </c:when>
    <c:when test="${fechaInvalida}">
        <jsp:forward page="periodo-form.jsp"><jsp:param name="error" value="fecha-invalida" /></jsp:forward>
    </c:when>
    <%-- Las fechas aaaa-mm-dd se pueden comparar como texto --%>
    <c:when test="${not empty param.fecha_inicio_informe_final and not empty param.fecha_fin_informe_final
                    and param.fecha_inicio_informe_final > param.fecha_fin_informe_final}">
        <jsp:forward page="periodo-form.jsp"><jsp:param name="error" value="fechas-informe" /></jsp:forward>
    </c:when>
</c:choose>

<c:catch var="errorGuardar">
    <c:choose>
        <c:when test="${not editando}">
            <sql:update>
                INSERT INTO periodos (nombre, fecha_inicio_semestre, fecha_cierre_banco, fecha_limite_pago,
                                      fecha_limite_propuestas, fecha_inicio_informe_final, fecha_fin_informe_final)
                VALUES (?, NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''))
                <sql:param value="${nombre}" />
                <sql:param value="${param.fecha_inicio_semestre}" />
                <sql:param value="${param.fecha_cierre_banco}" />
                <sql:param value="${param.fecha_limite_pago}" />
                <sql:param value="${param.fecha_limite_propuestas}" />
                <sql:param value="${param.fecha_inicio_informe_final}" />
                <sql:param value="${param.fecha_fin_informe_final}" />
            </sql:update>
        </c:when>
        <c:otherwise>
            <sql:update var="cambiados">
                UPDATE periodos
                SET nombre = ?, fecha_inicio_semestre = NULLIF(?, ''), fecha_cierre_banco = NULLIF(?, ''),
                    fecha_limite_pago = NULLIF(?, ''), fecha_limite_propuestas = NULLIF(?, ''),
                    fecha_inicio_informe_final = NULLIF(?, ''), fecha_fin_informe_final = NULLIF(?, '')
                WHERE id = ?
                <sql:param value="${nombre}" />
                <sql:param value="${param.fecha_inicio_semestre}" />
                <sql:param value="${param.fecha_cierre_banco}" />
                <sql:param value="${param.fecha_limite_pago}" />
                <sql:param value="${param.fecha_limite_propuestas}" />
                <sql:param value="${param.fecha_inicio_informe_final}" />
                <sql:param value="${param.fecha_fin_informe_final}" />
                <sql:param value="${param.id}" />
            </sql:update>
        </c:otherwise>
    </c:choose>
</c:catch>

<c:if test="${not empty errorGuardar}">
    <jsp:forward page="periodo-form.jsp">
        <jsp:param name="error" value="${fn:contains(errorGuardar.message, 'uq_periodos_nombre') ? 'nombre-duplicado' : 'general'}" />
    </jsp:forward>
</c:if>

<c:redirect url="/admin/periodos.jsp">
    <c:param name="ok" value="${editando ? 'periodo-actualizado' : 'periodo-creado'}" />
</c:redirect>
