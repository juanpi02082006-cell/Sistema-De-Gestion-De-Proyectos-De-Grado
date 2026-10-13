#!/usr/bin/env bash
# Pruebas de punta a punta de la fase final (Sprint 5, 2026-10-13, RF39): un proyecto llega
# a la fase final con el informe aprobado por el comité; los estudiantes, el director y el
# evaluador programan la sustentación (fecha, hora y lugar) y la pueden reprogramar; los
# codirectores la ven, pero no la programan. Después de la fecha, el comité registra la
# aprobación final con su acta y observación: el proyecto queda "Finalizado". También: el
# estudiante no sabe quién es su evaluador (RF27), avisos (RF5) e historial (RNF12).
# Se corren sobre la base recién importada (usuarios de prueba con la clave 123456).
B="http://localhost:8080/segundo-parcial"
T="$(dirname "$0")/tmp/sprint5d"; rm -rf "$T"; mkdir -p "$T"
OK=0; FALLA=0
MYSQL="/c/xampp/mysql/bin/mysql.exe -u root -N -B -D sistemas_proyectos_grado --default-character-set=utf8mb4"
HOY=$(date +%F); MANANA=$(date -d tomorrow +%F); AYER=$(date -d yesterday +%F); ANTEAYER=$(date -d "-2 days" +%F)
EN30=$(date -d "+30 days" +%F); EN60=$(date -d "+60 days" +%F); HACE100=$(date -d "-100 days" +%F)
EN7=$(date -d "+7 days" +%F); EN8=$(date -d "+8 days" +%F)

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
estado() { $MYSQL -e "SELECT estado FROM proyectos WHERE id=$1"; }
proyectoDe() { $MYSQL -e "SELECT proyecto_id FROM proyecto_estudiantes WHERE estudiante_id=$(id "$1") AND vigente=1"; }
avisos() { $MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=$1 AND mensaje LIKE '$2'"; }
# Respuestas de la rejilla, todas en "si": F-DC-124 de la modalidad o F-DC-129
rejilla() { # formato, modalidad
    ARGS=()
    for I in $($MYSQL -e "SELECT i.id FROM criterios_rejilla c JOIN indicadores_rejilla i ON i.criterio_id=c.id
                          WHERE c.formato='$1' AND ('$1'='FDC-129' OR c.id IN (SELECT criterio_id FROM criterio_modalidades WHERE modalidad_id=$2))
                          ORDER BY c.orden, i.orden" | tr -d '\r'); do
        ARGS+=(--data-urlencode "r$I=si")
    done
}
programar() { # usuario, proyecto, fecha y hora (aaaa-mm-ddThh:mm), lugar
    pedir "$1" POST /panel/sustentacion-programar.jsp --data-urlencode "id=$2" --data-urlencode "fecha_hora=$3" --data-urlencode "lugar=$4"
}
finalizar() { # acta, fecha del acta, observación
    pedir admin POST /admin/proyecto-finalizar.jsp --data-urlencode "id=$PA" --data-urlencode "acta=$1" --data-urlencode "fecha_acta=$2" --data-urlencode "observacion=$3"
}
sustentaciones() { $MYSQL -e "SELECT COUNT(*) FROM sustentaciones WHERE proyecto_id=$PA"; }
printf '%%PDF-1.4\n%% recibo\n' > "$T/recibo.pdf"
printf '%%PDF-1.4\n%% turnitin\n' > "$T/turnitin.pdf"
printf 'documento de Word de prueba' > "$T/propuesta.docx"
printf 'informe final de prueba' > "$T/informe.docx"

echo "== Preparación: un proyecto de dos estudiantes, con codirector, hasta la fase final"
entrar admin admin.prueba@uts.edu.co
pedir admin POST /admin/periodo-guardar.jsp --data-urlencode "nombre=2026-2" --data-urlencode "fecha_cierre_banco=$EN30" \
    --data-urlencode "fecha_limite_pago=$EN30" --data-urlencode "fecha_limite_propuestas=$EN60"
pedir admin POST /admin/periodo-estado.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM periodos WHERE nombre='2026-2'")" --data-urlencode "accion=activar"
entrar dir director.prueba@uts.edu.co
entrar eva evaluador.prueba@uts.edu.co
entrar doc docente.prueba@uts.edu.co; pedir doc POST /acceso/elegir-rol.jsp --data-urlencode "rol=3"
for IDEA in "Idea Final|2" "Idea Mono|3" "Idea Libre|3"; do
    IFS='|' read -r TIT MOD <<< "$IDEA"
    pedir dir POST /ideas/idea-guardar.jsp --data-urlencode "titulo=$TIT" --data-urlencode "nivel=1" --data-urlencode "modalidad=$MOD"
    pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='$TIT'")" \
        --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
done
registrar ana@correo.uts.edu.co 6000000101; registrar beto@correo.uts.edu.co 6000000102; registrar carla@correo.uts.edu.co 6000000103
entrar ana ana@correo.uts.edu.co Clave123; entrar beto beto@correo.uts.edu.co Clave123; entrar carla carla@correo.uts.edu.co Clave123
ANA=$(id ana@correo.uts.edu.co); BETO=$(id beto@correo.uts.edu.co)
pedir ana POST /ideas/idea-tomar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea Final'")"
pedir carla POST /ideas/idea-tomar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea Mono'")"
PA=$(proyectoDe ana@correo.uts.edu.co); PC=$(proyectoDe carla@correo.uts.edu.co)
pedir ana POST /estudiante/integrante-agregar.jsp --data-urlencode "correo=beto@correo.uts.edu.co"
for N in ana beto; do
    pedir $N POST /estudiante/pago-guardar.jsp -F "recibo=@$T/recibo.pdf;type=application/pdf"
    pedir admin POST /admin/pago-revisar.jsp --data-urlencode "id=$($MYSQL -e "SELECT MAX(id) FROM entregas WHERE proyecto_id=$PA AND tipo='Recibo de pago' AND subido_por=$(id $N@correo.uts.edu.co)")" \
        --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
done
pedir admin POST /admin/proyecto-asignar.jsp --data-urlencode "id=$PA" --data-urlencode "director=3" --data-urlencode "evaluador=4" \
    --data-urlencode "interdisciplinario=on" --data-urlencode "codirector1=6"
pedir ana POST /estudiante/propuesta-guardar.jsp -F "propuesta=@$T/propuesta.docx"; pedir ana POST /estudiante/propuesta-enviar.jsp
pedir dir POST /director/propuesta-revisar.jsp -F "id=$PA" -F "decision=aprobar" -F "observacion=Lista" -F "turnitin=@$T/turnitin.pdf"
rejilla FDC-124 2; pedir eva POST /evaluador/evaluacion-guardar.jsp --data-urlencode "id=$PA" --data-urlencode "accion=enviar" \
    --data-urlencode "concepto=Aprobado" --data-urlencode "observacion=Cumple" "${ARGS[@]}"
pedir admin POST /admin/propuesta-decidir.jsp --data-urlencode "id=$PA" --data-urlencode "decision=aprobar" --data-urlencode "acta=1" \
    --data-urlencode "fecha_acta=$HOY" --data-urlencode "observacion=Aprobada"
for S in "Avance del capitulo 1" "Resultados listos"; do
    pedir dir POST /director/seguimiento-registrar.jsp --data-urlencode "id=$PA" --data-urlencode "observacion=$S"
done
$MYSQL -e "UPDATE proyectos SET fecha_aprobacion_124='$HACE100', fecha_limite='$EN60' WHERE id=$PA"
pedir ana POST /estudiante/informe-guardar.jsp -F "informe=@$T/informe.docx"; pedir ana POST /estudiante/informe-enviar.jsp
pedir dir POST /director/informe-revisar.jsp -F "id=$PA" -F "decision=aprobar" -F "observacion=Listo" -F "turnitin=@$T/turnitin.pdf"
rejilla FDC-129 2; pedir eva POST /evaluador/evaluacion-guardar.jsp --data-urlencode "id=$PA" --data-urlencode "documento=informe" \
    --data-urlencode "accion=enviar" --data-urlencode "concepto=Aprobado" --data-urlencode "observacion=Cumple" --data-urlencode "plazo=" "${ARGS[@]}"
pedir admin POST /admin/informe-decidir.jsp --data-urlencode "id=$PA" --data-urlencode "decision=aprobar" --data-urlencode "acta=2" \
    --data-urlencode "fecha_acta=$HOY" --data-urlencode "observacion=Informe aprobado"
[ "$(fase $PA)" = "6" ] && [ "$(estado $PA)" = "En curso" ] && [ "$(proyectoDe beto@correo.uts.edu.co)" = "$PA" ]
revisar "El proyecto de Ana y Beto llega a la fase final, en curso" $?
[ "$(fase $PC)" = "1" ]; revisar "El de Carla sigue en la fase 1" $?

echo "== Fase final: lo que ve cada uno"
pedir ana GET /estudiante/proyecto.jsp
contiene "Sustentación" && contiene "sustentacion-programar.jsp" && contiene "Estudiantes, director y evaluador programan" && contiene "aprobó tu informe final" && sinError
revisar "El estudiante ve la tarjeta de la sustentación con el formulario" $?
pedir ana GET /panel/inicio.jsp; contiene "Fase final: Sustentación · Estado: En curso" && ! contiene "Fase 6" && sinError; revisar "Su inicio dice \"Fase final\" (no \"Fase 6\")" $?
pedir dir GET "/director/proyecto.jsp?id=$PA"; contiene "sustentacion-programar.jsp" && sinError; revisar "El director también puede programarla" $?
pedir eva GET "/evaluador/proyecto.jsp?id=$PA"; contiene "sustentacion-programar.jsp" && sinError; revisar "El evaluador también" $?
pedir doc GET "/director/proyecto.jsp?id=$PA"; contiene "Sustentación" && ! contiene "sustentacion-programar.jsp" && sinError
revisar "El codirector la ve, pero no la programa (decide el director, RF13)" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"
contiene "todavía no programan la sustentación" && ! contiene "sustentacion-programar.jsp" && ! contiene "proyecto-finalizar.jsp" && sinError
revisar "El comité ve que falta programarla; no la programa ni puede finalizar todavía" $?
pedir admin GET "/admin/proyectos.jsp?filtro=sustentacion"; contiene "Idea Final" && contiene "Sustentación por programar" && ! contiene "Idea Mono"
revisar "Filtro \"Fase final\" del comité, con la etiqueta \"Sustentación por programar\"" $?
pedir dir GET /director/proyectos.jsp; contiene "Sustentación por programar" && contiene ">Programar<" && sinError; revisar "En la lista del director sale por programar" $?
pedir eva GET /evaluador/proyectos.jsp; contiene "Sustentación por programar" && sinError; revisar "En la lista del evaluador también" $?

echo "== Quién puede programarla y validaciones"
pedir ana GET /panel/sustentacion-programar.jsp; [[ "$DESTINO" == *"/estudiante/proyecto.jsp" ]]; revisar "Por GET no guarda nada: vuelve a la página del proyecto" $?
programar admin $PA "${EN7}T15:30" "Auditorio"; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "El comité no la programa (la programan estudiantes, director y evaluador)" $?
programar carla $PA "${EN7}T15:30" "Auditorio"; [[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "Una estudiante de otro proyecto: rechazado" $?
programar doc $PA "${EN7}T15:30" "Auditorio"; [[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "El codirector: rechazado" $?
programar carla $PC "${EN7}T15:30" "Auditorio"; [[ "$DESTINO" == *"error=sustentacion-no-aplica"* ]]; revisar "Un proyecto que no está en la fase final: rechazado" $?
programar ana $PA "" "Auditorio"; [[ "$DESTINO" == *"error=sustentacion-fecha-invalida"* ]]; revisar "Sin fecha: rechazada" $?
programar ana $PA "manana a las 3" "Auditorio"; [[ "$DESTINO" == *"error=sustentacion-fecha-invalida"* ]]; revisar "Fecha con otro formato: rechazada" $?
programar ana $PA "${AYER}T10:00" "Auditorio"; [[ "$DESTINO" == *"error=sustentacion-fecha-invalida"* ]]; revisar "Fecha pasada: rechazada" $?
programar ana $PA "2027-02-30T10:00" "Auditorio"; [[ "$DESTINO" == *"error=sustentacion-fecha-invalida"* ]]; revisar "Fecha que no existe (30 de febrero): rechazada" $?
programar ana $PA "${EN7}T25:00" "Auditorio"; [[ "$DESTINO" == *"error=sustentacion-fecha-invalida"* ]]; revisar "Hora que no existe: rechazada" $?
programar ana $PA "${EN7}T15:30" "   "; [[ "$DESTINO" == *"error=sustentacion-lugar-invalido"* ]]; revisar "Sin lugar: rechazada" $?
programar ana $PA "${EN7}T15:30" "$(printf 'x%.0s' $(seq 1 151))"; [[ "$DESTINO" == *"error=sustentacion-lugar-invalido"* ]]; revisar "Lugar de más de 150 caracteres: rechazado" $?
[ "$(sustentaciones)" = "0" ]; revisar "Nada de lo rechazado quedó guardado" $?

echo "== Programar (una estudiante)"
programar ana $PA "${EN7}T15:30" "Auditorio Menor, edificio B"
[[ "$DESTINO" == *"ok=sustentacion-programada"* ]] && [ "$($MYSQL -e "SELECT CONCAT(fecha_hora,'|',lugar,'|',programada_por) FROM sustentaciones WHERE proyecto_id=$PA")" = "$EN7 15:30:00|Auditorio Menor, edificio B|$ANA" ]
revisar "La sustentación queda con su fecha, hora, lugar y quién la programó" $?
[ "$(avisos $BETO '%program_ la sustentaci_n%Auditorio Menor%')" = "1" ] && [ "$(avisos 3 '%program_ la sustentaci_n%')" = "1" ] && [ "$(avisos 4 '%program_ la sustentaci_n%')" = "1" ] \
  && [ "$(avisos 6 '%program_ la sustentaci_n%')" = "1" ] && [ "$(avisos 1 '%program_ la sustentaci_n%')" = "1" ] && [ "$(avisos $ANA '%program_ la sustentaci_n%')" = "0" ]
revisar "Avisos al compañero, al director, al evaluador, al codirector y al comité (no a quien la programó)" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM historial WHERE proyecto_id=$PA AND accion='Otro' AND usuario_id=$ANA AND descripcion LIKE 'Se program_ la sustentaci_n%'")" = "1" ]; revisar "Queda en el historial" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Auditorio Menor" && contiene "Reprograma la sustentación" && sinError; revisar "La estudiante la ve y puede reprogramarla" $?
pedir beto GET /estudiante/proyecto.jsp; contiene "Auditorio Menor" && sinError; revisar "Su compañero también la ve" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"; contiene "Auditorio Menor" && ! contiene "proyecto-finalizar.jsp"; revisar "El comité la ve; antes de la fecha no hay aprobación final" $?
finalizar 3 "$HOY" "Antes de tiempo"; [[ "$DESTINO" == *"error=finalizar-no-disponible"* ]] && [ "$(estado $PA)" = "En curso" ]; revisar "Antes de la sustentación no se finaliza" $?
pedir dir GET /director/proyectos.jsp; contiene "Sustentación ·" && ! contiene ">Programar<"; revisar "La lista del director muestra la fecha" $?
pedir eva GET /evaluador/proyectos.jsp; contiene "Sustentación: " && sinError; revisar "La del evaluador también" $?
pedir admin GET "/admin/proyectos.jsp?filtro=sustentacion"; contiene "Sustentación programada"; revisar "Para el comité, \"Sustentación programada\"" $?

echo "== Reprogramar (el evaluador): el estudiante no sabe quién es (RF27)"
programar eva $PA "${EN8}T09:00" "https://meet.uts.edu.co/sustentacion"
[[ "$DESTINO" == *"ok=sustentacion-reprogramada"* ]] && [ "$(sustentaciones)" = "1" ] \
  && [ "$($MYSQL -e "SELECT CONCAT(fecha_hora,'|',lugar,'|',programada_por) FROM sustentaciones WHERE proyecto_id=$PA")" = "$EN8 09:00:00|https://meet.uts.edu.co/sustentacion|4" ]
revisar "Se reprograma: sigue una sola, con la fecha, el lugar y quién la cambió" $?
[ "$(avisos $ANA '%reprogram_ la sustentaci_n%meet.uts.edu.co%')" = "1" ] && [ "$(avisos $ANA '%Evaluador de Prueba%')" = "0" ]
revisar "La estudiante recibe el aviso, que no nombra al evaluador" $?
pedir ana GET /estudiante/proyecto.jsp
contiene "Programada por</dt><dd>El evaluador" && contiene "meet.uts.edu.co" && ! contiene "Evaluador de Prueba" && sinError
revisar "En su página sale \"El evaluador\", sin el nombre (tampoco en el historial)" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"; contiene "Programada por</dt><dd>Evaluador de Prueba"; revisar "El comité sí ve quién la reprogramó" $?
pedir dir POST /panel/sustentacion-programar.jsp --data-urlencode "id=$PA" --data-urlencode "fecha_hora=${EN8} 10:00" --data-urlencode "lugar=Sala de juntas"
[[ "$DESTINO" == *"ok=sustentacion-reprogramada"* ]] && [ "$($MYSQL -e "SELECT CONCAT(fecha_hora,'|',programada_por) FROM sustentaciones WHERE proyecto_id=$PA")" = "$EN8 10:00:00|3" ]
revisar "El director la reprograma (también acepta la fecha con espacio)" $?

echo "== Aprobación final del comité"
$MYSQL -e "UPDATE sustentaciones SET fecha_hora='$AYER 10:00:00' WHERE proyecto_id=$PA"
pedir admin GET /panel/inicio.jsp; contiene "Aprobaciones finales" && grep -A1 'filtro=sustentacion"' "$T/cuerpo.html" | grep -q 'app-acceso-numero">1<' && sinError
revisar "Pasada la fecha, el inicio del comité cuenta 1 aprobación final pendiente" $?
pedir admin GET "/admin/proyectos.jsp?filtro=sustentacion"; contiene "Aprobación final pendiente"; revisar "En la lista sale \"Aprobación final pendiente\"" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"; contiene "proyecto-finalizar.jsp" && contiene "Ya pasó la fecha de la sustentación" && sinError
revisar "El comité ve el formulario de la aprobación final" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "falta la aprobación final del comité" && contiene "reprográmenla"; revisar "La estudiante ve que falta la aprobación final" $?
pedir admin GET /admin/proyecto-finalizar.jsp; [[ "$DESTINO" == *"/admin/proyectos.jsp" ]]; revisar "Por GET no finaliza" $?
pedir ana POST /admin/proyecto-finalizar.jsp --data-urlencode "id=$PA"; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Una estudiante no puede finalizar" $?
finalizar 3 "$HOY" ""; [[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Sin observación: rechazada (RF34)" $?
finalizar "" "$HOY" "Ok"; [[ "$DESTINO" == *"error=acta-invalida"* ]]; revisar "Sin número de acta: rechazada" $?
finalizar 3 "2026-02-30" "Ok"; [[ "$DESTINO" == *"error=acta-invalida"* ]]; revisar "Acta con fecha que no existe: rechazada" $?
finalizar 3 "$MANANA" "Ok"; [[ "$DESTINO" == *"error=acta-invalida"* ]]; revisar "Acta con fecha futura: rechazada" $?
finalizar 3 "$ANTEAYER" "Ok"; [[ "$DESTINO" == *"error=acta-antes-de-sustentacion"* ]]; revisar "Acta anterior a la sustentación: rechazada" $?
[ "$(estado $PA)" = "En curso" ]; revisar "Con los rechazos el proyecto sigue en curso" $?
finalizar 3 "$HOY" "Sustentacion aprobada por los jurados"
[[ "$DESTINO" == *"ok=proyecto-finalizado"* ]] && [ "$(estado $PA)" = "Finalizado" ] && [ "$(fase $PA)" = "6" ]
revisar "Registrada la aprobación final: el proyecto queda Finalizado en la fase final" $?
[ "$($MYSQL -e "SELECT CONCAT(numero,'|',fecha,'|',IFNULL(revision_id,'-')) FROM actas WHERE proyecto_id=$PA AND descripcion LIKE 'Aprobaci_n final%Sustentacion aprobada por los jurados'")" = "3|$HOY|-" ]
revisar "Queda el acta 3 con su fecha y la observación (sin decisión de un documento)" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM historial WHERE proyecto_id=$PA AND accion='Estado' AND descripcion LIKE '%aprobaci_n final%Finalizado%'")" = "1" ]; revisar "Queda en el historial" $?
[ "$(avisos $ANA '%qued_ finalizado%radicar%')" = "1" ] && [ "$(avisos $BETO '%qued_ finalizado%')" = "1" ] && [ "$(avisos 3 '%qued_ finalizado%')" = "1" ] \
  && [ "$(avisos 4 '%qued_ finalizado%')" = "1" ] && [ "$(avisos 6 '%qued_ finalizado%')" = "1" ]
revisar "Avisos a los estudiantes, al director, al evaluador y al codirector" $?
[ "$(proyectoDe ana@correo.uts.edu.co)" = "$PA" ] && [ "$(proyectoDe beto@correo.uts.edu.co)" = "$PA" ]; revisar "Los estudiantes siguen con su proyecto (terminado), como en los demás finalizados" $?
finalizar 4 "$HOY" "Otra vez"; [[ "$DESTINO" == *"error=proyecto-cerrado"* ]]; revisar "No se finaliza dos veces" $?
programar ana $PA "${EN7}T15:30" "Auditorio"; [[ "$DESTINO" == *"error=proyecto-cerrado"* ]]; revisar "Ya finalizado, la sustentación no se reprograma" $?

echo "== Proyecto finalizado: lo que ve cada uno"
pedir ana GET /estudiante/proyecto.jsp
contiene "Tu trabajo de grado quedó finalizado" && contiene "radicar los papeles de grado" && ! contiene "exonerados por Saber TyT" && contiene "N.º 3" \
  && ! contiene "sustentacion-programar.jsp" && contiene "Sustentación hecha y aprobación final" && ! contiene "(fase actual)" && sinError
revisar "La estudiante ve su trabajo de grado finalizado, con el acta y todas las fases completas" $?
pedir ana POST /ideas/idea-tomar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea Libre'")"
[[ "$DESTINO" == *"error=proyecto-vigente"* ]]; revisar "Con el proyecto finalizado no toma otra idea (RF35)" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"; contiene "Proyecto terminado" && contiene "N.º 3" && ! contiene "proyecto-finalizar.jsp" && sinError
revisar "El comité ve el proyecto terminado, sin formularios" $?
pedir admin GET /panel/inicio.jsp; grep -A1 'filtro=sustentacion"' "$T/cuerpo.html" | grep -q 'app-acceso-numero">0<'; revisar "El contador de aprobaciones finales vuelve a 0" $?
pedir admin GET "/admin/proyectos.jsp?filtro=sustentacion"; ! contiene "Idea Final"; revisar "Ya no sale en el filtro de la fase final" $?
pedir dir GET /director/proyectos.jsp; contiene "Finalizado" && sinError; revisar "El director lo ve finalizado" $?
pedir dir GET "/director/proyecto.jsp?id=$PA"; contiene "registró la aprobación final" && ! contiene "sustentacion-programar.jsp" && sinError; revisar "En su página, sin formularios" $?
pedir eva GET /evaluador/proyectos.jsp; contiene "Finalizado" && sinError; revisar "El evaluador también" $?
pedir eva GET "/evaluador/proyecto.jsp?id=$PA"; ! contiene "sustentacion-programar.jsp" && sinError; revisar "En su página, sin formularios" $?

echo "== Páginas sin errores"
for R in "admin|/admin/proyectos.jsp" "admin|/admin/auditoria.jsp" "admin|/panel/inicio.jsp" "dir|/panel/inicio.jsp" "eva|/panel/inicio.jsp" \
         "beto|/estudiante/proyecto.jsp" "beto|/panel/inicio.jsp" "carla|/estudiante/proyecto.jsp" "doc|/director/proyecto.jsp?id=$PA"; do
    IFS='|' read -r U RUTA <<< "$R"; pedir "$U" GET "$RUTA"; [ "$CODIGO" = "200" ] && sinError; revisar "$RUTA ($U)" $?
done

echo
echo "Resultado: $OK OK, $FALLA fallas"
[ "$FALLA" -eq 0 ]
