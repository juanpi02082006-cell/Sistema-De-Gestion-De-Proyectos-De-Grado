#!/usr/bin/env bash
# Pruebas de punta a punta de lo que completa las fases 0 a 3 y lo transversal (Sprint 5,
# 2026-10-10): catálogo de carreras y nivel (RF24), código del proyecto (RF40), avisos y
# alertas de vencimiento (RF5, RNF21), plazo del director en días hábiles (RF21, RNF19),
# codirectores (RF13), anexos (RF26, RF30), cambio de modalidad (RF12), PQR (RNF1),
# auditoría e historial (RNF12), exoneración por Saber TyT (RNF14), Seminario (RF17) y la
# cancelación por extemporaneidad de la semana 12 (RF30).
# Se corren sobre la base recién importada (usuarios de prueba con la clave 123456).
B="http://localhost:8080/segundo-parcial"
T="$(dirname "$0")/tmp/sprint5b"; rm -rf "$T"; mkdir -p "$T"
ARCHIVOS="$(dirname "$0")/../WEB-INF/archivos"
ls "$ARCHIVOS" > "$T/archivos-antes.txt"
OK=0; FALLA=0
MYSQL="/c/xampp/mysql/bin/mysql.exe -u root -N -B -D sistemas_proyectos_grado --default-character-set=utf8mb4"
HOY=$(date +%F); AYER=$(date -d yesterday +%F); MANANA=$(date -d tomorrow +%F)
EN3=$(date -d "+3 days" +%F); EN30=$(date -d "+30 days" +%F); EN60=$(date -d "+60 days" +%F)

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
registrar() { # correo, documento, carrera, [plan]
    pedir anon POST /acceso/registrar.jsp --data-urlencode "nombre=Estudiante $2" --data-urlencode "tipo_documento=1" \
        --data-urlencode "numero_documento=$2" --data-urlencode "correo=$1" --data-urlencode "clave=Clave123" \
        --data-urlencode "clave2=Clave123" --data-urlencode "carrera=$3" --data-urlencode "plan_estudios=${4:-Anterior}" \
        --data-urlencode "porcentaje_creditos=80" --data-urlencode "metodologia=on"
}
id() { $MYSQL -e "SELECT id FROM usuarios WHERE correo='$1'"; }
fase() { $MYSQL -e "SELECT f.orden FROM proyectos p JOIN fases f ON f.id=p.fase_id WHERE p.id=$1"; }
proyectoDe() { $MYSQL -e "SELECT proyecto_id FROM proyecto_estudiantes WHERE estudiante_id=$(id "$1") AND vigente=1"; }
subir() { pedir "$1" POST /estudiante/pago-guardar.jsp -F "recibo=@$T/recibo.pdf;type=application/pdf"; }
ultimoRecibo() { $MYSQL -e "SELECT MAX(id) FROM entregas WHERE proyecto_id=$1 AND tipo='Recibo de pago' AND subido_por=$2"; }
revisarPago() { pedir admin POST /admin/pago-revisar.jsp --data-urlencode "id=$1" --data-urlencode "decision=$2" --data-urlencode "observacion=$3"; }
avisos() { # usuario, patrón LIKE
    $MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=$1 AND mensaje LIKE '$2'"; }
printf '%%PDF-1.4\n%% recibo de prueba\n' > "$T/recibo.pdf"
printf '%%PDF-1.4\n%% anexo\n' > "$T/anexo.pdf"
printf '%%PDF-1.4\n%% certificado\n' > "$T/certificado.pdf"
printf 'documento de Word de prueba' > "$T/propuesta.docx"

echo "== Preparación: periodo activo e ideas aprobadas"
entrar admin admin.prueba@uts.edu.co
pedir admin POST /admin/periodo-guardar.jsp --data-urlencode "nombre=2026-2" --data-urlencode "fecha_cierre_banco=$EN30" \
    --data-urlencode "fecha_limite_pago=$EN30" --data-urlencode "fecha_limite_propuestas=$EN60"
P1=$($MYSQL -e "SELECT id FROM periodos WHERE nombre='2026-2'")
pedir admin POST /admin/periodo-estado.jsp --data-urlencode "id=$P1" --data-urlencode "accion=activar"
entrar dir director.prueba@uts.edu.co
for IDEA in "Idea A|1|2" "Idea B|1|2" "Idea U|2|1" "Idea D|1|2"; do
    IFS='|' read -r TIT NIV MOD <<< "$IDEA"
    pedir dir POST /ideas/idea-guardar.jsp --data-urlencode "titulo=$TIT" --data-urlencode "nivel=$NIV" --data-urlencode "modalidad=$MOD"
    pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='$TIT'")" \
        --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
done
[ "$(avisos 3 '%aprob_ la idea%')" = "4" ]; revisar "Quien propuso cada idea recibe el aviso de que se aprobó (RF5)" $?

echo "== Carreras: el registro usa el catálogo y el nivel sale de la carrera (RF24)"
pedir anon GET /registro.jsp; contiene '<optgroup label="Tecnológico">' && contiene '<optgroup label="Universitario">' && ! contiene 'name="nivel"'
revisar "El registro muestra las carreras agrupadas por nivel, sin preguntar el nivel" $?
contiene "Ingeniería de Sistemas — Bucaramanga" && contiene "Negocios Internacionales — Campus Virtual"; revisar "Cada carrera sale con su campus" $?
registrar raro@correo.uts.edu.co 5000000099 9999; contiene "Escoge tu carrera de la lista"; revisar "Carrera que no existe: rechazada" $?
registrar raro@correo.uts.edu.co 5000000099 ""; contiene "Completa todos los campos"; revisar "Sin carrera: rechazado" $?
registrar ana@correo.uts.edu.co 5000000001 1; registrar beto@correo.uts.edu.co 5000000002 1
registrar uri@correo.uts.edu.co 5000000003 35; registrar carlos@correo.uts.edu.co 5000000004 1; registrar dora@correo.uts.edu.co 5000000005 1
[ "$($MYSQL -e "SELECT CONCAT(u.nivel_id,'|',c.nombre) FROM usuarios u JOIN carreras c ON c.id=u.carrera_id WHERE u.correo='uri@correo.uts.edu.co'")" = "2|Ingeniería de Sistemas" ]
revisar "Ingeniería de Sistemas queda en el nivel universitario" $?
[ "$($MYSQL -e "SELECT nombre FROM niveles WHERE id=2")" = "Universitario" ]; revisar "El nivel 2 se llama Universitario" $?
for N in ana beto uri carlos dora; do entrar "$N" "$N@correo.uts.edu.co" Clave123; done
pedir ana GET /estudiante/habilitacion.jsp; contiene "Tecnología en Desarrollo de Sistemas Informáticos" && contiene "Estás habilitado"; revisar "La habilitación muestra la carrera del catálogo" $?
pedir admin GET "/admin/usuarios.jsp?q=Ingenier%C3%ADa%20de%20Sistemas"; contiene "uri@correo.uts.edu.co" && ! contiene "ana@correo.uts.edu.co"; revisar "El comité busca usuarios por carrera" $?

echo "== Código del proyecto (RF40)"
pedir ana POST /ideas/idea-tomar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea A'")"
pedir beto POST /ideas/idea-tomar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea B'")"
pedir uri POST /ideas/idea-tomar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea U'")"
pedir carlos POST /ideas/idea-tomar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM ideas WHERE titulo='Idea D'")"
PA=$(proyectoDe ana@correo.uts.edu.co); PB=$(proyectoDe beto@correo.uts.edu.co); PU=$(proyectoDe uri@correo.uts.edu.co); PD=$(proyectoDe carlos@correo.uts.edu.co)
[ "$($MYSQL -e "SELECT GROUP_CONCAT(codigo ORDER BY id SEPARATOR ',') FROM proyectos")" = "65-2026-2/1,65-2026-2/2,125-2026-2/1,65-2026-2/3" ]
revisar "Códigos 65 (tecnológico) y 125 (universitario), con el periodo y el consecutivo" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "65-2026-2/1" && sinError; revisar "La estudiante ve el código de su proyecto" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM historial WHERE proyecto_id=$PA AND descripcion LIKE '%65-2026-2/1%'")" = "1" ]; revisar "El código queda en el historial" $?
pedir carlos POST /estudiante/integrante-agregar.jsp --data-urlencode "correo=dora@correo.uts.edu.co"
[ "$(avisos "$(id dora@correo.uts.edu.co)" '%te agreg_ al proyecto%')" = "1" ]; revisar "La compañera agregada recibe un aviso" $?

echo "== Avisos dentro del sistema (RF5)"
ANA=$(id ana@correo.uts.edu.co)
subir ana
[ "$(avisos 1 '%subi_ su recibo de pago%')" = "1" ]; revisar "El comité recibe el aviso del recibo por revisar" $?
pedir admin GET /panel/inicio.jsp; contiene 'class="app-campana-numero"'; revisar "La campana muestra los avisos sin leer" $?
revisarPago "$(ultimoRecibo $PA $ANA)" devolver "Falta la marca de pagado"
[ "$(avisos $ANA '%devolvi_ tu recibo de pago%Falta la marca%')" = "1" ]; revisar "La estudiante recibe el aviso con la observación" $?
pedir ana GET /panel/avisos.jsp; contiene "tu recibo de pago" && contiene "app-aviso-item nuevo" && sinError; revisar "Ve sus avisos sin leer" $?
AV=$($MYSQL -e "SELECT MAX(id) FROM avisos WHERE usuario_id=$ANA")
pedir beto GET "/panel/aviso-abrir.jsp?id=$AV"; [[ "$DESTINO" == *"/panel/avisos.jsp" ]] && [ "$($MYSQL -e "SELECT leido FROM avisos WHERE id=$AV")" = "0" ]
revisar "Nadie abre los avisos de otro" $?
pedir ana GET "/panel/aviso-abrir.jsp?id=$AV"; [[ "$DESTINO" == *"/estudiante/proyecto.jsp" ]] && [ "$($MYSQL -e "SELECT leido FROM avisos WHERE id=$AV")" = "1" ]
revisar "Abrir un aviso lo marca leído y lleva a su página" $?
pedir ana POST /panel/avisos-leer.jsp
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=$ANA AND leido=0")" = "0" ]; revisar "Marcar todos como leídos" $?

echo "== Alertas de vencimiento (RNF21)"
$MYSQL -e "UPDATE periodos SET fecha_limite_pago='$EN3' WHERE id=$P1"
pedir ana GET /panel/inicio.jsp; pedir ana GET /panel/inicio.jsp
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=$ANA AND clave LIKE 'pago-%-p$PA'")" = "2" ]; revisar "Límite de pago a 3 días: alertas de 10 y 5 días, sin repetirse" $?
$MYSQL -e "UPDATE periodos SET fecha_limite_pago='$EN30', fecha_limite_propuestas='$EN3' WHERE id=$P1"
pedir ana GET /panel/inicio.jsp
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=$ANA AND clave LIKE 'semana12-%-p$PA'")" = "2" ]; revisar "Semana 12 a 3 días: alertas de 10 y 5 días (RF30)" $?
$MYSQL -e "UPDATE periodos SET fecha_limite_propuestas='$EN60' WHERE id=$P1"

echo "== Codirectores (RF13)"
subir ana; revisarPago "$(ultimoRecibo $PA $ANA)" aprobar "Ok"
asignarA() { pedir admin POST /admin/proyecto-asignar.jsp --data-urlencode "id=$PA" --data-urlencode "director=3" "$@"; }
asignarA --data-urlencode "evaluador=4" --data-urlencode "interdisciplinario=on" --data-urlencode "codirector1=3"
[[ "$DESTINO" == *"error=codirector-invalido"* ]]; revisar "El director no es codirector de su proyecto" $?
asignarA --data-urlencode "evaluador=4" --data-urlencode "interdisciplinario=on" --data-urlencode "codirector1=4"
[[ "$DESTINO" == *"error=codirector-invalido"* ]]; revisar "Un docente sin el rol Director no es codirector" $?
asignarA --data-urlencode "evaluador=6" --data-urlencode "interdisciplinario=on" --data-urlencode "codirector1=6"
[[ "$DESTINO" == *"error=codirector-invalido"* ]]; revisar "El evaluador no es codirector del mismo proyecto" $?
asignarA --data-urlencode "evaluador=4" --data-urlencode "interdisciplinario=on" --data-urlencode "codirector1=6" --data-urlencode "codirector2=6"
[[ "$DESTINO" == *"error=codirector-invalido"* ]]; revisar "El mismo codirector dos veces: rechazado" $?
asignarA --data-urlencode "evaluador=4" --data-urlencode "interdisciplinario=on" --data-urlencode "codirector1=6"
[[ "$DESTINO" == *"ok=asignacion-fase-2"* ]] && [ "$($MYSQL -e "SELECT GROUP_CONCAT(docente_id) FROM proyecto_codirectores WHERE proyecto_id=$PA")" = "6" ]
revisar "El comité asigna director, evaluador y un codirector; pasa a la fase 2" $?
[ "$(avisos $ANA '%pas_ a la fase 2%')" = "1" ] && [ "$(avisos 3 '%te asign_ como director%')" = "1" ] && [ "$(avisos 4 '%te asign_ como evaluador%')" = "1" ] && [ "$(avisos 6 '%te asign_ como codirector%')" = "1" ]
revisar "Avisos: fase 2 a la estudiante, y su asignación al director, al evaluador y al codirector" $?
[ "$(avisos $ANA '%Evaluador de Prueba%')" = "0" ]; revisar "Ningún aviso le dice a la estudiante quién la evalúa" $?

echo "== Anexos de la propuesta (RF26, RF30)"
pedir ana POST /estudiante/anexo-guardar.jsp -F "anexo=@$T/propuesta.docx"; [[ "$DESTINO" == *"error=archivo-invalido"* ]]; revisar "Un anexo que no es PDF: rechazado" $?
pedir ana POST /estudiante/anexo-guardar.jsp -F "anexo=@$T/anexo.pdf;type=application/pdf"; [[ "$DESTINO" == *"ok=anexo-subido"* ]]; revisar "Sube un anexo en PDF" $?
pedir ana POST /estudiante/anexo-guardar.jsp -F "anexo=@$T/recibo.pdf;type=application/pdf"
AX=$($MYSQL -e "SELECT MAX(id) FROM entregas WHERE proyecto_id=$PA AND tipo='Anexo'")
pedir beto POST /estudiante/anexo-quitar.jsp --data-urlencode "id=$AX"; [[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "Nadie más quita sus anexos" $?
pedir ana POST /estudiante/anexo-quitar.jsp --data-urlencode "id=$AX"; [[ "$DESTINO" == *"ok=anexo-quitado"* ]]; revisar "Quita un anexo en la fase 2" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM entregas WHERE proyecto_id=$PA AND tipo='Anexo'")" = "1" ]; revisar "Queda un anexo" $?
pedir dir GET "/director/proyecto.jsp?id=$PA"; contiene "anexo.pdf" && contiene "Anexos"; revisar "El director ve los anexos" $?

echo "== Plazo del director en días hábiles (RF21, RNF19)"
pedir ana POST /estudiante/propuesta-guardar.jsp -F "propuesta=@$T/propuesta.docx"
pedir ana POST /estudiante/propuesta-enviar.jsp; [[ "$DESTINO" == *"ok=propuesta-enviada"* ]]; revisar "Envía la propuesta" $?
# Plazo esperado: 5 días hábiles desde hoy, sin sábados, domingos ni festivos
$MYSQL -e "SELECT fecha FROM festivos" > "$T/festivos.txt"
D="$HOY"; N=0
while [ "$N" -lt 5 ]; do D=$(date -d "$D +1 day" +%F); [ "$(date -d "$D" +%u)" -lt 6 ] && ! grep -qx "$D" "$T/festivos.txt" && N=$((N+1)); done
[ "$($MYSQL -e "SELECT fecha_limite_revision FROM entregas WHERE proyecto_id=$PA AND tipo='FDC-124' AND version=1")" = "$D" ]
revisar "La revisión del director vence a los 5 días hábiles ($D)" $?
pedir ana POST /estudiante/anexo-guardar.jsp -F "anexo=@$T/anexo.pdf;type=application/pdf"; [[ "$DESTINO" == *"error=fase-no-permite-propuesta"* ]]; revisar "Enviada la propuesta, no se suben anexos" $?
[ "$(avisos 3 '%para revisarla%')" = "1" ] && [ "$(avisos 6 '%para revisarla%')" = "1" ]; revisar "El director y el codirector reciben el aviso con el plazo" $?
pedir dir GET "/director/proyecto.jsp?id=$PA"; contiene "Tienes hasta el" && contiene "Revisar la versión" && ! contiene "Observación de codirector"; revisar "El director ve su plazo y el formulario de revisión" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "tiene hasta el"; revisar "La estudiante ve hasta cuándo tiene el director" $?

echo "== Observaciones del codirector (RF13: comenta; decide el director)"
entrar doc docente.prueba@uts.edu.co; pedir doc POST /acceso/elegir-rol.jsp --data-urlencode "rol=3"
pedir doc GET "/director/proyecto.jsp?id=$PA"; contiene "Observación de codirector" && ! contiene "propuesta-revisar.jsp"; revisar "El codirector ve el formulario de observación, no el de decisión" $?
pedir doc POST /director/propuesta-observar.jsp --data-urlencode "id=$PA" --data-urlencode "observacion= "; [[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Observación vacía: rechazada" $?
pedir doc POST /director/propuesta-observar.jsp --data-urlencode "id=$PA" --data-urlencode "observacion=Revisar el presupuesto"; [[ "$DESTINO" == *"ok=observacion-codirector"* ]]; revisar "El codirector deja su observación" $?
[ "$($MYSQL -e "SELECT CONCAT(r.rol,'|',IFNULL(r.decision,'NULL')) FROM revisiones r JOIN entregas e ON e.id=r.entrega_id WHERE e.proyecto_id=$PA AND r.rol='Codirector'")" = "Codirector|NULL" ]
revisar "Queda como observación de codirector, sin decisión" $?
pedir doc POST /director/propuesta-revisar.jsp -F "id=$PA" -F "decision=devolver" -F "observacion=x"; [[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "El codirector no devuelve ni aprueba" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Codirector:" && contiene "Revisar el presupuesto"; revisar "La estudiante ve la observación del codirector" $?
pedir dir POST /director/propuesta-observar.jsp --data-urlencode "id=$PA" --data-urlencode "observacion=x"; [[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "El director no usa el formulario de codirector" $?

echo "== Plazo vencido del director"
$MYSQL -e "UPDATE entregas SET fecha_limite_revision='$AYER' WHERE proyecto_id=$PA AND tipo='FDC-124'"
pedir dir GET /panel/inicio.jsp
[ "$($MYSQL -e "SELECT COUNT(*) FROM avisos WHERE usuario_id=3 AND clave LIKE 'revision-e%'")" = "1" ]; revisar "El director recibe la alerta del plazo vencido" $?
pedir admin GET "/admin/proyectos.jsp?filtro=vencidos"; contiene "Idea A" && ! contiene "Idea B"; revisar "El comité filtra los plazos vencidos" $?
pedir admin GET "/admin/proyecto.jsp?id=$PA"; contiene "Se venció el plazo del director"; revisar "Y lo ve en el proyecto (sin aprobación automática)" $?
pedir dir POST /director/propuesta-revisar.jsp -F "id=$PA" -F "decision=devolver" -F "observacion=Ajustar objetivos"; [[ "$DESTINO" == *"ok=propuesta-devuelta-director"* ]]; revisar "El director todavía puede devolverla" $?
[ "$(avisos $ANA '%devolvi_ la versi_n 1%Ajustar objetivos%')" = "1" ]; revisar "La estudiante recibe el aviso de la devolución" $?

echo "== Cambio de modalidad (RF12)"
pedir ana POST /estudiante/modalidad-solicitar.jsp --data-urlencode "modalidad=2" --data-urlencode "motivo=x"; [[ "$DESTINO" == *"error=modalidad-invalida"* ]]; revisar "La misma modalidad: rechazado" $?
pedir ana POST /estudiante/modalidad-solicitar.jsp --data-urlencode "modalidad=3" --data-urlencode "motivo= "; [[ "$DESTINO" == *"error=motivo-requerido"* ]]; revisar "Sin motivo: rechazado" $?
pedir ana POST /estudiante/modalidad-solicitar.jsp --data-urlencode "modalidad=3" --data-urlencode "motivo=Prefiero hacer una monografia"
[[ "$DESTINO" == *"ok=modalidad-solicitada"* ]]; revisar "Pide pasar a Monografía" $?
pedir ana POST /estudiante/modalidad-solicitar.jsp --data-urlencode "modalidad=4" --data-urlencode "motivo=Otra"; [[ "$DESTINO" == *"error=modalidad-pendiente"* ]]; revisar "Una sola solicitud pendiente" $?
[ "$(avisos 1 '%pidi_ cambiar la modalidad%')" = "1" ]; revisar "El comité recibe el aviso" $?
pedir admin GET /panel/inicio.jsp; contiene "Solicitudes por decidir"; revisar "El inicio del comité cuenta las solicitudes" $?
pedir admin GET "/admin/proyectos.jsp?filtro=modalidad"; contiene "Idea A" && ! contiene "Idea B"; revisar "Filtro de cambios de modalidad por decidir" $?
CM=$($MYSQL -e "SELECT id FROM cambios_modalidad WHERE proyecto_id=$PA")
pedir admin POST /admin/modalidad-decidir.jsp --data-urlencode "id=$CM" --data-urlencode "decision=aprobar" --data-urlencode "observacion= "; [[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Decidir sin observación: rechazado" $?
pedir ana POST /admin/modalidad-decidir.jsp --data-urlencode "id=$CM" --data-urlencode "decision=aprobar" --data-urlencode "observacion=x"; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un estudiante no decide" $?
pedir admin POST /admin/modalidad-decidir.jsp --data-urlencode "id=$CM" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Viable"
[[ "$DESTINO" == *"ok=modalidad-aprobada"* ]] && [ "$($MYSQL -e "SELECT CONCAT(modalidad_id,'|',interdisciplinario,'|',(SELECT COUNT(*) FROM proyecto_codirectores WHERE proyecto_id=$PA)) FROM proyectos WHERE id=$PA")" = "3|0|0" ]
revisar "Aprobado: queda en Monografía, deja de ser interdisciplinario y sin codirectores" $?
[ "$($MYSQL -e "SELECT CONCAT(estado,'|',decidido_por) FROM cambios_modalidad WHERE id=$CM")" = "Aprobada|1" ] && [ "$($MYSQL -e "SELECT COUNT(*) FROM historial WHERE proyecto_id=$PA AND accion='Modalidad'")" = "2" ]
revisar "Queda el registro: quién pidió, quién decidió y el historial" $?
[ "$(avisos $ANA '%aprob_ el cambio de modalidad%')" = "1" ]; revisar "La estudiante recibe el aviso" $?
pedir admin POST /admin/modalidad-decidir.jsp --data-urlencode "id=$CM" --data-urlencode "decision=rechazar" --data-urlencode "observacion=x"; [[ "$DESTINO" == *"error=modalidad-ya-decidida"* ]]; revisar "Una solicitud decidida no se vuelve a decidir" $?
$MYSQL -e "UPDATE modalidades SET max_integrantes=1 WHERE id=4"
pedir carlos POST /estudiante/modalidad-solicitar.jsp --data-urlencode "modalidad=4" --data-urlencode "motivo=x"; [[ "$DESTINO" == *"error=modalidad-integrantes"* ]]; revisar "Una modalidad que no admite a los integrantes: rechazada" $?
$MYSQL -e "UPDATE modalidades SET max_integrantes=2 WHERE id=4; UPDATE proyectos SET fase_id=(SELECT id FROM fases WHERE orden=4) WHERE id=$PB"
pedir beto POST /estudiante/modalidad-solicitar.jsp --data-urlencode "modalidad=3" --data-urlencode "motivo=x"; [[ "$DESTINO" == *"error=modalidad-fuera-de-tiempo"* ]]; revisar "Con el FDC-124 aprobado (fase 4) ya no se cambia" $?
$MYSQL -e "UPDATE proyectos SET fase_id=(SELECT id FROM fases WHERE orden=1) WHERE id=$PB"

echo "== PQR (RNF1)"
pedir ana GET /panel/inicio.jsp; contiene 'panel/pqr.jsp'; revisar "El botón de PQR está en la cabecera" $?
pedir ana POST /panel/pqr-guardar.jsp --data-urlencode "tipo=Queja" --data-urlencode "comentario= "; [[ "$DESTINO" == *"error=pqr-incompleta"* ]]; revisar "PQR vacía: rechazada" $?
pedir ana POST /panel/pqr-guardar.jsp --data-urlencode "tipo=Otra" --data-urlencode "comentario=x"; [[ "$DESTINO" == *"error=pqr-incompleta"* ]]; revisar "Tipo inválido: rechazado" $?
pedir ana POST /panel/pqr-guardar.jsp --data-urlencode "tipo=Cambio de director" --data-urlencode "comentario=Necesito otro director"
[[ "$DESTINO" == *"ok=pqr-enviada"* ]] && [ "$($MYSQL -e "SELECT CONCAT(tipo,'|',estado,'|',proyecto_id) FROM pqrs WHERE usuario_id=$ANA")" = "Cambio de director|Pendiente|$PA" ]
revisar "Envía la PQR, ligada a su proyecto" $?
[ "$(avisos 1 '%Nueva PQR%')" = "1" ]; revisar "El comité recibe el aviso" $?
pedir admin GET /admin/pqrs.jsp; contiene "Necesito otro director" && contiene "Reporte" && sinError; revisar "El comité ve la PQR y el reporte" $?
Q=$($MYSQL -e "SELECT id FROM pqrs WHERE usuario_id=$ANA")
pedir admin POST /admin/pqr-responder.jsp --data-urlencode "id=$Q" --data-urlencode "respuesta= "; [[ "$DESTINO" == *"error=respuesta-requerida"* ]]; revisar "Respuesta vacía: rechazada" $?
pedir admin POST /admin/pqr-responder.jsp --data-urlencode "id=$Q" --data-urlencode "respuesta=Lo revisamos en la proxima sesion"; [[ "$DESTINO" == *"ok=pqr-respondida"* ]]; revisar "El comité responde" $?
pedir admin POST /admin/pqr-responder.jsp --data-urlencode "id=$Q" --data-urlencode "respuesta=otra"; [[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "No se responde dos veces" $?
pedir ana GET /panel/pqr.jsp; contiene "Lo revisamos en la proxima sesion"; revisar "La estudiante ve la respuesta" $?
[ "$(avisos $ANA '%respondi_ tu PQR%')" = "1" ]; revisar "Y recibe el aviso" $?
pedir admin GET "/admin/pqrs.jsp?estado=Todas&tipo=Queja"; contiene "No hay PQR con ese filtro"; revisar "Filtros por estado y tipo" $?
pedir ana GET /admin/pqrs.jsp; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un estudiante no entra a las PQR del comité" $?

echo "== Auditoría e historial (RNF12)"
pedir admin GET "/admin/auditoria.jsp?proyecto=65-2026-2/1"; contiene "Idea A" && ! contiene "Idea B" && sinError; revisar "Filtro por proyecto (código)" $?
pedir admin GET "/admin/auditoria.jsp?accion=Modalidad"; contiene "cambio de modalidad" && ! contiene "tomó la idea"; revisar "Filtro por tipo de acción" $?
pedir admin GET "/admin/auditoria.jsp?usuario=beto"; contiene "Idea B" && ! contiene "Idea A"; revisar "Filtro por usuario" $?
pedir admin GET "/admin/auditoria.jsp?desde=$MANANA"; contiene "No hay movimientos"; revisar "Filtro por fechas" $?
pedir ana GET /admin/auditoria.jsp; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un estudiante no entra a la auditoría" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Historial del proyecto" && ! contiene "Evaluador de Prueba"; revisar "La estudiante ve el historial, sin el nombre del evaluador" $?
pedir dir GET "/director/proyecto.jsp?id=$PA"; contiene "Historial del proyecto"; revisar "El director ve el historial" $?

echo "== Exoneración por Saber TyT (RNF14)"
exonerar() { pedir "$1" POST /estudiante/exoneracion-solicitar.jsp -F "puntaje=$2" ${3:+-F "certificado=@$3;type=application/pdf"}; }
exonerar uri 180 "$T/certificado.pdf"; [[ "$DESTINO" == *"error=exoneracion-solo-tecnologia"* ]]; revisar "Nivel universitario: no aplica (Saber Pro va aparte)" $?
pedir uri GET /estudiante/proyecto.jsp; ! contiene "Exoneración por Saber TyT"; revisar "Al universitario no le sale la sección" $?
exonerar beto 110 "$T/certificado.pdf"; [[ "$DESTINO" == *"error=puntaje-invalido"* ]]; revisar "Puntaje menor de 120: rechazado" $?
exonerar beto abc "$T/certificado.pdf"; [[ "$DESTINO" == *"error=puntaje-invalido"* ]]; revisar "Puntaje que no es número: rechazado" $?
exonerar beto 160; [[ "$DESTINO" == *"error=archivo-requerido"* ]]; revisar "Sin certificado: rechazado" $?
exonerar beto 160 "$T/certificado.pdf"; [[ "$DESTINO" == *"ok=exoneracion-solicitada"* ]]; revisar "Pide la exoneración con 160 puntos" $?
exonerar beto 165 "$T/certificado.pdf"; [[ "$DESTINO" == *"error=exoneracion-pendiente"* ]]; revisar "Una sola solicitud pendiente" $?
[ "$(avisos 1 '%pidi_ la exoneraci_n%')" = "1" ]; revisar "El comité recibe el aviso" $?
XB=$($MYSQL -e "SELECT id FROM exoneraciones WHERE estudiante_id=$(id beto@correo.uts.edu.co)")
pedir admin GET "/admin/proyecto.jsp?id=$PB"; contiene "Exoneraciones por Saber TyT" && contiene "4.7 y 50 % de beca" && sinError; revisar "El comité ve la solicitud con su estímulo" $?
pedir admin POST /admin/exoneracion-revisar.jsp --data-urlencode "id=$XB" --data-urlencode "decision=rechazar" --data-urlencode "observacion=El certificado no es legible"
[[ "$DESTINO" == *"ok=exoneracion-rechazada"* ]]; revisar "El comité la rechaza con observación" $?
pedir beto GET /estudiante/proyecto.jsp; contiene "El certificado no es legible" && contiene "exoneracion-solicitar.jsp"; revisar "El estudiante ve el rechazo y puede pedirla otra vez" $?
exonerar beto 175 "$T/certificado.pdf"
XB2=$($MYSQL -e "SELECT MAX(id) FROM exoneraciones WHERE estudiante_id=$(id beto@correo.uts.edu.co)")
pedir admin POST /admin/exoneracion-revisar.jsp --data-urlencode "id=$XB2" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Verificado"
[[ "$DESTINO" == *"ok=exoneracion-proyecto-terminado"* ]]; revisar "Proyecto individual: al aprobarla, el proyecto termina" $?
[ "$($MYSQL -e "SELECT CONCAT(p.estado,'|',pe.exonerado,'|',u.puntaje_saber_tyt) FROM proyectos p JOIN proyecto_estudiantes pe ON pe.proyecto_id=p.id JOIN usuarios u ON u.id=pe.estudiante_id WHERE p.id=$PB")" = "Finalizado|1|175" ]
revisar "Queda Finalizado, exonerado y con su puntaje" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM historial WHERE proyecto_id=$PB AND descripcion LIKE '%concepto Aprobado%'")" = "1" ]; revisar "El historial dice que terminó con concepto Aprobado" $?
pedir beto GET /estudiante/proyecto.jsp; contiene "terminó con concepto Aprobado" && contiene "5.0 y 100 % de beca" && ! contiene "pago-guardar.jsp"; revisar "El estudiante ve que terminó, con su estímulo, sin formularios" $?
subir beto; [[ "$DESTINO" == *"error=proyecto-cerrado"* ]]; revisar "En un proyecto terminado no se sube nada" $?
pedir beto POST /estudiante/exoneracion-renunciar.jsp; [[ "$DESTINO" == *"error=proyecto-cerrado"* ]]; revisar "Ni se renuncia" $?
pedir admin POST /admin/proyecto-asignar.jsp --data-urlencode "id=$PB" --data-urlencode "director=3"; [[ "$DESTINO" == *"error=proyecto-cerrado"* ]]; revisar "Ni el comité lo modifica" $?
CARLOS=$(id carlos@correo.uts.edu.co); DORA=$(id dora@correo.uts.edu.co)
exonerar carlos 155 "$T/certificado.pdf"
pedir admin POST /admin/exoneracion-revisar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM exoneraciones WHERE estudiante_id=$CARLOS")" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
[[ "$DESTINO" == *"ok=exoneracion-aprobada"* ]] && [ "$($MYSQL -e "SELECT estado FROM proyectos WHERE id=$PD")" = "Pendiente" ]; revisar "En un proyecto de dos, el compañero sigue (el proyecto no termina)" $?
pedir carlos GET /estudiante/proyecto.jsp; contiene "Estás exonerado" && contiene "4.7 y 50 % de beca"; revisar "El exonerado ve su estímulo" $?
pedir carlos POST /estudiante/exoneracion-renunciar.jsp; [[ "$DESTINO" == *"ok=exoneracion-renunciada"* ]]; revisar "Renuncia a la exoneración" $?
[ "$($MYSQL -e "SELECT CONCAT(exonerado,'|',renuncia_exoneracion) FROM proyecto_estudiantes WHERE estudiante_id=$CARLOS")" = "1|1" ]; revisar "Queda la renuncia" $?
exonerar carlos 160 "$T/certificado.pdf"; [[ "$DESTINO" == *"error=exoneracion-ya-decidida"* ]]; revisar "Después de renunciar no la pide otra vez (sin vuelta atrás)" $?
pedir carlos POST /estudiante/exoneracion-renunciar.jsp; [[ "$DESTINO" == *"error=sin-exoneracion"* ]]; revisar "No renuncia dos veces" $?
exonerar dora 130 "$T/certificado.pdf"
pedir admin POST /admin/exoneracion-revisar.jsp --data-urlencode "id=$($MYSQL -e "SELECT id FROM exoneraciones WHERE estudiante_id=$DORA")" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
[ "$($MYSQL -e "SELECT estado FROM proyectos WHERE id=$PD")" = "Pendiente" ]; revisar "Si uno renunció, aunque el otro quede exonerado el proyecto sigue" $?
# El informe final se entrega al enviarlo al director (fase 5); subir un borrador no cuenta
FASE_PA=$($MYSQL -e "SELECT fase_id FROM proyectos WHERE id=$PA")
$MYSQL -e "UPDATE proyectos SET fase_id=(SELECT id FROM fases WHERE orden=5) WHERE id=$PA"
exonerar ana 150 "$T/certificado.pdf"; [[ "$DESTINO" == *"error=exoneracion-informe-entregado"* ]]; revisar "Con el informe final entregado ya no se pide" $?
$MYSQL -e "UPDATE proyectos SET fase_id=$FASE_PA WHERE id=$PA"

echo "== Seminario: inscripción, seminario en curso y nota final (RF17)"
idIdea() { $MYSQL -e "SELECT id FROM ideas WHERE titulo='$1'"; }
pedir dir POST /ideas/idea-guardar.jsp --data-urlencode "titulo=Seminario de analitica" --data-urlencode "nivel=1" --data-urlencode "modalidad=5"
pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$(idIdea 'Seminario de analitica')" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
registrar sami@correo.uts.edu.co 5000000006 1; entrar sami sami@correo.uts.edu.co Clave123
pedir sami POST /ideas/idea-tomar.jsp --data-urlencode "id=$(idIdea 'Seminario de analitica')"
PS=$(proyectoDe sami@correo.uts.edu.co); SAMI=$(id sami@correo.uts.edu.co)
pedir sami GET /estudiante/proyecto.jsp; contiene "Inscripción al seminario" && contiene "Paso 1: Inscripción" && ! contiene "Para pasar a la fase 2" && sinError
revisar "El estudiante de Seminario ve la inscripción y sus pasos, no las fases del FDC-124" $?
inscribir() { pedir sami POST /estudiante/inscripcion-guardar.jsp -F "documento=$1" -F "archivo=@$2"; }
inscribir f-am-04 "$T/propuesta.docx"; [[ "$DESTINO" == *"error=archivo-invalido"* ]]; revisar "Documento que no es PDF: rechazado" $?
inscribir otro "$T/anexo.pdf;type=application/pdf"; [[ "$DESTINO" == *"error=general"* ]]; revisar "Tipo de documento inválido: rechazado" $?
inscribir f-am-04 "$T/anexo.pdf;type=application/pdf"; [[ "$DESTINO" == *"ok=inscripcion-documento"* ]]; revisar "Sube el formato F-AM-04" $?
pedir carlos POST /estudiante/inscripcion-guardar.jsp -F "documento=cedula" -F "archivo=@$T/anexo.pdf;type=application/pdf"
[[ "$DESTINO" == *"error=inscripcion-no-aplica"* ]]; revisar "Fuera de Seminario no se suben documentos de inscripción" $?
pedir admin POST /admin/proyecto-asignar.jsp --data-urlencode "id=$PS" --data-urlencode "director=3"
pedir admin POST /admin/inscripcion-validar.jsp --data-urlencode "id=$PS" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
[[ "$DESTINO" == *"error=pagos-pendientes"* ]]; revisar "Sin el pago aprobado no se valida" $?
subir sami; revisarPago "$(ultimoRecibo $PS $SAMI)" aprobar "Ok"
[ "$(fase $PS)" = "1" ] && [ "$($MYSQL -e "SELECT estado FROM proyectos WHERE id=$PS")" = "Pendiente" ]; revisar "Con pago y director, Seminario no pasa solo a la fase 2" $?
pedir admin POST /admin/inscripcion-validar.jsp --data-urlencode "id=$PS" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
[[ "$DESTINO" == *"error=inscripcion-incompleta"* ]]; revisar "Sin la cédula no se valida" $?
inscribir cedula "$T/anexo.pdf;type=application/pdf"
pedir admin GET "/admin/proyectos.jsp?filtro=seminario"; contiene "Seminario de analitica" && ! contiene "Idea A"; revisar "El comité filtra las inscripciones por validar" $?
pedir admin GET "/admin/proyecto.jsp?id=$PS"; contiene "Inscripción al seminario" && contiene "Formato F-AM-04" && contiene "inscripcion-validar.jsp" && sinError
revisar "El comité ve los documentos y el formulario de validación" $?
pedir admin POST /admin/inscripcion-validar.jsp --data-urlencode "id=$PS" --data-urlencode "decision=devolver" --data-urlencode "observacion= "
[[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Sin observación: rechazado" $?
pedir admin POST /admin/inscripcion-validar.jsp --data-urlencode "id=$PS" --data-urlencode "decision=devolver" --data-urlencode "observacion=La cedula no esta ampliada"
[[ "$DESTINO" == *"ok=inscripcion-devuelta"* ]]; revisar "El comité devuelve la inscripción" $?
[ "$(avisos $SAMI '%devolvi_ tu inscripci_n%no esta ampliada%')" = "1" ]; revisar "El estudiante recibe el aviso con la observación" $?
inscribir cedula "$T/anexo.pdf;type=application/pdf"
pedir admin POST /admin/inscripcion-validar.jsp --data-urlencode "id=$PS" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Soportes completos"
[[ "$DESTINO" == *"ok=inscripcion-validada"* ]] && [ "$($MYSQL -e "SELECT estado FROM proyectos WHERE id=$PS")" = "En curso" ]; revisar "El comité valida la inscripción: seminario en curso" $?
inscribir cedula "$T/anexo.pdf;type=application/pdf"; [[ "$DESTINO" == *"error=inscripcion-cerrada"* ]]; revisar "Validada, ya no se suben documentos" $?
pedir sami POST /estudiante/modalidad-solicitar.jsp --data-urlencode "modalidad=3" --data-urlencode "motivo=x"
[[ "$DESTINO" == *"error=modalidad-fuera-de-tiempo"* ]]; revisar "Ni se cambia la modalidad" $?
pedir sami GET /estudiante/proyecto.jsp; contiene "Seminario en curso" && contiene "Paso 2: Seminario en curso"; revisar "El estudiante ve el seminario en curso" $?
pedir dir GET "/director/proyecto.jsp?id=$PS"; contiene "Nota final del seminario" && sinError; revisar "El docente ve el formulario de la nota final" $?
nota() { pedir dir POST /director/nota-registrar.jsp --data-urlencode "id=$1" --data-urlencode "nota=$2" --data-urlencode "observacion=$3"; }
nota $PS 6 "x"; [[ "$DESTINO" == *"error=nota-invalida"* ]]; revisar "Nota de 6: rechazada" $?
nota $PS "4.5abc" "x"; [[ "$DESTINO" == *"error=nota-invalida"* ]]; revisar "Nota con letras: rechazada" $?
nota $PS "4,5" " "; [[ "$DESTINO" == *"error=observacion-requerida"* ]]; revisar "Sin observación: rechazada" $?
pedir doc POST /director/nota-registrar.jsp --data-urlencode "id=$PS" --data-urlencode "nota=4" --data-urlencode "observacion=x"
[[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "Solo el docente del seminario registra la nota" $?
nota $PS "4,5" "Buen articulo"; [[ "$DESTINO" == *"ok=nota-aprobada"* ]]; revisar "Registra 4,5: aprobado" $?
[ "$($MYSQL -e "SELECT CONCAT(estado,'|',nota_final) FROM proyectos WHERE id=$PS")" = "Finalizado|4.5" ]; revisar "Queda Finalizado con la nota 4.5" $?
pedir sami GET /estudiante/proyecto.jsp; contiene "Aprobaste el seminario con nota"; revisar "El estudiante ve que aprobó con su nota" $?
nota $PS "3" "x"; [[ "$DESTINO" == *"error=nota-no-aplica"* ]]; revisar "La nota no se registra dos veces" $?
pedir dir POST /ideas/idea-guardar.jsp --data-urlencode "titulo=Seminario B" --data-urlencode "nivel=1" --data-urlencode "modalidad=5"
pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$(idIdea 'Seminario B')" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
registrar sol@correo.uts.edu.co 5000000007 1; entrar sol sol@correo.uts.edu.co Clave123
pedir sol POST /ideas/idea-tomar.jsp --data-urlencode "id=$(idIdea 'Seminario B')"
PSB=$(proyectoDe sol@correo.uts.edu.co)
$MYSQL -e "UPDATE proyectos SET estado='En curso', director_id=3 WHERE id=$PSB"
nota $PSB "2.0" "No entrego el articulo"
[[ "$DESTINO" == *"ok=nota-reprobada"* ]] && [ "$($MYSQL -e "SELECT estado FROM proyectos WHERE id=$PSB")" = "Cancelado" ]; revisar "Registra 2.0: reprobado, el proyecto se cancela" $?
[ -z "$(proyectoDe sol@correo.uts.edu.co)" ]; revisar "El estudiante queda libre para empezar de nuevo" $?

echo "== Semana 12 vencida: cancelación por extemporaneidad (RF30, RNF21)"
pedir dir POST /ideas/idea-guardar.jsp --data-urlencode "titulo=Idea N" --data-urlencode "nivel=1" --data-urlencode "modalidad=2"
pedir admin POST /ideas/idea-revisar.jsp --data-urlencode "id=$(idIdea 'Idea N')" --data-urlencode "decision=aprobar" --data-urlencode "observacion=Ok"
registrar nico@correo.uts.edu.co 5000000008 1 Nuevo; entrar nico nico@correo.uts.edu.co Clave123
pedir nico POST /ideas/idea-tomar.jsp --data-urlencode "id=$(idIdea 'Idea N')"
PN=$(proyectoDe nico@correo.uts.edu.co)
$MYSQL -e "UPDATE periodos SET fecha_limite_propuestas='$AYER' WHERE id=$P1"
pedir admin GET /panel/inicio.jsp
[ "$($MYSQL -e "SELECT estado FROM proyectos WHERE id=$PA")" = "Cancelado" ]; revisar "Al usar el sistema, el proyecto con la propuesta sin aprobar se cancela" $?
[ -z "$(proyectoDe ana@correo.uts.edu.co)" ]; revisar "La estudiante queda libre (el pago pierde vigencia)" $?
[ "$($MYSQL -e "SELECT estado FROM ideas WHERE titulo='Idea A'")" = "Aprobada" ]; revisar "La idea vuelve al banco" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM historial WHERE proyecto_id=$PA AND descripcion LIKE '%extemporaneidad%'")" = "1" ]; revisar "Queda en el historial" $?
[ "$(avisos $ANA '%extemporaneidad%')" = "1" ] && [ "$(avisos 3 '%extemporaneidad%')" -ge 1 ]; revisar "Se avisa a la estudiante y al director" $?
[ "$($MYSQL -e "SELECT estado FROM proyectos WHERE id=$PN")" = "Pendiente" ]; revisar "Un proyecto solo de plan nuevo no se cancela (RF41)" $?
[ "$($MYSQL -e "SELECT CONCAT(estado,'|',(SELECT estado FROM proyectos WHERE id=$PS)) FROM proyectos WHERE id=$PB")" = "Finalizado|Finalizado" ]
revisar "Los proyectos terminados y el Seminario no se tocan" $?
pedir admin GET /panel/inicio.jsp
[ "$($MYSQL -e "SELECT COUNT(*) FROM historial WHERE proyecto_id=$PA AND descripcion LIKE '%extemporaneidad%'")" = "1" ]; revisar "No se cancela dos veces" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Todavía no tienes un proyecto"; revisar "La estudiante ya no tiene proyecto vigente" $?
$MYSQL -e "UPDATE periodos SET fecha_limite_propuestas='$EN60' WHERE id=$P1"

echo "== Diseño"
MOJIBAKE=0
for R in "ana /panel/avisos.jsp" "ana /panel/pqr.jsp" "admin /admin/pqrs.jsp" "admin /admin/auditoria.jsp" "admin /admin/proyecto.jsp?id=$PA" "ana /estudiante/proyecto.jsp" "dir /director/proyecto.jsp?id=$PA" "anon /registro.jsp"; do
    set -- $R; pedir "$1" GET "$2"; grep -q "Ã" "$T/cuerpo.html" && MOJIBAKE=1; sinError || MOJIBAKE=1
done
[ "$MOJIBAKE" = 0 ]; revisar "Las páginas nuevas abren sin errores ni letras raras (Ã)" $?
pedir admin GET /panel/inicio.jsp; contiene 'admin/pqrs.jsp" class' && contiene 'admin/auditoria.jsp" class'; revisar "El menú del comité tiene PQR y Auditoría" $?

# Borra solo los archivos que crearon estas pruebas
ls "$ARCHIVOS" | grep -vxF -f "$T/archivos-antes.txt" | while read -r A; do rm -f "$ARCHIVOS/$A"; done

echo
echo "Resultado: $OK bien, $FALLA con falla"
