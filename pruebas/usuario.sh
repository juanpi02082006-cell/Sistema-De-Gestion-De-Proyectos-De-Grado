#!/usr/bin/env bash
# Pruebas de usuario (2026-10-14): corre pruebas/usuario.js, que usa el sistema desde Chrome como
# lo usaría la gente, desde la base recién creada: el comité crea el periodo, ocho estudiantes se
# registran y cada proyecto recorre sus fases (camino completo, propuesta no aprobada, idea
# propia con exoneración, prórroga con plazo vencido y Seminario). Para adelantar el tiempo usa
# bd\demo-adelantar-tiempo.bat, como en la demostración.
# Se corre con correr-pruebas.sh (respalda la base y la devuelve):
#   bash pruebas/correr-pruebas.sh <carpeta-respaldo> usuario
# Necesita Node, playwright-core (ruta en PLAYWRIGHT; por defecto la de este computador) y Chrome.
cd "$(dirname "$0")/.." || exit 1
export PLAYWRIGHT="${PLAYWRIGHT:-C:/Users/juanp/node_modules/playwright-core}"
node pruebas/usuario.js
