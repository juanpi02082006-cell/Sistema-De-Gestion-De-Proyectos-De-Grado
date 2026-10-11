<%-- El estudiante exonerado por Saber TyT renuncia a la exoneración y sigue con el
     proyecto, por POST (RNF14, A-23). No tiene vuelta atrás: después no puede pedirla
     otra vez. No se puede si el proyecto ya terminó. --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.estado, pe.exonerado, pe.renuncia_exoneracion
    FROM proyecto_estudiantes pe JOIN proyectos p ON p.id = pe.proyecto_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:choose>
    <c:when test="${consulta.rowCount == 0}"><c:set var="motivo" value="no-encontrado" /></c:when>
    <c:when test="${consulta.rows[0].estado == 'Finalizado' or consulta.rows[0].estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${consulta.rows[0].exonerado != true or consulta.rows[0].renuncia_exoneracion == true}"><c:set var="motivo" value="sin-exoneracion" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/estudiante/proyecto.jsp">
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />

<sql:transaction>
    <sql:update>
        UPDATE proyecto_estudiantes SET renuncia_exoneracion = 1
        WHERE proyecto_id = ? AND estudiante_id = ? AND exonerado = 1
        <sql:param value="${p.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:update>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Estado', ?)
        <sql:param value="${p.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${sessionScope.usuario.nombre} renunció a la exoneración por Saber TyT y sigue con el proyecto." />
    </sql:update>
    <c:set var="avisoProyecto" value="${p.id}" />
    <c:set var="avisoMensaje">${sessionScope.usuario.nombre} renunció a la exoneración por Saber TyT y sigue con el proyecto.</c:set>
    <c:set var="avisoPara" value="estudiantes,director,comite" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
</sql:transaction>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="ok" value="exoneracion-renunciada" />
</c:redirect>
