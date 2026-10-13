#!/usr/bin/env bash
# Pruebas de punta a punta de la fase 4 (Sprint 5, 2026-10-11): el evaluador evalúa la
# propuesta con la rejilla del F-DC-124 (RF23, RF21), la devuelve al director o envía su
# concepto; el comité da la decisión final con su acta (RF14, RF22): aprueba, aplaza,
# devuelve o no aprueba. Con el FDC-124 aprobado, el director registra seguimientos
# (RF20) y el estudiante sube el informe final (FDC-125) y lo envía al director desde el
# día 90 (RF31): el proyecto pasa a la fase 5. Fase 5: el director revisa el informe y lo
# envía con Turnitin; el evaluador lo evalúa con la rejilla del F-DC-129 (con N/A y plazo
# de corrección si lo aplaza); el comité aprueba (fase final), aplaza o no aprueba
# (vuelve a corrección) o devuelve al director, con acta. Prórrogas (RF38) y cancelación
# de la modalidad cuando se vence el plazo sin prórroga. También: el estudiante no ve a
# su evaluador (RF27) y las alertas de los plazos y del informe final (RF5, RNF21).
# Se corren sobre la base recién importada (usuarios de prueba con la clave 123456).
B="http://localhost:8080/segundo-parcial"
T="$(dirname "$0")/tmp/sprint5c"; rm -rf "$T"; mkdir -p "$T"
OK=0; FALLA=0
MYSQL="/c/xampp/mysql/bin/mysql.exe -u root -N -B -D sistemas_proyectos_grado --default-character-set=utf8mb4"
HOY=$(date +%F); MANANA=$(date -d tomorrow +%F); AYER=$(date -d yesterday +%F)
EN3=$(date -d "+3 days" +%F); EN30=$(date -d "+30 days" +%F); EN60=$(date -d "+60 days" +%F)
EN180=$(date -d "+180 days" +%F); HACE100=$(date -d "-100 days" +%F); EN80=$(date -d "+80 days" +%F)

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
sinError() { ! grep -q "Exception\|HTTP Status 500\|Estado HTTP 500" "$T/cuerpo.html"; }
entrar() { pedir "$1" POST /acceso/validar.jsp --data-urlencode "correo=$2" --data-urlencode "clave=${3:-123456}"; }
registrar() { # correo, documento
    pedir anon POST /acceso/registrar.jsp --data-urlencode "nombre=Estudiante $2" --data-urlencode "tipo_documento=1" \
        --data-urlencode "numero_documento=$2" --data-urlencode "correo=$1" --data-urlencode "clave=Clave123" \
        --data-urlencode "clave2=Clave123" --data-urlencode "carrera=1" --data-urlencode "plan_estudios=Anterior" \
        --data-urlencode "porcentaje_creditos=80" --data-urlencode "metodologia=on"
}
id() { $MYSQL -e "SELECT id FROM usuarios WHERE correo='$1'"; }
fase() { $MYSQL -e "SELECT f.orden FROM proyectos p JOIN fases f ON f.id=p.fase_id WHERE p.id=$1"; }
proyectoDe() { $MYSQL -e "SELECT proyecto_id FROM proyecto_estudiantes WHERE estudiante_id=$(id "$1") AND vigente=1"; }
indicadores() { $MYSQL -e "SELECT i.id FROM criterios_rejilla c JOIN criterio_modalidades cm ON cm.criterio_id=c.id AND cm.modalidad_id=$1 JOIN indicadores_rejilla i ON i.criterio_id=c.id WHERE c.formato='FDC-124' ORDER BY c.orden, i.orden" | tr -d "\r"; }
# Respuestas de la rejilla: todos en "si", salvo el primero si se pide "uno-no", o solo los N primeros
rejilla() { # modalidad, modo (todos | uno-no | primeros:N)
    ARGS=(); local n=0
    for I in $(indicadores "$1"); do
        n=$((n+1))
        case "$2" in
            todos) ARGS+=(--data-urlencode "r$I=si") ;;
            uno-no) if [ $n -eq 1 ]; then ARGS+=(--data-urlencode "r$I=no" --data-urlencode "o$I=Falta la ficha"); else ARGS+=(--data-urlencode "r$I=si"); fi ;;
            primeros:*) [ $n -le "${2#primeros:}" ] && ARGS+=(--data-urlencode "r$I=si") ;;
        esac
    done
}
evaluar() { # proyecto, acción, concepto, observación, (ARGS de rejilla)
    pedir eva POST /evaluador/evaluacion-guardar.jsp --data-urlencode "id=$1" --data-urlencode "accion=$2" \
        --data-urlencode "concepto=$3" --data-urlencode "observacion=$4" "${ARGS[@]}"
}
decidir() { # proyecto, decisión, acta, fecha, observación
    pedir admin POST /admin/propuesta-decidir.jsp --data-urlencode "id=$1" --data-urlencode "decision=$2" \
        --data-urlencode "acta=$3" --data-urlencode "fecha_acta=$4" --data-urlencode "observacion=$5"
}
subirPropuesta() { pedir "$1" POST /estudiante/propuesta-guardar.jsp -F "propuesta=@$T/propuesta.docx"; }
aprobarDirector() { pedir dir POST /director/propuesta-revisar.jsp -F "id=$1" -F "decision=aprobar" -F "observacion=Lista" -F "turnitin=@$T/turnitin.pdf"; }
ultima() { $MYSQL -e "SELECT CONCAT(r.rol,':',r.decision) FROM revisiones r JOIN entregas e ON e.id=r.entrega_id WHERE e.proyecto_id=$1 AND e.tipo='FDC-124' AND r.estado='Enviada' AND r.rol<>'Codirector' ORDER BY r.id DESC LIMIT 1"; }
printf '%%PDF-1.4\n%% recibo\n' > "$T/recibo.pdf"
printf '%%PDF-1.4\n%% turnitin\n' > "$T/turnitin.pdf"
printf 'documento de Word de prueba' > "$T/propuesta.docx"
printf 'informe final de prueba' > "$T/informe.docx"

echo "== Preparación: periodo, ideas, dos proyectos en la fase 3"
entrar admin admin.prueba@uts.edu.co
pedir admin POST /admin/periodo-guardar.jsp --data-urlencode "nombre=2026-2" --data-urlencode "fecha_cierre_banco=$EN30" \
    --data-urlencode "fecha_limite_pago=$EN30" --data-urlencode "fecha_limite_propuestas=$EN60"
P1=$($MYSQL -e "SELECT id FROM periodos WHERE nombre='2026-2'")
pedir admin POST /admin/periodo-estado.jsp --data-urlencode "id=$P1" --data-urlencode "accion=activar"
entrar dir director.prueba@uts.edu.co
entrar eva evaluador.prueba@uts.edu.co
for IDEA in "Idea DT|1|2" "Idea Mono|1|3"; do
    IFS='|' read -r TIT NIV MOD <<< "$IDEA"
    pedir dir POST /ideas/idea-guardar.jsp --data-urlencode "titulo=$TIT" --data-urlencode "nivel=$NIV" --data-urlencode "modalidad=$MOD"
    pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='$TIT'")" \
        --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
done
registrar ana@correo.uts.edu.co 6000000001; registrar beto@correo.uts.edu.co 6000000002
entrar ana ana@correo.uts.edu.co Clave123; entrar beto beto@correo.uts.edu.co Clave123
pedir ana POST /ideas/idea-tomar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea DT'")"
pedir beto POST /ideas/idea-tomar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea Mono'")"
PA=$(proyectoDe ana@correo.uts.edu.co); PB=$(proyectoDe beto@correo.uts.edu.co)
for N in ana beto; do
    P=$([ $N = ana ] && echo $PA || echo $PB)
    pedir $N POST /estudiante/pago-guardar.jsp -F "recibo=@$T/recibo.pdf;type=application/pdf"
    pedir admin POST /admin/pago-revisar.jsp --data-urlencode "id=$($MYSQL -e "SELECT MAX(id) FROM entregas WHERE proyecto_id=$P AND tipo='Recibo de pago'")" \
        --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
    pedir admin POST /admin/proyecto-asignar.jsp --data-urlencode "id=$P" --data-urlencode "director=3" --data-urlencode "evaluador=4"
    subirPropuesta $N; pedir $N POST /estudiante/propuesta-enviar.jsp
done
[ "$(fase $PA)" = "3" ] && [ "$(fase $PB)" = "3" ]; revisar "Los dos proyectos llegan a la fase 3" $?

echo "== El evaluador antes de la fase 4"
pedir eva GET /evaluador/proyectos.jsp; contiene "Idea DT" && contiene "todavía no te llega" && sinError; revisar "El evaluador ve sus proyectos; la propuesta todavía no le llega" $?
pedir eva GET "/evaluador/proyecto.jsp?id=$PA"; ! contiene "evaluacion-guardar.jsp" && sinError; revisar "Sin la aprobación del director no hay rejilla" $?
evaluar $PA borrador "" ""; [[ "$DESTINO" == *"error=evaluacion-no-disponible"* ]]; revisar "No puede evaluar en la fase 3" $?
pedir ana GET /evaluador/proyectos.jsp; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un estudiante no entra a las páginas del evaluador" $?
pedir dir GET "/evaluador/proyecto.jsp?id=$PA"; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "El director tampoco" $?

echo "== El director aprueba: fase 4 y plazo del evaluador (RF21)"
aprobarDirector $PA
[ "$(fase $PA)" = "4" ] && [ "$(ultima $PA)" = "Director:Aprobado" ]; revisar "La propuesta pasa a la fase 4" $?
PLAZO=$($MYSQL -e "SELECT fecha_limite_revision FROM entregas WHERE proyecto_id=$PA AND tipo='FDC-124' AND version=1")
[ -n "$PLAZO" ] && [[ "$PLAZO" > "$HOY" ]] && [[ "$PLAZO" < "$(date -d '+8 days' +%F)" ]]; revisar "El evaluador tiene 3 días hábiles ($PLAZO)" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=4 AND mensaje LIKE '%evaluarla%3 d_as h_biles%'")" = "1" ]; revisar "El evaluador recibe el aviso con su plazo" $?
pedir eva GET /panel/inicio.jsp; contiene "Por evaluar" && sinError; revisar "El inicio del evaluador muestra lo que tiene por evaluar" $?
pedir eva GET /evaluador/proyectos.jsp; contiene ">Evaluar<" && contiene "Por evaluar"; revisar "En su lista la propuesta sale por evaluar" $?
pedir eva GET "/evaluador/proyecto.jsp?id=$PA"
[ "$(grep -o 'name="r[0-9]*" value="si"' "$T/cuerpo.html" | wc -l)" = "28" ] && contiene "Estado del arte" && sinError
revisar "Desarrollo tecnológico: rejilla con los 28 indicadores, con estado del arte (RF-58)" $?

echo "== Devolver al director (fase 4 → 3)"
evaluar $PA devolver "" ""; [[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Devolver sin observación: rechazado" $?
evaluar $PA devolver "" "Falta la firma del director"
[ "$(fase $PA)" = "3" ] && [ "$(ultima $PA)" = "Evaluador:Devuelto" ]; revisar "El evaluador la devuelve: vuelve a la fase 3" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=3 AND mensaje LIKE '%evaluador devolvi_%Falta la firma%'")" = "1" ]; revisar "El director recibe el aviso" $?
pedir dir GET "/director/proyecto.jsp?id=$PA"; contiene "El evaluador te devolvió" && contiene "propuesta-revisar.jsp" && sinError; revisar "El director ve la devolución y puede revisarla otra vez" $?
aprobarDirector $PA; [ "$(fase $PA)" = "4" ]; revisar "El director la aprueba otra vez: vuelve a la fase 4" $?

echo "== Borrador y validaciones de la rejilla (RF23)"
rejilla 2 primeros:3; evaluar $PA borrador "" "Voy en la ficha"
[ "$($MYSQL -e "SELECT COUNT(*) FROM revisiones r JOIN entregas e ON e.id=r.entrega_id WHERE e.proyecto_id=$PA AND r.rol='Evaluador' AND r.estado='Borrador'")" = "1" ] \
  && [ "$($MYSQL -e "SELECT COUNT(ri.cumple) FROM revision_indicadores ri JOIN revisiones r ON r.id=ri.revision_id WHERE r.estado='Borrador'")" = "3" ]
revisar "Guarda el borrador con 3 indicadores respondidos (RF-59)" $?
pedir eva GET "/evaluador/proyecto.jsp?id=$PA"; contiene "borrador guardado" && contiene "Voy en la ficha" && [ "$(grep -c 'value="si" checked' "$T/cuerpo.html")" = "3" ]
revisar "Al volver, el borrador sale con lo que llevaba" $?
rejilla 2 primeros:3; evaluar $PA borrador "" "Sigo"
[ "$($MYSQL -e "SELECT COUNT(*) FROM revisiones WHERE rol='Evaluador' AND estado='Borrador'")" = "1" ]; revisar "Guardar otra vez reemplaza el borrador" $?
pedir ana GET /estudiante/proyecto.jsp; ! contiene "Voy en la ficha" && ! contiene "Sigo"; revisar "El estudiante no ve el borrador" $?
rejilla 2 primeros:10; evaluar $PA enviar "Aprobado" "Bien"; [[ "$DESTINO" == *"error=rejilla-incompleta"* ]]; revisar "Enviar con indicadores sin responder: rechazado (RF-60)" $?
rejilla 2 todos; evaluar $PA enviar "" "Bien"; [[ "$DESTINO" == *"error=concepto-requerido"* ]]; revisar "Enviar sin concepto: rechazado" $?
rejilla 2 todos; evaluar $PA enviar "Aprobado con correcciones" "Bien"; [[ "$DESTINO" == *"error=concepto-requerido"* ]]; revisar "Un concepto que no está en el F-DC-124: rechazado" $?
rejilla 2 todos; evaluar $PA enviar "Aprobado" ""; [[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Enviar sin observación general: rechazado (RF34)" $?
rejilla 2 uno-no; evaluar $PA enviar "Aprobado" "Bien"; [[ "$DESTINO" == *"error=aprobado-con-no"* ]]; revisar "\"Aprobado\" con un indicador en No: rechazado (RF-68)" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"; ! contiene "propuesta-decidir.jsp"; revisar "Sin el concepto del evaluador, el comité no puede decidir" $?
decidir $PA aprobar 1 "$HOY" "Ok"; [[ "$DESTINO" == *"error=decision-no-disponible"* ]]; revisar "El comité no decide antes que el evaluador (RF14)" $?

echo "== El evaluador envía su concepto: Aplazado"
rejilla 2 uno-no; evaluar $PA enviar "Aplazado" "Hay que completar la ficha tecnica"
[[ "$DESTINO" == *"ok=evaluacion-enviada"* ]] && [ "$(ultima $PA)" = "Evaluador:Aplazado" ] && [ "$(fase $PA)" = "4" ]; revisar "Envía la evaluación con concepto Aplazado; sigue en la fase 4" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM revisiones WHERE rol='Evaluador' AND estado='Borrador'")" = "0" ]; revisar "El borrador ya no existe" $?
evaluar $PA enviar "Aprobado" "Otra vez"; [[ "$DESTINO" == *"error=evaluacion-no-disponible"* ]]; revisar "No puede enviar dos veces" $?
pedir ana GET /estudiante/proyecto.jsp
contiene "Concepto del evaluador" && contiene "Hay que completar la ficha" && contiene "Falta la ficha" && ! contiene "Evaluador de Prueba" && sinError
revisar "El estudiante ve el concepto, las observaciones y la rejilla, pero no quién lo evaluó (RF27, RF-62)" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos a JOIN usuarios u ON u.id=a.usuario_id WHERE u.correo='ana@correo.uts.edu.co' AND a.mensaje LIKE '%Evaluador de Prueba%'")" = "0" ]; revisar "Ningún aviso del estudiante nombra al evaluador" $?
pedir dir GET "/director/proyecto.jsp?id=$PA"; contiene "Concepto del evaluador" && contiene "falta la decisión del comité"; revisar "El director ve el concepto" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"; contiene "Evaluador de Prueba" && contiene "propuesta-decidir.jsp" && sinError; revisar "El comité ve quién evaluó y el formulario de la decisión" $?
pedir admin GET "/admin/proyectos.jsp?filtro=propuestas"; contiene "Idea DT" && ! contiene "Idea Mono"; revisar "Filtro \"Propuestas por decidir\"" $?
pedir admin GET /panel/inicio.jsp; contiene "Propuestas e informes por decidir" && sinError; revisar "El inicio del comité cuenta las propuestas por decidir" $?

echo "== Decisión del comité: Aplazado (vuelve a la fase 2)"
decidir $PA aplazar "" "$HOY" "Corregir"; [[ "$DESTINO" == *"error=acta-invalida"* ]]; revisar "Sin número de acta: rechazado" $?
decidir $PA aplazar "12" "$MANANA" "Corregir"; [[ "$DESTINO" == *"error=acta-invalida"* ]]; revisar "Acta con fecha futura: rechazada" $?
decidir $PA aplazar "12" "hoy" "Corregir"; [[ "$DESTINO" == *"error=acta-invalida"* ]]; revisar "Acta con fecha inválida: rechazada" $?
decidir $PA aplazar "12" "$HOY" ""; [[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Sin observación: rechazado (RF34)" $?
decidir $PA aplazar "12" "$HOY" "Completar la ficha tecnica y volver a enviar"
[ "$(fase $PA)" = "2" ] && [ "$(ultima $PA)" = "Comité:Aplazado" ] && [ "$($MYSQL -e "SELECT COUNT(*) FROM actas WHERE proyecto_id=$PA AND numero=12")" = "1" ]
revisar "Aplazada: vuelve a la fase 2 y queda el acta 12" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "El comité aplazó" && contiene "Acta" && ! contiene "propuesta-enviar.jsp"; revisar "El estudiante ve el aplazamiento y debe subir otra versión" $?
pedir ana POST /estudiante/propuesta-enviar.jsp; [[ "$DESTINO" == *"error=propuesta-devuelta"* ]]; revisar "No puede reenviar la misma versión" $?
subirPropuesta ana; pedir ana POST /estudiante/propuesta-enviar.jsp; [ "$(fase $PA)" = "3" ]; revisar "Sube la versión 2 y la envía: fase 3" $?
aprobarDirector $PA; [ "$(fase $PA)" = "4" ]; revisar "El director la aprueba: fase 4" $?

echo "== Alerta del plazo del evaluador vencido (RF21, RNF21)"
$MYSQL -e "UPDATE entregas SET fecha_limite_revision='$AYER' WHERE proyecto_id=$PA AND tipo='FDC-124' AND version=2"
pedir eva GET /panel/inicio.jsp; pedir eva GET /panel/inicio.jsp
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=4 AND clave LIKE 'evaluacion-e%'")" = "1" ]; revisar "El evaluador recibe una sola alerta de plazo vencido" $?
pedir admin GET "/admin/proyectos.jsp?filtro=vencidos"; contiene "Idea DT" && contiene "Plazo del evaluador vencido"; revisar "El comité ve el plazo del evaluador vencido" $?

echo "== Concepto Aprobado y decisión del comité: Aprobado"
rejilla 2 todos; evaluar $PA enviar "Aprobado" "Cumple todo"
[ "$(ultima $PA)" = "Evaluador:Aprobado" ]; revisar "El evaluador aprueba con todos los indicadores en Sí" $?
decidir $PA aprobar "15" "$HOY" "Aprobada en la sesion"
[ "$(ultima $PA)" = "Comité:Aprobado" ] && [ "$(fase $PA)" = "4" ]; revisar "El comité aprueba; el proyecto sigue en la fase 4" $?
[ "$($MYSQL -e "SELECT CONCAT(fecha_aprobacion_124,'|',fecha_notificacion,'|',fecha_limite) FROM proyectos WHERE id=$PA")" = "$HOY|$HOY|$EN180" ]
revisar "Fecha de aprobación, notificación y límite a 180 días (RF31, RF38)" $?
[ "$($MYSQL -e "SELECT version FROM entregas WHERE proyecto_id=$PA AND tipo='FDC-124' AND oficial=1")" = "2" ]; revisar "La versión 2 queda como la oficial (RF43)" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=$(id ana@correo.uts.edu.co) AND mensaje LIKE '%comit_ aprob_%acta 15%'")" = "1" ]; revisar "El estudiante recibe el aviso con el acta" $?
decidir $PA aprobar "16" "$HOY" "Otra vez"; [[ "$DESTINO" == *"error=decision-no-disponible"* ]]; revisar "No se decide dos veces" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Informe final (FDC-125)" && contiene "informe-guardar.jsp" && ! contiene "informe-enviar.jsp" && sinError
revisar "El estudiante ve el informe final, sin botón de enviar todavía" $?
contiene "exoneracion-solicitar.jsp"; revisar "Con la propuesta aprobada (fase 4) ya puede pedir la exoneración por Saber TyT" $?

echo "== Seguimientos del director (RF20)"
pedir dir POST /director/seguimiento-registrar.jsp --data-urlencode "id=$PB" --data-urlencode "observacion=x"; [[ "$DESTINO" == *"error=seguimiento-no-aplica"* ]]; revisar "Sin el FDC-124 aprobado no hay seguimientos" $?
pedir dir POST /director/seguimiento-registrar.jsp --data-urlencode "id=$PA" --data-urlencode "observacion= "; [[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Seguimiento sin observación: rechazado" $?
pedir dir POST /director/seguimiento-registrar.jsp --data-urlencode "id=$PA" --data-urlencode "observacion=Avance del capitulo 2"
[ "$($MYSQL -e "SELECT COUNT(*) FROM seguimientos WHERE proyecto_id=$PA")" = "1" ]; revisar "El director registra un seguimiento" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Avance del capitulo 2"; revisar "El estudiante lo ve" $?

echo "== Prórrogas del plazo del informe final (RF38)"
EN360=$(date -d "+360 days" +%F)
pedirProrroga() { pedir ana POST /estudiante/prorroga-solicitar.jsp "$@"; }
decidirProrroga() { pedir admin POST /admin/prorroga-decidir.jsp --data-urlencode "id=$($MYSQL -e "SELECT MAX(id) FROM prorrogas WHERE proyecto_id=$PA")" --data-urlencode "decision=$1" --data-urlencode "observacion=$2"; }
pedir ana GET /estudiante/proyecto.jsp; contiene "prorroga-solicitar.jsp" && contiene "0 de 3" && sinError; revisar "El estudiante ve cómo pedir la prórroga (0 de 3)" $?
pedirProrroga -F "motivo= " -F "soporte=@$T/recibo.pdf"; [[ "$DESTINO" == *"error=motivo-prorroga-requerido"* ]]; revisar "Sin motivo: rechazada" $?
pedirProrroga -F "motivo=Falta terminar las pruebas"; [[ "$DESTINO" == *"error=archivo-requerido"* ]]; revisar "Sin soporte: rechazada" $?
pedirProrroga -F "motivo=Falta terminar las pruebas" -F "soporte=@$T/informe.docx"; [[ "$DESTINO" == *"error=archivo-invalido"* ]]; revisar "Soporte que no es PDF: rechazado" $?
$MYSQL -e "UPDATE usuarios SET plan_estudios='Nuevo' WHERE correo='ana@correo.uts.edu.co'"
pedirProrroga -F "motivo=Falta terminar las pruebas" -F "soporte=@$T/recibo.pdf"; [[ "$DESTINO" == *"error=prorroga-plan-nuevo"* ]]; revisar "Planes nuevos: no hay prórrogas (RF42)" $?
$MYSQL -e "UPDATE usuarios SET plan_estudios='Anterior' WHERE correo='ana@correo.uts.edu.co'"
$MYSQL -e "UPDATE proyectos SET fecha_limite='$AYER' WHERE id=$PA"
pedirProrroga -F "motivo=Falta terminar las pruebas" -F "soporte=@$T/recibo.pdf"; [[ "$DESTINO" == *"error=prorroga-vencida"* ]]; revisar "Vencido el plazo ya no se pide" $?
$MYSQL -e "UPDATE proyectos SET fecha_limite='$EN180' WHERE id=$PA"
pedirProrroga -F "motivo=Falta terminar las pruebas" -F "soporte=@$T/recibo.pdf"
[[ "$DESTINO" == *"ok=prorroga-solicitada"* ]] && [ "$($MYSQL -e "SELECT CONCAT(estado,'|',IFNULL(numero,'-'),'|',nueva_fecha_limite) FROM prorrogas WHERE proyecto_id=$PA")" = "Pendiente|-|$EN360" ]
revisar "Pide la prórroga: queda pendiente, sin número, hasta 180 días más" $?
pedirProrroga -F "motivo=Otra" -F "soporte=@$T/recibo.pdf"; [[ "$DESTINO" == *"error=prorroga-pendiente"* ]]; revisar "Una sola solicitud pendiente" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=1 AND mensaje LIKE '%pidi_ una pr_rroga%'")" = "1" ]; revisar "El comité recibe el aviso" $?
pedir admin GET "/admin/proyectos.jsp?filtro=prorrogas"; contiene "Idea DT" && contiene "Prórroga por decidir"; revisar "Filtro \"Prórrogas por decidir\"" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"; contiene "prorroga-decidir.jsp" && contiene "Soporte" && sinError; revisar "El comité ve la solicitud con su soporte" $?
decidirProrroga rechazar ""; [[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Decidir sin observación: rechazado (RF34)" $?
decidirProrroga rechazar "El recibo no corresponde"
[ "$($MYSQL -e "SELECT CONCAT(estado,'|',IFNULL(numero,'-')) FROM prorrogas WHERE proyecto_id=$PA")" = "Rechazada|-" ] && [ "$($MYSQL -e "SELECT fecha_limite FROM proyectos WHERE id=$PA")" = "$EN180" ]
revisar "Rechazada: sin número y la fecha límite no cambia" $?
decidirProrroga aprobar "Otra vez"; [[ "$DESTINO" == *"error=prorroga-ya-decidida"* ]]; revisar "No se decide dos veces" $?
pedirProrroga -F "motivo=Falta terminar las pruebas" -F "soporte=@$T/recibo.pdf"; decidirProrroga aprobar "Recibo correcto"
[ "$($MYSQL -e "SELECT CONCAT(numero,'|',nueva_fecha_limite) FROM prorrogas WHERE proyecto_id=$PA AND estado='Aprobada'")" = "1|$EN360" ] && [ "$($MYSQL -e "SELECT fecha_limite FROM proyectos WHERE id=$PA")" = "$EN360" ]
revisar "Aprobada: prórroga 1 y la fecha límite pasa a 180 días más" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Prórroga 1 · hasta el"; revisar "El estudiante ve su prórroga aprobada" $?
$MYSQL -e "INSERT INTO prorrogas (proyecto_id, numero, fecha_solicitud, nueva_fecha_limite, estado, observacion, decidida_por, decidida_en) VALUES ($PA, 2, CURDATE(), CURDATE(), 'Aprobada', 'Ok', 1, NOW()), ($PA, 3, CURDATE(), CURDATE(), 'Aprobada', 'Ok', 1, NOW())"
pedirProrroga -F "motivo=Una mas" -F "soporte=@$T/recibo.pdf"; [[ "$DESTINO" == *"error=prorrogas-agotadas"* ]]; revisar "Con 3 prórrogas aprobadas no se pide una cuarta (F-DC-124)" $?
$MYSQL -e "DELETE FROM prorrogas WHERE proyecto_id=$PA AND numero IN (2, 3)"

echo "== Informe final (FDC-125, RF31)"
pedir ana POST /estudiante/informe-guardar.jsp -F "informe=@$T/recibo.pdf"; [[ "$DESTINO" == *"error=informe-no-word"* ]]; revisar "El informe en PDF: rechazado (va en Word)" $?
pedir ana POST /estudiante/informe-guardar.jsp -F "informe=@$T/informe.docx"
[ "$($MYSQL -e "SELECT COUNT(*) FROM entregas WHERE proyecto_id=$PA AND tipo='FDC-125' AND version=1")" = "1" ]; revisar "Sube la versión 1 del FDC-125" $?
pedir ana POST /estudiante/informe-enviar.jsp; [[ "$DESTINO" == *"error=informe-antes-de-90"* ]]; revisar "Antes del día 90 no se envía" $?
$MYSQL -e "UPDATE proyectos SET fecha_aprobacion_124='$HACE100', fecha_limite='$EN3' WHERE id=$PA"
pedir ana GET /panel/inicio.jsp; pedir ana GET /panel/inicio.jsp
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=$(id ana@correo.uts.edu.co) AND clave LIKE 'informe-%'")" = "3" ]; revisar "A 3 días del límite: alertas de 30, 10 y 5 días, sin repetirse (RF5)" $?
$MYSQL -e "UPDATE proyectos SET fecha_limite='$EN80' WHERE id=$PA"
pedir ana POST /estudiante/informe-enviar.jsp; [[ "$DESTINO" == *"error=faltan-seguimientos"* ]]; revisar "Con un solo seguimiento no se envía (RF20)" $?
pedir dir POST /director/seguimiento-registrar.jsp --data-urlencode "id=$PA" --data-urlencode "observacion=Resultados listos"
pedir ana GET /estudiante/proyecto.jsp; contiene "informe-enviar.jsp"; revisar "Con 90 días y 2 seguimientos aparece el botón de enviar" $?
$MYSQL -e "UPDATE proyectos SET fecha_limite='$AYER' WHERE id=$PA"
pedir ana POST /estudiante/informe-enviar.jsp; [[ "$DESTINO" == *"error=informe-vencido"* ]]; revisar "Vencido el plazo no se envía" $?
$MYSQL -e "UPDATE proyectos SET fecha_limite='$EN80' WHERE id=$PA"
pedir ana POST /estudiante/informe-enviar.jsp
[[ "$DESTINO" == *"ok=informe-enviado"* ]] && [ "$(fase $PA)" = "5" ]; revisar "Envía el informe al director: fase 5 (Informe II)" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=3 AND mensaje LIKE '%informe final%'")" -ge "1" ]; revisar "El director recibe el aviso" $?
pedir ana POST /estudiante/informe-guardar.jsp -F "informe=@$T/informe.docx"; [[ "$DESTINO" == *"error=informe-no-aplica"* ]]; revisar "En la fase 5 ya no sube versiones" $?
pedir dir GET "/director/proyecto.jsp?id=$PA"; contiene "del informe final para revisarla" && contiene "Resultados listos" && sinError; revisar "El director ve el informe y los seguimientos" $?
pedir ana GET /estudiante/proyecto.jsp; ! contiene "exoneracion-solicitar.jsp" && sinError; revisar "Con el informe entregado ya no se pide la exoneración" $?
pedir ana GET /estudiante/proyecto.jsp; grep -q "Evaluador de Prueba" "$T/cuerpo.html"; [ $? -ne 0 ]; revisar "El historial del estudiante no nombra al evaluador (RF27)" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"; contiene "Informe final (FDC-125)" && contiene "Resultados listos" && sinError; revisar "El comité ve el informe y los seguimientos" $?

echo "== Fase 5: el director revisa el informe final (RF14, RF21, RF31)"
revisarInforme() { pedir dir POST /director/informe-revisar.jsp -F "id=$PA" -F "decision=$1" -F "observacion=$2" ${3:+-F "turnitin=@$3"}; }
ultimaInf() { $MYSQL -e "SELECT CONCAT(r.rol,':',r.decision) FROM revisiones r JOIN entregas e ON e.id=r.entrega_id WHERE e.proyecto_id=$PA AND e.tipo='FDC-125' AND r.estado='Enviada' AND r.rol<>'Codirector' ORDER BY r.id DESC LIMIT 1"; }
evaluarInforme() { # acción, concepto, observación, plazo, (ARGS de rejilla)
    pedir eva POST /evaluador/evaluacion-guardar.jsp --data-urlencode "id=$PA" --data-urlencode "documento=informe" --data-urlencode "accion=$1" \
        --data-urlencode "concepto=$2" --data-urlencode "observacion=$3" --data-urlencode "plazo=$4" "${ARGS[@]}"
}
rejillaInforme() { # modo: todos | uno-no | con-na
    ARGS=(); local n=0
    for I in $($MYSQL -e "SELECT i.id FROM criterios_rejilla c JOIN indicadores_rejilla i ON i.criterio_id=c.id WHERE c.formato='FDC-129' ORDER BY c.orden, i.orden" | tr -d '\r'); do
        n=$((n+1))
        case "$1" in
            todos) ARGS+=(--data-urlencode "r$I=si") ;;
            uno-no) if [ $n -eq 1 ]; then ARGS+=(--data-urlencode "r$I=no"); else ARGS+=(--data-urlencode "r$I=si"); fi ;;
            con-na) if [ $n -ge 39 ]; then ARGS+=(--data-urlencode "r$I=na"); else ARGS+=(--data-urlencode "r$I=si"); fi ;;
        esac
    done
}
decidirInforme() { pedir admin POST /admin/informe-decidir.jsp --data-urlencode "id=$PA" --data-urlencode "decision=$1" --data-urlencode "acta=$2" --data-urlencode "fecha_acta=$HOY" --data-urlencode "observacion=$3"; }
subirInforme() { pedir ana POST /estudiante/informe-guardar.jsp -F "informe=@$T/informe.docx"; }
[ -n "$($MYSQL -e "SELECT fecha_limite_revision FROM entregas WHERE proyecto_id=$PA AND tipo='FDC-125' AND version=1")" ]; revisar "Al enviarlo, el director tiene 5 días hábiles para revisarlo" $?
pedir dir GET /director/proyectos.jsp; contiene "Informe por revisar" && sinError; revisar "En la lista del director sale el informe por revisar" $?
pedir dir GET "/director/proyecto.jsp?id=$PA"; contiene "informe-revisar.jsp" && sinError; revisar "El director ve el formulario para revisar el informe" $?
rejillaInforme todos; evaluarInforme enviar Aprobado "Bien" ""; [[ "$DESTINO" == *"error=evaluacion-no-disponible"* ]]; revisar "El evaluador no evalúa antes que el director" $?
$MYSQL -e "UPDATE entregas SET fecha_limite_revision='$AYER' WHERE proyecto_id=$PA AND tipo='FDC-125' AND version=1"
pedir dir GET /panel/inicio.jsp
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=3 AND clave LIKE 'informe-e%'")" = "1" ]; revisar "Alerta al director con el plazo del informe vencido" $?
pedir admin GET "/admin/proyectos.jsp?filtro=vencidos"; contiene "Plazo del director vencido (informe)"; revisar "El comité ve el plazo del director vencido en el informe" $?
revisarInforme devolver ""; [[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Devolver sin observación: rechazado" $?
revisarInforme devolver "Faltan las conclusiones"
[ "$(fase $PA)" = "4" ] && [ "$(ultimaInf)" = "Director:Devuelto" ]; revisar "El director lo devuelve: vuelve a la fase 4" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Tu director devolvi" && contiene "Faltan las conclusiones" && ! contiene "informe-enviar.jsp"; revisar "El estudiante ve la devolución, sin el botón de enviar" $?
pedir ana POST /estudiante/informe-enviar.jsp; [[ "$DESTINO" == *"error=informe-ya-revisado"* ]]; revisar "No puede reenviar la misma versión" $?
subirInforme; pedir ana POST /estudiante/informe-enviar.jsp; [ "$(fase $PA)" = "5" ]; revisar "Sube la versión 2 y la envía: fase 5" $?
revisarInforme aprobar "Listo"; [[ "$DESTINO" == *"error=turnitin-requerido"* ]]; revisar "Aprobar sin Turnitin: rechazado (RF31)" $?
revisarInforme aprobar "Listo para evaluar" "$T/turnitin.pdf"
[ "$(fase $PA)" = "5" ] && [ "$(ultimaInf)" = "Director:Aprobado" ]; revisar "El director lo aprueba con Turnitin; sigue en la fase 5" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=4 AND mensaje LIKE '%informe final%F-DC-129%5 d_as h_biles%'")" = "1" ]; revisar "El evaluador recibe el aviso con sus 5 días hábiles" $?

echo "== Fase 5: el evaluador evalúa con la rejilla del F-DC-129 (RF23, RF22)"
pedir eva GET /evaluador/proyectos.jsp; contiene "Informe final por evaluar"; revisar "En la lista del evaluador sale el informe por evaluar" $?
pedir eva GET "/evaluador/proyecto.jsp?id=$PA"
[ "$(grep -o 'name="r[0-9]*" value="na"' "$T/cuerpo.html" | wc -l)" = "40" ] && contiene "F-DC-129" && sinError
revisar "Rejilla del F-DC-129: 40 indicadores con Sí, No y N/A" $?
rejillaInforme uno-no; evaluarInforme enviar Aplazado "Corregir el formato" ""; [[ "$DESTINO" == *"error=plazo-correccion-invalido"* ]]; revisar "Aplazado sin plazo: rechazado (RF22)" $?
rejillaInforme uno-no; evaluarInforme enviar Aplazado "Corregir el formato" "$AYER"; [[ "$DESTINO" == *"error=plazo-correccion-invalido"* ]]; revisar "Plazo en el pasado: rechazado" $?
rejillaInforme uno-no; evaluarInforme enviar Aplazado "Corregir el formato" "$EN180"; [[ "$DESTINO" == *"error=plazo-correccion-invalido"* ]]; revisar "Plazo después de la fecha límite: rechazado" $?
rejillaInforme uno-no; evaluarInforme borrador Aplazado "Voy" "$EN30"
[ "$($MYSQL -e "SELECT plazo_correccion FROM revisiones WHERE rol='Evaluador' AND estado='Borrador'")" = "$EN30" ]; revisar "El borrador guarda el plazo" $?
rejillaInforme uno-no; evaluarInforme enviar Aplazado "Corregir el formato de la portada" "$EN30"
[ "$(ultimaInf)" = "Evaluador:Aplazado" ]; revisar "Envía el concepto Aplazado con el plazo" $?
pedir admin GET "/admin/proyectos.jsp?filtro=propuestas"; contiene "Informe por decidir"; revisar "El comité ve el informe por decidir" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"; contiene "informe-decidir.jsp" && contiene "Plazo para las correcciones" && sinError; revisar "El comité ve la evaluación con el plazo y el formulario" $?

echo "== Fase 5: decisiones del comité sobre el informe"
decidirInforme aplazar 30 "Corregir segun el evaluador"
[ "$(fase $PA)" = "4" ] && [ "$($MYSQL -e "SELECT estado FROM proyectos WHERE id=$PA")" != "Cancelado" ]; revisar "Aplazado: vuelve a la fase 4" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "El comité aplazó" && contiene "a más tardar el" && ! contiene "Evaluador de Prueba"; revisar "El estudiante ve el aplazamiento y el plazo, sin saber quién evaluó" $?
subirInforme
$MYSQL -e "UPDATE revisiones SET plazo_correccion='$AYER' WHERE rol='Evaluador' AND plazo_correccion IS NOT NULL"
pedir ana POST /estudiante/informe-enviar.jsp; [[ "$DESTINO" == *"error=plazo-correccion-vencido"* ]]; revisar "Vencido el plazo de corrección no se envía" $?
$MYSQL -e "UPDATE revisiones SET plazo_correccion='$EN30' WHERE rol='Evaluador' AND plazo_correccion IS NOT NULL"
pedir ana POST /estudiante/informe-enviar.jsp; [ "$(fase $PA)" = "5" ]; revisar "Envía la versión 3 dentro del plazo: fase 5" $?
revisarInforme aprobar "Corregido" "$T/turnitin.pdf"
rejillaInforme uno-no; evaluarInforme enviar Aprobado "Bien" ""; [[ "$DESTINO" == *"error=aprobado-con-no"* ]]; revisar "\"Aprobado\" con un indicador en No: rechazado" $?
rejillaInforme con-na; evaluarInforme enviar Aprobado "Cumple todo lo que aplica" ""
[ "$(ultimaInf)" = "Evaluador:Aprobado" ]; revisar "Aprobado con N/A en lo que no aplica" $?
decidirInforme no-aprobar 31 "Similitud alta en el capitulo 2"
[ "$(fase $PA)" = "4" ] && [ "$($MYSQL -e "SELECT estado FROM proyectos WHERE id=$PA")" != "Cancelado" ]; revisar "No aprobado: vuelve a la fase 4 para corrección, sin cancelar (decisión del equipo)" $?
subirInforme; pedir ana POST /estudiante/informe-enviar.jsp; revisarInforme aprobar "Parafraseado" "$T/turnitin.pdf"
rejillaInforme todos; evaluarInforme enviar Aprobado "Bien" ""
decidirInforme devolver 32 "Falta la firma del director"
[ "$(fase $PA)" = "5" ] && [ "$(ultimaInf)" = "Comité:Devuelto" ]; revisar "Devuelto: vuelve al director y sigue en la fase 5" $?
pedir dir GET "/director/proyecto.jsp?id=$PA"; contiene "El comité te devolvió el informe" && contiene "informe-revisar.jsp"; revisar "El director lo revisa otra vez" $?
revisarInforme aprobar "Firmado" "$T/turnitin.pdf"; rejillaInforme todos; evaluarInforme enviar Aprobado "Bien" ""
decidirInforme aprobar "" "Ok"; [[ "$DESTINO" == *"error=acta-invalida"* ]]; revisar "Sin acta: rechazado" $?
decidirInforme aprobar 33 "Informe aprobado"
[ "$(fase $PA)" = "6" ] && [ "$($MYSQL -e "SELECT version FROM entregas WHERE proyecto_id=$PA AND tipo='FDC-125' AND oficial=1")" = "4" ]
revisar "Aprobado: fase final y la versión 4 queda como la oficial" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM actas a JOIN revisiones r ON r.id=a.revision_id WHERE a.proyecto_id=$PA AND r.rol LIKE 'Comit_'")" = "$($MYSQL -e "SELECT COUNT(*) FROM actas WHERE proyecto_id=$PA")" ]
revisar "Cada acta queda ligada a la decisión del comité que respalda" $?
decidirInforme aprobar 34 "Otra vez"; [[ "$DESTINO" == *"error=decision-no-disponible"* ]]; revisar "No se decide dos veces" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "aprobó tu informe final" && contiene "N.º 15" && contiene "N.º 33" && sinError
revisar "El estudiante ve el informe aprobado y el acta de cada decisión" $?
pedir eva GET /evaluador/proyectos.jsp; contiene "Informe final aprobado por el comité"; revisar "El evaluador ve el informe aprobado" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"; contiene "Informe final (FDC-125)" && ! contiene "informe-decidir.jsp" && sinError; revisar "El comité ya no ve el formulario" $?

echo "== Monografía: sin estado del arte; el comité devuelve y luego no aprueba"
aprobarDirector $PB; [ "$(fase $PB)" = "4" ]; revisar "El director aprueba la monografía" $?
pedir eva GET "/evaluador/proyecto.jsp?id=$PB"
[ "$(grep -o 'name="r[0-9]*" value="si"' "$T/cuerpo.html" | wc -l)" = "26" ] && ! contiene "<h3 class=\"h6 fw-bold mt-4 mb-0\">Estado del arte"
revisar "Monografía: 26 indicadores, sin estado del arte" $?
rejilla 3 todos; evaluar $PB enviar "No aprobado" "No es viable"
decidir $PB devolver "20" "$HOY" "Falta la firma"
[ "$(fase $PB)" = "3" ] && [ "$(ultima $PB)" = "Comité:Devuelto" ]; revisar "El comité la devuelve al director: fase 3" $?
pedir dir GET "/director/proyecto.jsp?id=$PB"; contiene "El comité te devolvió"; revisar "El director ve la devolución del comité" $?
aprobarDirector $PB; rejilla 3 todos; evaluar $PB enviar "No aprobado" "No es viable"
decidir $PB no-aprobar "21" "$HOY" "La propuesta no es viable"
[ "$($MYSQL -e "SELECT estado FROM proyectos WHERE id=$PB")" = "Cancelado" ] && [ -z "$(proyectoDe beto@correo.uts.edu.co)" ] \
  && [ "$($MYSQL -e "SELECT estado FROM ideas WHERE titulo='Idea Mono'")" = "Aprobada" ]
revisar "No aprobada: proyecto cancelado, estudiante libre e idea de vuelta en el banco" $?
pedir admin GET "/admin/proyecto.jsp?id=$PB"; contiene "El proyecto se canceló en esta fase" && ! contiene "(fase actual)"; revisar "En las tarjetas de las fases se ve dónde se canceló" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=$(id beto@correo.uts.edu.co) AND mensaje LIKE '%comit_ no aprob_%'")" = "1" ]; revisar "El estudiante recibe el aviso" $?
pedir eva GET /evaluador/proyectos.jsp; contiene "Cancelado" && sinError; revisar "El evaluador ve el proyecto cancelado" $?

echo "== Plazo del informe final vencido sin prórroga: se cancela la modalidad (RF38)"
pedir beto POST /ideas/idea-tomar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea Mono'")"
PC=$(proyectoDe beto@correo.uts.edu.co)
pedir beto POST /estudiante/pago-guardar.jsp -F "recibo=@$T/recibo.pdf;type=application/pdf"
pedir admin POST /admin/pago-revisar.jsp --data-urlencode "id=$($MYSQL -e "SELECT MAX(id) FROM entregas WHERE proyecto_id=$PC AND tipo='Recibo de pago'")" \
    --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
pedir admin POST /admin/proyecto-asignar.jsp --data-urlencode "id=$PC" --data-urlencode "director=3" --data-urlencode "evaluador=4"
subirPropuesta beto; pedir beto POST /estudiante/propuesta-enviar.jsp; aprobarDirector $PC
rejilla 3 todos; evaluar $PC enviar "Aprobado" "Bien"; decidir $PC aprobar "40" "$HOY" "Aprobada"
[ "$(fase $PC)" = "4" ] && [ -n "$($MYSQL -e "SELECT fecha_aprobacion_124 FROM proyectos WHERE id=$PC")" ]; revisar "Otro proyecto con la propuesta aprobada (fase 4)" $?
pedir beto POST /estudiante/prorroga-solicitar.jsp -F "motivo=Necesito mas tiempo" -F "soporte=@$T/recibo.pdf"
$MYSQL -e "UPDATE proyectos SET fecha_limite='$AYER' WHERE id=$PC"
pedir beto GET /panel/inicio.jsp
[ "$($MYSQL -e "SELECT estado FROM proyectos WHERE id=$PC")" != "Cancelado" ]; revisar "Vencido con una prórroga pendiente: no se cancela mientras el comité decide" $?
pedir admin POST /admin/prorroga-decidir.jsp --data-urlencode "id=$($MYSQL -e "SELECT MAX(id) FROM prorrogas WHERE proyecto_id=$PC")" --data-urlencode "decision=rechazar" --data-urlencode "observacion=Fuera de tiempo"
pedir beto GET /panel/inicio.jsp
[ "$($MYSQL -e "SELECT estado FROM proyectos WHERE id=$PC")" = "Cancelado" ] && [ -z "$(proyectoDe beto@correo.uts.edu.co)" ] \
  && [ "$($MYSQL -e "SELECT estado FROM ideas WHERE titulo='Idea Mono'")" = "Aprobada" ]
revisar "Rechazada la prórroga y vencido el plazo: modalidad cancelada, estudiante libre e idea de vuelta en el banco" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=$(id beto@correo.uts.edu.co) AND mensaje LIKE '%cancel_ la modalidad%'")" = "1" ] \
  && [ "$($MYSQL -e "SELECT COUNT(*) FROM historial WHERE proyecto_id=$PC AND descripcion LIKE 'Modalidad cancelada%'")" = "1" ]
revisar "El estudiante recibe el aviso y queda en el historial" $?
$MYSQL -e "UPDATE proyectos SET fecha_limite='$AYER' WHERE id=$PA"
pedir ana GET /panel/inicio.jsp
[ "$($MYSQL -e "SELECT estado FROM proyectos WHERE id=$PA")" != "Cancelado" ]; revisar "Un proyecto en la fase final no se cancela por el plazo" $?

echo "== Páginas sin errores"
for R in "admin|/admin/proyectos.jsp" "admin|/admin/auditoria.jsp" "eva|/evaluador/proyectos.jsp" "eva|/evaluador/proyecto.jsp?id=$PA" "dir|/director/proyectos.jsp" "beto|/estudiante/proyecto.jsp"; do
    IFS='|' read -r U RUTA <<< "$R"; pedir "$U" GET "$RUTA"; [ "$CODIGO" = "200" ] && sinError; revisar "$RUTA ($U)" $?
done

echo
echo "Resultado: $OK OK, $FALLA fallas"
[ "$FALLA" -eq 0 ]
