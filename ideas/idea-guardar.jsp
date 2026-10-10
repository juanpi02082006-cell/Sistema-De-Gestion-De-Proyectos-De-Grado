<%-- Guarda una idea nueva o editada (RF10). Si la registra un docente, es de
     origen "Docente"; si la formula un estudiante, es "Estudiante" y de su nivel.
     Queda pendiente hasta que el comité la revise, también al editarla. Se asocia
     al periodo activo, si lo hay. --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/ideas/banco.jsp" />
</c:if>
<c:set var="rol" value="${sessionScope.rolActivo.id}" />
<c:set var="esEstudiante" value="${rol == 5}" />
<c:if test="${not (rol == 3 or rol == 4 or rol == 5)}">
    <c:redirect url="/ideas/banco.jsp">
        <c:param name="error" value="denegado" />
    </c:redirect>
</c:if>

<c:set var="editando" value="${not empty param.id}" />
<c:set var="origen" value="${esEstudiante ? 'Estudiante' : 'Docente'}" />
<c:set var="tituloIdea" value="${fn:trim(param.titulo)}" />

<%-- El estudiante propone para su propio nivel --%>
<c:choose>
    <c:when test="${esEstudiante}">
        <sql:query var="miNivel">
            SELECT nivel_id FROM usuarios WHERE id = ?
            <sql:param value="${sessionScope.usuario.id}" />
        </sql:query>
        <c:set var="nivel">${miNivel.rows[0].nivel_id}</c:set>
        <c:if test="${empty nivel}">
            <jsp:forward page="idea-form.jsp"><jsp:param name="error" value="sin-nivel" /></jsp:forward>
        </c:if>
    </c:when>
    <c:otherwise>
        <c:set var="nivel" value="${param.nivel}" />
    </c:otherwise>
</c:choose>

<c:if test="${empty tituloIdea or empty nivel}">
    <jsp:forward page="idea-form.jsp"><jsp:param name="error" value="faltan-datos" /></jsp:forward>
</c:if>

<sql:query var="periodoActivo">SELECT id FROM periodos WHERE estado = 'Activo' LIMIT 1</sql:query>
<c:set var="periodo">${periodoActivo.rowCount > 0 ? periodoActivo.rows[0].id : ''}</c:set>

<c:catch var="errorGuardar">
    <c:choose>
        <c:when test="${not editando}">
            <sql:update>
                INSERT INTO ideas (titulo, descripcion, nivel_id, modalidad_id, linea_investigacion_id, periodo_id, origen, propuesta_por)
                VALUES (?, NULLIF(?, ''), ?, NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), ?, ?)
                <sql:param value="${tituloIdea}" />
                <sql:param value="${fn:trim(param.descripcion)}" />
                <sql:param value="${nivel}" />
                <sql:param value="${param.modalidad}" />
                <sql:param value="${param.linea}" />
                <sql:param value="${periodo}" />
                <sql:param value="${origen}" />
                <sql:param value="${sessionScope.usuario.id}" />
            </sql:update>
        </c:when>
        <c:otherwise>
            <%-- Solo la idea propia, del mismo origen, pendiente o rechazada --%>
            <sql:update var="cambiados">
                UPDATE ideas
                SET titulo = ?, descripcion = NULLIF(?, ''), nivel_id = ?, modalidad_id = NULLIF(?, ''),
                    linea_investigacion_id = NULLIF(?, ''), estado = 'Pendiente', revisada_por = NULL,
                    observacion_revision = NULL
                WHERE id = ? AND propuesta_por = ? AND origen = ? AND estado IN ('Pendiente', 'Rechazada')
                <sql:param value="${tituloIdea}" />
                <sql:param value="${fn:trim(param.descripcion)}" />
                <sql:param value="${nivel}" />
                <sql:param value="${param.modalidad}" />
                <sql:param value="${param.linea}" />
                <sql:param value="${param.id}" />
                <sql:param value="${sessionScope.usuario.id}" />
                <sql:param value="${origen}" />
            </sql:update>
        </c:otherwise>
    </c:choose>
</c:catch>

<c:choose>
    <c:when test="${not empty errorGuardar}">
        <jsp:forward page="idea-form.jsp"><jsp:param name="error" value="general" /></jsp:forward>
    </c:when>
    <c:when test="${editando and cambiados == 0}">
        <c:redirect url="/ideas/banco.jsp">
            <c:param name="error" value="idea-no-editable" />
        </c:redirect>
    </c:when>
    <c:otherwise>
        <c:redirect url="/ideas/banco.jsp">
            <c:param name="ok" value="${editando ? 'idea-actualizada' : 'idea-creada'}" />
        </c:redirect>
    </c:otherwise>
</c:choose>
