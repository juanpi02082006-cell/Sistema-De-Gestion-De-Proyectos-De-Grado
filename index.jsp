<%-- Inicio de sesión (RF1). Se entra con correo y contraseña; la validación
     está en acceso/validar.jsp. "Recordarme" y "¿La olvidaste?" son solo visuales
     por ahora. Los estudiantes nuevos se registran en registro.jsp (RF24). --%>
<%-- Si ya hay una sesión abierta, entrar directo al panel --%>
<c:if test="${not empty sessionScope.usuario and not empty sessionScope.rolActivo}">
    <c:redirect url="/panel/inicio.jsp" />
</c:if>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/5.1.0/css/bootstrap.min.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap">
    <link rel="stylesheet" href="css/estilo.css?v=${initParam.versionEstilos}">
    <title>Inicia sesión</title>
</head>
<body class="login">
    <main class="login-contenedor">
        <form class="login-tarjeta" method="post" action="acceso/validar.jsp" autocomplete="on">
            <div class="login-logo">
                <img src="img/logo-uts.png" alt="Unidades Tecnológicas de Santander" width="184">
            </div>

            <h1>Inicia sesión</h1>

            <c:choose>
                <c:when test="${param.error == 'credenciales'}">
                    <div class="alert alert-danger login-aviso" role="alert">Correo o contraseña incorrectos.</div>
                </c:when>
                <c:when test="${param.error == 'dominio'}">
                    <div class="alert alert-danger login-aviso" role="alert">Ingresa con tu correo institucional (@uts.edu.co o @correo.uts.edu.co).</div>
                </c:when>
                <c:when test="${param.error == 'sin-rol'}">
                    <div class="alert alert-danger login-aviso" role="alert">Tu usuario no tiene un rol asignado. Comunícate con la administración.</div>
                </c:when>
                <c:when test="${param.aviso == 'sesion'}">
                    <div class="alert alert-warning login-aviso" role="status">Inicia sesión para continuar.</div>
                </c:when>
                <c:when test="${param.aviso == 'salida'}">
                    <div class="alert alert-success login-aviso" role="status">Cerraste sesión correctamente.</div>
                </c:when>
                <c:when test="${param.aviso == 'registrado'}">
                    <div class="alert alert-success login-aviso" role="status">Tu cuenta quedó creada. Ya puedes iniciar sesión.</div>
                </c:when>
            </c:choose>

            <div class="login-campo">
                <label for="correo">Correo institucional</label>
                <div class="login-entrada">
                    <svg class="login-icono" viewBox="0 0 24 24" aria-hidden="true"><rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>
                    <input type="email" id="correo" name="correo" value="${fn:escapeXml(param.correo)}" placeholder="usuario@uts.edu.co" autocomplete="username" required>
                </div>
            </div>

            <div class="login-campo">
                <label for="clave">Contraseña</label>
                <div class="login-entrada">
                    <svg class="login-icono" viewBox="0 0 24 24" aria-hidden="true"><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                    <input type="password" id="clave" name="clave" autocomplete="current-password" required>
                    <button type="button" class="login-ver" id="verClave" aria-controls="clave" aria-label="Mostrar contraseña">
                        <svg class="icono-oculta" viewBox="0 0 24 24" aria-hidden="true"><path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.53 13.53 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/></svg>
                        <svg class="icono-visible" viewBox="0 0 24 24" aria-hidden="true"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                </div>
            </div>

            <div class="login-opciones">
                <label class="login-interruptor">
                    <input type="checkbox" name="recordarme" checked>
                    <span class="login-interruptor-pista" aria-hidden="true"></span>
                    Recordarme
                </label>
                <a href="#" class="login-enlace">¿La olvidaste?</a>
            </div>

            <button type="submit" class="login-boton">Iniciar sesión</button>

            <p class="login-registro">¿Eres estudiante y no tienes cuenta? <a class="login-enlace" href="registro.jsp">Regístrate</a></p>
        </form>
    </main>

    <script>
        // Mostrar u ocultar la contraseña
        document.getElementById('verClave').addEventListener('click', function () {
            var campo = document.getElementById('clave');
            var mostrar = campo.type === 'password';
            campo.type = mostrar ? 'text' : 'password';
            this.classList.toggle('visible', mostrar);
            this.setAttribute('aria-label', mostrar ? 'Ocultar contraseña' : 'Mostrar contraseña');
        });
    </script>
</body>
</html>
