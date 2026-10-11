<%-- El estudiante pide cambiar la modalidad de su proyecto, por POST (RF12): solo antes
     de que el comité apruebe el FDC-124 (fases 1 a 3), con un motivo, y con una sola
     solicitud pendiente a la vez. La nueva modalidad debe admitir a los integrantes
     actuales (4 si el proyecto es interdisciplinario y la nueva modalidad es de
     investigación o desarrollo tecnológico, RF13). El comité la aprueba o la rechaza
     (admin/modalidad-decidir.jsp). --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.estado, p.titulo, p.modalidad_id, p.interdisciplinario, f.orden AS fase,
           (SELECT COUNT(*) FROM proyecto_estudiantes x WHERE x.proyecto_id = p.id AND x.vigente = 1) AS integrantes,
           (SELECT COUNT(*) FROM cambios_modalidad c WHERE c.proyecto_id = p.id AND c.estado = 'Pendiente') AS pendientes
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />

<sql:query var="nueva">
    SELECT id, nombre, max_integrantes FROM modalidades WHERE id = ?
    <sql:param value="${empty param.modalidad ? 0 : param.modalidad}" />
</sql:query>
<c:set var="motivoTexto" value="${fn:trim(param.motivo)}" />
<c:set var="idModalidadActual">${p.modalidad_id}</c:set>

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.fase < 1 or p.fase > 3}"><c:set var="motivo" value="modalidad-fuera-de-tiempo" /></c:when>
    <c:when test="${p.pendientes > 0}"><c:set var="motivo" value="modalidad-pendiente" /></c:when>
    <c:when test="${nueva.rowCount == 0 or param.modalidad == idModalidadActual}"><c:set var="motivo" value="modalidad-invalida" /></c:when>
    <c:when test="${p.integrantes > ((p.interdisciplinario == true and (nueva.rows[0].id == 1 or nueva.rows[0].id == 2)) ? 4 : nueva.rows[0].max_integrantes)}"><c:set var="motivo" value="modalidad-integrantes" /></c:when>
    <c:when test="${empty motivoTexto}"><c:set var="motivo" value="motivo-requerido" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/estudiante/proyecto.jsp">
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<sql:transaction>
    <sql:update>
        INSERT INTO cambios_modalidad (proyecto_id, modalidad_anterior_id, modalidad_nueva_id, solicitado_por, motivo)
        VALUES (?, ?, ?, ?, ?)
        <sql:param value="${p.id}" />
        <sql:param value="${p.modalidad_id}" />
        <sql:param value="${nueva.rows[0].id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${motivoTexto}" />
    </sql:update>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Modalidad', ?)
        <sql:param value="${p.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="El estudiante pidió cambiar la modalidad a ${nueva.rows[0].nombre}." />
    </sql:update>
    <c:set var="avisoProyecto" value="${p.id}" />
    <c:set var="avisoMensaje">${sessionScope.usuario.nombre} pidió cambiar la modalidad del proyecto «${p.titulo}» a ${nueva.rows[0].nombre}.</c:set>
    <c:set var="avisoPara" value="comite,estudiantes,director" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
</sql:transaction>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="ok" value="modalidad-solicitada" />
</c:redirect>
