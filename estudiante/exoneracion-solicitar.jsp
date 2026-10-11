<%-- El estudiante pide la exoneración por Saber TyT (RNF14, Acuerdo 01-009), por POST
     multipart: escribe su puntaje y sube el certificado en PDF; el comité lo verifica
     (decisión del equipo, 2026-10-10). Reglas:
       - solo nivel tecnológico (ingeniería y demás universitarios presentan Saber Pro);
       - proyecto vigente que no esté terminado, con la propuesta (FDC-124) aprobada por
         el comité y sin el informe final enviado al director: solo en la fase 4, porque
         lo que se exime es el informe final (decisión del equipo, 2026-10-11; antes de
         pagar y de aprobar la propuesta no se puede);
       - puntaje entero de 120 a 300 (los estímulos empiezan en 120);
       - una sola solicitud pendiente; quien ya está exonerado o renunció no pide otra
         (la renuncia no tiene vuelta atrás). --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.estado, p.titulo, p.fecha_aprobacion_124, f.id AS fase_id, f.orden AS fase, u.nivel_id, pe.exonerado, pe.renuncia_exoneracion,
           (f.orden >= 5) AS informes,
           (SELECT COUNT(*) FROM exoneraciones x WHERE x.proyecto_id = p.id AND x.estudiante_id = pe.estudiante_id AND x.estado = 'Pendiente') AS pendientes
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    JOIN usuarios u ON u.id = pe.estudiante_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />

<%-- Puntaje: entero de 120 a 300 --%>
<c:set var="puntajeTexto" value="${fn:trim(param.puntaje)}" />
<c:set var="puntajeValido" value="false" />
<c:if test="${not empty puntajeTexto}">
    <c:catch var="errorPuntaje">
        <fmt:parseNumber var="puntajeNumero" value="${puntajeTexto}" integerOnly="true" parseLocale="en_US" />
    </c:catch>
    <c:set var="puntajeNormalizado">${puntajeNumero}</c:set>
    <c:set var="puntajeValido" value="${empty errorPuntaje and puntajeNormalizado == puntajeTexto and puntajeNumero >= 120 and puntajeNumero <= 300}" />
</c:if>

<%-- El certificado: si es demasiado grande, getPart lanza una excepción --%>
<c:catch var="errorArchivo">
    <c:set var="parte" value="${pageContext.request.getPart('certificado')}" />
</c:catch>
<c:set var="nombreOriginal" value="${empty parte ? '' : fn:trim(parte.submittedFileName)}" />

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.nivel_id != 1}"><c:set var="motivo" value="exoneracion-solo-tecnologia" /></c:when>
    <c:when test="${p.informes > 0}"><c:set var="motivo" value="exoneracion-informe-entregado" /></c:when>
    <c:when test="${p.fase != 4 or empty p.fecha_aprobacion_124}"><c:set var="motivo" value="exoneracion-sin-propuesta" /></c:when>
    <c:when test="${p.exonerado == true or p.renuncia_exoneracion == true}"><c:set var="motivo" value="exoneracion-ya-decidida" /></c:when>
    <c:when test="${p.pendientes > 0}"><c:set var="motivo" value="exoneracion-pendiente" /></c:when>
    <c:when test="${not puntajeValido}"><c:set var="motivo" value="puntaje-invalido" /></c:when>
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
<c:set var="nombreGuardado" value="saber-p${p.id}-u${sessionScope.usuario.id}-${System.currentTimeMillis()}.pdf" />
<c:set var="carpeta" value="${pageContext.servletContext.getRealPath('/WEB-INF/archivos')}" />

<c:catch var="errorGuardar">
    <c:set var="rutaGuardada">${carpeta}/${nombreGuardado}</c:set>
    <c:set var="escrito" value="${parte.write(rutaGuardada)}" />
    <sql:transaction>
        <sql:update>
            INSERT INTO entregas (proyecto_id, fase_id, tipo, nombre_archivo, ruta_archivo, subido_por)
            VALUES (?, ?, 'Certificado Saber TyT', ?, ?, ?)
            <sql:param value="${p.id}" />
            <sql:param value="${p.fase_id}" />
            <sql:param value="${fn:substring(nombreOriginal, 0, 255)}" />
            <sql:param value="${nombreGuardado}" />
            <sql:param value="${sessionScope.usuario.id}" />
        </sql:update>
        <sql:update>
            INSERT INTO exoneraciones (proyecto_id, estudiante_id, puntaje, entrega_id) VALUES (?, ?, ?, LAST_INSERT_ID())
            <sql:param value="${p.id}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="${puntajeTexto}" />
        </sql:update>
        <sql:update>
            INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Documento', ?)
            <sql:param value="${p.id}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="${sessionScope.usuario.nombre} pidió la exoneración por Saber TyT (${puntajeTexto} puntos)." />
        </sql:update>
        <c:set var="avisoProyecto" value="${p.id}" />
        <c:set var="avisoMensaje">${sessionScope.usuario.nombre} pidió la exoneración por Saber TyT (${puntajeTexto} puntos): el certificado está por verificar.</c:set>
        <c:set var="avisoPara" value="comite" />
        <%@ include file="/WEB-INF/jspf/avisar.jspf" %>
    </sql:transaction>
</c:catch>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="${empty errorGuardar ? 'ok' : 'error'}" value="${empty errorGuardar ? 'exoneracion-solicitada' : 'general'}" />
</c:redirect>
