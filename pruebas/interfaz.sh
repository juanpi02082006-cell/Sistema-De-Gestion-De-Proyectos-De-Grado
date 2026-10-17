#!/usr/bin/env bash
# Pruebas de la interfaz en navegadores reales (2026-10-14): deja un proyecto en cada situación
# (fase 1 con el pago por revisar, 2 con la propuesta, 3 con la revisión del director, 4 con la
# rejilla del F-DC-124, 4 con la propuesta aprobada y el informe, 5 con la rejilla del
# F-DC-129, fase final con la sustentación por programar y Seminario con la inscripción),
# para que cada formulario salga en pantalla, y corre pruebas/interfaz.js: todas las páginas de
# cada rol en Chrome, Edge y Firefox, en computador y en celular.
# Se corre con correr-pruebas.sh (respalda la base y la devuelve):
#   bash pruebas/correr-pruebas.sh <carpeta-respaldo> interfaz
# Necesita Node, playwright-core (ruta en PLAYWRIGHT; por defecto la de este computador), Chrome
# y Edge instalados, y el Firefox de Playwright (node <playwright-core>/cli.js install firefox).
cd "$(dirname "$0")/.." || exit 1
MYSQL="/c/xampp/mysql/bin/mysql.exe -u root -N -B -D sistemas_proyectos_grado --default-character-set=utf8mb4"
export PLAYWRIGHT="${PLAYWRIGHT:-C:/Users/juanp/node_modules/playwright-core}"

$MYSQL <<'SQL'
INSERT INTO periodos (id, nombre, estado, fecha_inicio_semestre, fecha_cierre_banco, fecha_limite_pago, fecha_limite_propuestas)
VALUES (1, '2026-2', 'Activo', CURDATE() - INTERVAL 30 DAY, CURDATE() + INTERVAL 30 DAY, CURDATE() + INTERVAL 30 DAY, CURDATE() + INTERVAL 60 DAY);
INSERT INTO sesiones_comite (periodo_id, fecha, hora, lugar) VALUES (1, CURDATE() + INTERVAL 7 DAY, '14:00', 'Sala de juntas del bloque B');
INSERT INTO usuarios (id, nombre, tipo_documento_id, numero_documento, correo, contrasena, nivel_id, carrera_id, plan_estudios, porcentaje_creditos, metodologia_aprobada) VALUES
    (20, 'Ana Maria Rodriguez Fernandez', 1, '7000000020', 'ana.ui@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (21, 'Beto Alejandro Gutierrez Pinzon', 1, '7000000021', 'beto.ui@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (22, 'Caro Valentina Suarez', 1, '7000000022', 'caro.ui@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (23, 'Dani Esteban Mora', 1, '7000000023', 'dani.ui@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (24, 'Eli Sofia Paez', 1, '7000000024', 'eli.ui@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (25, 'Fer Andres Quintero', 1, '7000000025', 'fer.ui@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (26, 'Gabi Lucia Ortiz', 1, '7000000026', 'gabi.ui@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 80, 1),
    (27, 'Hugo Sebastian Rincon', 1, '7000000027', 'hugo.ui@correo.uts.edu.co', SHA2('123456', 256), 1, 1, 'Anterior', 95, 1);
INSERT INTO usuario_roles (usuario_id, rol_id) SELECT id, 5 FROM usuarios WHERE id BETWEEN 20 AND 27;
INSERT INTO proyectos (id, codigo, titulo, descripcion, modalidad_id, nivel_id, periodo_id, fase_id, estado, director_id, evaluador_id, fecha_inicio,
                       fecha_aprobacion_124, fecha_notificacion, fecha_limite) VALUES
    (1, '65-2026-2/1', 'Sistema de turnos para la cafeteria con notificaciones en tiempo real', 'Descripcion larga del proyecto para ver como se acomoda el texto en pantallas pequenas.', 2, 1, 1, 2, 'Pendiente', 3, NULL, NULL, NULL, NULL, NULL),
    (2, '65-2026-2/2', 'Inventario de equipos de laboratorio con codigos QR', 'Propuesta en la fase 2', 2, 1, 1, 3, 'En curso', 3, 4, CURDATE(), NULL, NULL, NULL),
    (3, '65-2026-2/3', 'Plataforma de tutorias entre pares', 'Propuesta enviada al director', 2, 1, 1, 4, 'En curso', 3, 4, CURDATE(), NULL, NULL, NULL),
    (4, '65-2026-2/4', 'Monitoreo de consumo electrico con IoT', 'Propuesta con el evaluador', 2, 1, 1, 5, 'En curso', 3, 4, CURDATE(), NULL, NULL, NULL),
    (5, '65-2026-2/5', 'Aplicacion movil para reservas deportivas', 'Propuesta aprobada, informe en curso', 2, 1, 1, 5, 'En curso', 3, 4, CURDATE() - INTERVAL 100 DAY, CURDATE() - INTERVAL 100 DAY, CURDATE() - INTERVAL 100 DAY, CURDATE() + INTERVAL 80 DAY),
    (6, '65-2026-2/6', 'Analisis de datos de desercion estudiantil', 'Informe con el evaluador', 2, 1, 1, 6, 'En curso', 3, 4, CURDATE() - INTERVAL 120 DAY, CURDATE() - INTERVAL 120 DAY, CURDATE() - INTERVAL 120 DAY, CURDATE() + INTERVAL 60 DAY),
    (7, '65-2026-2/7', 'Chatbot de orientacion academica', 'En la fase final', 2, 1, 1, 7, 'En curso', 3, 4, CURDATE() - INTERVAL 150 DAY, CURDATE() - INTERVAL 150 DAY, CURDATE() - INTERVAL 150 DAY, CURDATE() + INTERVAL 30 DAY),
    (8, '65-2026-2/8', 'Seminario de analitica de datos', 'Inscripcion al seminario', 5, 1, 1, 2, 'Pendiente', 3, NULL, NULL, NULL, NULL, NULL);
INSERT INTO proyecto_estudiantes (proyecto_id, estudiante_id) VALUES (1, 20), (2, 21), (3, 22), (4, 23), (5, 24), (6, 25), (7, 26), (8, 27);
INSERT INTO entregas (id, proyecto_id, fase_id, tipo, version, oficial, nombre_archivo, ruta_archivo, subido_por, fecha_limite_revision) VALUES
    (1, 1, 2, 'Recibo de pago', NULL, NULL, 'recibo de pago de la matricula de Ana Maria.pdf', 'ui-1.pdf', 20, NULL),
    (2, 2, 3, 'FDC-124', 1, NULL, 'propuesta-inventario-version-uno-con-un-nombre-largo.docx', 'ui-2.docx', 21, NULL),
    (3, 3, 4, 'FDC-124', 1, NULL, 'propuesta-tutorias.docx', 'ui-3.docx', 22, CURDATE() + INTERVAL 5 DAY),
    (4, 4, 5, 'FDC-124', 1, NULL, 'propuesta-iot.docx', 'ui-4.docx', 23, CURDATE() + INTERVAL 3 DAY),
    (5, 5, 5, 'FDC-124', 1, 1, 'propuesta-reservas.docx', 'ui-5.docx', 24, NULL),
    (6, 6, 5, 'FDC-124', 1, 1, 'propuesta-desercion.docx', 'ui-6.docx', 25, NULL),
    (7, 6, 6, 'FDC-125', 1, NULL, 'informe-desercion.docx', 'ui-7.docx', 25, CURDATE() + INTERVAL 5 DAY),
    (8, 7, 5, 'FDC-124', 1, 1, 'propuesta-chatbot.docx', 'ui-8.docx', 26, NULL),
    (9, 7, 6, 'FDC-125', 1, 1, 'informe-chatbot.docx', 'ui-9.docx', 26, NULL),
    (10, 5, 5, 'FDC-125', 1, NULL, 'informe-reservas-borrador.docx', 'ui-10.docx', 24, NULL);
INSERT INTO revisiones (entrega_id, revisor_id, rol, estado, decision, observacion) VALUES
    (4, 3, 'Director', 'Enviada', 'Aprobado', 'Lista para el evaluador'),
    (5, 3, 'Director', 'Enviada', 'Aprobado', 'Lista'), (5, 4, 'Evaluador', 'Enviada', 'Aprobado', 'Cumple'), (5, 1, 'Comité', 'Enviada', 'Aprobado', 'Aprobada'),
    (6, 3, 'Director', 'Enviada', 'Aprobado', 'Lista'), (6, 4, 'Evaluador', 'Enviada', 'Aprobado', 'Cumple'), (6, 1, 'Comité', 'Enviada', 'Aprobado', 'Aprobada'),
    (7, 3, 'Director', 'Enviada', 'Aprobado', 'Listo para evaluar'),
    (8, 3, 'Director', 'Enviada', 'Aprobado', 'Lista'), (8, 4, 'Evaluador', 'Enviada', 'Aprobado', 'Cumple'), (8, 1, 'Comité', 'Enviada', 'Aprobado', 'Aprobada'),
    (9, 3, 'Director', 'Enviada', 'Aprobado', 'Listo'), (9, 4, 'Evaluador', 'Enviada', 'Aprobado', 'Cumple'), (9, 1, 'Comité', 'Enviada', 'Aprobado', 'Informe aprobado');
INSERT INTO seguimientos (proyecto_id, director_id, fecha, observacion) VALUES
    (5, 3, CURDATE() - INTERVAL 40 DAY, 'Avance del capitulo de resultados'), (5, 3, CURDATE() - INTERVAL 10 DAY, 'Pruebas de usabilidad listas');
INSERT INTO ideas (titulo, descripcion, nivel_id, modalidad_id, origen, propuesta_por, estado, periodo_id) VALUES
    ('Sistema de prestamo de libros con lector de codigo de barras', 'Idea para el banco', 1, 2, 'Docente', 3, 'Aprobada', 1),
    ('Idea pendiente de revision', 'Para que el comite la revise', 1, 3, 'Docente', 3, 'Pendiente', 1);
INSERT INTO pqrs (usuario_id, proyecto_id, tipo, comentario) VALUES (21, 2, 'Cambio de director', 'Necesito cambiar de director porque no coincidimos en los horarios.');
SQL
node pruebas/interfaz.js
