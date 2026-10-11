<%-- El estudiante pide una prórroga del plazo del informe final, por POST multipart
     (RF38; reglamento, art. 16; F-DC-124). web.xml le da multipart-config a esta página.
     Reglas:
       - proyecto vigente en la fase 4 con el FDC-124 aprobado (los 180 días ya corren);
       - antes del vencimiento (se recomienda pedirla unos 8 días antes);
       - solo si algún integrante es de un plan anterior al decreto 1330 (en los planes
         nuevos no hay prórrogas, RF42) y no en Seminario;
       - hasta 3 prórrogas aprobadas y una sola solicitud pendiente;
       - con motivo y con el soporte en PDF: el recibo del nuevo pago del derecho
         pecuniario o, en Proyecto de investigación y Desarrollo tecnológico, el aval de
         la Dirección de Investigaciones y Extensión.
     La nueva fecha límite es la vigente más 180 días; la decide el comité
     (admin/prorroga-decidir.jsp). --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<c:set var="idEstudiante" value="${sessionScope.usuario.id}" />
<sql:query var="consulta">
    SELECT p.id, p.titulo, p.estado, p.modalidad_id, p.fecha_aprobacion_124, p.fecha_limite, f.orden AS fase, f.id AS fase_id,
           (CURDATE() > p.fecha_limite) AS vencido,
           (SELECT COUNT(*) FROM prorrogas x WHERE x.proyecto_id = p.id AND x.estado = 'Aprobada') AS aprobadas,
           (SELECT COUNT(*) FROM prorrogas x WHERE x.proyecto_id = p.id AND x.estado = 'Pendiente') AS pendientes,
           EXISTS (SELECT 1 FROM proyecto_estudiantes y JOIN usuarios uy ON uy.id = y.estudiante_id
                   WHERE y.proyecto_id = p.id AND y.vigente = 1 AND (uy.plan_estudios IS NULL OR uy.plan_estudios <> 'Nuevo')) AS plan_anterior
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${idEstudiante}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />
<c:set var="motivoTexto" value="${fn:trim(param.motivo)}" />

<c:catch var="errorArchivo">
    <c:set var="parte" value="${pageContext.request.getPart('soporte')}" />
</c:catch>
<c:set var="nombreOriginal" value="${empty parte ? '' : fn:trim(parte.submittedFileName)}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.modalidad_id == 5 or p.fase != 4 or empty p.fecha_aprobacion_124}"><c:set var="motivo" value="prorroga-no-aplica" /></c:when>
    <c:when test="${p.plan_anterior != 1}"><c:set var="motivo" value="prorroga-plan-nuevo" /></c:when>
    <c:when test="${p.vencido == 1}"><c:set var="motivo" value="prorroga-vencida" /></c:when>
    <c:when test="${p.aprobadas >= 3}"><c:set var="motivo" value="prorrogas-agotadas" /></c:when>
    <c:when test="${p.pendientes > 0}"><c:set var="motivo" value="prorroga-pendiente" /></c:when>
    <c:when test="${empty motivoTexto}"><c:set var="motivo" value="motivo-prorroga-requerido" /></c:when>
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

<c:set var="nombreGuardado" value="prorroga-p${p.id}-${System.currentTimeMillis()}.pdf" />
<c:set var="carpeta" value="${pageContext.servletContext.getRealPath('/WEB-INF/archivos')}" />

<c:catch var="errorGuardar">
    <c:set var="rutaGuardada">${carpeta}/${nombreGuardado}</c:set>
    <c:set var="escrito" value="${parte.write(rutaGuardada)}" />
    <sql:transaction>
        <sql:update>
            INSERT INTO entregas (proyecto_id, fase_id, tipo, nombre_archivo, ruta_archivo, subido_por)
            VALUES (?, ?, 'Soporte de prórroga', ?, ?, ?)
            <sql:param value="${p.id}" />
            <sql:param value="${p.fase_id}" />
            <sql:param value="${fn:substring(nombreOriginal, 0, 255)}" />
            <sql:param value="${nombreGuardado}" />
            <sql:param value="${idEstudiante}" />
        </sql:update>
        <sql:query var="soporte">SELECT LAST_INSERT_ID() AS id</sql:query>
        <sql:update>
            INSERT INTO prorrogas (proyecto_id, fecha_solicitud, nueva_fecha_limite, motivo, entrega_id, solicitada_por)
            VALUES (?, CURDATE(), ? + INTERVAL 180 DAY, ?, ?, ?)
            <sql:param value="${p.id}" />
            <sql:dateParam value="${p.fecha_limite}" type="date" />
            <sql:param value="${motivoTexto}" />
            <sql:param value="${soporte.rows[0].id}" />
            <sql:param value="${idEstudiante}" />
        </sql:update>
        <sql:update>
            INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Otro', ?)
            <sql:param value="${p.id}" />
            <sql:param value="${idEstudiante}" />
            <sql:param value="${sessionScope.usuario.nombre} pidió la prórroga ${p.aprobadas + 1} del plazo del informe final." />
        </sql:update>
        <c:set var="avisoProyecto" value="${p.id}" />
        <c:set var="avisoMensaje">${sessionScope.usuario.nombre} pidió una prórroga del plazo del informe final de «${p.titulo}». Motivo: ${motivoTexto}</c:set>
        <c:set var="avisoPara" value="comite,director" />
        <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
    </sql:transaction>
</c:catch>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="${empty errorGuardar ? 'ok' : 'error'}" value="${empty errorGuardar ? 'prorroga-solicitada' : 'general'}" />
</c:redirect>
