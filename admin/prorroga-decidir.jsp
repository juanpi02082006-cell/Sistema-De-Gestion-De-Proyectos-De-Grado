<%-- El comité (el administrador) decide una solicitud de prórroga, por POST (RF38, RF34;
     reglamento, art. 26: el comité gestiona las prórrogas). Con observación obligatoria.
       aprobar   la prórroga toma el número siguiente (1, 2 o 3) y la fecha límite del
                 proyecto pasa a la vigente más 180 días.
       rechazar  queda registrada sin número; si se vence el plazo sin otra prórroga, la
                 modalidad se cancela (cierres.jspf). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/admin/proyectos.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT x.id, x.estado, x.proyecto_id, p.titulo, p.estado AS estado_proyecto, p.fecha_limite,
           p.fecha_limite + INTERVAL 180 DAY AS nueva_fecha,
           (SELECT COUNT(*) FROM prorrogas y WHERE y.proyecto_id = x.proyecto_id AND y.estado = 'Aprobada') AS aprobadas
    FROM prorrogas x JOIN proyectos p ON p.id = x.proyecto_id
    WHERE x.id = ?
    <sql:param value="${empty param.id ? 0 : param.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/admin/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="x" value="${consulta.rows[0]}" />
<c:set var="observacion" value="${fn:trim(param.observacion)}" />
<c:set var="aprobar" value="${param.decision == 'aprobar'}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${x.estado_proyecto == 'Finalizado' or x.estado_proyecto == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${x.estado != 'Pendiente'}"><c:set var="motivo" value="prorroga-ya-decidida" /></c:when>
    <c:when test="${param.decision != 'aprobar' and param.decision != 'rechazar'}"><c:set var="motivo" value="general" /></c:when>
    <c:when test="${empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
    <c:when test="${aprobar and x.aprobadas >= 3}"><c:set var="motivo" value="prorrogas-agotadas" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/admin/proyecto.jsp">
        <c:param name="id" value="${x.proyecto_id}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<fmt:formatDate var="nuevaTexto" value="${x.nueva_fecha}" pattern="dd/MM/yyyy" />
<c:set var="numero" value="${x.aprobadas + 1}" />
<sql:transaction>
    <sql:update>
        UPDATE prorrogas SET estado = ?, numero = ?, nueva_fecha_limite = ?, observacion = ?, decidida_por = ?, decidida_en = NOW()
        WHERE id = ? AND estado = 'Pendiente'
        <sql:param value="${aprobar ? 'Aprobada' : 'Rechazada'}" />
        <sql:param value="${aprobar ? numero : null}" />
        <sql:dateParam value="${x.nueva_fecha}" type="date" />
        <sql:param value="${observacion}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${x.id}" />
    </sql:update>
    <c:if test="${aprobar}">
        <sql:update>
            UPDATE proyectos SET fecha_limite = ? WHERE id = ?
            <sql:dateParam value="${x.nueva_fecha}" type="date" />
            <sql:param value="${x.proyecto_id}" />
        </sql:update>
    </c:if>
    <c:set var="textoDecision">${aprobar ? 'El comité aprobó la prórroga ' : 'El comité rechazó la solicitud de prórroga'}${aprobar ? numero : ''}${aprobar ? ' de 3: la nueva fecha límite del informe final es el ' : '.'}${aprobar ? nuevaTexto : ''}${aprobar ? '.' : ''}</c:set>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Decisión', ?)
        <sql:param value="${x.proyecto_id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${textoDecision}" />
    </sql:update>
    <c:set var="avisoProyecto" value="${x.proyecto_id}" />
    <c:set var="avisoMensaje">${textoDecision} Observación: ${observacion}</c:set>
    <c:set var="avisoPara" value="estudiantes,director,codirectores" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
</sql:transaction>

<c:redirect url="/admin/proyecto.jsp">
    <c:param name="id" value="${x.proyecto_id}" />
    <c:param name="ok" value="${aprobar ? 'prorroga-aprobada' : 'prorroga-rechazada'}" />
</c:redirect>
