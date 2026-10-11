<%-- Guarda la evaluación del evaluador, por POST (RF23, RF22, RF34), de la propuesta
     (documento=propuesta: FDC-124 en la fase 4, rejilla del F-DC-124) o del informe final
     (documento=informe: FDC-125 en la fase 5, rejilla del F-DC-129, donde cada indicador
     también puede ser N/A). Solo el evaluador del proyecto y cuando el director ya le
     envió la última versión.
       borrador  guarda lo que lleve de la rejilla, el concepto y la observación, sin
                 validar; se puede seguir después (RF-59).
       enviar    exige todos los indicadores respondidos (RF-60), el concepto (Aprobado,
                 Aplazado o No aprobado; "Aprobado" solo si todos los que aplican están en
                 Sí, RF-68) y la observación general. En el informe, "Aplazado" exige el
                 plazo máximo para las correcciones (RF22), hasta la fecha límite del
                 proyecto. Pasa al comité, que da la decisión final (RF14); el estudiante y
                 el director ven el concepto y las observaciones (RF-62).
       devolver  solo la propuesta: con observación, la devuelve al director para arreglos;
                 el proyecto vuelve a la fase 3 y el director tiene otra vez 5 días
                 hábiles (Anexo H).
     Los avisos nunca dicen quién es el evaluador (RF27). --%>
<%@ include file="/WEB-INF/jspf/solo-evaluador.jspf" %>
<%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/evaluador/proyectos.jsp" />
</c:if>

<c:set var="esInforme" value="${param.documento == 'informe'}" />
<c:set var="tipoEntrega" value="${esInforme ? 'FDC-125' : 'FDC-124'}" />
<c:set var="nombreDocumento" value="${esInforme ? 'el informe final' : 'la propuesta'}" />
<sql:query var="consulta">
    SELECT p.id, p.titulo, p.estado, p.modalidad_id, p.fecha_limite, f.orden AS fase,
           ${esInforme ? sqlUltimaRevisionInforme : sqlUltimaRevision} AS ultima,
           e.id AS entrega_id, e.version
    FROM proyectos p
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN entregas e ON e.proyecto_id = p.id AND e.tipo = ?
         AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = ?)
    WHERE p.id = ? AND p.evaluador_id = ?
    <sql:param value="${tipoEntrega}" />
    <sql:param value="${tipoEntrega}" />
    <sql:param value="${empty param.id ? 0 : param.id}" />
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/evaluador/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="accion" value="${param.accion}" />
<c:set var="observacion" value="${fn:trim(param.observacion)}" />
<c:set var="concepto" value="${param.concepto == 'Aprobado' or param.concepto == 'Aplazado' or param.concepto == 'No aprobado' ? param.concepto : ''}" />

<%-- Indicadores que aplican a la modalidad y lo que marcó el evaluador en cada uno --%>
<sql:query var="indicadores">
    SELECT i.id FROM criterios_rejilla c
    JOIN criterio_modalidades cm ON cm.criterio_id = c.id AND cm.modalidad_id = ?
    JOIN indicadores_rejilla i ON i.criterio_id = c.id
    WHERE c.formato = ? ORDER BY c.orden, i.orden
    <sql:param value="${p.modalidad_id}" />
    <sql:param value="${esInforme ? 'FDC-129' : 'FDC-124'}" />
</sql:query>
<c:set var="respondidos" value="0" />
<c:set var="enNo" value="0" />
<c:forEach var="ind" items="${indicadores.rows}">
    <c:set var="campo">r${ind.id}</c:set>
    <c:if test="${param[campo] == 'si' or param[campo] == 'no' or (esInforme and param[campo] == 'na')}"><c:set var="respondidos" value="${respondidos + 1}" /></c:if>
    <c:if test="${param[campo] == 'no'}"><c:set var="enNo" value="${enNo + 1}" /></c:if>
</c:forEach>

<%-- Informe aplazado: plazo para las correcciones, después de hoy y hasta la fecha límite --%>
<c:set var="plazoTexto" value="${fn:trim(param.plazo)}" />
<sql:query var="datosPlazo">
    SELECT (? REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') AND STR_TO_DATE(?, '%Y-%m-%d') > CURDATE()
           AND (? IS NULL OR STR_TO_DATE(?, '%Y-%m-%d') <= ?) AS valido
    <sql:param value="${plazoTexto}" />
    <sql:param value="${plazoTexto}" />
    <sql:dateParam value="${p.fecha_limite}" type="date" />
    <sql:param value="${plazoTexto}" />
    <sql:dateParam value="${p.fecha_limite}" type="date" />
</sql:query>
<c:set var="conPlazo" value="${esInforme and concepto == 'Aplazado'}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${accion != 'borrador' and accion != 'enviar' and not (accion == 'devolver' and not esInforme)}"><c:set var="motivo" value="general" /></c:when>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.fase != (esInforme ? 5 : 4) or p.ultima != 'Director:Aprobado'}"><c:set var="motivo" value="evaluacion-no-disponible" /></c:when>
    <c:when test="${accion == 'devolver' and empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
    <c:when test="${accion == 'enviar' and respondidos < indicadores.rowCount}"><c:set var="motivo" value="rejilla-incompleta" /></c:when>
    <c:when test="${accion == 'enviar' and empty concepto}"><c:set var="motivo" value="concepto-requerido" /></c:when>
    <c:when test="${accion == 'enviar' and empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
    <c:when test="${accion == 'enviar' and concepto == 'Aprobado' and enNo > 0}"><c:set var="motivo" value="aprobado-con-no" /></c:when>
    <c:when test="${accion == 'enviar' and conPlazo and datosPlazo.rows[0].valido != 1}"><c:set var="motivo" value="plazo-correccion-invalido" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/evaluador/proyecto.jsp">
        <c:param name="id" value="${p.id}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<c:if test="${accion == 'devolver'}">
    <%-- El director tiene otra vez 5 días hábiles para revisarla (RF21) --%>
    <c:set var="diasHabiles" value="5" />
    <%@ include file="/WEB-INF/jspf/plazo-habil.jspf" %>
</c:if>

<sql:transaction>
    <%-- El borrador anterior se reemplaza (sus respuestas se borran en cascada) --%>
    <sql:update>
        DELETE FROM revisiones WHERE entrega_id = ? AND revisor_id = ? AND rol = 'Evaluador' AND estado = 'Borrador'
        <sql:param value="${p.entrega_id}" />
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:update>
    <c:choose>
        <c:when test="${accion == 'devolver'}">
            <sql:update>
                INSERT INTO revisiones (entrega_id, revisor_id, rol, estado, decision, observacion)
                VALUES (?, ?, 'Evaluador', 'Enviada', 'Devuelto', ?)
                <sql:param value="${p.entrega_id}" />
                <sql:param value="${sessionScope.usuario.id}" />
                <sql:param value="${observacion}" />
            </sql:update>
            <sql:update>
                UPDATE entregas SET fecha_limite_revision = ? WHERE id = ?
                <sql:dateParam value="${fechaPlazo}" type="date" />
                <sql:param value="${p.entrega_id}" />
            </sql:update>
            <sql:update>
                UPDATE proyectos SET fase_id = (SELECT id FROM fases WHERE orden = 3) WHERE id = ?
                <sql:param value="${p.id}" />
            </sql:update>
            <sql:update>
                INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Fase', ?)
                <sql:param value="${p.id}" />
                <sql:param value="${sessionScope.usuario.id}" />
                <sql:param value="El evaluador devolvió la versión ${p.version} del FDC-124 al director para arreglos. El proyecto volvió a la fase 3 (Propuesta II)." />
            </sql:update>
            <c:set var="avisoProyecto" value="${p.id}" />
            <c:set var="avisoMensaje">El evaluador devolvió la propuesta de «${p.titulo}» al director para arreglos. Observación: ${observacion}</c:set>
            <c:set var="avisoPara" value="estudiantes,director,codirectores,comite" />
            <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
        </c:when>
        <c:otherwise>
            <sql:update>
                INSERT INTO revisiones (entrega_id, revisor_id, rol, estado, decision, observacion, plazo_correccion)
                VALUES (?, ?, 'Evaluador', ?, NULLIF(?, ''), NULLIF(?, ''),
                        CASE WHEN ? = 1 AND ? REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(?, '%Y-%m-%d') END)
                <sql:param value="${p.entrega_id}" />
                <sql:param value="${sessionScope.usuario.id}" />
                <sql:param value="${accion == 'enviar' ? 'Enviada' : 'Borrador'}" />
                <sql:param value="${concepto}" />
                <sql:param value="${observacion}" />
                <sql:param value="${conPlazo ? 1 : 0}" />
                <sql:param value="${plazoTexto}" />
                <sql:param value="${plazoTexto}" />
            </sql:update>
            <sql:query var="nueva">SELECT LAST_INSERT_ID() AS id</sql:query>
            <c:forEach var="ind" items="${indicadores.rows}">
                <c:set var="campo">r${ind.id}</c:set>
                <c:set var="campoObservacion">o${ind.id}</c:set>
                <sql:update>
                    INSERT INTO revision_indicadores (revision_id, indicador_id, cumple, observacion)
                    VALUES (?, ?, NULLIF(?, ''), NULLIF(?, ''))
                    <sql:param value="${nueva.rows[0].id}" />
                    <sql:param value="${ind.id}" />
                    <sql:param value="${param[campo] == 'si' ? 'Sí' : (param[campo] == 'no' ? 'No' : (esInforme and param[campo] == 'na' ? 'N/A' : ''))}" />
                    <sql:param value="${fn:substring(fn:trim(param[campoObservacion]), 0, 500)}" />
                </sql:update>
            </c:forEach>
            <c:if test="${accion == 'enviar'}">
                <c:if test="${conPlazo}"><c:set var="textoPlazo"> Plazo para las correcciones: ${fn:substring(plazoTexto, 8, 10)}/${fn:substring(plazoTexto, 5, 7)}/${fn:substring(plazoTexto, 0, 4)}.</c:set></c:if>
                <sql:update>
                    INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Evaluación', ?)
                    <sql:param value="${p.id}" />
                    <sql:param value="${sessionScope.usuario.id}" />
                    <sql:param value="El evaluador envió la evaluación de la versión ${p.version} del ${tipoEntrega} con concepto ${concepto}.${textoPlazo} Pasa al comité para la decisión final." />
                </sql:update>
                <c:set var="avisoProyecto" value="${p.id}" />
                <c:set var="avisoMensaje">El evaluador dio su concepto sobre ${nombreDocumento}: ${concepto}.${textoPlazo} La decisión final es del comité. Observación: ${observacion}</c:set>
                <c:set var="avisoPara" value="estudiantes,director,codirectores" />
                <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
                <c:set var="avisoMensaje">${esInforme ? 'El informe final' : 'La propuesta'} de «${p.titulo}» ya tiene el concepto del evaluador (${concepto}): falta la decisión del comité.</c:set>
                <c:set var="avisoPara" value="comite" />
                <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
            </c:if>
        </c:otherwise>
    </c:choose>
</sql:transaction>

<c:redirect url="/evaluador/proyecto.jsp">
    <c:param name="id" value="${p.id}" />
    <c:param name="ok" value="${accion == 'devolver' ? 'evaluacion-devuelta' : (accion == 'enviar' ? 'evaluacion-enviada' : 'evaluacion-borrador')}" />
</c:redirect>
