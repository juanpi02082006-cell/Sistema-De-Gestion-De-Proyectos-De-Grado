<%-- Habilitación del estudiante (RF33): sus datos académicos, si cumple los
     requisitos de la fase 1 (RF29) y, si no, qué le falta. Si está habilitado,
     puede tomar cualquiera de las modalidades del sistema. --%>
<%@ include file="/WEB-INF/jspf/solo-estudiante.jspf" %>
<c:set var="idEstudiante" value="${sessionScope.usuario.id}" />
<%@ include file="/WEB-INF/jspf/habilitacion.jspf" %>
<sql:query var="modalidades">SELECT nombre FROM modalidades ORDER BY id</sql:query>

<c:set var="titulo" value="Habilitación" />
<c:set var="seccion" value="habilitacion" />
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <h1>Habilitación</h1>
    <p>Requisitos para empezar tu trabajo de grado (fase 1: tomar tu idea y subir el pago).</p>
</section>

<div class="app-resultado ${habilitado ? 'cumple' : ''}">
    <c:choose>
        <c:when test="${habilitado}">
            <h2>Estás habilitado</h2>
            <p>Puedes tomar una idea del banco o formular tu propia propuesta en cualquiera de estas modalidades:
                <c:forEach var="m" items="${modalidades.rows}" varStatus="s"><c:out value="${m.nombre}" />${s.last ? '.' : ', '}</c:forEach>
            </p>
        </c:when>
        <c:otherwise>
            <h2>Todavía no estás habilitado</h2>
            <p>Revisa abajo qué requisito te falta. Mientras tanto no hay modalidades disponibles para ti.</p>
        </c:otherwise>
    </c:choose>
</div>

<div class="app-tarjeta">
    <h2 class="app-tarjeta-titulo">Tus requisitos</h2>
    <ul class="app-lista">
        <li>
            <span><span class="app-lista-dato">Nivel</span></span>
            <span>
                <c:out value="${faltaNivel ? 'Sin registrar' : est.nivel}" />
                <span class="app-requisito ${faltaNivel ? '' : 'cumple'} ms-2">${faltaNivel ? 'Falta' : 'Listo'}</span>
            </span>
        </li>
        <li>
            <span><span class="app-lista-dato">Carrera</span></span>
            <span>
                <c:out value="${faltaCarrera ? 'Sin registrar' : est.carrera}" />
                <span class="app-requisito ${faltaCarrera ? '' : 'cumple'} ms-2">${faltaCarrera ? 'Falta' : 'Listo'}</span>
            </span>
        </li>
        <li>
            <span><span class="app-lista-dato">Plan de estudios</span></span>
            <span>
                <c:choose>
                    <c:when test="${faltaPlan}">Sin registrar</c:when>
                    <c:when test="${planNuevo}">Posterior al decreto 1330 de 2019</c:when>
                    <c:otherwise>Anterior al decreto 1330 de 2019</c:otherwise>
                </c:choose>
                <span class="app-requisito ${faltaPlan ? '' : 'cumple'} ms-2">${faltaPlan ? 'Falta' : 'Listo'}</span>
            </span>
        </li>
        <c:choose>
            <c:when test="${planNuevo}">
                <li>
                    <span>
                        <span class="app-lista-dato">Matrícula de Seminario de Grado I o III</span>
                        <span class="app-lista-nota">En los planes nuevos la propuesta se hace en ese curso. El sistema no lo puede verificar: lo confirma la coordinación.</span>
                    </span>
                    <span class="app-requisito">Por confirmar</span>
                </li>
            </c:when>
            <c:otherwise>
                <li>
                    <span>
                        <span class="app-lista-dato">Créditos aprobados</span>
                        <span class="app-lista-nota">Se necesita al menos el ${minimoCreditos} %.</span>
                    </span>
                    <span>
                        <c:out value="${faltanCreditosDato ? 'Sin registrar' : est.porcentaje_creditos}" />${faltanCreditosDato ? '' : ' %'}
                        <span class="app-requisito ${cumpleCreditos ? 'cumple' : ''} ms-2">${cumpleCreditos ? 'Cumple' : 'No cumple'}</span>
                    </span>
                </li>
                <li>
                    <span>
                        <span class="app-lista-dato">Metodología de la investigación</span>
                        <span class="app-lista-nota">O un curso equivalente.</span>
                    </span>
                    <span>
                        <c:choose>
                            <c:when test="${faltaMetodologiaDato}">Sin registrar</c:when>
                            <c:when test="${cumpleMetodologia}">Aprobada</c:when>
                            <c:otherwise>No aprobada</c:otherwise>
                        </c:choose>
                        <span class="app-requisito ${cumpleMetodologia ? 'cumple' : ''} ms-2">${cumpleMetodologia ? 'Cumple' : 'No cumple'}</span>
                    </span>
                </li>
            </c:otherwise>
        </c:choose>
    </ul>
    <p class="app-total">Si algún dato está mal, pídele al administrador que lo actualice.</p>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
