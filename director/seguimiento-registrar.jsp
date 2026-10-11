<%-- El director registra un seguimiento académico del trabajo, por POST (RF20): al menos
     2 antes de que el estudiante entregue el informe final, para avalarlo, recomendar
     cambios o reorientarlo. Solo el director (no los codirectores), en la fase 4 y con el
     FDC-124 aprobado por el comité, y con observación obligatoria (RF34). --%>
<%@ include file="/WEB-INF/jspf/solo-director.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/director/proyectos.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.titulo, p.estado, p.fecha_aprobacion_124, f.orden AS fase
    FROM proyectos p LEFT JOIN fases f ON f.id = p.fase_id
    WHERE p.id = ? AND p.director_id = ?
    <sql:param value="${empty param.id ? 0 : param.id}" />
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/director/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="observacion" value="${fn:trim(param.observacion)}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.fase != 4 or empty p.fecha_aprobacion_124}"><c:set var="motivo" value="seguimiento-no-aplica" /></c:when>
    <c:when test="${empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/director/proyecto.jsp">
        <c:param name="id" value="${p.id}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<sql:transaction>
    <sql:update>
        INSERT INTO seguimientos (proyecto_id, director_id, fecha, observacion) VALUES (?, ?, CURDATE(), ?)
        <sql:param value="${p.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${observacion}" />
    </sql:update>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Otro', ?)
        <sql:param value="${p.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="El director registró un seguimiento: ${fn:substring(observacion, 0, 180)}" />
    </sql:update>
    <c:set var="avisoProyecto" value="${p.id}" />
    <c:set var="avisoMensaje">Tu director registró un seguimiento de «${p.titulo}»: ${observacion}</c:set>
    <c:set var="avisoPara" value="estudiantes" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
</sql:transaction>

<c:redirect url="/director/proyecto.jsp">
    <c:param name="id" value="${p.id}" />
    <c:param name="ok" value="seguimiento-registrado" />
</c:redirect>
