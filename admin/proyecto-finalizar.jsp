<%-- Aprobación final del comité (el administrador), por POST (RF39; lista del otro
     equipo, RF-97: "registrar la aprobación final del Trabajo de Grado", que hace el
     administrador). Solo en la fase final y después de la fecha y la hora de la
     sustentación (RF-98: se finaliza con las fases completas). Con observación (RF34) y
     con el número y la fecha del acta (RF14, RF16), que no puede ser futura ni anterior
     a la sustentación. El proyecto queda "Finalizado" y los estudiantes pueden radicar
     los papeles de grado (punto 34, A-05); siguen vigentes en él, como en los demás
     proyectos terminados (RF35). El acta queda sin revision_id: no respalda la revisión
     de un documento, sino el cierre del proyecto. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/admin/proyectos.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.titulo, p.estado, f.orden AS fase, DATE(s.fecha_hora) AS fecha_sustentacion, (s.fecha_hora <= NOW()) AS realizada
    FROM proyectos p
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN sustentaciones s ON s.proyecto_id = p.id
    WHERE p.id = ?
    <sql:param value="${empty param.id ? 0 : param.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/admin/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="observacion" value="${fn:trim(param.observacion)}" />
<c:set var="numeroActa" value="${fn:trim(param.acta)}" />
<c:set var="fechaActa" value="${fn:trim(param.fecha_acta)}" />

<%-- Acta: número entero positivo y una fecha que exista (CAST da vacío para el 30 de
     febrero), que no sea futura ni anterior al día de la sustentación --%>
<sql:query var="datosActa">
    SELECT (? REGEXP '^[1-9][0-9]{0,8}$') AS numero_valido,
           (? REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') AND CAST(? AS DATE) IS NOT NULL AND CAST(? AS DATE) <= CURDATE() AS fecha_valida,
           CAST(? AS DATE) >= (SELECT DATE(s.fecha_hora) FROM sustentaciones s WHERE s.proyecto_id = ?) AS despues_de_sustentacion
    <sql:param value="${numeroActa}" />
    <sql:param value="${fechaActa}" />
    <sql:param value="${fechaActa}" />
    <sql:param value="${fechaActa}" />
    <sql:param value="${fechaActa}" />
    <sql:param value="${p.id}" />
</sql:query>
<c:set var="acta" value="${datosActa.rows[0]}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.fase != 6 or empty p.fecha_sustentacion or p.realizada != 1}"><c:set var="motivo" value="finalizar-no-disponible" /></c:when>
    <c:when test="${empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
    <c:when test="${acta.numero_valido != 1 or acta.fecha_valida != 1}"><c:set var="motivo" value="acta-invalida" /></c:when>
    <c:when test="${acta.despues_de_sustentacion != 1}"><c:set var="motivo" value="acta-antes-de-sustentacion" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/admin/proyecto.jsp">
        <c:param name="id" value="${p.id}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<fmt:formatDate var="sustentacionTexto" value="${p.fecha_sustentacion}" pattern="dd/MM/yyyy" />

<sql:transaction>
    <sql:update var="finalizados">
        UPDATE proyectos SET estado = 'Finalizado'
        WHERE id = ? AND estado NOT IN ('Finalizado', 'Cancelado') AND fase_id = (SELECT id FROM fases WHERE orden = 6)
        <sql:param value="${p.id}" />
    </sql:update>
    <c:if test="${finalizados == 1}">
        <sql:update>
            INSERT INTO actas (proyecto_id, revision_id, numero, fecha, descripcion) VALUES (?, NULL, ?, CAST(? AS DATE), ?)
            <sql:param value="${p.id}" />
            <sql:param value="${numeroActa}" />
            <sql:param value="${fechaActa}" />
            <sql:param value="Aprobación final del trabajo de grado (sustentación del ${sustentacionTexto}): Finalizado. ${observacion}" />
        </sql:update>
        <sql:update>
            INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Estado', ?)
            <sql:param value="${p.id}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="El comité registró la aprobación final (acta ${numeroActa}) después de la sustentación del ${sustentacionTexto}: el proyecto quedó Finalizado." />
        </sql:update>
        <c:set var="avisoProyecto" value="${p.id}" />
        <c:set var="avisoMensaje">El proyecto «${fn:substring(p.titulo, 0, 80)}» quedó finalizado: el comité registró la aprobación final (acta ${numeroActa}). Ya se pueden radicar los papeles de grado. Observación: ${observacion}</c:set>
        <c:set var="avisoPara" value="estudiantes,director,codirectores,evaluador,comite" />
        <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
    </c:if>
</sql:transaction>

<c:redirect url="/admin/proyecto.jsp">
    <c:param name="id" value="${p.id}" />
    <c:param name="${finalizados == 1 ? 'ok' : 'error'}" value="${finalizados == 1 ? 'proyecto-finalizado' : 'finalizar-no-disponible'}" />
</c:redirect>
