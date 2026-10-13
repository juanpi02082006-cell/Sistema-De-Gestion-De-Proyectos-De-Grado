#!/usr/bin/env bash
# Corre las pruebas sin arriesgar los datos del usuario: comprueba MySQL, respalda la base
# y WEB-INF/archivos (y verifica el respaldo), corre cada suite sobre la base recién
# importada y al final devuelve la base y los archivos. Si algo falla antes, se detiene.
# Uso: bash pruebas/correr-pruebas.sh <carpeta-respaldo> [suites...]   (por defecto, todas)
# La carpeta de respaldo va fuera del proyecto (por ejemplo, en la carpeta temporal).
set -u
PROYECTO=/c/xampp/tomcat/webapps/segundo-parcial
MYSQL=/c/xampp/mysql/bin/mysql.exe
DUMP=/c/xampp/mysql/bin/mysqldump.exe
RESPALDO="$1"; shift
SUITES="${*:-base sprints2-3 sprint4 sprint5 sprint5b sprint5c sprint5d}"
cd "$PROYECTO" || exit 1

/c/xampp/mysql/bin/mysqladmin.exe -u root ping > /dev/null 2>&1 || { echo "MySQL no responde: no se corre nada"; exit 1; }
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/segundo-parcial/ | grep -q 200 || { echo "Tomcat no responde: no se corre nada"; exit 1; }
rm -rf "$RESPALDO"; mkdir -p "$RESPALDO"
"$DUMP" -u root --default-character-set=utf8mb4 --databases sistemas_proyectos_grado > "$RESPALDO/base.sql" || { echo "Falló el respaldo: no se corre nada"; exit 1; }
grep -q "CREATE TABLE \`usuarios\`" "$RESPALDO/base.sql" || { echo "El respaldo está incompleto: no se corre nada"; exit 1; }
cp -r WEB-INF/archivos "$RESPALDO/archivos" || { echo "Falló el respaldo de los archivos"; exit 1; }
echo "Respaldo listo: $(grep -c 'INSERT INTO' "$RESPALDO/base.sql") inserciones, $(ls "$RESPALDO/archivos" | wc -l) archivos"

importar() { "$MYSQL" -u root < bd/sistemas_proyectos_grado.sql || { echo "Falló la importación"; return 1; }; }
for S in $SUITES; do
    importar || break
    echo "### $S"
    if [ "$S" = "base" ]; then
        "$MYSQL" -u root --default-character-set=utf8mb4 < pruebas/base-de-datos.sql 2>&1 | grep -i "falla\|pruebas OK"
    else
        bash "pruebas/$S.sh" 2>&1 | grep "FALLA\|Resultado"
    fi
done

"$MYSQL" -u root --default-character-set=utf8mb4 < "$RESPALDO/base.sql" && echo "Base devuelta"
find WEB-INF/archivos -type f -delete && cp -r "$RESPALDO/archivos/." WEB-INF/archivos/ && echo "Archivos devueltos"
rm -rf pruebas/tmp/*
