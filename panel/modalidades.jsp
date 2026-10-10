<%-- Información de las modalidades de grado (RF4), para todos los roles. Son las
     del reglamento menos Práctica. El administrador puede editar su descripción y
     su máximo de integrantes. --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<c:set var="titulo" value="Modalidades" />
<c:set var="seccion" value="modalidades" />

<sql:query var="modalidades">
    SELECT id, nombre, descripcion, max_integrantes FROM modalidades ORDER BY id
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <h1>Modalidades de grado</h1>
    <p>Para todas se necesita, en los planes anteriores, el 75 % de los créditos y Metodología de la investigación aprobada; en los planes nuevos, la matrícula de Seminario de Grado I o III.</p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="row g-4">
    <c:forEach var="m" items="${modalidades.rows}">
        <div class="col-md-6 col-lg-4">
            <div class="app-ficha">
                <h3><c:out value="${m.nombre}" /></h3>
                <div class="app-ficha-datos">
                    <span class="app-etiqueta ms-0">
                        <c:choose>
                            <c:when test="${m.max_integrantes == 1}">Individual</c:when>
                            <c:otherwise>Individual o hasta ${m.max_integrantes} estudiantes</c:otherwise>
                        </c:choose>
                    </span>
                    <c:if test="${m.id == 1 or m.id == 2}">
                        <span class="app-etiqueta ms-0">Interdisciplinario: hasta 4</span>
                    </c:if>
                    <c:if test="${m.id == 5}">
                        <span class="app-etiqueta ms-0">Sin prórroga</span>
                    </c:if>
                </div>
                <p><c:out value="${m.descripcion}" /></p>
                <c:if test="${sessionScope.rolActivo.id == 1}">
                    <div class="app-ficha-pie">
                        <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/admin/modalidad-form.jsp?id=${m.id}">Editar</a>
                    </div>
                </c:if>
            </div>
        </div>
    </c:forEach>
</div>

<p class="app-total">La modalidad Práctica y el nivel Técnico Profesional no están en el sistema.</p>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
