<%-- El estudiante toma una idea aprobada del banco (RF25, RF29), por POST. Se crea su
     proyecto en la fase 1 (pago) y la idea queda "Tomada".
     Reglas:
     - Debe estar habilitado (RF33).
     - Hay un periodo activo y el banco no ha cerrado (RF3, RF25).
     - La idea es de su nivel: el de tecnología no toma ideas del nivel universitario (RF25).
     - Si la idea es la propuesta de un estudiante, solo la toma quien la formuló.
     - Un solo proyecto vigente (RF35; la base también lo impide).
     - Si la idea no tiene modalidad, el estudiante la escoge. --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/ideas/banco.jsp" />
</c:if>

<c:set var="idEstudiante" value="${sessionScope.usuario.id}" />
<%@ include file="/WEB-INF/jspf/habilitacion.jspf" %>

<sql:query var="periodoActivo">
    SELECT id, (fecha_cierre_banco IS NULL OR CURDATE() <= fecha_cierre_banco) AS abierto
    FROM periodos WHERE estado = 'Activo' LIMIT 1
</sql:query>
<sql:query var="vigente">
    SELECT COUNT(*) AS total FROM proyecto_estudiantes WHERE estudiante_id = ? AND vigente = 1
    <sql:param value="${idEstudiante}" />
</sql:query>
<sql:query var="consultaIdea">
    SELECT id, titulo, modalidad_id
    FROM ideas
    WHERE id = ? AND estado = 'Aprobada' AND nivel_id = ?
      AND (origen = 'Docente' OR propuesta_por = ?)
    <sql:param value="${param.id}" />
    <sql:param value="${est.nivel_id}" />
    <sql:param value="${idEstudiante}" />
</sql:query>
<sql:query var="modalidadElegida">
    SELECT id FROM modalidades WHERE id = ?
    <sql:param value="${empty param.modalidad ? 0 : param.modalidad}" />
</sql:query>

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${not habilitado}"><c:set var="motivo" value="no-habilitado" /></c:when>
    <c:when test="${periodoActivo.rowCount == 0}"><c:set var="motivo" value="sin-periodo-activo" /></c:when>
    <c:when test="${periodoActivo.rows[0].abierto != 1}"><c:set var="motivo" value="banco-cerrado" /></c:when>
    <c:when test="${vigente.rows[0].total > 0}"><c:set var="motivo" value="proyecto-vigente" /></c:when>
    <c:when test="${consultaIdea.rowCount == 0}"><c:set var="motivo" value="idea-no-disponible" /></c:when>
    <c:when test="${empty consultaIdea.rows[0].modalidad_id and modalidadElegida.rowCount == 0}"><c:set var="motivo" value="modalidad-requerida" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/ideas/banco.jsp">
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<c:set var="idea" value="${consultaIdea.rows[0]}" />
<c:set var="modalidad">${empty idea.modalidad_id ? modalidadElegida.rows[0].id : idea.modalidad_id}</c:set>

<%-- Todo o nada: si otro estudiante la tomó primero, no cambia ninguna fila y no se
     crea el proyecto; si el estudiante ya tiene un proyecto vigente, la clave única
     de proyecto_estudiantes falla y se deshace todo. --%>
<c:catch var="errorTomar">
    <sql:transaction>
        <sql:update var="tomadas">
            UPDATE ideas SET estado = 'Tomada' WHERE id = ? AND estado = 'Aprobada'
            <sql:param value="${idea.id}" />
        </sql:update>
        <c:if test="${tomadas == 1}">
            <sql:update>
                INSERT INTO proyectos (titulo, descripcion, idea_id, modalidad_id, nivel_id, periodo_id, fase_id, estado)
                SELECT titulo, descripcion, id, ?, ?, ?, (SELECT id FROM fases WHERE orden = 1), 'Pendiente' FROM ideas WHERE id = ?
                <sql:param value="${modalidad}" />
                <sql:param value="${est.nivel_id}" />
                <sql:param value="${periodoActivo.rows[0].id}" />
                <sql:param value="${idea.id}" />
            </sql:update>
            <sql:query var="nuevo">SELECT LAST_INSERT_ID() AS id</sql:query>
            <%-- Código del proyecto (RF40): prefijo (65 tecnológico, 125 universitario),
                 periodo (2026-2) y consecutivo dentro del prefijo y el periodo, desde 1
                 (supuesto). Ejemplo: 65-2026-2/1. La clave única del código evita que dos
                 proyectos queden con el mismo. --%>
            <sql:query var="consecutivo">
                SELECT COUNT(*) AS n FROM proyectos WHERE periodo_id = ? AND nivel_id = ?
                <sql:param value="${periodoActivo.rows[0].id}" />
                <sql:param value="${est.nivel_id}" />
            </sql:query>
            <sql:update>
                UPDATE proyectos p JOIN periodos pr ON pr.id = p.periodo_id
                SET p.codigo = CONCAT(IF(p.nivel_id = 1, '65', '125'), '-', pr.nombre, '/', ?)
                WHERE p.id = ?
                <sql:param value="${consecutivo.rows[0].n}" />
                <sql:param value="${nuevo.rows[0].id}" />
            </sql:update>
            <sql:query var="codigoNuevo">
                SELECT codigo FROM proyectos WHERE id = ?
                <sql:param value="${nuevo.rows[0].id}" />
            </sql:query>
            <sql:update>
                INSERT INTO proyecto_estudiantes (proyecto_id, estudiante_id) VALUES (?, ?)
                <sql:param value="${nuevo.rows[0].id}" />
                <sql:param value="${idEstudiante}" />
            </sql:update>
            <sql:update>
                INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion)
                VALUES (?, ?, 'Estado', CONCAT('El estudiante tomó la idea "', LEFT(?, 160), '". Proyecto ', ?, ' en la fase 1.'))
                <sql:param value="${nuevo.rows[0].id}" />
                <sql:param value="${idEstudiante}" />
                <sql:param value="${idea.titulo}" />
                <sql:param value="${codigoNuevo.rows[0].codigo}" />
            </sql:update>
        </c:if>
    </sql:transaction>
</c:catch>

<c:choose>
    <c:when test="${not empty errorTomar}">
        <c:redirect url="/ideas/banco.jsp">
            <c:param name="error" value="${fn:contains(errorTomar.message, 'uq_proyecto_estudiantes_vigente') ? 'proyecto-vigente' : 'general'}" />
        </c:redirect>
    </c:when>
    <c:when test="${tomadas != 1}">
        <c:redirect url="/ideas/banco.jsp">
            <c:param name="error" value="idea-no-disponible" />
        </c:redirect>
    </c:when>
    <c:otherwise>
        <c:redirect url="/ideas/banco.jsp">
            <c:param name="ok" value="idea-tomada" />
        </c:redirect>
    </c:otherwise>
</c:choose>
