<%-- Editar la descripción y el máximo de integrantes de una modalidad (RF4, RF36).
     Las modalidades son las del reglamento: no se crean ni se eliminan aquí. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>

<sql:query var="consulta">
    SELECT id, nombre, descripcion, max_integrantes FROM modalidades WHERE id = ?
    <sql:param value="${param.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/panel/modalidades.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="m" value="${consulta.rows[0]}" />
<c:set var="reintento" value="${not empty param.error}" />
<c:set var="vDescripcion" value="${reintento ? param.descripcion : m.descripcion}" />
<c:set var="vMaximo">${reintento ? param.max_integrantes : m.max_integrantes}</c:set>

<c:set var="titulo" value="Editar modalidad" />
<c:set var="seccion" value="modalidades" />
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <a class="app-volver" href="${ctx}/panel/modalidades.jsp">← Volver a modalidades</a>
    <h1><c:out value="${m.nombre}" /></h1>
</section>

<c:if test="${reintento}">
    <div class="alert alert-danger app-aviso" role="alert">El máximo de integrantes debe ser 1, 2, 3 o 4.</div>
</c:if>

<form class="app-tarjeta app-formulario" method="post" action="${ctx}/admin/modalidad-guardar.jsp">
    <input type="hidden" name="id" value="${m.id}">
    <div class="row g-3">
        <div class="col-12">
            <label class="form-label" for="descripcion">Descripción</label>
            <textarea class="form-control" id="descripcion" name="descripcion" rows="5"><c:out value="${vDescripcion}" /></textarea>
        </div>
        <div class="col-md-4">
            <label class="form-label" for="max_integrantes">Máximo de integrantes *</label>
            <select class="form-select" id="max_integrantes" name="max_integrantes" required>
                <c:forEach var="n" begin="1" end="4">
                    <c:set var="nTexto">${n}</c:set>
                    <option value="${n}" ${nTexto == vMaximo ? 'selected' : ''}>${n == 1 ? 'Individual (1)' : n}</option>
                </c:forEach>
            </select>
            <div class="form-text">Reglamento: individual o hasta 2; hasta 3 en investigación y desarrollo tecnológico.</div>
        </div>
    </div>

    <div class="app-formulario-botones">
        <a class="btn btn-outline-dark rounded-pill app-boton" href="${ctx}/panel/modalidades.jsp">Cancelar</a>
        <button type="submit" class="btn btn-primary rounded-pill app-boton">Guardar</button>
    </div>
</form>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
