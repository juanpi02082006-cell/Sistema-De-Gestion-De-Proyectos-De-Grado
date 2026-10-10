<%-- Periodos académicos y su calendario (RF3). El comité (el administrador) los
     crea, los activa y los cierra. Solo puede haber un periodo activo: su calendario
     es el vigente para todos. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>
<c:set var="titulo" value="Periodos" />
<c:set var="seccion" value="periodos" />

<sql:query var="periodos">
    SELECT p.id, p.nombre, p.estado, p.fecha_inicio_semestre, p.fecha_cierre_banco, p.fecha_limite_pago,
           p.fecha_limite_propuestas, p.fecha_inicio_informe_final, p.fecha_fin_informe_final,
           (SELECT COUNT(*) FROM ideas i WHERE i.periodo_id = p.id) AS ideas,
           (SELECT COUNT(*) FROM proyectos pr WHERE pr.periodo_id = p.id) AS proyectos
    FROM periodos p
    ORDER BY p.nombre DESC
</sql:query>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado app-encabezado-acciones">
    <div>
        <h1>Periodos</h1>
        <p>Calendario de cada semestre. El periodo activo es el que ven todos en el calendario.</p>
    </div>
    <a class="btn btn-primary rounded-pill app-boton" href="${ctx}/admin/periodo-form.jsp">Nuevo periodo</a>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="app-tarjeta">
    <c:choose>
        <c:when test="${periodos.rowCount == 0}">
            <p class="app-vacio">Todavía no hay periodos. Crea el primero.</p>
        </c:when>
        <c:otherwise>
            <div class="table-responsive">
                <table class="table app-tabla align-middle">
                    <thead>
                        <tr>
                            <th>Periodo</th>
                            <th>Estado</th>
                            <th>Inicio</th>
                            <th>Cierre del banco</th>
                            <th>Límite de pago</th>
                            <th>Límite de propuestas</th>
                            <th>Informe final</th>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="p" items="${periodos.rows}">
                            <tr>
                                <td class="fw-semibold"><c:out value="${p.nombre}" /></td>
                                <td><span class="app-estado ${p.estado == 'Activo' ? 'activo' : 'inactivo'}"><c:out value="${p.estado}" /></span></td>
                                <td><fmt:formatDate value="${p.fecha_inicio_semestre}" pattern="dd/MM/yyyy" /></td>
                                <td><fmt:formatDate value="${p.fecha_cierre_banco}" pattern="dd/MM/yyyy" /></td>
                                <td><fmt:formatDate value="${p.fecha_limite_pago}" pattern="dd/MM/yyyy" /></td>
                                <td><fmt:formatDate value="${p.fecha_limite_propuestas}" pattern="dd/MM/yyyy" /></td>
                                <td>
                                    <fmt:formatDate value="${p.fecha_inicio_informe_final}" pattern="dd/MM/yyyy" />
                                    <c:if test="${not empty p.fecha_inicio_informe_final or not empty p.fecha_fin_informe_final}"> – </c:if>
                                    <fmt:formatDate value="${p.fecha_fin_informe_final}" pattern="dd/MM/yyyy" />
                                </td>
                                <td class="text-end app-acciones">
                                    <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/admin/sesiones.jsp?periodo=${p.id}">Sesiones</a>
                                    <a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/admin/periodo-form.jsp?id=${p.id}">Editar</a>
                                    <form method="post" action="${ctx}/admin/periodo-estado.jsp" class="d-inline">
                                        <input type="hidden" name="id" value="${p.id}">
                                        <c:choose>
                                            <c:when test="${p.estado == 'Activo'}">
                                                <input type="hidden" name="accion" value="cerrar">
                                                <button type="submit" class="btn btn-sm btn-outline-dark rounded-pill">Cerrar</button>
                                            </c:when>
                                            <c:otherwise>
                                                <input type="hidden" name="accion" value="activar">
                                                <button type="submit" class="btn btn-sm btn-primary rounded-pill">Activar</button>
                                            </c:otherwise>
                                        </c:choose>
                                    </form>
                                    <c:if test="${p.ideas == 0 and p.proyectos == 0}">
                                        <form method="post" action="${ctx}/admin/periodo-eliminar.jsp" class="d-inline"
                                              onsubmit="return confirm('¿Eliminar este periodo?');">
                                            <input type="hidden" name="id" value="${p.id}">
                                            <button type="submit" class="btn btn-sm btn-outline-danger rounded-pill">Eliminar</button>
                                        </form>
                                    </c:if>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
            <p class="app-total">${periodos.rowCount} ${periodos.rowCount == 1 ? 'periodo' : 'periodos'}</p>
        </c:otherwise>
    </c:choose>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
