<%-- Calendario académico vigente (RF3), para todos los roles: las fechas del
     periodo activo y el calendario de sesiones del comité (RF16). --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<c:set var="titulo" value="Calendario" />
<c:set var="seccion" value="calendario" />

<sql:query var="consulta">
    SELECT id, nombre, fecha_inicio_semestre, fecha_cierre_banco, fecha_limite_pago, fecha_limite_propuestas,
           fecha_inicio_informe_final, fecha_fin_informe_final,
           (fecha_cierre_banco IS NULL OR CURDATE() <= fecha_cierre_banco) AS banco_abierto
    FROM periodos WHERE estado = 'Activo'
    LIMIT 1
</sql:query>
<c:set var="p" value="${consulta.rows[0]}" />
<c:if test="${consulta.rowCount > 0}">
    <sql:query var="sesiones">
        SELECT fecha, hora, lugar, fecha < CURDATE() AS pasada FROM sesiones_comite WHERE periodo_id = ? ORDER BY fecha
        <sql:param value="${p.id}" />
    </sql:query>
</c:if>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <h1>Calendario</h1>
    <p>Fechas del proceso de trabajo de grado en el periodo vigente.</p>
</section>

<c:choose>
    <c:when test="${consulta.rowCount == 0}">
        <div class="app-tarjeta">
            <p class="app-vacio mt-0">Todavía no hay un periodo activo. El comité lo publica al iniciar el semestre.</p>
        </div>
    </c:when>
    <c:otherwise>
        <div class="app-tarjeta">
            <h2 class="app-tarjeta-titulo">Periodo <c:out value="${p.nombre}" /></h2>
            <ul class="app-lista">
                <li>
                    <span><span class="app-lista-dato">Inicio del semestre</span></span>
                    <span><fmt:formatDate value="${p.fecha_inicio_semestre}" pattern="dd/MM/yyyy" /><c:if test="${empty p.fecha_inicio_semestre}">Por definir</c:if></span>
                </li>
                <li>
                    <span>
                        <span class="app-lista-dato">Cierre del banco de ideas</span>
                        <span class="app-lista-nota">Semana 4. Hasta esta fecha se pueden tomar ideas.</span>
                    </span>
                    <span>
                        <fmt:formatDate value="${p.fecha_cierre_banco}" pattern="dd/MM/yyyy" /><c:if test="${empty p.fecha_cierre_banco}">Por definir</c:if>
                        <span class="app-requisito ${p.banco_abierto == 1 ? 'cumple' : ''} ms-2">${p.banco_abierto == 1 ? 'Abierto' : 'Cerrado'}</span>
                    </span>
                </li>
                <li>
                    <span>
                        <span class="app-lista-dato">Límite de pago</span>
                        <span class="app-lista-nota">Semana 8. El pago solo vale para este periodo.</span>
                    </span>
                    <span><fmt:formatDate value="${p.fecha_limite_pago}" pattern="dd/MM/yyyy" /><c:if test="${empty p.fecha_limite_pago}">Por definir</c:if></span>
                </li>
                <li>
                    <span>
                        <span class="app-lista-dato">Límite para aprobar la propuesta</span>
                        <span class="app-lista-nota">Semana 12. Si no se aprueba, pasa al siguiente semestre.</span>
                    </span>
                    <span><fmt:formatDate value="${p.fecha_limite_propuestas}" pattern="dd/MM/yyyy" /><c:if test="${empty p.fecha_limite_propuestas}">Por definir</c:if></span>
                </li>
                <li>
                    <span>
                        <span class="app-lista-dato">Entrega del informe final</span>
                        <span class="app-lista-nota">Entre 90 y 180 días después de que el comité aprueba el FDC-124.</span>
                    </span>
                    <span>
                        <c:choose>
                            <c:when test="${empty p.fecha_inicio_informe_final and empty p.fecha_fin_informe_final}">Por definir</c:when>
                            <c:otherwise>
                                <fmt:formatDate value="${p.fecha_inicio_informe_final}" pattern="dd/MM/yyyy" /> – <fmt:formatDate value="${p.fecha_fin_informe_final}" pattern="dd/MM/yyyy" />
                            </c:otherwise>
                        </c:choose>
                    </span>
                </li>
            </ul>
        </div>

        <div class="app-tarjeta mt-4">
            <h2 class="app-tarjeta-titulo">Sesiones del comité</h2>
            <c:choose>
                <c:when test="${sesiones.rowCount == 0}">
                    <p class="app-vacio mt-0">El comité todavía no ha publicado su calendario de sesiones.</p>
                </c:when>
                <c:otherwise>
                    <ul class="app-lista">
                        <c:forEach var="s" items="${sesiones.rows}">
                            <li>
                                <span>
                                    <span class="app-lista-dato"><fmt:formatDate value="${s.fecha}" pattern="EEEE d 'de' MMMM" /></span>
                                    <span class="app-lista-nota">
                                        <c:if test="${not empty s.hora}"><fmt:formatDate value="${s.hora}" pattern="h:mm a" /></c:if>
                                        <c:if test="${not empty s.hora and not empty s.lugar}"> · </c:if>
                                        <c:out value="${s.lugar}" />
                                    </span>
                                </span>
                                <span class="app-requisito ${s.pasada == 1 ? '' : 'cumple'}">${s.pasada == 1 ? 'Realizada' : 'Próxima'}</span>
                            </li>
                        </c:forEach>
                    </ul>
                </c:otherwise>
            </c:choose>
        </div>
    </c:otherwise>
</c:choose>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
