<%-- Recibe el recibo de pago de la fase 1 (RF29, RF32), por POST multipart.
     web.xml le da multipart-config a esta página: el archivo se lee con
     pageContext.request.getPart('recibo') y se guarda en WEB-INF/archivos.
     Cada estudiante sube su propio recibo (decisión del equipo, 2026-10-10).
     Reglas: proyecto vigente en la fase 1 o 2 (en la 2, para el compañero que se agregó
     después, RF36); pago dentro del plazo del periodo; en los planes nuevos no aplica
     (salvo en Seminario); si el comité ya aprobó su pago, no sube otro; solo PDF de hasta
     15 MB (RNF15, RNF16). --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<%@ include file="/WEB-INF/jspf/estado-pago.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<c:set var="idEstudiante" value="${sessionScope.usuario.id}" />

<sql:query var="consulta">
    SELECT p.id, p.estado, p.modalidad_id, f.orden AS fase, f.id AS fase_id, ${sqlEstadoPagoEstudiante} AS estado_pago,
           (pe2.fecha_limite_pago IS NULL OR CURDATE() <= pe2.fecha_limite_pago) AS pago_a_tiempo
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    JOIN usuarios ue ON ue.id = pe.estudiante_id
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN periodos pe2 ON pe2.id = p.periodo_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${idEstudiante}" />
</sql:query>

<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />

<%-- El archivo: si es demasiado grande, getPart lanza una excepción --%>
<c:catch var="errorArchivo">
    <c:set var="parte" value="${pageContext.request.getPart('recibo')}" />
</c:catch>
<c:set var="nombreOriginal" value="${empty parte ? '' : fn:trim(parte.submittedFileName)}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.estado_pago == 'No aplica'}"><c:set var="motivo" value="pago-no-aplica" /></c:when>
    <c:when test="${p.estado_pago == 'Aprobado'}"><c:set var="motivo" value="pago-aprobado" /></c:when>
    <c:when test="${p.fase != 1 and p.fase != 2}"><c:set var="motivo" value="fase-no-permite" /></c:when>
    <c:when test="${p.pago_a_tiempo != 1}"><c:set var="motivo" value="pago-vencido" /></c:when>
    <c:when test="${not empty errorArchivo}"><c:set var="motivo" value="archivo-grande" /></c:when>
    <c:when test="${empty parte or parte.size == 0 or empty nombreOriginal}"><c:set var="motivo" value="archivo-requerido" /></c:when>
    <c:when test="${parte.size > 15728640}"><c:set var="motivo" value="archivo-grande" /></c:when>
    <c:when test="${not fn:endsWith(fn:toLowerCase(nombreOriginal), '.pdf')}"><c:set var="motivo" value="archivo-invalido" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/estudiante/proyecto.jsp">
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<%-- Nombre con el que se guarda: no depende del nombre que mandó el usuario --%>
<c:set var="nombreGuardado" value="recibo-p${p.id}-${System.currentTimeMillis()}.pdf" />
<c:set var="carpeta" value="${pageContext.servletContext.getRealPath('/WEB-INF/archivos')}" />

<c:catch var="errorGuardar">
    <c:set var="rutaGuardada">${carpeta}/${nombreGuardado}</c:set>
        <c:set var="escrito" value="${parte.write(rutaGuardada)}" />
    <sql:transaction>
        <sql:update>
            INSERT INTO entregas (proyecto_id, fase_id, tipo, nombre_archivo, ruta_archivo, subido_por)
            VALUES (?, ?, 'Recibo de pago', ?, ?, ?)
            <sql:param value="${p.id}" />
            <sql:param value="${p.fase_id}" />
            <sql:param value="${fn:substring(nombreOriginal, 0, 255)}" />
            <sql:param value="${nombreGuardado}" />
            <sql:param value="${idEstudiante}" />
        </sql:update>
        <sql:update>
            INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion)
            VALUES (?, ?, 'Documento', 'El estudiante subió el recibo de pago. Queda en revisión del comité.')
            <sql:param value="${p.id}" />
            <sql:param value="${idEstudiante}" />
        </sql:update>
        <c:set var="avisoProyecto" value="${p.id}" />
        <c:set var="avisoMensaje" value="${sessionScope.usuario.nombre} subió su recibo de pago: está por revisar." />
        <c:set var="avisoPara" value="comite" />
        <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
    </sql:transaction>
</c:catch>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="${empty errorGuardar ? 'ok' : 'error'}" value="${empty errorGuardar ? 'pago-subido' : 'general'}" />
</c:redirect>
