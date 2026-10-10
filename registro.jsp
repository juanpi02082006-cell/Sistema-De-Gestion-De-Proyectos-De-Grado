<%-- Registro del estudiante (RF24): el estudiante crea su propia cuenta con su
     correo institucional (RF1) y sus datos académicos. A los docentes los registra
     el administrador (RF7). Si acceso/registrar.jsp encuentra un error, vuelve aquí
     con ?error=... y con los datos que se habían escrito. --%>
<c:if test="${not empty sessionScope.usuario and not empty sessionScope.rolActivo}">
    <c:redirect url="/panel/inicio.jsp" />
</c:if>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<sql:query var="tiposDocumento">SELECT id, nombre FROM tipos_documentos ORDER BY id</sql:query>
<sql:query var="niveles">SELECT id, nombre FROM niveles ORDER BY id</sql:query>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/5.1.0/css/bootstrap.min.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap">
    <link rel="stylesheet" href="${ctx}/css/estilo.css?v=${initParam.versionEstilos}">
    <title>Crea tu cuenta · Proyectos de Grado</title>
</head>
<body class="login">
    <main class="login-contenedor">
        <form class="login-tarjeta registro-tarjeta app-formulario" method="post" action="${ctx}/acceso/registrar.jsp">
            <div class="login-logo">
                <img src="${ctx}/img/logo-uts.png" alt="Unidades Tecnológicas de Santander" width="184">
            </div>

            <h1>Crea tu cuenta</h1>
            <p class="login-subtitulo">Registro para estudiantes. Si eres docente, el administrador crea tu usuario.</p>

            <c:if test="${not empty param.error}">
                <div class="alert alert-danger login-aviso" role="alert">
                    <c:choose>
                        <c:when test="${param.error == 'faltan-datos'}">Completa todos los campos obligatorios.</c:when>
                        <c:when test="${param.error == 'correo-no-institucional'}">Usa tu correo institucional: @uts.edu.co o @correo.uts.edu.co.</c:when>
                        <c:when test="${param.error == 'claves-distintas'}">Las dos contraseñas no coinciden.</c:when>
                        <c:when test="${param.error == 'creditos-invalidos'}">El porcentaje de créditos debe ser un número entero entre 0 y 100.</c:when>
                        <c:when test="${param.error == 'plan-invalido'}">Escoge si tu plan de estudios es anterior o posterior al decreto 1330.</c:when>
                        <c:when test="${param.error == 'correo-duplicado'}">Ya hay una cuenta con ese correo. Inicia sesión.</c:when>
                        <c:when test="${param.error == 'documento-duplicado'}">Ya hay una cuenta con ese número de documento.</c:when>
                        <c:otherwise>No se pudo crear la cuenta. Revisa los datos e inténtalo de nuevo.</c:otherwise>
                    </c:choose>
                </div>
            </c:if>

            <h2 class="app-tarjeta-titulo">Tus datos</h2>
            <div class="row g-3">
                <div class="col-12">
                    <label class="form-label" for="nombre">Nombre completo *</label>
                    <input class="form-control" type="text" id="nombre" name="nombre" maxlength="150" value="${fn:escapeXml(param.nombre)}" autocomplete="name" required>
                </div>
                <div class="col-md-5">
                    <label class="form-label" for="tipo_documento">Tipo de documento *</label>
                    <select class="form-select" id="tipo_documento" name="tipo_documento" required>
                        <c:forEach var="t" items="${tiposDocumento.rows}">
                            <c:set var="idTipo">${t.id}</c:set>
                            <option value="${t.id}" ${idTipo == param.tipo_documento ? 'selected' : ''}><c:out value="${t.nombre}" /></option>
                        </c:forEach>
                    </select>
                </div>
                <div class="col-md-7">
                    <label class="form-label" for="numero_documento">Número de documento *</label>
                    <input class="form-control" type="text" id="numero_documento" name="numero_documento" maxlength="20" value="${fn:escapeXml(param.numero_documento)}" required>
                </div>
                <div class="col-md-7">
                    <label class="form-label" for="correo">Correo institucional *</label>
                    <input class="form-control" type="email" id="correo" name="correo" maxlength="150" value="${fn:escapeXml(param.correo)}"
                           pattern=".+@(uts\.edu\.co|correo\.uts\.edu\.co)" title="Debe ser un correo @uts.edu.co o @correo.uts.edu.co"
                           placeholder="usuario@correo.uts.edu.co" autocomplete="email" required>
                    <div class="form-text">Con este correo inicias sesión.</div>
                </div>
                <div class="col-md-5">
                    <label class="form-label" for="celular">Celular</label>
                    <input class="form-control" type="tel" id="celular" name="celular" maxlength="20" value="${fn:escapeXml(param.celular)}" autocomplete="tel">
                </div>
                <div class="col-md-6">
                    <label class="form-label" for="clave">Contraseña *</label>
                    <input class="form-control" type="password" id="clave" name="clave" autocomplete="new-password" required>
                </div>
                <div class="col-md-6">
                    <label class="form-label" for="clave2">Repite la contraseña *</label>
                    <input class="form-control" type="password" id="clave2" name="clave2" autocomplete="new-password" required>
                </div>
            </div>

            <h2 class="app-tarjeta-titulo mt-4">Datos académicos</h2>
            <div class="row g-3">
                <div class="col-md-5">
                    <label class="form-label" for="nivel">Nivel *</label>
                    <select class="form-select" id="nivel" name="nivel" required>
                        <option value="">Escoge tu nivel</option>
                        <c:forEach var="n" items="${niveles.rows}">
                            <c:set var="idNivel">${n.id}</c:set>
                            <option value="${n.id}" ${idNivel == param.nivel ? 'selected' : ''}><c:out value="${n.nombre}" /></option>
                        </c:forEach>
                    </select>
                </div>
                <div class="col-md-7">
                    <label class="form-label" for="carrera">Carrera *</label>
                    <input class="form-control" type="text" id="carrera" name="carrera" maxlength="150" value="${fn:escapeXml(param.carrera)}" required>
                </div>
                <div class="col-md-7">
                    <label class="form-label" for="plan_estudios">Plan de estudios *</label>
                    <select class="form-select" id="plan_estudios" name="plan_estudios" required>
                        <option value="">Escoge tu plan</option>
                        <option value="Anterior" ${param.plan_estudios == 'Anterior' ? 'selected' : ''}>Anterior al decreto 1330 de 2019</option>
                        <option value="Nuevo" ${param.plan_estudios == 'Nuevo' ? 'selected' : ''}>Posterior al decreto 1330 de 2019</option>
                    </select>
                </div>
                <div class="col-md-5">
                    <label class="form-label" for="porcentaje_creditos">Créditos aprobados (%) *</label>
                    <input class="form-control" type="number" id="porcentaje_creditos" name="porcentaje_creditos" min="0" max="100" step="1" value="${fn:escapeXml(param.porcentaje_creditos)}" required>
                </div>
                <div class="col-12">
                    <div class="form-check form-switch">
                        <input class="form-check-input" type="checkbox" role="switch" id="metodologia" name="metodologia" ${param.metodologia == 'on' ? 'checked' : ''}>
                        <label class="form-check-label" for="metodologia">Ya aprobé Metodología de la investigación (o un curso equivalente)</label>
                    </div>
                </div>
            </div>

            <button type="submit" class="login-boton mt-4">Crear cuenta</button>
            <a class="login-enlace rol-salir" href="${ctx}/index.jsp">Ya tengo cuenta: iniciar sesión</a>
        </form>
    </main>
</body>
</html>
