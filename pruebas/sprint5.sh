#!/usr/bin/env bash
# Pruebas de punta a punta del Sprint 5: el comité revisa el recibo de pago (RF32,
# observación obligatoria RF34), asigna director y evaluador (RF11, RF27) y el proyecto
# pasa a la fase 2 cuando tiene el pago aprobado (o no aplica) y director. En la fase 2 el
# estudiante sube el FDC-124 por versiones (RF26, RF30, RF43) y lo envía al director, que
# lo ve en sus proyectos (RF18, RF19); el proyecto pasa a la fase 3. En la fase 3 el
# director la devuelve (vuelve a la fase 2) o la aprueba con el reporte de Turnitin y la
# envía al evaluador y al comité (pasa a la fase 4).
# Se corren sobre la base recién importada (usuarios de prueba con la clave 123456).
B="http://localhost:8080/segundo-parcial"
T="$(dirname "$0")/tmp/sprint5"; rm -rf "$T"; mkdir -p "$T"
ARCHIVOS="$(dirname "$0")/../WEB-INF/archivos"
ls "$ARCHIVOS" > "$T/archivos-antes.txt"
OK=0; FALLA=0
MYSQL="/c/xampp/mysql/bin/mysql.exe -u root -N -B -D sistemas_proyectos_grado --default-character-set=utf8mb4"
HOY=$(date +%F); EN30=$(date -d "+30 days" +%F)

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
registrar() { # correo, documento, plan
    pedir anon POST /acceso/registrar.jsp --data-urlencode "nombre=Estudiante $2" --data-urlencode "tipo_documento=1" \
        --data-urlencode "numero_documento=$2" --data-urlencode "correo=$1" --data-urlencode "clave=Clave123" \
        --data-urlencode "clave2=Clave123" --data-urlencode "carrera=1" \
        --data-urlencode "plan_estudios=$3" --data-urlencode "porcentaje_creditos=80" --data-urlencode "metodologia=on"
}
subir() { pedir "$1" POST /estudiante/pago-guardar.jsp -F "recibo=@$T/recibo.pdf;type=application/pdf"; }
ultimoRecibo() { $MYSQL -e "SELECT MAX(id) FROM entregas WHERE proyecto_id=$1 AND tipo='Recibo de pago'"; }
revisarPago() { # quien, entrega, decision, observacion
    pedir "$1" POST /admin/pago-revisar.jsp --data-urlencode "id=$2" --data-urlencode "decision=$3" --data-urlencode "observacion=$4"
}
asignar() { # proyecto, director, evaluador
    pedir admin POST /admin/proyecto-asignar.jsp --data-urlencode "id=$1" --data-urlencode "director=$2" --data-urlencode "evaluador=$3"
}
fase() { $MYSQL -e "SELECT f.orden FROM proyectos p JOIN fases f ON f.id=p.fase_id WHERE p.id=$1"; }

echo "== Preparación: periodo activo, ideas aprobadas y dos estudiantes con proyecto"
printf '%%PDF-1.4\n%% recibo de prueba\n' > "$T/recibo.pdf"
entrar admin admin.prueba@uts.edu.co
pedir admin POST /admin/periodo-guardar.jsp --data-urlencode "nombre=2026-2" --data-urlencode "fecha_cierre_banco=$EN30" --data-urlencode "fecha_limite_pago=$EN30"
P1=$($MYSQL -e "SELECT id FROM periodos WHERE nombre='2026-2'")
pedir admin POST /admin/periodo-estado.jsp --data-urlencode "id=$P1" --data-urlencode "accion=activar"
entrar dir director.prueba@uts.edu.co
for TIT in "Idea A" "Idea B"; do
    pedir dir POST /ideas/idea-guardar.jsp --data-urlencode "titulo=$TIT" --data-urlencode "nivel=1" --data-urlencode "modalidad=2"
    I=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='$TIT'")
    pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$I" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
done
registrar ana@correo.uts.edu.co 4000000001 Anterior; entrar ana ana@correo.uts.edu.co Clave123
registrar caro@correo.uts.edu.co 4000000002 Nuevo; entrar caro caro@correo.uts.edu.co Clave123
pedir ana POST /ideas/idea-tomar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea A'")"
pedir caro POST /ideas/idea-tomar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea B'")"
PA=$($MYSQL -e "SELECT p.id FROM proyectos p WHERE p.titulo='Idea A'")
PC=$($MYSQL -e "SELECT p.id FROM proyectos p WHERE p.titulo='Idea B'")
[ -n "$PA" ] && [ -n "$PC" ]; revisar "Dos proyectos en la fase 1" $?

echo "== Lista de proyectos del comité (RF9)"
pedir admin GET /admin/proyectos.jsp; contiene "Idea A" && contiene "Idea B" && sinError; revisar "El comité ve los proyectos" $?
contiene ">Sin recibo<" && contiene ">No aplica<"; revisar "Estado del pago: sin recibo (plan anterior) y no aplica (plan nuevo)" $?
pedir admin GET "/admin/proyectos.jsp?filtro=pago"; contiene "No hay proyectos con ese filtro"; revisar "Sin recibos: no hay pagos por revisar" $?
pedir admin GET "/admin/proyectos.jsp?filtro=director"; contiene "Idea A" && contiene "Idea B"; revisar "Filtro sin director" $?
pedir ana GET /admin/proyectos.jsp; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un estudiante no entra a la lista" $?
pedir admin GET "/admin/proyecto.jsp?id=99999"; [[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "Proyecto que no existe: vuelve con aviso" $?

echo "== El comité revisa el recibo de pago (RF32, RF34)"
subir ana; [[ "$DESTINO" == *"ok=pago-subido"* ]]; revisar "La estudiante sube el recibo" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "En revisión" && contiene "Para pasar a la fase 2"; revisar "La estudiante ve el recibo en revisión y lo que le falta" $?
pedir admin GET "/admin/proyectos.jsp?filtro=pago"; contiene "Idea A" && ! contiene "Idea B"; revisar "El recibo aparece en los pagos por revisar" $?
pedir admin GET /panel/inicio.jsp; tr -d '\r\n' < "$T/cuerpo.html" | grep -q 'filtro=pago">[[:space:]]*<span class="app-acceso-numero">1</span>'; revisar "El inicio del comité cuenta 1 pago por revisar" $?
R1=$(ultimoRecibo $PA)
pedir admin GET "/admin/proyecto.jsp?id=$PA"; contiene "pago-revisar.jsp" && contiene "proyecto-asignar.jsp" && sinError; revisar "El proyecto muestra la revisión del pago y la asignación" $?
revisarPago admin $R1 aprobar "   "; [[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Sin observación: rechazado" $?
revisarPago admin $R1 otra "x"; [[ "$DESTINO" == *"error=general"* ]]; revisar "Decisión inválida: rechazada" $?
revisarPago ana $R1 aprobar "x"; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un estudiante no revisa pagos" $?
revisarPago admin $R1 devolver "El recibo no tiene la marca de pagado"; [[ "$DESTINO" == *"ok=pago-devuelto"* ]]; revisar "El comité devuelve el recibo" $?
[ "$($MYSQL -e "SELECT CONCAT(rol,'|',estado,'|',decision,'|',revisor_id) FROM revisiones WHERE entrega_id=$R1")" = "Comité|Enviada|Devuelto|1" ]; revisar "En la base: revisión del comité, devuelta, con quién revisó" $?
revisarPago admin $R1 aprobar "x"; [[ "$DESTINO" == *"error=pago-ya-revisado"* ]]; revisar "Un recibo ya revisado no se vuelve a revisar" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Devuelto" && contiene "no tiene la marca de pagado" && contiene 'pago-guardar.jsp'; revisar "La estudiante ve la devolución con la observación y puede subirlo otra vez" $?
subir ana; R2=$(ultimoRecibo $PA)
revisarPago admin $R1 aprobar "x"; [[ "$DESTINO" == *"error=pago-ya-revisado"* ]]; revisar "Solo se revisa el último recibo" $?
revisarPago admin $R2 aprobar "Pago verificado"; [[ "$DESTINO" == *"ok=pago-aprobado"* && "$DESTINO" != *"fase-2"* ]]; revisar "El comité aprueba el pago (sin director, sigue en la fase 1)" $?
[ "$(fase $PA)" = "1" ]; revisar "Sin director no pasa a la fase 2" $?
subir ana; [[ "$DESTINO" == *"error=pago-aprobado"* ]]; revisar "Con el pago aprobado no se sube otro recibo" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "El comité aprobó tu pago" && ! contiene 'pago-guardar.jsp'; revisar "La estudiante ve el pago aprobado, sin el formulario" $?
pedir caro POST /estudiante/pago-guardar.jsp -F "recibo=@$T/recibo.pdf"; [[ "$DESTINO" == *"error=pago-no-aplica"* ]]; revisar "Plan nuevo: sigue sin subir recibo" $?
pedir admin GET /admin/pago-revisar.jsp; [[ "$DESTINO" == *"/admin/proyectos.jsp" ]]; revisar "Por GET no revisa nada" $?

echo "== El comité asigna director y evaluador (RF11, RF27)"
asignar $PA 4 ""; [[ "$DESTINO" == *"error=director-invalido"* ]]; revisar "Un docente sin el rol Director no dirige" $?
asignar $PA "" ""; [[ "$DESTINO" == *"error=director-invalido"* ]]; revisar "Sin director: rechazado" $?
asignar $PA 3 3; [[ "$DESTINO" == *"error=evaluador-invalido"* ]]; revisar "Un docente sin el rol Evaluador no evalúa" $?
asignar $PA 6 6; [[ "$DESTINO" == *"error=director-evaluador"* ]]; revisar "El mismo docente no dirige y evalúa (aunque tenga los dos roles)" $?
$MYSQL -e "UPDATE usuarios SET activo=0 WHERE id=3"
asignar $PA 3 4; [[ "$DESTINO" == *"error=director-invalido"* ]]; revisar "Un docente inactivo no se asigna" $?
$MYSQL -e "UPDATE usuarios SET activo=1 WHERE id=3"
pedir dir POST /admin/proyecto-asignar.jsp --data-urlencode "id=$PA" --data-urlencode "director=3"; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un docente no asigna directores" $?
asignar $PA 3 4; [[ "$DESTINO" == *"ok=asignacion-fase-2"* ]]; revisar "Pago aprobado + director: pasa a la fase 2" $?
[ "$($MYSQL -e "SELECT CONCAT(f.orden,'|',p.estado,'|',p.director_id,'|',p.evaluador_id,'|',p.fecha_inicio) FROM proyectos p JOIN fases f ON f.id=p.fase_id WHERE p.id=$PA")" = "2|En curso|3|4|$HOY" ]; revisar "En la base: fase 2, en curso, director, evaluador y fecha de inicio" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM historial WHERE proyecto_id=$PA AND accion='Fase'")" = "1" ]; revisar "El paso de fase queda en el historial" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM historial WHERE proyecto_id=$PA AND descripcion LIKE '%Evaluador de Prueba%'")" = "0" ]; revisar "El historial no dice quién es el evaluador" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Director de Prueba" && ! contiene "Evaluador de Prueba" && ! contiene "Para pasar a la fase 2"; revisar "La estudiante ve a su director, no a su evaluador" $?
pedir ana GET /panel/inicio.jsp; contiene "Fase 2: Propuesta I" && contiene "app-fase completa"; revisar "Su inicio muestra la fase 2" $?
asignar $PA 6 ""; [[ "$DESTINO" == *"ok=asignacion-guardada"* ]] && [ "$(fase $PA)" = "2" ]; revisar "Cambiar el director después: guarda y sigue en la fase 2" $?
[ "$($MYSQL -e "SELECT IFNULL(evaluador_id,'NULL') FROM proyectos WHERE id=$PA")" = "NULL" ]; revisar "Quitar el evaluador lo deja vacío" $?
asignar $PC 6 ""; [[ "$DESTINO" == *"ok=asignacion-fase-2"* ]]; revisar "Plan nuevo (pago no aplica) + director: pasa a la fase 2" $?

echo "== Fase 2: la propuesta FDC-124 con sus versiones (RF26, RF30, RF43)"
printf 'documento de Word de prueba v1' > "$T/propuesta.docx"
printf 'documento de Word de prueba v2' > "$T/propuesta v2.docx"
subirPropuesta() { pedir "$1" POST /estudiante/propuesta-guardar.jsp -F "propuesta=@$2"; }
enviar() { pedir "$1" POST /estudiante/propuesta-enviar.jsp; }
pedir ana GET /estudiante/proyecto.jsp; contiene "Propuesta (FDC-124)" && contiene "propuesta-guardar.jsp" && ! contiene "propuesta-enviar.jsp"; revisar "Fase 2: puede subir el FDC-124; sin versiones no hay botón de enviar" $?
enviar ana; [[ "$DESTINO" == *"error=propuesta-requerida"* ]]; revisar "Enviar sin versiones: rechazado" $?
subirPropuesta ana "$T/recibo.pdf"; [[ "$DESTINO" == *"error=archivo-no-word"* ]]; revisar "Un PDF como FDC-124: rechazado (va en Word)" $?
pedir ana POST /estudiante/propuesta-guardar.jsp -F "otro=x"; [[ "$DESTINO" == *"error=archivo-requerido"* ]]; revisar "Sin archivo: rechazado" $?
subirPropuesta ana "$T/propuesta.docx"; [[ "$DESTINO" == *"ok=propuesta-subida"* ]]; revisar "Sube la versión 1" $?
subirPropuesta ana "$T/propuesta v2.docx"; [[ "$DESTINO" == *"ok=propuesta-subida"* ]]; revisar "Sube la versión 2" $?
[ "$($MYSQL -e "SELECT GROUP_CONCAT(CONCAT(version,':',nombre_archivo) ORDER BY version SEPARATOR ',') FROM entregas WHERE proyecto_id=$PA AND tipo='FDC-124'")" = "1:propuesta.docx,2:propuesta v2.docx" ]; revisar "En la base: las dos versiones, con su nombre original" $?
V2=$($MYSQL -e "SELECT id FROM entregas WHERE proyecto_id=$PA AND tipo='FDC-124' AND version=2")
pedir ana GET /estudiante/proyecto.jsp; contiene "Versión 2" && contiene "Versión 1" && contiene "Enviar versión 2 al director"; revisar "Ve las dos versiones y el botón para enviar la última" $?
CABECERAS=$(curl -s -D - -o "$T/bajado.docx" -b "$T/ana" "$B/archivos/ver.jsp?id=$V2")
echo "$CABECERAS" | grep -qi "wordprocessingml" && echo "$CABECERAS" | grep -qi "attachment; filename\*=UTF-8''propuesta%20v2.docx" && cmp -s "$T/bajado.docx" "$T/propuesta v2.docx"
revisar "El Word se descarga con su nombre original y sin cambios" $?
curl -s -D - -o /dev/null -b "$T/ana" "$B/archivos/ver.jsp?id=$R2" | grep -qi "content-disposition: inline"; revisar "El PDF se sigue abriendo en el navegador" $?
entrar doc docente.prueba@uts.edu.co; pedir doc POST /acceso/elegir-rol.jsp --data-urlencode "rol=3"
pedir doc GET /director/proyectos.jsp; contiene "Idea A" && contiene "Versión 2" && sinError; revisar "El director ve el proyecto que dirige, con la versión 2" $?
pedir doc GET "/director/proyecto.jsp?id=$PA"; contiene "Estudiante 4000000001" && contiene "Créditos aprobados" && contiene "80 %" && ! contiene "Evaluador de Prueba" && sinError; revisar "El director ve la información del estudiante (RF19)" $?
pedir dir GET "/director/proyecto.jsp?id=$PA"; [[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "Otro director no ve el proyecto" $?
pedir dir GET "/archivos/ver.jsp?id=$V2"; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Ni descarga su propuesta" $?
pedir ana GET /director/proyectos.jsp; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un estudiante no entra a las páginas del director" $?

echo "== Fase 2 -> 3: el estudiante envía la propuesta al director (RF18)"
enviar ana; [[ "$DESTINO" == *"ok=propuesta-enviada"* ]]; revisar "Envía la versión 2 al director" $?
[ "$(fase $PA)" = "3" ]; revisar "El proyecto pasa a la fase 3" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM historial WHERE proyecto_id=$PA AND accion='Fase' AND descripcion LIKE '%versi_n 2 del FDC-124 al director%'")" = "1" ]; revisar "El envío queda en el historial con la versión" $?
subirPropuesta ana "$T/propuesta.docx"; [[ "$DESTINO" == *"error=fase-no-permite-propuesta"* ]]; revisar "En la fase 3 no se suben versiones" $?
enviar ana; [[ "$DESTINO" == *"error=fase-no-permite-propuesta"* ]]; revisar "Ni se vuelve a enviar" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Está en revisión" && ! contiene "propuesta-guardar.jsp"; revisar "La estudiante ve que está en revisión, sin formulario" $?
pedir doc GET /panel/inicio.jsp; tr -d '\r\n' < "$T/cuerpo.html" | grep -q 'director/proyectos.jsp">[[:space:]]*<span class="app-acceso-numero">1</span>'; revisar "El inicio del director cuenta 1 propuesta por revisar" $?
pedir doc GET /director/proyectos.jsp; contiene "Por revisar"; revisar "En sus proyectos aparece por revisar" $?

echo "== Fase 3: el director devuelve la propuesta (RF18, RF34, RF43)"
printf '%%PDF-1.4\n%% reporte de Turnitin\n' > "$T/turnitin.pdf"
revisarPropuesta() { # quien, decision, observacion, [archivo]
    pedir "$1" POST /director/propuesta-revisar.jsp -F "id=$PA" -F "decision=$2" -F "observacion=$3" ${4:+-F "turnitin=@$4"}
}
pedir doc GET "/director/proyecto.jsp?id=$PA"; contiene "propuesta-revisar.jsp" && contiene "Revisar la versión 2"; revisar "El director ve el formulario para revisar la versión 2" $?
contiene "todavía no asigna el evaluador"; revisar "Sin evaluador se le avisa que no puede enviarla" $?
revisarPropuesta doc devolver "  "; [[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Devolver sin observación: rechazado" $?
revisarPropuesta dir devolver "x"; [[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "Otro director no la revisa" $?
revisarPropuesta ana devolver "x"; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un estudiante no la revisa" $?
revisarPropuesta doc devolver "Falta el presupuesto"; [[ "$DESTINO" == *"ok=propuesta-devuelta-director"* ]]; revisar "El director la devuelve con observación" $?
[ "$(fase $PA)" = "2" ] && [ "$($MYSQL -e "SELECT CONCAT(rol,'|',decision,'|',revisor_id) FROM revisiones WHERE entrega_id=$V2")" = "Director|Devuelto|6" ]; revisar "Vuelve a la fase 2 y la versión 2 queda devuelta" $?
revisarPropuesta doc devolver "otra vez"; [[ "$DESTINO" == *"error=propuesta-no-revisable"* ]]; revisar "Fuera de la fase 3 no se revisa" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "devolvió la última versión" && contiene "Falta el presupuesto" && ! contiene "propuesta-enviar.jsp"; revisar "La estudiante ve la devolución con la observación y sin el botón de enviar" $?
enviar ana; [[ "$DESTINO" == *"error=propuesta-devuelta"* ]]; revisar "No reenvía la versión devuelta" $?
subirPropuesta ana "$T/propuesta.docx"; enviar ana; [[ "$DESTINO" == *"ok=propuesta-enviada"* ]]; revisar "Con la versión 3 sí la envía" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"; contiene "Versión 3" && contiene "Falta el presupuesto"; revisar "El comité ve las versiones y las observaciones" $?

echo "== Fase 3 -> 4: el director aprueba, sube Turnitin y la envía al evaluador y al comité (RF14, RF30)"
revisarPropuesta doc aprobar "Lista para evaluar" "$T/turnitin.pdf"; [[ "$DESTINO" == *"error=sin-evaluador"* ]]; revisar "Sin evaluador no la envía" $?
asignar $PA 6 4
revisarPropuesta doc aprobar "Lista para evaluar"; [[ "$DESTINO" == *"error=turnitin-requerido"* ]]; revisar "Aprobar sin el reporte de Turnitin: rechazado" $?
revisarPropuesta doc aprobar "Lista para evaluar" "$T/propuesta.docx"; [[ "$DESTINO" == *"error=archivo-invalido"* ]]; revisar "Turnitin que no es PDF: rechazado" $?
revisarPropuesta doc aprobar "" "$T/turnitin.pdf"; [[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Aprobar sin observación: rechazado" $?
revisarPropuesta doc aprobar "Lista para evaluar" "$T/turnitin.pdf"; [[ "$DESTINO" == *"ok=propuesta-aprobada-director"* ]]; revisar "El director la aprueba y la envía" $?
V3=$($MYSQL -e "SELECT id FROM entregas WHERE proyecto_id=$PA AND tipo='FDC-124' AND version=3")
[ "$(fase $PA)" = "4" ] && [ "$($MYSQL -e "SELECT CONCAT(rol,'|',decision) FROM revisiones WHERE entrega_id=$V3")" = "Director|Aprobado" ]; revisar "Pasa a la fase 4 y la versión 3 queda aprobada por el director" $?
[ "$($MYSQL -e "SELECT CONCAT(COUNT(*),'|',MAX(subido_por)) FROM entregas WHERE proyecto_id=$PA AND tipo='Reporte Turnitin'")" = "1|6" ]; revisar "El reporte de Turnitin queda guardado, subido por el director" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM historial WHERE proyecto_id=$PA AND descripcion LIKE '%evaluador y al comit%'")" = "1" ]; revisar "Queda en el historial" $?
revisarPropuesta doc aprobar "Otra vez" "$T/turnitin.pdf"; [[ "$DESTINO" == *"error=propuesta-no-revisable"* ]]; revisar "No se aprueba dos veces" $?
pedir doc GET "/director/proyecto.jsp?id=$PA"; contiene "Reportes de Turnitin" && ! contiene "propuesta-revisar.jsp" && ! contiene "Evaluador de Prueba"; revisar "El director ve el reporte, sin el formulario y sin el nombre del evaluador" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Lista para evaluar" && contiene "la envió al evaluador" && ! contiene "Evaluador de Prueba"; revisar "La estudiante ve la aprobación del director, sin saber quién la evalúa" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"; contiene "Reportes de Turnitin"; revisar "El comité ve el reporte de Turnitin" $?
pedir admin GET "/admin/proyectos.jsp?filtro=evaluador"; ! contiene "Idea A"; revisar "Con evaluador ya no sale en el filtro sin evaluador" $?

echo "== Seminario no usa el F-DC-124 (RF17)"
$MYSQL -e "UPDATE proyectos SET modalidad_id=5 WHERE id=$PC"
subirPropuesta caro "$T/propuesta.docx"; [[ "$DESTINO" == *"error=seminario-sin-124"* ]]; revisar "Seminario: no sube el FDC-124" $?
pedir caro GET /estudiante/proyecto.jsp; contiene "no usa el F-DC-124" && ! contiene "propuesta-guardar.jsp"; revisar "Seminario: se le explica, sin formulario" $?

echo "== Integrantes: varios estudiantes en un proyecto (RF36, RF35, RF13)"
id() { $MYSQL -e "SELECT id FROM usuarios WHERE correo='$1'"; }
agregar() { pedir "$1" POST /estudiante/integrante-agregar.jsp --data-urlencode "correo=$2"; }
quitar() { pedir "$1" POST /estudiante/integrante-quitar.jsp --data-urlencode "estudiante=$2"; }
for N in gema hugo ines juan kike luz mia; do
    registrar "$N@correo.uts.edu.co" "40000001${#N}$(printf '%d' "'$N")" Anterior; entrar "$N" "$N@correo.uts.edu.co" Clave123
done
$MYSQL -e "UPDATE usuarios SET porcentaje_creditos=60 WHERE correo='kike@correo.uts.edu.co'; UPDATE usuarios SET nivel_id=2, carrera_id=35 WHERE correo='luz@correo.uts.edu.co'"
pedir dir POST /ideas/idea-guardar.jsp --data-urlencode "titulo=Idea C" --data-urlencode "nivel=1" --data-urlencode "modalidad=2"
IC=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea C'")
pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$IC" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
pedir gema POST /ideas/idea-tomar.jsp --data-urlencode "id=$IC"
PG=$($MYSQL -e "SELECT id FROM proyectos WHERE titulo='Idea C'")
pedir gema GET /estudiante/proyecto.jsp; contiene "Agregar un compañero" && contiene "(hasta 3 en esta modalidad)"; revisar "En la fase 1 puede agregar compañeros (hasta 3 en Desarrollo tecnológico)" $?
agregar gema nadie@correo.uts.edu.co; [[ "$DESTINO" == *"error=integrante-no-existe"* ]]; revisar "Un correo sin cuenta: rechazado" $?
agregar gema ana@correo.uts.edu.co; [[ "$DESTINO" == *"error=integrante-con-proyecto"* ]]; revisar "Un estudiante con otro proyecto: rechazado (RF35)" $?
agregar gema gema@correo.uts.edu.co; [[ "$DESTINO" == *"error=integrante-con-proyecto"* ]]; revisar "No se agrega a sí misma" $?
agregar gema kike@correo.uts.edu.co; [[ "$DESTINO" == *"error=integrante-no-habilitado"* ]]; revisar "Un estudiante no habilitado (60 %): rechazado" $?
agregar gema luz@correo.uts.edu.co; [[ "$DESTINO" == *"error=integrante-otro-nivel"* ]]; revisar "Un estudiante de otro nivel: rechazado" $?
agregar gema director.prueba@uts.edu.co; [[ "$DESTINO" == *"error=integrante-no-existe"* ]]; revisar "Un docente no entra como integrante" $?
agregar gema HUGO@correo.uts.edu.co; [[ "$DESTINO" == *"ok=integrante-agregado"* ]]; revisar "Agrega a un compañero (el correo sin importar mayúsculas)" $?
agregar gema ines@correo.uts.edu.co; [[ "$DESTINO" == *"ok=integrante-agregado"* ]]; revisar "Agrega a otro" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM proyecto_estudiantes WHERE proyecto_id=$PG AND vigente=1")" = "3" ]; revisar "En la base: 3 integrantes vigentes" $?
agregar gema juan@correo.uts.edu.co; [[ "$DESTINO" == *"error=integrantes-completos"* ]]; revisar "El cuarto en Desarrollo tecnológico: rechazado (máximo 3)" $?
pedir hugo GET /estudiante/proyecto.jsp; contiene "Idea C" && contiene "integrante-quitar.jsp" && contiene "(tú)"; revisar "El compañero ve el proyecto y puede quitar a los demás" $?
pedir hugo GET /panel/inicio.jsp; contiene "Tu proyecto: Idea C"; revisar "Y lo ve en su inicio" $?
quitar hugo "$(id hugo@correo.uts.edu.co)"; [[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "Nadie se quita a sí mismo" $?
quitar ana "$(id ines@correo.uts.edu.co)"; [[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "Un estudiante de otro proyecto no quita a nadie" $?
quitar gema "$(id ines@correo.uts.edu.co)"; [[ "$DESTINO" == *"ok=integrante-quitado"* ]]; revisar "Quita a una compañera" $?
[ "$($MYSQL -e "SELECT CONCAT(estado,'|',IFNULL(vigente,'NULL')) FROM proyecto_estudiantes WHERE proyecto_id=$PG AND estudiante_id=$(id ines@correo.uts.edu.co)")" = "Excluido|NULL" ]; revisar "Queda Excluida y sin vigencia (se conserva el historial)" $?
pedir ines GET /estudiante/proyecto.jsp; contiene "Todavía no tienes un proyecto"; revisar "Ella ya no tiene proyecto (puede empezar otro)" $?
agregar gema ines@correo.uts.edu.co; [[ "$DESTINO" == *"ok=integrante-agregado"* ]]; revisar "Se puede volver a agregar" $?
pedir admin POST /admin/proyecto-asignar.jsp --data-urlencode "id=$PG" --data-urlencode "director=3" --data-urlencode "interdisciplinario=on"
[[ "$DESTINO" == *"ok=asignacion-guardada"* ]] && [ "$($MYSQL -e "SELECT interdisciplinario FROM proyectos WHERE id=$PG")" = "1" ]; revisar "El comité marca el proyecto como interdisciplinario y asigna director (RF13)" $?
agregar gema juan@correo.uts.edu.co; [[ "$DESTINO" == *"ok=integrante-agregado"* ]]; revisar "Interdisciplinario: entra el cuarto" $?
agregar gema mia@correo.uts.edu.co; [[ "$DESTINO" == *"error=integrantes-completos"* ]]; revisar "Interdisciplinario: el quinto no (máximo 4)" $?
pedir admin POST /admin/proyecto-asignar.jsp --data-urlencode "id=$PG" --data-urlencode "director=3"
[[ "$DESTINO" == *"error=demasiados-integrantes"* ]]; revisar "Con 4 integrantes no se desmarca el interdisciplinario" $?
pedir admin POST /admin/proyecto-asignar.jsp --data-urlencode "id=$PC" --data-urlencode "director=6" --data-urlencode "interdisciplinario=on"
[ "$($MYSQL -e "SELECT interdisciplinario FROM proyectos WHERE id=$PC")" = "0" ]; revisar "Seminario no puede ser interdisciplinario" $?

echo "== Pago: cada estudiante sube su recibo (RF32)"
subir gema; subir hugo
[ "$($MYSQL -e "SELECT COUNT(DISTINCT subido_por) FROM entregas WHERE proyecto_id=$PG AND tipo='Recibo de pago'")" = "2" ]; revisar "Cada uno sube su propio recibo" $?
pedir hugo GET /estudiante/proyecto.jsp; contiene "En revisión" && contiene "El comité aprueba el pago de todos los integrantes"; revisar "Cada uno ve su recibo y que deben pagar todos" $?
pedir admin GET "/admin/proyecto.jsp?id=$PG"; [ "$(grep -c 'pago-revisar.jsp' "$T/cuerpo.html")" = "2" ] && contiene "Estudiante 40000001"; revisar "El comité ve un formulario por cada recibo por revisar" $?
for N in gema hugo; do revisarPago admin "$($MYSQL -e "SELECT MAX(id) FROM entregas WHERE proyecto_id=$PG AND subido_por=$(id $N@correo.uts.edu.co)")" aprobar "Ok"; done
[[ "$DESTINO" == *"ok=pago-aprobado"* && "$DESTINO" != *"fase-2"* ]] && [ "$(fase $PG)" = "1" ]; revisar "Con dos de cuatro pagos aprobados, sigue en la fase 1" $?
subir gema; [[ "$DESTINO" == *"error=pago-aprobado"* ]]; revisar "Quien ya tiene su pago aprobado no sube otro" $?
subir ines; subir juan
revisarPago admin "$($MYSQL -e "SELECT MAX(id) FROM entregas WHERE proyecto_id=$PG AND subido_por=$(id ines@correo.uts.edu.co)")" aprobar "Ok"
revisarPago admin "$($MYSQL -e "SELECT MAX(id) FROM entregas WHERE proyecto_id=$PG AND subido_por=$(id juan@correo.uts.edu.co)")" aprobar "Ok"
[[ "$DESTINO" == *"ok=pago-aprobado-fase-2"* ]] && [ "$(fase $PG)" = "2" ]; revisar "Con el último pago aprobado (y director), pasa a la fase 2" $?

echo "== Fase 2: el grupo se puede cambiar hasta enviar la propuesta"
quitar gema "$(id juan@correo.uts.edu.co)"; [[ "$DESTINO" == *"ok=integrante-quitado"* ]]; revisar "En la fase 2 todavía se quita a un compañero" $?
agregar gema mia@correo.uts.edu.co; [[ "$DESTINO" == *"ok=integrante-agregado"* ]]; revisar "Y se agrega a otro" $?
subirPropuesta gema "$T/propuesta.docx"
pedir gema GET /estudiante/proyecto.jsp; contiene "todos los integrantes deben tener el pago aprobado"; revisar "Se avisa que falta el pago de la nueva compañera" $?
enviar gema; [[ "$DESTINO" == *"error=pagos-pendientes"* ]]; revisar "Sin el pago de todos no se envía la propuesta" $?
subir mia; [[ "$DESTINO" == *"ok=pago-subido"* ]]; revisar "La nueva compañera sube su recibo en la fase 2" $?
revisarPago admin "$($MYSQL -e "SELECT MAX(id) FROM entregas WHERE proyecto_id=$PG AND subido_por=$(id mia@correo.uts.edu.co)")" aprobar "Ok"
[[ "$DESTINO" == *"ok=pago-aprobado"* ]] && [ "$(fase $PG)" = "2" ]; revisar "El comité aprueba su pago en la fase 2 (sigue en la 2)" $?
$MYSQL -e "UPDATE usuarios SET metodologia_aprobada=0 WHERE correo='hugo@correo.uts.edu.co'"
enviar gema; [[ "$DESTINO" == *"error=integrante-no-habilitado"* ]]; revisar "Si un integrante deja de estar habilitado, no se envía" $?
$MYSQL -e "UPDATE usuarios SET metodologia_aprobada=1 WHERE correo='hugo@correo.uts.edu.co'"
enviar mia; [[ "$DESTINO" == *"ok=propuesta-enviada"* ]] && [ "$(fase $PG)" = "3" ]; revisar "Con todo al día, cualquier integrante la envía (pasa a la fase 3)" $?
agregar gema juan@correo.uts.edu.co; [[ "$DESTINO" == *"error=integrantes-cerrados"* ]]; revisar "En la fase 3 ya no se agregan compañeros" $?
quitar gema "$(id mia@correo.uts.edu.co)"; [[ "$DESTINO" == *"error=integrantes-cerrados"* ]]; revisar "Ni se quitan" $?
pedir gema GET /estudiante/proyecto.jsp; ! contiene "integrante-quitar.jsp" && ! contiene "Agregar un compañero"; revisar "Sin formulario ni botón de quitar" $?
entrar dir2 director.prueba@uts.edu.co
pedir dir2 GET "/director/proyecto.jsp?id=$PG"; [ "$(grep -c 'class="app-estudiante"' "$T/cuerpo.html")" = "4" ]; revisar "El director ve a los 4 integrantes" $?

echo "== Diseño"
MOJIBAKE=0
for R in "admin /admin/proyectos.jsp" "admin /admin/proyecto.jsp?id=$PA" "admin /panel/inicio.jsp" "ana /estudiante/proyecto.jsp" "doc /director/proyectos.jsp" "doc /director/proyecto.jsp?id=$PA" "doc /panel/inicio.jsp"; do
    set -- $R; pedir "$1" GET "$2"; grep -q "Ã" "$T/cuerpo.html" && MOJIBAKE=1
done
[ "$MOJIBAKE" = 0 ]; revisar "Ninguna página nueva muestra letras raras (Ã)" $?
pedir admin GET /panel/inicio.jsp; contiene 'admin/proyectos.jsp" class'; revisar "El menú del comité tiene Proyectos" $?
pedir doc GET /panel/inicio.jsp; contiene 'director/proyectos.jsp" class' && ! contiene 'admin/proyectos.jsp'; revisar "El menú del director tiene Mis proyectos" $?

# Borra solo los recibos que crearon estas pruebas
ls "$ARCHIVOS" | grep -vxF -f "$T/archivos-antes.txt" | while read -r A; do rm -f "$ARCHIVOS/$A"; done

echo
echo "Resultado: $OK bien, $FALLA con falla"
