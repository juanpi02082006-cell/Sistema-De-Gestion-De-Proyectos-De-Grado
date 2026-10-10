#!/usr/bin/env bash
# Pruebas de punta a punta de los Sprints 2 y 3 (login, usuarios, roles, correo institucional y créditos).
# Se corren sobre la base recién importada (usuarios de prueba con la clave 123456).
B="http://localhost:8080/segundo-parcial"
T="$(dirname "$0")/tmp/sprints2-3"; rm -rf "$T"; mkdir -p "$T"
OK=0; FALLA=0
MYSQL="/c/xampp/mysql/bin/mysql.exe -u root -N -B -D sistemas_proyectos_grado"

revisar() { # nombre, condición (0 = bien)
    if [ "$2" -eq 0 ]; then echo "  OK    $1"; OK=$((OK+1)); else echo "  FALLA $1"; FALLA=$((FALLA+1)); fi
}
pedir() { # cookie, método, ruta, datos... -> deja código y Location en variables
    local jar="$T/$1"; local metodo="$2"; local ruta="$3"; shift 3
    if [ "$metodo" = "POST" ]; then
        RES=$(curl -s -o "$T/cuerpo.html" -w "%{http_code} %{redirect_url}" -b "$jar" -c "$jar" -X POST "$@" "$B$ruta")
    else
        RES=$(curl -s -o "$T/cuerpo.html" -w "%{http_code} %{redirect_url}" -b "$jar" -c "$jar" "$B$ruta")
    fi
    CODIGO="${RES%% *}"; DESTINO="${RES#* }"
}
contiene() { grep -q "$1" "$T/cuerpo.html"; }

echo "== Acceso"
pedir anon GET /panel/inicio.jsp
[[ "$CODIGO" = 302 && "$DESTINO" == *"index.jsp?aviso=sesion"* ]]; revisar "Sin sesión, el panel manda al login" $?
pedir anon GET "/index.jsp?aviso=sesion"; contiene "Inicia sesión para continuar"; revisar "El login muestra el aviso de sesión" $?
pedir anon POST /acceso/validar.jsp --data-urlencode "correo=admin.prueba@uts.edu.co" --data-urlencode "clave=mala"
[[ "$CODIGO" = 302 && "$DESTINO" == *"error=credenciales"* ]]; revisar "Contraseña incorrecta: vuelve con error" $?
pedir anon GET /acceso/validar.jsp
[[ "$CODIGO" = 302 && "$DESTINO" == *"index.jsp" ]]; revisar "validar.jsp por GET: vuelve al login" $?

echo "== Administrador"
pedir admin POST /acceso/validar.jsp --data-urlencode "correo=admin.prueba@uts.edu.co" --data-urlencode "clave=123456"
[[ "$CODIGO" = 302 && "$DESTINO" == *"/panel/inicio.jsp" ]]; revisar "Login del admin: entra al panel" $?
pedir admin GET /panel/inicio.jsp; contiene "Hola, Administrador de Prueba"; revisar "El panel saluda al admin" $?
contiene "admin/usuarios.jsp"; revisar "El admin ve el menú Usuarios" $?
pedir admin GET /index.jsp
[[ "$CODIGO" = 302 && "$DESTINO" == *"/panel/inicio.jsp" ]]; revisar "Con sesión abierta, el login manda al panel" $?
pedir admin GET /admin/usuarios.jsp; contiene "5 usuarios"; revisar "Lista: 5 usuarios de prueba" $?
contiene "C.C 1000000001"; revisar "Lista: el documento sale con su espacio (C.C 1000000001)" $?
pedir admin GET "/admin/usuarios.jsp?rol=5"; contiene "1 usuario<"; revisar "Filtro por rol Estudiante: 1 usuario" $?
pedir admin GET "/admin/usuarios.jsp?q=docente"; contiene "docente.prueba@uts.edu.co"; revisar "Búsqueda por texto" $?

echo "== Crear, editar y validar usuarios"
# Texto con tildes ya codificado en UTF-8, como lo envía un navegador:
#   nombre  = "José Pérez Ñáñez"        carrera = "Ingeniería de Sistemas"
NOMBRE_UTF8="Jos%C3%A9%20P%C3%A9rez%20%C3%91%C3%A1%C3%B1ez"
CARRERA_UTF8="Ingenier%C3%ADa%20de%20Sistemas"
pedir admin POST /admin/usuario-guardar.jsp --data "nombre=$NOMBRE_UTF8" --data-urlencode "tipo_documento=2" \
    --data-urlencode "numero_documento=2000000001" --data-urlencode "correo=jose.perez@correo.uts.edu.co" --data-urlencode "clave=Clave123*" \
    --data-urlencode "celular=3001234567" --data-urlencode "roles=5" --data-urlencode "nivel=2" --data "carrera=$CARRERA_UTF8"
[[ "$CODIGO" = 302 && "$DESTINO" == *"ok=usuario-creado"* ]]; revisar "Crear estudiante con tildes y eñe" $?
# Se compara en hexadecimal para no depender de la codificación de la consola
FILA=$($MYSQL -e "SELECT CONCAT(HEX(nombre), '|', HEX(carrera), '|', nivel_id) FROM usuarios WHERE correo='jose.perez@correo.uts.edu.co'")
[ "$FILA" = "4A6F73C3A92050C3A972657A20C391C3A1C3B1657A|496E67656E696572C3AD612064652053697374656D6173|2" ]; revisar "En la base quedó bien escrito (tildes, carrera, nivel)" $?
ID=$($MYSQL -e "SELECT id FROM usuarios WHERE correo='jose.perez@correo.uts.edu.co'")

pedir admin POST /admin/usuario-guardar.jsp --data-urlencode "nombre=Otro" --data-urlencode "tipo_documento=2" \
    --data-urlencode "numero_documento=2000000099" --data-urlencode "correo=jose.perez@correo.uts.edu.co" --data-urlencode "clave=x" --data-urlencode "roles=5"
[ "$CODIGO" = 200 ] && contiene "Ya existe un usuario con ese correo"; revisar "Correo repetido: muestra el error" $?
contiene 'value="Otro"'; revisar "Correo repetido: conserva lo escrito" $?
pedir admin POST /admin/usuario-guardar.jsp --data-urlencode "nombre=Otro" --data-urlencode "tipo_documento=2" \
    --data-urlencode "numero_documento=2000000001" --data-urlencode "correo=otro@correo.uts.edu.co" --data-urlencode "clave=x" --data-urlencode "roles=5"
contiene "Ya existe un usuario con ese número de documento"; revisar "Documento repetido: muestra el error" $?
pedir admin POST /admin/usuario-guardar.jsp --data-urlencode "nombre=Sin rol" --data-urlencode "tipo_documento=2" \
    --data-urlencode "numero_documento=2000000098" --data-urlencode "correo=sinrol@uts.edu.co" --data-urlencode "clave=x"
contiene "Escoge al menos un rol"; revisar "Sin roles: muestra el error" $?
pedir admin POST /admin/usuario-guardar.jsp --data-urlencode "nombre=Sin clave" --data-urlencode "tipo_documento=2" \
    --data-urlencode "numero_documento=2000000097" --data-urlencode "correo=sinclave@uts.edu.co" --data-urlencode "roles=5"
contiene "Escribe una contraseña"; revisar "Usuario nuevo sin contraseña: muestra el error" $?

pedir admin GET "/admin/usuario-form.jsp?id=$ID"; contiene 'value="jose.perez@correo.uts.edu.co"' && contiene '2000000001'; revisar "Editar: el formulario trae los datos" $?
grep -q "$(printf 'Jos\xc3\xa9 P\xc3\xa9rez')" "$T/cuerpo.html"; revisar "Editar: el nombre con tildes se ve bien en el formulario" $?
HASH_ANTES=$($MYSQL -e "SELECT contrasena FROM usuarios WHERE id=$ID")
pedir admin POST /admin/usuario-guardar.jsp --data-urlencode "id=$ID" --data "nombre=Jos%C3%A9%20Editado" --data-urlencode "tipo_documento=2" \
    --data-urlencode "numero_documento=2000000001" --data-urlencode "correo=jose.perez@correo.uts.edu.co" --data-urlencode "roles=5" --data-urlencode "roles=3" \
    --data-urlencode "nivel=2" --data "carrera=$CARRERA_UTF8" --data-urlencode "activo=on"
[[ "$CODIGO" = 302 && "$DESTINO" == *"ok=usuario-actualizado"* ]]; revisar "Editar: guarda los cambios" $?
[ "$($MYSQL -e "SELECT contrasena FROM usuarios WHERE id=$ID")" = "$HASH_ANTES" ]; revisar "Editar sin contraseña: conserva la anterior" $?
[ "$($MYSQL -e "SELECT GROUP_CONCAT(rol_id ORDER BY rol_id) FROM usuario_roles WHERE usuario_id=$ID")" = "3,5" ]; revisar "Editar: roles actualizados (Director y Estudiante)" $?

pedir admin POST /admin/usuario-guardar.jsp --data-urlencode "id=1" --data-urlencode "nombre=Administrador de Prueba" --data-urlencode "tipo_documento=2" \
    --data-urlencode "numero_documento=1000000001" --data-urlencode "correo=admin.prueba@uts.edu.co" --data-urlencode "roles=3" --data-urlencode "activo=on"
contiene "No puedes quitarte el rol de Administrador"; revisar "El admin no puede quitarse su propio rol" $?

echo "== Estudiante y permisos"
pedir est POST /acceso/validar.jsp --data-urlencode "correo=estudiante.prueba@correo.uts.edu.co" --data-urlencode "clave=123456"
[[ "$DESTINO" == *"/panel/inicio.jsp" ]]; revisar "Login del estudiante" $?
pedir est GET /admin/usuarios.jsp
[[ "$CODIGO" = 302 && "$DESTINO" == *"error=denegado"* ]]; revisar "El estudiante no puede entrar a Usuarios" $?
pedir est GET /admin/roles.jsp
[[ "$CODIGO" = 302 && "$DESTINO" == *"error=denegado"* ]]; revisar "El estudiante no puede entrar a Roles" $?
pedir est POST /admin/usuario-eliminar.jsp --data-urlencode "id=$ID"
[[ "$DESTINO" == *"error=denegado"* ]]; revisar "El estudiante no puede eliminar usuarios" $?
pedir est GET /panel/inicio.jsp; ! contiene "admin/usuarios.jsp"; revisar "El estudiante no ve el menú de administración" $?

echo "== Usuario con varios roles"
pedir doc POST /acceso/validar.jsp --data-urlencode "correo=docente.prueba@uts.edu.co" --data-urlencode "clave=123456"
[[ "$DESTINO" == *"/acceso/elegir-rol.jsp" ]]; revisar "Docente con 2 roles: va a elegir rol" $?
pedir doc GET /acceso/elegir-rol.jsp; contiene ">Director<" && contiene ">Evaluador<"; revisar "Muestra Director y Evaluador" $?
pedir doc GET /panel/inicio.jsp
[[ "$CODIGO" = 302 ]]; revisar "Sin elegir rol no entra al panel" $?
pedir doc GET "/acceso/elegir-rol.jsp?rol=1"
[ "$CODIGO" = 200 ]; revisar "No puede escoger un rol que no tiene (Administrador)" $?
pedir doc GET "/acceso/elegir-rol.jsp?rol=abc"
[ "$CODIGO" = 200 ]; revisar "Un valor raro en ?rol no rompe la página" $?
pedir doc GET "/acceso/elegir-rol.jsp?rol=4"
[[ "$DESTINO" == *"/panel/inicio.jsp" ]]; revisar "Escoge Evaluador y entra" $?
pedir doc GET /panel/inicio.jsp; contiene "<strong>Evaluador</strong>" && contiene "Cambiar rol"; revisar "Panel como Evaluador, con opción de cambiar rol" $?

echo "== Roles"
pedir admin POST /admin/rol-guardar.jsp --data-urlencode "nombre=Rol de prueba" --data-urlencode "descripcion=Temporal"
[[ "$DESTINO" == *"ok=rol-creado"* ]]; revisar "Crear rol" $?
pedir admin POST /admin/rol-guardar.jsp --data-urlencode "nombre=Rol de prueba"
contiene "Ya existe un rol con ese nombre"; revisar "Rol repetido: muestra el error" $?
IDROL=$($MYSQL -e "SELECT id FROM roles WHERE nombre='Rol de prueba'")
pedir admin POST /admin/rol-guardar.jsp --data-urlencode "id=$IDROL" --data-urlencode "nombre=Rol de prueba 2" --data-urlencode "descripcion=Editado"
[[ "$DESTINO" == *"ok=rol-actualizado"* ]]; revisar "Editar rol" $?
pedir admin POST /admin/rol-eliminar.jsp --data-urlencode "id=1"
[[ "$DESTINO" == *"error=rol-base"* ]]; revisar "No se puede eliminar un rol base" $?
$MYSQL -e "INSERT INTO usuario_roles VALUES ($ID, $IDROL)"
pedir admin POST /admin/rol-eliminar.jsp --data-urlencode "id=$IDROL"
[[ "$DESTINO" == *"error=rol-con-usuarios"* ]]; revisar "No se puede eliminar un rol con usuarios" $?
$MYSQL -e "DELETE FROM usuario_roles WHERE rol_id=$IDROL"
pedir admin POST /admin/rol-eliminar.jsp --data-urlencode "id=$IDROL"
[[ "$DESTINO" == *"ok=rol-eliminado"* ]]; revisar "Eliminar rol sin usuarios" $?

echo "== Eliminar usuarios"
pedir admin POST /admin/usuario-eliminar.jsp --data-urlencode "id=1"
[[ "$DESTINO" == *"error=eliminar-propio"* ]]; revisar "El admin no puede eliminarse a sí mismo" $?
$MYSQL -e "INSERT INTO ideas (titulo, nivel_id, propuesta_por) VALUES ('Idea temporal', 1, $ID)"
pedir admin POST /admin/usuario-eliminar.jsp --data-urlencode "id=$ID"
[[ "$DESTINO" == *"error=usuario-con-registros"* ]]; revisar "Usuario con información asociada: no se elimina" $?
$MYSQL -e "DELETE FROM ideas WHERE titulo='Idea temporal'"
pedir admin POST /admin/usuario-eliminar.jsp --data-urlencode "id=$ID"
[[ "$DESTINO" == *"ok=usuario-eliminado"* ]]; revisar "Eliminar usuario" $?
[ "$($MYSQL -e "SELECT COUNT(*) FROM usuario_roles WHERE usuario_id=$ID")" = "0" ]; revisar "Sus roles también se borraron" $?

echo "== Usuario inactivo y salida"
$MYSQL -e "UPDATE usuarios SET activo=0 WHERE id=4"
pedir eva POST /acceso/validar.jsp --data-urlencode "correo=evaluador.prueba@uts.edu.co" --data-urlencode "clave=123456"
[[ "$DESTINO" == *"error=credenciales"* ]]; revisar "Usuario inactivo no puede entrar" $?
$MYSQL -e "UPDATE usuarios SET activo=1 WHERE id=4"
pedir admin GET /acceso/salir.jsp
[[ "$DESTINO" == *"aviso=salida"* ]]; revisar "Salir cierra la sesión" $?
pedir admin GET /panel/inicio.jsp
[[ "$CODIGO" = 302 && "$DESTINO" == *"aviso=sesion"* ]]; revisar "Después de salir, el panel pide login" $?


echo "== Segunda entrevista: correo institucional (A-10) y créditos (A-07)"
pedir nuevo POST /acceso/validar.jsp --data-urlencode "correo=alguien@gmail.com" --data-urlencode "clave=123456"
[[ "$CODIGO" = 302 && "$DESTINO" == *"error=dominio"* ]]; revisar "Login con Gmail: rechazado por no ser institucional" $?
pedir nuevo GET "/index.jsp?error=dominio"; contiene "correo institucional"; revisar "El login explica que debe ser correo institucional" $?
pedir nuevo POST /acceso/validar.jsp --data-urlencode "correo=alguien@fakeuts.edu.co" --data-urlencode "clave=123456"
[[ "$DESTINO" == *"error=dominio"* ]]; revisar "Dominio parecido (@fakeuts.edu.co): rechazado" $?
pedir may POST /acceso/validar.jsp --data-urlencode "correo=ADMIN.PRUEBA@UTS.EDU.CO" --data-urlencode "clave=123456"
[[ "$DESTINO" == *"/panel/inicio.jsp" ]]; revisar "Login con el correo en mayúsculas: entra" $?

pedir admin2 POST /acceso/validar.jsp --data-urlencode "correo=admin.prueba@uts.edu.co" --data-urlencode "clave=123456"
pedir admin2 POST /admin/usuario-guardar.jsp --data-urlencode "nombre=Externo" --data-urlencode "tipo_documento=2" \
    --data-urlencode "numero_documento=4000000001" --data-urlencode "correo=externo@gmail.com" --data-urlencode "clave=x" --data-urlencode "roles=5"
contiene "El correo debe ser institucional"; revisar "Crear usuario con Gmail: muestra el error" $?
for MALO in 150 abc 80.5 -3; do
    pedir admin2 POST /admin/usuario-guardar.jsp --data-urlencode "nombre=Est" --data-urlencode "tipo_documento=2" \
        --data-urlencode "numero_documento=4000000002" --data-urlencode "correo=est.creditos@correo.uts.edu.co" --data-urlencode "clave=x" \
        --data-urlencode "roles=5" --data-urlencode "porcentaje_creditos=$MALO"
    contiene "El porcentaje de créditos debe ser"; revisar "Créditos '$MALO': muestra el error" $?
done
pedir admin2 POST /admin/usuario-guardar.jsp --data-urlencode "nombre=Est Creditos" --data-urlencode "tipo_documento=2" \
    --data-urlencode "numero_documento=4000000002" --data-urlencode "correo=Est.Creditos@Correo.UTS.edu.co" --data-urlencode "clave=x" \
    --data-urlencode "roles=5" --data-urlencode "nivel=1" --data-urlencode "porcentaje_creditos=85"
[[ "$DESTINO" == *"ok=usuario-creado"* ]]; revisar "Estudiante con 85 % de créditos: se crea" $?
[ "$($MYSQL -e "SELECT CONCAT(correo, '|', porcentaje_creditos) FROM usuarios WHERE numero_documento='4000000002'")" = "est.creditos@correo.uts.edu.co|85" ]; revisar "Se guardó el correo en minúsculas y los créditos (85)" $?
IDC=$($MYSQL -e "SELECT id FROM usuarios WHERE numero_documento='4000000002'")
pedir admin2 GET "/admin/usuario-form.jsp?id=$IDC"; contiene 'id="porcentaje_creditos"' && contiene 'value="85"'; revisar "Editar: el formulario muestra los créditos" $?
pedir admin2 POST /admin/usuario-guardar.jsp --data-urlencode "id=$IDC" --data-urlencode "nombre=Est Creditos" --data-urlencode "tipo_documento=2" \
    --data-urlencode "numero_documento=4000000002" --data-urlencode "correo=est.creditos@correo.uts.edu.co" \
    --data-urlencode "roles=3" --data-urlencode "porcentaje_creditos=85" --data-urlencode "activo=on"
[ "$($MYSQL -e "SELECT IFNULL(porcentaje_creditos, 'NULL') FROM usuarios WHERE id=$IDC")" = "NULL" ]; revisar "Si deja de ser estudiante, se borran sus créditos" $?
pedir admin2 POST /admin/usuario-eliminar.jsp --data-urlencode "id=$IDC"

echo
echo "Resultado: $OK bien, $FALLA con falla"
