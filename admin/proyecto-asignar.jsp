<%-- El comité (el administrador) asigna el director y el evaluador de un proyecto
     (RF11), por POST. El director es obligatorio y debe tener el rol Docente director (3); el
     evaluador es opcional y debe tener el rol Docente evaluador (4). Un docente nunca evalúa el
     proyecto que dirige ni el que codirige (también lo impide la base para el director).
     También marca si el proyecto es interdisciplinario (RF13: solo investigación o
     desarrollo tecnológico; admite hasta 4 estudiantes y hasta 2 codirectores, docentes
     activos con el rol Docente director, distintos del director y del evaluador). No se
     desmarca si ya tiene más estudiantes de los que permite la modalidad; al
     desmarcarlo se quitan los codirectores. Si el pago ya está aprobado (o no aplica),
     el proyecto pasa a la fase 2 (avanzar-fase-2.jspf). --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
    <c:redirect url="/admin/proyectos.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.titulo, p.estado, p.modalidad_id, p.director_id, p.evaluador_id, m.max_integrantes,
           (SELECT COUNT(*) FROM proyecto_estudiantes x WHERE x.proyecto_id = p.id AND x.vigente = 1) AS integrantes,
           (SELECT CONCAT('|', GROUP_CONCAT(pc.docente_id SEPARATOR '|'), '|') FROM proyecto_codirectores pc WHERE pc.proyecto_id = p.id) AS codirectores
    FROM proyectos p JOIN modalidades m ON m.id = p.modalidad_id
    WHERE p.id = ?
    <sql:param value="${param.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/admin/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="idProyecto" value="${p.id}" />
<c:set var="interdisciplinario" value="${param.interdisciplinario == 'on' and (p.modalidad_id == 1 or p.modalidad_id == 2)}" />
<c:set var="codirector1" value="${interdisciplinario ? fn:trim(param.codirector1) : ''}" />
<c:set var="codirector2" value="${interdisciplinario ? fn:trim(param.codirector2) : ''}" />

<%-- Docente activo con el rol pedido (si el id no es un número, no encuentra a nadie) --%>
<sql:query var="director">
    SELECT u.nombre FROM usuarios u JOIN usuario_roles ur ON ur.usuario_id = u.id
    WHERE u.id = ? AND ur.rol_id = 3 AND u.activo = 1
    <sql:param value="${empty param.director ? 0 : param.director}" />
</sql:query>
<sql:query var="evaluador">
    SELECT u.nombre FROM usuarios u JOIN usuario_roles ur ON ur.usuario_id = u.id
    WHERE u.id = ? AND ur.rol_id = 4 AND u.activo = 1
    <sql:param value="${empty param.evaluador ? 0 : param.evaluador}" />
</sql:query>
<sql:query var="codirectoresValidos">
    SELECT COUNT(*) AS total FROM usuarios u JOIN usuario_roles ur ON ur.usuario_id = u.id
    WHERE u.id IN (?, ?) AND ur.rol_id = 3 AND u.activo = 1
    <sql:param value="${empty codirector1 ? 0 : codirector1}" />
    <sql:param value="${empty codirector2 ? 0 : codirector2}" />
</sql:query>
<c:set var="codirectoresPedidos" value="${(empty codirector1 ? 0 : 1) + (empty codirector2 ? 0 : 1)}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${director.rowCount == 0}"><c:set var="motivo" value="director-invalido" /></c:when>
    <c:when test="${not empty param.evaluador and evaluador.rowCount == 0}"><c:set var="motivo" value="evaluador-invalido" /></c:when>
    <c:when test="${not empty param.evaluador and param.evaluador == param.director}"><c:set var="motivo" value="director-evaluador" /></c:when>
    <c:when test="${not interdisciplinario and p.integrantes > p.max_integrantes}"><c:set var="motivo" value="demasiados-integrantes" /></c:when>
    <c:when test="${not empty codirector1 and codirector1 == codirector2}"><c:set var="motivo" value="codirector-invalido" /></c:when>
    <c:when test="${codirectoresValidos.rows[0].total != codirectoresPedidos}"><c:set var="motivo" value="codirector-invalido" /></c:when>
    <c:when test="${(not empty codirector1 and (codirector1 == param.director or codirector1 == param.evaluador))
                    or (not empty codirector2 and (codirector2 == param.director or codirector2 == param.evaluador))}"><c:set var="motivo" value="codirector-invalido" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/admin/proyecto.jsp">
        <c:param name="id" value="${idProyecto}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<c:set var="directorAnterior">${p.director_id}</c:set>
<c:set var="evaluadorAnterior">${p.evaluador_id}</c:set>

<%-- En el historial y en los avisos de los estudiantes va el nombre del director, pero
     no el del evaluador: el estudiante no debe saber quién lo evalúa (RF27). --%>
<c:catch var="errorGuardar">
    <sql:transaction>
        <sql:update>
            UPDATE proyectos SET director_id = ?, evaluador_id = NULLIF(?, ''), interdisciplinario = ? WHERE id = ?
            <sql:param value="${param.director}" />
            <sql:param value="${empty param.evaluador ? '' : param.evaluador}" />
            <sql:param value="${interdisciplinario ? 1 : 0}" />
            <sql:param value="${idProyecto}" />
        </sql:update>
        <sql:update>
            DELETE FROM proyecto_codirectores WHERE proyecto_id = ?
            <sql:param value="${idProyecto}" />
        </sql:update>
        <c:forEach var="cd" items="${codirector1},${codirector2}">
            <c:if test="${not empty fn:trim(cd)}">
                <sql:update>
                    INSERT INTO proyecto_codirectores (proyecto_id, docente_id) VALUES (?, ?)
                    <sql:param value="${idProyecto}" />
                    <sql:param value="${fn:trim(cd)}" />
                </sql:update>
            </c:if>
        </c:forEach>
        <sql:update>
            INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion)
            VALUES (?, ?, 'Decisión', ?)
            <sql:param value="${idProyecto}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="El comité asignó como director a ${director.rows[0].nombre}${empty param.evaluador ? '' : ' y asignó el evaluador'}${codirectoresPedidos > 0 ? ' y los codirectores' : ''}${interdisciplinario ? ' (proyecto interdisciplinario)' : ''}." />
        </sql:update>

        <%-- Avisos (RF5): solo a quien cambió --%>
        <c:set var="avisoProyecto" value="${idProyecto}" />
        <c:if test="${param.director != directorAnterior}">
            <c:set var="avisoMensaje">El comité asignó a ${director.rows[0].nombre} como director del proyecto.</c:set>
            <c:set var="avisoPara" value="estudiantes" />
            <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
            <c:set var="avisoMensaje">El comité te asignó como director del proyecto «${p.titulo}».</c:set>
            <c:set var="avisoPara" value="director" />
            <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
        </c:if>
        <c:if test="${not empty param.evaluador and param.evaluador != evaluadorAnterior}">
            <c:set var="avisoMensaje">El comité te asignó como evaluador del proyecto «${p.titulo}». La propuesta te llega cuando el director la envía.</c:set>
            <c:set var="avisoPara" value="evaluador" />
            <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
        </c:if>
        <c:forEach var="cd" items="${codirector1},${codirector2}">
            <c:set var="marcaCodirector">|${fn:trim(cd)}|</c:set>
            <c:if test="${not empty fn:trim(cd) and not fn:contains(p.codirectores, marcaCodirector)}">
                <c:set var="avisoMensaje">El comité te asignó como codirector del proyecto «${p.titulo}».</c:set>
                <c:set var="avisoPara" value="usuario" />
                <c:set var="avisoUsuario" value="${fn:trim(cd)}" />
                <c:set var="avisoEnlace" value="/director/proyecto.jsp?id=${idProyecto}" />
                <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
            </c:if>
        </c:forEach>
    </sql:transaction>
</c:catch>
<c:if test="${not empty errorGuardar}">
    <c:redirect url="/admin/proyecto.jsp">
        <c:param name="id" value="${idProyecto}" />
        <c:param name="error" value="general" />
    </c:redirect>
</c:if>

<%@ include file="/WEB-INF/jspf/avanzar-fase-2.jspf" %>

<c:redirect url="/admin/proyecto.jsp">
    <c:param name="id" value="${idProyecto}" />
    <c:param name="ok" value="${avanzoFase2 ? 'asignacion-fase-2' : 'asignacion-guardada'}" />
</c:redirect>
