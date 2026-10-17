-- =============================================================================
-- Nombres de los roles de docente (decisión del 2026-10-16), para una base que ya
-- tiene datos y no se quiere volver a crear. Los ids no cambian (el código decide por
-- el id): 3 = Docente director, 4 = Docente evaluador. Correrlo dos veces no hace nada más.
--
-- Uso (MySQL encendido), desde la carpeta del proyecto:
--   C:\xampp\mysql\bin\mysql.exe -u root --default-character-set=utf8mb4 sistemas_proyectos_grado < bd\migracion-roles-docente.sql
-- Quien tenga la sesión abierta ve el nombre nuevo al volver a entrar.
-- =============================================================================

UPDATE roles SET nombre = 'Docente director',
                 descripcion = 'Docente que dirige o codirige proyectos; también registra ideas en el banco'
WHERE id = 3;

UPDATE roles SET nombre = 'Docente evaluador',
                 descripcion = 'Docente que evalúa proyectos aprobados por el director; también registra ideas en el banco'
WHERE id = 4;

SELECT id, nombre FROM roles ORDER BY id;
