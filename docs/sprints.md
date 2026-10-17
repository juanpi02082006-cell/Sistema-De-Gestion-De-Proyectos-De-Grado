# Sprints del proyecto

Última actualización: 2026-10-13

Plan de trabajo y seguimiento de *Sistemas de Información Proyectos de Grado* (objetivo específico 2 de la presentación).

## Cómo se trabaja

- El proyecto se hace por partes, en sprints.
- Los requerimientos se asignan a un sprint **a medida que avanza el proyecto**; el equipo decide cuáles entran en cada uno.
- La columna **Sprint** de [requerimientos.md](requerimientos.md) dice en qué sprint quedó cada requerimiento, y la columna **Estado**, cómo va.
- Estados: **Pendiente**, **En progreso**, **Hecho**.
- Al cerrar un sprint se anota qué se logró, qué quedó pendiente (pasa al siguiente sprint) y las observaciones.
- Los sprints **no tienen duración fija**: cada uno dura lo que tome terminarlo. Sirven para mantener el proyecto ordenado.
- Fecha de entrega del parcial: dentro de un mes aproximadamente (finales de octubre de 2026, por confirmar).

## Resumen

| Sprint | Objetivo | Inicio | Cierre | Estado |
| --- | --- | --- | --- | --- |
| 1 | Preparar el entorno, levantar los requerimientos y diseñar el inicio de sesión. | 2026-09-22 | Por definir | En progreso |
| 2 | Crear la base de datos del proyecto, hacer funcionar el login y gestionar usuarios y roles. | 2026-09-30 | 2026-09-30 | Hecho (falta la revisión del equipo) |
| 3 | Incorporar la segunda entrevista: requerimientos, base de datos versión 2, login institucional y créditos del estudiante. | 2026-10-05 | 2026-10-05 | Hecho (falta la revisión del equipo) |
| 4 | Registro del estudiante, habilitación, periodos, calendario y sesiones del comité, modalidades, banco de ideas, pago de la fase 1 y diseño nuevo. | 2026-10-08 | 2026-10-10 | Hecho (falta la revisión del equipo) |
| 5 | Fases 2 y 3: propuesta (FDC-124) con versiones y la revisión del director. | 2026-10-10 | Por definir | En progreso (fases 0 a 5, fase final y lo transversal hechos; falta la revisión del equipo) |
| 6 | Fases 4, 5 y final: evaluación con las rejillas, FDC-125, plazos, prórrogas y sustentación. | Por definir | Por definir | Propuesto |
| 7 | Buscador, informes de estado, PQR, historial y avisos. | Por definir | Por definir | Propuesto |

## Sprint 1 — Preparación y requerimientos

- **Objetivo:** dejar listo el entorno de desarrollo, levantar los requerimientos y definir el estilo visual con el diseño del inicio de sesión.
- **Inicio:** 2026-09-22
- **Cierre:** por definir
- **Requerimientos:** RF1 (Login: el diseño está listo, falta la validación).

| Tarea | Estado | Notas |
| --- | --- | --- |
| Instalar Tomcat 11 en XAMPP, con JSTL 3.0 y el driver de MySQL | Hecho | Funciona desde el panel de XAMPP. |
| Transcribir los requerimientos de la entrevista | Hecho | Solo falta el puntaje de exoneración (RNF14). |
| Indicar cuáles requerimientos son no funcionales | Pendiente | Lo indica el equipo. |
| Definir la paleta de colores y el estilo visual | Hecho | Verde lima `#C1D72F` y negro; ver `css/estilo.css`. |
| Diseñar el inicio de sesión (`index.jsp`) | Hecho | Solo el diseño. |
| Revisar la base original (`sistemastg`) y definir en qué se diferencia la del proyecto | Hecho | Ver `docs/base-de-datos.md`. |

**Cierre del sprint** (se llena al terminar):

- Logrado:
- Pasa al siguiente sprint:
- Observaciones:

## Sprint 2 — Base de datos, login y usuarios

- **Objetivo:** crear la base de datos del proyecto, hacer que el inicio de sesión funcione de verdad y que el administrador gestione usuarios y roles. Es la base que necesitan todos los demás paneles.
- **Inicio:** 2026-09-30
- **Cierre:** 2026-09-30
- **Requerimientos:** RF1, RF7, RF8 y RNF22.

| Tarea | Estado | Notas |
| --- | --- | --- |
| Crear la base de datos del proyecto en MySQL (script SQL y datos de prueba) | Hecho | Punto 52. Script `bd/sistemas_proyectos_grado.sql`, importado en el MySQL de XAMPP el 2026-09-30. |
| Conectar la aplicación a la base de datos | Hecho | Conexión única en `WEB-INF/web.xml`; todas las consultas usan `<sql:query>` y `<sql:update>` de JSTL con parámetros. |
| Login funcional: validar correo y contraseña, y llevar a cada rol a su panel | Hecho | Punto 1. `index.jsp` + `acceso/validar.jsp`. Quien tiene varios roles elige con cuál entra (`acceso/elegir-rol.jsp`) y puede cambiarlo. |
| Panel del administrador: crear, ver, editar y eliminar usuarios | Hecho | RF7 y PPT. Búsqueda y filtro por rol; incluye nivel y carrera del estudiante. |
| Panel del administrador: CRUD de roles | Hecho | Punto 3. Los 5 roles base no se pueden eliminar. |
| Probar el sprint de punta a punta | Hecho | 50 pruebas automáticas, todas bien (ver el cierre). |

**Cierre del sprint:**

- **Logrado:** login con correo y contraseña; sesión protegida (sin sesión no se entra a ninguna página interna, y cada página revisa el rol); elección de rol para usuarios con varios roles; panel de inicio para todos los roles; administración de usuarios (crear, ver, buscar, filtrar, editar, desactivar y eliminar) y de roles (crear, ver, editar y eliminar).
- **Pruebas (2026-09-30):** 50 pruebas automáticas, todas bien. Cubren: login correcto e incorrecto, usuario inactivo, permisos por rol (el estudiante no entra a la administración), elección de rol, crear y editar con tildes, correo y documento repetidos, roles base protegidos, roles y usuarios con información asociada, eliminar y cerrar sesión. También se comprobó que el sistema resiste un nombre con código HTML (se muestra como texto) y una búsqueda con inyección SQL (se trata como texto).
- **Pasa al siguiente sprint:** nada de este sprint. "Recordarme" y "¿La olvidaste?" del login siguen siendo solo visuales hasta que se defina cómo funcionan.
- **Observaciones:** usuarios de prueba en `docs/base-de-datos.md` (contraseña `123456` desde el 2026-10-08).

## Sprint 3 — Segunda entrevista

- **Objetivo:** incorporar los requerimientos de la segunda entrevista (audios) y ajustar lo que ya estaba hecho.
- **Inicio:** 2026-10-05
- **Cierre:** 2026-10-05
- **Requerimientos:** RF1 (hecho) y la base de RF3, RF29, RF34, RF36, RF38 y RNF14.

| Tarea | Estado | Notas |
| --- | --- | --- |
| Registrar los 31 requerimientos de la segunda entrevista (A-01 a A-31) y relacionarlos con los de la primera | Hecho | `docs/requerimientos.md`. |
| Resolver con el equipo lo que chocaba entre entrevistas | Hecho | Coordinación hace de comité; correos `@uts.edu.co` y `@correo.uts.edu.co`; integrantes según carrera; el estudiante no ve al evaluador. |
| Base de datos versión 2 | Hecho | 18 tablas. La base ya asegura: correo institucional, créditos de 0 a 100, un proyecto vigente por estudiante, máximo 2 prórrogas, observación obligatoria, aprobación del comité, exoneración y su renuncia, fases 0 a 5 e historial de movimientos. |
| Login solo con correo institucional (RF1) | Hecho | Mensaje claro si el correo no es institucional; el correo se compara en minúsculas. |
| Formulario de usuarios: correo institucional y % de créditos del estudiante (RF29) | Hecho | |
| Probar de punta a punta | Hecho | 63 pruebas automáticas, todas bien (las 50 del Sprint 2 con los correos nuevos y 13 nuevas), más 15 pruebas de las reglas de la base. |

**Cierre del sprint:**

- **Logrado:** todo lo de la tabla.
- **Pasa a los siguientes sprints:** el resto de la segunda entrevista, repartido en la propuesta de abajo.
- **Observaciones:** los usuarios de prueba cambiaron a correos institucionales (ver `docs/base-de-datos.md`).

## Antes del Sprint 4 — Base de datos versión 3

- **Fecha:** 2026-10-06.
- **Qué se hizo:** la base quedó ajustada al reglamento y a las decisiones del equipo: 4 roles (el administrador es el comité; se quitó Coordinación), fases 1 a 5, registro del estudiante (plan de estudios y puntaje de Saber TyT), máximo de integrantes por modalidad, proyectos interdisciplinarios con codirectores, resultados del reglamento y nota, seguimientos del director, festivos y límite de pago. Detalle en [base-de-datos.md](base-de-datos.md).
- **Diagrama entidad-relación:** `bd/diagrama-entidad-relacion.png`.
- **Código:** solo cambiaron los textos sobre los roles (`admin/roles.jsp`, `admin/rol-eliminar.jsp` y `WEB-INF/jspf/mensajes.jspf`); los roles conservan su id.
- **Pruebas:** 26 de 26 pruebas de restricciones de la base y 63 de 63 pruebas de punta a punta de la aplicación.

## Antes del Sprint 4 — Base de datos versión 4

- **Fecha:** 2026-10-08.
- **Qué se hizo:** se comparó la lista de requerimientos de otro equipo (RF-01 a RF-100) y se tomó lo que no choca con las decisiones del equipo: tres requerimientos nuevos (RF23 rejilla del F-DC-124, RF33 habilitación del estudiante y RF43 versiones de los documentos) y detalles en RF3, RF6, RF7, RF12, RF14, RF18, RF24–RF26, RF32, RF36 y RNF12. Los RF se renumeraron (RF1–RF43; equivalencia en el Anexo G de [requerimientos.md](requerimientos.md), y la comparación completa en el Anexo I).
- **Base de datos:** versión 4, con 26 tablas: Metodología aprobada del estudiante, estado del periodo, versiones y entregables en `entregas`, evaluación en borrador, rejilla del F-DC-124 (12 criterios y 28 indicadores del formato), solicitudes de cambio de modalidad y tipo de acción en el historial. Detalle en [base-de-datos.md](base-de-datos.md).
- **Diagramas:** `bd/diagrama-entidad-relacion.png` y `bd/diagrama-drawio.txt` (para draw.io).
- **Usuarios de prueba:** la contraseña de todos pasa a `123456` (pedido del equipo).
- **Código:** no cambia; las páginas hechas solo usan `usuarios` y `usuario_roles`.
- **F-DC-124 versión 2.0 (2023):** la rejilla de evaluación sale del formato, y donde el formato no coincide con el reglamento (2021), manda el formato: concepto aprobado, aplazado o no aprobado; hasta 3 prórrogas (Anexo J de [requerimientos.md](requerimientos.md)).
- **F-DC-125 y F-DC-129:** el FDC-124 se aprueba en la fase 2 y el FDC-125 se entrega en la 4; el informe final se evalúa con la rejilla del F-DC-129 (17 criterios, 40 indicadores, con N/A). Seminario no usa el F-DC-124 (Anexo K de [requerimientos.md](requerimientos.md)).
- **Pruebas:** 67 de 67 pruebas de la base y 63 de 63 pruebas de punta a punta de la aplicación (con la contraseña nueva). Detalle en [base-de-datos.md](base-de-datos.md#pruebas-hechas).

## Sprint 4 — Registro, calendario y banco de ideas

- **Objetivo:** que el estudiante se registre solo, sepa si está habilitado y tome una idea del banco; que el comité maneje los periodos y apruebe las ideas.
- **Inicio:** 2026-10-08
- **Cierre:** 2026-10-10
- **Requerimientos:** RF3, RF4, RF7, RF10, RF24, RF25, RF29, RF33 y parte de RF32.

| Tarea | Estado | Notas |
| --- | --- | --- |
| Registro del estudiante (`registro.jsp`, `acceso/registrar.jsp`) | Hecho | RF24. Correo institucional, contraseña repetida, nivel, carrera, plan, créditos y Metodología. Queda con el rol Estudiante. |
| Habilitación (`estudiante/habilitacion.jsp`, `WEB-INF/jspf/habilitacion.jspf`) | Hecho | RF33. Planes anteriores: 75 % y Metodología. Planes nuevos: la matrícula de Seminario de Grado la confirma la coordinación. |
| Usuarios: filtros y datos académicos | Hecho | RF7. Filtros por texto (también carrera), rol, nivel, plan y estado; plan y Metodología en el formulario. |
| Periodos (`admin/periodos.jsp` y sus páginas) | Hecho | RF3. Crear, editar, activar, cerrar y eliminar; un solo periodo activo; fechas validadas. |
| Calendario (`panel/calendario.jsp`) | Hecho | RF3. Fechas del periodo activo, si el banco está abierto y las sesiones del comité. |
| Sesiones del comité (`admin/sesiones.jsp` y sus páginas) | Hecho | RF3, RF16. El comité agrega y quita las sesiones de cada periodo (fecha, hora y lugar). |
| Mi proyecto y pago de la fase 1 (`estudiante/proyecto.jsp`, `estudiante/pago-guardar.jsp`, `archivos/ver.jsp`) | Hecho | RF29, RF32. El estudiante sube el recibo en PDF (hasta 15 MB) dentro del plazo de pago; en los planes nuevos no aplica, salvo en Seminario. Los archivos quedan en `WEB-INF/archivos` y solo los ven el comité y la gente del proyecto. |
| Diseño parecido al sistema actual de la UTS | Hecho | Menú lateral con íconos, cabecera "Bienvenido" y tarjetas por fase (`WEB-INF/jspf/fases-proyecto.jspf`), en verde lima y negro; se adapta a celular. |
| Modalidades (`panel/modalidades.jsp`, `admin/modalidad-form.jsp`) | Hecho | RF4. Todos las ven; el administrador edita la descripción y el máximo de integrantes. |
| Banco de ideas (`ideas/`) | Hecho | RF10, RF25. Los docentes registran ideas, el estudiante formula su propuesta y el comité aprueba o rechaza con observación. El estudiante toma una idea de su nivel antes del cierre del banco y se crea su proyecto en la fase 1. |
| Inicio y menú por rol | Hecho | Accesos de cada rol; el estudiante ve su proyecto. |
| Fases del sistema actual de la UTS (0 a 5 y final) | Hecho | En la base y en la documentación (Anexo H). |
| Pruebas guardadas en `pruebas/` | Hecho | Base 72/72, Sprints 2 y 3 63/63, Sprint 4 127/127. |

**Cierre del sprint:**

- Logrado: todo lo de la tabla.
- Pasa al siguiente sprint: nada. Lo que se había dejado para el Sprint 5 (subir el pago y el calendario de sesiones del comité) se hizo en este.
- Observaciones:
  - `web.xml` ahora fija el idioma de las etiquetas `fmt` (es-CO). Sin eso, las fechas salían sin formato cuando el navegador no mandaba su idioma.
  - `web.xml` también activa `useOldAliasMetadataBehavior` en la conexión. Sin eso, JSTL perdía los alias de las columnas (`SELECT f.orden AS fase`).
  - `web.xml` declara UTF-8 también para los `.jspf`. Sin eso, las tildes del menú salían como "HabilitaciÃ³n".
  - `web.xml` le da `multipart-config` a la página que guarda el recibo: así JSTL/EL puede leer el archivo con `getPart`, sin Servlets.

## Sprint 5 — Pago, director y propuesta

- **Objetivo:** que el comité revise el pago y asigne el director y el evaluador, y que el proyecto avance por las fases 2 a 5: propuesta (FDC-124) e informe final (FDC-125), cada uno revisado por el director, evaluado con su rejilla y decidido por el comité.
- **Inicio:** 2026-10-10
- **Cierre:** por definir
- **Requerimientos:** hechos hasta ahora: RF9, RF11, RF14, RF18–RF23, RF30–RF32, RF37–RF39 y RF43, y parte de RF26. Lo demás está en la [propuesta](#propuesta-para-los-siguientes-sprints).

| Tarea | Estado | Notas |
| --- | --- | --- |
| Proyectos del comité (`admin/proyectos.jsp`, `admin/proyecto.jsp`) | Hecho | RF9. Lista con la fase, el estado del pago y el director; filtros "pagos por revisar" y "sin director". El inicio del comité cuenta los pagos por revisar. |
| Revisión del pago (`admin/pago-revisar.jsp`, `WEB-INF/jspf/estado-pago.jspf`) | Hecho | RF32, RF34. El comité aprueba o devuelve el último recibo, con observación (queda en `revisiones`, rol Comité). El estudiante ve el estado y la observación; si se devuelve, sube otro; si se aprueba, ya no. |
| Asignar director y evaluador (`admin/proyecto-asignar.jsp`) | Hecho | RF11, RF27. Docentes activos con el rol Director o Evaluador; nunca el mismo docente. El evaluador es opcional y no aparece en el historial. El estudiante no puede pedir director (decisión del equipo). |
| Paso a la fase 2 (`WEB-INF/jspf/avanzar-fase-2.jspf`) | Hecho | Con el pago aprobado (o no aplica) y el director asignado, el proyecto pasa a la fase 2, "En curso", con fecha de inicio. Confirmado (2026-10-14). |
| Fase 2: el estudiante sube el FDC-124 con sus versiones y lo envía al director (`estudiante/propuesta-guardar.jsp`, `estudiante/propuesta-enviar.jsp`, `WEB-INF/jspf/propuesta-versiones.jspf`) | Hecho | RF26, RF30, RF43. Word de hasta 15 MB; cada archivo es una versión nueva. Al enviarla, el proyecto pasa a la fase 3. Si el director la devuelve, hay que subir otra versión antes de reenviar. Seminario no sube el F-DC-124. Los Word se descargan con su nombre original. |
| Mis proyectos del director (`director/proyectos.jsp`, `director/proyecto.jsp`) | Hecho | RF18 (en parte), RF19. Los proyectos que dirige, las propuestas por revisar (también en su inicio), las versiones y la información de sus estudiantes. |
| Diseño de "Datos del proyecto" y "Estudiantes" (`WEB-INF/jspf/datos-proyecto.jspf`, `WEB-INF/jspf/integrantes.jspf`) | Hecho | Pedido del equipo: primero "se ve muy simple" y después "muy genérico, hazlo más sencillo, sin tantas tarjetas". Quedó sin cajas: la descripción como texto, los datos en dos columnas (etiqueta gris y valor en negrilla) y cada estudiante con sus iniciales y su nombre, y debajo sus datos con el mismo estilo (correo, celular, nivel, carrera, plan y créditos). Lo usan las páginas del estudiante, del director y del comité; el estudiante no ve los datos académicos de sus compañeros. |
| Pruebas (`pruebas/sprint5.sh`) | Hecho | 136/136. |
| Base de datos versión 5 | Hecho | Catálogo de carreras (nivel "Universitario"), avisos, exoneraciones, rol Codirector, tipos de PQR y festivos de 2027; 31 tablas. La base se reinició desde la fase 0, conservando usuarios, periodo e ideas. |
| Catálogo de carreras (`WEB-INF/jspf/selector-carrera.jspf`) | Hecho | RF24. El registro y la administración de usuarios usan la lista; el nivel sale de la carrera. |
| Avisos y alertas (`WEB-INF/jspf/avisar.jspf`, `alertas.jspf`, `panel/avisos.jsp`) | Hecho | RF5, RNF21. Campana en la cabecera; avisos de cada movimiento; alertas del límite de pago, la semana 12 y el plazo del director. |
| Historial y auditoría (`WEB-INF/jspf/historial-proyecto.jspf`, `admin/auditoria.jsp`) | Hecho | RNF12. Historial plegable en cada proyecto; auditoría con filtros. |
| Plazos en días hábiles (`WEB-INF/jspf/plazo-habil.jspf`) | Hecho | RF21, RNF19. El director tiene 5 días hábiles (confirmado) para revisar la propuesta; se ve en su página y en la del comité, con la marca de vencido. |
| Código del proyecto | Hecho | RF40. Al tomar la idea: 65 o 125, el periodo y un consecutivo (65-2026-2/1). |
| Codirectores (`admin/proyecto-asignar.jsp`, `director/propuesta-observar.jsp`) | Hecho | RF13. Hasta 2 en los interdisciplinarios; comentan y decide el director. |
| Cambio de modalidad (`estudiante/modalidad-solicitar.jsp`, `admin/modalidad-decidir.jsp`) | Hecho | RF12. En las fases 1 a 3, con motivo; el comité decide con observación. |
| Anexos de la propuesta (`estudiante/anexo-guardar.jsp`, `anexo-quitar.jsp`) | Hecho | RF26, RF30. PDF opcionales en la fase 2. |
| PQR (`panel/pqr.jsp`, `admin/pqrs.jsp`) | Hecho | RNF1. Botón en la cabecera; el comité responde y ve el reporte. |
| Exoneración por Saber TyT (`estudiante/exoneracion-solicitar.jsp`, `exoneracion-renunciar.jsp`, `admin/exoneracion-revisar.jsp`) | Hecho | RNF14. Puntaje y certificado, solo en la fase 4 con la propuesta aprobada (cambio del 2026-10-11); el comité verifica; renuncia sin vuelta atrás; si todos quedan exonerados, el proyecto termina con concepto Aprobado. |
| Seminario (`estudiante/inscripcion-guardar.jsp`, `admin/inscripcion-validar.jsp`, `director/nota-registrar.jsp`) | Hecho | RF17. Cada estudiante sube su recibo, el F-AM-04 y su documento de identidad; el comité valida la inscripción (con el docente del seminario como director) o la devuelve; el docente registra la nota final (3.0 o más: Finalizado; menos: Cancelado). |
| Semana 12 vencida (`WEB-INF/jspf/cierres.jspf`) | Hecho | RF30, RNF21. Sin el FDC-124 aprobado, el proyecto se cancela solo por extemporaneidad (solo planes anteriores, no Seminario); la idea vuelve al banco y se avisa a todos. |
| Pruebas de lo anterior (`pruebas/sprint5b.sh`) | Hecho | 153/153. Siguen pasando: base 95/95, Sprints 2 y 3 63/63, Sprint 4 127/127, Sprint 5 136/136. |
| Integrantes (`estudiante/integrante-agregar.jsp`, `estudiante/integrante-quitar.jsp`) | Hecho | RF13, RF35, RF36. Cualquier integrante agrega a un compañero por correo (habilitado, del mismo nivel, sin otro proyecto, sin pasarse del máximo) o lo quita, en las fases 1 y 2. El comité marca el proyecto como interdisciplinario (hasta 4). Al enviar la propuesta se revisa todo el grupo. |
| Pago por estudiante (`WEB-INF/jspf/estado-pago.jspf`) | Hecho | RF32. Cada estudiante sube su recibo y el comité revisa el de cada uno; el proyecto pasa a la fase 2 cuando todos están al día. |
| Fase 3: el director revisa, deja observaciones, pasa Turnitin, devuelve o envía al evaluador y al comité (`director/propuesta-revisar.jsp`) | Hecho | RF18, RF30, RF34. Devolver: vuelve a la fase 2. Aprobar: reporte de Turnitin en PDF y evaluador asignado; pasa a la fase 4. El comité tiene el filtro "sin evaluador". La firma es la aprobación en el sistema (confirmado el 2026-10-14). |
| Fase 4: el evaluador evalúa la propuesta con la rejilla del F-DC-124 (`evaluador/proyectos.jsp`, `evaluador/proyecto.jsp`, `evaluador/evaluacion-guardar.jsp`) | Hecho | RF21, RF22, RF23, RF27. Menú "Mis evaluaciones"; 3 días hábiles desde que el director la aprueba, con alerta al vencer; solo los criterios de la modalidad; borrador; para enviar, todos los indicadores, concepto y observación ("Aprobado" solo con todo en Sí). Puede devolverla al director (fase 3). El estudiante ve el concepto y las observaciones, nunca quién lo evaluó. |
| Decisión del comité con su acta (`admin/propuesta-decidir.jsp`) | Hecho | RF14, RF22, RF34, RF43. Aprobada: versión oficial y 180 días desde la fecha del acta. Aplazada: vuelve a la fase 2. No aprobada: se cancela y la idea vuelve al banco. Devuelta: al director (fase 3). Filtro "Propuestas por decidir" y contador en el inicio. |
| Seguimientos e informe final (`director/seguimiento-registrar.jsp`, `estudiante/informe-guardar.jsp`, `estudiante/informe-enviar.jsp`) | Hecho | RF20, RF31, RF43. El director registra seguimientos; el estudiante sube el FDC-125 por versiones y lo envía al director desde el día 90 hasta el 180, con al menos 2 seguimientos: pasa a la fase 5. Alertas del límite a 30, 10 y 5 días. |
| Pruebas de la fase 4 (`pruebas/sprint5c.sh`) | Hecho | 86/86. Siguen pasando: base 95/95, Sprints 2 y 3 63/63, Sprint 4 127/127, Sprint 5 136/136 y `sprint5b.sh` 153/153. |
| Fase 5: el director revisa el informe final (`director/informe-revisar.jsp`) | Hecho | RF14, RF18, RF21, RF31. 5 días hábiles; lo devuelve (fase 4) o lo aprueba con Turnitin y lo envía al evaluador y al comité. |
| Fase 5: el evaluador evalúa el informe con la rejilla del F-DC-129 (`WEB-INF/jspf/rejilla-formulario.jspf`, `evaluador/evaluacion-guardar.jsp`) | Hecho | RF21, RF22, RF23. 5 días hábiles; Sí, No o N/A; si lo aplaza, indica el plazo para las correcciones. La rejilla de la propuesta y la del informe usan el mismo fragmento. |
| Fase 5: decisión del comité sobre el informe (`admin/informe-decidir.jsp`) | Hecho | RF14, RF22. Aprobado: versión oficial y fase final. Aplazado o no aprobado: vuelve a la fase 4 para corrección (el aplazado, dentro del plazo del evaluador). Devuelto: al director. Cada acta queda ligada a su decisión (`actas.revision_id`). |
| Pruebas de la fase 5 (en `pruebas/sprint5c.sh`) | Hecho | `sprint5c.sh` 125/125 (fases 4 y 5); base 97/97; las demás siguen pasando. |
| Orden de las páginas del proyecto (estudiante, comité, director y evaluador) | Hecho | Pedido del equipo: más ordenado y fácil de usar, sin cambiar el diseño. Comité: arriba los requisitos y los pagos por revisar a la izquierda y la asignación pendiente a la derecha; abajo, plegados, los recibos y el cambio de director y evaluador; prórrogas y exoneraciones plegadas salvo que haya una por decidir. En todos los roles, la propuesta aprobada queda plegada. Evaluador: la observación de cada indicador va plegada. Estudiante: Arriba lo que hay que hacer (en la fase 1, requisitos y pago lado a lado); el pago solo mientras hay algo que hacer con él; "Datos del proyecto" e "Integrantes" lado a lado; cambio de modalidad (fases 1 a 3) y prórroga plegados; exoneración solo cuando aplica; sin secciones vacías repetidas ni tarjetas de un proyecto terminado. |
| Fase final: programar la sustentación y dejar el proyecto "Finalizado" (`WEB-INF/jspf/sustentacion.jspf`, `admin/sustentacion-programar.jsp`, `admin/proyecto-finalizar.jsp`) | Hecho | RF39, RF5, RF27, RF34. El comité registra la fecha, la hora y el lugar o enlace de la sustentación y la puede reprogramar (reglamento, art. 26, literal m; decisión del 2026-10-14); los estudiantes, el director, los codirectores y el evaluador la ven y reciben el aviso. Pasada la fecha, el comité registra la aprobación final con acta y observación: el proyecto queda "Finalizado". Filtro "Fase final" en la lista del comité y contador "Fase final" en su inicio (sustentaciones por programar y aprobaciones finales). La aprobación final lleva acta (confirmado el 2026-10-14). |
| Prórrogas del informe final (`estudiante/prorroga-solicitar.jsp`, `admin/prorroga-decidir.jsp`) | Hecho | RF38. Antes del vencimiento, con motivo y soporte en PDF; el comité la aprueba (+180 días, hasta 3) o la rechaza. Sin prórrogas en los planes nuevos. Filtro "Prórrogas por decidir". |
| Cancelación por el plazo del informe vencido (`WEB-INF/jspf/cierres.jspf`) | Hecho | RF38, RNF21. Fase 4, fecha límite pasada y sin prórroga pendiente: se cancela la modalidad y la idea vuelve al banco. |
| Pruebas de las prórrogas (en `pruebas/sprint5c.sh`) | Hecho | `sprint5c.sh` 147/147; base 102/102; las demás siguen pasando. |
| Pruebas de la fase final (`pruebas/sprint5d.sh`) | Hecho | 76/76; base 103/103; las demás siguen pasando (63, 127, 136, 156 y 149). |
| Roles del docente: "Docente director" y "Docente evaluador" en el menú (`WEB-INF/jspf/sesion.jspf`, `solo-director.jspf`, `solo-evaluador.jspf`, `cabecera.jspf`, `acceso/validar.jsp`, `bd/migracion-roles-docente.sql`) | Hecho | 2026-10-16, pedido del equipo. Siguen 4 roles; los de id 3 y 4 se llaman Docente director y Docente evaluador. El docente con los dos entra directo y en el menú le salen las dos opciones; al abrir una, el rol activo cambia solo. El inicio le muestra lo que tiene por revisar y por evaluar. Solo escoge rol quien tiene roles de grupos distintos (por ejemplo, comité y docente). |
| Buscador (`panel/buscar.jsp`) | Hecho | 2026-10-17. RF6, RNF3. "Buscar" en el menú de todos los roles; cada uno busca solo en lo suyo (comité, docente, estudiante), por palabra, fase, estado y periodo, y el comité además por modalidad y docente. Hasta 200 resultados; con 5.005 proyectos responde en menos de 2 s. |
| Informes del comité (`admin/informes.jsp`) | Hecho | 2026-10-17. RF15. Por periodo: resumen, por modalidad, por cantidad de estudiantes y listados de aprobados y no aprobados (con el motivo); se puede imprimir. |
| Pruebas del buscador y los informes (`pruebas/sprint7.sh`) | Hecho | 2026-10-17. 55/55, con la medición de RNF3. |
| Pruebas de QA (`pruebas/qa.sh`) | Hecho | 2026-10-14. 58/58: cada página de cada carpeta con cada rol (y sin sesión), datos de otros proyectos por id, cambio de rol que no se tiene, XSS guardado y reflejado, SQL, 144 combinaciones de parámetros basura, GET sobre acciones POST, archivos (tipos, vacío, 16 MB, nombres con rutas) y sesión (id nuevo al entrar, HttpOnly, sin caché, salir, 30 minutos). Encontró un error, ya corregido: un estudiante quitado del proyecto todavía abría sus archivos (`archivos/ver.jsp`). |
| Pruebas de la interfaz (`pruebas/interfaz.sh`) | Hecho | 2026-10-14. 498/498: todas las páginas de cada rol, con un proyecto en cada fase, en Chrome, Edge y Firefox (desde el 2026-10-17, en Chrome y Brave: RNF11), en computador (1366 px) y celular (390 px): sin errores del servidor ni de JavaScript, con los estilos y sin desplazamiento horizontal; el menú del celular abre; subir la propuesta toma 5 clics (RNF17). Encontró un error, ya corregido: en el celular, el campo del anexo (fase 2) se salía de la tarjeta en Chrome y Edge. |
| Pruebas de usuario (`pruebas/usuario.sh`) | Hecho | 2026-10-14. 202/202, en Chrome y desde la pantalla: el comité crea y activa el periodo; 8 estudiantes se registran (2 desde el celular) y recorren el camino completo hasta "Finalizado", la propuesta no aprobada, la idea propia con cambio de modalidad y exoneración, la prórroga con el plazo vencido, el Seminario, la PQR y los avisos. Encontró un error, ya corregido: la primera página después de un vencimiento todavía mostraba el proyecto activo, porque el cierre automático corría en la cabecera, después de las consultas (ahora corre en `sesion.jspf` al abrir cada página, antes de las consultas; las acciones POST siguen revisando sus propios plazos). |

## Propuesta para los siguientes sprints

Orden pensado para que cada sprint use lo que dejó listo el anterior. El equipo puede cambiarlo. Desde el 2026-10-06 incluye los requerimientos del reglamento (RF13, RF15–RF17, RF20, RF22, RF32, RF41, RF42), y desde el 2026-10-08 los que se tomaron de la lista de otro equipo (RF23, RF33, RF43). La base de datos ya está lista para todos (versión 4, ver arriba). Los no funcionales (rendimiento, seguridad, usabilidad…) aplican en todos los sprints.

| Sprint | Contenido | Requerimientos | Depende de |
| --- | --- | --- | --- |
| 4 | Registro del estudiante (con carrera, nivel, plan de estudios, créditos y Metodología); el administrador registra a los docentes, filtra usuarios y actualiza los datos académicos de los estudiantes; habilitación del estudiante (qué le falta y qué modalidades puede tomar); calendario configurable por periodo (crear, activar y cerrar) y sesiones del comité; panel de modalidades; banco de ideas (los docentes las registran, el estudiante formula la suya, el comité aprueba; elegir según el nivel y antes del cierre) | RF3, RF4, RF7, RF10, RF24, RF25, RF33 | — |
| 5 | Asignar director, evaluador y codirectores; integrantes con sus límites; fase 2 (propuesta I: el estudiante diligencia el FDC-124 y lo envía al director); fase 3 (propuesta II: el director la revisa, la pasa por Turnitin, puede devolverla a la 2 y la envía al evaluador y al comité); subir la propuesta y el FDC-124 con firma y Turnitin, con sus versiones; observaciones del director antes de su aval; evaluación con la rejilla del F-DC-124 (borrador y envío); aprobación director → evaluador → comité con observación obligatoria y sus resultados; actas del comité; plazos; solicitud de cambio de modalidad y su registro; propuesta de los planes nuevos y modalidad Seminario; el estudiante no ve al evaluador | RF9, RF11–RF14, RF16–RF19, RF21–RF23, RF26–RF30, RF32, RF34–RF36, RF41, RF43 | Sprint 4. Es grande: el equipo puede partirlo |
| 6 | Fase 4 (informe I: el evaluador puede devolver la propuesta a la 3; con el FDC-124 aprobado empieza el FDC-125 y el estudiante lo envía al director), fase 5 (informe II: el director lo envía al evaluador y al comité) y fase final (programar la sustentación); contador de días de la fase 4 (parte de RF2); FDC-125 entre 90 y 180 días con Turnitin y FDC-129, con sus versiones y los entregables de la modalidad; seguimientos del director; evaluación del informe final; prórrogas; cancelación; desarrollo de los planes nuevos; proyecto "finalizado" después de la fase final; exoneración por Saber TyT | RF20, RF22, RF26, RF31, RF37–RF39, RF42, RF43, RNF14 | Sprint 5 |
| 7 | Buscador único (cada rol en lo suyo); informes de estado y estadísticos; PQR con botón arriba y su reporte; historial y auditoría con filtros; código del proyecto (65 tecnología, 125 ingeniería); avisos dentro del sistema (sin correo) | RF2, RF5, RF6, RF15, RF40, RNF1, RNF12 | Sprints 5 y 6 |

## Plantilla para un sprint nuevo

Copiar este bloque, cambiar el número y llenarlo. Agregar también una fila en el [resumen](#resumen).

```markdown
## Sprint N — Nombre corto

- **Objetivo:**
- **Inicio:**
- **Cierre:**
- **Requerimientos:** (IDs RF y RNF de requerimientos.md)

| Tarea | Estado | Notas |
| --- | --- | --- |
|  | Pendiente |  |

**Cierre del sprint** (se llena al terminar):

- Logrado:
- Pasa al siguiente sprint:
- Observaciones:
```
