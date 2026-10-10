<%-- Calendario de sesiones del comité de un periodo (RF3, RF16): el comité publica
     al inicio del periodo las fechas en que sesiona. ?periodo=id --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:set var="titulo" value="Sesiones del comité" />
<c:set var="seccion" value="periodos" />

<sql:query var="consultaPeriodo">
    SELECT id, nombre FROM periodos WHERE id = ?
    <sql:param value="${empty param.periodo ? 0 : param.periodo}" />
</sql:query>
<c:if test="${consultaPeriodo.rowCount == 0}">
    <c:redirect url="/admin/periodos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="periodo" value="${consultaPeriodo.rows[0]}" />
<sql:query var="sesiones">
    SELECT id, fecha, hora, lugar FROM sesiones_comite WHERE periodo_id = ? ORDER BY fecha
    <sql:param value="${periodo.id}" />
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <a class="app-volver" href="${ctx}/admin/periodos.jsp">← Volver a periodos</a>
    <h1>Sesiones del comité · <c:out value="${periodo.nombre}" /></h1>
    <p>El comité sesiona cada semana; estas fechas salen en el calendario de todos.</p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="row g-4">
    <div class="col-lg-7">
        <div class="app-tarjeta h-100">
            <h2 class="app-tarjeta-titulo">Sesiones</h2>
            <c:choose>
                <c:when test="${sesiones.rowCount == 0}">
                    <p class="app-vacio mt-0">Todavía no hay sesiones en este periodo.</p>
                </c:when>
                <c:otherwise>
                    <ul class="app-lista">
                        <c:forEach var="s" items="${sesiones.rows}">
                            <li>
                                <span>
                                    <span class="app-lista-dato"><fmt:formatDate value="${s.fecha}" pattern="EEEE d 'de' MMMM 'de' yyyy" /></span>
                                    <span class="app-lista-nota">
                                        <c:if test="${not empty s.hora}"><fmt:formatDate value="${s.hora}" pattern="h:mm a" /></c:if>
                                        <c:if test="${not empty s.hora and not empty s.lugar}"> · </c:if>
                                        <c:out value="${s.lugar}" />
                                    </span>
                                </span>
                                <form method="post" action="${ctx}/admin/sesion-eliminar.jsp" class="d-inline"
                                      onsubmit="return confirm('¿Quitar esta sesión del calendario?');">
                                    <input type="hidden" name="id" value="${s.id}">
                                    <input type="hidden" name="periodo" value="${periodo.id}">
                                    <button type="submit" class="btn btn-sm btn-outline-danger rounded-pill">Quitar</button>
                                </form>
                            </li>
                        </c:forEach>
                    </ul>
                </c:otherwise>
            </c:choose>
        </div>
    </div>
    <div class="col-lg-5">
        <form class="app-tarjeta app-formulario h-100" method="post" action="${ctx}/admin/sesion-guardar.jsp">
            <h2 class="app-tarjeta-titulo">Agregar sesión</h2>
            <input type="hidden" name="periodo" value="${periodo.id}">
            <div class="row g-3">
                <div class="col-md-7">
                    <label class="form-label" for="fecha">Fecha *</label>
                    <input class="form-control" type="date" id="fecha" name="fecha" required>
                </div>
                <div class="col-md-5">
                    <label class="form-label" for="hora">Hora</label>
                    <input class="form-control" type="time" id="hora" name="hora">
                </div>
                <div class="col-12">
                    <label class="form-label" for="lugar">Lugar</label>
                    <input class="form-control" type="text" id="lugar" name="lugar" maxlength="150" placeholder="Sala o enlace de la reunión">
                </div>
            </div>
            <div class="app-formulario-botones">
                <button type="submit" class="btn btn-primary rounded-pill app-boton">Agregar</button>
            </div>
        </form>
    </div>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
