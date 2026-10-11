<%-- Guarda la cuenta de un estudiante que se registra solo (RF24), con el rol
     Estudiante (id 5). La carrera sale del catálogo de la UTS y el nivel se toma de la
     carrera. Si algo falla, vuelve a registro.jsp con el error y los datos. --%>
<c:if test="${pageContext.request.method != 'POST'}">
    <c:redirect url="/registro.jsp" />
</c:if>

<%-- Correo en minúsculas; debe ser institucional (RF1) --%>
<c:set var="correo" value="${fn:toLowerCase(fn:trim(param.correo))}" />
<c:set var="esInstitucional" value="${fn:endsWith(correo, '@uts.edu.co') or fn:endsWith(correo, '@correo.uts.edu.co')}" />

<%-- % de créditos aprobados: entero de 0 a 100 --%>
<c:set var="creditosTexto" value="${fn:trim(param.porcentaje_creditos)}" />
<c:set var="creditosValidos" value="false" />
<c:if test="${not empty creditosTexto}">
    <c:catch var="errorCreditos">
        <fmt:parseNumber var="creditosNumero" value="${creditosTexto}" integerOnly="true" parseLocale="en_US" />
    </c:catch>
    <c:set var="creditosNormalizado">${creditosNumero}</c:set>
    <c:set var="creditosValidos" value="${empty errorCreditos and creditosNormalizado == creditosTexto
                                          and creditosNumero >= 0 and creditosNumero <= 100}" />
</c:if>

<%-- La carrera debe existir en el catálogo; de ella sale el nivel --%>
<sql:query var="carrera">
    SELECT id, nivel_id FROM carreras WHERE id = ?
    <sql:param value="${empty param.carrera ? 0 : param.carrera}" />
</sql:query>

<c:choose>
    <c:when test="${empty fn:trim(param.nombre) or empty param.tipo_documento or empty fn:trim(param.numero_documento)
                    or empty correo or empty param.clave or empty param.carrera
                    or empty creditosTexto}">
        <jsp:forward page="/registro.jsp"><jsp:param name="error" value="faltan-datos" /></jsp:forward>
    </c:when>
    <c:when test="${not esInstitucional}">
        <jsp:forward page="/registro.jsp"><jsp:param name="error" value="correo-no-institucional" /></jsp:forward>
    </c:when>
    <c:when test="${param.clave != param.clave2}">
        <jsp:forward page="/registro.jsp"><jsp:param name="error" value="claves-distintas" /></jsp:forward>
    </c:when>
    <c:when test="${carrera.rowCount == 0}">
        <jsp:forward page="/registro.jsp"><jsp:param name="error" value="carrera-invalida" /></jsp:forward>
    </c:when>
    <c:when test="${param.plan_estudios != 'Anterior' and param.plan_estudios != 'Nuevo'}">
        <jsp:forward page="/registro.jsp"><jsp:param name="error" value="plan-invalido" /></jsp:forward>
    </c:when>
    <c:when test="${not creditosValidos}">
        <jsp:forward page="/registro.jsp"><jsp:param name="error" value="creditos-invalidos" /></jsp:forward>
    </c:when>
</c:choose>

<c:catch var="errorGuardar">
    <sql:transaction>
        <sql:update>
            INSERT INTO usuarios (nombre, tipo_documento_id, numero_documento, correo, contrasena, celular,
                                  nivel_id, carrera_id, plan_estudios, porcentaje_creditos, metodologia_aprobada)
            VALUES (?, ?, ?, ?, SHA2(?, 256), NULLIF(?, ''), ?, ?, ?, ?, ?)
            <sql:param value="${fn:trim(param.nombre)}" />
            <sql:param value="${param.tipo_documento}" />
            <sql:param value="${fn:trim(param.numero_documento)}" />
            <sql:param value="${correo}" />
            <sql:param value="${param.clave}" />
            <sql:param value="${fn:trim(param.celular)}" />
            <sql:param value="${carrera.rows[0].nivel_id}" />
            <sql:param value="${carrera.rows[0].id}" />
            <sql:param value="${param.plan_estudios}" />
            <sql:param value="${creditosTexto}" />
            <sql:param value="${param.metodologia == 'on' ? 1 : 0}" />
        </sql:update>
        <sql:update>
            INSERT INTO usuario_roles (usuario_id, rol_id) VALUES (LAST_INSERT_ID(), 5)
        </sql:update>
    </sql:transaction>
</c:catch>

<c:if test="${not empty errorGuardar}">
    <c:choose>
        <c:when test="${fn:contains(errorGuardar.message, 'uq_usuarios_correo')}">
            <jsp:forward page="/registro.jsp"><jsp:param name="error" value="correo-duplicado" /></jsp:forward>
        </c:when>
        <c:when test="${fn:contains(errorGuardar.message, 'uq_usuarios_documento')}">
            <jsp:forward page="/registro.jsp"><jsp:param name="error" value="documento-duplicado" /></jsp:forward>
        </c:when>
        <c:otherwise>
            <jsp:forward page="/registro.jsp"><jsp:param name="error" value="general" /></jsp:forward>
        </c:otherwise>
    </c:choose>
</c:if>

<c:redirect url="/index.jsp">
    <c:param name="aviso" value="registrado" />
    <c:param name="correo" value="${correo}" />
</c:redirect>
