<%-- El comité (el administrador) da la decisión final sobre el informe final, por POST
     (RF14, RF22, RF34, RF39). Solo en la fase 5, cuando el evaluador ya envió su
     concepto con la rejilla del F-DC-129; el comité decide sea cual sea ese concepto.
     Siempre con observación y con el número y la fecha del acta.
       aprobar     la versión queda como la oficial (RF43) y el proyecto pasa a la fase
                   final, donde el comité programa la sustentación (RF39).
       aplazar     el proyecto vuelve a la fase 4: el estudiante hace las correcciones
                   dentro del plazo que indicó el evaluador y lo envía otra vez (RF22).
       no-aprobar  también vuelve a la fase 4 para corrección (por ejemplo, parafraseo si
                   hay plagio), hasta antes de la fecha límite del proyecto (decisión del
                   equipo del 2026-10-06; se aparta del art. 34 del reglamento).
       devolver    si falta algo (por ejemplo la firma o el Turnitin), vuelve al director,
                   que tiene otra vez 5 días hábiles; sigue en la fase 5. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/admin/proyectos.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.titulo, p.estado, p.fecha_limite, f.orden AS fase, ${sqlUltimaRevisionInforme} AS ultima,
           e.id AS entrega_id, e.version,
           (SELECT r.plazo_correccion FROM revisiones r WHERE r.entrega_id = e.id AND r.rol = 'Evaluador' AND r.estado = 'Enviada'
            ORDER BY r.id DESC LIMIT 1) AS plazo_correccion
    FROM proyectos p
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN entregas e ON e.proyecto_id = p.id AND e.tipo = 'FDC-125'
         AND e.version = (SELECT MAX(e2.version) FROM entregas e2 WHERE e2.proyecto_id = p.id AND e2.tipo = 'FDC-125')
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
<c:set var="decision" value="${param.decision}" />

<%-- Acta: número entero positivo y fecha válida que no sea futura --%>
<sql:query var="datosActa">
    SELECT (? REGEXP '^[1-9][0-9]{0,8}$') AS numero_valido,
           (? REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') AND STR_TO_DATE(?, '%Y-%m-%d') IS NOT NULL
               AND STR_TO_DATE(?, '%Y-%m-%d') <= CURDATE() AS fecha_valida
    <sql:param value="${fn:trim(param.acta)}" />
    <sql:param value="${fn:trim(param.fecha_acta)}" />
    <sql:param value="${fn:trim(param.fecha_acta)}" />
    <sql:param value="${fn:trim(param.fecha_acta)}" />
</sql:query>
<c:set var="acta" value="${datosActa.rows[0]}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.fase != 5 or not fn:startsWith(p.ultima, 'Evaluador:')}"><c:set var="motivo" value="decision-no-disponible" /></c:when>
    <c:when test="${decision != 'aprobar' and decision != 'aplazar' and decision != 'no-aprobar' and decision != 'devolver'}"><c:set var="motivo" value="general" /></c:when>
    <c:when test="${empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
    <c:when test="${acta.numero_valido != 1 or acta.fecha_valida != 1}"><c:set var="motivo" value="acta-invalida" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/admin/proyecto.jsp">
        <c:param name="id" value="${p.id}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<c:set var="decisionGuardada" value="${decision == 'aprobar' ? 'Aprobado' : (decision == 'aplazar' ? 'Aplazado' : (decision == 'no-aprobar' ? 'No aprobado' : 'Devuelto'))}" />
<c:set var="numeroActa" value="${fn:trim(param.acta)}" />
<fmt:formatDate var="limiteTexto" value="${p.fecha_limite}" pattern="dd/MM/yyyy" />
<fmt:formatDate var="plazoTexto" value="${p.plazo_correccion}" pattern="dd/MM/yyyy" />
<c:if test="${decision == 'devolver'}">
    <c:set var="diasHabiles" value="5" />
    <%@ include file="/WEB-INF/jspf/plazo-habil.jspf" %>
</c:if>
<c:choose>
    <c:when test="${decision == 'aprobar'}"><c:set var="textoDecision">El comité aprobó la versión ${p.version} del informe final (acta ${numeroActa}). El proyecto pasó a la fase final: el comité programará la sustentación.</c:set></c:when>
    <c:when test="${decision == 'aplazar'}"><c:set var="textoDecision">El comité aplazó el informe final (versión ${p.version}, acta ${numeroActa}): hay que corregirlo${empty plazoTexto ? '' : ' a más tardar el '}${plazoTexto} y enviarlo otra vez. El proyecto volvió a la fase 4.</c:set></c:when>
    <c:when test="${decision == 'no-aprobar'}"><c:set var="textoDecision">El comité no aprobó el informe final (versión ${p.version}, acta ${numeroActa}): vuelve para corrección, antes del ${limiteTexto}. El proyecto volvió a la fase 4.</c:set></c:when>
    <c:otherwise><c:set var="textoDecision">El comité devolvió la versión ${p.version} del informe final al director (acta ${numeroActa}) porque le falta algo.</c:set></c:otherwise>
</c:choose>

<sql:transaction>
    <sql:update>
        INSERT INTO revisiones (entrega_id, revisor_id, rol, estado, decision, observacion)
        VALUES (?, ?, 'Comité', 'Enviada', ?, ?)
        <sql:param value="${p.entrega_id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${decisionGuardada}" />
        <sql:param value="${observacion}" />
    </sql:update>
    <sql:query var="decisionNueva">SELECT LAST_INSERT_ID() AS id</sql:query>
    <sql:update>
        INSERT INTO actas (proyecto_id, revision_id, numero, fecha, descripcion) VALUES (?, ?, ?, STR_TO_DATE(?, '%Y-%m-%d'), ?)
        <sql:param value="${p.id}" />
        <sql:param value="${decisionNueva.rows[0].id}" />
        <sql:param value="${numeroActa}" />
        <sql:param value="${fn:trim(param.fecha_acta)}" />
        <sql:param value="Informe final (FDC-125, versión ${p.version}): ${decisionGuardada}. ${observacion}" />
    </sql:update>
    <c:choose>
        <c:when test="${decision == 'aprobar'}">
            <sql:update>
                UPDATE entregas SET oficial = 1 WHERE id = ?
                <sql:param value="${p.entrega_id}" />
            </sql:update>
            <sql:update>
                UPDATE proyectos SET fase_id = (SELECT id FROM fases WHERE orden = 6) WHERE id = ?
                <sql:param value="${p.id}" />
            </sql:update>
        </c:when>
        <c:when test="${decision == 'aplazar' or decision == 'no-aprobar'}">
            <sql:update>
                UPDATE proyectos SET fase_id = (SELECT id FROM fases WHERE orden = 4) WHERE id = ?
                <sql:param value="${p.id}" />
            </sql:update>
        </c:when>
        <c:otherwise>
            <sql:update>
                UPDATE entregas SET fecha_limite_revision = ? WHERE id = ?
                <sql:dateParam value="${fechaPlazo}" type="date" />
                <sql:param value="${p.entrega_id}" />
            </sql:update>
        </c:otherwise>
    </c:choose>
    <c:set var="avisoProyecto" value="${p.id}" />
    <c:set var="avisoMensaje">${textoDecision} Observación: ${observacion}</c:set>
    <c:set var="avisoPara" value="estudiantes,director,codirectores,evaluador" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Decisión', ?)
        <sql:param value="${p.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${fn:substring(textoDecision, 0, 255)}" />
    </sql:update>
</sql:transaction>

<c:redirect url="/admin/proyecto.jsp">
    <c:param name="id" value="${p.id}" />
    <c:param name="ok" value="informe-${decision}-comite" />
</c:redirect>
