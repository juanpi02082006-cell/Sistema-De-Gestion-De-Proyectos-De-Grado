-- Pruebas de las restricciones de la base v5 (incluye las de la v3, la v4 y las del 2026-10-10). Los resultados van en una base aparte (pruebas_tmp);
-- el procedimiento se crea en la base del proyecto (así sus sentencias ven las tablas). Al final hay que reimportar el script.
DROP DATABASE IF EXISTS pruebas_tmp;
CREATE DATABASE pruebas_tmp;
USE pruebas_tmp;
CREATE TABLE resultados (n INT AUTO_INCREMENT PRIMARY KEY, prueba VARCHAR(120), esperado VARCHAR(10), obtenido VARCHAR(10), estado VARCHAR(5));

USE sistemas_proyectos_grado;
DELIMITER //
CREATE PROCEDURE prueba(IN nombre VARCHAR(120), IN sentencia TEXT, IN debe_fallar TINYINT)
BEGIN
    DECLARE fallo TINYINT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET fallo = 1;
    SET @s = sentencia;
    PREPARE st FROM @s;
    EXECUTE st;
    DEALLOCATE PREPARE st;
    INSERT INTO pruebas_tmp.resultados (prueba, esperado, obtenido, estado)
    VALUES (nombre, IF(debe_fallar, 'rechaza', 'acepta'), IF(fallo, 'rechaza', 'acepta'), IF(fallo = debe_fallar, 'OK', 'FALLA'));
END//
DELIMITER ;

-- Datos base para las pruebas
INSERT INTO sistemas_proyectos_grado.periodos (id, nombre, fecha_limite_pago) VALUES (1, '2026-2', '2026-09-25');
INSERT INTO sistemas_proyectos_grado.ideas (id, titulo, nivel_id, origen, propuesta_por) VALUES (1, 'Idea de prueba', 1, 'Docente', 3);
INSERT INTO sistemas_proyectos_grado.proyectos (id, titulo, modalidad_id, nivel_id, fase_id, director_id, evaluador_id) VALUES (1, 'Proyecto 1', 1, 1, 1, 3, 4);
INSERT INTO sistemas_proyectos_grado.proyectos (id, titulo, modalidad_id, nivel_id, fase_id, estado) VALUES (2, 'Proyecto 2', 2, 1, 1, 'Cancelado');
INSERT INTO sistemas_proyectos_grado.proyectos (id, titulo, modalidad_id, nivel_id, fase_id) VALUES (3, 'Proyecto 3', 3, 1, 1);
INSERT INTO sistemas_proyectos_grado.proyecto_estudiantes (proyecto_id, estudiante_id, vigente) VALUES (2, 5, NULL);
INSERT INTO sistemas_proyectos_grado.entregas (id, proyecto_id, fase_id, tipo, nombre_archivo, ruta_archivo, subido_por) VALUES (1, 1, 1, 'Propuesta', 'p.docx', '/p.docx', 5);
INSERT INTO sistemas_proyectos_grado.revisiones (id, entrega_id, revisor_id, rol, estado) VALUES (100, 1, 4, 'Evaluador', 'Borrador');

USE sistemas_proyectos_grado;
-- Lo que la base debe rechazar
CALL prueba('Correo que no es institucional (Gmail)', "INSERT INTO usuarios (nombre, tipo_documento_id, numero_documento, correo, contrasena) VALUES ('X', 2, '9', 'x@gmail.com', SHA2('a',256))", 1);
CALL prueba('Créditos de 120 %', "UPDATE usuarios SET porcentaje_creditos = 120 WHERE id = 5", 1);
CALL prueba('Plan de estudios que no existe', "UPDATE usuarios SET plan_estudios = 'Otro' WHERE id = 5", 1);
CALL prueba('Rol Coordinación (id 2) ya no existe', "INSERT INTO usuario_roles (usuario_id, rol_id) VALUES (3, 2)", 1);
CALL prueba('Director igual al evaluador', "UPDATE proyectos SET evaluador_id = 3 WHERE id = 1", 1);
CALL prueba('Modalidad con 5 integrantes', "UPDATE modalidades SET max_integrantes = 5 WHERE id = 1", 1);
CALL prueba('Fase con orden repetido', "INSERT INTO fases (orden, nombre) VALUES (3, 'Otra')", 1);
CALL prueba('Festivo repetido', "INSERT INTO festivos VALUES ('2026-12-25', 'Otra vez')", 1);
CALL prueba('Idea sin origen válido', "INSERT INTO ideas (titulo, nivel_id, origen, propuesta_por) VALUES ('X', 1, 'Coordinación', 3)", 1);
CALL prueba('Revisión con la decisión vieja "Rechazado"', "INSERT INTO revisiones (entrega_id, revisor_id, rol, decision, observacion) VALUES (1, 3, 'Director', 'Rechazado', 'x')", 1);
CALL prueba('Revisión sin observación', "INSERT INTO revisiones (entrega_id, revisor_id, rol, decision, observacion) VALUES (1, 3, 'Director', 'Aprobado', '   ')", 1);
CALL prueba('Nota mayor que 5', "INSERT INTO revisiones (entrega_id, revisor_id, rol, decision, nota, observacion) VALUES (1, 4, 'Evaluador', 'Aprobado', 6, 'x')", 1);
CALL prueba('Seguimiento sin observación', "INSERT INTO seguimientos (proyecto_id, director_id, fecha, observacion) VALUES (1, 3, '2026-10-06', '')", 1);
CALL prueba('Codirector repetido en el mismo proyecto', "INSERT INTO proyecto_codirectores VALUES (1, 6), (1, 6)", 1);
CALL prueba('Estudiante en un segundo proyecto vigente', "INSERT INTO proyecto_estudiantes (proyecto_id, estudiante_id) VALUES (1, 5), (3, 5)", 1);
CALL prueba('Renunciar a la exoneración sin estar exonerado', "INSERT INTO proyecto_estudiantes (proyecto_id, estudiante_id, vigente, renuncia_exoneracion) VALUES (3, 6, NULL, 1)", 1);
CALL prueba('Cuarta prórroga (F-DC-124: hasta 3)', "INSERT INTO prorrogas (proyecto_id, numero, fecha_solicitud, nueva_fecha_limite) VALUES (1, 4, '2026-10-01', '2027-04-01')", 1);
CALL prueba('Decisión "Aprobado con correcciones" (no está en el F-DC-124)', "INSERT INTO revisiones (entrega_id, revisor_id, rol, decision, observacion) VALUES (1, 4, 'Evaluador', 'Aprobado con correcciones', 'x')", 1);

-- Versión 4: lo que la base debe rechazar
CALL prueba('v4: Metodología aprobada con valor 2', "UPDATE usuarios SET metodologia_aprobada = 2 WHERE id = 5", 1);
CALL prueba('v4: Periodo con estado que no existe', "UPDATE periodos SET estado = 'Abierto' WHERE id = 1", 1);
CALL prueba('v4: Entrega con tipo que no existe', "INSERT INTO entregas (proyecto_id, tipo, nombre_archivo, ruta_archivo, subido_por) VALUES (1, 'Video', 'v.mp4', '/v.mp4', 5)", 1);
CALL prueba('v4: Versión repetida de la propuesta', "INSERT INTO entregas (proyecto_id, tipo, version, nombre_archivo, ruta_archivo, subido_por) VALUES (3, 'Propuesta', 1, 'a.docx', '/a', 5), (3, 'Propuesta', 1, 'b.docx', '/b', 5)", 1);
CALL prueba('v4: Dos versiones oficiales del mismo tipo', "INSERT INTO entregas (proyecto_id, tipo, version, oficial, nombre_archivo, ruta_archivo, subido_por) VALUES (3, 'FDC-124', 1, 1, 'a.docx', '/a', 5), (3, 'FDC-124', 2, 1, 'b.docx', '/b', 5)", 1);
CALL prueba('v4: Versión 0', "INSERT INTO entregas (proyecto_id, tipo, version, nombre_archivo, ruta_archivo, subido_por) VALUES (3, 'FDC-125', 0, 'a.docx', '/a', 5)", 1);
CALL prueba('v4: Oficial con valor 0', "INSERT INTO entregas (proyecto_id, tipo, version, oficial, nombre_archivo, ruta_archivo, subido_por) VALUES (3, 'FDC-125', 1, 0, 'a.docx', '/a', 5)", 1);
CALL prueba('v4: Evaluación enviada sin decisión', "INSERT INTO revisiones (entrega_id, revisor_id, rol, estado, observacion) VALUES (1, 4, 'Evaluador', 'Enviada', 'x')", 1);
CALL prueba('v4: Evaluación enviada sin observación', "INSERT INTO revisiones (entrega_id, revisor_id, rol, estado, decision) VALUES (1, 4, 'Evaluador', 'Enviada', 'Aprobado')", 1);
CALL prueba('v4: Enviar un borrador sin decisión', "UPDATE revisiones SET estado = 'Enviada' WHERE id = 100", 1);
CALL prueba('v4: Revisión con estado que no existe', "INSERT INTO revisiones (entrega_id, revisor_id, rol, estado) VALUES (1, 4, 'Evaluador', 'Listo')", 1);
CALL prueba('v4: Rejilla con respuesta que no existe', "INSERT INTO revision_indicadores (revision_id, indicador_id, cumple) VALUES (100, 1, 'Tal vez')", 1);
CALL prueba('v4: Indicador repetido en la misma evaluación', "INSERT INTO revision_indicadores (revision_id, indicador_id) VALUES (100, 2), (100, 2)", 1);
CALL prueba('v4: Indicador de la rejilla que no existe', "INSERT INTO revision_indicadores (revision_id, indicador_id) VALUES (100, 99)", 1);
CALL prueba('v4: Indicador con el mismo orden en su criterio', "INSERT INTO indicadores_rejilla (criterio_id, orden, pregunta) VALUES (2, 1, 'Otra')", 1);
CALL prueba('v4: Cambio a la misma modalidad', "INSERT INTO cambios_modalidad (proyecto_id, modalidad_anterior_id, modalidad_nueva_id, solicitado_por) VALUES (1, 1, 1, 5)", 1);
CALL prueba('v4: Cambio de modalidad aprobado sin quién decidió', "INSERT INTO cambios_modalidad (proyecto_id, modalidad_anterior_id, modalidad_nueva_id, solicitado_por, estado) VALUES (1, 1, 2, 5, 'Aprobada')", 1);
CALL prueba('v4: Cambio de modalidad con estado que no existe', "INSERT INTO cambios_modalidad (proyecto_id, modalidad_anterior_id, modalidad_nueva_id, solicitado_por, estado) VALUES (1, 1, 2, 5, 'En estudio')", 1);
CALL prueba('v4: Historial con acción que no existe', "INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (1, 1, 'Borrado', 'x')", 1);

-- Lo que la base debe aceptar
CALL prueba('Correo institucional en mayúsculas', "INSERT INTO usuarios (nombre, tipo_documento_id, numero_documento, correo, contrasena) VALUES ('Y', 1, '8', 'NUEVO.ESTUDIANTE@CORREO.UTS.EDU.CO', SHA2('a',256))", 0);
CALL prueba('Estudiante con plan Nuevo y puntaje Saber TyT', "UPDATE usuarios SET plan_estudios = 'Nuevo', puntaje_saber_tyt = 160 WHERE id = 5", 0);
CALL prueba('Propuesta formulada por el estudiante', "INSERT INTO ideas (titulo, nivel_id, origen, propuesta_por) VALUES ('Mi propuesta', 1, 'Estudiante', 5)", 0);
CALL prueba('Estudiante en proyecto nuevo tras uno cancelado', "INSERT INTO proyecto_estudiantes (proyecto_id, estudiante_id) VALUES (1, 5)", 0);
CALL prueba('Proyecto interdisciplinario con 2 codirectores', "INSERT INTO proyecto_codirectores VALUES (1, 6), (1, 4)", 0);
CALL prueba('Revisión "Aplazado" con nota', "INSERT INTO revisiones (entrega_id, revisor_id, rol, decision, nota, observacion) VALUES (1, 4, 'Evaluador', 'Aplazado', 4.2, 'Ajustar la metodología')", 0);
CALL prueba('Devolución del comité (administrador)', "INSERT INTO revisiones (entrega_id, revisor_id, rol, decision, observacion) VALUES (1, 1, 'Comité', 'Devuelto', 'Falta la firma')", 0);
CALL prueba('Seguimiento del director', "INSERT INTO seguimientos (proyecto_id, director_id, fecha, observacion) VALUES (1, 3, '2026-10-06', 'Avance del capítulo 1')", 0);
CALL prueba('Prórrogas 1, 2 y 3', "INSERT INTO prorrogas (proyecto_id, numero, fecha_solicitud, nueva_fecha_limite) VALUES (1, 1, '2026-10-01', '2027-04-01'), (1, 2, '2027-03-20', '2027-09-28'), (1, 3, '2027-09-20', '2028-03-26')", 0);
CALL prueba('Proyecto con fecha de notificación de la aprobación', "UPDATE proyectos SET fecha_aprobacion_124 = '2026-10-01', fecha_notificacion = '2026-10-05', fecha_limite = DATE_ADD('2026-10-01', INTERVAL 180 DAY) WHERE id = 1", 0);

-- Versión 4: lo que la base debe aceptar
CALL prueba('v4: Estudiante con Metodología aprobada', "UPDATE usuarios SET metodologia_aprobada = 1 WHERE id = 5", 0);
CALL prueba('v4: Periodo activo', "UPDATE periodos SET estado = 'Activo' WHERE id = 1", 0);
CALL prueba('v4: Evaluación en borrador sin decisión ni observación', "INSERT INTO revisiones (entrega_id, revisor_id, rol, estado) VALUES (1, 4, 'Evaluador', 'Borrador')", 0);
CALL prueba('v4: Rejilla: Sí, No y sin responder (borrador)', "INSERT INTO revision_indicadores (revision_id, indicador_id, cumple, observacion) VALUES (100, 1, 'Sí', NULL), (100, 2, 'No', 'Falta delimitar el problema'), (100, 3, NULL, NULL)", 0);
CALL prueba('v4: Enviar el borrador con decisión y observación', "UPDATE revisiones SET estado = 'Enviada', decision = 'Aplazado', observacion = 'Ajustar el problema' WHERE id = 100", 0);
CALL prueba('v4: Versiones 1 y 2 de la propuesta, la 2 oficial', "INSERT INTO entregas (proyecto_id, tipo, version, oficial, nombre_archivo, ruta_archivo, subido_por) VALUES (3, 'Propuesta', 1, NULL, 'v1.docx', '/v1', 5), (3, 'Propuesta', 2, 1, 'v2.docx', '/v2', 5)", 0);
CALL prueba('v4: Varios anexos sin versión en el mismo proyecto', "INSERT INTO entregas (proyecto_id, tipo, nombre_archivo, ruta_archivo, subido_por) VALUES (3, 'Anexo', 'a1.pdf', '/a1', 5), (3, 'Anexo', 'a2.pdf', '/a2', 5)", 0);
CALL prueba('v4: Entregables de la modalidad', "INSERT INTO entregas (proyecto_id, tipo, nombre_archivo, ruta_archivo, subido_por) VALUES (3, 'Manual de usuario', 'm.pdf', '/m', 5), (3, 'Código fuente', 'c.zip', '/c', 5), (3, 'Evidencia', 'e.pdf', '/e', 5)", 0);
CALL prueba('v4: Solicitud de cambio de modalidad pendiente', "INSERT INTO cambios_modalidad (id, proyecto_id, modalidad_anterior_id, modalidad_nueva_id, solicitado_por, motivo) VALUES (1, 1, 3, 2, 5, 'Pasar de monografía a desarrollo')", 0);
CALL prueba('v4: El comité aprueba el cambio de modalidad', "UPDATE cambios_modalidad SET estado = 'Aprobada', decidido_por = 1, decidido_en = NOW(), observacion = 'Aprobado en sesión' WHERE id = 1", 0);
CALL prueba('v4: Historial con tipo de acción', "INSERT INTO historial (proyecto_id, usuario_id, accion, descripcion) VALUES (1, 1, 'Modalidad', 'Cambio de Monografía a Desarrollo tecnológico')", 0);
CALL prueba('v4: Respuesta N/A (F-DC-129)', "INSERT INTO revision_indicadores (revision_id, indicador_id, cumple) VALUES (100, 60, 'N/A')", 0);
CALL prueba('v4: Criterio con el mismo nombre en otro formato', "INSERT INTO criterios_rejilla (formato, orden, nombre) VALUES ('FDC-129', 99, 'Presupuesto')", 0);
CALL prueba('v4: Criterio repetido en el mismo formato', "INSERT INTO criterios_rejilla (formato, orden, nombre) VALUES ('FDC-124', 98, 'Justificación')", 1);
CALL prueba('v4: Rejilla de un formato que no existe', "INSERT INTO criterios_rejilla (formato, orden, nombre) VALUES ('FDC-125', 97, 'Otro')", 1);

-- 2026-10-10: sesiones del comité y sustentaciones
CALL prueba('Sesiones del comité en dos días distintos', "INSERT INTO sesiones_comite (periodo_id, fecha, hora, lugar) VALUES (1, '2026-10-14', '14:00', 'Sala 201'), (1, '2026-10-21', NULL, NULL)", 0);
CALL prueba('Dos sesiones del comité el mismo día', "INSERT INTO sesiones_comite (periodo_id, fecha) VALUES (1, '2026-10-14')", 1);
CALL prueba('Sustentación con fecha y lugar', "INSERT INTO sustentaciones (proyecto_id, fecha_hora, lugar, programada_por) VALUES (1, '2027-05-20 10:00', 'Auditorio', 3)", 0);
CALL prueba('Sustentación sin lugar', "INSERT INTO sustentaciones (proyecto_id, fecha_hora, lugar, programada_por) VALUES (3, '2027-05-20 10:00', '  ', 3)", 1);
CALL prueba('Segunda sustentación del mismo proyecto', "INSERT INTO sustentaciones (proyecto_id, fecha_hora, lugar, programada_por) VALUES (1, '2027-06-01 10:00', 'Sala 2', 3)", 1);

-- Versión 5: carreras, avisos, exoneraciones, codirectores y PQR
CALL prueba('Carrera que no existe en el catálogo', "UPDATE usuarios SET carrera_id = 9999 WHERE id = 5", 1);
CALL prueba('Carrera del catálogo', "UPDATE usuarios SET carrera_id = 35, nivel_id = 2 WHERE id = 5", 0);
CALL prueba('Dos ofertas con el mismo SNIES', "INSERT INTO carreras (nombre, nivel_id, snies, campus) VALUES ('Otra', 1, '101597', 'Vélez')", 1);
CALL prueba('Carrera con metodología vacía', "INSERT INTO carreras (nombre, nivel_id, campus, metodologia) VALUES ('Otra', 1, 'Vélez', '')", 1);
CALL prueba('Aviso sin mensaje', "INSERT INTO avisos (usuario_id, mensaje) VALUES (5, '  ')", 1);
CALL prueba('Aviso normal (sin clave)', "INSERT INTO avisos (usuario_id, proyecto_id, mensaje) VALUES (5, 1, 'Hola')", 0);
CALL prueba('Otro aviso normal (las claves NULL no chocan)', "INSERT INTO avisos (usuario_id, proyecto_id, mensaje) VALUES (5, 1, 'Hola')", 0);
CALL prueba('Alerta con clave', "INSERT INTO avisos (usuario_id, mensaje, clave) VALUES (5, 'Vence', 'pago-10-p1')", 0);
CALL prueba('La misma alerta otra vez', "INSERT INTO avisos (usuario_id, mensaje, clave) VALUES (5, 'Vence', 'pago-10-p1')", 1);
INSERT INTO sistemas_proyectos_grado.entregas (id, proyecto_id, fase_id, tipo, nombre_archivo, ruta_archivo, subido_por) VALUES (2, 1, 1, 'Certificado Saber TyT', 'c.pdf', 'c.pdf', 5);
CALL prueba('Exoneración con 110 puntos', "INSERT INTO exoneraciones (proyecto_id, estudiante_id, puntaje, entrega_id) VALUES (1, 5, 110, 2)", 1);
CALL prueba('Exoneración con 160 puntos', "INSERT INTO exoneraciones (id, proyecto_id, estudiante_id, puntaje, entrega_id) VALUES (1, 1, 5, 160, 2)", 0);
CALL prueba('Exoneración aprobada sin observación', "UPDATE exoneraciones SET estado = 'Aprobada', revisada_por = 1, revisada_en = NOW() WHERE id = 1", 1);
CALL prueba('Exoneración con estado vacío', "UPDATE exoneraciones SET estado = '' WHERE id = 1", 1);
CALL prueba('Exoneración aprobada con observación', "UPDATE exoneraciones SET estado = 'Aprobada', revisada_por = 1, revisada_en = NOW(), observacion = 'Ok' WHERE id = 1", 0);
CALL prueba('Observación de codirector sin decisión', "INSERT INTO revisiones (entrega_id, revisor_id, rol, estado, observacion) VALUES (1, 6, 'Codirector', 'Enviada', 'Revisar')", 0);
CALL prueba('Codirector con decisión (decide el director)', "INSERT INTO revisiones (entrega_id, revisor_id, rol, estado, decision, observacion) VALUES (1, 6, 'Codirector', 'Enviada', 'Aprobado', 'Ok')", 1);
CALL prueba('Revisión enviada del director sin decisión', "INSERT INTO revisiones (entrega_id, revisor_id, rol, estado, observacion) VALUES (1, 3, 'Director', 'Enviada', 'Ok')", 1);
CALL prueba('PQR de tipo que no existe', "INSERT INTO pqrs (usuario_id, tipo, comentario) VALUES (5, 'Otra', 'x')", 1);
CALL prueba('PQR vacía', "INSERT INTO pqrs (usuario_id, tipo, comentario) VALUES (5, 'Queja', '  ')", 1);
CALL prueba('PQR de petición', "INSERT INTO pqrs (id, usuario_id, tipo, comentario) VALUES (1, 5, 'Petición', 'Necesito ayuda')", 0);
CALL prueba('PQR respondida sin respuesta', "UPDATE pqrs SET estado = 'Respondida', respondida_por = 1, respondida_en = NOW() WHERE id = 1", 1);

-- Datos de las rejillas (no son restricciones: se comprueban los conteos)
INSERT INTO pruebas_tmp.resultados (prueba, esperado, obtenido, estado)
    SELECT 'Rejilla F-DC-124: 12 criterios y 28 indicadores', '12/28', CONCAT(COUNT(DISTINCT c.id), '/', COUNT(i.id)),
           IF(COUNT(DISTINCT c.id) = 12 AND COUNT(i.id) = 28, 'OK', 'FALLA')
    FROM criterios_rejilla c JOIN indicadores_rejilla i ON i.criterio_id = c.id WHERE c.formato = 'FDC-124';
INSERT INTO pruebas_tmp.resultados (prueba, esperado, obtenido, estado)
    SELECT 'Rejilla F-DC-129: 17 criterios y 40 indicadores', '17/40', CONCAT(COUNT(DISTINCT c.id), '/', COUNT(i.id)),
           IF(COUNT(DISTINCT c.id) = 17 AND COUNT(i.id) = 40, 'OK', 'FALLA')
    FROM criterios_rejilla c JOIN indicadores_rejilla i ON i.criterio_id = c.id WHERE c.formato = 'FDC-129';
INSERT INTO pruebas_tmp.resultados (prueba, esperado, obtenido, estado)
    SELECT 'F-DC-124: estado del arte solo en investigación y desarrollo', '1,2', GROUP_CONCAT(cm.modalidad_id ORDER BY cm.modalidad_id),
           IF(GROUP_CONCAT(cm.modalidad_id ORDER BY cm.modalidad_id) = '1,2', 'OK', 'FALLA')
    FROM criterio_modalidades cm JOIN criterios_rejilla c ON c.id = cm.criterio_id WHERE c.formato = 'FDC-124' AND c.nombre = 'Estado del arte';
INSERT INTO pruebas_tmp.resultados (prueba, esperado, obtenido, estado)
    SELECT 'Seminario no usa el F-DC-124', '0', COUNT(*), IF(COUNT(*) = 0, 'OK', 'FALLA')
    FROM criterio_modalidades cm JOIN criterios_rejilla c ON c.id = cm.criterio_id WHERE c.formato = 'FDC-124' AND cm.modalidad_id = 5;
INSERT INTO pruebas_tmp.resultados (prueba, esperado, obtenido, estado)
    SELECT 'Fases 0 a 6: FDC-124 en la 2 y la 3, FDC-125 en la 4 y la 5', '0-6|2:FDC-124,3:FDC-124,4:FDC-125,5:FDC-125',
           CONCAT(MIN(orden), '-', MAX(orden), '|', GROUP_CONCAT(IF(formato IS NULL, NULL, CONCAT(orden, ':', formato)) ORDER BY orden)),
           IF(CONCAT(MIN(orden), '-', MAX(orden), '|', GROUP_CONCAT(IF(formato IS NULL, NULL, CONCAT(orden, ':', formato)) ORDER BY orden))
              = '0-6|2:FDC-124,3:FDC-124,4:FDC-125,5:FDC-125', 'OK', 'FALLA')
    FROM fases;
INSERT INTO pruebas_tmp.resultados (prueba, esperado, obtenido, estado)
    SELECT 'Catálogo de carreras: 30 tecnológicas y 29 universitarias', '30/29',
           CONCAT(SUM(nivel_id = 1), '/', SUM(nivel_id = 2)), IF(SUM(nivel_id = 1) = 30 AND SUM(nivel_id = 2) = 29, 'OK', 'FALLA')
    FROM carreras;
INSERT INTO pruebas_tmp.resultados (prueba, esperado, obtenido, estado)
    SELECT 'Festivos de 2026 y 2027', '18/18',
           CONCAT(SUM(YEAR(fecha) = 2026), '/', SUM(YEAR(fecha) = 2027)), IF(SUM(YEAR(fecha) = 2026) = 18 AND SUM(YEAR(fecha) = 2027) = 18, 'OK', 'FALLA')
    FROM festivos;

SELECT n, estado, esperado, obtenido, prueba FROM pruebas_tmp.resultados ORDER BY n;
SELECT CONCAT(SUM(estado = 'OK'), ' de ', COUNT(*), ' pruebas OK') AS total FROM pruebas_tmp.resultados;
DROP DATABASE pruebas_tmp;
