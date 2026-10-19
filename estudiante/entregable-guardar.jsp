<%-- Recibe un entregable de la modalidad (RF26; lista de otro equipo, RF-86 y RF-88), por
     POST multipart: el manual de usuario (PDF o Word), el código fuente (ZIP, RAR o 7Z) o
     una evidencia del desarrollo (PDF, imagen PNG o JPG, o ZIP), de hasta 15 MB (RNF15).
     Van con el informe final: se suben en la fase 4, con el FDC-124 aprobado por el
     comité, y los ven el director, los codirectores, el evaluador y el comité
     (informe-final.jspf). Son opcionales y puede haber varios de cada tipo; no llevan
     versión. Seminario no tiene informe final. web.xml le da multipart-config a esta
     página. --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>

<sql:query var="consulta">
    SELECT p.id, p.estado, p.modalidad_id, p.fecha_aprobacion_124, f.orden AS fase, f.id AS fase_id
    FROM proyecto_estudiantes pe
    JOIN proyectos p ON p.id = pe.proyecto_id
    LEFT JOIN fases f ON f.id = p.fase_id
    WHERE pe.estudiante_id = ? AND pe.vigente = 1
    <sql:param value="${sessionScope.usuario.id}" />
</sql:query>
<c:if test="${consulta.rowCount == 0}">
    <c:redirect url="/estudiante/proyecto.jsp" />
</c:if>
<c:set var="p" value="${consulta.rows[0]}" />

<%-- El archivo: si es demasiado grande, getPart lanza una excepción --%>
<c:catch var="errorArchivo">
    <c:set var="parte" value="${pageContext.request.getPart('archivo')}" />
</c:catch>
<c:set var="nombreOriginal" value="${empty parte ? '' : fn:trim(parte.submittedFileName)}" />
<c:set var="nombreMinusculas" value="${fn:toLowerCase(nombreOriginal)}" />

<%-- El tipo de entregable y las extensiones que acepta cada uno --%>
<c:set var="tipo" value="${param.tipo == 'manual' ? 'Manual de usuario' : (param.tipo == 'codigo' ? 'Código fuente' : (param.tipo == 'evidencia' ? 'Evidencia' : ''))}" />
<c:set var="extension" value="" />
<c:forEach var="ext" items="${param.tipo == 'manual' ? '.pdf,.docx,.doc' : (param.tipo == 'codigo' ? '.zip,.rar,.7z' : (param.tipo == 'evidencia' ? '.pdf,.png,.jpeg,.jpg,.zip' : ''))}">
    <c:if test="${empty extension and fn:endsWith(nombreMinusculas, ext)}"><c:set var="extension" value="${ext}" /></c:if>
</c:forEach>

<c:set var="motivo" value="" />
<c:choose>
    <c:when test="${p.estado == 'Finalizado' or p.estado == 'Cancelado'}"><c:set var="motivo" value="proyecto-cerrado" /></c:when>
    <c:when test="${p.modalidad_id == 5 or p.fase != 4 or empty p.fecha_aprobacion_124}"><c:set var="motivo" value="fase-no-permite-entregable" /></c:when>
    <c:when test="${empty tipo}"><c:set var="motivo" value="entregable-tipo-invalido" /></c:when>
    <c:when test="${not empty errorArchivo}"><c:set var="motivo" value="archivo-grande" /></c:when>
    <c:when test="${empty parte or parte.size == 0 or empty nombreOriginal}"><c:set var="motivo" value="archivo-requerido" /></c:when>
    <c:when test="${parte.size > 15728640}"><c:set var="motivo" value="archivo-grande" /></c:when>
    <c:when test="${empty extension}"><c:set var="motivo" value="entregable-formato" /></c:when>
</c:choose>
<c:if test="${not empty motivo}">
    <c:redirect url="/estudiante/proyecto.jsp">
        <c:param name="error" value="${motivo}" />
    </c:redirect>
</c:if>

<%-- Nombre con el que se guarda: no depende del nombre que mandó el usuario --%>
<c:set var="nombreGuardado" value="entregable-p${p.id}-${System.currentTimeMillis()}${extension}" />
<c:set var="carpeta" value="${pageContext.servletContext.getRealPath('/WEB-INF/archivos')}" />

<c:catch var="errorGuardar">
    <c:set var="rutaGuardada">${carpeta}/${nombreGuardado}</c:set>
    <c:set var="escrito" value="${parte.write(rutaGuardada)}" />
    <sql:transaction>
        <sql:update>
            INSERT INTO entregas (proyecto_id, fase_id, tipo, nombre_archivo, ruta_archivo, subido_por)
            VALUES (?, ?, ?, ?, ?, ?)
            <sql:param value="${p.id}" />
            <sql:param value="${p.fase_id}" />
            <sql:param value="${tipo}" />
            <sql:param value="${fn:substring(nombreOriginal, 0, 255)}" />
            <sql:param value="${nombreGuardado}" />
            <sql:param value="${sessionScope.usuario.id}" />
        </sql:update>
        <sql:update>
            INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (?, ?, 'Documento', ?)
            <sql:param value="${p.id}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="El estudiante subió el entregable «${fn:substring(nombreOriginal, 0, 150)}» (${tipo})." />
        </sql:update>
    </sql:transaction>
</c:catch>

<c:redirect url="/estudiante/proyecto.jsp">
    <c:param name="${empty errorGuardar ? 'ok' : 'error'}" value="${empty errorGuardar ? 'entregable-subido' : 'general'}" />
</c:redirect>
