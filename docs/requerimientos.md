# Requerimientos del proyecto

Última actualización: 2026-10-13

La lista oficial está en [Requerimientos](#requerimientos): **RF1 a RF43** (funcionales) y **RNF1 a RNF26** (no funcionales), cada uno con su rol y su origen. Fuentes:

- **Reglamento de Trabajo de Grado** de la UTS (Acuerdo 01-026 del Consejo Directivo, 27 de julio de 2021), en `SEGUNDO CORTE\reglamento de trabajo de grado.pdf`. Es la fuente oficial: **donde no coincide con la entrevista, manda el reglamento**; y donde el reglamento (2021) no coincide con el formato F-DC-124 (2023), **manda el formato, que es más nuevo** ([Anexo C](#anexo-c-reglamento-de-trabajo-de-grado)).
- **Acuerdo 01-009** de la UTS: estímulos por puntaje en Saber TyT ([Anexo D](#anexo-d-estímulos-por-saber-tyt)).
- **Lista de requisitos no funcionales** del equipo, con perfil y fases ([Anexo F](#anexo-f-lista-de-requisitos-no-funcionales)).
- **Fases del proyecto**, definidas por el equipo ([Anexo H](#anexo-h-fases-del-proyecto)).
- **Lista de requerimientos de otro equipo** (RF-01 a RF-100), entregada el 2026-10-08. Se tomó lo que no choca con las decisiones del equipo ([Anexo I](#anexo-i-lista-de-requerimientos-de-otro-equipo)).
- **Formato F-DC-124** versión 2.0 (septiembre de 2023), *Propuesta de trabajo de grado: Investigación, Desarrollo Tecnológico, Monografía y Emprendimiento*, entregado el 2026-10-08 (carpeta "DOCUMENTOS DE GRADO" del equipo). Trae la rejilla de evaluación de la propuesta ([Anexo J](#anexo-j-formato-f-dc-124-y-su-rejilla)).
- **Formatos F-DC-125** versión 2 (*Informe final de trabajo de grado*, de todas las modalidades del sistema, incluido Seminario) y **F-DC-129** versión 2 (*Rejilla de evaluación del informe final*), entregados el 2026-10-08, con un texto del equipo sobre en qué momento va cada formato ([Anexo K](#anexo-k-formatos-f-dc-125-y-f-dc-129)).
- **Carreras de la UTS** con su nivel, código SNIES y campus, entregadas el 2026-10-10 ([Anexo L](#anexo-l-carreras-de-la-uts)).
- Presentación *Parcial Java Sistema de Informacion Proyecto Segundo Corte.pptx* (Programación en Java, segundo corte).
- Notas de la entrevista ([Anexo A](#anexo-a-notas-de-la-entrevista)): los puntos 1 a 25 los escribió un compañero del equipo; del 26 en adelante, el equipo durante la sesión con el profesor.
- Audios de esa misma sesión con el profesor ([Anexo B](#anexo-b-audios-de-la-entrevista)).

Este documento solo recoge lo que dicen las fuentes y las decisiones del equipo, sin supuestos.

## Contexto y objetivo

- Nombre del proyecto: Sistemas de Información Proyectos de Grado
- Objetivo (de la presentación): diseño e implementación de un sistema para gestión y seguimiento de los trabajos de grado de la UTS.
- Resultado esperado (del equipo): que todo el sistema funcione. El tiempo para desarrollarlo es corto.

### Objetivos específicos (de la presentación)

1. Levantar requerimientos funcionales y no funcionales.
2. Diseñar las historias de usuarios y su plan de trabajo.
3. Diseñar e implementar un módulo para la gestión de los trabajos de grado, desde el anteproyecto a la entrega final del documento de grado.
4. Desarrollar un sistema web que solucione el almacenamiento, organización y búsqueda de información de los estudiantes y sus trabajos de grado.
5. Realizar pruebas del software desarrollado.

Entrega (de la presentación): entregar y sustentar el código.

## Alcance

- Incluye (del equipo): el sistema de información de proyectos de grado, con los requerimientos de la entrevista y del reglamento, para todas las modalidades del reglamento excepto Práctica: Proyecto de investigación, Desarrollo tecnológico, Monografía, Seminario y Emprendimiento.
- Incluye los dos regímenes del reglamento: los **planes anteriores** al decreto 1330 de 2019 (180 días y prórrogas) y los **planes nuevos** (Seminario de Grado I a IV, sin prórrogas).
- No incluye: la modalidad Práctica, ni el nivel Técnico Profesional, porque su única modalidad es Práctica (reglamento, art. 8).

## Usuarios y roles

Roles de la presentación, con lo que dice cada diapositiva, transcrito sin interpretar:

| Rol | Qué dice la presentación |
| --- | --- |
| Administrador ("crea usuarios") | Registrar usuarios tales como docentes, coordinación y alumnos. Editar, ver y eliminar los datos de los roles cuando sea necesario. |
| Coordinación | Crea la idea de anteproyecto (CRUD). Agregar un director a un anteproyecto aprobado. Ingresa el código del estudiante o el nombre para ver los datos del proyecto o anteproyecto. Informe del estado del proyecto en alumnos, en director y en evaluador. Consultar calendario académico. Consultar formatos de grado. |
| Director | CRUD para calificar los anteproyectos subidos por el alumno. Ver en el CRUD la información del alumno. Aprobar anteproyecto para el evaluador. Consultar calendario académico. Consultar formatos de grado. |
| Evaluador | CRUD de anteproyectos aprobados por el director. Aprobar anteproyectos para los alumnos y coordinación. Consultar calendario académico. Consultar formatos de grado. |
| Estudiante | Seleccionar idea de proyecto. CRUD para subir el anteproyecto; en el CRUD debe aparecer la información del docente director y evaluador. Informe para ver la calificación de anteproyectos. Consultar calendario académico. Consultar formatos de grado. |

Cambios de la segunda entrevista sobre los roles:

- **El administrador es el comité de trabajos de grado** (decisión del equipo del 2026-10-06): registra a los docentes (RF7), aprueba las ideas y las propuestas (RF10), es el último filtro de aprobación después del director y el evaluador (RF14), gestiona prórrogas y actas, y asume lo que el PPT le daba a Coordinación. **Coordinación ya no es un rol:** el sistema tiene **4 roles** (Administrador, Director, Evaluador y Estudiante).
- **Los estudiantes se registran solos** (RF24); a los docentes los registra el administrador. Los docentes (director y evaluador) registran las ideas del banco, y el estudiante puede formular su propia propuesta (RF10).
- **El estudiante no ve a su evaluador** (RF27), aunque el PPT decía que sí.

Según el reglamento (art. 23), el comité de trabajo de grado lo conforman, como mínimo, el coordinador del programa (que lo convoca y preside), el líder del grupo de investigación, el líder del semillero y un docente por cada eje de formación. En el sistema, ese papel lo cumple el rol Administrador.

## Requerimientos

Lista oficial del proyecto. Cada requerimiento **fusiona** lo que quedó escrito en las notas de la entrevista con lo que se grabó en los audios de la misma sesión con el profesor. También incluye lo del PPT, lo del reglamento y las decisiones del equipo. **Donde el reglamento y la entrevista no coinciden, manda el reglamento; donde el F-DC-124 y el reglamento no coinciden, manda el F-DC-124, que es más nuevo.**

- **ID:** RF = funcional, RNF = no funcional. El tipo sigue lo que dijo el profesor en los audios; MySQL va como RNF por ser una restricción técnica.
- **Origen:** de dónde sale cada requerimiento. Los números (1–55) son los puntos de las notas ([Anexo A](#anexo-a-notas-de-la-entrevista)), los A-xx son los audios ([Anexo B](#anexo-b-audios-de-la-entrevista)) y **Reg.** son los artículos del reglamento ([Anexo C](#anexo-c-reglamento-de-trabajo-de-grado)). **Lista RNF-xx** es el número en la lista de no funcionales del equipo ([Anexo F](#anexo-f-lista-de-requisitos-no-funcionales)); "adaptado" indica que se ajustó a la tecnología del proyecto. **Otro equipo RF-xx** es el número en la lista de otro equipo ([Anexo I](#anexo-i-lista-de-requerimientos-de-otro-equipo)). **F-DC-124** es el formato de la propuesta ([Anexo J](#anexo-j-formato-f-dc-124-y-su-rejilla)); **F-DC-125** y **F-DC-129**, los del informe final y su rejilla ([Anexo K](#anexo-k-formatos-f-dc-125-y-f-dc-129)).
- **Rol:** quién ejecuta el requerimiento. "Todos" aplica a todos los roles; "Sistema" son reglas que el sistema aplica solo; "Equipo de desarrollo" son reglas técnicas. En el Word se agrupan por rol.
- **Planes anteriores** y **planes nuevos:** el reglamento aplica reglas distintas según si el plan de estudios del estudiante se aprobó antes o después del decreto 1330 de 2019.
- **Texto resumido:** cada requerimiento va con lo esencial. La versión completa, con todos los casos y plazos, está en el [Anexo E](#anexo-e-detalle-de-los-requerimientos); hay que consultarla al programarlo.
- **Sprint y Estado:** seguimiento (Pendiente, En progreso, Hecho). El detalle de cada sprint está en [sprints.md](sprints.md).

### Requerimientos funcionales

| ID | Rol | Requerimiento | Origen | Sprint | Estado |
| --- | --- | --- | --- | --- | --- |
| RF1 | Todos | Ingreso solo con correo institucional (@uts.edu.co o @correo.uts.edu.co). | 1 · A-10 | 1, 2, 3 | Hecho |
| RF2 | Todos | Informe del estado (fase) del proyecto para estudiantes, director y evaluador, con contador de días en la fase 4. | 7, 14, 18, 21 · A-15 |  | Pendiente |
| RF3 | Todos | Calendario académico configurable por semestre: banco de ideas hasta la semana 4, pago hasta la 8, propuesta aprobada hasta la 12, fechas del informe final (no antes de 90 días y máximo a los 180) y sesiones del comité. El comité crea, activa y cierra los periodos. | 8, 48 · A-27 · Reg. 12, 24, 28 · decisión del equipo · Otro equipo RF-21 | 3, 4 | Hecho (periodos, calendario, cierre del banco y sesiones del comité) |
| RF4 | Todos | Información de las modalidades: Proyecto de investigación, Desarrollo tecnológico, Monografía, Seminario y Emprendimiento (sin Práctica). | 9, 42 · A-08 · Reg. 8, 39, 42, 45, 51, 62 | 4 | Hecho |
| RF5 | Todos | Avisos dentro del sistema (sin correo) en cada movimiento; decisiones del comité notificadas en máximo 2 días hábiles; alertas de vencimiento a los 30 y a los 5–10 días. | 41, 44, 47 · A-16, A-25 · Reg. 25 | 5 | Hecho (avisos dentro del sistema en cada movimiento, en el momento; alertas del límite de pago, la semana 12, los plazos del director y del evaluador y el informe final a 30, 10 y 5 días, con la sugerencia de pedir prórroga) |
| RF6 | Todos | Buscador con filtros por fase, integrante, proyecto, título, docente, periodo o palabra. Cada rol busca solo en lo suyo: el estudiante en sus proyectos, el director en los que dirige y el evaluador en los que evalúa. | 49 · A-28 · Otro equipo RF-35–38 |  | Pendiente |
| RF7 | Administrador | El administrador crea y modifica los usuarios docentes; de cada docente registra cédula, correo y nombre completo. Busca y filtra usuarios (documento, nombre, correo, rol, programa, nivel, plan y estado), los desactiva sin borrar su historial y actualiza los datos académicos de los estudiantes. | 2, 55 · Reg. 2 · decisión del equipo · Otro equipo RF-05, RF-07–09 (adaptados) | 2, 3, 4 | Hecho |
| RF8 | Administrador | El administrador gestiona los roles (CRUD). | 3 | 2 | Hecho |
| RF9 | Administrador | Gestión de proyectos (CRUD); el comité registra la modalidad de cada estudiante. | 4 · Reg. 17 | 5 | En progreso (lista de proyectos con su fase, pago y director, y la página de cada proyecto) |
| RF10 | Administrador | Banco de ideas: los docentes registran las ideas y el estudiante puede formular su propia propuesta; el comité aprueba ambas. | 5 · A-20, A-21, A-30 · Reg. 27 · decisión del equipo | 4 | Hecho |
| RF11 | Administrador | Asignar a cada proyecto director y evaluador (el comité lo formaliza). Un docente nunca evalúa el proyecto que dirige. | 6, 22 · A-17 · PPT · Reg. 18, 20, 26 · decisión | 2, 5 | En progreso (el comité asigna director y evaluador; la base y la página impiden director = evaluador; faltan los codirectores) |
| RF12 | Administrador | Cambio de modalidad sin perder el proceso, solo antes de aprobar el FDC-124: el estudiante lo solicita y el comité lo aprueba o lo rechaza. Queda registro de la modalidad anterior y la nueva, quién lo pidió, quién decidió y cuándo. | 51 · A-31 · Otro equipo RF-82–85 | 5 | Hecho (el estudiante pide el cambio en las fases 1 a 3 y el comité lo aprueba o lo rechaza, con registro) |
| RF13 | Administrador | Proyectos interdisciplinarios (investigación o desarrollo tecnológico): director de la disciplina principal, hasta 2 codirectores y máximo 4 estudiantes. | Reg. 22 · decisión del equipo | 5 | Hecho (interdisciplinario con hasta 4 estudiantes y 2 codirectores, que comentan; decide el director) |
| RF14 | Administrador | Aprobación en orden: director (firma) → evaluador (concepto) → comité (decisión final; devuelve el proyecto si falta algo). La decisión del comité queda con su acta. | 17, 19, 20 · A-14 · Reg. 20, 26, 28, 31 · Otro equipo RF-70, RF-71 | 5 | Hecho (propuesta e informe final: director → evaluador → comité, con la decisión y su acta) |
| RF15 | Administrador | El comité genera informes estadísticos por periodo, por modalidad y por cantidad de estudiantes, y listados de aprobados y no aprobados. | Reg. 26 · decisión del equipo |  | Pendiente |
| RF16 | Administrador | El comité sesiona cada semana, deja acta de cada sesión y decide con al menos 3 miembros. | Reg. 24 |  | Pendiente |
| RF17 | Administrador | Seminario: el docente propone el tema desde el banco de ideas y el comité lo avala; mínimo 25 estudiantes y sin prórroga. No usa el F-DC-124. | Reg. 16, 18, 27, 32, 45–50 · decisión del equipo | 5 | En progreso (inscripción con recibo, F-AM-04 y documento de identidad; el comité la valida y asigna al docente como director; el docente registra la nota final; falta el mínimo de 25 estudiantes del grupo) |
| RF18 | Director | El director califica los proyectos de sus estudiantes: revisa la propuesta, deja observaciones de forma y contenido antes de su aval y revisa las correcciones. | 15 · Otro equipo RF-43, RF-44, RF-64, RF-94 | 5 | Hecho (el director devuelve o aprueba la propuesta y el informe final, y los revisa otra vez si el evaluador o el comité se los devuelven) |
| RF19 | Director | El director consulta la información del estudiante. | 16 | 5 | Hecho (datos académicos y de contacto de sus estudiantes) |
| RF20 | Director | El director registra al menos 2 seguimientos antes de la entrega del informe final. | Reg. 19 | 5 | Hecho (el director registra los seguimientos; sin 2 no se envía el informe final) |
| RF21 | Evaluador | Plazos: el evaluador tiene 3 días hábiles para la propuesta y 5 para el informe final; el director, 5 días. No hay aprobación automática. | 24, 43 · A-18 · Reg. 21 | 5 | Hecho (director 5 días hábiles; evaluador 3 para la propuesta y 5 para el informe final; alertas al vencer) |
| RF22 | Evaluador | Resultados: propuesta aprobada, aplazada o no aprobada; informe final aplazado, aprobado o no aprobado. Si el informe no se aprueba (por ejemplo, por plagio), se devuelve para corrección (parafraseo) y el estudiante tiene hasta antes de la fecha de vencimiento. | Reg. 21, 31, 32, 34 · F-DC-124 · decisión del equipo | 5 | Hecho (Aprobado, Aplazado o No aprobado en la propuesta y el informe final; el informe aplazado lleva plazo de corrección y el no aprobado vuelve a corrección; la nota de los planes nuevos va con RF42) |
| RF23 | Evaluador | Rejillas de evaluación: el evaluador marca *Cumple* en cada indicador de la rejilla del F-DC-124 para la propuesta (12 criterios y 28 indicadores; el estado del arte solo en investigación y desarrollo tecnológico; Seminario no la usa) o del F-DC-129 para el informe final (17 criterios y 40 indicadores, con N/A), con observaciones y una general; puede guardar en borrador. Solo envía con todo respondido, y para "Aprobado" deben cumplirse todos los que aplican. El estudiante y el director ven las observaciones cuando la evaluación está enviada. | Reg. 20, 21 · F-DC-124 · F-DC-129 · Otro equipo RF-58–62, RF-67, RF-68 | 5 | Hecho (rejillas del F-DC-124 y del F-DC-129, con N/A, borrador, validaciones y observaciones) |
| RF24 | Estudiante | El estudiante se registra solo en el sistema con su correo institucional, y registra su carrera, su nivel, su tipo de plan de estudios (anterior o posterior al decreto 1330), su porcentaje de créditos y si aprobó Metodología de la investigación (el administrador puede actualizarlos, RF7). | decisión del equipo · 50, 55 · Reg. 2 · Otro equipo RF-08 | 4, 5 | Hecho (con el catálogo de carreras de la UTS; el nivel sale de la carrera) |
| RF25 | Estudiante | El estudiante elige una idea según su nivel: el de tecnología no puede tomar ideas de ingeniería. Después del cierre del banco no se pueden tomar ideas. | 10, 50 · A-29 · Otro equipo RF-30 | 4 | Hecho |
| RF26 | Estudiante | El estudiante sube la propuesta, el anteproyecto y los entregables de su modalidad (evidencias del desarrollo, manual de usuario, código fuente). | 11, 45 · Otro equipo RF-86, RF-88 | 5 | En progreso (FDC-124 y anexos en PDF; faltan los entregables de la modalidad, que van con el informe final) |
| RF27 | Estudiante | La administración ve al director y al evaluador; el estudiante solo ve a su director. | 12 · A-19 | 5 | Hecho |
| RF28 | Estudiante | El estudiante consulta la información de su anteproyecto. | 13 | 5 | Hecho (Mi proyecto) |
| RF29 | Estudiante | Fase 1 (pago): tomar una idea del banco o la propia ya aprobada, subir el recibo de pago y cumplir los requisitos de la modalidad (75 % de créditos, 90 % en prácticas, y Metodología de la investigación aprobada). | 37, 38 · A-07 · Reg. 40–48, 52, 53, 63, 64 · fases del equipo · decisión del equipo | 3, 4 | Hecho (tomar la idea, requisitos y recibo de pago) |
| RF30 | Estudiante | La propuesta va con la firma del director y el concepto del evaluador; el FDC-124 lleva firma y Turnitin (similitud máxima del 10 %). Se aprueba hasta la semana 12 o pasa al siguiente semestre. Los formatos institucionales van en Word y los anexos en PDF. | 25, 26, 27 · A-12, A-13 · Reg. 12, 13, 28 · F-DC-124 | 5 | Hecho (FDC-124 en Word, aval del director, Turnitin, anexos, concepto del evaluador, decisión del comité y cancelación por la semana 12) |
| RF31 | Estudiante | El informe final (FDC-125), con firma del director, Turnitin y FDC-129, se entrega como mínimo 90 y como máximo 180 días después de que el comité aprueba totalmente el FDC-124; antes de 90 días el sistema no lo recibe. | 28, 29 · A-01, A-02 · Reg. 14, 31 · F-DC-124 · decisión del equipo | 5 | Hecho (FDC-125 por versiones, entre los días 90 y 180, con aval del director, Turnitin y la rejilla del F-DC-129) |
| RF32 | Estudiante | Pago del derecho pecuniario hasta la semana 8 (en los planes nuevos lo cubre la matrícula, salvo en Seminario); solo vale para ese periodo. El estudiante consulta el estado y la vigencia de su pago. | Reg. 12, 13, 67 · Otro equipo RF-79–81 · decisión del equipo | 4, 5 | Hecho (subir y consultar el recibo, límite de pago, planes nuevos y revisión del comité) |
| RF33 | Estudiante | Habilitación: el estudiante consulta si cumple los requisitos de la fase 1; el sistema le dice qué requisito le falta y le muestra solo las modalidades que puede tomar. | Reg. 40–48, 52, 53, 63, 64 · Otro equipo RF-11, RF-20 | 4 | Hecho (en los planes nuevos, la matrícula de Seminario de Grado la confirma la coordinación) |
| RF34 | Sistema | Observación obligatoria en cada aprobación y al cerrar cada etapa. | 35 · A-06 | 3, 5 | Hecho (obligatoria en la base y en todas las decisiones) |
| RF35 | Sistema | Un estudiante solo puede tener un proyecto a la vez. | 23 | 2, 3, 5 | Hecho |
| RF36 | Sistema | Integrantes: individual o hasta 2; hasta 3 en Proyecto de investigación y Desarrollo tecnológico. El estudiante agrega a sus compañeros y el sistema valida los requisitos de todos. | 54 · A-22 · Reg. 11 · Otro equipo RF-33, RF-34 · decisión del equipo | 3, 5 | Hecho (agregar y quitar compañeros en las fases 1 y 2, con sus validaciones y la revisión al enviar la propuesta) |
| RF37 | Sistema | El proyecto avanza por fases, como en el sistema actual de la UTS: 0 aprobación de la idea, 1 pago, 2 propuesta I (el estudiante envía el FDC-124 al director), 3 propuesta II (el director la revisa, la pasa por Turnitin y la envía al evaluador y al comité; puede devolverla a la 2), 4 informe I (el evaluador puede devolverla a la 3; con el FDC-124 aprobado por el comité empieza el FDC-125 y el estudiante envía el informe al director), 5 informe II (el director envía el informe al evaluador y al comité) y fase final (programar la sustentación). Cada cambio requiere aprobación y se guarda el progreso. | 53 · A-11 · fases del equipo · decisión del equipo · sistema actual de la UTS · texto del equipo (Anexo H) | 5 | Hecho (fases 0 a 5 y fase final: con el informe aprobado se programa la sustentación y el comité registra la aprobación final) |
| RF38 | Sistema | Plazo de 180 días desde la aprobación total del FDC-124, con hasta 3 prórrogas de 180 días, pedidas antes del vencimiento y pagadas de nuevo. Si se agotan, se cancela y el estudiante presenta una propuesta nueva. El Seminario no tiene prórroga. | 30, 31, 32 · A-03 · Reg. 13, 14, 16, 26 · F-DC-124 · decisión del equipo | 5 | Hecho (180 días desde la aprobación del FDC-124; hasta 3 prórrogas pedidas antes del vencimiento con su soporte y decididas por el comité; vencido sin prórroga, se cancela la modalidad; sin prórrogas en los planes nuevos) |
| RF39 | Sistema | El proyecto queda en estado "finalizado" después de la fase final (sustentación), con el informe final aprobado, para poder radicar los papeles de grado. En la fase final, el comité programa la sustentación (el sistema guarda su fecha y lugar), el evaluador la atiende y los estudiantes la presentan. | 34 · A-05 · Reg. 14, 21, 26, 32 · fases del equipo · decisión del equipo · Otro equipo RF-95, RF-97, RF-98 | 5 | Hecho (el comité programa y reprograma la sustentación con fecha, hora y lugar; los demás la ven y reciben el aviso; pasada la fecha, el comité registra la aprobación final con acta y el proyecto queda Finalizado) |
| RF40 | Sistema | Código único por proyecto (prefijo-año-periodo-consecutivo): 65 para tecnología y 125 para ingeniería, por ejemplo 65-2026-1/200. | 46 · A-24 | 5 | Hecho (se asigna al tomar la idea, por ejemplo 65-2026-2/1) |
| RF41 | Sistema | Planes nuevos: la propuesta se aprueba en Seminario de Grado I o III; su docente es el director y la presenta al comité entre las semanas 8 y 14. | Reg. 2, 15, 18, 20, 28, 29 |  | Pendiente |
| RF42 | Sistema | Planes nuevos: el trabajo se desarrolla en Seminario de Grado II o IV, cuyo docente es el director; sin prórrogas (si no termina, lo matricula de nuevo) y el informe final se califica con nota. | Reg. 15, 16, 18, 20, 31, 32, 33 |  | Pendiente |
| RF43 | Sistema | Versiones: después de cada observación se sube una versión nueva de la propuesta o del informe final; se conservan todas, con quién la subió y cuándo, y la aprobada queda marcada como oficial. | 53 · Otro equipo RF-45, RF-47, RF-63, RF-76, RF-93 | 5 | Hecho (versiones del FDC-124 y del FDC-125 con quién y cuándo; la aprobada queda como oficial) |

### Requerimientos no funcionales

| ID | Rol | Requerimiento | Origen | Sprint | Estado |
| --- | --- | --- | --- | --- | --- |
| RNF1 | Todos | Botón de PQR visible en cualquier fase (por ejemplo, para pedir cambio de director o evaluador), con su reporte. | 33 · A-04, A-26 | 5 | Hecho (botón en la cabecera para estudiantes, directores y evaluadores; el comité las responde con aviso y ve el reporte por tipo y estado, pero no las envía) |
| RNF2 | Todos | Las páginas cargan en menos de 3 s con 100 usuarios conectados a la vez. | Lista RNF-01 |  | Pendiente |
| RNF3 | Todos | Las búsquedas con filtros responden en menos de 2 s con 5.000 proyectos. | Lista RNF-02 |  | Pendiente |
| RNF4 | Todos | Las contraseñas se guardan con hash (SHA-256), nunca en texto plano. | Lista RNF-04 (adaptado: bcrypt → SHA-256) | 2 | Hecho |
| RNF5 | Todos | Control de acceso por rol en el servidor: cada página revisa la sesión y el rol con fragmentos `.jspf`. | Lista RNF-05 (adaptado: javax.servlet.Filter → `.jspf`) | 2 | En progreso (páginas del administrador) |
| RNF6 | Todos | La sesión expira a los 30 minutos de inactividad. | Lista RNF-07 | 2 | Hecho |
| RNF7 | Todos | Cumplir la Ley 1581 de 2012 (protección de datos personales). | Lista RNF-09 |  | Pendiente |
| RNF8 | Todos | Disponibilidad del 99 % en horario académico. | Lista RNF-11 |  | Pendiente |
| RNF9 | Todos | Diseño responsivo con Bootstrap. | Lista RNF-15 | 1, 2 | En progreso (pantallas hechas) |
| RNF10 | Todos | Mensajes de error claros y en español. | Lista RNF-17 | 2, 3 | En progreso (pantallas hechas) |
| RNF11 | Todos | Compatible con Chrome, Edge y Firefox (sus 2 últimas versiones). | Lista RNF-18 |  | Pendiente |
| RNF12 | Administrador | Auditoría de cada cambio de estado: quién, qué y cuándo. Se consulta con filtros por usuario, proyecto, tipo de acción y fechas, y el historial de cada proyecto se ve en orden cronológico. | Lista RNF-10 · Otro equipo RF-10, RF-39 | 5 | Hecho (historial de cada proyecto y auditoría con filtros por usuario, proyecto, acción y fechas) |
| RNF13 | Administrador | Copia de seguridad diaria, guardada por 30 días. | Lista RNF-12 |  | Pendiente |
| RNF14 | Estudiante | Saber TyT: si un integrante queda exonerado, el otro sigue; el exonerado puede renunciar, sin vuelta atrás. Estímulos (solo nivel tecnológico; ingeniería presenta Saber Pro, que no está en el sistema): exención del informe final con 4.5 (120–150 puntos), con 4.7 y 50 % de beca (151–170) o con 5.0 y 100 % de beca (171 o más). | 39, 40 · A-23 · Acuerdo 01-009 | 5 | Hecho (solicitud con certificado, verificación del comité, estímulo, renuncia y proyecto terminado si todos quedan exonerados) |
| RNF15 | Estudiante, Director | El estudiante y el director pueden subir archivos de hasta 15 MB. | Lista RNF-03 · decisión del equipo | 4, 5 | Hecho |
| RNF16 | Estudiante, Director | El servidor valida el tipo (.docx, .pdf) y el tamaño de los archivos que suben el estudiante y el director. | Lista RNF-08 | 4, 5 | Hecho (PDF y Word, según el documento) |
| RNF17 | Estudiante | Un estudiante nuevo sube su propuesta en máximo 5 clics. | Lista RNF-16 |  | Pendiente |
| RNF18 | Sistema | Todas las consultas son parametrizadas con `<sql:param>` (por dentro usa PreparedStatement). | Lista RNF-06 (adaptado) | 2, 3 | En progreso (se cumple en lo hecho) |
| RNF19 | Sistema | Los plazos los calcula el servidor en la zona America/Bogota; los días hábiles excluyen fines de semana y festivos de Colombia (tabla de festivos). | Lista RNF-13 | 5 | Hecho (festivos de 2026 y 2027; hay que agregar los de cada año) |
| RNF20 | Sistema | Soporta 3 veces más usuarios sin cambiar el diseño. | Lista RNF-25 |  | Pendiente |
| RNF21 | Sistema | Las tareas automáticas (alertas, cierres y rechazo por tiempo) se revisan cada vez que alguien usa el sistema. | Lista RNF-27 (adaptado: proceso programado → al usar el sistema) | 5 | Hecho (las alertas se revisan cada vez que alguien abre una página) |
| RNF22 | Equipo de desarrollo | Funciona en Tomcat 11 (Jakarta) y MySQL. | 52 · Lista RNF-22 (adaptado: Tomcat 9 → Tomcat 11) | 2 | Hecho |
| RNF23 | Equipo de desarrollo | Arquitectura JSP + JSTL (tema del parcial): las páginas acceden a los datos con las etiquetas `sql` de JSTL. | Lista RNF-19 (adaptado: Servlet + DAO → JSP + JSTL) | 2 | En progreso |
| RNF24 | Equipo de desarrollo | Fragmentos `.jspf` para los elementos repetidos. | Lista RNF-20 | 2 | En progreso (cabecera, pie, sesión y mensajes) |
| RNF25 | Equipo de desarrollo | Código documentado y versionado con Git. | Lista RNF-21 |  | Pendiente |
| RNF26 | Equipo de desarrollo | UTF-8 en todo el sistema (utf8mb4 en la base). | Lista RNF-23 | 2 | Hecho (web.xml y base) |

## Tecnología y entorno

- Editor: VS Code
- Tema del parcial: JSTL (segundo corte)
- Servidor instalado: Apache Tomcat 11 (XAMPP), con JSTL 3.0 disponible
- Base de datos: MySQL (RNF22). En local, XAMPP trae MariaDB 10.4, que es compatible con MySQL.
- Base de datos de referencia: `segundoparcial.sql` (base `sistemastg`), la base original que usan los profesores y coordinadores de la UTS para los proyectos de grado.
- Base de datos del proyecto: `sistemas_proyectos_grado`, creada con `bd/sistemas_proyectos_grado.sql`. El diseño está en [base-de-datos.md](base-de-datos.md).
- Dependencias clave (`.jar`): JSTL 3.0 (`jakarta.servlet.jsp.jstl-api-3.0.2` y `jakarta.servlet.jsp.jstl-3.0.1`) y el driver de MySQL (`mysql-connector-j`)
- Colores: verde lima `#C1D72F` y negro `#000000`, definidos en `css/estilo.css` (sin colores fuera de esta paleta, salvo eliminar y similares, que llevan su color convencional)

## Registro de decisiones y notas

| Fecha | Decisión | Motivo |
| --- | --- | --- |
| 2026-09-22 | Documentar los requerimientos aquí antes de empezar a programar. | Tener una memoria central del proyecto. |
| 2026-09-24 | Mover este archivo a `docs/`. | Es la ruta que usan `CLAUDE.md` y `README.md`. |
| 2026-09-24 | Los requerimientos se registran después de la entrevista; aquí no se documentan supuestos. | Levantarlos es parte del parcial (objetivo específico 1). |
| 2026-09-24 | Colores del sistema: verde lima `#C1D72F` y negro. | Elección del equipo. |
| 2026-09-24 | Uso de los colores: no se usan colores fuera del verde lima y el negro (y sus tonos). En general, negro para las fuentes y verde lima para fondos y animaciones (botones, estados activos, efectos al pasar el mouse, foco). Las acciones con significado propio, como eliminar, llevan su color convencional (rojo, etc., con las clases de Bootstrap). | Decisión del equipo. |
| 2026-09-24 | Estilo visual: fuente Plus Jakarta Sans, tarjetas blancas redondeadas, campos con fondo lima suave, botón principal lima en forma de píldora y fondo de página claro con resplandor lima. Logo UTS en `img/logo-uts.png`. | Aprobado por el equipo en el diseño del inicio de sesión (`index.jsp`); las demás pantallas siguen este estilo. |
| 2026-09-26 | Transcribir las notas de la entrevista con su numeración y sus bloques originales. | Mantener la trazabilidad con las notas del equipo mientras se clasifican en RF y RNF. |
| 2026-09-30 | Trabajar por sprints. Los requerimientos se asignan a un sprint a medida que avanza el proyecto; el seguimiento va en `docs/sprints.md`. | Decisión del equipo: hacer el proyecto por partes y llevar el seguimiento. |
| 2026-09-30 | Base del proyecto sin las tablas de Laravel de la original. | El sistema original es Laravel (PHP); esas tablas no sirven en JSP. |
| 2026-09-30 | Solo los 5 roles del PPT por ahora, y un usuario puede tener varios (por ejemplo, Director y Evaluador). | Decisión del equipo: un docente puede dirigir un proyecto y evaluar otro. |
| 2026-09-30 | Inicio de sesión con correo y contraseña. | Decisión del equipo, igual que en la original. |
| 2026-09-30 | Los proyectos van en una tabla `proyectos` explícita, no como "solicitudes" con formularios dinámicos. | Pedido del equipo: hacerlo de la forma más simple; es más fácil de programar con JSTL. |
| 2026-09-30 | Se agregan a la base los datos que pide la entrevista y la original no tiene (carrera del estudiante, prórrogas, código del proyecto, integrantes, PQR). | Pedido del equipo. |
| 2026-09-30 | Las prácticas no se incluyen en el sistema. Las firmas (25 y 26) no serían necesarias (por confirmar); el formato (29) sí va. | Decisión del equipo. |
| 2026-09-30 | El acceso a datos se hace con las etiquetas `<sql:query>` y `<sql:update>` de JSTL, siempre con `<sql:param>`; la conexión está una sola vez en `WEB-INF/web.xml`. | El parcial es de JSTL (guía del profesor); los parámetros evitan la inyección SQL. |
| 2026-10-05 | El rol Coordinación cumple el papel de comité (aprueba ideas y es el filtro final). Se mantienen 5 roles. **Reemplazada el 2026-10-06:** el comité es el administrador y Coordinación deja de ser un rol (ver abajo). | Decisión del equipo sobre A-14 y A-30. |
| 2026-10-05 | Correos institucionales aceptados: `@uts.edu.co` y `@correo.uts.edu.co`. | Decisión del equipo sobre A-10. |
| 2026-10-05 | Integrantes: de la misma carrera, 1 o 2; multidisciplinarios (de distintas carreras), 3 o 4; la monografía es de 1. **Reemplazada el 2026-10-06 por el reglamento** (ver abajo). | Decisión del equipo: une el punto 54 con A-22. |
| 2026-10-05 | El estudiante no ve a su evaluador; prevalece el audio sobre el PPT. | Decisión del equipo sobre A-19. |
| 2026-10-05 | La firma del director y Turnitin sí son necesarias. | Lo dice la segunda entrevista (A-02 y A-13); reemplaza la nota anterior de que no lo serían. |
| 2026-10-05 | Un estudiante puede tener varios proyectos en su historial, pero **solo uno vigente**. | Así cumple el punto 23 y también A-03 y el 32 (si se cancela un proyecto, puede empezar otro). Desde el 2026-10-06, según el reglamento (art. 16), tras la cancelación presenta una propuesta nueva, sin restricción de modalidad. |
| 2026-10-05 | Prefijo del código del proyecto: 65 para tecnología y **125** para ingeniería. | Confirmado por el equipo (A-24); el 126 del ejemplo de la primera entrevista era un error. |
| 2026-10-05 | **No se envían correos.** Los avisos de cada movimiento y de vencimiento se muestran dentro del sistema. | Lo decidió el profesor. Aplica a los puntos 44 y 47 y a A-16 y A-25. |
| 2026-10-05 | Las notas y los audios se fusionan en una sola lista oficial, numerada RF1–RF30 y RNF1–RNF4, con su origen. Las notas y los audios quedan como anexos. | Son la misma entrevista: del punto 26 en adelante el equipo escribió lo que dijo el profesor, que también se grabó. Pedido del equipo: una sola tabla de requerimientos. |
| 2026-10-06 | El **Reglamento de Trabajo de Grado** (Acuerdo 01-026 de 2021) es la fuente oficial: donde no coincide con la entrevista, manda el reglamento. Se ajustaron RF3–RF5, RF7, RF10, RF11, RF14, RF21, RF29–RF31, RF36, RF38 y RF39. | Decisión del equipo: "lo que diga el reglamento, ese es el oficial". |
| 2026-10-06 | Integrantes según el reglamento: individual o hasta 2; hasta 3 en Proyecto de investigación y Desarrollo tecnológico. Ninguna modalidad es solo individual. | Reglamento, art. 11. Reemplaza la decisión del 2026-10-05. |
| 2026-10-06 | El sistema maneja los dos regímenes del reglamento: planes anteriores al decreto 1330 (180 días y prórrogas) y planes nuevos (Seminario de Grado I a IV, sin prórrogas). | Decisión del equipo: seguir lo que diga el reglamento. |
| 2026-10-06 | Un docente puede ser director y evaluador, pero **nunca evaluador del proyecto que dirige**, sin excepciones. Se aparta del reglamento, que permite que el mismo docente dirija y evalúe en la modalidad Seminario (arts. 18 y 32) y en la propuesta de los planes nuevos (art. 20). | Decisión del equipo; prevalece sobre el reglamento en este punto. Aplica a RF11, RF17 y RF41. |
| 2026-10-06 | Estímulos por puntaje en Saber TyT para el nivel tecnológico, según el Acuerdo 01-009: 120–150 puntos, 4.5; 151–170, 4.7 y 50 % de beca en los derechos de grado; 171 o más, 5.0 y 100 % de beca. | Texto entregado por el equipo. Responde el puntaje de exoneración pendiente (punto 40, RNF14). |
| 2026-10-06 | Se quita el antiguo RNF1 ("los colores y el tamaño de letra no importan", A-09). El antiguo RNF14 (PQR) pasa a RNF1 y el RNF2 (exoneración) a RNF14. | Decisión del equipo: lo quitó del Word. |
| 2026-10-06 | Los textos de la lista oficial se resumen a lo esencial. La versión completa queda en el Anexo E. | Pedido del equipo: había requerimientos muy extensos. |
| 2026-10-06 | ~~El comité y la coordinación no son lo mismo: el comité pasa a ser un rol propio (Comité, sexto rol).~~ **Anulada el mismo día** (ver la decisión siguiente). | Decisión del equipo. |
| 2026-10-06 | ~~**Coordinador y comité son uno solo:** se quita el rol Comité y queda solo Coordinación, que cumple el papel de comité. El sistema vuelve a 5 roles.~~ **Reemplazada el mismo día** por "el administrador es el comité". Los requerimientos del comité (RF14–RF17) pasan al grupo Coordinación; la numeración no cambia. | Decisión del equipo: "coordinador y comité es uno solo, solo deja coordinador". |
| 2026-10-06 | Fases del proyecto: 1 revisión de los requisitos del estudiante y planteamiento de la idea; 2 presentación de la idea al comité; 3 desarrollo de la idea; 4 ajustes; 5 sustentación. La creación del usuario (fase 0) no es una fase del proyecto, porque la hace el administrador. Lo que antes era la "fase 0" (elegir la idea, pagar y cumplir los créditos, A-07) queda en la fase 1 (RF29). Más tarde cambió el nombre de la fase 1 (ver abajo). | Definidas por el equipo (Anexo H). |
| 2026-10-06 | **El comité de trabajos de grado es el administrador.** Coordinación deja de ser un rol: quedan 4 (Administrador, Director, Evaluador, Estudiante). Los requerimientos de Coordinación pasan al grupo Administrador. | Decisión del equipo. Reemplaza "coordinador y comité son uno solo". |
| 2026-10-06 | El administrador (comité) registra a los docentes con cédula, correo y nombre completo; **los estudiantes se registran solos** (nuevo RF24). Los docentes registran las ideas del banco y el estudiante puede formular su propia propuesta; el comité aprueba ambas (RF10). | Decisión del equipo. |
| 2026-10-06 | Fase 1: "seleccionar la idea y pagar" (RF29, RF37). | Decisión del equipo. |
| 2026-10-06 | Cambios que el equipo hizo en el Word: fechas del informe final en el calendario, entre 90 y 180 días (RF3); interdisciplinarios con máximo 4 estudiantes (RF13); informes por modalidad y por cantidad de estudiantes (RF15); si el informe final no se aprueba, se devuelve para corrección hasta antes del vencimiento (RF22); 90 % de créditos en prácticas (RF29); "finalizado" después de la fase 5 (RF39); archivos de hasta 15 MB (RNF15). Se quita el tercer evaluador. | Decisión del equipo. RF13 se aparta del reglamento (art. 11: hasta 3), RF22 también (art. 34: propuesta nueva con otro tema) y RF29 (el reglamento pide 90 % en Seminario). |
| 2026-10-06 | Segunda renumeración del día: al quitar el tercer evaluador y agregar el registro del estudiante, RF15–RF22 cambiaron de número. El Anexo G ya tiene la equivalencia final. | Mantener los IDs seguidos. |
| 2026-10-06 | Base de datos versión 3: 4 roles (sin el rol 2), fases 1 a 5, plan de estudios y puntaje de Saber TyT del estudiante, máximo de integrantes por modalidad, proyectos interdisciplinarios con codirectores, resultados del reglamento y nota en las revisiones, seguimientos del director, festivos, límite de pago y origen de las ideas. Diagrama entidad-relación en `bd/diagrama-entidad-relacion.png`. | Pedido del equipo: ajustar la base antes del diagrama. Detalle en `docs/base-de-datos.md`. |
| 2026-10-06 | Cada columna ENUM de la base lleva `CHECK (columna <> '')`. | MariaDB de XAMPP no está en modo estricto y guardaría un valor inválido como texto vacío. Se resuelve en la base, sin tocar la configuración del servidor (la comparten otras apps). |
| 2026-10-06 | Se quita RNF27 (conexión a la base con pool, DataSource de Tomcat). Quedan RNF1–RNF26. | Decisión del equipo: lo borró del Word. |
| 2026-10-06 | Se agregan los requisitos no funcionales de la lista del equipo como RNF2–RNF13, RNF15–RNF21, RNF23–RNF27 (el RNF27, conexión con pool, se quitó después). No se incluyen los de correo (RNF-14 y RNF-26), por la decisión del profesor de no enviar correos. Los de tecnología se adaptan al proyecto: SHA-256 en vez de bcrypt (RNF-04), `.jspf` en vez de javax.servlet.Filter (RNF-05), `<sql:param>` (RNF-06), JSP + JSTL en vez de Servlet + DAO (RNF-19), Tomcat 11 en vez de Tomcat 9 (RNF-22, unido a RNF22) y tareas automáticas revisadas al usar el sistema en vez de un proceso programado (RNF-27). | Decisión del equipo. El parcial es de JSTL y el proyecto ya va en JSP + JSTL sobre Tomcat 11 (Jakarta). |
| 2026-10-06 | Cada requerimiento lleva su rol (columna Rol). En el Word van en una sola tabla agrupada por rol. | Pedido del equipo: separar los requisitos por rol. |
| 2026-10-06 | Los RNF van en una tabla aparte de los RF, aquí y en el Word; cada tabla sigue agrupada por rol. | Pedido del equipo. |
| 2026-10-06 | Se **renumeran** los RF y los RNF en el orden de los grupos por rol, para que salgan seguidos (RF1–RF3…). Todas las referencias de los documentos ya usan los números nuevos; la equivalencia con los anteriores está en el Anexo G. | Pedido del equipo: en el Word salían saltados (RF1, RF7, RF8…). |
| 2026-10-06 | Se agregan RF13, RF15–RF17, RF20, RF22, RF32, RF41, RF42 desde el reglamento. Lo que el reglamento deja a otras dependencias o a otros sistemas (repositorio, distinción, propiedad intelectual, notas del sistema académico, trámites de pago) se marca "fuera del sistema" en el Anexo C; el equipo puede pedir que se incluya. | Decisión del equipo: agregar lo que diga el reglamento. |
| 2026-10-08 | Se compara la lista de requerimientos de otro equipo (RF-01 a RF-100, Anexo I) con la nuestra y se toma lo que no choca con las decisiones del equipo: lo que allá hace el rol Comité, aquí lo hace el Administrador; se mantienen los integrantes (hasta 3 en investigación y desarrollo tecnológico, hasta 4 en interdisciplinarios) y que un docente nunca evalúa el proyecto que dirige. | Decisión del equipo: "mantener lo nuestro". |
| 2026-10-08 | **Los estudiantes se registran solos** (RF24); el administrador puede corregir o actualizar sus datos académicos (porcentaje de créditos, Metodología aprobada y plan de estudios), que cambian cada semestre (RF7). | Un profesor lo explicó: un administrador no puede registrar a más de 500 estudiantes. |
| 2026-10-08 | Siguen fuera del sistema la modalidad Práctica, el nivel Técnico Profesional y la publicación en el repositorio, aunque la lista del otro equipo los incluye. | Decisión del equipo. |
| 2026-10-08 | De los requerimientos nuevos de esa lista entran la rejilla del F-DC-124 con borrador (nuevo RF23), la habilitación del estudiante (nuevo RF33), las versiones de los documentos (nuevo RF43), la solicitud de cambio de modalidad con su registro (RF12) y los filtros de la auditoría (RNF12); también se suman detalles a RF3, RF6, RF7, RF14, RF18, RF24–RF26, RF32 y RF36. No entran los campos del F-DC-124 dentro del sistema ni el bloqueo de la versión oficial (el formato se sube en Word), la programación de la sustentación (fuera del sistema) ni los grupos de investigación (no hay catálogo). Se renumeran los RF: quedan RF1–RF43 (equivalencia en el Anexo G). | El equipo pidió "los más recomendados". La rejilla la pide el reglamento (arts. 20 y 21) y el cambio de modalidad hoy se hace a mano en la base (A-31). |
| 2026-10-08 | Base de datos versión 4: Metodología aprobada del estudiante, estado del periodo, versiones y entregables de la modalidad en `entregas`, evaluación en borrador, rejilla del F-DC-124 (criterios, indicadores, criterios por modalidad y respuestas por indicador), solicitudes de cambio de modalidad y tipo de acción en el historial. | Para RF7, RF3, RF26, RF43, RF23, RF12 y RNF12. Detalle en `docs/base-de-datos.md`. |
| 2026-10-08 | Contraseña de todos los usuarios de prueba: `123456`. | Pedido del equipo. Son usuarios de prueba; en producción cada usuario tiene la suya. |
| 2026-10-10 | **Fases del proyecto** como en el sistema actual de la UTS: 0 aprobación de la idea, 1 pago, 2 propuesta I, 3 propuesta II, 4 informe I, 5 informe II y fase final (sustentación). El director puede devolver la propuesta de la fase 3 a la 2 y el evaluador de la 4 a la 3; el FDC-125 empieza en la fase 4, cuando el comité aprueba el FDC-124. Reemplazan las del 2026-10-06 (Anexo H). | Texto del equipo y foto del seguimiento del director en el sistema actual (sistemastg). |
| 2026-10-10 | Sprint 4 hecho: registro del estudiante, habilitación, filtros y datos académicos de los usuarios, periodos y calendario, modalidades y banco de ideas. El proyecto se crea en la fase 1 cuando el estudiante toma una idea aprobada. | Pedido del equipo: "arranca el Sprint 4". Detalle en sprints.md. |
| 2026-10-10 | Los 180 días para entregar el FDC-125 (y los 90 mínimos) se cuentan **desde que el comité aprueba totalmente el FDC-124**. Es un solo plazo: lo de "180 días en la fase 2" se refería a este. | Decisión del equipo. Reemplaza el conteo desde la notificación (F-DC-124). |
| 2026-10-10 | La sustentación (fase final) se guarda en el sistema con su fecha y lugar (tabla `sustentaciones`). La pantalla va con la fase final. | Decisión del equipo: "sería lo adecuado". Cambia lo que se había dejado fuera del sistema (lista del otro equipo, RF-95). |
| 2026-10-10 | Diseño de las páginas internas inspirado en el sistema actual de la UTS: menú lateral con íconos, cabecera "Bienvenido" con el usuario y seguimiento del proyecto en tarjetas por fase; siempre en verde lima y negro. | Pedido del equipo: "algo parecido, para que no se vea genérico". |
| 2026-10-10 | **El comité revisa el recibo de pago** de la fase 1: lo aprueba o lo devuelve al estudiante, siempre con observación (RF32, RF34). Si lo devuelve, el estudiante sube otro dentro del plazo de pago. | Decisión del equipo: "el comité revisa el pago". |
| 2026-10-10 | **El estudiante no puede pedir su director**: el comité asigna el director y el evaluador (RF11). Cierra la pregunta de la lista del otro equipo (RF-42). | Decisión del equipo. |
| 2026-10-10 | El proyecto pasa de la fase 1 a la fase 2 cuando tiene **el pago aprobado por el comité (o no aplica, en los planes nuevos) y el director asignado**, sin importar el orden en que pasen; queda "En curso" y con la fecha de inicio de ese día. El evaluador se puede asignar después. **Por confirmar con el profesor** (**confirmado el 2026-10-14**: queda así). | Propuesta de Claude, a partir de las decisiones anteriores: en la fase 2 el estudiante le envía la propuesta al director, así que sin director no puede empezarla. |
| 2026-10-10 | Fase 2 (Propuesta I): el estudiante sube el FDC-124 en Word tantas veces como quiera (cada archivo es una versión nueva) y envía la última a su director; con eso el proyecto pasa a la fase 3. Si el director devuelve una versión, el proyecto vuelve a la fase 2 y el estudiante debe subir una versión nueva antes de reenviarla. Seminario no sube el F-DC-124. | Texto del equipo sobre las fases (Anexo H), RF30 (formatos en Word), RF43 (versiones) y RF17. |
| 2026-10-10 | Fase 3 (Propuesta II): el director revisa la última versión y, siempre con observación, la devuelve (vuelve a la fase 2) o la aprueba: sube el reporte de Turnitin en PDF y la envía al evaluador y al comité, con lo que el proyecto pasa a la fase 4. Para enviarla, el comité ya debe haber asignado el evaluador. Solo decide el director, no los codirectores. El porcentaje de similitud no se guarda aparte: lo revisa el evaluador con el indicador de Turnitin de la rejilla (RF30). Su aprobación en el sistema se toma como su aval (la "firma" de RF30); **por confirmar** si además debe subir el formato firmado (**confirmado el 2026-10-14**: basta con la aprobación en el sistema). | Texto del equipo sobre las fases (Anexo H), RF14, RF18, RF30 y RF34. |
| 2026-10-10 | **Integrantes (RF36):** cualquier estudiante del proyecto agrega a un compañero con su correo y este queda en el proyecto de una vez (sin invitación). El compañero debe ser un estudiante activo, habilitado, del mismo nivel y sin otro proyecto vigente. El máximo es el de la modalidad, o 4 si el comité marca el proyecto como interdisciplinario (RF13, solo investigación o desarrollo tecnológico). | Decisión del equipo (RF36 de la lista del otro equipo: "el estudiante agrega a sus compañeros"). |
| 2026-10-10 | **Los compañeros se agregan o se quitan en las fases 1 y 2**; al enviar la propuesta al director, el grupo se cierra. Antes de enviarla, el sistema vuelve a revisar que no se pase del máximo y que todos estén habilitados y con el pago al día. Quitar no borra: el compañero queda "Excluido" y sin vigencia, y puede empezar otro proyecto (RF35). | Decisión del equipo (RF36: "antes de enviar la propuesta"). |
| 2026-10-10 | **Cada estudiante sube su propio recibo de pago** y el comité revisa el de cada uno. El proyecto pasa a la fase 2 cuando todos tienen el pago aprobado (o no les aplica) y hay director. Un compañero agregado en la fase 2 sube su recibo en esa fase, y la propuesta no se envía hasta que su pago esté aprobado. | Decisión del equipo. |
| 2026-10-10 | **Regla del profesor: solo JSTL, nada de scriptlets ni archivos `.java`.** El proyecto ya la cumplía. Las expresiones EL que llaman métodos para subir y descargar archivos (`getPart`, `write`, `URLEncoder`) se dejan, porque JSTL no tiene una etiqueta para recibir archivos; en lo nuevo, los cálculos (plazos, código, estímulos) se hacen en SQL. | Lo dijo el profesor; el equipo decidió dejar la subida como está. |
| 2026-10-10 | Antes de seguir con la fase 4 se completa todo lo de las fases 0 a 3 y lo transversal: avisos, historial y auditoría, plazos en días hábiles, código del proyecto, PQR, codirectores, cambio de modalidad, anexos, catálogo de carreras y exoneración por Saber TyT. El buscador (RF6) y los informes (RF15) quedan para el final. La base se reinició: se conservaron los usuarios, el periodo 2026-2 y las ideas, y se borraron los proyectos. | Pedido del equipo: "agrega todo lo necesario, sin tener que hacer después". |
| 2026-10-10 | **Catálogo de carreras** de la UTS (Anexo L): el estudiante escoge su carrera de la lista y su nivel sale de ella. El nivel "Ingeniería" pasa a llamarse **"Universitario"**, como en la UTS y el reglamento; el prefijo 125 del código queda para todo el nivel universitario. | Lista entregada por el equipo; decisión del equipo sobre el nombre del nivel. |
| 2026-10-10 | **Exoneración por Saber TyT (RNF14):** el estudiante escribe su puntaje y sube el certificado en PDF, y el comité lo verifica; se pide en cualquier fase mientras no haya entregado el informe final (**reemplazado el 2026-10-11**: solo con la propuesta aprobada, en la fase 4). Si todos los integrantes vigentes quedan exonerados (sin renuncia), el proyecto se da por terminado con concepto "Aprobado" y se exime el informe final. | Decisiones del equipo. |
| 2026-10-10 | **Codirectores (RF13):** los asigna el comité (hasta 2, solo en interdisciplinarios); ven el proyecto y dejan observaciones, pero decide el director. El evaluador tampoco puede ser codirector del proyecto. | Decisión del equipo. |
| 2026-10-10 | **Avisos (RF5, RNF21):** cada movimiento deja un aviso dentro del sistema a quien le interesa (campana en la cabecera); el estudiante nunca recibe un aviso que nombre a su evaluador. Las alertas de vencimiento (límite de pago y semana 12 a 10 y 5 días; plazo del director vencido) se revisan cada vez que alguien abre una página. | RF5, RNF21 y decisión del profesor (sin correos). |
| 2026-10-10 | Supuestos, por confirmar (**confirmados el 2026-10-11**, ver abajo): los "5 días" del director para revisar la propuesta son hábiles, como los del evaluador (RF21); el consecutivo del código del proyecto empieza en 1 en cada periodo y nivel (RF40). | Propuesta de Claude: las fuentes no lo dicen. |
| 2026-10-11 | **Seminario (RF17):** cada estudiante se inscribe subiendo su recibo de pago, el formato F-AM-04 y su documento de identidad (ampliado al 150 %), en PDF. El comité valida la inscripción (todos los pagos aprobados, los documentos completos y el docente del seminario asignado como director) o la devuelve con observación; validada, el proyecto queda "En curso" y el grupo se cierra. Las 16 semanas de clase y el entregable en Atena van fuera del sistema. Al terminar, el docente registra la nota final con observación: con 3.0 o más el proyecto queda "Finalizado"; con menos, "Cancelado", y los estudiantes pueden empezar de nuevo. | Proceso de Seminario entregado por el equipo; la nota mínima de 3.0 la confirmó el equipo el 2026-10-11. |
| 2026-10-11 | **Semana 12 vencida (RF30):** si vence la fecha límite de propuestas sin el FDC-124 aprobado, "el trámite se cancela por extemporaneidad" y el pago no se reembolsa ni se abona. El sistema cancela el proyecto solo (se revisa cada vez que alguien abre una página, RNF21), avisa a los estudiantes, al director, a los codirectores y al comité, libera a los estudiantes y devuelve la idea al banco. Aplica solo si algún integrante es de un plan anterior al decreto 1330, y no a Seminario. | Texto entregado por el equipo y decisiones del equipo (automático, la idea vuelve al banco, solo planes anteriores). |
| 2026-10-11 | **Supuestos confirmados por el equipo:** la nota mínima para aprobar es 3.0 (Seminario, RF17); el director tiene 5 días hábiles para revisar la propuesta (RF21); el consecutivo del código del proyecto vuelve a empezar en 1 en cada periodo académico (RF40). SNIES 119351 para Negocios Internacionales (nivel profesional); quedó en la oferta de Bucaramanga, y la oferta del Campus Virtual se deja sin SNIES (decisión del 2026-10-14). | Respuesta del equipo. |
| 2026-10-11 | **Fase 4 (Informe I):** con la aprobación del director, el evaluador tiene 3 días hábiles para evaluar la propuesta con la rejilla del F-DC-124 (borrador, Sí o No por indicador y observaciones). Puede devolverla al director (vuelve a la fase 3, Anexo H) o enviar su concepto (Aprobado, Aplazado o No aprobado). El comité da la decisión final con el número y la fecha del acta: **aprobada**, la versión queda como oficial y desde la fecha del acta corren los 180 días del informe final; **aplazada**, vuelve a la fase 2 para que el estudiante suba una versión corregida; **no aprobada**, el proyecto se cancela y la idea vuelve al banco; si falta algo, la devuelve al director (fase 3). Con la propuesta aprobada, el director registra los seguimientos y el estudiante sube el FDC-125 por versiones y lo envía al director desde el día 90, con al menos 2 seguimientos (RF20); con eso pasa a la fase 5. | Texto del equipo sobre las fases (Anexo H), RF14, RF20–RF23, RF31; aplazar y no aprobar, decisión del equipo (2026-10-11). |
| 2026-10-11 | **Fase 5 (Informe II):** el estudiante envía el FDC-125 al director, que tiene 5 días hábiles para devolverlo (vuelve a la fase 4) o aprobarlo con el reporte de Turnitin y enviarlo al evaluador y al comité. El evaluador tiene 5 días hábiles para evaluarlo con la rejilla del F-DC-129 (Sí, No o N/A; "Aprobado" con todos los que aplican en Sí); si lo aplaza, indica el plazo máximo para las correcciones, hasta la fecha límite del proyecto. El comité decide con acta: **aprobado**, la versión queda como oficial y el proyecto pasa a la fase final; **aplazado**, vuelve a la fase 4 y el estudiante lo reenvía dentro del plazo del evaluador; **no aprobado**, también vuelve a la fase 4 para corrección hasta la fecha límite (cambio del 2026-10-06 en RF22); si falta algo, lo devuelve al director. Cada acta queda ligada a la decisión que respalda. | Anexo H, RF14, RF21, RF22, RF23, RF31 y Anexo K. |
| 2026-10-11 | **Plazo del informe final vencido (RF38):** "al expirar el tiempo establecido sin haber culminado el proceso o tramitado una prórroga sucesiva" se cancela la modalidad, se pierden los derechos sobre la propuesta aprobada y el estudiante empieza de nuevo (otra propuesta u otra modalidad, como Seminario de Grado). El sistema lo hace solo cuando el proyecto sigue en la fase 4 (no envió el informe) y pasó su fecha límite sin una prórroga pendiente: queda "Cancelado", la idea vuelve al banco y los estudiantes quedan libres. Como en la semana 12, solo si hay algún estudiante de plan anterior. | Texto del reglamento entregado por el equipo. |
| 2026-10-11 | **Prórrogas (RF38):** el estudiante la pide antes del vencimiento, con motivo y soporte en PDF (el recibo del nuevo pago o, en investigación y desarrollo tecnológico, el aval de la Dirección de Investigaciones y Extensión). El comité la aprueba (la fecha límite suma 180 días; hasta 3) o la rechaza, con observación. En los planes nuevos no hay prórrogas (RF42). | Anexo E (RF38), reglamento (arts. 16 y 26) y F-DC-124. |
| 2026-10-11 | **Informe final de los planes nuevos (RF42):** se evalúa con concepto (Aprobado, Aplazado o No aprobado), sin nota, porque el sistema actual de la UTS (Academusoft) sigue con el esquema que solo da un concepto cualitativo. | Respuesta del equipo. |
| 2026-10-11 | **Exoneración por Saber TyT, cuándo se pide (RNF14):** solo con la propuesta (FDC-124) aprobada por el comité, en la fase 4, y antes de enviar el informe final, porque lo que se exime es el informe ("exención del informe final", Acuerdo 01-009). Antes de pagar y de aprobar la propuesta no se puede. Reemplaza el "en cualquier fase" del 2026-10-10. | Decisión del equipo. |
| 2026-10-11 | Para la exoneración (RNF14), el informe final cuenta como entregado cuando el estudiante lo envía al director (fase 5), no cuando sube un borrador. | Ajuste al programar la fase 4. |
| 2026-10-13 | **Fase final (RF39):** la sustentación la registra en el sistema cualquiera de los estudiantes vigentes, el director o el evaluador del proyecto, cada uno con su rol activo (los codirectores la ven, pero no la programan; el comité tampoco): fecha y hora después de este momento y lugar o enlace de la reunión (hasta 150 caracteres). Hay una sola por proyecto y se puede reprogramar hasta la aprobación final; queda quién la programó y cuándo, sale en el historial y les llega un aviso a los demás y al comité. Al estudiante (y al director) le sale "El evaluador", sin el nombre (RF27). Cuando pasan la fecha y la hora de la sustentación, el comité registra la aprobación final con observación (RF34) y con el número y la fecha del acta (no futura ni anterior a la sustentación): el proyecto queda "Finalizado" y los estudiantes pueden radicar los papeles de grado; siguen vigentes en el proyecto terminado, como en los demás finalizados (RF35). El resultado de la sustentación no se registra (no se incluyó RF-96 de la lista del otro equipo). **Por confirmar** (**resuelto el 2026-10-14**: la programa el comité y la aprobación final lleva acta): quién registra la sustentación en el sistema (las fuentes dicen que la programan estudiantes, director y evaluador; en la lista del otro equipo la programaba el comité) y que la aprobación final lleve acta. | RF39, Anexo H, decisión del 2026-10-10 y lista del otro equipo (RF-95; RF-97: la aprobación final la registra el administrador; RF-98). Lo marcado por confirmar es propuesta de Claude: las fuentes no lo dicen. |
| 2026-10-14 | **PQR (RNF1):** el administrador no envía PQR: es el comité, que las responde. Sin el botón de la cabecera; si entra a la página de enviar, va a la de responder. Los demás roles siguen igual. | Decisión del equipo ("el administrador no debería tener opción de enviar PQR"). |
| 2026-10-14 | **Demostración:** los 90 días para enviar el informe final (RF31) y la aprobación final después de la sustentación (RF39) no cambian. Para la presentación hay un script aparte, `bd/demo-adelantar-tiempo.bat` (con `bd/demo-adelantar-tiempo.sql`), que adelanta las fechas de un proyecto: en la fase 4, lo que falta para el día 90; en la fase final, deja la sustentación como hecha hace una hora. No es parte del sistema ni de los requerimientos. | Pedido del equipo: mostrar el flujo completo la semana siguiente sin esperar 90 días. |
| 2026-10-14 | **Fase final (RF39): la sustentación la programa el comité.** Registra y reprograma la fecha, la hora y el lugar o enlace; los estudiantes, el director, los codirectores y el evaluador la ven y reciben el aviso, pero no la cambian. Reemplaza lo del 2026-10-13 (la programaban estudiantes, director o evaluador). A los demás, en "Programada por" les sale "El comité". | Reglamento: el comité "coordina las sustentaciones" (art. 26, literal m) y el evaluador las atiende y las califica (art. 21, literal e). Decisión del equipo: "como dice el comité, es lo más lógico". |
| 2026-10-14 | **Preguntas abiertas resueltas:** (1) el paso de la fase 1 a la 2 queda como está (pago de todos aprobado y director asignado); (2) la firma del director en el FDC-124 es su aprobación en el sistema, sin subir el formato firmado (RF30); (3) la aprobación final del comité lleva acta (RF39); (4) el criterio 16 "Sustentación" del F-DC-129 lo marca el evaluador en la fase 5, con el resto de la rejilla, como calificación provisional: la sustentación se programa después y un ajuste posterior lo maneja la coordinación, fuera del sistema; (5) la oferta de Negocios Internacionales del Campus Virtual se queda sin SNIES; (6) se quita el pendiente de diseñar las historias de usuario. | Respuestas del equipo. En (4): en las UTS el evaluador completa y cierra la rejilla antes de que se habilite la sustentación en la plataforma. |
| 2026-10-08 | La rejilla de evaluación de la propuesta (RF23) sigue el F-DC-124 versión 2.0: 12 criterios y 28 indicadores, *Sí/No* por indicador, y el estado del arte solo para Proyecto de investigación y Desarrollo tecnológico. Seminario queda como Monografía y Emprendimiento (sin estado del arte) hasta confirmar si usa este formato. Las diferencias del formato con el reglamento y con las decisiones del equipo quedan como preguntas abiertas; mientras tanto se mantiene lo que ya estaba. | Formato entregado por el equipo (Anexo J). Resuelve qué criterios aplican a cada modalidad. |
| 2026-10-08 | **El F-DC-124 manda sobre el reglamento** donde no coinciden, porque es más nuevo (2023; el reglamento es de 2021). Cambia: el concepto sobre la propuesta es aprobado, aplazado o no aprobado (sin "aprobado con correcciones", RF22); hasta 3 prórrogas (RF38); y los 180 días se cuentan desde la notificación de la aprobación al estudiante (RF31, RF38). Los 4 integrantes de los interdisciplinarios (RF13) se mantienen, porque son una decisión del equipo. | Decisión del equipo: "el reglamento está desactualizado, usa el formato, que es más nuevo". |
| 2026-10-08 | ~~El FDC-124 (propuesta) se aprueba en la fase 2 y el FDC-125 (informe final) se entrega en la fase 4~~ (**reemplazado el 2026-10-10** por las fases del sistema actual); el informe final se evalúa con la rejilla del F-DC-129 (17 criterios, 40 indicadores, con N/A). Seminario no usa el F-DC-124. El FDC-126 es de prácticas y el 90 % de créditos también es de prácticas: los dos quedan fuera del sistema. Los estímulos son solo para tecnología (Saber TyT); ingeniería presenta Saber Pro, que es aparte. | Respuestas del equipo y formatos F-DC-125 y F-DC-129 (Anexo K). |

## Pendientes y preguntas abiertas

- [x] Hacer la entrevista y registrar los requerimientos (transcritos el 2026-09-26).
- [x] Revisar la transcripción de las notas (solo queda el puntaje de exoneración, ver abajo).
- [x] Clasificar en funcionales y no funcionales: al fusionar notas y audios quedaron RF1–RF30 y RNF1–RNF4 (2026-10-05).
- [x] Confirmar la base de datos de referencia: es `segundoparcial.sql` (`sistemastg`).
- [x] Definir en qué se diferencia la base del proyecto de la original (ver `docs/base-de-datos.md`).
- [x] Prácticas: **no se incluyen** en el sistema (decisión del equipo, 2026-09-30).
- [x] Firma del director y Turnitin: sí son necesarias (segunda entrevista, A-02 y A-13).
- [x] Prefijo del código de ingeniería: **125** (confirmado por el equipo; el 126 de la primera entrevista era un error).
- [x] Qué pasa en cada fase (RF37): definidas por el equipo el 2026-10-06 ([Anexo H](#anexo-h-fases-del-proyecto)).
- [x] ¿En qué fase se aprueba el FDC-124 y en cuál se entrega el FDC-125? El FDC-124 en la fase 2 y el FDC-125 en la fase 4 (texto del equipo, Anexo K).
- [x] ¿Existe un formato FDC-126? Sí, pero es de prácticas, que están fuera del sistema (lo confirmó el equipo).
- [x] ¿El FDC-124 es el formato de la propuesta? Sí: el F-DC-124 es la "Propuesta de trabajo de grado" (Anexo J).
- [x] Incorporar el Reglamento de Trabajo de Grado (2026-10-06): RF13, RF15–RF17, RF20, RF22, RF32, RF41, RF42 y ajustes en la tabla; detalle en el Anexo C.
- [x] Ajustar la base de datos al reglamento (versión 3, 2026-10-06): plan de estudios, máximo de integrantes, codirectores, resultados de evaluación y nota, seguimientos, puntaje de Saber TyT y festivos. Diagrama en `bd/diagrama-entidad-relacion.png`.
- [x] La lista de no funcionales ubica la propuesta en la fase 1 (RNF-16) y la subida de archivos en las fases 2 y 4 (RNF-03 y RNF-08); concuerda con las fases definidas (planteamiento de la idea, presentación al comité y ajustes).
- [x] Ajustar las fases en la base (versión 3): fases 1 a 5 del equipo.
- [x] Ajustar la base y el código a los 4 roles (versión 3): sin el rol 2 (Coordinación) ni su usuario de prueba; los demás roles conservan su id.
- [x] Programar el registro del estudiante (RF24): hecho en el Sprint 4.
- [x] El equipo dijo que en la fase 2 el estudiante "tiene 180 días para presentar y aprobar" el FDC-124, y también que hay "180 días para entregar el 125". ¿Son dos plazos distintos (uno para la propuesta y otro para el informe final)? Es un solo plazo: 180 días desde que el comité aprueba totalmente el FDC-124 (2026-10-10).
- [x] Fase final ("estudiantes, director y evaluador programan la sustentación"): ¿el sistema guarda la fecha y el lugar? Sí: fecha y lugar (2026-10-10).
- [x] Comparar la lista de requerimientos de otro equipo (2026-10-08): se toma lo que no choca; detalle en el [Anexo I](#anexo-i-lista-de-requerimientos-de-otro-equipo).
- [x] ¿Qué criterios de la rejilla del F-DC-124 aplican a cada modalidad (RF23)? Según el formato, todos, menos el estado del arte, que solo aplica a investigación y desarrollo tecnológico (Anexo J).
- [x] ¿El F-DC-124 se usa también para Seminario? No (lo confirmó el equipo). Su informe final sí usa el F-DC-125.
- [x] Concepto del evaluador sobre la propuesta: Aprobado, No aprobado o Aplazado, como en el F-DC-124 (manda sobre el reglamento, RF22).
- [x] Prórrogas: hasta 3, como en el F-DC-124 (RF38).
- [x] Los 180 días se cuentan desde que el comité aprueba totalmente el FDC-124 (decisión del equipo del 2026-10-10, RF31, RF38). Antes se contaban desde la notificación, como en el F-DC-124.
- [x] El F-DC-124 tiene espacio para 3 estudiantes; RF13 permite hasta 4 en los interdisciplinarios. Se mantienen 4 (decisión del equipo, 2026-10-08).
- [x] ¿El estudiante puede solicitar su director y su codirector (lista del otro equipo, RF-42)? No: los asigna el comité (RF11, RF13; decisión del equipo, 2026-10-10).
- [x] ¿Cuándo pasa el proyecto de la fase 1 a la 2? Cuando el comité aprobó el pago de todos y asignó el director: queda así (confirmado el 2026-10-14).
- [x] La firma del director en el FDC-124 (RF30): ¿basta con su aprobación en el sistema o debe subir el formato firmado? Basta con la aprobación en el sistema (confirmado el 2026-10-14).
- [x] Fase final (RF39): ¿quién registra la sustentación en el sistema? El comité, como dice el reglamento (art. 26, literal m); el evaluador la atiende y los estudiantes la presentan (2026-10-14).
- [x] ¿La aprobación final del comité lleva acta? Sí, con número y fecha (confirmado el 2026-10-14).
- [x] El reglamento dice que el evaluador califica la sustentación (art. 21, literal e) con la rejilla del informe final (art. 31, parágrafo 4; criterio 16 del F-DC-129, "Sustentación"). En el sistema, el evaluador llena esa rejilla en la fase 5, antes de la sustentación. ¿Cómo se maneja ese criterio? Como en el sistema actual de la UTS: el evaluador completa y cierra toda la rejilla antes de que se programe la sustentación, y el criterio 16 queda como calificación provisional; un ajuste posterior lo maneja la coordinación (2026-10-14).
- [x] Seminario (no usa el F-DC-124): ¿qué hace el proyecto después del pago? Inscripción con recibo, F-AM-04 y documento; el comité la valida y el docente registra la nota final (2026-10-11).
- [x] Semana 12 vencida sin la propuesta aprobada (RF30): el trámite se cancela solo por extemporaneidad, la idea vuelve al banco y el pago no se reembolsa; solo planes anteriores (2026-10-11).
- [x] Confirmar que la nota aprobatoria del Seminario es 3.0 (RF17): confirmado (2026-10-11).
- [x] ¿Qué pasa si el comité aplaza o no aprueba la propuesta? Aplazada vuelve a la fase 2; no aprobada se cancela y la idea vuelve al banco (2026-10-11).
- [x] SNIES de Negocios Internacionales en el Campus Virtual (el 119351 quedó en la de Bucaramanga): se deja sin el dato (2026-10-14).
- [x] Informe final de los planes nuevos (RF42): se evalúa con concepto, sin nota, como en Academusoft (2026-10-11).
- [x] ¿Qué pasa si vence la fecha límite del informe final sin prórroga (RF38)? Se cancela la modalidad, la propuesta pierde vigencia y el estudiante empieza de nuevo (2026-10-11).
- [x] "Negocios Internacionales": universitaria, en Bucaramanga y en el Campus Virtual (confirmado por el equipo, 2026-10-10). SNIES 119351 (2026-10-11).
- [x] Confirmar los supuestos del 2026-10-10: 5 días hábiles del director (RF21) y consecutivo del código desde 1 en cada periodo (RF40). Confirmados (2026-10-11).
- [x] El 90 % de créditos de RF29 es para prácticas (lo confirmó el equipo), que están fuera del sistema; no es para Seminario.
- [x] Correos automáticos (A-16, A-25): **no se envían correos**; los avisos se muestran dentro del sistema (decisión del profesor).
- [x] Marca de agua de pago (37): es el recibo de pago con la marca "pagado" que se sube al inicio, en la fase 1 (A-07, RF29).
- [x] Valor del puntaje de exoneración (RNF14): estímulos del Acuerdo 01-009 para el nivel tecnológico (2026-10-06, [Anexo D](#anexo-d-estímulos-por-saber-tyt)).
- [x] ¿Hay estímulos para el nivel de ingeniería? Ingeniería presenta Saber Pro, que es aparte y no está en el sistema; los estímulos de RNF14 son solo para tecnología (Saber TyT).
- [x] Alcance y resultado esperado del proyecto.
- [x] Plan de trabajo por sprints: `docs/sprints.md` (2026-09-30).
- [x] Duración de los sprints: sin duración fija. Entrega del parcial: en un mes aproximadamente (por confirmar).

## Anexo A: notas de la entrevista

Fuente: notas a mano del equipo (4 páginas de cuaderno), transcritas el 2026-09-26.

- Se conservan la numeración y los dos bloques del cuaderno: "Requisitos de la web" y "Cosas a definir".
- Solo se corrigió la ortografía; el contenido va como está escrito.
- **[?]** marca una palabra que no se lee con seguridad. El equipo debe confirmarla o corregirla.
- El texto tachado en el cuaderno no se incluye; cuando cambia el sentido, se menciona en la nota.
- El punto 36 fue eliminado por el equipo; la numeración no se corre, para que las referencias entre puntos (por ejemplo, "lo mismo que el 7") sigan siendo válidas.
- Estos puntos están fusionados con los audios en la tabla de [Requerimientos](#requerimientos); allí se ve en qué RF o RNF quedó cada uno (columna Origen).

### Requisitos de la web (1 a 21)

| N.º | Requisito | Nota de transcripción |
| --- | --- | --- |
| 1 | Login. | Con correo institucional y contraseña (A-10). "Recordarme" y "¿La olvidaste?" son solo visuales por ahora |
| 2 | El administrador, dentro de su panel, debe crear usuarios y poder modificarlos. |
| 3 | El administrador debe tener un panel CRUD para los roles. |
| 4 | Que tenga un panel CRUD para los proyectos. |
| 5 | Panel donde se suba la idea de proyecto propuesta por el coordinador. |
| 6 | Panel para asignar coordinador y evaluador a proyectos o anteproyectos que se estén realizando. |
| 7 | Informe del estado del proyecto en alumnos, director y evaluador (fase del proyecto). |
| 8 | Debe tener un hipervínculo al calendario académico. |
| 9 | Panel de descripción e información de las modalidades de proyecto de grado. |
| 10 | Módulo donde se seleccionen los proyectos. |
| 11 | CRUD para subir los anteproyectos. |
| 12 | Que salga el nombre del docente director y evaluador (Admin). |
| 13 | Módulo para que el estudiante vea la información del anteproyecto. |
| 14 | Lo mismo del requerimiento número 7. |
| 15 | Módulo para calificar proyectos subidos por los alumnos. |
| 16 | Que el director pueda ver la información del alumno. |
| 17 | Aprobar o reprobar el anteproyecto. |
| 18 | Lo mismo que el requisito 7 y 14. |
| 19 | Módulo del anteproyecto para el evaluador, donde verá los proyectos aprobados por el director. |
| 20 | Aprobar o desaprobar los anteproyectos para los alumnos. |
| 21 | Lo mismo que el requisito 7, 14 y 18. |

### Cosas a definir (22 a 55)

| N.º | Punto | Nota de transcripción |
| --- | --- | --- |
| 22 | Director y evaluador no pueden ser el mismo usuario. |
| 23 | Un alumno no puede tener más de 1 proyecto. |
| 24 | El estudiante, el director y el evaluador tienen un tiempo asignado para las funciones (calificar, aprobar, subir). |
| 25 | Firma del director. |
| 26 | Pasar por firma Turnitin. |
| 27 | Formato institucional en Word y lo demás en PDF. |
| 28 | Entregar el proyecto en 90 días. |
| 29 | Aprobación por parte del director: aprueba formato 129. |
| 30 | Rechazo por tiempo. |
| 31 | Poder pedir prórroga (2). |
| 32 | Si se vence la prórroga, poder volver a escoger otra modalidad. |
| 33 | PQR (colocar comentario). |
| 34 | El proyecto debe estar finalizado para hacer los papeles de derecho de grado. |
| 35 | Cada vez que acabe una etapa debe haber un campo de observación. |
| 37 | Marca de agua de pago a la hora de subir. |
| 38 | Cumplir con los créditos aprobados. | Ya se registra el % de créditos del estudiante; falta revisarlo en la fase 0 (A-07) |
| 39 | Si el proyecto es de dos personas y uno es excluido, el otro debe finalizarlo. |
| 40 | Se subió el puntaje [?] para exoneración. |
| 41 | Alertas cuando esté próximo a cerrar: a los 30 días y a los 15 días. |
| 42 | Deben estar todas las modalidades. |
| 43 | El director y el evaluador tienen 5 días para aprobarlo o rechazarlo. |
| 44 | Que mande un email de alerta. |
| 45 | El estudiante puede subir la propuesta. |
| 46 | Cada proyecto tiene un código asignado. Ejemplos: `65-2026-1/200` para proyectos de tecnología y `125-2026-1/200` para proyectos de ingeniería. |
| 47 | En cada movimiento debe llegar un correo; dependiendo del movimiento, le llega a uno o a otro. |
| 48 | Calendario de cuándo se cierran las fechas. |
| 49 | Filtros de búsqueda para cada fase: por integrante, por título, por docente y por palabra. |
| 50 | El nivel del estudiante, para poder escoger la idea según sea nivel tecnológico o de ingeniería. |
| 51 | Poder cambiar la modalidad sin perder el proceso, antes de mandar el 124. |
| 52 | MySQL. |
| 53 | Que se vaya guardando el progreso de cada fase (FD-124, FD-125, FD-126). |
| 54 | Hay proyectos multidisciplinarios de 3 o 4 estudiantes. |
| 55 | Poner la carrera que cursa el estudiante. |

## Anexo B: audios de la entrevista

Fuente: transcripción de 6 audios de la sesión con el profesor, entregada por el equipo el 2026-10-05. Son los mismos requerimientos que el equipo escribió en esa sesión (Anexo A, del punto 26 en adelante); por eso están fusionados en la tabla de [Requerimientos](#requerimientos). Vienen clasificados como RF o RNF y se numeran **A-01 a A-31** en el orden de los audios. La columna **Relación** indica con qué puntos de las notas se cruza cada uno.

| ID | Tipo | Requerimiento | Relación |
| --- | --- | --- | --- |
| A-01 | RF | El informe final (FDC-125) se puede entregar como mínimo 90 días después de aprobado el FDC-124, y como máximo a los 180. El sistema bloquea la entrega antes de los 90 días. | Complementa 28 y 53 |
| A-02 | RF | El FDC-125 debe ir con el reporte antiplagio Turnitin y con el formato FDC-129. | Complementa 26 y 29 |
| A-03 | RF | Si pasan 180 días sin terminar, el proyecto se cierra. Para evitarlo se pide una prórroga unos 8 días antes. Se permiten hasta 2 prórrogas de 180 días, y cada una cuesta una matrícula (unos $600–700 mil). Si se vencen todas, el proyecto se cancela y el estudiante no puede repetir esa modalidad. | Complementa 30, 31 y 32 |
| A-04 | RNF | PQR: un botón arriba para hacer peticiones en cualquier fase, por ejemplo pedir cambio de director o evaluador. | Complementa 33 |
| A-05 | RF | El proyecto tiene que quedar en estado "finalizado" (fase 5) para poder radicar papeles de grado. | Complementa 34 |
| A-06 | RF | En cada aprobación del director o del evaluador, el campo de observación es obligatorio. | Complementa 35 |
| A-07 | RF | Fase 0: elegir una idea del banco o proponer una que sea aprobada, subir el recibo de pago con la marca "pagado" y cumplir los créditos aprobados (~75 % para desarrollo, 90–100 % para práctica). | Complementa 10, 37, 38 y 45 |
| A-08 | Alcance | Todas las modalidades excepto prácticas. | Confirma 42 y la decisión de no incluir prácticas |
| A-09 | RNF | Colores y tamaño de letra no importan. | Se quitó de la lista oficial (decisión del 2026-10-06) |
| A-10 | RF | El ingreso es solo con correo institucional. | Complementa 1 |
| A-11 | RF | El sistema avanza por fases 1 a 5, y cada cambio de fase requiere aprobación. | Complementa 7 y 53 |
| A-12 | RF | El FDC-124 debe aprobarse dentro de las primeras 12 semanas del semestre. Si no, queda para el siguiente. | Complementa 48 |
| A-13 | RF | El FDC-124 lleva firma del director y Turnitin. Los formatos institucionales van en Word y los anexos en PDF. | Complementa 25, 26 y 27 |
| A-14 | RF | El orden de aprobación es director → evaluador → comité. El comité es el filtro final y devuelve el proyecto si falta algo, por ejemplo una firma. | Complementa 17, 19 y 20 |
| A-15 | Sin clasificar | El sistema muestra la fase del proyecto y un contador de días en la fase 4. | Complementa 7 |
| A-16 | RF | Se envían alertas por correo al director, al evaluador y a los estudiantes cuando faltan 30 días y cuando faltan 5–10 días para el vencimiento. | Cambia 41 (antes 30 y 15 días) y complementa 44. Sin correo: los avisos van dentro del sistema |
| A-17 | RF | El director debe ser distinto al evaluador. | Confirma 22 |
| A-18 | RF propuesto | El director o el evaluador tiene 5 días para aprobar o rechazar. No hay aprobación automática si no responde. Está en la norma, no en el software actual. | Complementa 43 |
| A-19 | RF | El estudiante no puede ver quién es su evaluador, para evitar presiones. | Cambia lo del PPT (el estudiante veía al evaluador) y el 12 |
| A-20 | RNF | Que el estudiante proponga una idea es opcional. | Complementa A-07 |
| A-21 | RF | El banco de ideas debe tener ideas disponibles para elegir. | Complementa 5 y 10 |
| A-22 | RF | Todas las modalidades permiten 1 o 2 integrantes, menos la monografía, que es individual. | Complementa 54 (ver la decisión del 2026-10-05) |
| A-23 | RNF | En un proyecto de dos, si uno queda exonerado por las pruebas Saber TyT, el otro sigue hasta el final. El exonerado puede renunciar a la exoneración y seguir, pero después no puede echarse atrás. | Complementa 39 y 40 |
| A-24 | RF | Cada proyecto tiene un código único con el formato prefijo-año-periodo-consecutivo. El prefijo es 65 para tecnología y 125 para ingeniería. | Complementa 46. El equipo confirmó el prefijo 125 para ingeniería |
| A-25 | RF | Notificaciones automáticas al correo institucional en cada movimiento (aprobado, rechazado, revisión habilitada). También recordatorios de vencimiento con la sugerencia de pedir prórroga, que le llegan al director. | Complementa 44 y 47. Sin correo: los avisos van dentro del sistema |
| A-26 | RNF | Enviar el reporte de PQR. | Complementa 33 |
| A-27 | RF | El calendario tiene fechas configurables: el banco de ideas cierra en la semana 4, las propuestas se reciben hasta la semana 12 y hay fechas de informe final. Se actualizan a mano cada semestre. | Complementa 8 y 48 |
| A-28 | RF | Buscador único con filtros por fase, integrante, proyecto, título, docente, periodo o palabra. | Complementa 49 |
| A-29 | RF | El nivel del estudiante limita las ideas: un estudiante de tecnología no puede elegir ideas de ingeniería. | Complementa 50 |
| A-30 | RF | Toda idea, venga de un docente o de un estudiante, la aprueba el comité. | Complementa 5 |
| A-31 | RF (hoy RNF) | Cambio de modalidad (por ejemplo, de monografía a desarrollo) sin rechazar todo el proyecto, solo antes de aprobar el FDC-124. Hoy se hace modificando la base de datos a mano. | Complementa 51 |

### Contexto adicional de los audios

No son requerimientos, pero sirven para entender el sistema:

- Antes todo se manejaba en Excel. El sistema actual lo desarrolló como trabajo de grado un estudiante, John Gómez, a quien se podría entrevistar.
- Hay quejas por la carga de proyectos entre docentes. Por ahora el software lo usa solo el programa de Sistemas; Industrial rechazó el piloto porque su proceso es distinto.
- El profesor de la materia solo permite una tecnología (Java).
- En los audios los formatos se llaman **FDC**-124, FDC-125 y FDC-129; en la primera entrevista estaban como FD-124, FD-125 y FD-126.

## Anexo C: Reglamento de Trabajo de Grado

Fuente: Acuerdo 01-026 del Consejo Directivo de las UTS (27 de julio de 2021), entregado por el equipo el 2026-10-06. Archivo: `C:\Users\juanp\Desktop\Universidad\QUINTO SEMESTRE\PROGRAMACION EN JAVA\SEGUNDO CORTE\reglamento de trabajo de grado.pdf` (27 páginas, 74 artículos).

- Es la fuente oficial: donde no coincide con la entrevista, manda el reglamento (decisión del 2026-10-06). Donde no coincide con el formato F-DC-124 (2023), manda el formato (decisión del 2026-10-08, Anexo J).
- La columna **Dónde quedó** dice en qué requerimiento quedó cada artículo. **Fuera del sistema** marca trámites que maneja otra dependencia u otro sistema; el equipo puede pedir que se incluyan.
- El reglamento no habla de fases, de formatos por número (FDC-124, etc.) ni de la exoneración por Saber TyT.

| Artículos | Qué dice | Dónde quedó |
| --- | --- | --- |
| 1–7 | Objeto del reglamento y definición de trabajo de grado, propuesta e informe final. | Contexto, no son requerimientos |
| 2 | Dos regímenes: planes aprobados antes y después del decreto 1330 de 2019. En los planes nuevos, la propuesta se aprueba en Seminario de Grado I o III y el trabajo se desarrolla en Seminario de Grado II o IV. | RF7, RF41, RF42 |
| 8 | Modalidades: Proyecto de investigación, Desarrollo tecnológico, Monografía, Seminario, Práctica y Emprendimiento. El nivel Técnico Profesional solo puede hacer Práctica. | RF4 (sin Práctica ni Técnico Profesional) |
| 9 | Todo trabajo de grado deja al menos un producto tangible. | Informativo |
| 10–11 | El estudiante elige la modalidad. Individual o hasta 2 estudiantes; hasta 3 en Proyecto de investigación y Desarrollo tecnológico. | RF36 |
| 12–13 | Pago del derecho pecuniario (hasta la semana 8 en los planes anteriores) y vigencia solo por el periodo del pago. Propuesta aprobada hasta la semana 12. | RF3, RF30, RF32 |
| 13 par. 4 | Devolución del 80 % del pago del Seminario por enfermedad grave. | Fuera del sistema (trámite financiero) |
| 14 | 180 días calendario desde la aprobación de la propuesta para terminar, con el visto bueno del director y del evaluador. | RF31, RF38, RF39. El equipo decidió contarlos desde la aprobación total del FDC-124 |
| 15 | Planes nuevos: sin Seminario de Grado II o IV matriculado no hay asesoría ni se recibe el informe final. Los docentes de carrera tienen tiempo asignado para dirigir. | RF42. La carga docente queda fuera del sistema |
| 16 | Prórrogas: hasta 2 por periodos iguales, pedidas antes del vencimiento y pagando otra vez; cancelación después de 3 periodos. El Seminario no tiene prórroga; en los planes nuevos no hay prórrogas. | RF17, RF38, RF42. Según el F-DC-124, hasta 3 prórrogas |
| 17 | La coordinación hace el registro académico de la modalidad del estudiante. | RF9 |
| 18 | Director: lo encarga la coordinación y lo formaliza el comité. En el Seminario es el docente que lo orienta; en los planes nuevos, el docente del seminario de grado. | RF11, RF17, RF41, RF42 |
| 18 par. 2 y 32 par. 1 | En el Seminario, el docente que lo orienta es director y evaluador. | **No se aplica:** el equipo decidió que nunca se evalúa el proyecto que se dirige (RF11) |
| 19 | Funciones del director: orientar, asesorar, al menos 2 seguimientos antes del informe final, informar plagios y evaluar el informe final. Presentar trabajos para distinción y velar por la propiedad intelectual. | RF14, RF20. Distinción y propiedad intelectual: fuera del sistema |
| 20–21 | Evaluador: lo encarga la coordinación después de la firma del director y lo formaliza el comité. Aplica la rejilla institucional; 3 días hábiles para la propuesta (aprobado, aprobado con correcciones o no aprobado) y 5 días hábiles para el informe final; atiende la sustentación y emite la calificación (art. 21, literal e). En los planes nuevos, el director y el evaluador de la propuesta son el mismo docente (art. 20 par. 2). | RF11, RF14, RF21, RF22, RF23 (rejilla), RF39 (atiende la sustentación). Resultados de la propuesta según el F-DC-124: aprobado, aplazado o no aprobado. Lo del mismo docente **no se aplica** (decisión del equipo, RF11) |
| 22 | Trabajos interdisciplinarios: director de la disciplina principal, hasta 2 codirectores y un evaluador por programa. | RF13 |
| 23 | Conformación del comité de trabajo de grado. | Usuarios y roles |
| 24 | El comité sesiona cada semana, deja actas, decide con al menos 3 miembros y publica su calendario de sesiones. | RF3, RF16 |
| 25 | Las decisiones del comité se notifican en máximo 2 días hábiles. | RF5 |
| 26 | Funciones del comité: aprobar director, evaluador y propuestas; gestionar prórrogas; informes estadísticos; listados de aprobados. También estrategias de producción científica, mejoramiento y distinciones, y "coordinar las sustentaciones y divulgación de los Informes Finales" (literal m). | RF11, RF14, RF15, RF38, RF39 (programa la sustentación). Lo demás, fuera del sistema |
| 27 | Propuesta: tema del banco de ideas o propuesto por el estudiante si el comité lo considera viable. En el Seminario la presenta el docente. Procedimiento de la Práctica. | RF10, RF17. Práctica: no aplica |
| 28 | Aprobación de la propuesta: plantilla institucional, formato firmado por el director y concepto del evaluador; el comité da el concepto final. Planes nuevos: semanas 8 a 14 y 15; la nota del curso es 20 % + 20 % + 60 %. | RF14, RF30, RF41. La nota del curso la registra el docente en el sistema académico: fuera del sistema |
| 29 | Planes nuevos: desistir de la propuesta aprobada y presentar una nueva; revisión si el estudiante se ausenta 2 semestres. | RF41 |
| 30–31 | Informe final: se entrega al comité con el formato firmado por el director, no antes de 3 meses de aprobada la propuesta; se divulga y se sustenta. | RF31 |
| 32 | Valoración del informe final: aplazado, aprobado o no aprobado; tercer evaluador si no hay consenso; cualitativa en los planes anteriores y nota en los nuevos. | RF22, RF42. El tercer evaluador se quitó (decisión del 2026-10-06) |
| 33 | Planes nuevos: si no termina o no aprueba, matricula otra vez Seminario de Grado II o IV; dos periodos en investigación y desarrollo tecnológico. | RF42 |
| 34 | Si el informe final no se aprueba, nueva propuesta sobre otro tema. | RF22 |
| 35–38 | Distinción, publicación en el Repositorio Institucional y registro de productos en el Banco de Proyectos. | Fuera del sistema (Dirección de Investigaciones y repositorio) |
| 39–44 | Proyecto de investigación y Monografía: descripción y requisitos (75 % de créditos y Metodología). | RF4, RF29 |
| 45–50 | Seminario: descripción, aval del comité, mínimo 25 estudiantes, 160 horas, 90 % de créditos y procedimiento. | RF4, RF17, RF29 |
| 51–54 | Desarrollo tecnológico: descripción, requisitos, producto funcional. Registro del software ante Derechos de Autor y carta de donación del producto. | RF4, RF29. Registro y donación: fuera del sistema |
| 55–61 | Práctica. | No aplica: las prácticas no se incluyen |
| 62–66 | Emprendimiento: descripción, requisitos y plan de negocios. | RF4, RF29 |
| 67 | El valor de los derechos pecuniarios lo fija el Consejo Directivo. | RF32 |
| 68–70 | Comité de ética y propiedad intelectual. | Fuera del sistema |
| 71–74 | Transición y disposiciones finales. | Informativo |

## Anexo D: estímulos por Saber TyT

Fuente: texto entregado por el equipo el 2026-10-06, transcrito tal cual. Corresponde al Acuerdo 01-009 de la UTS y cubre solo el nivel tecnológico. Quedó en RNF14.

> Estímulos según el puntaje en Saber T&T (Nivel Tecnológico). Conforme al Acuerdo No. 01-009 de la UTS, los beneficios por obtener un puntaje destacado son:

| Puntaje | Beneficio |
| --- | --- |
| 120 a 150 | Exención del informe final (aprobado) o del Seminario de Grado II con calificación de 4.5. |
| 151 a 170 | Exención del informe final (aprobado) o del Seminario de Grado II con calificación de 4.7, más un 50 % de beca en los derechos de grado. |
| 171 o más | Exención del informe final (aprobado) o del Seminario de Grado II con calificación de 5.0, más el 100 % de beca en los derechos de grado. |


## Anexo E: detalle de los requerimientos

Versión completa de cada requerimiento, antes de resumir la lista oficial (2026-10-06; ampliada el 2026-10-08 con la lista de otro equipo). Tiene todos los casos y plazos de la entrevista y del reglamento; sirve como referencia al programar cada uno.

| ID | Detalle |
| --- | --- |
| RF1 | El ingreso al sistema (login) es solo con correo institucional: @uts.edu.co o @correo.uts.edu.co. |
| RF2 | Informe del estado del proyecto (fase) para alumnos, director y evaluador. El sistema muestra la fase del proyecto y un contador de días en la fase 4. |
| RF3 | Hipervínculo al calendario académico. El calendario tiene fechas configurables que se actualizan a mano cada semestre: el banco de ideas cierra en la semana 4, el pago va hasta la semana 8, la propuesta se aprueba hasta la semana 12 y hay fechas de informe final. En los planes nuevos, las propuestas se presentan entre las semanas 8 y 14 y el comité las estudia hasta la semana 15. Al inicio del periodo se publica el calendario de sesiones del comité. **Cambio (2026-10-06): el calendario muestra las fechas del informe final, no antes de 90 días y máximo a los 180.** **Cambio (2026-10-08): El comité crea, activa y cierra los periodos académicos (lista de otro equipo, RF-21).** |
| RF4 | Panel de descripción e información de las modalidades de grado: Proyecto de investigación, Desarrollo tecnológico, Monografía, Seminario y Emprendimiento (todas las del reglamento, excepto Práctica). |
| RF5 | Avisos dentro del sistema (sin correo, por decisión del profesor) en cada movimiento (aprobado, rechazado, revisión habilitada), dirigidos a quien corresponda. Las decisiones del comité se notifican al director y a los estudiantes en máximo 2 días hábiles, y el comité publica los resultados de sus sesiones. También alertas de vencimiento cuando faltan 30 días y cuando faltan 5–10 días, para el director, el evaluador y los estudiantes, con la sugerencia de pedir prórroga. |
| RF6 | Buscador único con filtros por fase, integrante, proyecto, título, docente, periodo o palabra. **Cambio (2026-10-08): Cada rol busca solo en lo suyo: el estudiante en sus propios proyectos (por código o título, con su estado, fase y fechas), el director en los proyectos que dirige y el evaluador en los que evalúa (lista de otro equipo, RF-35 a RF-38).** |
| RF7 | El administrador, dentro de su panel, crea usuarios y puede modificarlos; de cada estudiante se registran su carrera, su nivel y si su plan de estudios es anterior o posterior al decreto 1330 de 2019, porque el reglamento aplica reglas distintas a cada uno. **Cambio (2026-10-06): el administrador (que es el comité) registra solo a los docentes, con cédula, correo y nombre completo. Los estudiantes se registran solos (ver el registro del estudiante).** **Cambio (2026-10-08): El administrador busca y filtra usuarios por documento, nombre, correo, rol, programa académico, nivel, tipo de plan y estado de la cuenta; puede desactivar una cuenta sin borrar su historial, y actualiza los datos académicos de los estudiantes (porcentaje de créditos, Metodología aprobada y plan de estudios), que cambian cada semestre. Los estudiantes se siguen registrando solos (RF24): un profesor explicó que un administrador no puede registrar a más de 500 estudiantes (lista de otro equipo, RF-05, RF-07 a RF-09, adaptados).** |
| RF8 | El administrador tiene un panel CRUD para los roles. |
| RF9 | Panel CRUD para los proyectos. La coordinación hace el registro académico de la modalidad de cada estudiante. |
| RF10 | Banco de ideas: panel donde se suben las ideas de proyecto. Las propone el coordinador, y el estudiante puede proponer la suya (es opcional) si el comité la considera viable. Toda idea, venga de un docente o de un estudiante, la aprueba el comité. El banco debe tener ideas disponibles para elegir. **Cambio (2026-10-06): las ideas las registran los docentes y el estudiante puede formular su propia propuesta; el comité (el administrador) aprueba ambas.** |
| RF11 | Panel para asignar a los proyectos su coordinador, director y evaluador. La coordinación encarga al director y al evaluador, docentes de la misma disciplina o perfil del programa, y el comité formaliza la designación cuando se presenta la propuesta por primera vez. Un docente puede ser director de un proyecto y evaluador de otro, pero nunca evaluador del proyecto que dirige, sin excepciones (decisión del equipo, que se aparta del reglamento en el Seminario y en la propuesta de los planes nuevos). **Cambio (2026-10-10): El estudiante no puede pedir su director; los asigna el comité (decisión del equipo, lista de otro equipo RF-42). El evaluador se puede asignar después del director.** |
| RF12 | Se puede cambiar la modalidad (por ejemplo, de monografía a desarrollo) sin rechazar todo el proyecto ni perder el proceso, solo antes de aprobar el FDC-124. **Cambio (2026-10-08): El estudiante solicita el cambio de modalidad y el comité lo aprueba o lo rechaza; el sistema no lo permite después de aprobado el FDC-124. Queda registro de la modalidad anterior, la nueva, quién lo pidió, la decisión, quién la tomó y la fecha; hoy se hace a mano en la base (A-31) (lista de otro equipo, RF-82 a RF-85).** |
| RF13 | Un Proyecto de investigación o un Desarrollo tecnológico puede ser interdisciplinario: el director es de la disciplina principal y puede haber hasta 2 codirectores de las otras disciplinas, que también avalan la propuesta y el informe final. Ambos documentos se entregan al comité del programa de cada autor; el comité de la disciplina principal hace la evaluación y pide un evaluador a cada comité de los otros programas. **Cambio (2026-10-06): máximo 4 estudiantes en los proyectos interdisciplinarios (el reglamento, art. 11, dice hasta 3).** |
| RF14 | Aprobación en orden director → evaluador → comité: el director firma el formato que avala la propuesta o el informe final; con esa firma, la coordinación entrega los documentos al evaluador, que da su concepto; el comité da el concepto final, sea cual sea el del evaluador, y devuelve el proyecto si falta algo, por ejemplo una firma. **Cambio (2026-10-08): La decisión del comité sobre la propuesta queda asociada al proyecto y con su acta (lista de otro equipo, RF-70 y RF-71).** |
| RF15 | El comité saca informes estadísticos de las modalidades de grado de cada periodo y listados de los estudiantes que aprueban o no el informe final. **Cambio (2026-10-06): los informes también van por modalidad y por cantidad de estudiantes.** |
| RF16 | El comité sesiona cada semana durante el periodo académico, y de forma extraordinaria cuando haga falta. De cada sesión queda un acta, y sus decisiones requieren al menos 3 de sus miembros. |
| RF17 | Modalidad Seminario: el docente que lo orienta propone el tema a partir de una idea validada del banco de ideas y presenta la propuesta al comité, que la avala ante el Consejo de Facultad (tecnológico) o el Consejo Académico (universitario). Se ofrece con mínimo 25 estudiantes (con 160 horas en los planes anteriores). El docente que lo orienta es el director (el evaluador es otro docente, RF11) y avala el desempeño y los productos de los estudiantes, que luego evalúa el comité. Solo dura su periodo académico y no tiene prórroga. **Cambio (2026-10-08): Seminario no usa el F-DC-124 (lo confirmó el equipo); su informe final sí usa el F-DC-125.** **Cambio (2026-10-11): proceso entregado por el equipo: el estudiante se inscribe con el recibo de pago, el formato F-AM-04 y el documento de identidad ampliado al 150 %; la coordinación (en el sistema, el comité) valida la inscripción y asigna el grupo y su docente; las clases duran 16 semanas y el entregable va en Atena; al final, el docente registra la nota en Academusoft (en el sistema, la registra el director del proyecto). Con la nota aprobatoria se cumple el requisito de grado.** |
| RF18 | Módulo para que el director califique los proyectos subidos por los alumnos. **Cambio (2026-10-08): El estudiante envía la propuesta al director; el director la revisa y deja observaciones de forma y contenido antes de dar su aval; después de una evaluación, revisa las correcciones y dice si el proyecto sigue (lista de otro equipo, RF-43, RF-44, RF-64 y RF-94).** |
| RF19 | El director puede ver la información del alumno. |
| RF20 | El director registra al menos 2 seguimientos académicos antes de la entrega del informe final, para avalarlo, recomendar cambios o reorientarlo. También informa al comité los posibles plagios que detecte. |
| RF21 | El estudiante, el director y el evaluador tienen un tiempo asignado para sus funciones (subir, calificar, aprobar). El evaluador tiene 3 días hábiles para dar su concepto sobre la propuesta y 5 días hábiles para evaluar el informe final; el director tiene 5 días para aprobar o rechazar. No hay aprobación automática si no responden. |
| RF22 | Resultados de la evaluación, con la rejilla institucional. Propuesta: aprobado, aprobado con correcciones o no aprobado. Informe final: aplazado (el evaluador indica las correcciones y el plazo máximo; corregido, el director pide otra evaluación), aprobado o no aprobado; el plagio comprobado es causa de no aprobación. En los planes anteriores la evaluación del informe final es cualitativa; en el Seminario no existe "aplazado". Si el informe final no se aprueba, el estudiante empieza de nuevo con una propuesta sobre otro tema. **Cambio (2026-10-06): si el informe final no se aprueba (por ejemplo, por plagio), se devuelve para corrección (parafraseo) y el estudiante tiene hasta antes de la fecha de vencimiento. Se aparta del reglamento (art. 34, propuesta nueva con otro tema).** **Cambio (2026-10-08): según el F-DC-124 (manda sobre el reglamento), el concepto sobre la propuesta es Aprobado, No aprobado o Aplazado; ya no existe "aprobado con correcciones".** |
| RF23 | Rejilla institucional del F-DC-124 (reglamento, arts. 20 y 21: el evaluador aplica la rejilla). El evaluador abre la propuesta con sus datos y sus versiones; la evaluación ya trae los datos de la propuesta, los estudiantes, la modalidad y el evaluador. Marca *Cumple: Sí* o *No* en cada criterio que aplica a la modalidad: ficha técnica, descripción del problema, justificación, objetivos, estado del arte, fundamento teórico, resultados esperados, plan de actividades y presupuesto, y los demás que pida el formato vigente. Puede dejar observaciones por criterio y una general, y guardar la evaluación en borrador. No puede enviarla mientras falte algún criterio, y para dar el concepto "Aprobado" deben cumplirse todos. Cuando la envía, el estudiante y el director ven las observaciones. Se conserva cada evaluación: evaluador, fecha, respuestas, observaciones y concepto (lista de otro equipo, RF-56 a RF-62, RF-66 a RF-68). **Cambio (2026-10-08): según el F-DC-124 versión 2.0 (Anexo J), la rejilla tiene 12 criterios (los 9 anteriores más consideraciones éticas, referencias bibliográficas y resumen de similitud), cada uno con sus indicadores (28 en total), y el *Sí/No* se marca en cada indicador. El estado del arte solo aplica a Proyecto de investigación y Desarrollo tecnológico: "la monografía y emprendimiento no llevan estado de arte". Para dar "Aprobado" se deben cumplir todos los criterios que aplican a la modalidad. El formato tiene una sola sección de observaciones generales; las observaciones por indicador vienen de la lista del otro equipo.** **Cambio (2026-10-08): Seminario no usa el F-DC-124. El informe final se evalúa con la rejilla del F-DC-129 versión 2 (Anexo K): 17 criterios y 40 indicadores; ahí el evaluador puede marcar N/A ("si algún ítem no aplica dependiendo de la modalidad se debe marcar con N/A"), y para "Aprobado" deben cumplirse todos los que aplican. El concepto final es Aprobado, No aprobado o Aplazado.** |
| RF24 | El estudiante se registra solo en el sistema, con su correo institucional (RF1). Al registrarse indica su carrera y su nivel (puntos 50 y 55) y si su plan de estudios es anterior o posterior al decreto 1330 de 2019 (reglamento, art. 2). Los docentes, en cambio, los registra el administrador. **Cambio (2026-10-08): Al registrarse, el estudiante también indica su porcentaje de créditos aprobados y si aprobó Metodología de la investigación o un curso equivalente; el administrador puede corregirlos o actualizarlos (RF7) (lista de otro equipo, RF-08, adaptado: allá los registra el administrador).** |
| RF25 | Módulo donde el estudiante selecciona la idea de proyecto. El nivel del estudiante limita las ideas: un estudiante de tecnología no puede elegir ideas de ingeniería. **Cambio (2026-10-08): Después de la fecha de cierre del banco del periodo no se pueden tomar ideas (lista de otro equipo, RF-30).** |
| RF26 | CRUD para que el estudiante suba la propuesta y el anteproyecto. **Cambio (2026-10-08): Además de la propuesta y el informe final, el estudiante sube los entregables que pida su modalidad: evidencias del desarrollo, manual de usuario, código fuente u otros documentos (lista de otro equipo, RF-86 y RF-88).** |
| RF27 | Se muestra el nombre del docente director y del evaluador (administración). El estudiante no puede ver quién es su evaluador, para evitar presiones. |
| RF28 | Módulo para que el estudiante vea la información de su anteproyecto. |
| RF29 | Fase 1 (antes llamada fase 0): el estudiante elige una idea del banco o propone una que sea aprobada, sube el recibo de pago con la marca de agua "pagado" (cuando aplica, RF32) y cumple los requisitos de la modalidad. Planes anteriores: Proyecto de investigación, Monografía, Desarrollo tecnológico y Emprendimiento piden el 75 % de los créditos (o todos los cursos hasta el 4.º semestre en tecnológico o hasta el 3.º en universitario); Seminario pide el 90 %; y todas, tener aprobado el curso de Metodología de la investigación o uno similar. Planes nuevos: cumplir los requisitos de matrícula de Seminario de Grado I o III. **Cambio (2026-10-06): es la fase 1, "seleccionar la idea y pagar". El equipo pide 90 % de créditos en prácticas (el reglamento pide 90 % en Seminario).** **Cambio (2026-10-08): el equipo confirma que el 90 % de créditos es para prácticas, que están fuera del sistema (como en A-07); no es para Seminario. En el sistema, todas las modalidades piden el 75 % y Metodología de la investigación.** **Cambio (2026-10-10): la fase 1 se llama "Pago": el estudiante describe su idea (la toma del banco o formula la suya) y sube el pago.** |
| RF30 | La propuesta se presenta al comité en la plantilla institucional, con el formato firmado por el director y el concepto del evaluador. El FDC-124 lleva la firma del director y el reporte de Turnitin. En los planes anteriores, la propuesta debe aprobarse dentro de las primeras 12 semanas del semestre; si no, queda para el siguiente y el pago de ese periodo no sirve. Sin la propuesta aprobada no se puede desarrollar el trabajo. Los formatos institucionales van en Word y los anexos en PDF. **Cambio (2026-10-08): el F-DC-124 pide que el informe de similitud (Turnitin) dé entre 0 y 10 %; es un indicador de la rejilla (RF23).** **Cambio (2026-10-11): si vence la semana 12 sin la propuesta aprobada, "el trámite se cancela por extemporaneidad" y el pago no se reembolsa ni se abona; el sistema cancela el proyecto solo y la idea vuelve al banco (texto y decisiones del equipo).** |
| RF31 | El informe final (FDC-125) se entrega al comité con el formato firmado por el director que indica que está listo para evaluar, el reporte de Turnitin y el formato FDC-129, que aprueba el director. Se entrega como mínimo 90 días (3 meses) y como máximo 180 días después de aprobada la propuesta; el sistema bloquea la entrega antes del mínimo. El estudiante debe prever entregarlo antes de los 180 días para alcanzar a corregir lo que pida el evaluador. En los planes nuevos, el plazo es el del Seminario de Grado II o IV (RF42). **Cambio (2026-10-08): según el F-DC-124, los 180 días se cuentan desde la notificación de la aprobación al estudiante; el mínimo de 90 días sigue contando desde la aprobación.** **Cambio (2026-10-10): los 90 días mínimos y los 180 máximos se cuentan desde que el comité aprueba totalmente el FDC-124 (decisión del equipo; reemplaza lo de la notificación).** |
| RF32 | Pago del derecho pecuniario de la modalidad. Planes anteriores: se paga antes de presentar la propuesta, hasta la semana 8; el del Seminario, antes de que empiece. Planes nuevos: lo cubre la matrícula del Seminario de Grado, salvo en la modalidad Seminario, que se paga antes de la semana 8. El pago solo vale para el periodo en que se hizo: si la propuesta no se aprueba en ese periodo, no sirve para el siguiente. **Cambio (2026-10-08): El estudiante consulta el estado y la vigencia de su pago, que se controla según el periodo y su tipo de plan (lista de otro equipo, RF-79 a RF-81).** **Cambio (2026-10-10): El comité revisa el recibo: lo aprueba o lo devuelve con observación; si lo devuelve, el estudiante sube otro dentro del plazo. Con el pago aprobado (o si no aplica) y el director asignado, el proyecto pasa a la fase 2 (decisión del equipo; el paso de fase se confirmó el 2026-10-14).** **Cambio (2026-10-10): Cada estudiante del proyecto sube su propio recibo y el comité revisa el de cada uno; el proyecto pasa a la fase 2 cuando todos tienen el pago al día (decisión del equipo).** |
| RF33 | Habilitación para la fase 1: el estudiante consulta su información académica y si cumple los requisitos para empezar (RF29). Según su tipo de plan (anterior o nuevo) el sistema aplica las reglas que le corresponden; si le falta algo, le dice qué requisito le impide seguir y le muestra solo las modalidades para las que sí está habilitado (lista de otro equipo, RF-11, RF-12 y RF-20). |
| RF34 | En cada aprobación del director o del evaluador, y al terminar cada etapa, el campo de observación es obligatorio. |
| RF35 | Un alumno no puede tener más de un proyecto a la vez. |
| RF36 | Integrantes: el trabajo de grado es individual o de hasta 2 estudiantes; en Proyecto de investigación y Desarrollo tecnológico se aceptan hasta 3. El número depende de la complejidad y el impacto del tema. **Cambio (2026-10-08): El estudiante registra a sus compañeros de proyecto, y antes de enviar la propuesta el sistema valida la cantidad de integrantes y que todos cumplan los requisitos (lista de otro equipo, RF-33 y RF-34).** **Cambio (2026-10-10): El compañero queda en el proyecto de una vez, sin invitación; los integrantes se cambian en las fases 1 y 2 y el grupo se cierra al enviar la propuesta; cada uno sube su recibo de pago (decisiones del equipo).** |
| RF37 | El proyecto avanza por fases de la 1 a la 5; cada cambio de fase requiere aprobación, y se va guardando el progreso de cada fase. **Cambio (2026-10-06): fases del equipo: 1 seleccionar la idea y pagar, 2 presentación de la idea al comité, 3 desarrollo de la idea, 4 ajustes, 5 sustentación.** **Cambio (2026-10-08): el FDC-124 (propuesta) se aprueba en la fase 2 (presentación de la idea al comité), antes de desarrollar; el FDC-125 (informe final) se entrega al terminar el desarrollo, en la fase 4 (ajustes), donde el director lo avala y el evaluador lo califica con el F-DC-129; la fase 5 es la sustentación (texto del equipo, Anexo K).** **Cambio (2026-10-10): fases del sistema actual de la UTS (pantalla del seguimiento del director) y del texto del equipo (Anexo H): 0 aprobación de la idea; 1 pago; 2 propuesta I; 3 propuesta II; 4 informe I; 5 informe II; fase final, sustentación. Reemplaza las fases del 2026-10-06.** |
| RF38 | Planes anteriores: hay 180 días calendario desde la aprobación de la propuesta para terminar, con el visto bueno del director y del evaluador. Si no alcanza, se pide prórroga al comité antes del vencimiento (unos 8 días antes), por otro periodo igual, hasta 2 veces seguidas; cada prórroga exige pagar otra vez el derecho pecuniario de la modalidad, salvo en Proyecto de investigación y Desarrollo tecnológico si la avala la Dirección de Investigaciones y Extensión. Quien no la pide a tiempo pierde el derecho al servicio. Si pasan los 3 periodos de 180 días sin terminar, se cancela la modalidad y el estudiante debe presentar una nueva propuesta (o hacer el Seminario), pagando de nuevo. El Seminario no tiene prórroga: solo dura su periodo académico. **Cambio (2026-10-08): según el F-DC-124 (manda sobre el reglamento), se permiten hasta 3 prórrogas, y los 180 días se cuentan desde la notificación de la aprobación al estudiante.** **Cambio (2026-10-10): los 180 días se cuentan desde la aprobación total del FDC-124 (decisión del equipo).** **Cambio (2026-10-11): texto del reglamento entregado por el equipo: al expirar el tiempo sin haber culminado ni tramitado una prórroga, se cancela la modalidad, se pierden los derechos sobre la propuesta aprobada y se inicia un proceso nuevo (otra propuesta o cambio de modalidad, como Seminario de Grado). El sistema la cancela solo.** |
| RF39 | El proyecto debe quedar en estado "finalizado" (fase 5) para poder radicar los papeles de grado. Queda finalizado cuando el informe final está aprobado, con el visto bueno del director y del evaluador. **Cambio (2026-10-06): el estado "finalizado" se da después de la fase 5.** **Cambio (2026-10-10): en la fase final, estudiantes, director y evaluador programan la sustentación, y el sistema guarda la fecha y el lugar (decisión del equipo; lista de otro equipo, RF-95).** **Cambio (2026-10-13): la registra en el sistema cualquiera de los estudiantes, el director o el evaluador, y se puede reprogramar; después de la fecha de la sustentación, el comité registra la aprobación final (lista de otro equipo, RF-97, que hace el administrador) con observación y acta, y el proyecto queda "Finalizado". Quién la registra y el acta eran propuesta de Claude (resuelto el 2026-10-14: la programa el comité y la aprobación final lleva acta).** **Cambio (2026-10-14): la programa y la reprograma el comité, como dice el reglamento (art. 26, literal m: "coordinar las sustentaciones"); el evaluador la atiende y la califica (art. 21, literal e) y los estudiantes la presentan. Los estudiantes, el director, los codirectores y el evaluador la ven y reciben el aviso (decisión del equipo).** |
| RF40 | Cada proyecto tiene un código único con el formato prefijo-año-periodo-consecutivo: 65 para tecnología y 125 para ingeniería (por ejemplo, 65-2026-1/200 y 125-2026-1/200). |
| RF41 | Planes nuevos, propuesta: se presenta y aprueba en el curso Seminario de Grado I (tecnológico) o III (universitario). El docente del curso es el director de la propuesta (el evaluador es otro docente, RF11) y la presenta con su aval al comité entre las semanas 8 y 14; el comité las estudia hasta la semana 15. Sin la propuesta aprobada no se aprueba el curso. Si el estudiante desiste de una propuesta aprobada, presenta una nueva y renuncia a la anterior; si no la tiene aprobada antes de la semana 8, no puede matricular Seminario de Grado II o IV el periodo siguiente. Si se ausenta 2 semestres seguidos, el director y el comité revisan la propuesta para actualizarla. |
| RF42 | Planes nuevos, desarrollo: el trabajo se desarrolla en Seminario de Grado II (tecnológico) o IV (universitario); su docente es el director, y el evaluador del informe final lo designa la coordinación. Sin esa materia matriculada, el estudiante no recibe asesoría ni se le recibe el informe final. No hay prórrogas: si no termina o no aprueba el informe final, matricula otra vez Seminario de Grado II o IV. En Proyecto de investigación y Desarrollo tecnológico se pueden dar dos periodos seguidos si el cronograma lo pide y lo avalan el director y el comité. La evaluación del informe final es una nota, que es la del Seminario de Grado II o IV. **Cambio (2026-10-11): el informe final se evalúa con concepto, sin nota, porque el sistema actual de la UTS (Academusoft) sigue con el esquema cualitativo (respuesta del equipo).** |
| RF43 | Versiones de los documentos: después de cada observación (del director, del evaluador o del comité) el estudiante sube una versión nueva de la propuesta o del informe final, con los soportes que le pidan. El sistema conserva todas las versiones, cada una con quién la subió y la fecha y hora, y la versión aprobada queda marcada como la oficial (lista de otro equipo, RF-45, RF-47, RF-63, RF-76 y RF-93). |
| RNF1 | PQR: un botón arriba para hacer peticiones con comentario en cualquier fase (por ejemplo, pedir cambio de director o evaluador), y envío del reporte de PQR. |
| RNF12 | Auditoría de cada cambio de estado: quién, qué y cuándo. **Cambio (2026-10-08): el administrador consulta la auditoría con filtros por usuario, proyecto, tipo de acción y rango de fechas, y ve quién hizo el cambio, qué cambió y cuándo; cada proyecto tiene su historial cronológico de estados, fases, documentos, evaluaciones y decisiones (lista de otro equipo, RF-10 y RF-39).** |
| RNF14 | En un proyecto de dos, si uno es excluido o queda exonerado por las pruebas Saber TyT, el otro sigue hasta el final. El exonerado puede renunciar a la exoneración y seguir, pero después no puede echarse atrás. Estímulos por puntaje en Saber TyT (nivel tecnológico, Acuerdo 01-009): de 120 a 150 puntos, exención del informe final (aprobado) o del Seminario de Grado II con 4.5; de 151 a 170, con 4.7 y 50 % de beca en los derechos de grado; 171 o más, con 5.0 y 100 % de beca. **Cambio (2026-10-08): los estímulos son solo para el nivel tecnológico (pruebas Saber TyT). Los de ingeniería presentan Saber Pro, que es algo aparte y no está en el sistema.** |
| RNF22 | La base de datos es MySQL. |

## Anexo F: lista de requisitos no funcionales

Fuente: lista entregada por el equipo el 2026-10-06, transcrita tal cual. La columna **Dónde quedó** dice qué RNF de la lista oficial le corresponde; los dos de correo no se incluyeron y los de tecnología se adaptaron al proyecto (decisión del 2026-10-06).

| ID | Categoría | Perfil | Fases | Requisito | Dónde quedó |
| --- | --- | --- | --- | --- | --- |
| RNF-01 | Rendimiento | Todos los perfiles | Todas | Páginas en menos de 3 s con 100 usuarios concurrentes. | RNF2 |
| RNF-02 | Rendimiento | Todos los perfiles | Todas | Búsquedas con filtros en menos de 2 s con 5.000 proyectos. | RNF3 |
| RNF-03 | Rendimiento | Estudiante, Docente director | 2 y 4 | Subida de archivos de hasta 10 MB. | RNF15 |
| RNF-04 | Seguridad | Todos los perfiles | Todas | Contraseñas con hash bcrypt. | RNF4, adaptado: SHA-256, que es lo que ya usa el sistema |
| RNF-05 | Seguridad | Todos los perfiles | Todas | Control de acceso por rol en el servidor con javax.servlet.Filter. | RNF5, adaptado: fragmentos `.jspf` (el proyecto es JSP + JSTL sobre Jakarta) |
| RNF-06 | Seguridad | Sistema | Todas | Todas las consultas usan PreparedStatement. | RNF18, adaptado: `<sql:param>`, que por dentro usa PreparedStatement |
| RNF-07 | Seguridad | Todos los perfiles | Todas | La sesión expira a los 30 minutos de inactividad. | RNF6 |
| RNF-08 | Seguridad | Estudiante, Docente director | 2 y 4 | Validar en el servidor tipo (.docx, .pdf) y tamaño de archivo. | RNF16 |
| RNF-09 | Seguridad | Todos los perfiles | Todas | Cumplir la Ley 1581 de 2012. | RNF7 |
| RNF-10 | Seguridad | Administrador | Todas | Auditoría (quién, qué, cuándo) en cada cambio de estado. | RNF12 |
| RNF-11 | Disponibilidad y confiabilidad | Todos los perfiles | Todas | Disponibilidad del 99% en horario académico. | RNF8 |
| RNF-12 | Disponibilidad y confiabilidad | Administrador | Todas | Copia de seguridad diaria, retención de 30 días. | RNF13 |
| RNF-13 | Disponibilidad y confiabilidad | Sistema | Todas | Los plazos los calcula el servidor en zona America/Bogota. Los días hábiles excluyen fines de semana y festivos de Colombia, guardados en una tabla. | RNF19 |
| RNF-14 | Disponibilidad y confiabilidad | Sistema | Todas | Si falla un correo, se reintenta sin perder el evento. | **No se incluye:** no se envían correos (decisión del profesor) |
| RNF-15 | Usabilidad | Todos los perfiles | Todas | Diseño responsivo con Bootstrap. | RNF9 |
| RNF-16 | Usabilidad | Estudiante | 1 | Un estudiante nuevo sube su propuesta en máximo 5 clics. | RNF17 |
| RNF-17 | Usabilidad | Todos los perfiles | Todas | Mensajes de error claros y en español. | RNF10 |
| RNF-18 | Usabilidad | Todos los perfiles | Todas | Compatible con Chrome, Edge y Firefox (últimas 2 versiones). | RNF11 |
| RNF-19 | Mantenibilidad | Equipo de desarrollo | Todas | Arquitectura MVC: Servlet, JSP, DAO. | RNF23, adaptado: JSP + JSTL (tema del parcial) |
| RNF-20 | Mantenibilidad | Equipo de desarrollo | Todas | Fragmentos .jspf para elementos repetidos. | RNF24 |
| RNF-21 | Mantenibilidad | Equipo de desarrollo | Todas | Código documentado y versionado con Git. | RNF25 |
| RNF-22 | Compatibilidad y portabilidad | Equipo de desarrollo | Todas | Funciona en Tomcat 9 y MySQL 8. | RNF22, adaptado: Tomcat 11 (Jakarta) y MySQL |
| RNF-23 | Compatibilidad y portabilidad | Equipo de desarrollo | Todas | UTF-8 y utf8mb4 en todo el sistema. | RNF26 |
| RNF-24 | Compatibilidad y portabilidad | Equipo de desarrollo | Todas | Conexión a base de datos con pool (DataSource de Tomcat). | **Quitado:** el equipo lo borró del Word (2026-10-06) |
| RNF-25 | Escalabilidad e integración | Sistema | Todas | Soporta 3 veces más usuarios sin cambiar el diseño. | RNF20 |
| RNF-26 | Escalabilidad e integración | Sistema | Todas | Correos por SMTP con cuenta institucional. Respetar el límite diario de envíos del proveedor. | **No se incluye:** no se envían correos (decisión del profesor) |
| RNF-27 | Escalabilidad e integración | Sistema | Todas | Las tareas automáticas (alertas, cierres, rechazo por tiempo) corren como proceso programado del servidor. | RNF21, adaptado: se revisan cada vez que alguien usa el sistema |


## Anexo G: equivalencia de la numeración

El 2026-10-06 los RF y los RNF se renumeraron en el orden de los grupos por rol, para que salgan seguidos en el Word. Esta tabla da el número anterior de cada uno; los documentos ya usan el nuevo. Ese mismo día se renumeró otra vez (se quitó el tercer evaluador y se agregó el registro del estudiante, entonces RF23 y hoy RF24); la columna **2026-10-06** tiene el número de ese día. Los de Coordinación quedaron en el grupo Administrador.

El 2026-10-08 se agregaron RF23 (rejilla del F-DC-124), RF33 (habilitación) y RF43 (versiones), tomados de la lista de otro equipo ([Anexo I](#anexo-i-lista-de-requerimientos-de-otro-equipo)); los que estaban después subieron de número. La columna **Ahora** tiene el número vigente. Los RNF no cambiaron.

| Antes | 2026-10-06 | Ahora | Rol |
| --- | --- | --- | --- |
| RF1 | RF1 | RF1 | Todos |
| RF7 | RF2 | RF2 | Todos |
| RF8 | RF3 | RF3 | Todos |
| RF9 | RF4 | RF4 | Todos |
| RF28 | RF5 | RF5 | Todos |
| RF30 | RF6 | RF6 | Todos |
| RF2 | RF7 | RF7 | Administrador |
| RF3 | RF8 | RF8 | Administrador |
| RF4 | RF9 | RF9 | Administrador |
| RF5 | RF10 | RF10 | Administrador |
| RF6 | RF11 | RF11 | Administrador |
| RF26 | RF12 | RF12 | Administrador |
| RF35 | RF13 | RF13 | Administrador |
| RF16 | RF14 | RF14 | Administrador |
| RF34 | Quitado | Quitado | — |
| RF37 | RF15 | RF15 | Administrador |
| RF39 | RF16 | RF16 | Administrador |
| RF40 | RF17 | RF17 | Administrador |
| RF14 | RF18 | RF18 | Director |
| RF15 | RF19 | RF19 | Director |
| RF36 | RF20 | RF20 | Director |
| RF18 | RF21 | RF21 | Evaluador |
| RF33 | RF22 | RF22 | Evaluador |
| — | — | RF23 | Evaluador (nuevo) |
| — | RF23 | RF24 | Estudiante |
| RF10 | RF24 | RF25 | Estudiante |
| RF11 | RF25 | RF26 | Estudiante |
| RF12 | RF26 | RF27 | Estudiante |
| RF13 | RF27 | RF28 | Estudiante |
| RF21 | RF28 | RF29 | Estudiante |
| RF23 | RF29 | RF30 | Estudiante |
| RF24 | RF30 | RF31 | Estudiante |
| RF38 | RF31 | RF32 | Estudiante |
| — | — | RF33 | Estudiante (nuevo) |
| RF17 | RF32 | RF34 | Sistema |
| RF19 | RF33 | RF35 | Sistema |
| RF20 | RF34 | RF36 | Sistema |
| RF22 | RF35 | RF37 | Sistema |
| RF25 | RF36 | RF38 | Sistema |
| RF27 | RF37 | RF39 | Sistema |
| RF29 | RF38 | RF40 | Sistema |
| RF31 | RF39 | RF41 | Sistema |
| RF32 | RF40 | RF42 | Sistema |
| — | — | RF43 | Sistema (nuevo) |
| RNF2 | RNF1 | RNF1 | Todos |
| RNF4 | RNF2 | RNF2 | Todos |
| RNF5 | RNF3 | RNF3 | Todos |
| RNF7 | RNF4 | RNF4 | Todos |
| RNF8 | RNF5 | RNF5 | Todos |
| RNF10 | RNF6 | RNF6 | Todos |
| RNF12 | RNF7 | RNF7 | Todos |
| RNF14 | RNF8 | RNF8 | Todos |
| RNF17 | RNF9 | RNF9 | Todos |
| RNF19 | RNF10 | RNF10 | Todos |
| RNF20 | RNF11 | RNF11 | Todos |
| RNF13 | RNF12 | RNF12 | Administrador |
| RNF15 | RNF13 | RNF13 | Administrador |
| RNF3 | RNF14 | RNF14 | Estudiante |
| RNF6 | RNF15 | RNF15 | Estudiante, Director |
| RNF11 | RNF16 | RNF16 | Estudiante, Director |
| RNF18 | RNF17 | RNF17 | Estudiante |
| RNF9 | RNF18 | RNF18 | Sistema |
| RNF16 | RNF19 | RNF19 | Sistema |
| RNF26 | RNF20 | RNF20 | Sistema |
| RNF27 | RNF21 | RNF21 | Sistema |
| RNF1 | RNF22 | RNF22 | Equipo de desarrollo |
| RNF21 | RNF23 | RNF23 | Equipo de desarrollo |
| RNF22 | RNF24 | RNF24 | Equipo de desarrollo |
| RNF23 | RNF25 | RNF25 | Equipo de desarrollo |
| RNF24 | RNF26 | RNF26 | Equipo de desarrollo |
| RNF25 | Quitado | Quitado | — |

## Anexo H: fases del proyecto

Fuente: texto del equipo y foto del seguimiento del director en el sistema actual de la UTS (sistemastg), entregados el 2026-10-10. Reemplazan las fases del 2026-10-06 (ver abajo). Quedó en RF37 (fases), RF29 (fase 1) y RF39 (fase final).

| Fase | Nombre (sistema actual) | Qué pasa |
| --- | --- | --- |
| 0 | Aprobación de la idea | El comité aprueba la idea del proyecto. |
| 1 | Pago | El estudiante describe su idea y sube el pago. En este sistema, el proyecto se crea aquí, cuando el estudiante toma una idea aprobada. |
| 2 | Propuesta I | El estudiante diligencia el FDC-124 y envía la propuesta al director. |
| 3 | Propuesta II | El director revisa la propuesta y la pasa por Turnitin; puede devolverla a la fase 2 por faltas. La envía al evaluador y al comité. |
| 4 | Informe I | El evaluador analiza la propuesta; puede devolverla a la fase 3 para arreglos. Cuando el comité aprueba totalmente el FDC-124 empieza el FDC-125 y desde ahí corren los 180 días para entregarlo; el estudiante envía el informe al director. |
| 5 | Informe II | El director envía el informe al evaluador y al comité. |
| Final | Sustentación | Estudiantes, director y evaluador programan la sustentación; el sistema guarda la fecha y el lugar. Después el proyecto queda "finalizado" (RF39). **Cambio (2026-10-14): la programa el comité, como dice el reglamento (art. 26, literal m); el evaluador la atiende y los estudiantes la presentan.** |

Texto del equipo, tal cual: "124, 180 días para entregar el 125. Fase 0 aprueban la idea del proyecto, fase 1 subir el proyecto, fase 2 estudiante tiene empezar diligenciar el formato 124 y tiene 180 días para presentarlo y aprobarlo, fase 3 revisar el proyecto el director, donde se puede devolver a fase 2 por faltas del proyecto, en la fase 3 queda a manos del director y pasarlo por Turnitin, fase 4 el evaluador empieza a analizarlo, puede devolverlo a fase 3 para hacer arreglos, queda en fase 4, pasa a fase 5 de sustentación. En la fase 4 se inicia el FDC-125 cuando el FDC-124 sea aprobado por el comité. Fase 3 el director envía propuesta a evaluador y comité. Fase 5 el director envía el informe al evaluador y comité. Fase final estudiantes, director y programan sustentación."

Fases anteriores (2026-10-06, reemplazadas): 1 seleccionar la idea y pagar, 2 presentación de la idea al comité, 3 desarrollo de la idea, 4 ajustes, 5 sustentación. La creación del usuario no era una fase.

## Anexo I: lista de requerimientos de otro equipo

Fuente: lista de requerimientos funcionales de otro equipo (RF-01 a RF-100), entregada el 2026-10-08, transcrita tal cual. Está organizada en secciones: 2.1 Usuarios y administración (RF-01 a RF-10), 2.2 Fase 0, habilitación académica (RF-11 a RF-20), 2.3 Periodos, calendario y Banco de Ideas (RF-21 a RF-30), 2.4 Proyecto y registro de la propuesta (RF-31 a RF-50), 2.5 Director, Evaluador, Comité y evaluación de la propuesta (RF-51 a RF-77), 2.6 Pagos y cambio de modalidad (RF-78 a RF-85) y 2.7 Desarrollo, Informe Final, sustentación y cierre (RF-86 a RF-100).

- Se tomó lo que no choca con las decisiones del equipo (decisión del 2026-10-08). La columna **Dónde quedó** dice si ya estaba, en qué requerimiento se sumó, si es un requerimiento nuevo o por qué no se incluye.
- Esa lista usa 5 roles, con un **Comité** aparte del Administrador. En este proyecto **el administrador es el comité** (decisión del 2026-10-06): lo que allá hace el Comité, aquí lo hace el Administrador.

| ID | Actor | Requerimiento | Dónde quedó |
| --- | --- | --- | --- |
| RF-01 | Todos los usuarios | El sistema deberá permitir a los usuarios registrados iniciar sesión mediante sus credenciales. | Ya estaba: RF1 |
| RF-02 | Sistema | El sistema deberá autenticar las credenciales e identificar el rol del usuario como Estudiante, Docente Director, Docente Evaluador, Comité o Administrador. | Ya estaba: RF1, RNF5, con 4 roles (el comité es el administrador) |
| RF-03 | Sistema | El sistema deberá mostrar únicamente las funcionalidades y la información autorizadas para el rol del usuario autenticado. | Ya estaba: RNF5 |
| RF-04 | Administrador | El sistema deberá permitir al Administrador crear cuentas de usuario. | Ya estaba: RF7. El administrador crea solo a los docentes; los estudiantes se registran solos (RF24) |
| RF-05 | Administrador | El sistema deberá permitir al Administrador modificar los datos de una cuenta y activar o desactivar su acceso sin eliminar su historial. | Se sumó a RF7 |
| RF-06 | Administrador | El sistema deberá permitir al Administrador asignar o modificar los roles de usuario, limitándolos a los cinco roles definidos para la réplica. | Ya estaba: RF8, con 4 roles |
| RF-07 | Administrador | El sistema deberá permitir al Administrador registrar y actualizar para cada Estudiante la carrera o programa académico, el nivel de formación y el tipo de plan de estudios, indicando si es anterior o posterior al Decreto 1330 de 2019. | Se sumó a RF7 y RF24, adaptado: el estudiante los registra al registrarse y el administrador los actualiza |
| RF-08 | Administrador | El sistema deberá permitir al Administrador registrar y actualizar el porcentaje de créditos aprobados y el estado de aprobación de Metodología para la Elaboración de Proyectos, Metodología de la Investigación o su equivalente. | Se sumó a RF24 y RF7, adaptado como RF-07 |
| RF-09 | Administrador | El sistema deberá permitir al Administrador buscar y filtrar usuarios por identificación, nombre, correo, rol, programa académico, nivel de formación, tipo de plan o estado de la cuenta. | Se sumó a RF7 |
| RF-10 | Administrador | El sistema deberá permitir al Administrador consultar y filtrar la auditoría por usuario, proyecto, entidad afectada, tipo de acción y rango de fechas, visualizando quién realizó el cambio, qué cambió y cuándo ocurrió. | Se sumó a RNF12 |
| RF-11 | Estudiante | El sistema deberá permitir al Estudiante consultar su información académica registrada y conocer si se encuentra habilitado para iniciar el proceso de Trabajo de Grado. | Nuevo: RF33 |
| RF-12 | Sistema | El sistema deberá determinar, a partir del tipo de plan registrado por el Administrador, si al Estudiante se le aplican las reglas de un plan anterior o posterior al Decreto 1330 de 2019. | Ya estaba: RF29, RF41, RF42; se usa en RF33 |
| RF-13 | Sistema | El sistema deberá reconocer como modalidades de Trabajo de Grado: Proyecto de Investigación, Desarrollo Tecnológico, Monografía, Seminario, Práctica y Emprendimiento. | Ya estaba: RF4, sin Práctica (fuera del alcance) |
| RF-14 | Sistema | El sistema deberá restringir al Estudiante del nivel Técnico Profesional a la modalidad Práctica, de acuerdo con el Reglamento de Trabajo de Grado. | No se incluye: Práctica y Técnico Profesional están fuera del alcance |
| RF-15 | Sistema | Para planes anteriores al Decreto 1330, el sistema deberá habilitar Proyecto de Investigación, Monografía, Desarrollo Tecnológico y Emprendimiento únicamente cuando el Estudiante tenga al menos el 75 % de los créditos aprobados y haya aprobado Metodología para la Elaboración de Proyectos, Metodología de la Investigación o su equivalente. | Ya estaba: RF29 |
| RF-16 | Sistema | Para planes anteriores al Decreto 1330, el sistema deberá habilitar la modalidad Seminario únicamente cuando el Estudiante tenga al menos el 90 % de los créditos aprobados y haya aprobado Metodología para la Elaboración de Proyectos, Metodología de la Investigación o su equivalente. | Ya estaba: RF29 (ver el pendiente del 90 %) |
| RF-17 | Sistema | Para planes anteriores al Decreto 1330, el sistema deberá habilitar la modalidad Práctica cuando el Estudiante tenga al menos el 90 % de los créditos aprobados y haya aprobado Metodología para la Elaboración de Proyectos, Metodología de la Investigación o su equivalente; para el nivel Técnico Profesional deberá aceptar como mínimo el 70 % de los créditos aprobados. | No se incluye: Práctica y Técnico Profesional están fuera del alcance |
| RF-18 | Sistema | Para planes posteriores al Decreto 1330, el sistema deberá validar los requisitos de matrícula y aprobación de Seminario de Grado I o III y de los espacios académicos acreditables Seminario de Grado II o IV que correspondan al nivel y a la etapa del proceso. | Ya estaba: RF41, RF42 |
| RF-19 | Sistema | El sistema deberá validar que el Trabajo de Grado tenga máximo dos Estudiantes y solo permitirá hasta tres integrantes en Proyecto de Investigación o Desarrollo Tecnológico cuando el Comité registre la excepción institucional correspondiente. | No se incluye: decisión del equipo (RF36 y RF13: hasta 3 en investigación y desarrollo tecnológico y hasta 4 en interdisciplinarios, sin excepción caso por caso) |
| RF-20 | Sistema | Cuando el Estudiante no cumpla una condición de Fase 0, el sistema deberá indicar de forma explícita el requisito académico que impide continuar y mostrar únicamente las modalidades para las que sí se encuentra habilitado. | Nuevo: RF33 |
| RF-21 | Comité | El sistema deberá permitir al Comité crear, activar, cerrar y consultar los periodos académicos utilizados en la gestión de los Trabajos de Grado. | Se sumó a RF3 (lo hace el administrador) |
| RF-22 | Comité | El sistema deberá permitir al Comité parametrizar las fechas de inicio y cierre de las fases, actividades y plazos del proceso para cada periodo académico. | Ya estaba: RF3 |
| RF-23 | Todos los usuarios | El sistema deberá permitir a los usuarios consultar el calendario vigente del proceso de Trabajos de Grado. | Ya estaba: RF3 |
| RF-24 | Comité | El sistema deberá permitir al Comité crear, modificar, habilitar o cerrar las ideas registradas en el Banco de Ideas. | Ya estaba: RF10 (las registran los docentes y las aprueba el administrador) |
| RF-25 | Comité | El sistema deberá permitir al Comité establecer la fecha de apertura y la fecha de cierre del Banco de Ideas para cada periodo académico. | Ya estaba: RF3 (el banco cierra en la semana 4 del periodo) |
| RF-26 | Estudiante | El sistema deberá permitir al Estudiante consultar las ideas disponibles en el Banco de Ideas mientras el periodo se encuentre abierto. | Ya estaba: RF25 |
| RF-27 | Sistema | El sistema deberá mostrar al Estudiante únicamente las ideas compatibles con su programa, nivel de formación y condiciones académicas registradas. | Ya estaba: RF25 (nivel) y RF33 (requisitos). Las ideas no tienen programa, así que no se filtran por programa |
| RF-28 | Estudiante | El sistema deberá permitir al Estudiante seleccionar una idea disponible del Banco de Ideas como base para su propuesta. | Ya estaba: RF25 |
| RF-29 | Estudiante | El sistema deberá permitir al Estudiante registrar una propuesta propia cuando no seleccione una idea existente del Banco de Ideas. | Ya estaba: RF10, RF29 |
| RF-30 | Sistema | El sistema deberá impedir nuevas selecciones del Banco de Ideas cuando se haya alcanzado la fecha de cierre parametrizada para el periodo académico. | Se sumó a RF25 |
| RF-31 | Estudiante | El sistema deberá permitir al Estudiante crear un proyecto únicamente después de superar las validaciones de Fase 0. | Ya estaba: RF29; se apoya en RF33 |
| RF-32 | Sistema | El sistema deberá asignar a cada proyecto un código o identificador único que se conserve durante todo el proceso. | Ya estaba: RF40 |
| RF-33 | Estudiante | El sistema deberá permitir al Estudiante registrar a los demás integrantes del proyecto cuando el Trabajo de Grado sea desarrollado en equipo. | Se sumó a RF36 |
| RF-34 | Sistema | El sistema deberá validar la cantidad de integrantes y sus condiciones académicas antes de permitir enviar la propuesta. | Se sumó a RF36 |
| RF-35 | Estudiante | El sistema deberá permitir al Estudiante consultar sus propios proyectos y buscar dentro de ellos por código o título, visualizando su estado, fase y fechas relevantes. | Se sumó a RF6 (y RF28) |
| RF-36 | Docente Director | El sistema deberá permitir al Docente Director buscar y filtrar únicamente sus proyectos asignados por código, título, Estudiante, fase, estado o periodo académico. | Se sumó a RF6 |
| RF-37 | Docente Evaluador | El sistema deberá permitir al Docente Evaluador buscar y filtrar únicamente sus evaluaciones asignadas por código de proyecto, título, Estudiante, tipo de evaluación, estado o periodo académico. | Se sumó a RF6 |
| RF-38 | Comité | El sistema deberá permitir al Comité buscar y filtrar los proyectos del programa por código, título, Estudiante, Docente Director, Docente Evaluador, modalidad, fase, estado, periodo académico o palabras registradas en el proyecto. | Ya estaba: RF6 |
| RF-39 | Sistema | El sistema deberá mantener un historial cronológico de estados, fases, actuaciones, documentos, evaluaciones y decisiones de cada proyecto. | Se sumó a RNF12 |
| RF-40 | Estudiante | El sistema deberá permitir al Estudiante registrar el título, modalidad, modalidad específica, descripción del problema, justificación, objetivo general, objetivos específicos y demás información exigida por el formato F-DC-124 para la propuesta. | No se incluye: el F-DC-124 se sube en Word (RF30); sus campos no se repiten en el sistema |
| RF-41 | Estudiante | El sistema deberá permitir al Estudiante cargar el documento de propuesta diligenciado en el formato institucional F-DC-124 vigente. | Ya estaba: RF26, RF30 |
| RF-42 | Estudiante | El sistema deberá permitir al Estudiante seleccionar o solicitar un Docente Director y registrar un codirector cuando la propuesta requiera esta figura. | Ya estaba en parte: RF11 y RF13 (el administrador asigna director y codirectores). Que el estudiante pida su director no se incluye (decisión del equipo, 2026-10-10) |
| RF-43 | Estudiante | El sistema deberá permitir al Estudiante enviar la propuesta al Docente Director para revisión. | Se sumó a RF18 |
| RF-44 | Docente Director | El sistema deberá permitir al Docente Director revisar la propuesta y registrar observaciones de forma y contenido. | Se sumó a RF18 |
| RF-45 | Estudiante | El sistema deberá permitir al Estudiante cargar una nueva versión de la propuesta después de atender las observaciones del Docente Director. | Nuevo: RF43 |
| RF-46 | Docente Director | El sistema deberá permitir al Docente Director registrar el aval de la propuesta cuando considere que está lista para continuar con el proceso de evaluación. | Ya estaba: RF14, RF30 |
| RF-47 | Sistema | El sistema deberá conservar las versiones de la propuesta y relacionar cada versión con el usuario que la cargó y su fecha y hora. | Nuevo: RF43 |
| RF-48 | Estudiante | El sistema deberá permitir al Estudiante consultar el estado de revisión de la propuesta y las observaciones registradas por los responsables del proceso. | Ya estaba: RF28 (y RF23) |
| RF-49 | Estudiante | El sistema deberá permitir al Estudiante registrar en la propuesta el Grupo de Investigación al que se asocia el Trabajo de Grado y la Línea de Investigación correspondiente, de acuerdo con la información consignada en el F-DC-124 y el catálogo institucional vigente. | No se incluye por ahora: no hay catálogo de grupos de investigación |
| RF-50 | Sistema | El sistema deberá validar que la Línea de Investigación seleccionada pertenezca al Grupo de Investigación registrado y deberá conservar ambos datos como parte de la ficha oficial de la propuesta. | No se incluye por ahora: depende de RF-49 |
| RF-51 | Comité | El sistema deberá permitir al Comité formalizar la asignación del Docente Director y del codirector cuando corresponda. | Ya estaba: RF11, RF13 (lo hace el administrador) |
| RF-52 | Comité | El sistema deberá permitir al Comité asignar y formalizar un Docente Evaluador de acuerdo con el perfil y disponibilidad requeridos. | Ya estaba: RF11 (lo hace el administrador) |
| RF-53 | Sistema | El sistema deberá impedir que el mismo docente sea simultáneamente Docente Director y Docente Evaluador del Informe Final de un mismo proyecto. | Ya estaba: RF11 (más estricto: en ninguna etapa) |
| RF-54 | Sistema | Para la evaluación de propuestas de planes posteriores al Decreto 1330, el sistema deberá permitir la excepción reglamentaria en la que el docente de Seminario de Grado I o III actúa como Director y Evaluador de la propuesta cuando aplique. | No se incluye: decisión del equipo (un docente nunca evalúa el proyecto que dirige, RF11) |
| RF-55 | Docente Director / Docente Evaluador | El sistema deberá permitir al responsable autorizado registrar el resultado de la revisión de similitud mediante Turnitin cuando este control forme parte del procedimiento de la propuesta. | Ya estaba: RF30 (Turnitin siempre va) |
| RF-56 | Docente Evaluador | El sistema deberá permitir al Docente Evaluador abrir la propuesta asignada junto con sus datos generales, documento F-DC-124, versiones y soportes relacionados. | Nuevo: RF23 |
| RF-57 | Sistema | El sistema deberá precargar en la evaluación los datos generales de la propuesta, estudiantes, modalidad, programa y Docente Evaluador para evitar su digitación repetida. | Nuevo: RF23 |
| RF-58 | Sistema | El sistema deberá mostrar en la evaluación únicamente los criterios e indicadores aplicables a la modalidad de la propuesta. | Nuevo: RF23 |
| RF-59 | Docente Evaluador | El sistema deberá permitir al Docente Evaluador guardar una evaluación en borrador antes de enviarla de forma definitiva. | Nuevo: RF23 |
| RF-60 | Sistema | El sistema deberá impedir el envío definitivo de una evaluación mientras existan indicadores obligatorios sin responder. | Nuevo: RF23 |
| RF-61 | Docente Evaluador | El sistema deberá permitir al Docente Evaluador registrar observaciones generales y observaciones asociadas a los criterios de la propuesta. | Nuevo: RF23 |
| RF-62 | Sistema | El sistema deberá poner a disposición del Estudiante y del Docente Director las observaciones de la evaluación una vez esta sea enviada de forma definitiva. | Nuevo: RF23 |
| RF-63 | Estudiante | El sistema deberá permitir al Estudiante cargar la versión corregida de la propuesta y los soportes solicitados después de una evaluación. | Nuevo: RF43 |
| RF-64 | Docente Director | El sistema deberá permitir al Docente Director revisar las correcciones realizadas y registrar si la propuesta corregida puede continuar con el flujo correspondiente. | Se sumó a RF18 |
| RF-65 | Comité | El sistema deberá permitir al Comité consultar la propuesta, el aval del Docente Director, la evaluación, las correcciones y las versiones existentes antes de tomar una decisión. | Ya estaba: RF14; las versiones, en RF43 |
| RF-66 | Sistema | El sistema deberá conservar el historial de cada evaluación, incluyendo Docente Evaluador, fecha, respuestas, observaciones y concepto emitido. | Nuevo: RF23 |
| RF-67 | Docente Evaluador | El sistema deberá permitir al Docente Evaluador diligenciar la rejilla institucional del F-DC-124, marcando Cumple: Sí o No para los indicadores aplicables de ficha técnica, descripción del problema, justificación, objetivos, estado del arte, fundamento teórico, resultados esperados, plan de actividades, presupuesto y los demás criterios definidos por el formato vigente. | Nuevo: RF23 |
| RF-68 | Sistema | El sistema deberá validar que todos los criterios aplicables de la rejilla F-DC-124 estén registrados antes de permitir al Docente Evaluador emitir el concepto final; para emitir el concepto Aprobado deberán cumplirse todos los criterios aplicables. | Nuevo: RF23 |
| RF-69 | Docente Evaluador | El sistema deberá permitir al Docente Evaluador registrar el concepto final de la evaluación de la propuesta y las observaciones que lo sustentan. | Ya estaba: RF22, RF34 |
| RF-70 | Comité | El sistema deberá permitir al Comité registrar la decisión final de aprobación o no aprobación de la propuesta y asociarla al proyecto correspondiente. | Se sumó a RF14 |
| RF-71 | Comité | El sistema deberá permitir al Comité registrar el acta o soporte de la decisión tomada sobre la propuesta. | Se sumó a RF14 (y RF16) |
| RF-72 | Sistema | El sistema deberá informar al Estudiante y al Docente Director la decisión registrada por el Comité y la fecha en que fue emitida. | Ya estaba: RF5 |
| RF-73 | Sistema | El sistema deberá impedir que el Estudiante avance a la fase de desarrollo mientras la propuesta no se encuentre aprobada. | Ya estaba: RF30, RF37 |
| RF-74 | Sistema | El sistema deberá habilitar la fase siguiente únicamente cuando se cumplan las condiciones requeridas por el estado actual del proyecto. | Ya estaba: RF37 |
| RF-75 | Comité | El sistema deberá permitir al Comité devolver una propuesta a una etapa anterior cuando la decisión académica registrada así lo requiera, conservando la trazabilidad del cambio. | Ya estaba: RF14, RNF12 |
| RF-76 | Sistema | El sistema deberá conservar como versión oficial la propuesta aprobada, incluyendo el documento, los objetivos, el Grupo de Investigación y la Línea de Investigación registrados. | Nuevo: RF43 (el documento aprobado queda como versión oficial; los objetivos y el grupo no se registran aparte) |
| RF-77 | Sistema / Comité | Una vez aprobada la propuesta, el sistema deberá bloquear la edición directa del objetivo general y de los datos esenciales de la versión oficial; si se requiere modificarlos, el Comité deberá autorizar el cambio y el sistema deberá crear una nueva versión conservando el valor anterior en el historial. | No se incluye: el F-DC-124 se sube en Word (RF30); un cambio queda como versión nueva (RF43) |
| RF-78 | Estudiante | El sistema deberá permitir al Estudiante registrar o adjuntar la información del pago de la modalidad cuando dicho pago aplique. | Ya estaba: RF29, RF32 |
| RF-79 | Sistema | El sistema deberá asociar cada pago al Estudiante, proyecto, modalidad y periodo académico correspondientes. | Se sumó a RF32 |
| RF-80 | Estudiante | El sistema deberá permitir al Estudiante consultar el estado y la vigencia del pago registrado. | Se sumó a RF32 |
| RF-81 | Sistema | El sistema deberá controlar la vigencia del pago de acuerdo con el periodo académico y las reglas aplicables al tipo de plan de estudios y modalidad. | Se sumó a RF32 |
| RF-82 | Estudiante | El sistema deberá permitir al Estudiante solicitar un cambio de modalidad únicamente mientras el proyecto se encuentre en una etapa que permita realizarlo. | Se sumó a RF12 |
| RF-83 | Comité | El sistema deberá permitir al Comité aprobar o rechazar la solicitud de cambio de modalidad. | Se sumó a RF12 (lo hace el administrador) |
| RF-84 | Sistema | El sistema deberá impedir el cambio de modalidad cuando el proyecto haya superado la etapa autorizada para dicha modificación. | Se sumó a RF12 |
| RF-85 | Sistema | El sistema deberá conservar la trazabilidad del cambio de modalidad, registrando modalidad anterior, nueva modalidad, solicitante, decisión, responsable y fecha. | Se sumó a RF12 |
| RF-86 | Estudiante | El sistema deberá permitir al Estudiante cargar documentos y evidencias asociados al desarrollo del proyecto. | Se sumó a RF26 |
| RF-87 | Docente Director | El sistema deberá permitir al Docente Director revisar los documentos de desarrollo y registrar observaciones de seguimiento. | Ya estaba: RF20 |
| RF-88 | Estudiante | El sistema deberá permitir al Estudiante cargar el Informe Final y los entregables requeridos por la modalidad, incluyendo manual de usuario, código fuente u otros documentos cuando correspondan. | Se sumó a RF26 (y RF31) |
| RF-89 | Docente Director | El sistema deberá permitir al Docente Director revisar el Informe Final y registrar su aval cuando considere que se cumplieron los objetivos aprobados. | Ya estaba: RF14, RF31 |
| RF-90 | Sistema | El sistema deberá impedir el envío del Informe Final al Docente Evaluador mientras no exista el aval del Docente Director. | Ya estaba: RF14 |
| RF-91 | Docente Evaluador | El sistema deberá permitir al Docente Evaluador consultar el Informe Final avalado, sus entregables y los antecedentes necesarios para realizar la evaluación final. | Ya estaba: RF21, RF22 |
| RF-92 | Docente Evaluador | El sistema deberá permitir al Docente Evaluador registrar el resultado de la evaluación final, las observaciones y las correcciones solicitadas cuando correspondan. | Ya estaba: RF22 |
| RF-93 | Estudiante | El sistema deberá permitir al Estudiante cargar una versión corregida del Informe Final después de atender las observaciones de la evaluación. | Nuevo: RF43 |
| RF-94 | Docente Director | El sistema deberá permitir al Docente Director revisar las correcciones del Informe Final y solicitar una nueva evaluación cuando considere que fueron atendidas. | Se sumó a RF18 |
| RF-95 | Comité | El sistema deberá permitir al Comité programar la sustentación del Trabajo de Grado y registrar fecha, lugar o medio, participantes y estado de la actividad. | Se sumó a RF39: el sistema guarda la fecha y el lugar (decisión del equipo, 2026-10-10); desde el 2026-10-14 la programa el comité, como aquí y en el reglamento (art. 26) |
| RF-96 | Docente Evaluador | El sistema deberá permitir al Docente Evaluador registrar el resultado o concepto correspondiente a la sustentación cuando aplique. | No se incluye: depende de RF-95 |
| RF-97 | Comité | El sistema deberá permitir al Comité registrar la aprobación final del Trabajo de Grado cuando se hayan cumplido las condiciones académicas y documentales requeridas. | Ya estaba: RF39 (lo hace el administrador) |
| RF-98 | Sistema | El sistema deberá finalizar un proyecto únicamente cuando se encuentren completas las fases, evaluaciones, decisiones y entregables obligatorios. | Ya estaba: RF39 |
| RF-99 | Comité | El sistema deberá permitir al Comité gestionar la publicación de los documentos finales aprobados en el repositorio institucional y registrar restricciones de acceso por propiedad intelectual, propiedad industrial o secreto empresarial. | No se incluye: el repositorio y la propiedad intelectual quedan fuera del sistema (Anexo C, arts. 35–38 y 68–70) |
| RF-100 | Comité | El sistema deberá permitir al Comité registrar el cierre definitivo del proceso y dejar disponible el historial completo del proyecto para consulta posterior. | Ya estaba: RF39, RNF12 |

## Anexo J: formato F-DC-124 y su rejilla

Fuente: formato institucional **F-DC-124 versión 2.0**, *Propuesta de trabajo de grado: Investigación, Desarrollo Tecnológico, Monografía y Emprendimiento* (Docencia; aprobado en septiembre de 2023), entregado por el equipo el 2026-10-08. Los criterios y los indicadores van transcritos tal cual. Quedó en RF23 (rejilla), RF30 (similitud), RF22 (concepto), RF31 y RF38 (180 días y prórrogas). **Donde no coincide con el reglamento, manda el formato** (decisión del 2026-10-08).

### Rejilla de evaluación de la propuesta

El evaluador marca *Cumple: Sí* o *No* en cada indicador. Según el formato, "para emitir el concepto de Aprobado se deben cumplir todos los criterios que aplican para la modalidad que se está evaluando". Al final hay una sección de observaciones generales y el concepto final.

| Criterio | Indicadores | Modalidades |
| --- | --- | --- |
| Ficha técnica | ¿La ficha técnica relaciona toda la información requerida? | Todas |
| Descripción del problema | ¿Cumple el máximo de 20 líneas? · ¿Describe claramente la problemática a resolver? · ¿Se evidencia la pregunta concreta de investigación? (expresa la relación entre dos o más variables) · ¿Se ilustran citas bibliográficas en la redacción texto relevantes con respecto a la problemática? | Todas |
| Justificación | ¿Se evidencia por qué se debe realizar este trabajo de grado? · ¿Se argumenta la necesidad, la conveniencia, las implicaciones tecnológicas, sociales, económicas, entre otras?, es decir el para qué del trabajo a desarrollar? · ¿Genera un aporte al desarrollo de la investigación o al DTeI, del grupo de investigación o de las UTS? | Todas |
| Objetivos | ¿El objetivo general plantea una solución clara la problemática? · En el objetivo general y los específicos se evidencia: el ¿qué? ¿Cómo? y el ¿Para qué? · ¿El objetivo general tiene relación con el título de la propuesta de trabajo de grado? · ¿Hay relación entre el cómo del objetivo general y los objetivos específicos? · ¿Se mantiene un orden cronológico en los objetivos específicos? | Todas |
| Estado del arte | ¿Se referencian otros casos o estudios a nivel nacional e internacional relacionados con el tema? · ¿Se manejan las citas de acuerdo a la norma APA vigente? | Solo Proyecto de investigación y Desarrollo tecnológico ("la monografía y emprendimiento no llevan estado de arte") |
| Fundamento teórico | ¿Se evidencian los diferentes fundamentos teóricos, en el desarrollo de la propuesta de trabajo de grado? · ¿Los fundamentos teóricos son coherentes con la solución de la problemática? | Todas |
| Resultados esperados | ¿Se definen los resultados que se quieren obtener de acuerdo a la metodología planteada? | Todas |
| Plan de actividades | ¿El tiempo de duración total del trabajo de grado está acorde con lo estipulado en el Reglamento de Trabajo de Grado? · ¿La duración planteada para cada actividad es razonable? · ¿Las actividades planteadas son las necesarias para cumplir con el objetivo general del trabajo de grado? | Todas |
| Presupuesto | ¿El presupuesto estipula claramente los costos en recurso humano? · ¿El presupuesto estipula los costos en recursos tecnológicos? · ¿El presupuesto estipula los costos en materiales requeridos? · ¿Se discrimina en el presupuesto el aporte realizado por los autores, las UTS y otras instituciones patrocinadoras, en cada uno de los rubros costeados? | Todas |
| Consideraciones éticas | ¿Se evidencia dentro del informe el detalle de las consideraciones éticas que se pueden presentar en su desarrollo? | Todas |
| Referencias bibliográficas | ¿Las referencias aplican el estándar APA de la edición vigente? | Todas |
| Resumen de similitud | El resultado del informe de similitud evidencia un porcentaje de similitud entre el 0 y 10 % (ver Anexo A del formato) | Todas |

En total son 12 criterios y 28 indicadores. Están en la base, en las tablas `criterios_rejilla`, `indicadores_rejilla` y `criterio_modalidades`.

### Otros datos del formato

- **Ficha técnica:** título (entre 7 y 21 palabras), fecha, código de la propuesta (lo asigna la coordinación del programa), modalidad y modalidad específica, facultad (FCNI o FCSE), grupo de investigación, programa y ciudad, hasta 3 estudiantes (correo, cédula, teléfono y programa), director y codirector, y los datos del pago (número del LQ, banco, valor y fecha).
- **Modalidades específicas:** Desarrollo tecnológico: desarrollo de software, planta piloto, esquema de circuito integrado o signos distintivos. Monografía: teórica, análisis o sistematización de experiencias. Emprendimiento: casos de estudio, planes de negocio o fortalecimiento empresarial.
- **Contenido de la propuesta:** descripción del problema (máximo 20 líneas, con la pregunta problema), justificación (máximo 20 líneas), objetivo general, objetivos específicos (entre 3 y 5), estado del arte, fundamento teórico, resultados esperados, plan de actividades por semanas y fases, presupuesto, consideraciones éticas y referencias (APA).
- **Concepto final del evaluador:** Aprobado, No aprobado o Aplazado, con las firmas del director y del evaluador.
- **Sección del comité:** fechas de recibido y de emisión del concepto; concepto (Aprobado, No aprobado o Aplazado), observaciones, fecha de aprobación y número del acta; firmas de los estudiantes, el director y el coordinador del programa; fecha de notificación al estudiante, fecha de inicio y fecha de finalización ("180 días a partir de la notificación de la aprobación al estudiante"), y espacio para las prórrogas 1, 2 y 3.
- **Similitud:** "el porcentaje máximo de similitud admitido debe ser menor o igual al 10 %"; los índices no determinan por sí solos si hay plagio.

### Diferencias con el reglamento

El formato es de 2023 y el reglamento de 2021: donde no coinciden, manda el formato (decisión del 2026-10-08).

| Tema | Reglamento (2021) | F-DC-124 (2023) | Queda |
| --- | --- | --- | --- |
| Concepto del evaluador sobre la propuesta | Art. 21: aprobado, aprobado con correcciones o no aprobado | Aprobado, No aprobado o Aplazado | El del formato (RF22) |
| Prórrogas | Art. 16: hasta 2 | Espacio para 3 | 3 (RF38) |
| Desde cuándo se cuentan los 180 días | Art. 14: desde la aprobación de la propuesta | Desde la notificación de la aprobación al estudiante | Desde la aprobación total del FDC-124, por decisión del equipo del 2026-10-10 (RF31, RF38) |
| Integrantes | Art. 11: hasta 2, o 3 en investigación y desarrollo tecnológico | Espacio para 3 | Hasta 3, y 4 en los interdisciplinarios por decisión del equipo (RF13, RF36) |

Seminario no usa el F-DC-124 (lo confirmó el equipo el 2026-10-08): en la tabla de la rejilla, "Todas" son las otras cuatro modalidades.

## Anexo K: formatos F-DC-125 y F-DC-129

Fuente: formatos institucionales **F-DC-125 versión 2** (*Informe final trabajo de grado modalidad proyecto de investigación, desarrollo tecnológico, monografía, emprendimiento y seminario*) y **F-DC-129 versión 2** (*Rejilla de evaluación informe final de trabajo de grado*), entregados por el equipo el 2026-10-08, y un texto del equipo sobre el momento de cada formato. Quedó en RF23 (rejilla), RF37 (fases), RF17 (Seminario) y RF31 (informe final).

### En qué momento va cada formato

Texto entregado por el equipo, resumido:

- El **F-DC-124 (propuesta)** se radica y se aprueba al inicio, en la planeación. No se puede desarrollar el trabajo ni pasar al informe final hasta que el comité lo apruebe. Con la aprobación quedan el director y el código del proyecto.
- El **F-DC-125 (informe final)** se entrega al cierre, cuando ya se ejecutaron las actividades del cronograma y se redactaron los resultados. Se entrega al director para su aval y después a los evaluadores para la sustentación.
- Lo aprobado en el F-DC-124 (título, planteamiento, objetivos y justificación) se transcribe al capítulo 1 del F-DC-125.

En las fases (Anexo H): el F-DC-124 se diligencia en la **fase 2**, lo revisa el director en la **3** y el evaluador en la **4**; con la aprobación del comité empieza el F-DC-125, que el estudiante envía al director (fase 4) y el director al evaluador y al comité (**fase 5**); el evaluador lo califica con el F-DC-129, y en la **fase final** se programa la sustentación.

### F-DC-125: estructura del informe final

Portada y contraportada (título, modalidad, autores con cédula, director, grupo de investigación, facultad y programa), nota de aceptación firmada por el evaluador y el director, dedicatoria y agradecimientos (opcionales), tabla de contenido y listas de figuras y tablas, y estos capítulos:

- Resumen ejecutivo (máximo 300 palabras) y hasta 5 palabras clave.
- Introducción.
- 1. Descripción del trabajo: planteamiento del problema, justificación, objetivos (transcritos de la propuesta) y estado del arte (solo investigación y desarrollo tecnológico).
- 2. Marco referencial (teórico, legal, conceptual, ambiental, histórico).
- 3. Diseño de la investigación (no aplica en emprendimiento).
- 4. Desarrollo del trabajo de grado (en emprendimiento, el plan de negocios).
- 5. Resultados, 6. Conclusiones, 7. Recomendaciones, 8. Referencias (APA), 9. Apéndices y 10. Anexos (por ejemplo, manuales de usuario).

### F-DC-129: rejilla de evaluación del informe final

El evaluador marca *Cumple: Sí* o *No* en cada indicador. Según el formato, "si algún ítem no aplica dependiendo de la modalidad se debe marcar con N/A" y "para emitir el concepto de Aprobado, todos los ítems a evaluar que aplican deben ser cumplidos". Al final van las observaciones generales y el concepto final (Aprobado, No aprobado o Aplazado).

| Criterio | Indicadores |
| --- | --- |
| Formato | ¿El documento cumple con la plantilla establecida? · ¿La portada y la contraportada cumplen con la totalidad de la información solicitada en el formato? · ¿Tiene Tabla de contenido, lista de Figuras y lista de Tablas correctamente diligenciada? · ¿Se cita y referencia las fuentes consultadas para el desarrollo de todos los componentes del documento, de acuerdo con la norma APA? · ¿La redacción del documento se ajusta a las normas sobre escritura de documentos técnicos? |
| Resumen | ¿Se cumple con el máximo de 300 palabras? · ¿Presenta un máximo de 5 palabras clave correctas? · ¿El resumen describe claramente: ¿los objetivos, la metodología los resultados y las conclusiones más relevantes del trabajo de grado? |
| Introducción | ¿El documento establece los antecedentes suficientes para cubrir el tema? · ¿Se deja claro el método y la técnica empleados para la solución de la problemática? |
| Planteamiento de la problemática | ¿Se describe las causas que lo ocasionan y los efectos que se generan al no resolver la problemática? · ¿Se evidencia la pregunta concreta que soporta la problemática? |
| Justificación | ¿Se evidencia por qué se debe realizar este trabajo de grado? · ¿Se argumenta la necesidad, la conveniencia, las implicaciones tecnológicas, sociales, económicas, entre otras? |
| Objetivos | ¿Los objetivos generales y específicos son coherentes con el planteamiento del problema y la justificación descrita en el documento? · Se encuentran formulados de manera adecuada, inician con un verbo en infinitivo y responden las preguntas ¿qué?, ¿cómo? y ¿para qué? · ¿Cumple con la ejecución o desarrollo total de los objetivos? |
| Estado del arte o Antecedentes | ¿Se referencian otros casos o estudios a nivel nacional e internacional relacionados con el tema? · ¿Se manejan las citas de acuerdo a la norma APA vigente? |
| Marcos referenciales | ¿Se evidencian los diferentes marcos que aplican (teórico, histórico, conceptual, legal y ambiental), en el desarrollo de la propuesta de trabajo de grado? · ¿Los marcos referenciales se soportan en una amplia búsqueda de información? · ¿Los marcos de referencia son coherentes con la solución de la problemática? |
| Desarrollo del trabajo de grado | ¿Describe cronológicamente todas las fases que se requirieron para ejecutar correctamente el trabajo de grado? · ¿Se consigna la totalidad de información necesaria para que otro estudiante realice el trabajo de grado obteniendo los mismos resultados? · ¿Se detallan todas las pruebas que fueren requeridas para ejecutar el trabajo de grado? |
| Resultados | ¿Se evidencian claramente los resultados obtenidos durante la ejecución del trabajo de grado, mediante tablas, ecuaciones, tabulaciones, entre otros? · ¿Se documentan los resultados cuantitativa y cualitativamente? · Al leer la sección de resultados ¿se aprecia claramente el cumplimiento de todos los objetivos que requieren validación? |
| Conclusiones y recomendaciones | ¿Se describen claramente cuáles fueron los resultados más relevantes del trabajo de grado? · ¿Se indica claramente los resultados obtenidos sin las indicaciones numéricas? · ¿Las conclusiones aportan al lector, conocimiento que solo se obtiene con la realización de ese trabajo de grado? · ¿Se plantean recomendaciones con respecto a trabajos futuros, temas de investigación, aplicación de estrategias, etc.? |
| Consideraciones éticas | El documento incluye de forma detallada los anexos correspondientes a las consideraciones éticas (de no ser necesario indicar con N/A) |
| Referencias Bibliográficas | ¿Las referencias citadas cumplen la norma de citación APA vigente? · ¿Las referencias corresponden a la totalidad de las citas incluidas en el documento? · ¿Emplea un gestor de referencias? |
| Anexos (en caso de aplicar) | ¿Presenta todos los anexos que se consideren pertinentes para el entendimiento o aclaración del trabajo de grado? |
| Certificados | ¿Presenta los certificados propios del producto de investigación asociado al trabajo de grado (Acta de conformidad de la empresa, cámara de comercio, etc.)? Si no presenta productos como resultado de la investigación marcar N/A |
| Sustentación | ¿Se cumple con los requerimientos establecidos por el evaluador y director? |
| Índice de similitud | El documento incluye el informe arrojado por la herramienta institucional anti plagio, con un porcentaje de similitud menor o igual al 10%. |

En total son 17 criterios y 40 indicadores. Están en la base, en `criterios_rejilla` (formato `FDC-129`) e `indicadores_rejilla`, y aplican a todas las modalidades (el evaluador marca N/A lo que no aplique).

**No se incluye en el sistema:**
- La recomendación de distinción, porque la distinción queda fuera del sistema (Anexo C, arts. 35–38).
- Los productos de investigación (consultorías, prototipos, software, planta piloto, IG/IPP, secreto empresarial).

**Por revisar:** las modalidades del F-DC-129 incluyen Práctica, que está fuera del sistema, pero no Seminario, aunque el F-DC-125 sí es para Seminario. Por ahora la rejilla aplica también a Seminario.


## Anexo L: carreras de la UTS

Fuente: lista entregada por el equipo el 2026-10-10 (nombre, nivel, código SNIES y campus de cada oferta). Está en la tabla `carreras` de la base; el nivel "Universitario" es el que antes se llamaba "Ingeniería". "Negocios Internacionales" llegó cortada: el equipo confirmó que es universitaria y se ofrece en Bucaramanga y en el Campus Virtual (SNIES 119351, entregado el 2026-10-11; quedó en la de Bucaramanga; la del Campus Virtual se deja sin SNIES, decisión del 2026-10-14).

| Nivel | Campus | Carreras (SNIES) |
| --- | --- | --- |
| Tecnológico | Bucaramanga | Desarrollo de Sistemas Informáticos (101597), Entrenamiento Deportivo (17664), Gestión Bancaria y Financiera (109548), Gestión de la Moda (106408), Gestión de Sistemas de Telecomunicaciones (108284), Gestión Empresarial (11007), Implementación de Sistemas Electrónicos Industriales (109017), Instalación de Sistemas Eléctricos (118041), Logística del Transporte (111645), Manejo de la Información Contable (110921), Manejo de Recursos Ambientales (101724), Mercadeo y Gestión Comercial (103073), Operación y Mantenimiento Electromecánico (102378), Producción Industrial (107256) |
| Tecnológico | Piedecuesta | Construcción de Obras Civiles (111452), Gestión Agroindustrial (10349), Gestión Económica de Proyectos (116930), Levantamientos Topográficos (109015) |
| Tecnológico | Vélez | Gestión Empresarial (116905), Manejo de la Información Contable (117163), Manejo de Sistemas Agroforestales (111742) |
| Tecnológico | Barrancabermeja | Gestión de Recursos Energéticos (111122), Gestión Empresarial (90358), Manejo de la Información Contable (116931), Operación y Mantenimiento Electromecánico (90531) |
| Tecnológico | Campus Virtual | Análisis y Gestión de Datos (119109), Gestión Contable (118008), Gestión del Comercio Exterior (119347), Gestión Empresarial (107179), Gestión Turística y Hotelera (118606) |
| Universitario | Bucaramanga | Negocios Internacionales (119351), Administración de Empresas (53456), Administración Financiera (109549), Contaduría Pública (90894), Ingeniería Ambiental (101707), Ingeniería de Sistemas (101596), Ingeniería de Telecomunicaciones (53092), Ingeniería Eléctrica (106412), Ingeniería Electromecánica (90937), Ingeniería Electrónica (53390), Ingeniería en Sistemas de Transporte (111646), Ingeniería en Topografía (109226), Ingeniería Industrial (107257), Mercadeo (110617), Profesional en Cultura Física y Deporte (110922), Profesional en Diseño de Modas (106407) |
| Universitario | Piedecuesta | Economía (116932), Ingeniería Civil (111356) |
| Universitario | Vélez | Administración de Empresas (116816), Contaduría Pública (117161), Ingeniería Agroforestal (111743) |
| Universitario | Barrancabermeja | Administración de Empresas (103265), Contaduría Pública (116768), Ingeniería Electromecánica (103234), Ingeniería en Energías (111123) |
| Universitario | Campus Virtual | Administración de Empresas (107432), Administración de Empresas Turísticas y Hoteleras (118607), Contaduría Pública (107060), Ingeniería en Inteligencia Artificial y Ciencia de Datos (119105), Negocios Internacionales (sin dato) |

Las carreras tecnológicas se llaman "Tecnología en …" (por ejemplo, Tecnología en Desarrollo de Sistemas Informáticos).
