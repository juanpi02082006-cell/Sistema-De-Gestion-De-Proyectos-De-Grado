<%-- Buscador (RF6; RNF3): un solo buscador para todos los roles, y cada uno busca solo en lo
     suyo (lista de otro equipo, RF-35 a RF-38):
       comité      todos los proyectos, por palabra (código, título, descripción, estudiantes,
                   director o evaluador), modalidad, fase, estado, periodo y docente;
       docente     los que dirige o codirige (Docente director) y los que evalúa (Docente
                   evaluador), por palabra (código, título, descripción o estudiantes), fase,
                   estado y periodo;
       estudiante  sus propios proyectos (también uno cancelado; no aquel del que lo quitaron),
                   por código o título, con su estado, fase y fechas. Nunca ve quién lo evalúa
                   (RF27).
     Los filtros solo toman valores de sus listas; uno raro se ignora. Muestra hasta 200
     resultados (con más, pide afinar la búsqueda). --%>
<%@ include file="/WEB-INF/jspf/sesion.jspf" %>
<c:set var="titulo" value="Buscar" />
<c:set var="seccion" value="buscar" />
<c:set var="rol" value="${sessionScope.rolActivo.id}" />
<c:set var="esComite" value="${rol == 1}" />
<c:set var="esDocente" value="${rol == 3 or rol == 4}" />
<c:set var="esEstudiante" value="${rol == 5}" />
<c:set var="idUsuario" value="${sessionScope.usuario.id}" />
<c:set var="q" value="${fn:trim(param.q)}" />
<c:set var="patron" value="%${q}%" />

<%-- Listas de los filtros; cada filtro solo vale si está en su lista --%>
<sql:query var="fases">SELECT orden, nombre FROM fases WHERE orden >= 1 ORDER BY orden</sql:query>
<sql:query var="periodos">SELECT id, nombre FROM periodos ORDER BY fecha_inicio_semestre DESC, id DESC</sql:query>
<sql:query var="modalidades">SELECT id, nombre FROM modalidades ORDER BY id</sql:query>
<sql:query var="docentes">
    SELECT DISTINCT u.id, u.nombre FROM usuarios u JOIN usuario_roles ur ON ur.usuario_id = u.id
    WHERE ur.rol_id IN (3, 4) ORDER BY u.nombre
</sql:query>
<c:set var="fFase" value="" />
<c:forEach var="o" items="${fases.rows}"><c:set var="x">${o.orden}</c:set><c:if test="${x == param.fase}"><c:set var="fFase" value="${x}" /></c:if></c:forEach>
<c:set var="fPeriodo" value="" />
<c:forEach var="o" items="${periodos.rows}"><c:set var="x">${o.id}</c:set><c:if test="${x == param.periodo}"><c:set var="fPeriodo" value="${x}" /></c:if></c:forEach>
<c:set var="fModalidad" value="" />
<c:if test="${esComite}">
    <c:forEach var="o" items="${modalidades.rows}"><c:set var="x">${o.id}</c:set><c:if test="${x == param.modalidad}"><c:set var="fModalidad" value="${x}" /></c:if></c:forEach>
</c:if>
<c:set var="fDocente" value="" />
<c:if test="${esComite}">
    <c:forEach var="o" items="${docentes.rows}"><c:set var="x">${o.id}</c:set><c:if test="${x == param.docente}"><c:set var="fDocente" value="${x}" /></c:if></c:forEach>
</c:if>
<c:set var="fEstado" value="${param.estado == 'Pendiente' or param.estado == 'En curso' or param.estado == 'Finalizado' or param.estado == 'Cancelado' ? param.estado : ''}" />

<sql:query var="resultados">
    SELECT p.id, p.codigo, p.titulo, p.estado, p.fecha_inicio, p.fecha_aprobacion_124, p.fecha_limite, p.modalidad_id,
           f.orden AS fase, f.nombre AS nombre_fase, m.nombre AS modalidad, n.nombre AS nivel, pr.nombre AS periodo,
           d.nombre AS director, ev.nombre AS evaluador,
           (SELECT GROUP_CONCAT(u.nombre ORDER BY u.nombre SEPARATOR ', ') FROM proyecto_estudiantes pe JOIN usuarios u ON u.id = pe.estudiante_id
            WHERE pe.proyecto_id = p.id AND (pe.vigente = 1 OR (p.estado = 'Cancelado' AND pe.estado = 'Activo'))) AS estudiantes,
           (p.director_id = ?) AS es_director,
           EXISTS (SELECT 1 FROM proyecto_codirectores pc WHERE pc.proyecto_id = p.id AND pc.docente_id = ?) AS es_codirector,
           (p.evaluador_id = ?) AS es_evaluador,
           EXISTS (SELECT 1 FROM proyecto_estudiantes pe WHERE pe.proyecto_id = p.id AND pe.estudiante_id = ? AND pe.vigente = 1) AS es_vigente
    FROM proyectos p
    JOIN modalidades m ON m.id = p.modalidad_id
    JOIN niveles n ON n.id = p.nivel_id
    LEFT JOIN fases f ON f.id = p.fase_id
    LEFT JOIN periodos pr ON pr.id = p.periodo_id
    LEFT JOIN usuarios d ON d.id = p.director_id
    LEFT JOIN usuarios ev ON ev.id = p.evaluador_id
    WHERE (? = 1
           OR (? = 1 AND ((? = 1 AND (p.director_id = ? OR EXISTS (SELECT 1 FROM proyecto_codirectores pc WHERE pc.proyecto_id = p.id AND pc.docente_id = ?)))
                          OR (? = 1 AND p.evaluador_id = ?)))
           OR (? = 1 AND EXISTS (SELECT 1 FROM proyecto_estudiantes pe WHERE pe.proyecto_id = p.id AND pe.estudiante_id = ? AND pe.estado = 'Activo')))
      AND (? = '' OR p.codigo LIKE ? OR p.titulo LIKE ?
           OR (? = 0 AND (p.descripcion LIKE ?
               OR EXISTS (SELECT 1 FROM proyecto_estudiantes pe JOIN usuarios u ON u.id = pe.estudiante_id
                          WHERE pe.proyecto_id = p.id AND pe.estado = 'Activo' AND (u.nombre LIKE ? OR u.correo LIKE ?))))
           OR (? = 1 AND (d.nombre LIKE ? OR ev.nombre LIKE ?)))
      AND (? = '' OR f.orden = ?)
      AND (? = '' OR p.estado = ?)
      AND (? = '' OR p.periodo_id = ?)
      AND (? = '' OR p.modalidad_id = ?)
      AND (? = '' OR p.director_id = ? OR p.evaluador_id = ?
           OR EXISTS (SELECT 1 FROM proyecto_codirectores pc WHERE pc.proyecto_id = p.id AND pc.docente_id = ?))
    ORDER BY pr.fecha_inicio_semestre DESC, p.id DESC
    LIMIT 201
    <sql:param value="${idUsuario}" />
    <sql:param value="${idUsuario}" />
    <sql:param value="${idUsuario}" />
    <sql:param value="${idUsuario}" />
    <sql:param value="${esComite ? 1 : 0}" />
    <sql:param value="${esDocente ? 1 : 0}" />
    <sql:param value="${tieneRolDirector ? 1 : 0}" />
    <sql:param value="${idUsuario}" />
    <sql:param value="${idUsuario}" />
    <sql:param value="${tieneRolEvaluador ? 1 : 0}" />
    <sql:param value="${idUsuario}" />
    <sql:param value="${esEstudiante ? 1 : 0}" />
    <sql:param value="${idUsuario}" />
    <sql:param value="${q}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${esEstudiante ? 1 : 0}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${esComite ? 1 : 0}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${fFase}" />
    <sql:param value="${fFase}" />
    <sql:param value="${fEstado}" />
    <sql:param value="${fEstado}" />
    <sql:param value="${fPeriodo}" />
    <sql:param value="${fPeriodo}" />
    <sql:param value="${fModalidad}" />
    <sql:param value="${fModalidad}" />
    <sql:param value="${fDocente}" />
    <sql:param value="${fDocente}" />
    <sql:param value="${fDocente}" />
    <sql:param value="${fDocente}" />
</sql:query>
<c:set var="hayMas" value="${resultados.rowCount > 200}" />
<c:set var="conFiltros" value="${not empty q or not empty fFase or not empty fEstado or not empty fPeriodo or not empty fModalidad or not empty fDocente}" />

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<section class="app-encabezado">
    <h1>Buscar</h1>
    <p>
        <c:choose>
            <c:when test="${esComite}">Todos los proyectos: por código, título, descripción, estudiante, director o evaluador, y con los filtros.</c:when>
            <c:when test="${esDocente}">Los proyectos que diriges o codiriges y los que evalúas: por código, título, descripción o estudiante.</c:when>
            <c:otherwise>Tus proyectos: por código o título, con su estado, fase y fechas.</c:otherwise>
        </c:choose>
    </p>
</section>

<%@ include file="/WEB-INF/jspf/mensajes.jspf" %>

<div class="app-tarjeta">
    <form class="app-filtros" method="get" action="${ctx}/panel/buscar.jsp" role="search">
        <input type="search" class="form-control" name="q" value="${fn:escapeXml(q)}" maxlength="100"
               placeholder="${esEstudiante ? 'Código o título' : (esComite ? 'Código, título, estudiante, docente o palabra' : 'Código, título, estudiante o palabra')}" aria-label="Buscar">
        <select class="form-select" name="fase" aria-label="Fase">
            <option value="">Todas las fases</option>
            <c:forEach var="o" items="${fases.rows}">
                <c:set var="x">${o.orden}</c:set>
                <option value="${o.orden}" ${x == fFase ? 'selected' : ''}>${o.orden == 6 ? 'Fase final' : 'Fase '}${o.orden == 6 ? '' : o.orden} · <c:out value="${o.nombre}" /></option>
            </c:forEach>
        </select>
        <select class="form-select" name="estado" aria-label="Estado">
            <option value="">Todos los estados</option>
            <c:forEach var="o" items="Pendiente,En curso,Finalizado,Cancelado">
                <option value="${o}" ${o == fEstado ? 'selected' : ''}>${o}</option>
            </c:forEach>
        </select>
        <select class="form-select" name="periodo" aria-label="Periodo">
            <option value="">Todos los periodos</option>
            <c:forEach var="o" items="${periodos.rows}">
                <c:set var="x">${o.id}</c:set>
                <option value="${o.id}" ${x == fPeriodo ? 'selected' : ''}><c:out value="${o.nombre}" /></option>
            </c:forEach>
        </select>
        <c:if test="${esComite}">
            <select class="form-select" name="modalidad" aria-label="Modalidad">
                <option value="">Todas las modalidades</option>
                <c:forEach var="o" items="${modalidades.rows}">
                    <c:set var="x">${o.id}</c:set>
                    <option value="${o.id}" ${x == fModalidad ? 'selected' : ''}><c:out value="${o.nombre}" /></option>
                </c:forEach>
            </select>
            <select class="form-select" name="docente" aria-label="Docente">
                <option value="">Todos los docentes</option>
                <c:forEach var="o" items="${docentes.rows}">
                    <c:set var="x">${o.id}</c:set>
                    <option value="${o.id}" ${x == fDocente ? 'selected' : ''}><c:out value="${o.nombre}" /></option>
                </c:forEach>
            </select>
        </c:if>
        <button type="submit" class="btn btn-primary rounded-pill">Buscar</button>
        <c:if test="${conFiltros}"><a class="btn btn-outline-dark rounded-pill" href="${ctx}/panel/buscar.jsp">Limpiar</a></c:if>
    </form>

    <c:choose>
        <c:when test="${resultados.rowCount == 0}">
            <p class="app-vacio">${conFiltros ? 'No hay proyectos con esa búsqueda.' : (esEstudiante ? 'Todavía no tienes proyectos. Se crean cuando tomas una idea del banco.' : 'Todavía no hay proyectos.')}</p>
        </c:when>
        <c:otherwise>
            <div class="table-responsive">
                <table class="table app-tabla align-middle">
                    <thead>
                        <tr>
                            <th>Proyecto</th>
                            <c:if test="${not esEstudiante}"><th>Estudiantes</th></c:if>
                            <th>Fase y estado</th>
                            <th>Fechas</th>
                            <c:if test="${esComite}"><th>Director y evaluador</th></c:if>
                            <c:if test="${esDocente}"><th>Tu papel</th></c:if>
                            <th class="text-end">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="r" items="${resultados.rows}" end="199">
                            <tr>
                                <td>
                                    <span class="fw-semibold"><c:out value="${r.titulo}" /></span>
                                    <c:if test="${not empty r.codigo}"><span class="app-lista-nota"><c:out value="${r.codigo}" /></span></c:if>
                                    <span class="app-lista-nota"><c:out value="${r.modalidad}" /> · <c:out value="${r.nivel}" /><c:if test="${not empty r.periodo}"> · <c:out value="${r.periodo}" /></c:if></span>
                                </td>
                                <c:if test="${not esEstudiante}"><td><c:out value="${empty r.estudiantes ? '—' : r.estudiantes}" /></td></c:if>
                                <td class="text-nowrap">
                                    <c:choose>
                                        <c:when test="${r.modalidad_id == 5}">Seminario</c:when>
                                        <c:when test="${r.fase == 6}">Fase final</c:when>
                                        <c:otherwise>Fase <c:out value="${r.fase}" /></c:otherwise>
                                    </c:choose>
                                    <c:if test="${r.modalidad_id != 5}"><span class="app-lista-nota"><c:out value="${r.nombre_fase}" /></span></c:if>
                                    <span class="app-estado ${r.estado == 'Finalizado' or r.estado == 'En curso' ? 'activo' : 'inactivo'}"><c:out value="${r.estado}" /></span>
                                </td>
                                <td class="text-nowrap">
                                    <span class="app-lista-nota mt-0">Inicio: <c:choose><c:when test="${empty r.fecha_inicio}">—</c:when><c:otherwise><fmt:formatDate value="${r.fecha_inicio}" pattern="dd/MM/yyyy" /></c:otherwise></c:choose></span>
                                    <c:if test="${not empty r.fecha_aprobacion_124}"><span class="app-lista-nota">Propuesta aprobada: <fmt:formatDate value="${r.fecha_aprobacion_124}" pattern="dd/MM/yyyy" /></span></c:if>
                                    <c:if test="${not empty r.fecha_limite and r.estado != 'Finalizado' and r.estado != 'Cancelado'}"><span class="app-lista-nota">Límite del informe: <fmt:formatDate value="${r.fecha_limite}" pattern="dd/MM/yyyy" /></span></c:if>
                                </td>
                                <c:if test="${esComite}">
                                    <td>
                                        <c:out value="${empty r.director ? 'Sin director' : r.director}" />
                                        <span class="app-lista-nota">Evaluador: <c:out value="${empty r.evaluador ? 'sin asignar' : r.evaluador}" /></span>
                                    </td>
                                </c:if>
                                <c:if test="${esDocente}">
                                    <td>${r.es_director == 1 ? 'Director' : (r.es_codirector == 1 ? 'Codirector' : 'Evaluador')}</td>
                                </c:if>
                                <td class="text-end app-acciones">
                                    <c:choose>
                                        <c:when test="${esComite}"><a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/admin/proyecto.jsp?id=${r.id}">Ver</a></c:when>
                                        <c:when test="${esDocente and tieneRolDirector and (r.es_director == 1 or r.es_codirector == 1)}"><a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/director/proyecto.jsp?id=${r.id}">Ver</a></c:when>
                                        <c:when test="${esDocente}"><a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/evaluador/proyecto.jsp?id=${r.id}">Ver</a></c:when>
                                        <c:when test="${r.es_vigente == 1}"><a class="btn btn-sm btn-outline-dark rounded-pill" href="${ctx}/estudiante/proyecto.jsp">Ver</a></c:when>
                                        <c:otherwise><span class="app-lista-nota mt-0">Proyecto anterior</span></c:otherwise>
                                    </c:choose>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
            <p class="app-total">
                <c:choose>
                    <c:when test="${hayMas}">Más de 200 proyectos: se muestran los 200 más recientes. Afina la búsqueda con los filtros.</c:when>
                    <c:otherwise>${resultados.rowCount} ${resultados.rowCount == 1 ? 'proyecto' : 'proyectos'}</c:otherwise>
                </c:choose>
            </p>
        </c:otherwise>
    </c:choose>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
