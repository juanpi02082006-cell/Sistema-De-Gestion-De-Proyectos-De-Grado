<%-- PQR (RNF1): cualquier usuario, en cualquier fase, escribe una petición, queja o
     reclamo (por ejemplo, para pedir cambio de director o de evaluador) y ve las suyas
     con la respuesta del comité. Se liga al proyecto vigente del estudiante si lo tiene.
     El administrador no envía PQR: es el comité que las responde (admin/pqrs.jsp). --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<c:if test="${sessionScope.rolActivo.id == 1}">
    <c:redirect url="/admin/pqrs.jsp" />
</c:if>
<c:set var="titulo" value="PQR" />
<c:set var="seccion" value="pqr" />

<sql:query var="misPqrs">
    SELECT q.id, q.tipo, q.comentario, q.estado, q.respuesta, q.creado_en, q.respondida_en, p.titulo AS proyecto
    FROM pqrs q LEFT JOIN proyectos p ON p.id = q.proyecto_id
    WHERE q.usuario_id = ? ORDER BY q.creado_en DESC, q.id DESC
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <h1>PQR</h1>
    <p>Peticiones, quejas y reclamos al comité de trabajos de grado. Te responden por aquí y te llega un aviso.</p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="row g-4">
    <div class="col-lg-5">
        <form class="app-tarjeta app-formulario h-100" method="post" action="${ctx}/panel/pqr-guardar.jsp">
            <h2 class="app-tarjeta-titulo">Nueva PQR</h2>
            <label class="form-label" for="tipo">Tipo *</label>
            <select class="form-select" id="tipo" name="tipo" required>
                <c:forEach var="t" items="Petición,Queja,Reclamo,Cambio de director,Cambio de evaluador">
                    <option value="${t}" ${param.tipo == t ? 'selected' : ''}><c:out value="${t}" /></option>
                </c:forEach>
            </select>
            <label class="form-label mt-3" for="comentario">Cuéntanos *</label>
            <textarea class="form-control" id="comentario" name="comentario" maxlength="2000" required><c:out value="${param.comentario}" /></textarea>
            <button type="submit" class="btn btn-primary rounded-pill app-boton mt-3">Enviar</button>
        </form>
    </div>
    <div class="col-lg-7">
        <div class="app-tarjeta h-100">
            <h2 class="app-tarjeta-titulo">Mis PQR</h2>
            <c:choose>
                <c:when test="${misPqrs.rowCount == 0}"><p class="app-vacio mt-0">Todavía no has enviado ninguna.</p></c:when>
                <c:otherwise>
                    <ul class="app-lista">
                        <c:forEach var="q" items="${misPqrs.rows}">
                            <li class="d-block">
                                <span class="d-flex justify-content-between gap-2">
                                    <span class="app-lista-dato"><c:out value="${q.tipo}" /></span>
                                    <span class="app-estado ${q.estado == 'Respondida' ? 'activo' : 'inactivo'}"><c:out value="${q.estado}" /></span>
                                </span>
                                <span class="app-lista-nota"><fmt:formatDate value="${q.creado_en}" pattern="dd/MM/yyyy HH:mm" /><c:if test="${not empty q.proyecto}"> · <c:out value="${q.proyecto}" /></c:if></span>
                                <p class="mb-0 mt-2"><c:out value="${q.comentario}" /></p>
                                <c:if test="${not empty q.respuesta}">
                                    <p class="app-observacion"><strong>Respuesta del comité:</strong> <c:out value="${q.respuesta}" /></p>
                                </c:if>
                            </li>
                        </c:forEach>
                    </ul>
                </c:otherwise>
            </c:choose>
        </div>
    </div>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
