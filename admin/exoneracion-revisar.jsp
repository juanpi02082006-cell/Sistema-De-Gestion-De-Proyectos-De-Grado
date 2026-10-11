<%-- El comité (el administrador) verifica una solicitud de exoneración por Saber TyT
     (RNF14), por POST, con observación obligatoria (RF34). Si la aprueba, el estudiante
     queda exonerado del informe final con la nota del estímulo (Acuerdo 01-009) y se
     guarda su puntaje. Los compañeros siguen (A-23). Si con esta quedan exonerados
     todos los integrantes vigentes (sin renuncia), el proyecto se da por terminado
     con concepto "Aprobado" y se exime el informe final (decisión del equipo,
     2026-10-10). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/admin/proyectos.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT x.id, x.proyecto_id, x.estudiante_id, x.puntaje, x.estado AS estado_solicitud, u.nombre AS estudiante,
           p.estado, p.titulo,
           CASE WHEN x.puntaje >= 171 THEN '5.0 y 100 % de beca en los derechos de grado'
                WHEN x.puntaje >= 151 THEN '4.7 y 50 % de beca en los derechos de grado'
                ELSE '4.5' END AS estimulo
    FROM exoneraciones x
    JOIN proyectos p ON p.id = x.proyecto_id
    JOIN usuarios u ON u.id = x.estudiante_id
    WHERE x.id = ?
    <sql:param value="${param.id}" />
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
    <c:when test="${x.estado_solicitud != 'Pendiente'}"><c:set var="motivo" value="exoneracion-ya-decidida" /></c:when>
    <c:when test="${x.estado == 'Finalizado' or x.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${param.decision != 'aprobar' and param.decision != 'rechazar'}"><c:set var="motivo" value="general" /></c:when>
    <c:when test="${empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/admin/proyecto.jsp">
        <c:param name="id" value="${x.proyecto_id}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<sql:transaction>
    <sql:update>
        UPDATE exoneraciones SET estado = ?, observacion = ?, revisada_por = ?, revisada_en = NOW()
        WHERE id = ? AND estado = 'Pendiente'
        <sql:param value="${aprobar ? 'Aprobada' : 'Rechazada'}" />
        <sql:param value="${observacion}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${x.id}" />
    </sql:update>
    <c:if test="${aprobar}">
        <sql:update>
            UPDATE proyecto_estudiantes SET exonerado = 1 WHERE proyecto_id = ? AND estudiante_id = ?
            <sql:param value="${x.proyecto_id}" />
            <sql:param value="${x.estudiante_id}" />
        </sql:update>
        <sql:update>
            UPDATE usuarios SET puntaje_saber_tyt = ? WHERE id = ?
            <sql:param value="${x.puntaje}" />
            <sql:param value="${x.estudiante_id}" />
        </sql:update>
    </c:if>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Decisión', ?)
        <sql:param value="${x.proyecto_id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="El comité ${aprobar ? 'aprobó' : 'rechazó'} la exoneración por Saber TyT de ${x.estudiante} (${x.puntaje} puntos)${aprobar ? ': queda exento del informe final con ' : ''}${aprobar ? x.estimulo : ''}." />
    </sql:update>
    <c:set var="avisoProyecto" value="${x.proyecto_id}" />
    <c:set var="avisoMensaje">El comité ${aprobar ? 'aprobó' : 'rechazó'} tu exoneración por Saber TyT. Observación: ${observacion}</c:set>
    <c:set var="avisoPara" value="usuario" />
    <c:set var="avisoUsuario" value="${x.estudiante_id}" />
    <c:set var="avisoEnlace" value="/estudiante/proyecto.jsp" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>

    <%-- ¿Quedaron exonerados todos los integrantes vigentes? Entonces el proyecto termina
         con concepto Aprobado, sin informe final. --%>
    <c:if test="${aprobar}">
        <sql:query var="grupo">
            SELECT COUNT(*) AS total, SUM(exonerado = 1 AND renuncia_exoneracion = 0) AS exonerados
            FROM proyecto_estudiantes WHERE proyecto_id = ? AND vigente = 1
            <sql:param value="${x.proyecto_id}" />
        </sql:query>
        <c:if test="${grupo.rows[0].total > 0 and grupo.rows[0].total == grupo.rows[0].exonerados}">
            <sql:update>
                UPDATE proyectos SET estado = 'Finalizado' WHERE id = ?
                <sql:param value="${x.proyecto_id}" />
            </sql:update>
            <sql:update>
                INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Estado', ?)
                <sql:param value="${x.proyecto_id}" />
                <sql:param value="${sessionScope.usuario.id}" />
                <sql:param value="Proyecto terminado con concepto Aprobado: todos los integrantes quedaron exonerados por Saber TyT; se exime el informe final." />
            </sql:update>
            <c:set var="avisoMensaje">El proyecto «${x.titulo}» terminó con concepto Aprobado: todos los integrantes quedaron exonerados por Saber TyT y se exime el informe final.</c:set>
            <c:set var="avisoPara" value="estudiantes,director,codirectores,evaluador,comite" />
            <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
            <c:set var="proyectoTerminado" value="true" />
        </c:if>
    </c:if>
</sql:transaction>

<c:redirect url="/admin/proyecto.jsp">
    <c:param name="id" value="${x.proyecto_id}" />
    <c:param name="ok" value="${not aprobar ? 'exoneracion-rechazada' : (proyectoTerminado ? 'exoneracion-proyecto-terminado' : 'exoneracion-aprobada')}" />
</c:redirect>
