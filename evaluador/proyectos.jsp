<%-- Mis evaluaciones (evaluador): los proyectos que el comité le asignó para evaluar
     (RF11, RF23). La propuesta le llega en la fase 4, cuando el director la aprueba y
     se la envía; tiene 3 días hábiles para evaluarla con la rejilla del F-DC-124 (RF21).
     El informe final le llega en la fase 5 y tiene 5 días hábiles (rejilla del F-DC-129).
     En la fase final sale la fecha de la sustentación (RF39). Primero va lo que tiene
     por evaluar. --%>
<%@ include file="/WEB-INF/jspf/solo-evaluador.jspf" %>
<%@ include file="/WEB-INF/jspf/revision-propuesta.jspf" %>
<c:set var="titulo" value="Mis evaluaciones" />
<c:set var="seccion" value="evaluaciones" />

<sql:query var="proyectos">
    SELECT * FROM (
        SELECT p.id, p.codigo, p.titulo, p.estado, p.fecha_aprobacion_124, f.orden AS fase, f.nombre AS nombre_fase,
               m.nombre AS modalidad, n.nombre AS nivel, ${sqlUltimaRevision} AS ultima, ${sqlUltimaRevisionInforme} AS ultima_informe,
               (SELECT e.fecha_limite_revision FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124'
                ORDER BY e.version DESC LIMIT 1) AS limite,
               (SELECT e.fecha_limite_revision < CURDATE() FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-124'
                ORDER BY e.version DESC LIMIT 1) AS vencido,
               (SELECT e.fecha_limite_revision FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125'
                ORDER BY e.version DESC LIMIT 1) AS limite_informe,
               (SELECT e.fecha_limite_revision < CURDATE() FROM entregas e WHERE e.proyecto_id = p.id AND e.tipo = 'FDC-125'
                ORDER BY e.version DESC LIMIT 1) AS informe_vencido,
               (SELECT DATE(s.fecha_hora) FROM sustentaciones s WHERE s.proyecto_id = p.id) AS sustentacion,
               (SELECT TIME(s.fecha_hora) FROM sustentaciones s WHERE s.proyecto_id = p.id) AS sustentacion_hora
        FROM proyectos p
        JOIN modalidades m ON m.id = p.modalidad_id
        JOIN niveles n ON n.id = p.nivel_id
        LEFT JOIN fases f ON f.id = p.fase_id
        WHERE p.evaluador_id = ?
    ) t
    ORDER BY (((fase = 4 AND ultima = 'Director:Aprobado') OR (fase = 5 AND ultima_informe = 'Director:Aprobado'))
              AND estado NOT IN ('Finalizado', 'Cancelado')) DESC, fase, titulo
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <h1>Mis evaluaciones</h1>
    <p>Los proyectos que el comité te asignó. La propuesta te llega cuando el director la aprueba y te la envía.</p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="app-tarjeta">
    <c:choose>
        <c:when test="${proyectos.rowCount == 0}">
            <p class="app-vacio">Todavía no tienes proyectos para evaluar. El comité te los asigna.</p>
        </c:when>
        <c:otherwise>
            <div class="table-responsive">
                <table class="table app-tabla align-middle">
                    <thead>
                        <tr>
                            <th>Proyecto</th>
                            <th>Fase</th>
                            <th>Evaluación</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="p" items="${proyectos.rows}">
                            <c:set var="cerrado" value="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}" />
                            <c:set var="porEvaluar" value="${p.fase == 4 and p.ultima == 'Director:Aprobado' and not cerrado}" />
                            <c:set var="informePorEvaluar" value="${p.fase == 5 and p.ultima_informe == 'Director:Aprobado' and not cerrado}" />
                            <tr>
                                <td>
                                    <span class="fw-semibold"><c:out value="${p.titulo}" /></span>
                                    <span class="app-lista-nota"><c:if test="${not empty p.codigo}"><c:out value="${p.codigo}" /> · </c:if><c:out value="${p.modalidad}" /> · <c:out value="${p.nivel}" /></span>
                                </td>
                                <td class="text-nowrap">
                                    <c:choose><c:when test="${p.fase == 6}">Fase final</c:when><c:otherwise>Fase <c:out value="${p.fase}" /></c:otherwise></c:choose>
                                    <span class="app-lista-nota"><c:out value="${p.nombre_fase}" /></span>
                                </td>
                                <td>
                                    <c:choose>
                                        <c:when test="${cerrado}"><span class="app-estado inactivo"><c:out value="${p.estado}" /></span></c:when>
                                        <c:when test="${porEvaluar}">
                                            <span class="app-estado activo">Por evaluar</span>
                                            <span class="app-lista-nota">${p.vencido == 1 ? 'Plazo vencido el ' : 'Hasta el '}<fmt:formatDate value="${p.limite}" pattern="dd/MM/yyyy" /></span>
                                        </c:when>
                                        <c:when test="${informePorEvaluar}">
                                            <span class="app-estado activo">Informe final por evaluar</span>
                                            <span class="app-lista-nota">${p.informe_vencido == 1 ? 'Plazo vencido el ' : 'Hasta el '}<fmt:formatDate value="${p.limite_informe}" pattern="dd/MM/yyyy" /></span>
                                        </c:when>
                                        <c:when test="${p.fase == 6}">
                                            Informe final aprobado por el comité
                                            <span class="app-lista-nota"><c:choose><c:when test="${empty p.sustentacion}">Sustentación por programar</c:when><c:otherwise>Sustentación: <fmt:formatDate value="${p.sustentacion}" pattern="dd/MM/yyyy" /> <fmt:formatDate value="${p.sustentacion_hora}" pattern="h:mm a" /></c:otherwise></c:choose></span>
                                        </c:when>
                                        <c:when test="${p.fase == 5 and fn:startsWith(p.ultima_informe, 'Evaluador:')}">Informe evaluado · esperando al comité</c:when>
                                        <c:when test="${not empty p.fecha_aprobacion_124}">Propuesta aprobada por el comité</c:when>
                                        <c:when test="${p.ultima == 'Evaluador:Devuelto'}">Devuelta al director</c:when>
                                        <c:when test="${fn:startsWith(p.ultima, 'Evaluador:')}">Enviada · esperando al comité</c:when>
                                        <c:otherwise><span class="app-lista-nota d-inline">La propuesta todavía no te llega</span></c:otherwise>
                                    </c:choose>
                                </td>
                                <td class="text-end app-acciones">
                                    <a class="btn btn-sm ${porEvaluar or informePorEvaluar ? 'btn-primary' : 'btn-outline-dark'} rounded-pill" href="${ctx}/evaluador/proyecto.jsp?id=${p.id}">${porEvaluar or informePorEvaluar ? 'Evaluar' : 'Ver'}</a>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
            <p class="app-total">${proyectos.rowCount} ${proyectos.rowCount == 1 ? 'proyecto' : 'proyectos'}</p>
        </c:otherwise>
    </c:choose>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
