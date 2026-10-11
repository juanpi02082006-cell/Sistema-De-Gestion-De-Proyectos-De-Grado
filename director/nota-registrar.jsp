<%-- El docente del seminario (el director del proyecto) registra la nota final, por
     POST (RF17; proceso entregado por el equipo el 2026-10-10: al terminar las clases y
     el entregable, el docente registra la nota). Solo para Seminario en curso, con
     observación obligatoria (RF34). Nota de 0.0 a 5.0, con punto o coma; se aprueba con
     3.0 o más (supuesto: la escala usual; el texto del equipo dice "nota aprobatoria").
       aprobada   el proyecto termina ("Finalizado") y el requisito queda cumplido;
       reprobada  el proyecto se cancela y los estudiantes quedan libres para empezar de
                  nuevo. --%>
<%@ include file="/WEB-INF/jspf/solo-director.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/director/proyectos.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.titulo, p.estado, p.modalidad_id FROM proyectos p WHERE p.id = ? AND p.director_id = ?
    <sql:param value="${empty param.id ? 0 : param.id}" />
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/director/proyectos.jsp">
        <c:param name="error" value="no-encontrado" />
    </c:redirect>
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="observacion" value="${fn:trim(param.observacion)}" />

<%-- Nota: número de 0 a 5 (acepta coma o punto) --%>
<c:set var="notaTexto" value="${fn:replace(fn:trim(param.nota), ',', '.')}" />
<c:set var="notaValida" value="false" />
<%-- Formato estricto (dígitos y a lo sumo un decimal): fmt:parseNumber aceptaría "4.5abc" --%>
<sql:query var="formatoNota">
    SELECT (? REGEXP '^[0-9]([.][0-9]+)?$') AS valido
    <sql:param value="${notaTexto}" />
</sql:query>
<c:if test="${not empty notaTexto and formatoNota.rows[0].valido == 1}">
    <c:catch var="errorNota">
        <fmt:parseNumber var="notaNumero" value="${notaTexto}" parseLocale="en_US" />
    </c:catch>
    <c:set var="notaValida" value="${empty errorNota and not fn:contains(notaTexto, ' ') and notaNumero >= 0 and notaNumero <= 5}" />
</c:if>

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.modalidad_id != 5}"><c:set var="motivo" value="nota-no-aplica" /></c:when>
    <c:when test="${p.estado != 'En curso'}"><c:set var="motivo" value="nota-no-aplica" /></c:when>
    <c:when test="${not notaValida}"><c:set var="motivo" value="nota-invalida" /></c:when>
    <c:when test="${empty observacion}"><c:set var="motivo" value="observacion-requerida" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/director/proyecto.jsp">
        <c:param name="id" value="${p.id}" />
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>
<c:set var="aprobado" value="${notaNumero >= 3}" />
<fmt:formatNumber var="notaMostrada" value="${notaNumero}" minFractionDigits="1" maxFractionDigits="1" />

<sql:transaction>
    <sql:update>
        UPDATE proyectos SET nota_final = ROUND(?, 1), estado = ? WHERE id = ? AND estado = 'En curso'
        <sql:param value="${notaTexto}" />
        <sql:param value="${aprobado ? 'Finalizado' : 'Cancelado'}" />
        <sql:param value="${p.id}" />
    </sql:update>
    <sql:update>
        INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Evaluación', ?)
        <sql:param value="${p.id}" />
        <sql:param value="${sessionScope.usuario.id}" />
        <sql:param value="El docente registró la nota final del seminario: ${notaMostrada} (${aprobado ? 'aprobado; el proyecto terminó' : 'reprobado; el proyecto se canceló'}). Observación: ${fn:substring(observacion, 0, 120)}" />
    </sql:update>
    <c:set var="avisoProyecto" value="${p.id}" />
    <c:set var="avisoMensaje">Nota final del seminario: ${notaMostrada}. ${aprobado ? 'Aprobaste: el requisito de trabajo de grado quedó cumplido.' : 'No se aprobó: el proyecto se canceló y puedes empezar de nuevo.'} Observación: ${observacion}</c:set>
    <c:set var="avisoPara" value="estudiantes,comite" />
    <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
    <c:if test="${not aprobado}">
        <sql:update>
            UPDATE proyecto_estudiantes SET vigente = NULL WHERE proyecto_id = ? AND vigente = 1
            <sql:param value="${p.id}" />
        </sql:update>
    </c:if>
</sql:transaction>

<c:redirect url="/director/proyecto.jsp">
    <c:param name="id" value="${p.id}" />
    <c:param name="ok" value="${aprobado ? 'nota-aprobada' : 'nota-reprobada'}" />
</c:redirect>
