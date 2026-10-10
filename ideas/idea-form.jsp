<%-- Registrar (sin id) o editar (con ?id=) una idea del banco (RF10). La registran
     los docentes (Director o Evaluador); el estudiante formula aquí su propia
     propuesta, de su nivel. Solo se editan las ideas propias pendientes o rechazadas.
     Si idea-guardar.jsp encuentra un error, vuelve aquí con ?error=... --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<c:set var="rol" value="${sessionScope.rolActivo.id}" />
<c:set var="esEstudiante" value="${rol == 5}" />
<c:if test="${not (rol == 3 or rol == 4 or rol == 5)}">
    <c:redirect url="/ideas/banco.jsp">
        <c:param name="error" value="denegado" />
    </c:redirect>
</c:if>

<c:set var="editando" value="${not empty param.id}" />
<c:set var="reintento" value="${not empty param.error}" />

<c:if test="${editando}">
    <sql:query var="consulta">
        SELECT id, titulo, descripcion, nivel_id, modalidad_id, linea_investigacion_id
        FROM ideas
        WHERE id = ? AND propuesta_por = ? AND origen = ? AND estado IN ('Pendiente', 'Rechazada')
        <sql:param value="${param.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="${esEstudiante ? 'Estudiante' : 'Docente'}" />
    </sql:query>
    <c:if test="${consulta.rowCount == 0}">
        <c:redirect url="/ideas/banco.jsp">
            <c:param name="error" value="idea-no-editable" />
        </c:redirect>
    </c:if>
    <c:set var="i" value="${consulta.rows[0]}" />
</c:if>

<sql:query var="niveles">SELECT id, nombre FROM niveles ORDER BY id</sql:query>
<sql:query var="modalidades">SELECT id, nombre FROM modalidades ORDER BY id</sql:query>
<sql:query var="lineas">SELECT id, nombre FROM lineas_investigacion ORDER BY nombre</sql:query>
<c:if test="${esEstudiante}">
    <sql:query var="miNivel">
        SELECT n.id, n.nombre FROM usuarios u JOIN niveles n ON n.id = u.nivel_id WHERE u.id = ?
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
</c:if>

<c:set var="vTitulo" value="${reintento ? param.titulo : i.titulo}" />
<c:set var="vDescripcion" value="${reintento ? param.descripcion : i.descripcion}" />
<c:set var="vNivel">${reintento ? param.nivel : i.nivel_id}</c:set>
<c:set var="vModalidad">${reintento ? param.modalidad : i.modalidad_id}</c:set>
<c:set var="vLinea">${reintento ? param.linea : i.linea_investigacion_id}</c:set>

<c:set var="titulo" value="${esEstudiante ? (editando ? 'Editar mi propuesta' : 'Formular mi propuesta') : (editando ? 'Editar idea' : 'Registrar idea')}" />
<c:set var="seccion" value="ideas" />
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <a class="app-volver" href="${ctx}/ideas/banco.jsp">← Volver al banco de ideas</a>
    <h1><c:out value="${titulo}" /></h1>
    <p>${esEstudiante ? 'Tu propuesta queda pendiente hasta que el comité la apruebe.' : 'La idea queda pendiente hasta que el comité la apruebe; después aparece en el banco para los estudiantes de su nivel.'}</p>
</section>

<c:if test="${reintento}">
    <div class="alert alert-danger app-aviso" role="alert">
        <c:choose>
            <c:when test="${param.error == 'faltan-datos'}">Escribe el título y escoge el nivel.</c:when>
            <c:when test="${param.error == 'sin-nivel'}">No tienes un nivel registrado. Pídele al administrador que lo actualice.</c:when>
            <c:otherwise>No se pudo guardar. Revisa los datos e inténtalo de nuevo.</c:otherwise>
        </c:choose>
    </div>
</c:if>

<form class="app-tarjeta app-formulario" method="post" action="${ctx}/ideas/idea-guardar.jsp">
    <c:if test="${editando}">
        <input type="hidden" name="id" value="${fn:escapeXml(param.id)}">
    </c:if>
    <div class="row g-3">
        <div class="col-12">
            <label class="form-label" for="titulo">Título *</label>
            <input class="form-control" type="text" id="titulo" name="titulo" maxlength="255" value="${fn:escapeXml(vTitulo)}" required>
        </div>
        <div class="col-12">
            <label class="form-label" for="descripcion">Descripción</label>
            <textarea class="form-control" id="descripcion" name="descripcion" rows="5"><c:out value="${vDescripcion}" /></textarea>
            <div class="form-text">Qué problema resuelve y qué se espera obtener.</div>
        </div>
        <div class="col-md-4">
            <label class="form-label" for="nivel">Nivel *</label>
            <c:choose>
                <c:when test="${esEstudiante}">
                    <input class="form-control" type="text" id="nivel" value="${miNivel.rowCount == 0 ? 'Sin nivel' : miNivel.rows[0].nombre}" disabled>
                    <div class="form-text">Tu propuesta es de tu nivel.</div>
                </c:when>
                <c:otherwise>
                    <select class="form-select" id="nivel" name="nivel" required>
                        <option value="">Escoge el nivel</option>
                        <c:forEach var="n" items="${niveles.rows}">
                            <c:set var="idNivel">${n.id}</c:set>
                            <option value="${n.id}" ${idNivel == vNivel ? 'selected' : ''}><c:out value="${n.nombre}" /></option>
                        </c:forEach>
                    </select>
                    <div class="form-text">Un estudiante de tecnología no puede tomar ideas de ingeniería.</div>
                </c:otherwise>
            </c:choose>
        </div>
        <div class="col-md-4">
            <label class="form-label" for="modalidad">Modalidad</label>
            <select class="form-select" id="modalidad" name="modalidad">
                <option value="">Sin definir</option>
                <c:forEach var="m" items="${modalidades.rows}">
                    <c:set var="idModalidad">${m.id}</c:set>
                    <option value="${m.id}" ${idModalidad == vModalidad ? 'selected' : ''}><c:out value="${m.nombre}" /></option>
                </c:forEach>
            </select>
            <div class="form-text">Si no se define, el estudiante la escoge al tomar la idea.</div>
        </div>
        <div class="col-md-4">
            <label class="form-label" for="linea">Línea de investigación</label>
            <select class="form-select" id="linea" name="linea">
                <option value="">Sin definir</option>
                <c:forEach var="l" items="${lineas.rows}">
                    <c:set var="idLinea">${l.id}</c:set>
                    <option value="${l.id}" ${idLinea == vLinea ? 'selected' : ''}><c:out value="${l.nombre}" /></option>
                </c:forEach>
            </select>
        </div>
    </div>

    <div class="app-formulario-botones">
        <a class="btn btn-outline-dark rounded-pill app-boton" href="${ctx}/ideas/banco.jsp">Cancelar</a>
        <button type="submit" class="btn btn-primary rounded-pill app-boton">${esEstudiante ? 'Enviar propuesta' : 'Guardar idea'}</button>
    </div>
</form>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
