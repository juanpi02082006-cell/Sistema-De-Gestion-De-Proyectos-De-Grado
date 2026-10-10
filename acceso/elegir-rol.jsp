<%-- Para usuarios con varios roles (por ejemplo, Director y Evaluador):
     escoger con qué rol entrar. También sirve para cambiar de rol. --%>
<c:if test="${empty sessionScope.usuario}">
    <c:redirect url="/index.jsp">
        <c:param name="aviso" value="sesion" />
    </c:redirect>
</c:if>

<%-- Se eligió un rol: comprobar que sea uno de los roles del usuario --%>
<c:if test="${not empty param.rol}">
    <c:forEach var="r" items="${sessionScope.roles}">
        <c:set var="idRol">${r.id}</c:set>
        <c:if test="${idRol == param.rol}">
            <c:set var="rolActivo" scope="session" value="${r}" />
            <c:redirect url="/panel/inicio.jsp" />
        </c:if>
    </c:forEach>
</c:if>

<c:set var="ctx" value="${pageContext.request.contextPath}" />
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
    <title>Elige tu rol</title>
</head>
<body class="login">
    <main class="login-contenedor">
        <div class="login-tarjeta">
            <div class="login-logo">
                <img src="${ctx}/img/logo-uts.png" alt="Unidades Tecnológicas de Santander" width="184">
            </div>

            <h1>Elige tu rol</h1>
            <p class="login-subtitulo">Hola, <c:out value="${sessionScope.usuario.nombre}" />. Tienes varios roles; escoge con cuál quieres entrar.</p>

            <div class="rol-opciones">
                <c:forEach var="r" items="${sessionScope.roles}">
                    <a class="rol-opcion ${sessionScope.rolActivo.id == r.id ? 'actual' : ''}" href="${ctx}/acceso/elegir-rol.jsp?rol=${r.id}">
                        <span><c:out value="${r.nombre}" /></span>
                        <c:if test="${sessionScope.rolActivo.id == r.id}"><small>Rol actual</small></c:if>
                    </a>
                </c:forEach>
            </div>

            <a class="login-enlace rol-salir" href="${ctx}/acceso/salir.jsp">Salir</a>
        </div>
    </main>
</body>
</html>
