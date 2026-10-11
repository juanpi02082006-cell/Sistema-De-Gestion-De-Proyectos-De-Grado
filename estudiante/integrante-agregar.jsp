<%-- Un estudiante del proyecto agrega a un compañero con su correo, por POST (RF36,
     decisión del equipo del 2026-10-10: queda en el proyecto de una vez). Reglas:
       - el proyecto está en la fase 1 o 2 (al enviar la propuesta, el grupo se cierra);
       - el compañero es un estudiante activo, del mismo nivel que el proyecto (RF25),
         habilitado (RF33) y sin otro proyecto vigente (RF35);
       - no se pasa del máximo de la modalidad, o de 4 si el comité marcó el proyecto
         como interdisciplinario (RF13, RF36).
     El compañero sube después su propio recibo de pago (RF32). --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.estado, p.titulo, p.nivel_id, f.orden AS fase,
           CASE WHEN p.interdisciplinario = 1 THEN 4 ELSE m.max_integrantes END AS maximo,
           (SELECT COUNT(*) FROM proyecto_estudiantes x WHERE x.proyecto_id = p.id AND x.vigente = 1) AS integrantes
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    JOIN modalidades m ON m.id = p.modalidad_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />

<%-- El compañero: estudiante (rol 5) activo con ese correo --%>
<c:set var="correo" value="${fn:toLowerCase(fn:trim(param.correo))}" />
<sql:query var="companero">
    SELECT u.id, u.nombre, u.nivel_id,
           (SELECT COUNT(*) FROM proyecto_estudiantes x WHERE x.estudiante_id = u.id AND x.vigente = 1) AS con_proyecto
    FROM usuarios u JOIN usuario_roles ur ON ur.usuario_id = u.id AND ur.rol_id = 5
    WHERE LOWER(u.correo) = ? AND u.activo = 1
    <sql:param value="${correo}" />
</sql:query>
<c:if test="${companero.rowCount > 0}">
    <c:set var="c" value="${companero.rows[0]}" />
    <%-- Habilitación del compañero (deja "habilitado") --%>
    <c:set var="idEstudiante" value="${c.id}" />
    <%@ include file="/WEB-INF/jspf/habilitacion.jspf" %>
    <c:set var="idCompanero">${c.id}</c:set>
    <c:set var="idNivelCompanero">${c.nivel_id}</c:set>
    <c:set var="idNivelProyecto">${p.nivel_id}</c:set>
</c:if>

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.fase != 1 and p.fase != 2}"><c:set var="motivo" value="integrantes-cerrados" /></c:when>
    <c:when test="${empty correo or companero.rowCount == 0}"><c:set var="motivo" value="integrante-no-existe" /></c:when>
    <c:when test="${c.con_proyecto > 0}"><c:set var="motivo" value="integrante-con-proyecto" /></c:when>
    <c:when test="${idNivelCompanero != idNivelProyecto}"><c:set var="motivo" value="integrante-otro-nivel" /></c:when>
    <c:when test="${not habilitado}"><c:set var="motivo" value="integrante-no-habilitado" /></c:when>
    <c:when test="${p.integrantes >= p.maximo}"><c:set var="motivo" value="integrantes-completos" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/estudiante/proyecto.jsp">
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<%-- Si ya había estado en este proyecto (lo quitaron antes), vuelve a quedar vigente.
     La clave única (estudiante_id, vigente) impide que quede en dos proyectos. --%>
<c:catch var="errorGuardar">
    <sql:transaction>
        <sql:update var="reactivado">
            UPDATE proyecto_estudiantes SET estado = 'Activo', vigente = 1 WHERE proyecto_id = ? AND estudiante_id = ?
            <sql:param value="${p.id}" />
            <sql:param value="${idCompanero}" />
        </sql:update>
        <c:if test="${reactivado == 0}">
            <sql:update>
                INSERT INTO proyecto_estudiantes (proyecto_id, estudiante_id, estado, vigente) VALUES (?, ?, 'Activo', 1)
                <sql:param value="${p.id}" />
                <sql:param value="${idCompanero}" />
            </sql:update>
        </c:if>
        <sql:update>
            INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Estado', ?)
            <sql:param value="${p.id}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="${sessionScope.usuario.nombre} agregó a ${c.nombre} al proyecto." />
        </sql:update>
        <c:set var="avisoProyecto" value="${p.id}" />
        <c:set var="avisoMensaje">${sessionScope.usuario.nombre} te agregó al proyecto «${p.titulo}». Recuerda subir tu recibo de pago.</c:set>
        <c:set var="avisoPara" value="usuario" />
        <c:set var="avisoUsuario" value="${idCompanero}" />
        <c:set var="avisoEnlace" value="/estudiante/proyecto.jsp" />
        <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
    </sql:transaction>
</c:catch>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="${empty errorGuardar ? 'ok' : 'error'}" value="${empty errorGuardar ? 'integrante-agregado' : 'integrante-con-proyecto'}" />
</c:redirect>
