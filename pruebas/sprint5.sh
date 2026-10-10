#!/usr/bin/env bash
# Pruebas de punta a punta del Sprint 5 (primera parte): el comité revisa el recibo de pago
# (RF32, observación obligatoria RF34), asigna director y evaluador (RF11, RF27) y el
# proyecto pasa a la fase 2 cuando tiene el pago aprobado (o no aplica) y director.
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
        --data-urlencode "clave2=Clave123" --data-urlencode "nivel=1" --data-urlencode "carrera=Sistemas" \
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
pedir ana GET /estudiante/proyecto.jsp; contiene "Devuelto" && contiene "no tiene la marca de pagado" && contiene 'enctype="multipart/form-data"'; revisar "La estudiante ve la devolución con la observación y puede subirlo otra vez" $?
subir ana; R2=$(ultimoRecibo $PA)
revisarPago admin $R1 aprobar "x"; [[ "$DESTINO" == *"error=pago-ya-revisado"* ]]; revisar "Solo se revisa el último recibo" $?
revisarPago admin $R2 aprobar "Pago verificado"; [[ "$DESTINO" == *"ok=pago-aprobado"* && "$DESTINO" != *"fase-2"* ]]; revisar "El comité aprueba el pago (sin director, sigue en la fase 1)" $?
[ "$(fase $PA)" = "1" ]; revisar "Sin director no pasa a la fase 2" $?
subir ana; [[ "$DESTINO" == *"error=pago-aprobado"* ]]; revisar "Con el pago aprobado no se sube otro recibo" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "El comité aprobó tu pago" && ! contiene 'enctype="multipart/form-data"'; revisar "La estudiante ve el pago aprobado, sin el formulario" $?
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

echo "== Diseño"
MOJIBAKE=0
for R in "admin /admin/proyectos.jsp" "admin /admin/proyecto.jsp?id=$PA" "admin /panel/inicio.jsp" "ana /estudiante/proyecto.jsp"; do
    set -- $R; pedir "$1" GET "$2"; grep -q "Ã" "$T/cuerpo.html" && MOJIBAKE=1
done
[ "$MOJIBAKE" = 0 ]; revisar "Ninguna página nueva muestra letras raras (Ã)" $?
pedir admin GET /panel/inicio.jsp; contiene 'admin/proyectos.jsp" class'; revisar "El menú del comité tiene Proyectos" $?

# Borra solo los recibos que crearon estas pruebas
ls "$ARCHIVOS" | grep -vxF -f "$T/archivos-antes.txt" | while read -r A; do rm -f "$ARCHIVOS/$A"; done

echo
echo "Resultado: $OK bien, $FALLA con falla"
