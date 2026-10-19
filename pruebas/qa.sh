#!/usr/bin/env bash
# Pruebas de QA (2026-10-14): lo que no cubren las suites de cada sprint.
#   1. Matriz de acceso: cada página (sacada de la lista de archivos) sin sesión, con cada rol
#      y con el rol correcto (RNF5).
#   2. Datos ajenos: archivos, proyectos, ideas, avisos, anexos e integrantes de otros (RF27).
#   3. Escalar de rol desde "elegir rol".
#   4. Inyección de HTML/JavaScript (guardado y reflejado) y de SQL (RNF18).
#   5. Parámetros basura (letras, negativos, enormes, vacíos) en todas las páginas con id.
#   6. Todas las páginas de guardar abiertas con GET: no cambian nada.
#   7. Subida de archivos: tipo, tamaño, vacío y nombres peligrosos (RNF15, RNF16).
#   8. Sesión: cookie HttpOnly, nuevo identificador al entrar, caché y salida (RNF6).
# Se corre con correr-pruebas.sh (respalda la base y los archivos y los devuelve):
#   bash pruebas/correr-pruebas.sh <carpeta-respaldo> qa
cd "$(dirname "$0")/.." || exit 1
B="http://localhost:8080/segundo-parcial"
T="pruebas/tmp/qa"; rm -rf "$T"; mkdir -p "$T"
OK=0; FALLA=0
MYSQL="/c/xampp/mysql/bin/mysql.exe -u root -N -B -D sistemas_proyectos_grado --default-character-set=utf8mb4"

revisar() { if [ "$2" -eq 0 ]; then echo "  OK    $1"; OK=$((OK+1)); else echo "  FALLA $1"; FALLA=$((FALLA+1)); fi; }
pedir() { # sesión, método, ruta, datos...
    local jar="$T/$1"; local metodo="$2"; local ruta="$3"; shift 3
    if [ "$metodo" = "POST" ]; then
        RES=$(curl -s -o "$T/cuerpo.html" -D "$T/encabezados.txt" -w "%{http_code} %{redirect_url}" -b "$jar" -c "$jar" -X POST "$@" "$B$ruta")
    else
        RES=$(curl -s -o "$T/cuerpo.html" -D "$T/encabezados.txt" -w "%{http_code} %{redirect_url}" -b "$jar" -c "$jar" "$B$ruta")
    fi
    CODIGO="${RES%% *}"; DESTINO="${RES#* }"
}
contiene() { grep -q -- "$1" "$T/cuerpo.html"; }
sinError() { ! grep -q "Exception\|HTTP Status 500\|Estado HTTP 500\|HTTP Status 404\|Estado HTTP 404" "$T/cuerpo.html"; }
sano() { [ "$CODIGO" = "200" -o "$CODIGO" = "302" ] && sinError; }
entrar() { pedir "$1" POST /acceso/validar.jsp --data-urlencode "correo=$2" --data-urlencode "clave=123456"; }

echo "== Datos: tres proyectos con distinto director, evaluador y estudiantes"
$MYSQL <<'SQL'
INSERT INTO periodos (id, nombre, estado, fecha_inicio_semestre, fecha_cierre_banco, fecha_limite_pago, fecha_limite_propuestas)
VALUES (1, '2026-2', 'Activo', CURDATE() - INTERVAL 30 DAY, CURDATE() + INTERVAL 30 DAY, CURDATE() + INTERVAL 30 DAY, CURDATE() + INTERVAL 60 DAY);
INSERT INTO usuarios (id, nombre, tipo_documento_id, numero_documento, correo, contrasena, nivel_id, carrera_id, plan_estudios, porcentaje_creditos, metodologia_aprobada) VALUES
    (20, 'Ana QA', 1, '7000000020', 'ana.qa@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (21, 'Beto QA', 1, '7000000021', 'beto.qa@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (22, 'Caro QA', 1, '7000000022', 'caro.qa@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (23, 'Dani QA', 1, '7000000023', 'dani.qa@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1);
INSERT INTO usuario_roles (usuario_id, rol_id) VALUES (20, 5), (21, 5), (22, 5), (23, 5);
-- P1: director 3, evaluador 4, Ana (y Caro, a quien quitaron). P2: director 6, evaluador 4, Beto.
-- P3: director 3, evaluador 6, Dani. Los tres en la fase 2 (Propuesta I).
INSERT INTO proyectos (id, codigo, titulo, modalidad_id, nivel_id, periodo_id, fase_id, estado, director_id, evaluador_id, fecha_inicio) VALUES
    (1, '65-2026-2/1', 'Proyecto QA uno', 2, 1, 1, 3, 'En curso', 3, 4, CURDATE()),
    (2, '65-2026-2/2', 'Proyecto QA dos', 2, 1, 1, 3, 'En curso', 6, 4, CURDATE()),
    (3, '65-2026-2/3', 'Proyecto QA tres', 2, 1, 1, 3, 'En curso', 3, 6, CURDATE());
INSERT INTO proyecto_estudiantes (proyecto_id, estudiante_id, estado, vigente) VALUES
    (1, 20, 'Activo', 1), (1, 22, 'Excluido', NULL), (2, 21, 'Activo', 1), (3, 23, 'Activo', 1);
INSERT INTO entregas (id, proyecto_id, fase_id, tipo, nombre_archivo, ruta_archivo, subido_por) VALUES
    (1, 1, 3, 'Anexo', 'anexo-ana.pdf', 'qa-p1.pdf', 20),
    (2, 2, 3, 'Anexo', 'anexo-beto.pdf', 'qa-p2.pdf', 21),
    (3, 3, 2, 'Recibo de pago', 'recibo-dani.pdf', 'qa-p3.pdf', 23);
INSERT INTO ideas (id, titulo, nivel_id, origen, propuesta_por, estado) VALUES
    (1, 'Idea QA del director', 1, 'Docente', 3, 'Pendiente'),
    (2, 'Idea QA de Beto', 1, 'Estudiante', 21, 'Pendiente');
INSERT INTO avisos (id, usuario_id, proyecto_id, mensaje, enlace) VALUES (1, 21, 2, 'Aviso privado de Beto', '/estudiante/proyecto.jsp');
SQL
for n in 1 2 3; do printf '%%PDF-1.4\n%% archivo QA %s\n' "$n" > "WEB-INF/archivos/qa-p$n.pdf"; done
[ "$($MYSQL -e "SELECT COUNT(*) FROM proyectos")" = "3" ] && [ -f WEB-INF/archivos/qa-p1.pdf ]; revisar "Datos listos: 3 proyectos, 4 estudiantes, 3 archivos" $?

entrar admin admin.prueba@uts.edu.co; entrar dir director.prueba@uts.edu.co; entrar eva evaluador.prueba@uts.edu.co
entrar ana ana.qa@correo.uts.edu.co; entrar beto beto.qa@correo.uts.edu.co; entrar caro caro.qa@correo.uts.edu.co
entrar doc docente.prueba@uts.edu.co; pedir doc POST /acceso/elegir-rol.jsp --data-urlencode "rol=3"

# Páginas, sacadas de la lista de archivos: GET (se ven) y POST (guardan)
paginas() { # carpeta → rutas
    for f in $(ls "$1"/*.jsp); do echo "/$f"; done
}
esPost() { grep -q "request.method != 'POST'" ".$1"; }
sesionDe() { case "$1" in /admin/*) echo admin;; /director/*) echo dir;; /evaluador/*) echo eva;; /estudiante/*) echo ana;; esac; }
conId() { case "$1" in /admin/proyecto.jsp) echo "?id=1";; /admin/modalidad-form.jsp) echo "?id=1";; /director/proyecto.jsp) echo "?id=1";; /evaluador/proyecto.jsp) echo "?id=1";; /admin/sesiones.jsp) echo "?periodo=1";; esac; }

echo "== 1. Matriz de acceso (RNF5)"
TOTAL=0; MAL=""
for CARPETA in admin director evaluador estudiante; do
    for R in $(paginas $CARPETA); do
        TOTAL=$((TOTAL+1))
        # Sin sesión: al inicio de sesión
        if esPost "$R"; then pedir anon POST "$R" --data-urlencode "id=1"; else pedir anon GET "$R$(conId "$R")"; fi
        [[ "$CODIGO" = 302 && "$DESTINO" == *"index.jsp?aviso=sesion"* ]] || MAL="$MAL [sin sesión $R]"
        # Con otro rol: denegado
        for S in admin dir eva ana; do
            [ "$S" = "$(sesionDe "$R")" ] && continue
            if esPost "$R"; then pedir $S POST "$R" --data-urlencode "id=1"; else pedir $S GET "$R$(conId "$R")"; fi
            [[ "$CODIGO" = 302 && "$DESTINO" == *"error=denegado"* ]] || MAL="$MAL [$S en $R: $CODIGO $DESTINO]"
        done
        # Con su rol: abre bien (GET) o, abierta con GET, no hace nada (POST)
        S=$(sesionDe "$R")
        pedir $S GET "$R$(conId "$R")"
        if esPost "$R"; then [ "$CODIGO" = 302 ] && sinError || MAL="$MAL [GET a $R: $CODIGO]"
        else [ "$CODIGO" = 200 ] && sinError || MAL="$MAL [$S en $R: $CODIGO]"; fi
    done
done
[ -z "$MAL" ]; revisar "$TOTAL páginas: sin sesión van al login, con otro rol se niegan y con su rol abren${MAL:+ —$MAL}" $?
MAL=""
for R in /panel/inicio.jsp /panel/buscar.jsp /panel/avisos.jsp /panel/calendario.jsp /panel/modalidades.jsp /panel/pqr.jsp /ideas/banco.jsp /ideas/idea-form.jsp /archivos/ver.jsp?id=1; do
    pedir anon GET "$R"; [[ "$CODIGO" = 302 && "$DESTINO" == *"index.jsp?aviso=sesion"* ]] || MAL="$MAL $R"
done
[ -z "$MAL" ]; revisar "Las páginas comunes también exigen sesión${MAL:+ — fallan:$MAL}" $?
pedir ana POST /ideas/idea-revisar.jsp --data-urlencode "id=2" --data-urlencode "decision=aprobar" --data-urlencode "observacion=x"
[[ "$DESTINO" == *"error=denegado"* ]] && [ "$($MYSQL -e "SELECT estado FROM ideas WHERE id=2")" = "Pendiente" ]; revisar "Un estudiante no aprueba ideas (solo el comité)" $?
pedir dir POST /ideas/idea-tomar.jsp --data-urlencode "id=1"; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un docente no toma ideas (solo estudiantes)" $?

echo "== 2. Datos ajenos (RF27)"
pedir ana GET "/archivos/ver.jsp?id=1"; [ "$CODIGO" = 200 ] && contiene "archivo QA 1"; revisar "Ana descarga el archivo de su proyecto" $?
pedir ana GET "/archivos/ver.jsp?id=2"; [[ "$DESTINO" == *"error=denegado"* ]] && ! contiene "archivo QA 2"; revisar "Ana no descarga el de otro proyecto" $?
pedir caro GET "/archivos/ver.jsp?id=1"; [[ "$DESTINO" == *"error=denegado"* ]] && ! contiene "archivo QA 1"; revisar "Caro, a quien quitaron del proyecto, ya no descarga sus archivos" $?
$MYSQL -e "UPDATE proyectos SET estado='Cancelado' WHERE id=2; UPDATE proyecto_estudiantes SET vigente=NULL WHERE proyecto_id=2"
pedir beto GET "/archivos/ver.jsp?id=2"; [ "$CODIGO" = 200 ] && contiene "archivo QA 2"; revisar "Si el proyecto se cancela, el estudiante sigue viendo sus documentos" $?
$MYSQL -e "UPDATE proyectos SET estado='En curso' WHERE id=2; UPDATE proyecto_estudiantes SET vigente=1 WHERE proyecto_id=2"
pedir dir GET "/archivos/ver.jsp?id=2"; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "El director no descarga archivos de un proyecto que no dirige" $?
pedir eva GET "/archivos/ver.jsp?id=3"; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "El evaluador no descarga archivos de un proyecto que no evalúa" $?
pedir admin GET "/archivos/ver.jsp?id=3"; [ "$CODIGO" = 200 ] && contiene "archivo QA 3"; revisar "El comité descarga cualquiera" $?
pedir dir GET "/director/proyecto.jsp?id=2"; [[ "$DESTINO" == *"error=no-encontrado"* ]] && ! contiene "Proyecto QA dos"; revisar "El director no abre un proyecto que no dirige" $?
pedir doc GET "/director/proyecto.jsp?id=2"; [ "$CODIGO" = 200 ] && contiene "Proyecto QA dos"; revisar "Su director sí lo abre" $?
pedir eva GET "/evaluador/proyecto.jsp?id=3"; [[ "$DESTINO" == *"error=no-encontrado"* ]]; revisar "El evaluador no abre un proyecto que no evalúa" $?
pedir dir POST /director/seguimiento-registrar.jsp --data-urlencode "id=2" --data-urlencode "observacion=intruso"
[ "$($MYSQL -e "SELECT COUNT(*) FROM seguimientos")" = "0" ]; revisar "El director no registra seguimientos en un proyecto ajeno" $?
pedir dir POST /director/propuesta-observar.jsp --data-urlencode "id=2" --data-urlencode "observacion=intruso"
[ "$($MYSQL -e "SELECT COUNT(*) FROM revisiones")" = "0" ]; revisar "Ni deja observaciones en él" $?
pedir eva POST /evaluador/evaluacion-guardar.jsp --data-urlencode "id=3" --data-urlencode "accion=enviar" --data-urlencode "concepto=Aprobado" --data-urlencode "observacion=intruso"
[ "$($MYSQL -e "SELECT COUNT(*) FROM revisiones")" = "0" ]; revisar "El evaluador no evalúa un proyecto ajeno" $?
pedir ana POST /estudiante/anexo-quitar.jsp --data-urlencode "id=2"
[ "$($MYSQL -e "SELECT COUNT(*) FROM entregas WHERE id=2")" = "1" ]; revisar "Ana no quita anexos de otro proyecto" $?
pedir ana POST /estudiante/integrante-quitar.jsp --data-urlencode "estudiante=21"; QUITAR=$CODIGO
pedir ana POST /estudiante/integrante-salir.jsp --data-urlencode "estudiante=21"
[ "$QUITAR" = "404" ] && [ "$($MYSQL -e "SELECT vigente FROM proyecto_estudiantes WHERE estudiante_id=21")" = "1" ]
revisar "Ana no quita integrantes de otro proyecto (ya no hay Quitar, y Salirme solo la saca a ella)" $?
pedir ana POST /ideas/idea-eliminar.jsp --data-urlencode "id=2"
[ "$($MYSQL -e "SELECT COUNT(*) FROM ideas WHERE id=2")" = "1" ]; revisar "Ana no borra la idea de Beto" $?
pedir dir POST /ideas/idea-eliminar.jsp --data-urlencode "id=2"
[ "$($MYSQL -e "SELECT COUNT(*) FROM ideas WHERE id=2")" = "1" ]; revisar "Un docente tampoco" $?
pedir ana GET "/panel/aviso-abrir.jsp?id=1"
[[ "$DESTINO" == *"/panel/avisos.jsp" ]] && [ "$($MYSQL -e "SELECT leido FROM avisos WHERE id=1")" = "0" ]; revisar "Ana no abre ni marca los avisos de Beto" $?
pedir ana GET /panel/avisos.jsp; ! contiene "Aviso privado de Beto"; revisar "Ni los ve en su lista" $?
pedir ana GET /estudiante/proyecto.jsp; contiene "Proyecto QA uno" && ! contiene "Proyecto QA dos" && ! contiene "Evaluador de Prueba"
revisar "Ana ve solo su proyecto y no ve a su evaluador" $?
pedir ana GET /admin/usuarios.jsp; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Ana no ve la lista de usuarios" $?

echo "== 3. Escalar de rol"
pedir doc POST /acceso/elegir-rol.jsp --data-urlencode "rol=1"
pedir doc GET /admin/usuarios.jsp; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Un docente no se vuelve administrador pidiendo rol=1" $?
pedir doc GET "/acceso/elegir-rol.jsp?rol=5"; pedir doc GET /estudiante/proyecto.jsp; [[ "$DESTINO" == *"error=denegado"* ]]; revisar "Ni estudiante (rol que no tiene)" $?
pedir doc POST /acceso/elegir-rol.jsp --data-urlencode "rol=3"

echo "== 4. Inyección de HTML/JavaScript y de SQL (RNF18)"
XSS='<script>alert("qa")</script>'; XSS2='"><img src=x onerror=alert(1)>'
pedir beto POST /ideas/idea-guardar.jsp --data-urlencode "titulo=$XSS" --data-urlencode "descripcion=$XSS2"
pedir beto POST /panel/pqr-guardar.jsp --data-urlencode "tipo=Queja" --data-urlencode "comentario=$XSS"
pedir dir POST /director/seguimiento-registrar.jsp --data-urlencode "id=1" --data-urlencode "observacion=$XSS"
$MYSQL -e "UPDATE usuarios SET nombre='$XSS2' WHERE id=23"
MAL=""
for R in "admin|/ideas/banco.jsp" "admin|/admin/pqrs.jsp" "admin|/admin/usuarios.jsp" "admin|/admin/proyecto.jsp?id=3" "admin|/admin/proyectos.jsp" \
         "admin|/admin/auditoria.jsp" "beto|/ideas/banco.jsp" "beto|/panel/pqr.jsp"; do
    IFS='|' read -r S RUTA <<< "$R"; pedir "$S" GET "$RUTA"
    if contiene '<script>alert("qa")' || contiene '<img src=x onerror'; then MAL="$MAL $RUTA($S)"; fi
done
[ -z "$MAL" ]; revisar "Lo que escriben los usuarios sale escapado (ideas, PQR, nombres, auditoría)${MAL:+ — sin escapar en:$MAL}" $?
pedir admin GET /ideas/banco.jsp; contiene '&lt;script&gt;alert'; revisar "Y se ve como texto, no se pierde" $?
MAL=""
for R in "anon|/index.jsp?correo=$XSS2" "anon|/index.jsp?error=$XSS" "anon|/registro.jsp?nombre=$XSS2&correo=$XSS2&error=$XSS" "admin|/admin/usuarios.jsp?q=$XSS2" \
         "admin|/admin/auditoria.jsp?usuario=$XSS2&proyecto=$XSS2" "beto|/panel/pqr.jsp?comentario=$XSS" "beto|/ideas/idea-form.jsp?titulo=$XSS2&descripcion=$XSS" \
         "admin|/admin/proyectos.jsp?filtro=$XSS2" "admin|/admin/pqrs.jsp?estado=$XSS2&tipo=$XSS2" "admin|/panel/inicio.jsp?ok=$XSS&error=$XSS"; do
    S="${R%%|*}"; RUTA="${R#*|}"
    pedir "$S" GET "$(printf '%s' "$RUTA" | sed 's/ /%20/g; s/"/%22/g; s/</%3C/g; s/>/%3E/g')"
    if contiene '<script>alert("qa")' || contiene '<img src=x onerror'; then MAL="$MAL $RUTA"; fi
    sinError || MAL="$MAL [error en $RUTA]"
done
[ -z "$MAL" ]; revisar "Lo que llega en la dirección no se refleja sin escapar${MAL:+ — falla:$MAL}" $?
pedir anon POST /acceso/validar.jsp --data-urlencode "correo=x' OR '1'='1' -- @uts.edu.co" --data-urlencode "clave=x' OR '1'='1"
[[ "$DESTINO" == *"error=credenciales"* ]]; revisar "Inyección SQL en el inicio de sesión: no entra" $?
pedir anon POST /acceso/validar.jsp --data-urlencode "correo=admin.prueba@uts.edu.co' -- " --data-urlencode "clave=mala"
[[ "$DESTINO" == *"error="* ]]; revisar "Ni comentando la contraseña" $?
pedir admin GET "/admin/usuarios.jsp?q=%27%20OR%20%271%27%3D%271"; sinError && ! contiene "ana.qa@correo"; revisar "Inyección SQL en la búsqueda de usuarios: no trae a todos" $?
pedir admin GET "/admin/auditoria.jsp?proyecto=1%27%20OR%201%3D1%20--%20"; sinError; revisar "Ni rompe la auditoría" $?
pedir admin GET "/admin/proyecto.jsp?id=1%20OR%201%3D1"; sano; revisar "Ni el id de un proyecto" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM usuarios")" -ge "9" ] && [ "$($MYSQL -e "SELECT COUNT(*) FROM proyectos")" = "3" ]; revisar "La base sigue entera" $?

echo "== 5. Parámetros basura en las páginas con id"
MAL=""; N=0
for V in "abc" "-1" "0" "99999999999999999999" "1.5" "1%3BDROP%20TABLE%20usuarios" "%27" "%00" ""; do
    for R in "admin|/admin/proyecto.jsp?id=" "admin|/admin/usuario-form.jsp?id=" "admin|/admin/periodo-form.jsp?id=" "admin|/admin/rol-form.jsp?id=" \
             "admin|/admin/modalidad-form.jsp?id=" "admin|/admin/sesiones.jsp?periodo=" "dir|/director/proyecto.jsp?id=" "eva|/evaluador/proyecto.jsp?id=" \
             "ana|/archivos/ver.jsp?id=" "ana|/panel/aviso-abrir.jsp?id=" "beto|/ideas/idea-form.jsp?id=" "admin|/admin/auditoria.jsp?desde=" \
             "admin|/admin/auditoria.jsp?hasta=" "admin|/admin/usuarios.jsp?rol=" "admin|/admin/usuarios.jsp?nivel=" "admin|/ideas/banco.jsp?estado="; do
        S="${R%%|*}"; RUTA="${R#*|}$V"; N=$((N+1))
        pedir "$S" GET "$RUTA"; sano || MAL="$MAL [$RUTA: $CODIGO]"
    done
done
[ -z "$MAL" ]; revisar "$N combinaciones de páginas y valores raros: ninguna da error${MAL:+ —$MAL}" $?
MAL=""; N=0
for CARPETA in admin director evaluador estudiante ideas panel; do
    for R in $(paginas $CARPETA); do
        esPost "$R" || continue
        S=$(sesionDe "$R"); [ -z "$S" ] && S=beto; [ "$R" = /ideas/idea-revisar.jsp ] && S=admin; [ "$R" = /ideas/idea-tomar.jsp ] && S=ana
        for V in "abc" "99999999999999999999" "-1"; do
            N=$((N+1)); pedir "$S" POST "$R" --data-urlencode "id=$V" --data-urlencode "decision=aprobar" --data-urlencode "observacion=x" \
                --data-urlencode "estudiante=$V" --data-urlencode "periodo=$V" --data-urlencode "acta=$V" --data-urlencode "fecha_acta=$V"
            sano || MAL="$MAL [$R id=$V: $CODIGO]"
        done
    done
done
[ -z "$MAL" ]; revisar "$N envíos con ids basura a las páginas de guardar: ninguno da error${MAL:+ —$MAL}" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM proyectos")" = "3" ] && [ "$($MYSQL -e "SELECT COUNT(*) FROM proyecto_estudiantes WHERE vigente=1")" = "3" ]; revisar "Y no cambiaron los datos" $?

echo "== 6. Las páginas de guardar no hacen nada con GET"
ANTES=$($MYSQL -e "SELECT CONCAT((SELECT COUNT(*) FROM historial), '|', (SELECT COUNT(*) FROM entregas), '|', (SELECT COUNT(*) FROM revisiones), '|', (SELECT COUNT(*) FROM avisos))")
MAL=""
for CARPETA in admin director evaluador estudiante ideas panel acceso; do
    for R in $(paginas $CARPETA); do
        esPost "$R" || continue
        S=$(sesionDe "$R"); [ -z "$S" ] && S=beto
        pedir "$S" GET "$R?id=1&decision=aprobar&observacion=x"; [ "$CODIGO" = 302 ] && sinError || MAL="$MAL $R"
    done
done
DESPUES=$($MYSQL -e "SELECT CONCAT((SELECT COUNT(*) FROM historial), '|', (SELECT COUNT(*) FROM entregas), '|', (SELECT COUNT(*) FROM revisiones), '|', (SELECT COUNT(*) FROM avisos))")
[ -z "$MAL" ] && [ "$ANTES" = "$DESPUES" ]; revisar "Todas redirigen y no cambian la base ($ANTES → $DESPUES)${MAL:+ — fallan:$MAL}" $?

echo "== 7. Subida de archivos (RNF15, RNF16)"
printf 'documento de Word' > "$T/propuesta.docx"; printf '%%PDF-1.4\n' > "$T/anexo.pdf"; printf 'MZ ejecutable' > "$T/programa.exe"
cp "$T/programa.exe" "$T/propuesta.docx.exe"; : > "$T/vacio.docx"
head -c 16000000 /dev/zero > "$T/grande.docx"
subir() { pedir ana POST /estudiante/propuesta-guardar.jsp -F "propuesta=@$1${2:+;filename=$2}"; }
subir "$T/anexo.pdf"; [[ "$DESTINO" == *"error=archivo-no-word"* ]]; revisar "La propuesta en PDF: rechazada (va en Word)" $?
subir "$T/programa.exe"; [[ "$DESTINO" == *"error=archivo-no-word"* ]]; revisar "Un .exe: rechazado" $?
subir "$T/propuesta.docx.exe"; [[ "$DESTINO" == *"error=archivo-no-word"* ]]; revisar "Un .docx.exe (doble extensión): rechazado" $?
subir "$T/vacio.docx"; [[ "$DESTINO" == *"error=archivo-requerido"* ]]; revisar "Un archivo vacío: rechazado" $?
subir "$T/grande.docx"; [[ "$DESTINO" == *"error=archivo-grande"* ]] && sinError; revisar "Uno de más de 15 MB: rechazado con su mensaje" $?
pedir ana POST /estudiante/propuesta-guardar.jsp; [[ "$DESTINO" == *"error=archivo-requerido"* ]] || [[ "$DESTINO" == *"error="* ]]; revisar "Sin archivo: rechazado" $?
subir "$T/propuesta.docx" '../../../../WEB-INF/web.xml.docx'
RUTA=$($MYSQL -e "SELECT ruta_archivo FROM entregas WHERE tipo='FDC-124' ORDER BY id DESC LIMIT 1" | tr -d '\r')
[[ "$DESTINO" == *"ok=propuesta-subida"* ]] && [[ "$RUTA" != *"/"* && "$RUTA" != *".."* && "$RUTA" != *"\\"* ]] && [ -f "WEB-INF/archivos/$RUTA" ] && grep -q "<web-app" WEB-INF/web.xml
revisar "Un nombre con ../ se guarda con un nombre del sistema, dentro de WEB-INF/archivos ($RUTA)" $?
pedir ana POST /estudiante/anexo-guardar.jsp -F "anexo=@$T/propuesta.docx"; [[ "$DESTINO" == *"error=archivo-invalido"* ]]; revisar "Un anexo en Word: rechazado (va en PDF)" $?
pedir anon GET /WEB-INF/archivos/qa-p1.pdf; [ "$CODIGO" = 404 ]; revisar "Los archivos no se abren directo desde el navegador" $?
pedir anon GET /WEB-INF/web.xml; [ "$CODIGO" = 404 ]; revisar "Ni la configuración" $?

echo "== 8. Sesión (RNF6)"
rm -f "$T/nueva"; pedir nueva GET /index.jsp; ANTES=$(grep JSESSIONID "$T/nueva" | awk '{print $7}')
pedir nueva POST /acceso/validar.jsp --data-urlencode "correo=ana.qa@correo.uts.edu.co" --data-urlencode "clave=123456"
DESPUES=$(grep JSESSIONID "$T/nueva" | awk '{print $7}')
[ -n "$DESPUES" ] && [ "$ANTES" != "$DESPUES" ]; revisar "Al entrar cambia el identificador de la sesión" $?
grep -qi "^Set-Cookie: JSESSIONID=.*HttpOnly" "$T/encabezados.txt" || grep -q "#HttpOnly_" "$T/nueva"; revisar "La cookie de sesión es HttpOnly" $?
pedir nueva GET /panel/inicio.jsp; grep -qi "^Cache-Control: no-store" "$T/encabezados.txt"; revisar "Las páginas internas no se guardan en la caché (no-store)" $?
pedir nueva GET "/panel/inicio.jsp;jsessionid=$DESPUES"; [ "$CODIGO" != 200 ] || ! grep -q "Ana QA" "$T/cuerpo.html" || [ -n "$DESPUES" ]; revisar "La sesión no viaja en la dirección" $?
cp "$T/nueva" "$T/robada"
pedir nueva GET /acceso/salir.jsp; [[ "$DESTINO" == *"aviso=salida"* ]]; revisar "Salir cierra la sesión" $?
pedir robada GET /panel/inicio.jsp; [[ "$DESTINO" == *"aviso=sesion"* ]]; revisar "Después de salir, la cookie vieja ya no sirve" $?
grep -q "<session-timeout>30</session-timeout>" WEB-INF/web.xml; revisar "La sesión vence a los 30 minutos sin uso" $?

echo
echo "Resultado: $OK OK, $FALLA fallas"
[ "$FALLA" -eq 0 ]
