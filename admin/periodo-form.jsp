<%-- Crear (sin id) o editar (con ?id=) un periodo y sus fechas (RF3): banco de
     ideas hasta la semana 4, pago hasta la 8, propuestas hasta la 12 y fechas del
     informe final. Si periodo-guardar.jsp encuentra un error, vuelve aquí con
     ?error=... y con los datos que se habían escrito. --%>
<%@ include file="/WEB-INF/jspf/solo-admin.jspf" %>

<c:set var="editando" value="${not empty param.id}" />
<c:set var="reintento" value="${not empty param.error}" />

<c:if test="${editando}">
    <sql:query var="consulta">
        SELECT id, nombre, fecha_inicio_semestre, fecha_cierre_banco, fecha_limite_pago, fecha_limite_propuestas,
               fecha_inicio_informe_final, fecha_fin_informe_final
        FROM periodos WHERE id = ?
        <sql:param value="${param.id}" />
    </sql:query>
    <c:if test="${consulta.rowCount == 0}">
        <c:redirect url="/admin/periodos.jsp">
            <c:param name="error" value="no-encontrado" />
        </c:redirect>
    </c:if>
    <c:set var="p" value="${consulta.rows[0]}" />
</c:if>

<%-- Las fechas van al formulario como aaaa-mm-dd (formato del campo de fecha) --%>
<c:set var="campos" value="fecha_inicio_semestre,fecha_cierre_banco,fecha_limite_pago,fecha_limite_propuestas,fecha_inicio_informe_final,fecha_fin_informe_final" />
<jsp:useBean id="valores" class="java.util.HashMap" />
<c:forTokens var="campo" items="${campos}" delims=",">
    <c:choose>
        <c:when test="${reintento}"><c:set target="${valores}" property="${campo}" value="${param[campo]}" /></c:when>
        <c:otherwise>
            <c:set var="fechaTexto"><fmt:formatDate value="${p[campo]}" pattern="yyyy-MM-dd" /></c:set>
            <c:set target="${valores}" property="${campo}" value="${fechaTexto}" />
        </c:otherwise>
    </c:choose>
</c:forTokens>
<c:set var="vNombre" value="${reintento ? param.nombre : p.nombre}" />

<c:set var="titulo" value="${editando ? 'Editar periodo' : 'Nuevo periodo'}" />
<c:set var="seccion" value="periodos" />
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <a class="app-volver" href="${ctx}/admin/periodos.jsp">← Volver a periodos</a>
    <h1><c:out value="${titulo}" /></h1>
</section>

<c:if test="${reintento}">
    <div class="alert alert-danger app-aviso" role="alert">
        <c:choose>
            <c:when test="${param.error == 'faltan-datos'}">Escribe el nombre del periodo.</c:when>
            <c:when test="${param.error == 'fecha-invalida'}">Alguna fecha no es válida. Usa el formato aaaa-mm-dd.</c:when>
            <c:when test="${param.error == 'fechas-informe'}">La fecha de inicio del informe final debe ser anterior a la de fin.</c:when>
            <c:when test="${param.error == 'nombre-duplicado'}">Ya existe un periodo con ese nombre.</c:when>
            <c:otherwise>No se pudo guardar el periodo. Revisa los datos e inténtalo de nuevo.</c:otherwise>
        </c:choose>
    </div>
</c:if>

<form class="app-tarjeta app-formulario" method="post" action="${ctx}/admin/periodo-guardar.jsp">
    <c:if test="${editando}">
        <input type="hidden" name="id" value="${fn:escapeXml(param.id)}">
    </c:if>

    <div class="row g-3">
        <div class="col-md-4">
            <label class="form-label" for="nombre">Periodo *</label>
            <input class="form-control" type="text" id="nombre" name="nombre" maxlength="10" value="${fn:escapeXml(vNombre)}" placeholder="2026-2" required>
            <div class="form-text">Año y semestre, por ejemplo 2026-2.</div>
        </div>
        <div class="col-md-4">
            <label class="form-label" for="fecha_inicio_semestre">Inicio del semestre</label>
            <input class="form-control" type="date" id="fecha_inicio_semestre" name="fecha_inicio_semestre" value="${fn:escapeXml(valores.fecha_inicio_semestre)}">
        </div>
    </div>

    <h2 class="app-tarjeta-titulo mt-4">Fechas del proceso</h2>
    <div class="row g-3">
        <div class="col-md-4">
            <label class="form-label" for="fecha_cierre_banco">Cierre del banco de ideas</label>
            <input class="form-control" type="date" id="fecha_cierre_banco" name="fecha_cierre_banco" value="${fn:escapeXml(valores.fecha_cierre_banco)}">
            <div class="form-text">Semana 4. Después no se pueden tomar ideas.</div>
        </div>
        <div class="col-md-4">
            <label class="form-label" for="fecha_limite_pago">Límite de pago</label>
            <input class="form-control" type="date" id="fecha_limite_pago" name="fecha_limite_pago" value="${fn:escapeXml(valores.fecha_limite_pago)}">
            <div class="form-text">Semana 8.</div>
        </div>
        <div class="col-md-4">
            <label class="form-label" for="fecha_limite_propuestas">Límite para aprobar propuestas</label>
            <input class="form-control" type="date" id="fecha_limite_propuestas" name="fecha_limite_propuestas" value="${fn:escapeXml(valores.fecha_limite_propuestas)}">
            <div class="form-text">Semana 12.</div>
        </div>
        <div class="col-md-4">
            <label class="form-label" for="fecha_inicio_informe_final">Inicio de entrega del informe final</label>
            <input class="form-control" type="date" id="fecha_inicio_informe_final" name="fecha_inicio_informe_final" value="${fn:escapeXml(valores.fecha_inicio_informe_final)}">
        </div>
        <div class="col-md-4">
            <label class="form-label" for="fecha_fin_informe_final">Fin de entrega del informe final</label>
            <input class="form-control" type="date" id="fecha_fin_informe_final" name="fecha_fin_informe_final" value="${fn:escapeXml(valores.fecha_fin_informe_final)}">
        </div>
    </div>

    <div class="app-formulario-botones">
        <a class="btn btn-outline-dark rounded-pill app-boton" href="${ctx}/admin/periodos.jsp">Cancelar</a>
        <button type="submit" class="btn btn-primary rounded-pill app-boton">Guardar</button>
    </div>
</form>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
