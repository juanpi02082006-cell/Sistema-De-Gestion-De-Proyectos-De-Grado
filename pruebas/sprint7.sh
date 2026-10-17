#!/usr/bin/env bash
# Pruebas del buscador (RF6) y de los informes del comité (RF15), 2026-10-17, y del tiempo de
# respuesta de las búsquedas con 5.000 proyectos (RNF3). Deja proyectos en cada situación:
# uno con codirector y una estudiante quitada, uno finalizado, uno cancelado de otro periodo,
# un Seminario aprobado y uno en curso con una estudiante exonerada. Revisa que cada rol
# busque solo en lo suyo (el comité en todo, el docente en lo que dirige, codirige o evalúa,
# el estudiante en sus proyectos y sin ver a su evaluador), cada filtro, los valores raros y
# el HTML en la búsqueda; y que los informes cuenten bien por periodo, modalidad y cantidad
# de estudiantes, con los listados de aprobados y no aprobados.
# Se corren sobre la base recién importada (usuarios de prueba con la clave 123456):
#   bash pruebas/correr-pruebas.sh <carpeta-respaldo> sprint7
B="http://localhost:8080/segundo-parcial"
T="$(dirname "$0")/tmp/sprint7"; rm -rf "$T"; mkdir -p "$T"
OK=0; FALLA=0
MYSQL="/c/xampp/mysql/bin/mysql.exe -u root -N -B -D sistemas_proyectos_grado --default-character-set=utf8mb4"

revisar() { if [ "$2" -eq 0 ]; then echo "  OK    $1"; OK=$((OK+1)); else echo "  FALLA $1"; FALLA=$((FALLA+1)); fi; }
pedir() {
    local jar="$T/$1"; local metodo="$2"; local ruta="$3"; shift 3
    if [ "$metodo" = "POST" ]; then
        RES=$(curl -s -o "$T/cuerpo.html" -w "%{http_code} %{redirect_url} %{time_total}" -b "$jar" -c "$jar" -X POST "$@" "$B$ruta")
    else
        RES=$(curl -s -o "$T/cuerpo.html" -w "%{http_code} %{redirect_url} %{time_total}" -b "$jar" -c "$jar" "$B$ruta")
    fi
    CODIGO="${RES%% *}"; RESTO="${RES#* }"; DESTINO="${RESTO% *}"; TIEMPO="${RES##* }"
}
contiene() { grep -q "$1" "$T/cuerpo.html"; }
sinError() { ! grep -q "Exception\|HTTP Status 500\|Estado HTTP 500" "$T/cuerpo.html"; }
plano() { tr -s ' \r\n\t' ' ' < "$T/cuerpo.html"; }
entrar() { pedir "$1" POST /acceso/validar.jsp --data-urlencode "correo=$2" --data-urlencode "clave=123456"; }
# Cuántos proyectos encontró el buscador (0 si dice que no hay)
resultados() {
    if contiene "No hay proyectos con esa b\|Todav.\{1,2\}a no tienes proyectos\|Todav.\{1,2\}a no hay proyectos"; then echo 0; return; fi
    plano | grep -o 'app-total"> [0-9]* proyecto' | grep -o '[0-9][0-9]*' | head -1
}
buscar() { pedir "$1" GET "/panel/buscar.jsp?$2"; resultados; }
dato() { plano | grep -q "<dt>$1</dt><dd>$2</dd>"; }   # par etiqueta / valor del informe

echo "== Datos: dos periodos, cinco proyectos y siete estudiantes"
$MYSQL <<'SQL'
INSERT INTO periodos (id, nombre, estado, fecha_inicio_semestre, fecha_cierre_banco, fecha_limite_pago, fecha_limite_propuestas) VALUES
    (1, '2026-2', 'Activo', CURDATE() - INTERVAL 60 DAY, CURDATE() + INTERVAL 30 DAY, CURDATE() + INTERVAL 30 DAY, CURDATE() + INTERVAL 60 DAY),
    (2, '2026-1', 'Cerrado', CURDATE() - INTERVAL 240 DAY, CURDATE() - INTERVAL 200 DAY, CURDATE() - INTERVAL 200 DAY, CURDATE() - INTERVAL 150 DAY);
INSERT INTO usuarios (id, nombre, tipo_documento_id, numero_documento, correo, contrasena, nivel_id, carrera_id, plan_estudios, porcentaje_creditos, metodologia_aprobada) VALUES
    (20, 'Ana Siete Rueda', 2, '7700000020', 'ana.siete@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (21, 'Beto Siete Pinto', 2, '7700000021', 'beto.siete@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (22, 'Caro Siete Diaz', 2, '7700000022', 'caro.siete@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (23, 'Dani Siete Mora', 2, '7700000023', 'dani.siete@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (24, 'Eli Siete Paez', 2, '7700000024', 'eli.siete@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (25, 'Fer Siete Ortiz', 2, '7700000025', 'fer.siete@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (26, 'Gabi Siete Leon', 2, '7700000026', 'gabi.siete@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1);
INSERT INTO usuario_roles (usuario_id, rol_id) SELECT id, 5 FROM usuarios WHERE id BETWEEN 20 AND 26;
-- P1 en curso con codirector (el docente 6) y Caro quitada; P2 finalizado (director 6); P3 cancelado
-- en el periodo anterior (director 3, evaluador 6); P4 Seminario aprobado; P5 en curso con Eli exonerada
INSERT INTO proyectos (id, codigo, titulo, descripcion, modalidad_id, nivel_id, periodo_id, fase_id, estado, director_id, evaluador_id, interdisciplinario, fecha_inicio, fecha_aprobacion_124, fecha_limite, nota_final) VALUES
    (1, '65-2026-2/1', 'Turnos de la cafeteria', 'Notificaciones al celular', 2, 1, 1, 5, 'En curso', 3, 4, 1, CURDATE() - INTERVAL 50 DAY, CURDATE() - INTERVAL 20 DAY, CURDATE() + INTERVAL 160 DAY, NULL),
    (2, '65-2026-2/2', 'Monografia de redes', 'Seguridad perimetral', 3, 1, 1, 7, 'Finalizado', 6, 4, 0, CURDATE() - INTERVAL 55 DAY, CURDATE() - INTERVAL 40 DAY, CURDATE() + INTERVAL 140 DAY, NULL),
    (3, '65-2026-1/1', 'Inventario con QR', 'Laboratorios de electronica', 2, 1, 2, 3, 'Cancelado', 3, 6, 0, CURDATE() - INTERVAL 230 DAY, NULL, NULL, NULL),
    (4, '65-2026-2/3', 'Seminario de analitica', 'Datos academicos', 5, 1, 1, 2, 'Finalizado', 6, NULL, 0, CURDATE() - INTERVAL 45 DAY, NULL, NULL, 4.2),
    (5, '65-2026-2/4', 'Reservas de salas', 'Biblioteca', 2, 1, 1, 5, 'En curso', 6, 4, 0, CURDATE() - INTERVAL 40 DAY, CURDATE() - INTERVAL 10 DAY, CURDATE() + INTERVAL 170 DAY, NULL);
INSERT INTO proyecto_codirectores (proyecto_id, docente_id) VALUES (1, 6);
INSERT INTO proyecto_estudiantes (proyecto_id, estudiante_id, estado, vigente, exonerado) VALUES
    (1, 20, 'Activo', 1, 0), (1, 21, 'Activo', 1, 0), (1, 22, 'Excluido', NULL, 0),
    (2, 23, 'Activo', 1, 0), (3, 24, 'Activo', NULL, 0), (4, 25, 'Activo', 1, 0),
    (5, 24, 'Activo', 1, 1), (5, 26, 'Activo', 1, 0);
INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES
    (3, NULL, 'Estado', 'Proyecto cancelado por extemporaneidad: la propuesta no quedo aprobada antes de la semana 12.');
SQL
[ "$($MYSQL -e "SELECT COUNT(*) FROM proyectos")" = "5" ]; revisar "Datos listos: 5 proyectos en 2 periodos" $?

entrar admin admin.prueba@uts.edu.co; entrar dir director.prueba@uts.edu.co; entrar eva evaluador.prueba@uts.edu.co
entrar doc docente.prueba@uts.edu.co
entrar ana ana.siete@correo.uts.edu.co; entrar caro caro.siete@correo.uts.edu.co; entrar eli eli.siete@correo.uts.edu.co

echo "== Buscador (RF6): cada rol busca solo en lo suyo"
pedir anon GET /panel/buscar.jsp; [[ "$DESTINO" == *"index.jsp?aviso=sesion"* ]]; revisar "Sin sesión, al inicio de sesión" $?
pedir admin GET /panel/inicio.jsp; contiene 'panel/buscar.jsp" class'; revisar "El menú tiene Buscar" $?
[ "$(buscar admin "")" = "5" ] && sinError; revisar "El comité ve los 5 proyectos" $?
[ "$(buscar dir "")" = "2" ]; revisar "El director (solo ese rol) ve los 2 que dirige" $?
pedir dir GET /panel/buscar.jsp; ! contiene "Monografia de redes"; revisar "Y no el de otro director" $?
[ "$(buscar eva "")" = "3" ]; revisar "El evaluador ve los 3 que evalúa" $?
pedir eva GET /panel/buscar.jsp; contiene "<td>Evaluador</td>" && ! contiene "Seminario de analitica"; revisar "Con su papel (Evaluador) y sin los ajenos" $?
[ "$(buscar doc "")" = "5" ]; revisar "El docente con los dos roles ve lo que dirige, codirige y evalúa (5)" $?
pedir doc GET /panel/buscar.jsp; contiene "<td>Codirector</td>" && contiene "<td>Director</td>" && contiene "<td>Evaluador</td>"; revisar "Con su papel en cada uno" $?
pedir doc GET /panel/buscar.jsp; contiene 'director/proyecto.jsp?id=1' && contiene 'evaluador/proyecto.jsp?id=3'; revisar "Cada uno abre en su sección (Docente director o evaluador)" $?
[ "$(buscar ana "")" = "1" ]; revisar "La estudiante ve solo su proyecto" $?
pedir ana GET /panel/buscar.jsp; ! contiene "Evaluador de Prueba" && ! contiene "Docente de Prueba"; revisar "Sin ver a su evaluador ni a su codirector (RF27)" $?
[ "$(buscar caro "")" = "0" ]; revisar "A la estudiante que quitaron del proyecto no le sale" $?
[ "$(buscar eli "")" = "2" ]; revisar "Eli ve su proyecto cancelado y el nuevo" $?
pedir eli GET /panel/buscar.jsp; contiene "Proyecto anterior" && contiene 'estudiante/proyecto.jsp">Ver'; revisar "El cancelado sale como anterior y el vigente se abre" $?

echo "== Buscador: filtros"
[ "$(buscar admin "q=Rueda")" = "1" ]; revisar "Por estudiante (nombre)" $?
[ "$(buscar admin "q=beto.siete")" = "1" ]; revisar "Por estudiante (correo)" $?
[ "$(buscar admin "q=Docente+de+Prueba")" = "4" ]; revisar "Por docente (nombre): 3 que dirige y 1 que evalúa" $?
[ "$(buscar admin "q=Evaluador+de+Prueba")" = "3" ]; revisar "Por evaluador (nombre)" $?
[ "$(buscar admin "q=65-2026-1")" = "1" ]; revisar "Por código" $?
[ "$(buscar admin "q=perimetral")" = "1" ]; revisar "Por palabra de la descripción" $?
[ "$(buscar admin "fase=4")" = "2" ]; revisar "Por fase" $?
[ "$(buscar admin "estado=Cancelado")" = "1" ]; revisar "Por estado" $?
[ "$(buscar admin "periodo=2")" = "1" ]; revisar "Por periodo" $?
[ "$(buscar admin "modalidad=5")" = "1" ]; revisar "Por modalidad" $?
[ "$(buscar admin "docente=6")" = "5" ] && [ "$(buscar admin "docente=3")" = "2" ]; revisar "Por docente (director, codirector o evaluador)" $?
[ "$(buscar admin "q=cafeteria&fase=4&estado=En+curso&periodo=1&modalidad=2")" = "1" ]; revisar "Varios filtros a la vez" $?
[ "$(buscar admin "fase=abc&estado=x&periodo=-1&modalidad=99&docente=zz")" = "5" ] && sinError; revisar "Valores raros: se ignoran" $?
[ "$(buscar admin "q=no+existe+nada")" = "0" ]; revisar "Sin resultados: lo dice" $?
[ "$(buscar dir "q=Rueda")" = "1" ] && [ "$(buscar dir "q=Mora")" = "0" ]; revisar "El director busca por sus estudiantes, no por los ajenos" $?
[ "$(buscar ana "q=Beto")" = "0" ] && [ "$(buscar ana "q=65-2026-2")" = "1" ]; revisar "La estudiante busca por código o título (no por personas)" $?
pedir admin GET "/panel/buscar.jsp?q=%3Cscript%3Ealert(1)%3C%2Fscript%3E"; contiene "&lt;script&gt;" && ! contiene "<script>alert(1)"; revisar "HTML en la búsqueda: sale escapado" $?
pedir admin GET "/panel/buscar.jsp?q=%27%20OR%201%3D1%20--%20"; [ "$(resultados)" = "0" ] && sinError; revisar "SQL en la búsqueda: no entra" $?

echo "== Informes (RF15)"
pedir dir GET /admin/informes.jsp; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Solo el comité: el director no entra" $?
pedir ana GET /admin/informes.jsp; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Ni la estudiante" $?
pedir admin GET /panel/inicio.jsp; contiene 'admin/informes.jsp" class'; revisar "El menú del comité tiene Informes" $?
pedir admin GET /admin/informes.jsp; sinError && contiene "Periodo 2026-2"; revisar "Por defecto, el periodo activo" $?
dato "Proyectos" 4 && dato "Estudiantes" 6 && dato "En curso" 2 && dato "Finalizados" 2 && dato "Cancelados" 0; revisar "Resumen del periodo: 4 proyectos, 6 estudiantes (sin la quitada), 2 en curso y 2 finalizados" $?
dato "Estudiantes que aprobaron" 3; revisar "3 aprobaron: el finalizado, el Seminario y la exonerada" $?
contiene "Informe final aprobado y sustentado" && contiene "Seminario aprobado con 4,2" && contiene "Exonerado por Saber TyT"; revisar "Cada uno con cómo aprobó" $?
contiene "No hay estudiantes con el proyecto cancelado"; revisar "Sin cancelados en el periodo" $?
pedir admin GET "/admin/informes.jsp?periodo=2"; contiene "Eli Siete Paez" && contiene "Proyecto cancelado por extemporaneidad" && dato "Cancelados" 1
revisar "Periodo anterior: Eli no aprobó, con el motivo" $?
pedir admin GET "/admin/informes.jsp?periodo=todos"; dato "Proyectos" 5 && dato "Estudiantes" 6
revisar "Todos los periodos: 5 proyectos y 6 estudiantes distintos" $?
plano | grep -q "<td>Desarrollo tecnol[^<]*</td> <td class=\"text-end\">3</td> <td class=\"text-end\">5</td>"; revisar "Por modalidad: Desarrollo tecnológico con 3 proyectos y 5 estudiantes" $?
plano | grep -q "<td>Seminario</td> <td class=\"text-end\">1</td> <td class=\"text-end\">1</td>"; revisar "Seminario con 1 y 1" $?
plano | grep -q "1 estudiante</span> <span>3 proyectos" && plano | grep -q "2 estudiantes</span> <span>2 proyectos"; revisar "Por cantidad: 3 proyectos de 1 estudiante y 2 de 2" $?
contiene "window.print()"; revisar "Se puede imprimir" $?
pedir admin GET "/admin/informes.jsp?periodo=abc"; sinError && contiene "Todos los periodos"; revisar "Periodo raro: todos" $?

echo "== RNF3: búsquedas con 5.000 proyectos"
$MYSQL <<'SQL'
INSERT INTO proyectos (codigo, titulo, descripcion, modalidad_id, nivel_id, periodo_id, fase_id, estado, director_id, evaluador_id)
SELECT CONCAT('C-', n), CONCAT('Proyecto de carga ', n), 'Carga para medir el buscador', 1 + (n % 4), 1, 1 + (n % 2), 2 + (n % 5), 'En curso', 3, 4
FROM (SELECT a.d + 10 * b.d + 100 * c.d + 1000 * e.d AS n
      FROM (SELECT 0 d UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
           (SELECT 0 d UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
           (SELECT 0 d UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c,
           (SELECT 0 d UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) e) numeros;
ANALYZE TABLE proyectos;
SQL
[ "$($MYSQL -e "SELECT COUNT(*) FROM proyectos")" = "5005" ]; revisar "5.005 proyectos en la base" $?
LENTO=""
for QS in "" "q=carga+4321" "fase=4&estado=En+curso" "q=carga&periodo=2&modalidad=3" "docente=4&fase=3"; do
    pedir admin GET "/panel/buscar.jsp?$QS"
    awk "BEGIN { exit !($TIEMPO < 2) }" && sinError || LENTO="$LENTO [${QS:-sin filtros}: ${TIEMPO}s]"
done
[ -z "$LENTO" ]; revisar "El comité busca en menos de 2 s (con y sin filtros)${LENTO}" $?
pedir admin GET /panel/buscar.jsp; contiene "Más de 200 proyectos"; revisar "Con más de 200 resultados, muestra 200 y pide afinar" $?
[ "$(buscar admin "q=carga+4321")" = "1" ]; revisar "Y encuentra uno entre 5.000" $?
pedir dir GET "/panel/buscar.jsp?q=carga&fase=3"; awk "BEGIN { exit !($TIEMPO < 2) }" && sinError; revisar "El director también, en menos de 2 s (${TIEMPO}s)" $?
pedir admin GET "/admin/informes.jsp?periodo=todos"; awk "BEGIN { exit !($TIEMPO < 2) }" && sinError && dato "Proyectos" 5005; revisar "Los informes con 5.005 proyectos, en menos de 2 s (${TIEMPO}s)" $?

echo ""
echo "Resultado: $OK OK, $FALLA fallas"
