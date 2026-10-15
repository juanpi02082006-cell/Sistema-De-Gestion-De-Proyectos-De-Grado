@echo off
rem SOLO PARA LA DEMOSTRACION: adelanta el tiempo de un proyecto (ver demo-adelantar-tiempo.sql).
rem Uso: bd\demo-adelantar-tiempo.bat 65-2026-2/1
if "%~1"=="" (
    echo Uso: bd\demo-adelantar-tiempo.bat CODIGO-DEL-PROYECTO   ^(por ejemplo 65-2026-2/1^)
    exit /b 1
)
cd /d "%~dp0.."
"C:\xampp\mysql\bin\mysql.exe" -u root -D sistemas_proyectos_grado --default-character-set=utf8mb4 -e "SET @codigo = '%~1'; SOURCE bd/demo-adelantar-tiempo.sql;"