<%-- Avisos del usuario (RF5): cada movimiento de sus proyectos y las alertas de
     vencimiento (RNF21). No se envían correos. Al abrir un aviso queda leído. --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<c:set var="titulo" value="Avisos" />
<c:set var="seccion" value="avisos" />

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="avisos">
    SELECT id, mensaje, enlace, leido, creado_en FROM avisos
    WHERE usuario_id = ? ORDER BY creado_en DESC, id DESC LIMIT 100
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>

<section class="app-encabezado app-encabezado-acciones">
    <div>
        <h1>Avisos</h1>
        <p>Lo que ha pasado en tus proyectos y los plazos que se acercan.</p>
    </div>
    <c:if test="${totalAvisos > 0}">
        <form method="post" action="${ctx}/panel/avisos-leer.jsp">
            <button type="submit" class="btn btn-outline-dark rounded-pill">Marcar todos como leídos</button>
        </form>
    </c:if>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="app-tarjeta">
    <c:choose>
        <c:when test="${avisos.rowCount == 0}">
            <p class="app-vacio mt-0">No tienes avisos.</p>
        </c:when>
        <c:otherwise>
            <c:forEach var="a" items="${avisos.rows}">
                <div class="app-aviso-item ${a.leido == true ? '' : 'nuevo'}">
                    <span class="app-aviso-marca" aria-hidden="true"></span>
                    <span>
                        <span class="app-aviso-texto d-block">
                            <c:choose>
                                <c:when test="${not empty a.enlace}"><a href="${ctx}/panel/aviso-abrir.jsp?id=${a.id}"><c:out value="${a.mensaje}" /></a></c:when>
                                <c:otherwise><c:out value="${a.mensaje}" /></c:otherwise>
                            </c:choose>
                            <c:if test="${a.leido != true}"><span class="visually-hidden">(sin leer)</span></c:if>
                        </span>
                        <span class="app-lista-nota"><fmt:formatDate value="${a.creado_en}" pattern="dd/MM/yyyy h:mm a" /></span>
                    </span>
                </div>
            </c:forEach>
        </c:otherwise>
    </c:choose>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
