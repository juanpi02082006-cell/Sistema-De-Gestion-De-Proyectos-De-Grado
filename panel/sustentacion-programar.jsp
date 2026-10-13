<%-- Programa o reprograma la sustentación de un proyecto en la fase final, por POST
     (RF39; Anexo H: "estudiantes, director y evaluador programan la sustentación; el
     sistema guarda la fecha y el lugar"). Puede hacerlo, cada uno con su rol activo,
     un estudiante vigente del proyecto, su director (no los codirectores: decide el
     director, RF13) o su evaluador, mientras el proyecto siga en la fase final sin la
     aprobación final del comité. Pide la fecha y la hora, después de este momento, y el
     lugar o el enlace de la reunión (hasta 150 caracteres). Hay una sola por proyecto
     (decisión del 2026-10-10): si ya estaba, se reprograma y queda quién lo hizo y
     cuándo. Avisa a los demás y al comité (RF5); el aviso no nombra a quien la programó,
     así que el estudiante nunca sabe quién es su evaluador (RF27). --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<c:set var="rol" value="${sessionScope.rolActivo.id}" />
<c:choose>
    <c:when test="${rol == 5}">
        <c:set var="paginaProyecto" value="/estudiante/proyecto.jsp" />
        <c:set var="paginaLista" value="/estudiante/proyecto.jsp" />
    </c:when>
    <c:when test="${rol == 3}">
        <c:set var="paginaProyecto" value="/director/proyecto.jsp" />
        <c:set var="paginaLista" value="/director/proyectos.jsp" />
    </c:when>
    <c:when test="${rol == 4}">
        <c:set var="paginaProyecto" value="/evaluador/proyecto.jsp" />
        <c:set var="paginaLista" value="/evaluador/proyectos.jsp" />
    </c:when>
    <c:otherwise>
        <c:redirect url="/panel/inicio.jsp">
            <c:param name="error" value="denegado" />
        </c:redirect>
    </c:otherwise>
</c:choose>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="${paginaLista}" />
</c:if>

<%-- El proyecto, solo si quien la programa es de él --%>
<sql:query var="consulta">
    SELECT p.id, p.titulo, p.estado, p.modalidad_id, f.orden AS fase,
           (SELECT COUNT(*) FROM sustentaciones s WHERE s.proyecto_id = p.id) AS programada
    FROM proyectos p
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE p.id = ?
      AND ((? = 5 AND EXISTS (SELECT 1 FROM proyecto_estudiantes pe
                              WHERE pe.proyecto_id = p.id AND pe.estudiante_id = ? AND pe.vigente = 1))
           OR (? = 3 AND p.director_id = ?)
           OR (? = 4 AND p.evaluador_id = ?))
    <sql:param value="${empty param.id ? 0 : param.id}" />
    <sql:param value="${rol}" />
    <sql:param value="${sessionScope.usuario.id}" />
    <sql:param value="${rol}" />
    <sql:param value="${sessionScope.usuario.id}" />
    <sql:param value="${rol}" />
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="${paginaLista}">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />

<%-- Fecha y hora del campo datetime-local (aaaa-mm-ddThh:mm): con ese formato exacto,
     una fecha que exista y después de este momento. Para el 30 de febrero, CAST da vacío,
     pero MariaDB igual lo compara con NOW(): por eso va también IS NOT NULL.
     La fecha y la hora salen por separado para formatearlas (fmt no formatea un DATETIME,
     que el driver entrega como LocalDateTime). --%>
<c:set var="fechaHoraTexto" value="${fn:replace(fn:trim(param.fecha_hora), 'T', ' ')}" />
<c:set var="lugar" value="${fn:trim(param.lugar)}" />
<sql:query var="datosFecha">
    SELECT (? REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$') AND CAST(? AS DATETIME) IS NOT NULL
               AND CAST(? AS DATETIME) > NOW() AS valida,
           DATE(CAST(? AS DATETIME)) AS fecha, TIME(CAST(? AS DATETIME)) AS hora
    <sql:param value="${fechaHoraTexto}" />
    <sql:param value="${fechaHoraTexto}" />
    <sql:param value="${fechaHoraTexto}" />
    <sql:param value="${fechaHoraTexto}" />
    <sql:param value="${fechaHoraTexto}" />
</sql:query>
<c:set var="fh" value="${datosFecha.rows[0]}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.fase != 6 or p.modalidad_id == 5}"><c:set var="motivo" value="sustentacion-no-aplica" /></c:when>
    <c:when test="${fh.valida != 1}"><c:set var="motivo" value="sustentacion-fecha-invalida" /></c:when>
    <c:when test="${empty lugar or fn:length(lugar) > 150}"><c:set var="motivo" value="sustentacion-lugar-invalido" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="${paginaProyecto}">
        <c:param name="id" value="${p.id}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<c:set var="reprogramada" value="${p.programada > 0}" />
<fmt:formatDate var="fechaTexto" value="${fh.fecha}" pattern="dd/MM/yyyy" />
<fmt:formatDate var="horaTexto" value="${fh.hora}" pattern="h:mm a" />
<c:set var="textoSustentacion">${reprogramada ? 'Se reprogramó' : 'Se programó'} la sustentación de «${fn:substring(p.titulo, 0, 80)}» para el ${fechaTexto} a las ${horaTexto}, en ${lugar}.</c:set>

<sql:transaction>
    <sql:update>
        INSERT INTO sustentaciones (proyecto_id, fecha_hora, lugar, programada_por) VALUES (?, CAST(? AS DATETIME), ?, ?)
        ON DUPLICATE KEY UPDATE fecha_hora = VALUES(fecha_hora), lugar = VALUES(lugar),
                                programada_por = VALUES(programada_por), programada_en = CURRENT_TIMESTAMP
        <sql:param value="${p.id}" />
        <sql:param value="${fechaHoraTexto}" />
        <sql:param value="${lugar}" />
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:update>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Otro', ?)
        <sql:param value="${p.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${fn:substring(textoSustentacion, 0, 255)}" />
    </sql:update>
    <c:set var="avisoProyecto" value="${p.id}" />
    <c:set var="avisoMensaje" value="${textoSustentacion}" />
    <c:set var="avisoPara" value="estudiantes,director,codirectores,evaluador,comite" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
</sql:transaction>

<c:redirect url="${paginaProyecto}">
    <c:param name="id" value="${p.id}" />
    <c:param name="ok" value="${reprogramada ? 'sustentacion-reprogramada' : 'sustentacion-programada'}" />
</c:redirect>
