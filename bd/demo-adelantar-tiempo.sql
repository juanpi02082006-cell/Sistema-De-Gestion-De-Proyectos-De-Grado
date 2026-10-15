-- =============================================================================
-- SOLO PARA LA DEMOSTRACIÓN DEL PARCIAL: "adelanta el tiempo" de UN proyecto, para
-- mostrar el flujo completo sin esperar. Las reglas del sistema no cambian.
--
-- Uso (MySQL encendido): bd\demo-adelantar-tiempo.bat 65-2026-2/1
-- (o, desde la carpeta del proyecto:
--  C:\xampp\mysql\bin\mysql.exe -u root -D sistemas_proyectos_grado --default-character-set=utf8mb4
--      -e "SET @codigo = '65-2026-2/1'; SOURCE bd/demo-adelantar-tiempo.sql;")
--
-- Qué hace con el proyecto de ese código (los demás no se tocan):
--   1. Fase 4 (Informe I), con la propuesta aprobada y antes del día 90: corre hacia
--      atrás los días que faltan para el día 90 la fecha de aprobación del FDC-124, la
--      de notificación, la fecha límite y las prórrogas aprobadas, como si ya hubieran
--      pasado. El estudiante ya puede enviar el informe final (RF31) y le quedan los
--      mismos días de plazo que tendría en el día 90. Correrlo dos veces no hace nada más.
--   2. Fase final, con la sustentación programada a futuro: la deja como hecha hace una
--      hora, para que el comité registre la aprobación final (RF39).
-- Un proyecto finalizado o cancelado no se toca.
-- =============================================================================

-- El código llega con la collation de la consola; la base usa utf8mb4_unicode_ci
SET @codigo := CONVERT(@codigo USING utf8mb4) COLLATE utf8mb4_unicode_ci;

SET @dias := (
    SELECT DATEDIFF(p.fecha_aprobacion_124 + INTERVAL 90 DAY, CURDATE())
    FROM proyectos p JOIN fases f ON f.id = p.fase_id
    WHERE p.codigo = @codigo AND f.orden = 4 AND p.fecha_aprobacion_124 IS NOT NULL
      AND p.estado NOT IN ('Finalizado', 'Cancelado')
);

UPDATE prorrogas x JOIN proyectos p ON p.id = x.proyecto_id
SET x.nueva_fecha_limite = x.nueva_fecha_limite - INTERVAL @dias DAY
WHERE p.codigo = @codigo AND x.estado = 'Aprobada' AND @dias > 0;

UPDATE proyectos
SET fecha_aprobacion_124 = fecha_aprobacion_124 - INTERVAL @dias DAY,
    fecha_notificacion   = fecha_notificacion - INTERVAL @dias DAY,
    fecha_limite         = fecha_limite - INTERVAL @dias DAY
WHERE codigo = @codigo AND @dias > 0;

UPDATE sustentaciones s
JOIN proyectos p ON p.id = s.proyecto_id
JOIN fases f ON f.id = p.fase_id
SET s.fecha_hora = NOW() - INTERVAL 1 HOUR
WHERE p.codigo = @codigo AND f.orden = 6 AND s.fecha_hora > NOW()
  AND p.estado NOT IN ('Finalizado', 'Cancelado');

-- Cómo quedó
SELECT CASE WHEN COUNT(*) = 0 THEN CONCAT('No hay un proyecto con el código ', @codigo)
            WHEN @dias > 0 THEN CONCAT('Listo: se adelantaron ', @dias, ' días; el estudiante ya puede enviar el informe final')
            ELSE 'Listo' END AS resultado
FROM proyectos WHERE codigo = @codigo;

SELECT p.codigo, f.orden AS fase, p.estado,
       p.fecha_aprobacion_124 + INTERVAL 90 DAY AS informe_desde, p.fecha_limite,
       s.fecha_hora AS sustentacion
FROM proyectos p
LEFT JOIN fases f ON f.id = p.fase_id
LEFT JOIN sustentaciones s ON s.proyecto_id = p.id
WHERE p.codigo = @codigo;
