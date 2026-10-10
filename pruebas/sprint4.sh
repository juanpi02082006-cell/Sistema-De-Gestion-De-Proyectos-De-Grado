#!/usr/bin/env bash
# Pruebas de punta a punta del Sprint 4: registro del estudiante (RF24), habilitación (RF33),
# usuarios (RF7), periodos y calendario con las sesiones del comité (RF3), modalidades (RF4), banco de
# ideas (RF10, RF25), pago de la fase 1 (RF29, RF32) y el diseño (tildes, menú lateral y fases).
# Se corren sobre la base recién importada (usuarios de prueba con la clave 123456).
B="http://localhost:8080/segundo-parcial"
T="$(dirname "$0")/tmp/sprint4"; rm -rf "$T"; mkdir -p "$T"
OK=0; FALLA=0
MYSQL="/c/xampp/mysql/bin/mysql.exe -u root -N -B -D sistemas_proyectos_grado"
HOY=$(date +%F); MANANA=$(date -d tomorrow +%F); AYER=$(date -d yesterday +%F); EN30=$(date -d "+30 days" +%F)

revisar() { if [ "$2" -eq 0 ]; then echo "  OK    $1"; OK=$((OK+1)); else echo "  FALLA $1"; FALLA=$((FALLA+1)); fi; }
pedir() {
    local jar="$T/$1"; local metodo="$2"; local ruta="$3"; shift 3
    if [ "$metodo" = "POST" ]; then
        RES=$(curl -s -o "$T/cuerpo.html" -w "%{http_code} %{redirect_url}" -b "$jar" -c "$jar" -X POST "$@" "$B$ruta")
    else
        RES=$(curl -s -o "$T/cuerpo.html" -w "%{http_code} %{redirect_url}" -b "$jar" -c "$jar" "$B$ruta")
    fi
    CODIGO="${RES%% *}"; DESTINO="${RES#* }"
}
contiene() { grep -q "$1" "$T/cuerpo.html"; }
sinError() { ! grep -q "Exception\|HTTP Status 500" "$T/cuerpo.html"; }
entrar() { pedir "$1" POST /acceso/validar.jsp --data-urlencode "correo=$2" --data-urlencode "clave=${3:-123456}"; }
registrar() { # correo, documento, nivel, plan, créditos, metodología(on|""), clave2
    pedir anon POST /acceso/registrar.jsp --data "nombre=Ana%20Mar%C3%ADa%20P%C3%A9rez" --data-urlencode "tipo_documento=1" \
        --data-urlencode "numero_documento=$2" --data-urlencode "correo=$1" --data-urlencode "clave=Clave123" \
        --data-urlencode "clave2=${7:-Clave123}" --data-urlencode "nivel=$3" --data "carrera=Tecnolog%C3%ADa%20en%20Sistemas" \
        --data-urlencode "plan_estudios=$4" --data-urlencode "porcentaje_creditos=$5" ${6:+--data-urlencode "metodologia=$6"}
}

echo "== Registro del estudiante (RF24)"
pedir anon GET /index.jsp; contiene "registro.jsp"; revisar "El login tiene el enlace para registrarse" $?
pedir anon GET /registro.jsp; [ "$CODIGO" = 200 ] && contiene "Crea tu cuenta"; revisar "La página de registro abre" $?
registrar ana@gmail.com 3000000001 1 Anterior 80 on
contiene "Usa tu correo institucional"; revisar "Correo de Gmail: rechazado" $?
contiene 'value="3000000001"'; revisar "Si hay error, conserva lo escrito" $?
registrar ana.perez@correo.uts.edu.co 3000000001 1 Anterior 80 on Otra
contiene "no coinciden"; revisar "Contraseñas distintas: rechazado" $?
registrar ana.perez@correo.uts.edu.co 3000000001 1 Anterior 120 on
contiene "entre 0 y 100"; revisar "Créditos 120: rechazado" $?
registrar ana.perez@correo.uts.edu.co 3000000001 1 Otro 80 on
contiene "anterior o posterior al decreto"; revisar "Plan de estudios inválido: rechazado" $?
registrar Ana.Perez@Correo.UTS.edu.co 3000000001 1 Anterior 80 on
[[ "$CODIGO" = 302 && "$DESTINO" == *"aviso=registrado"* ]]; revisar "Registro válido: vuelve al login con aviso" $?
FILA=$($MYSQL -e "SELECT CONCAT(u.correo,'|',u.nivel_id,'|',u.plan_estudios,'|',u.porcentaje_creditos,'|',u.metodologia_aprobada,'|',GROUP_CONCAT(ur.rol_id),'|',HEX(u.nombre)) FROM usuarios u JOIN usuario_roles ur ON ur.usuario_id=u.id WHERE u.numero_documento='3000000001' GROUP BY u.id")
[ "$FILA" = "ana.perez@correo.uts.edu.co|1|Anterior|80|1|5|416E61204D6172C3AD612050C3A972657A" ]; revisar "En la base: correo en minúsculas, rol Estudiante, datos académicos y tildes" $?
pedir anon GET "/index.jsp?aviso=registrado"; contiene "Tu cuenta quedó creada"; revisar "El login muestra el aviso de cuenta creada" $?
registrar ana.perez@correo.uts.edu.co 3000000002 1 Anterior 80 on
contiene "Ya hay una cuenta con ese correo"; revisar "Correo repetido: rechazado" $?
registrar otra@correo.uts.edu.co 3000000001 1 Anterior 80 on
contiene "Ya hay una cuenta con ese número de documento"; revisar "Documento repetido: rechazado" $?
entrar ana ana.perez@correo.uts.edu.co Clave123
[[ "$DESTINO" == *"/panel/inicio.jsp" ]]; revisar "La estudiante registrada inicia sesión" $?

echo "== Habilitación (RF33)"
pedir ana GET /estudiante/habilitacion.jsp; contiene "Estás habilitado" && sinError; revisar "80 % y Metodología: habilitada" $?
contiene "Monografía"; revisar "Le muestra las modalidades que puede tomar" $?
contiene "Tecnol"; revisar "Muestra su nivel (los alias de las columnas funcionan)" $?
entrar est estudiante.prueba@correo.uts.edu.co
pedir est GET /estudiante/habilitacion.jsp; contiene "Todavía no estás habilitado" && contiene "Sin registrar"; revisar "Sin Metodología registrada: no habilitado y dice qué falta" $?
registrar beto@correo.uts.edu.co 3000000003 1 Anterior 60 on
entrar beto beto@correo.uts.edu.co Clave123
pedir beto GET /estudiante/habilitacion.jsp; contiene "No cumple" && contiene "Todavía no estás habilitado"; revisar "60 % de créditos: no habilitado" $?
registrar caro@correo.uts.edu.co 3000000004 2 Nuevo 10
entrar caro caro@correo.uts.edu.co Clave123
pedir caro GET /estudiante/habilitacion.jsp; contiene "Estás habilitado" && contiene "Por confirmar"; revisar "Plan nuevo: habilitado, con la matrícula de Seminario por confirmar" $?
entrar dir director.prueba@uts.edu.co
pedir dir GET /estudiante/habilitacion.jsp
[[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un docente no entra a la habilitación" $?

echo "== Usuarios: filtros y datos académicos (RF7)"
entrar admin admin.prueba@uts.edu.co
pedir admin GET "/admin/usuarios.jsp?plan=Nuevo"; contiene "caro@correo.uts.edu.co" && ! contiene "ana.perez"; revisar "Filtro por plan nuevo" $?
pedir admin GET "/admin/usuarios.jsp?nivel=2"; contiene "caro@correo.uts.edu.co" && ! contiene "ana.perez"; revisar "Filtro por nivel" $?
pedir admin GET "/admin/usuarios.jsp?q=Carrera%20de%20prueba"; contiene "estudiante.prueba@correo.uts.edu.co"; revisar "Búsqueda por carrera" $?
$MYSQL -e "UPDATE usuarios SET activo=0 WHERE correo='beto@correo.uts.edu.co'"
pedir admin GET "/admin/usuarios.jsp?estado=inactivo"; contiene "beto@correo.uts.edu.co" && ! contiene "ana.perez"; revisar "Filtro por estado inactivo" $?
$MYSQL -e "UPDATE usuarios SET activo=1 WHERE correo='beto@correo.uts.edu.co'"
pedir admin GET "/admin/usuario-form.jsp?id=5"; contiene 'id="plan_estudios"' && contiene 'id="metodologia"'; revisar "El formulario tiene plan y Metodología" $?
pedir admin POST /admin/usuario-guardar.jsp --data-urlencode "id=5" --data-urlencode "nombre=Estudiante de Prueba" --data-urlencode "tipo_documento=1" \
    --data-urlencode "numero_documento=1000000005" --data-urlencode "correo=estudiante.prueba@correo.uts.edu.co" --data-urlencode "roles=5" \
    --data-urlencode "nivel=1" --data-urlencode "carrera=Carrera de prueba" --data-urlencode "porcentaje_creditos=80" \
    --data-urlencode "plan_estudios=Anterior" --data-urlencode "metodologia=on" --data-urlencode "activo=on"
[[ "$DESTINO" == *"ok=usuario-actualizado"* ]]; revisar "El admin actualiza los datos académicos" $?
[ "$($MYSQL -e "SELECT CONCAT(plan_estudios,'|',metodologia_aprobada) FROM usuarios WHERE id=5")" = "Anterior|1" ]; revisar "Quedaron plan Anterior y Metodología aprobada" $?
pedir est GET /estudiante/habilitacion.jsp; contiene "Estás habilitado"; revisar "Con eso, el estudiante queda habilitado" $?

echo "== Periodos y calendario (RF3)"
pedir est GET /panel/calendario.jsp; contiene "no hay un periodo activo"; revisar "Sin periodo activo, el calendario lo dice" $?
pedir admin POST /admin/periodo-guardar.jsp --data-urlencode "nombre=2026-2" --data-urlencode "fecha_inicio_semestre=$HOY" \
    --data-urlencode "fecha_cierre_banco=$EN30" --data-urlencode "fecha_limite_pago=2026-12-01" --data-urlencode "fecha_limite_propuestas=2026-12-15" \
    --data-urlencode "fecha_inicio_informe_final=2027-03-01" --data-urlencode "fecha_fin_informe_final=2027-06-30"
[[ "$DESTINO" == *"ok=periodo-creado"* ]]; revisar "Crear periodo" $?
[ "$($MYSQL -e "SELECT CONCAT(estado,'|',fecha_cierre_banco) FROM periodos WHERE nombre='2026-2'")" = "Planeado|$EN30" ]; revisar "Queda Planeado, con sus fechas" $?
P1=$($MYSQL -e "SELECT id FROM periodos WHERE nombre='2026-2'")
pedir admin POST /admin/periodo-guardar.jsp --data-urlencode "nombre=2027-1" --data-urlencode "fecha_cierre_banco=2027-02-30"
contiene "Alguna fecha no es válida"; revisar "Fecha imposible (30 de febrero): rechazada" $?
pedir admin POST /admin/periodo-guardar.jsp --data-urlencode "nombre=2027-1" --data "fecha_cierre_banco=ma%C3%B1ana"
contiene "Alguna fecha no es válida"; revisar "Fecha con texto: rechazada" $?
pedir admin POST /admin/periodo-guardar.jsp --data-urlencode "nombre=2027-1" --data-urlencode "fecha_inicio_informe_final=2027-06-01" --data-urlencode "fecha_fin_informe_final=2027-01-01"
contiene "debe ser anterior"; revisar "Informe final con inicio después del fin: rechazado" $?
pedir admin POST /admin/periodo-guardar.jsp --data-urlencode "nombre=2026-2"
contiene "Ya existe un periodo con ese nombre"; revisar "Periodo repetido: rechazado" $?
pedir admin POST /admin/periodo-estado.jsp --data-urlencode "id=$P1" --data-urlencode "accion=activar"
[[ "$DESTINO" == *"ok=periodo-activado"* ]]; revisar "Activar periodo" $?
pedir est GET /panel/calendario.jsp; contiene "Periodo 2026-2" && contiene "Abierto"; revisar "El calendario muestra el periodo activo con el banco abierto" $?
pedir admin POST /admin/periodo-guardar.jsp --data-urlencode "nombre=2027-1"
P2=$($MYSQL -e "SELECT id FROM periodos WHERE nombre='2027-1'")
pedir admin POST /admin/periodo-estado.jsp --data-urlencode "id=$P2" --data-urlencode "accion=activar"
[[ "$DESTINO" == *"error=otro-periodo-activo"* ]]; revisar "No se activan dos periodos a la vez" $?
pedir admin POST /admin/periodo-eliminar.jsp --data-urlencode "id=$P2"
[[ "$DESTINO" == *"ok=periodo-eliminado"* ]]; revisar "Eliminar un periodo sin ideas ni proyectos" $?
pedir est GET /admin/periodos.jsp
[[ "$DESTINO" == *"error=denegado"* ]]; revisar "El estudiante no entra a los periodos" $?
pedir est POST /admin/periodo-estado.jsp --data-urlencode "id=$P1" --data-urlencode "accion=cerrar"
[[ "$DESTINO" == *"error=denegado"* ]]; revisar "El estudiante no puede cerrar un periodo" $?

echo "== Modalidades (RF4)"
pedir est GET /panel/modalidades.jsp; contiene "Proyecto de investigación" && contiene "Interdisciplinario: hasta 4" && ! contiene "modalidad-form.jsp"; revisar "El estudiante ve las modalidades, sin editar" $?
pedir admin POST /admin/modalidad-guardar.jsp --data-urlencode "id=3" --data-urlencode "max_integrantes=5"
contiene "debe ser 1, 2, 3 o 4"; revisar "Máximo de 5 integrantes: rechazado" $?
pedir admin POST /admin/modalidad-guardar.jsp --data-urlencode "id=3" --data-urlencode "max_integrantes=2" --data "descripcion=Revisi%C3%B3n%20de%20literatura"
[[ "$DESTINO" == *"ok=modalidad-actualizada"* ]]; revisar "El admin edita una modalidad" $?
pedir est POST /admin/modalidad-guardar.jsp --data-urlencode "id=3" --data-urlencode "max_integrantes=1"
[[ "$DESTINO" == *"error=denegado"* ]]; revisar "El estudiante no puede editar modalidades" $?

echo "== Banco de ideas: los docentes registran y el comité aprueba (RF10)"
pedir dir POST /ideas/idea-guardar.jsp --data "titulo=Sistema%20de%20turnos%20<script>alert(1)</script>" --data "descripcion=Para%20la%20cafeter%C3%ADa" \
    --data-urlencode "nivel=1" --data-urlencode "modalidad=2" --data-urlencode "linea=1"
[[ "$DESTINO" == *"ok=idea-creada"* ]]; revisar "El director registra una idea de tecnología" $?
I1=$($MYSQL -e "SELECT id FROM ideas WHERE titulo LIKE 'Sistema de turnos%'")
[ "$($MYSQL -e "SELECT CONCAT(origen,'|',estado,'|',periodo_id) FROM ideas WHERE id=$I1")" = "Docente|Pendiente|$P1" ]; revisar "Queda Docente, Pendiente y en el periodo activo" $?
pedir dir POST /ideas/idea-guardar.jsp --data-urlencode "titulo=Red de sensores" --data-urlencode "nivel=2"
I2=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Red de sensores'")
pedir dir POST /ideas/idea-guardar.jsp --data-urlencode "titulo=Sin modalidad" --data-urlencode "nivel=1"
I3=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Sin modalidad'")
pedir dir POST /ideas/idea-guardar.jsp --data-urlencode "titulo=" --data-urlencode "nivel=1"
contiene "Escribe el título"; revisar "Idea sin título: rechazada" $?
pedir dir GET /ideas/banco.jsp; contiene "Mis ideas" && contiene "Red de sensores"; revisar "El director ve sus ideas" $?
pedir admin GET "/ideas/banco.jsp?estado=Todas"; contiene "Director de Prueba"; revisar "El comité ve quién propuso cada idea" $?
contiene "&lt;script&gt;"; revisar "El título se muestra escapado (sin XSS)" $?
pedir ana GET /ideas/banco.jsp; ! contiene "Sistema de turnos"; revisar "Una idea pendiente no la ven los estudiantes" $?
pedir admin GET /ideas/banco.jsp; contiene "Red de sensores" && contiene "idea-revisar.jsp"; revisar "El comité ve las pendientes con el formulario de revisión" $?
pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$I1" --data-urlencode "decision=aprobar" --data-urlencode "observacion=   "
[[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Aprobar sin observación: rechazado" $?
for I in $I1 $I2 $I3; do
    pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$I" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Pertinente"
done
[[ "$DESTINO" == *"ok=idea-aprobada"* ]]; revisar "El comité aprueba las ideas" $?
[ "$($MYSQL -e "SELECT CONCAT(estado,'|',revisada_por,'|',observacion_revision) FROM ideas WHERE id=$I1")" = "Aprobada|1|Pertinente" ]; revisar "Queda aprobada, con quién revisó y la observación" $?
pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$I1" --data-urlencode "decision=rechazar" --data-urlencode "observacion=x"
[[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "Una idea ya revisada no se vuelve a revisar" $?
pedir dir POST /ideas/idea-revisar.jsp --data-urlencode "id=$I2" --data-urlencode "decision=rechazar" --data-urlencode "observacion=x"
[[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un docente no puede revisar ideas" $?
pedir dir GET "/ideas/idea-form.jsp?id=$I1"
[[ "$DESTINO" == *"error=idea-no-editable"* ]]; revisar "Una idea aprobada ya no se edita" $?

echo "== Banco de ideas: el estudiante toma una idea (RF25)"
pedir ana GET /ideas/banco.jsp; contiene "Sistema de turnos" && ! contiene "Red de sensores"; revisar "La estudiante de tecnología no ve ideas de ingeniería" $?
contiene "Tomar esta idea"; revisar "Habilitada y con el banco abierto: puede tomar ideas" $?
pedir beto GET /ideas/banco.jsp; ! contiene "Tomar esta idea" && contiene "Revisa tu habilitación"; revisar "No habilitado: no ve el botón y se le explica" $?
pedir beto POST /ideas/idea-tomar.jsp --data-urlencode "id=$I1"
[[ "$DESTINO" == *"error=no-habilitado"* ]]; revisar "No habilitado: no puede tomar la idea" $?
pedir ana POST /ideas/idea-tomar.jsp --data-urlencode "id=$I2"
[[ "$DESTINO" == *"error=idea-no-disponible"* ]]; revisar "Tecnología no puede tomar una idea de ingeniería" $?
pedir ana POST /ideas/idea-tomar.jsp --data-urlencode "id=$I3"
[[ "$DESTINO" == *"error=modalidad-requerida"* ]]; revisar "Idea sin modalidad: debe escogerla" $?
pedir ana POST /ideas/idea-tomar.jsp --data-urlencode "id=$I1"
[[ "$DESTINO" == *"ok=idea-tomada"* ]]; revisar "La estudiante toma la idea" $?
ANA=$($MYSQL -e "SELECT id FROM usuarios WHERE correo='ana.perez@correo.uts.edu.co'")
FILA=$($MYSQL -e "SELECT CONCAT(p.idea_id,'|',p.modalidad_id,'|',p.nivel_id,'|',p.periodo_id,'|',(SELECT orden FROM fases WHERE id=p.fase_id),'|',p.estado,'|',pe.vigente) FROM proyectos p JOIN proyecto_estudiantes pe ON pe.proyecto_id=p.id WHERE pe.estudiante_id=$ANA")
[ "$FILA" = "$I1|2|1|$P1|1|Pendiente|1" ]; revisar "Proyecto creado: idea, modalidad, nivel, periodo, fase 1 y vigente" $?
[ "$($MYSQL -e "SELECT estado FROM ideas WHERE id=$I1")" = "Tomada" ]; revisar "La idea queda Tomada" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM historial h JOIN proyectos p ON p.id=h.proyecto_id JOIN proyecto_estudiantes pe ON pe.proyecto_id=p.id WHERE pe.estudiante_id=$ANA AND h.accion='Estado'")" = "1" ]; revisar "Queda en el historial" $?
pedir ana GET /panel/inicio.jsp; contiene "Tu proyecto:" && contiene "Fase 1: Pago"; revisar "El inicio muestra su proyecto en la fase 1 (Pago)" $?
pedir ana POST /ideas/idea-tomar.jsp --data-urlencode "id=$I3" --data-urlencode "modalidad=3"
[[ "$DESTINO" == *"error=proyecto-vigente"* ]]; revisar "Con un proyecto vigente no toma otra idea" $?
pedir est POST /ideas/idea-tomar.jsp --data-urlencode "id=$I1"
[[ "$DESTINO" == *"error=idea-no-disponible"* ]]; revisar "Una idea tomada ya no está disponible" $?
pedir est POST /ideas/idea-tomar.jsp --data-urlencode "id=$I3" --data-urlencode "modalidad=3"
[[ "$DESTINO" == *"ok=idea-tomada"* ]]; revisar "Otro estudiante toma la idea sin modalidad, escogiendo Monografía" $?
[ "$($MYSQL -e "SELECT modalidad_id FROM proyectos WHERE idea_id=$I3")" = "3" ]; revisar "Su proyecto quedó en Monografía" $?

echo "== Propuesta propia del estudiante (RF10)"
pedir caro POST /ideas/idea-guardar.jsp --data-urlencode "titulo=App de reciclaje" --data-urlencode "descripcion=Mi idea" --data-urlencode "nivel=1"
[[ "$DESTINO" == *"ok=idea-creada"* ]]; revisar "La estudiante formula su propuesta" $?
I4=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='App de reciclaje'")
[ "$($MYSQL -e "SELECT CONCAT(origen,'|',nivel_id,'|',estado) FROM ideas WHERE id=$I4")" = "Estudiante|2|Pendiente" ]; revisar "Queda de origen Estudiante y de SU nivel (ingeniería), aunque mande otro" $?
pedir dir GET "/ideas/idea-form.jsp?id=$I4"
[[ "$DESTINO" == *"error=idea-no-editable"* ]]; revisar "Un docente no edita la propuesta de un estudiante" $?
pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$I4" --data-urlencode "decision=rechazar" --data-urlencode "observacion=Falta delimitar el alcance"
[[ "$DESTINO" == *"ok=idea-rechazada"* ]]; revisar "El comité la rechaza con observación" $?
pedir caro GET /ideas/banco.jsp; contiene "Falta delimitar el alcance"; revisar "La estudiante ve la observación del comité" $?
pedir caro POST /ideas/idea-guardar.jsp --data-urlencode "id=$I4" --data-urlencode "titulo=App de reciclaje para la UTS" --data-urlencode "descripcion=Ajustada"
[[ "$DESTINO" == *"ok=idea-actualizada"* ]]; revisar "La corrige y la vuelve a enviar" $?
[ "$($MYSQL -e "SELECT CONCAT(estado,'|',IFNULL(observacion_revision,'-')) FROM ideas WHERE id=$I4")" = "Pendiente|-" ]; revisar "Vuelve a quedar pendiente, sin la observación anterior" $?
pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$I4" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Aprobada"
registrar dani@correo.uts.edu.co 3000000005 2 Anterior 90 on
entrar dani dani@correo.uts.edu.co Clave123
pedir dani GET /ideas/banco.jsp; ! contiene "App de reciclaje"; revisar "Otro estudiante de ingeniería no ve la propuesta ajena" $?
pedir dani POST /ideas/idea-tomar.jsp --data-urlencode "id=$I4" --data-urlencode "modalidad=1"
[[ "$DESTINO" == *"error=idea-no-disponible"* ]]; revisar "Ni puede tomarla" $?
pedir caro POST /ideas/idea-tomar.jsp --data-urlencode "id=$I4" --data-urlencode "modalidad=1"
[[ "$DESTINO" == *"ok=idea-tomada"* ]]; revisar "Quien la formuló sí la toma" $?

echo "== Cierre del banco y eliminación de ideas"
pedir dir POST /ideas/idea-guardar.jsp --data-urlencode "titulo=Idea tardia" --data-urlencode "nivel=2" --data-urlencode "modalidad=1"
I5=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea tardia'")
pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$I5" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
$MYSQL -e "UPDATE periodos SET fecha_cierre_banco='$AYER' WHERE id=$P1"
pedir dani GET /ideas/banco.jsp; contiene "El banco cerró" && ! contiene "Tomar esta idea"; revisar "Banco cerrado: lo dice y no deja tomar" $?
pedir dani POST /ideas/idea-tomar.jsp --data-urlencode "id=$I5"
[[ "$DESTINO" == *"error=banco-cerrado"* ]]; revisar "Banco cerrado: no se toman ideas" $?
$MYSQL -e "UPDATE periodos SET fecha_cierre_banco='$EN30' WHERE id=$P1"
pedir dir POST /ideas/idea-guardar.jsp --data-urlencode "titulo=Borrador" --data-urlencode "nivel=1"
I6=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Borrador'")
pedir ana POST /ideas/idea-eliminar.jsp --data-urlencode "id=$I6"
[[ "$DESTINO" == *"error=idea-no-editable"* ]]; revisar "Nadie elimina la idea de otro" $?
pedir dir POST /ideas/idea-eliminar.jsp --data-urlencode "id=$I6"
[[ "$DESTINO" == *"ok=idea-eliminada"* ]]; revisar "El docente elimina su idea pendiente" $?
pedir dir POST /ideas/idea-eliminar.jsp --data-urlencode "id=$I5"
[[ "$DESTINO" == *"error=idea-no-editable"* ]]; revisar "Una idea aprobada no se elimina" $?
pedir admin POST /admin/periodo-eliminar.jsp --data-urlencode "id=$P1"
[[ "$DESTINO" == *"error=periodo-con-registros"* ]]; revisar "Un periodo con ideas y proyectos no se elimina" $?
pedir admin POST /admin/periodo-estado.jsp --data-urlencode "id=$P1" --data-urlencode "accion=cerrar"
[[ "$DESTINO" == *"ok=periodo-cerrado"* ]]; revisar "Cerrar el periodo" $?
pedir dani POST /ideas/idea-tomar.jsp --data-urlencode "id=$I5"
[[ "$DESTINO" == *"error=sin-periodo-activo"* ]]; revisar "Sin periodo activo: no se toman ideas" $?

echo "== Menú según el rol"
pedir ana GET /panel/inicio.jsp; contiene "estudiante/habilitacion.jsp" && contiene "ideas/banco.jsp" && ! contiene "admin/periodos.jsp"; revisar "Menú del estudiante" $?
pedir dir GET /panel/inicio.jsp; contiene "ideas/banco.jsp" && ! contiene "estudiante/habilitacion.jsp"; revisar "Menú del docente" $?
pedir admin GET /panel/inicio.jsp; contiene "admin/periodos.jsp" && contiene "Ideas por revisar"; revisar "Menú e inicio del administrador" $?

echo "== Diseño: tildes bien escritas en todas las páginas"
MOJIBAKE=0
for R in "ana /panel/inicio.jsp" "ana /estudiante/proyecto.jsp" "ana /estudiante/habilitacion.jsp" "ana /ideas/banco.jsp" "admin /admin/usuarios.jsp" "admin /admin/periodos.jsp" "dir /panel/modalidades.jsp"; do
    set -- $R; pedir "$1" GET "$2"; grep -q "Ã" "$T/cuerpo.html" && MOJIBAKE=1
done
[ "$MOJIBAKE" = 0 ]; revisar "Ninguna página muestra letras raras (Ã) en vez de tildes" $?
pedir ana GET /panel/inicio.jsp; contiene 'class="app-lateral"' && contiene "app-fase actual"; revisar "Menú lateral y seguimiento por fases con la fase actual marcada" $?

echo "== Pago de la fase 1 (RF29, RF32)"
pedir admin POST /admin/periodo-estado.jsp --data-urlencode "id=$P1" --data-urlencode "accion=activar"
printf '%%PDF-1.4\n%% recibo de prueba\n' > "$T/recibo.pdf"
printf 'no es un pdf' > "$T/recibo.docx"
head -c 16000000 /dev/zero > "$T/grande.pdf"
ARCHIVOS="$(dirname "$0")/../WEB-INF/archivos"
pedir ana GET /estudiante/proyecto.jsp; contiene "Pago de la modalidad" && contiene 'enctype="multipart/form-data"'; revisar "Mi proyecto muestra el formulario del recibo" $?
pedir ana POST /estudiante/pago-guardar.jsp -F "recibo=@$T/recibo.docx"
[[ "$DESTINO" == *"error=archivo-invalido"* ]]; revisar "Un archivo que no es PDF: rechazado" $?
pedir ana POST /estudiante/pago-guardar.jsp -F "otro=x"
[[ "$DESTINO" == *"error=archivo-requerido"* ]]; revisar "Sin archivo: rechazado" $?
pedir ana POST /estudiante/pago-guardar.jsp -F "recibo=@$T/grande.pdf"
[[ "$DESTINO" == *"error=archivo-grande"* || "$CODIGO" = 413 || "$CODIGO" = 000 ]]; revisar "Más de 15 MB: rechazado" $?
pedir ana POST /estudiante/pago-guardar.jsp -F "recibo=@$T/recibo.pdf;type=application/pdf"
[[ "$DESTINO" == *"ok=pago-subido"* ]]; revisar "Recibo en PDF: se sube" $?
FILA=$($MYSQL -e "SELECT CONCAT(e.id,'|',e.nombre_archivo,'|',e.ruta_archivo,'|',f.orden) FROM entregas e JOIN fases f ON f.id=e.fase_id JOIN proyecto_estudiantes pe ON pe.proyecto_id=e.proyecto_id WHERE pe.estudiante_id=$ANA AND e.tipo='Recibo de pago'")
IDREC="${FILA%%|*}"; RUTA=$(echo "$FILA" | cut -d'|' -f3)
[[ "$FILA" == *"|recibo.pdf|recibo-p"*".pdf|1" ]]; revisar "En la base: nombre original, nombre guardado y fase 1" $?
[ -f "$ARCHIVOS/$RUTA" ]; revisar "El archivo quedó en WEB-INF/archivos" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "recibo.pdf" && contiene "archivos/ver.jsp?id=$IDREC"; revisar "Mi proyecto lista el recibo subido" $?
CT=$(curl -s -o "$T/bajado.pdf" -w "%{http_code} %{content_type}" -b "$T/ana" "$B/archivos/ver.jsp?id=$IDREC")
[[ "$CT" == "200 application/pdf"* ]] && cmp -s "$T/bajado.pdf" "$T/recibo.pdf"; revisar "La estudiante ve su recibo (PDF igual al subido)" $?
pedir admin GET "/archivos/ver.jsp?id=$IDREC"; [ "$CODIGO" = 200 ]; revisar "El comité también lo ve" $?
pedir dani GET "/archivos/ver.jsp?id=$IDREC"
[[ "$DESTINO" == *"error=denegado"* ]]; revisar "Otro estudiante no puede verlo" $?
pedir anon GET "/archivos/ver.jsp?id=$IDREC"
[[ "$DESTINO" == *"aviso=sesion"* ]]; revisar "Sin sesión no se ve" $?
CODIGO=$(curl -s -o /dev/null -w "%{http_code}" "$B/WEB-INF/archivos/$RUTA"); [ "$CODIGO" = 404 ]; revisar "WEB-INF/archivos no se abre desde el navegador" $?
pedir caro GET /estudiante/proyecto.jsp; contiene "lo cubre la matr"; revisar "Plan nuevo: no necesita recibo" $?
pedir caro POST /estudiante/pago-guardar.jsp -F "recibo=@$T/recibo.pdf"
[[ "$DESTINO" == *"error=pago-no-aplica"* ]]; revisar "Plan nuevo: no sube recibo" $?
$MYSQL -e "UPDATE periodos SET fecha_limite_pago='$AYER' WHERE id=$P1"
pedir ana POST /estudiante/pago-guardar.jsp -F "recibo=@$T/recibo.pdf"
[[ "$DESTINO" == *"error=pago-vencido"* ]]; revisar "Después de la fecha límite: no se sube" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Ya pas"; revisar "Mi proyecto avisa que venció el plazo" $?
$MYSQL -e "UPDATE periodos SET fecha_limite_pago='$EN30' WHERE id=$P1"
$MYSQL -e "UPDATE proyectos p JOIN proyecto_estudiantes pe ON pe.proyecto_id=p.id SET p.fase_id=(SELECT id FROM fases WHERE orden=2) WHERE pe.estudiante_id=$ANA"
pedir ana POST /estudiante/pago-guardar.jsp -F "recibo=@$T/recibo.pdf"
[[ "$DESTINO" == *"error=fase-no-permite"* ]]; revisar "Fuera de la fase 1: no se sube" $?
pedir ana GET /panel/inicio.jsp; contiene "app-fase completa" && contiene "Fase 2: Propuesta I"; revisar "En la fase 2: las fases 0 y 1 salen completas" $?
$MYSQL -e "UPDATE proyectos p JOIN proyecto_estudiantes pe ON pe.proyecto_id=p.id SET p.fase_id=(SELECT id FROM fases WHERE orden=1) WHERE pe.estudiante_id=$ANA"
pedir est GET /estudiante/pago-guardar.jsp
[[ "$DESTINO" == *"/estudiante/proyecto.jsp" ]]; revisar "Por GET no sube nada" $?
pedir dir POST /estudiante/pago-guardar.jsp -F "recibo=@$T/recibo.pdf"
[[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un docente no sube recibos" $?
rm -f "$ARCHIVOS"/recibo-p*.pdf

echo "== Calendario de sesiones del comité (RF3, RF16)"
EN7=$(date -d "+7 days" +%F)
pedir admin GET "/admin/sesiones.jsp?periodo=$P1"; [ "$CODIGO" = 200 ] && contiene "Agregar sesi"; revisar "La página de sesiones abre" $?
pedir admin POST /admin/sesion-guardar.jsp --data-urlencode "periodo=$P1" --data-urlencode "fecha=$EN7" --data-urlencode "hora=14:00" --data-urlencode "lugar=Sala 201"
[[ "$DESTINO" == *"ok=sesion-creada"* ]]; revisar "Agregar una sesión" $?
pedir admin POST /admin/sesion-guardar.jsp --data-urlencode "periodo=$P1" --data-urlencode "fecha=$EN7"
[[ "$DESTINO" == *"error=sesion-duplicada"* ]]; revisar "Dos sesiones el mismo día: rechazado" $?
pedir admin POST /admin/sesion-guardar.jsp --data-urlencode "periodo=$P1" --data-urlencode "fecha=2027-02-30"
[[ "$DESTINO" == *"error=sesion-invalida"* ]]; revisar "Fecha imposible: rechazada" $?
pedir admin POST /admin/sesion-guardar.jsp --data-urlencode "periodo=$P1" --data-urlencode "fecha=$MANANA" --data-urlencode "hora=25:00"
[[ "$DESTINO" == *"error=sesion-invalida"* ]]; revisar "Hora imposible: rechazada" $?
pedir ana GET /panel/calendario.jsp; contiene "Sala 201" && contiene "2:00 p"; revisar "El calendario muestra la sesión con su hora y lugar" $?
IDSES=$($MYSQL -e "SELECT id FROM sesiones_comite WHERE periodo_id=$P1")
pedir ana POST /admin/sesion-guardar.jsp --data-urlencode "periodo=$P1" --data-urlencode "fecha=$MANANA"
[[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un estudiante no agrega sesiones" $?
pedir admin POST /admin/sesion-eliminar.jsp --data-urlencode "id=$IDSES" --data-urlencode "periodo=$P1"
[[ "$DESTINO" == *"ok=sesion-eliminada"* ]]; revisar "Quitar una sesión" $?
pedir admin GET "/admin/sesiones.jsp?periodo=99999"
[[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "Un periodo que no existe: vuelve con aviso" $?

echo
echo "Resultado: $OK bien, $FALLA con falla"
