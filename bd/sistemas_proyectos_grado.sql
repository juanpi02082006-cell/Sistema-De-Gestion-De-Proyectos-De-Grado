-- =============================================================================
-- Base de datos: Sistemas de Información Proyectos de Grado (versión 4)
-- Versión 1: Sprint 2 (2026-09-30). Versión 2: segunda entrevista (2026-10-05).
-- Versión 3: reglamento y decisiones del equipo (2026-10-06): 4 roles (el
-- administrador es el comité), fases 1 a 5, registro del estudiante, plan de
-- estudios, integrantes por modalidad, codirectores, seguimientos y festivos.
-- Versión 4: lista de otro equipo (2026-10-08): Metodología aprobada, estado del
-- periodo, versiones de los documentos, evaluación en borrador con la rejilla del
-- F-DC-124 y del F-DC-129, solicitudes de cambio de modalidad y
-- tipo de acción en el historial.
-- 2026-10-10: fases del sistema actual (0 a 5 y final), calendario de sesiones del
-- comité y sustentaciones (fecha y lugar).
-- Versión 5 (2026-10-10): catálogo de carreras de la UTS (el nivel se toma de la
-- carrera; "Ingeniería" pasa a llamarse "Universitario"), avisos dentro del sistema,
-- solicitudes de exoneración por Saber TyT, observaciones de los codirectores, tipos
-- de PQR y festivos de 2027.
-- Cada ENUM lleva CHECK (columna <> ''): MariaDB de XAMPP no está en modo estricto y
-- guardaría un valor inválido como '' con solo una advertencia.
--
-- Diseño explicado en docs/base-de-datos.md; diagrama en bd/diagrama-entidad-relacion.png.
-- Los requerimientos se citan como RF/RNF (docs/requerimientos.md). Los
-- comentarios de la versión 2 usan "punto N" y "A-xx" (columna Origen).
-- Referencia: base original de la UTS "sistemastg" (solo la estructura y los
-- catálogos institucionales; no se copian datos de personas).
--
-- Importar (con MySQL encendido en el panel de XAMPP):
--   C:\xampp\mysql\bin\mysql.exe -u root < bd\sistemas_proyectos_grado.sql
--
-- ¡ATENCIÓN! Este script BORRA la base y la vuelve a crear desde cero.
-- Si ya tiene datos que importan, haga una copia antes de ejecutarlo.
-- =============================================================================

SET NAMES utf8mb4;

DROP DATABASE IF EXISTS sistemas_proyectos_grado;
CREATE DATABASE sistemas_proyectos_grado
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE sistemas_proyectos_grado;

-- -----------------------------------------------------------------------------
-- Catálogos
-- -----------------------------------------------------------------------------

-- 4 roles. Un usuario puede tener varios (usuario_roles).
-- El Administrador es el comité de trabajos de grado (RF7, RF10, RF14).
-- El id 2 (Coordinación) ya no se usa; los demás conservan su id porque el
-- código decide por el id (1 Administrador, 5 Estudiante).
CREATE TABLE roles (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(30)  NOT NULL,
    descripcion VARCHAR(255) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_roles_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE tipos_documentos (
    id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(50)  NOT NULL,
    sigla  VARCHAR(10)  NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_tipos_documentos_nombre (nombre)
) ENGINE=InnoDB;

-- Nivel del estudiante y de la idea (RF25, RF40).
CREATE TABLE niveles (
    id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(50)  NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_niveles_nombre (nombre)
) ENGINE=InnoDB;

-- Modalidades del reglamento, menos Práctica (RF4).
-- max_integrantes (RF36): individual o hasta 2; hasta 3 en Proyecto de
-- investigación y Desarrollo tecnológico. Los interdisciplinarios admiten
-- hasta 4 (RF13): ese caso lo controla la aplicación con proyectos.interdisciplinario.
CREATE TABLE modalidades (
    id              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    nombre          VARCHAR(100)     NOT NULL,
    descripcion     TEXT             NULL,
    max_integrantes TINYINT UNSIGNED NOT NULL DEFAULT 2,
    PRIMARY KEY (id),
    UNIQUE KEY uq_modalidades_nombre (nombre),
    CONSTRAINT chk_modalidades_max_integrantes CHECK (max_integrantes BETWEEN 1 AND 4)
) ENGINE=InnoDB;

-- Carreras de la UTS (lista oficial entregada por el equipo el 2026-10-10). Una
-- misma carrera puede ofrecerse en varios campus: cada oferta tiene su propio código
-- SNIES. El nivel del estudiante se toma de su carrera (RF24, RF25).
CREATE TABLE carreras (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(150) NOT NULL,
    nivel_id    INT UNSIGNED NOT NULL,
    snies       VARCHAR(10)  NULL COMMENT 'Código SNIES de la oferta; NULL si falta el dato',
    campus      VARCHAR(60)  NOT NULL,
    metodologia ENUM('Presencial', 'Virtual') NOT NULL DEFAULT 'Presencial',
    PRIMARY KEY (id),
    UNIQUE KEY uq_carreras_snies (snies),
    UNIQUE KEY uq_carreras_nombre_campus (nombre, campus),
    CONSTRAINT fk_carreras_nivel FOREIGN KEY (nivel_id) REFERENCES niveles (id),
    CONSTRAINT chk_carreras_metodologia_valido CHECK (metodologia <> '')
) ENGINE=InnoDB;

CREATE TABLE lineas_investigacion (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(100) NOT NULL,
    descripcion TEXT         NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_lineas_investigacion_nombre (nombre)
) ENGINE=InnoDB;

-- Fases del proyecto (RF37): de la 0 a la 5 y la fase final, como en el sistema
-- actual de la UTS. La creación del usuario no es una fase (la hace el administrador).
CREATE TABLE fases (
    id          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    orden       TINYINT UNSIGNED NOT NULL,
    nombre      VARCHAR(100)     NOT NULL,
    descripcion VARCHAR(255)     NULL,
    formato     VARCHAR(20)      NULL COMMENT 'Código del formato, por ejemplo FDC-124 (por definir)',
    PRIMARY KEY (id),
    UNIQUE KEY uq_fases_orden (orden)
) ENGINE=InnoDB;

-- Festivos de Colombia, para calcular los días hábiles de los plazos (RNF19).
CREATE TABLE festivos (
    fecha  DATE         NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    PRIMARY KEY (fecha)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Usuarios (RF1, RF7, RF8, RF24, RF29, RNF14)
-- -----------------------------------------------------------------------------

-- A los docentes los registra el administrador (cédula, correo y nombre, RF7);
-- los estudiantes se registran solos (RF24).
CREATE TABLE usuarios (
    id                  INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    nombre              VARCHAR(150)      NOT NULL COMMENT 'Nombre completo',
    tipo_documento_id   INT UNSIGNED      NOT NULL,
    numero_documento    VARCHAR(20)       NOT NULL COMMENT 'Cédula del docente o documento del estudiante',
    correo              VARCHAR(150)      NOT NULL COMMENT 'Correo institucional; se usa para iniciar sesión (RF1)',
    contrasena          CHAR(64)          NOT NULL COMMENT 'SHA-256 en hexadecimal: SHA2(clave, 256) (RNF4)',
    celular             VARCHAR(20)       NULL,
    nivel_id            INT UNSIGNED      NULL COMMENT 'Solo estudiantes: el de su carrera (RF24)',
    carrera_id          INT UNSIGNED      NULL COMMENT 'Solo estudiantes (RF24)',
    plan_estudios       ENUM('Anterior', 'Nuevo') NULL COMMENT 'Solo estudiantes: plan anterior o posterior al decreto 1330 de 2019 (RF24)',
    porcentaje_creditos TINYINT UNSIGNED  NULL COMMENT 'Solo estudiantes: % de créditos aprobados (RF29)',
    puntaje_saber_tyt   SMALLINT UNSIGNED NULL COMMENT 'Solo estudiantes de tecnología: puntaje en Saber TyT, para los estímulos (RNF14). Ingeniería presenta Saber Pro, que no está en el sistema',
    metodologia_aprobada TINYINT(1)       NULL COMMENT 'Solo estudiantes: aprobó Metodología de la investigación o un curso equivalente (RF24, RF29)',
    activo              TINYINT(1)        NOT NULL DEFAULT 1,
    creado_en           TIMESTAMP         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en      TIMESTAMP         NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_usuarios_correo (correo),
    UNIQUE KEY uq_usuarios_documento (numero_documento),
    CONSTRAINT fk_usuarios_tipo_documento FOREIGN KEY (tipo_documento_id) REFERENCES tipos_documentos (id),
    CONSTRAINT fk_usuarios_nivel          FOREIGN KEY (nivel_id)          REFERENCES niveles (id),
    CONSTRAINT fk_usuarios_carrera        FOREIGN KEY (carrera_id)        REFERENCES carreras (id),
    -- RF1: solo correos institucionales de la UTS.
    CONSTRAINT chk_usuarios_correo_institucional
        CHECK (LOWER(correo) LIKE '%@uts.edu.co' OR LOWER(correo) LIKE '%@correo.uts.edu.co'),
    CONSTRAINT chk_usuarios_porcentaje_creditos
        CHECK (porcentaje_creditos IS NULL OR porcentaje_creditos <= 100),
    CONSTRAINT chk_usuarios_plan_estudios_valido CHECK (plan_estudios <> ''),
    CONSTRAINT chk_usuarios_metodologia CHECK (metodologia_aprobada IS NULL OR metodologia_aprobada IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE usuario_roles (
    usuario_id INT UNSIGNED NOT NULL,
    rol_id     INT UNSIGNED NOT NULL,
    PRIMARY KEY (usuario_id, rol_id),
    CONSTRAINT fk_usuario_roles_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
    CONSTRAINT fk_usuario_roles_rol     FOREIGN KEY (rol_id)     REFERENCES roles (id)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Periodos e ideas
-- -----------------------------------------------------------------------------

-- Calendario de cada periodo, configurable a mano cada semestre (RF3):
-- banco de ideas hasta la semana 4, pago hasta la semana 8, propuesta aprobada
-- hasta la semana 12 y fechas del informe final (entre 90 y 180 días).
-- El comité crea, activa y cierra los periodos (estado).
CREATE TABLE periodos (
    id                         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre                     VARCHAR(10)  NOT NULL COMMENT 'Por ejemplo 2026-2',
    estado                     ENUM('Planeado', 'Activo', 'Cerrado') NOT NULL DEFAULT 'Planeado',
    fecha_inicio_semestre      DATE         NULL,
    fecha_cierre_banco         DATE         NULL COMMENT 'Semana 4',
    fecha_limite_pago          DATE         NULL COMMENT 'Semana 8 (RF32)',
    fecha_limite_propuestas    DATE         NULL COMMENT 'Semana 12 (RF30)',
    fecha_inicio_informe_final DATE         NULL,
    fecha_fin_informe_final    DATE         NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_periodos_nombre (nombre),
    CONSTRAINT chk_periodos_estado_valido CHECK (estado <> '')
) ENGINE=InnoDB;

-- Banco de ideas (RF10, RF25): las registran los docentes, y el estudiante puede
-- formular su propia propuesta; el comité (el administrador) aprueba ambas.
CREATE TABLE ideas (
    id                     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    titulo                 VARCHAR(255) NOT NULL,
    descripcion            TEXT         NULL,
    nivel_id               INT UNSIGNED NOT NULL,
    modalidad_id           INT UNSIGNED NULL,
    linea_investigacion_id INT UNSIGNED NULL,
    periodo_id             INT UNSIGNED NULL,
    origen                 ENUM('Docente', 'Estudiante') NOT NULL COMMENT 'Idea de un docente o propuesta de un estudiante',
    propuesta_por          INT UNSIGNED NOT NULL COMMENT 'Docente que la registra o estudiante que la formula',
    estado                 ENUM('Pendiente', 'Aprobada', 'Rechazada', 'Tomada') NOT NULL DEFAULT 'Pendiente',
    revisada_por           INT UNSIGNED NULL COMMENT 'Administrador (comité) que la aprobó o rechazó',
    observacion_revision   TEXT         NULL,
    creado_en              TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_ideas_nivel     FOREIGN KEY (nivel_id)               REFERENCES niveles (id),
    CONSTRAINT fk_ideas_modalidad FOREIGN KEY (modalidad_id)           REFERENCES modalidades (id),
    CONSTRAINT fk_ideas_linea     FOREIGN KEY (linea_investigacion_id) REFERENCES lineas_investigacion (id),
    CONSTRAINT fk_ideas_periodo   FOREIGN KEY (periodo_id)             REFERENCES periodos (id),
    CONSTRAINT fk_ideas_propuesta FOREIGN KEY (propuesta_por)          REFERENCES usuarios (id),
    CONSTRAINT fk_ideas_revisada  FOREIGN KEY (revisada_por)           REFERENCES usuarios (id),
    CONSTRAINT chk_ideas_origen_valido CHECK (origen <> ''),
    CONSTRAINT chk_ideas_estado_valido CHECK (estado <> '')
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Proyectos (RF9, RF11, RF13, RF30, RF31, RF35–RF40)
-- -----------------------------------------------------------------------------

CREATE TABLE proyectos (
    id                   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    codigo               VARCHAR(30)  NULL COMMENT 'prefijo-año-periodo-consecutivo (RF40), ej.: 65-2026-1/200',
    titulo               VARCHAR(255) NOT NULL,
    descripcion          TEXT         NULL,
    idea_id              INT UNSIGNED NULL,
    modalidad_id         INT UNSIGNED NOT NULL,
    nivel_id             INT UNSIGNED NOT NULL,
    periodo_id           INT UNSIGNED NULL,
    fase_id              INT UNSIGNED NULL,
    estado               ENUM('Pendiente', 'En curso', 'Aprobado', 'Rechazado', 'Finalizado', 'Cancelado') NOT NULL DEFAULT 'Pendiente',
    interdisciplinario   TINYINT(1)   NOT NULL DEFAULT 0 COMMENT 'RF13: con codirectores y hasta 4 estudiantes',
    director_id          INT UNSIGNED NULL,
    evaluador_id         INT UNSIGNED NULL,
    fecha_inicio         DATE         NULL,
    fecha_aprobacion_124 DATE         NULL COMMENT 'Aprobación total del FDC-124 por el comité: desde aquí se cuentan los 90 días mínimos y los 180 para entregar el FDC-125 (RF31, RF38)',
    fecha_notificacion   DATE         NULL COMMENT 'Notificación de la aprobación al estudiante (dato del F-DC-124)',
    fecha_limite         DATE         NULL COMMENT 'Fecha límite vigente (180 días desde la aprobación del FDC-124, más las prórrogas, RF38)',
    creado_en            TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en       TIMESTAMP    NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_proyectos_codigo (codigo),
    KEY idx_proyectos_titulo (titulo),
    CONSTRAINT fk_proyectos_idea      FOREIGN KEY (idea_id)      REFERENCES ideas (id),
    CONSTRAINT fk_proyectos_modalidad FOREIGN KEY (modalidad_id) REFERENCES modalidades (id),
    CONSTRAINT fk_proyectos_nivel     FOREIGN KEY (nivel_id)     REFERENCES niveles (id),
    CONSTRAINT fk_proyectos_periodo   FOREIGN KEY (periodo_id)   REFERENCES periodos (id),
    CONSTRAINT fk_proyectos_fase      FOREIGN KEY (fase_id)      REFERENCES fases (id),
    CONSTRAINT fk_proyectos_director  FOREIGN KEY (director_id)  REFERENCES usuarios (id),
    CONSTRAINT fk_proyectos_evaluador FOREIGN KEY (evaluador_id) REFERENCES usuarios (id),
    -- RF11: un docente nunca evalúa el proyecto que dirige.
    CONSTRAINT chk_proyectos_director_evaluador
        CHECK (director_id IS NULL OR evaluador_id IS NULL OR director_id <> evaluador_id),
    CONSTRAINT chk_proyectos_estado_valido CHECK (estado <> '')
) ENGINE=InnoDB;

-- Codirectores de los proyectos interdisciplinarios (RF13): hasta 2 por
-- proyecto; ese límite lo controla la aplicación.
CREATE TABLE proyecto_codirectores (
    proyecto_id INT UNSIGNED NOT NULL,
    docente_id  INT UNSIGNED NOT NULL,
    PRIMARY KEY (proyecto_id, docente_id),
    CONSTRAINT fk_proyecto_codirectores_proyecto FOREIGN KEY (proyecto_id) REFERENCES proyectos (id) ON DELETE CASCADE,
    CONSTRAINT fk_proyecto_codirectores_docente  FOREIGN KEY (docente_id)  REFERENCES usuarios (id)
) ENGINE=InnoDB;

-- Integrantes del proyecto (RF35, RF36, RNF14).
-- vigente = 1 mientras el proyecto sigue; NULL cuando terminó o se canceló.
-- La clave única (estudiante_id, vigente) hace que cada estudiante tenga como
-- máximo UN proyecto vigente (RF35), pero puede empezar otro si el anterior se
-- canceló (RF38). Los NULL no chocan entre sí en una clave única.
-- El número de integrantes (modalidades.max_integrantes, o 4 si es
-- interdisciplinario) lo controla la aplicación.
CREATE TABLE proyecto_estudiantes (
    proyecto_id          INT UNSIGNED NOT NULL,
    estudiante_id        INT UNSIGNED NOT NULL,
    estado               ENUM('Activo', 'Excluido') NOT NULL DEFAULT 'Activo',
    vigente              TINYINT(1)   NULL DEFAULT 1,
    exonerado            TINYINT(1)   NOT NULL DEFAULT 0 COMMENT 'RNF14: exonerado por Saber TyT',
    renuncia_exoneracion TINYINT(1)   NOT NULL DEFAULT 0 COMMENT 'RNF14: renunció a la exoneración (no tiene vuelta atrás)',
    PRIMARY KEY (proyecto_id, estudiante_id),
    UNIQUE KEY uq_proyecto_estudiantes_vigente (estudiante_id, vigente),
    CONSTRAINT fk_proyecto_estudiantes_proyecto   FOREIGN KEY (proyecto_id)   REFERENCES proyectos (id) ON DELETE CASCADE,
    CONSTRAINT fk_proyecto_estudiantes_estudiante FOREIGN KEY (estudiante_id) REFERENCES usuarios (id),
    CONSTRAINT chk_proyecto_estudiantes_vigente CHECK (vigente IS NULL OR vigente = 1),
    -- Solo puede renunciar a la exoneración quien fue exonerado.
    CONSTRAINT chk_proyecto_estudiantes_renuncia CHECK (renuncia_exoneracion = 0 OR exonerado = 1),
    CONSTRAINT chk_proyecto_estudiantes_estado_valido CHECK (estado <> '')
) ENGINE=InnoDB;

-- Archivos del proyecto (RF26, RF29–RF31, RNF15, RNF16): formatos
-- institucionales en Word y anexos en PDF, de hasta 15 MB (lo valida el servidor),
-- y los entregables de la modalidad (evidencias, manual de usuario, código fuente).
-- Versiones (RF43): la propuesta y el informe final llevan version 1, 2, 3…; los
-- archivos que no se versionan (anexos, evidencias…) la dejan en NULL. oficial = 1
-- marca la versión aprobada; NULL en las demás. Como los NULL no chocan en una
-- clave única, cada proyecto tiene una sola versión N y una sola oficial por tipo.
CREATE TABLE entregas (
    id                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    proyecto_id           INT UNSIGNED NOT NULL,
    fase_id               INT UNSIGNED NULL,
    tipo                  ENUM('Propuesta', 'FDC-124', 'FDC-125', 'FDC-129', 'Reporte Turnitin', 'Recibo de pago', 'Anexo', 'Evidencia', 'Manual de usuario', 'Código fuente', 'Certificado Saber TyT') NOT NULL,
    version               SMALLINT UNSIGNED NULL COMMENT 'RF43: 1, 2, 3…; NULL si el archivo no se versiona',
    oficial               TINYINT(1)   NULL DEFAULT NULL COMMENT 'RF43: 1 en la versión aprobada; NULL en las demás',
    nombre_archivo        VARCHAR(255) NOT NULL,
    ruta_archivo          VARCHAR(500) NOT NULL,
    subido_por            INT UNSIGNED NOT NULL,
    subido_en             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_limite_revision DATE         NULL COMMENT 'RF21: evaluador, 3 días hábiles (propuesta) o 5 (informe final); director, 5 días',
    PRIMARY KEY (id),
    UNIQUE KEY uq_entregas_version (proyecto_id, tipo, version),
    UNIQUE KEY uq_entregas_oficial (proyecto_id, tipo, oficial),
    CONSTRAINT fk_entregas_proyecto FOREIGN KEY (proyecto_id) REFERENCES proyectos (id) ON DELETE CASCADE,
    CONSTRAINT fk_entregas_fase     FOREIGN KEY (fase_id)     REFERENCES fases (id),
    CONSTRAINT fk_entregas_usuario  FOREIGN KEY (subido_por)  REFERENCES usuarios (id),
    CONSTRAINT chk_entregas_tipo_valido CHECK (tipo <> ''),
    CONSTRAINT chk_entregas_version CHECK (version IS NULL OR version >= 1),
    CONSTRAINT chk_entregas_oficial CHECK (oficial IS NULL OR oficial = 1)
) ENGINE=InnoDB;

-- Aprobaciones en orden director -> evaluador -> comité (RF14); el comité es el
-- administrador. Resultados del F-DC-124 (RF22): aprobado, aplazado o no aprobado;
-- el comité también puede devolver.
-- La observación es obligatoria en cada aprobación (RF34).
-- El evaluador puede guardar la evaluación en borrador (RF23): la decisión y la
-- observación solo son obligatorias cuando está enviada.
-- Los codirectores (RF13) solo dejan observaciones, sin decisión: decide el director
-- (decisión del equipo, 2026-10-10).
CREATE TABLE revisiones (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    entrega_id  INT UNSIGNED NOT NULL,
    revisor_id  INT UNSIGNED NOT NULL,
    rol         ENUM('Director', 'Codirector', 'Evaluador', 'Comité') NOT NULL,
    estado      ENUM('Borrador', 'Enviada') NOT NULL DEFAULT 'Enviada' COMMENT 'RF23',
    decision    ENUM('Aprobado', 'Aplazado', 'No aprobado', 'Devuelto') NULL,
    nota        DECIMAL(3,1) NULL COMMENT 'Planes nuevos: el informe final se califica con nota (RF42)',
    observacion TEXT         NULL COMMENT 'Observación general (RF34)',
    revisado_en TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_revisiones_entrega FOREIGN KEY (entrega_id) REFERENCES entregas (id) ON DELETE CASCADE,
    CONSTRAINT fk_revisiones_revisor FOREIGN KEY (revisor_id) REFERENCES usuarios (id),
    CONSTRAINT chk_revisiones_enviada
        CHECK (estado = 'Borrador' OR ((decision IS NOT NULL OR rol = 'Codirector') AND observacion IS NOT NULL AND TRIM(observacion) <> '')),
    CONSTRAINT chk_revisiones_codirector CHECK (rol <> 'Codirector' OR decision IS NULL),
    CONSTRAINT chk_revisiones_estado_valido CHECK (estado <> ''),
    CONSTRAINT chk_revisiones_nota CHECK (nota IS NULL OR nota BETWEEN 0 AND 5),
    CONSTRAINT chk_revisiones_rol_valido CHECK (rol <> ''),
    CONSTRAINT chk_revisiones_decision_valido CHECK (decision <> '')
) ENGINE=InnoDB;

-- Rejillas institucionales de evaluación (RF23), cada criterio con sus indicadores
-- (preguntas): F-DC-124 versión 2.0 para la propuesta (12 criterios) y F-DC-129
-- versión 2 para el informe final (17 criterios). El evaluador marca cada indicador.
CREATE TABLE criterios_rejilla (
    id          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    formato     ENUM('FDC-124', 'FDC-129') NOT NULL COMMENT 'FDC-124: propuesta; FDC-129: informe final',
    orden       TINYINT UNSIGNED NOT NULL,
    nombre      VARCHAR(100)     NOT NULL,
    descripcion VARCHAR(255)     NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_criterios_rejilla_orden (formato, orden),
    UNIQUE KEY uq_criterios_rejilla_nombre (formato, nombre),
    CONSTRAINT chk_criterios_rejilla_formato_valido CHECK (formato <> '')
) ENGINE=InnoDB;

-- Indicadores de cada criterio de la rejilla (RF23), tal como están en los formatos.
CREATE TABLE indicadores_rejilla (
    id          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    criterio_id INT UNSIGNED     NOT NULL,
    orden       TINYINT UNSIGNED NOT NULL,
    pregunta    VARCHAR(400)     NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_indicadores_rejilla_orden (criterio_id, orden),
    CONSTRAINT fk_indicadores_rejilla_criterio FOREIGN KEY (criterio_id) REFERENCES criterios_rejilla (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Criterios que aplican a cada modalidad (RF23). En el F-DC-124, el estado del arte
-- solo aplica a Proyecto de investigación y Desarrollo tecnológico, y Seminario no
-- usa ese formato. En el F-DC-129 aplican todos y el evaluador marca N/A lo que no aplique.
CREATE TABLE criterio_modalidades (
    criterio_id  INT UNSIGNED NOT NULL,
    modalidad_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (criterio_id, modalidad_id),
    CONSTRAINT fk_criterio_modalidades_criterio  FOREIGN KEY (criterio_id)  REFERENCES criterios_rejilla (id) ON DELETE CASCADE,
    CONSTRAINT fk_criterio_modalidades_modalidad FOREIGN KEY (modalidad_id) REFERENCES modalidades (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Respuestas de la rejilla en cada evaluación (RF23): Cumple Sí, No o N/A en cada
-- indicador, con su observación (la observación general va en revisiones). N/A solo
-- existe en el F-DC-129. cumple queda en NULL mientras la evaluación es borrador.
-- Que estén respondidos todos los indicadores antes de enviar, y que "Aprobado" exija
-- todos los que aplican en Sí, lo controla la aplicación (dependen de varias filas).
CREATE TABLE revision_indicadores (
    revision_id  INT UNSIGNED NOT NULL,
    indicador_id INT UNSIGNED NOT NULL,
    cumple       ENUM('Sí', 'No', 'N/A') NULL,
    observacion  TEXT         NULL,
    PRIMARY KEY (revision_id, indicador_id),
    CONSTRAINT fk_revision_indicadores_revision  FOREIGN KEY (revision_id)  REFERENCES revisiones (id) ON DELETE CASCADE,
    CONSTRAINT fk_revision_indicadores_indicador FOREIGN KEY (indicador_id) REFERENCES indicadores_rejilla (id),
    CONSTRAINT chk_revision_indicadores_cumple_valido CHECK (cumple <> '')
) ENGINE=InnoDB;

-- Solicitudes de cambio de modalidad (RF12): las pide el estudiante y las decide
-- el comité, solo antes de aprobar el FDC-124 (eso lo controla la aplicación).
-- Queda el registro de la modalidad anterior y la nueva, quién y cuándo.
CREATE TABLE cambios_modalidad (
    id                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    proyecto_id           INT UNSIGNED NOT NULL,
    modalidad_anterior_id INT UNSIGNED NOT NULL,
    modalidad_nueva_id    INT UNSIGNED NOT NULL,
    solicitado_por        INT UNSIGNED NOT NULL,
    solicitado_en         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo                TEXT         NULL,
    estado                ENUM('Pendiente', 'Aprobada', 'Rechazada') NOT NULL DEFAULT 'Pendiente',
    decidido_por          INT UNSIGNED NULL COMMENT 'Administrador (comité)',
    decidido_en           TIMESTAMP    NULL DEFAULT NULL,
    observacion           TEXT         NULL,
    PRIMARY KEY (id),
    KEY idx_cambios_modalidad_proyecto (proyecto_id, solicitado_en),
    CONSTRAINT fk_cambios_modalidad_proyecto  FOREIGN KEY (proyecto_id)           REFERENCES proyectos (id) ON DELETE CASCADE,
    CONSTRAINT fk_cambios_modalidad_anterior  FOREIGN KEY (modalidad_anterior_id) REFERENCES modalidades (id),
    CONSTRAINT fk_cambios_modalidad_nueva     FOREIGN KEY (modalidad_nueva_id)    REFERENCES modalidades (id),
    CONSTRAINT fk_cambios_modalidad_solicita  FOREIGN KEY (solicitado_por)        REFERENCES usuarios (id),
    CONSTRAINT fk_cambios_modalidad_decide    FOREIGN KEY (decidido_por)          REFERENCES usuarios (id),
    CONSTRAINT chk_cambios_modalidad_distinta CHECK (modalidad_anterior_id <> modalidad_nueva_id),
    CONSTRAINT chk_cambios_modalidad_decision
        CHECK (estado = 'Pendiente' OR (decidido_por IS NOT NULL AND decidido_en IS NOT NULL)),
    CONSTRAINT chk_cambios_modalidad_estado_valido CHECK (estado <> '')
) ENGINE=InnoDB;

-- Seguimientos del director: al menos 2 antes de entregar el informe final (RF20).
CREATE TABLE seguimientos (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    proyecto_id INT UNSIGNED NOT NULL,
    director_id INT UNSIGNED NOT NULL,
    fecha       DATE         NOT NULL,
    observacion TEXT         NOT NULL,
    PRIMARY KEY (id),
    KEY idx_seguimientos_proyecto (proyecto_id, fecha),
    CONSTRAINT fk_seguimientos_proyecto FOREIGN KEY (proyecto_id) REFERENCES proyectos (id) ON DELETE CASCADE,
    CONSTRAINT fk_seguimientos_director FOREIGN KEY (director_id) REFERENCES usuarios (id),
    CONSTRAINT chk_seguimientos_observacion CHECK (TRIM(observacion) <> '')
) ENGINE=InnoDB;

-- Prórrogas (RF38): máximo 3 por proyecto (F-DC-124), de 180 días cada una.
-- La clave única (proyecto_id, numero) y numero IN (1, 2, 3) impiden una cuarta.
CREATE TABLE prorrogas (
    id                 INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    proyecto_id        INT UNSIGNED     NOT NULL,
    numero             TINYINT UNSIGNED NOT NULL COMMENT '1, 2 o 3',
    fecha_solicitud    DATE             NOT NULL,
    nueva_fecha_limite DATE             NOT NULL,
    motivo             TEXT             NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_prorrogas_numero (proyecto_id, numero),
    CONSTRAINT fk_prorrogas_proyecto FOREIGN KEY (proyecto_id) REFERENCES proyectos (id) ON DELETE CASCADE,
    CONSTRAINT chk_prorrogas_numero CHECK (numero IN (1, 2, 3))
) ENGINE=InnoDB;

-- Calendario de sesiones del comité (RF3, RF16): el comité publica al inicio del
-- periodo las fechas en que sesiona. Una sesión por día en cada periodo.
CREATE TABLE sesiones_comite (
    id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    periodo_id INT UNSIGNED NOT NULL,
    fecha      DATE         NOT NULL,
    hora       TIME         NULL,
    lugar      VARCHAR(150) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_sesiones_comite_fecha (periodo_id, fecha),
    CONSTRAINT fk_sesiones_comite_periodo FOREIGN KEY (periodo_id) REFERENCES periodos (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Sustentación del proyecto (fase final, RF39): estudiantes, director y evaluador
-- la programan y el sistema guarda la fecha y el lugar (decisión del 2026-10-10).
-- Una por proyecto: si se reprograma, se actualiza.
CREATE TABLE sustentaciones (
    id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    proyecto_id    INT UNSIGNED NOT NULL,
    fecha_hora     DATETIME     NOT NULL,
    lugar          VARCHAR(150) NOT NULL COMMENT 'Salón o medio (por ejemplo, el enlace de la reunión)',
    programada_por INT UNSIGNED NOT NULL,
    programada_en  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_sustentaciones_proyecto (proyecto_id),
    CONSTRAINT fk_sustentaciones_proyecto FOREIGN KEY (proyecto_id)    REFERENCES proyectos (id) ON DELETE CASCADE,
    CONSTRAINT fk_sustentaciones_usuario  FOREIGN KEY (programada_por) REFERENCES usuarios (id),
    CONSTRAINT chk_sustentaciones_lugar CHECK (TRIM(lugar) <> '')
) ENGINE=InnoDB;

-- Actas del comité por proyecto (RF16; igual que en la original).
CREATE TABLE actas (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    proyecto_id INT UNSIGNED NOT NULL,
    numero      INT          NOT NULL,
    fecha       DATE         NOT NULL,
    descripcion TEXT         NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_actas_proyecto FOREIGN KEY (proyecto_id) REFERENCES proyectos (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- PQR en cualquier fase, por ejemplo cambio de director o evaluador (RNF1). El comité
-- las responde (la respuesta es obligatoria) y ve el reporte por tipo y estado.
CREATE TABLE pqrs (
    id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    usuario_id     INT UNSIGNED NOT NULL,
    proyecto_id    INT UNSIGNED NULL,
    tipo           ENUM('Petición', 'Queja', 'Reclamo', 'Cambio de director', 'Cambio de evaluador') NOT NULL DEFAULT 'Petición',
    comentario     TEXT         NOT NULL,
    estado         ENUM('Pendiente', 'Respondida') NOT NULL DEFAULT 'Pendiente',
    respuesta      TEXT         NULL,
    respondida_por INT UNSIGNED NULL,
    respondida_en  TIMESTAMP    NULL DEFAULT NULL,
    creado_en      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_pqrs_usuario     FOREIGN KEY (usuario_id)     REFERENCES usuarios (id),
    CONSTRAINT fk_pqrs_proyecto    FOREIGN KEY (proyecto_id)    REFERENCES proyectos (id) ON DELETE SET NULL,
    CONSTRAINT fk_pqrs_respondida  FOREIGN KEY (respondida_por) REFERENCES usuarios (id),
    CONSTRAINT chk_pqrs_tipo_valido CHECK (tipo <> ''),
    CONSTRAINT chk_pqrs_estado_valido CHECK (estado <> ''),
    CONSTRAINT chk_pqrs_comentario CHECK (TRIM(comentario) <> ''),
    CONSTRAINT chk_pqrs_respuesta
        CHECK (estado = 'Pendiente' OR (respuesta IS NOT NULL AND TRIM(respuesta) <> '' AND respondida_por IS NOT NULL AND respondida_en IS NOT NULL))
) ENGINE=InnoDB;

-- Historial de movimientos de cada proyecto: quién, qué y cuándo (RNF12).
-- Sirve para el seguimiento y para los avisos de cada movimiento (RF5). El
-- administrador lo filtra por usuario, proyecto, tipo de acción y fechas.
CREATE TABLE historial (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    proyecto_id INT UNSIGNED NOT NULL,
    usuario_id  INT UNSIGNED NULL COMMENT 'Quién hizo el movimiento',
    accion      ENUM('Estado', 'Fase', 'Documento', 'Evaluación', 'Decisión', 'Modalidad', 'Otro') NOT NULL DEFAULT 'Otro',
    descripcion VARCHAR(255) NOT NULL COMMENT 'Qué cambió',
    fecha       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_historial_proyecto (proyecto_id, fecha),
    KEY idx_historial_accion (accion, fecha),
    CONSTRAINT fk_historial_proyecto FOREIGN KEY (proyecto_id) REFERENCES proyectos (id) ON DELETE CASCADE,
    CONSTRAINT fk_historial_usuario  FOREIGN KEY (usuario_id)  REFERENCES usuarios (id) ON DELETE SET NULL,
    CONSTRAINT chk_historial_accion_valido CHECK (accion <> '')
) ENGINE=InnoDB;

-- Avisos dentro del sistema (RF5): no se envían correos (decisión del profesor). Cada
-- movimiento le deja un aviso a quien le interesa; las alertas de vencimiento (RNF21)
-- llevan una clave para no repetirse (por ejemplo "pago-10-p12-u5"): los NULL no
-- chocan en la clave única, así que los avisos normales no la necesitan.
CREATE TABLE avisos (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    usuario_id  INT UNSIGNED NOT NULL COMMENT 'A quién va dirigido',
    proyecto_id INT UNSIGNED NULL,
    mensaje     VARCHAR(255) NOT NULL,
    enlace      VARCHAR(255) NULL COMMENT 'Página del sistema, relativa (por ejemplo /estudiante/proyecto.jsp)',
    leido       TINYINT(1)   NOT NULL DEFAULT 0,
    clave       VARCHAR(60)  NULL COMMENT 'Solo las alertas de vencimiento',
    creado_en   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_avisos_clave (usuario_id, clave),
    KEY idx_avisos_usuario (usuario_id, leido, creado_en),
    CONSTRAINT fk_avisos_usuario  FOREIGN KEY (usuario_id)  REFERENCES usuarios (id) ON DELETE CASCADE,
    CONSTRAINT fk_avisos_proyecto FOREIGN KEY (proyecto_id) REFERENCES proyectos (id) ON DELETE CASCADE,
    CONSTRAINT chk_avisos_mensaje CHECK (TRIM(mensaje) <> ''),
    CONSTRAINT chk_avisos_leido CHECK (leido IN (0, 1))
) ENGINE=InnoDB;

-- Solicitudes de exoneración por Saber TyT (RNF14, Acuerdo 01-009; solo nivel
-- tecnológico). El estudiante escribe su puntaje y sube el certificado (entrega de
-- tipo "Certificado Saber TyT"); el comité la aprueba o la rechaza con observación.
-- Si la aprueba, proyecto_estudiantes.exonerado = 1. Estímulos: 120–150, 4.5;
-- 151–170, 4.7 y 50 % de beca; 171 o más, 5.0 y 100 % de beca (se calculan del puntaje).
CREATE TABLE exoneraciones (
    id            INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    proyecto_id   INT UNSIGNED      NOT NULL,
    estudiante_id INT UNSIGNED      NOT NULL,
    puntaje       SMALLINT UNSIGNED NOT NULL,
    entrega_id    INT UNSIGNED      NOT NULL COMMENT 'Certificado de Saber TyT (PDF)',
    estado        ENUM('Pendiente', 'Aprobada', 'Rechazada') NOT NULL DEFAULT 'Pendiente',
    observacion   TEXT              NULL COMMENT 'Del comité (RF34)',
    revisada_por  INT UNSIGNED      NULL,
    revisada_en   TIMESTAMP         NULL DEFAULT NULL,
    creada_en     TIMESTAMP         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_exoneraciones_proyecto (proyecto_id, estudiante_id),
    CONSTRAINT fk_exoneraciones_proyecto   FOREIGN KEY (proyecto_id)   REFERENCES proyectos (id) ON DELETE CASCADE,
    CONSTRAINT fk_exoneraciones_estudiante FOREIGN KEY (estudiante_id) REFERENCES usuarios (id),
    CONSTRAINT fk_exoneraciones_entrega    FOREIGN KEY (entrega_id)    REFERENCES entregas (id) ON DELETE CASCADE,
    CONSTRAINT fk_exoneraciones_revisada   FOREIGN KEY (revisada_por)  REFERENCES usuarios (id),
    CONSTRAINT chk_exoneraciones_puntaje CHECK (puntaje BETWEEN 120 AND 300),
    CONSTRAINT chk_exoneraciones_estado_valido CHECK (estado <> ''),
    CONSTRAINT chk_exoneraciones_revision
        CHECK (estado = 'Pendiente' OR (revisada_por IS NOT NULL AND revisada_en IS NOT NULL
                                        AND observacion IS NOT NULL AND TRIM(observacion) <> ''))
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- Datos iniciales de los catálogos
-- -----------------------------------------------------------------------------

INSERT INTO roles (id, nombre, descripcion) VALUES
    (1, 'Administrador', 'Comité de trabajos de grado: registra a los docentes, aprueba ideas y propuestas y es el último filtro de aprobación'),
    (3, 'Director',      'Docente que dirige y califica proyectos; también registra ideas en el banco'),
    (4, 'Evaluador',     'Docente que evalúa proyectos aprobados por el director; también registra ideas en el banco'),
    (5, 'Estudiante',    'Se registra solo, elige una idea o formula su propuesta y sube los formatos de su proyecto');

INSERT INTO tipos_documentos (id, nombre, sigla) VALUES
    (1, 'Tarjeta de identidad',  'T.I'),
    (2, 'Cédula de ciudadanía',  'C.C'),
    (3, 'Cédula de extranjería', 'Ext.');

INSERT INTO niveles (id, nombre) VALUES
    (1, 'Tecnológico'),
    (2, 'Universitario');

-- Carreras de la UTS, tal como las entregó el equipo (2026-10-10). "Negocios
-- Internacionales" llegó sin nivel, SNIES ni campus: se dejó como universitaria del
-- Campus Virtual, sin SNIES, mientras se completa el dato.
INSERT INTO carreras (id, nombre, nivel_id, snies, campus, metodologia) VALUES
    (1, 'Tecnología en Desarrollo de Sistemas Informáticos', 1, '101597', 'Bucaramanga', 'Presencial'),
    (2, 'Tecnología en Entrenamiento Deportivo', 1, '17664', 'Bucaramanga', 'Presencial'),
    (3, 'Tecnología en Gestión Bancaria y Financiera', 1, '109548', 'Bucaramanga', 'Presencial'),
    (4, 'Tecnología en Gestión de la Moda', 1, '106408', 'Bucaramanga', 'Presencial'),
    (5, 'Tecnología en Gestión de Sistemas de Telecomunicaciones', 1, '108284', 'Bucaramanga', 'Presencial'),
    (6, 'Tecnología en Gestión Empresarial', 1, '11007', 'Bucaramanga', 'Presencial'),
    (7, 'Tecnología en Implementación de Sistemas Electrónicos Industriales', 1, '109017', 'Bucaramanga', 'Presencial'),
    (8, 'Tecnología en Instalación de Sistemas Eléctricos', 1, '118041', 'Bucaramanga', 'Presencial'),
    (9, 'Tecnología en Logística del Transporte', 1, '111645', 'Bucaramanga', 'Presencial'),
    (10, 'Tecnología en Manejo de la Información Contable', 1, '110921', 'Bucaramanga', 'Presencial'),
    (11, 'Tecnología en Manejo de Recursos Ambientales', 1, '101724', 'Bucaramanga', 'Presencial'),
    (12, 'Tecnología en Mercadeo y Gestión Comercial', 1, '103073', 'Bucaramanga', 'Presencial'),
    (13, 'Tecnología en Operación y Mantenimiento Electromecánico', 1, '102378', 'Bucaramanga', 'Presencial'),
    (14, 'Tecnología en Producción Industrial', 1, '107256', 'Bucaramanga', 'Presencial'),
    (15, 'Tecnología en Construcción de Obras Civiles', 1, '111452', 'Piedecuesta', 'Presencial'),
    (16, 'Tecnología en Gestión Agroindustrial', 1, '10349', 'Piedecuesta', 'Presencial'),
    (17, 'Tecnología en Gestión Económica de Proyectos', 1, '116930', 'Piedecuesta', 'Presencial'),
    (18, 'Tecnología en Levantamientos Topográficos', 1, '109015', 'Piedecuesta', 'Presencial'),
    (19, 'Tecnología en Gestión Empresarial', 1, '116905', 'Vélez', 'Presencial'),
    (20, 'Tecnología en Manejo de la Información Contable', 1, '117163', 'Vélez', 'Presencial'),
    (21, 'Tecnología en Manejo de Sistemas Agroforestales', 1, '111742', 'Vélez', 'Presencial'),
    (22, 'Tecnología en Gestión de Recursos Energéticos', 1, '111122', 'Barrancabermeja', 'Presencial'),
    (23, 'Tecnología en Gestión Empresarial', 1, '90358', 'Barrancabermeja', 'Presencial'),
    (24, 'Tecnología en Manejo de la Información Contable', 1, '116931', 'Barrancabermeja', 'Presencial'),
    (25, 'Tecnología en Operación y Mantenimiento Electromecánico', 1, '90531', 'Barrancabermeja', 'Presencial'),
    (26, 'Tecnología en Análisis y Gestión de Datos', 1, '119109', 'Campus Virtual', 'Virtual'),
    (27, 'Tecnología en Gestión Contable', 1, '118008', 'Campus Virtual', 'Virtual'),
    (28, 'Tecnología en Gestión del Comercio Exterior', 1, '119347', 'Campus Virtual', 'Virtual'),
    (29, 'Tecnología en Gestión Empresarial', 1, '107179', 'Campus Virtual', 'Virtual'),
    (30, 'Tecnología en Gestión Turística y Hotelera', 1, '118606', 'Campus Virtual', 'Virtual'),
    (31, 'Administración de Empresas', 2, '53456', 'Bucaramanga', 'Presencial'),
    (32, 'Administración Financiera', 2, '109549', 'Bucaramanga', 'Presencial'),
    (33, 'Contaduría Pública', 2, '90894', 'Bucaramanga', 'Presencial'),
    (34, 'Ingeniería Ambiental', 2, '101707', 'Bucaramanga', 'Presencial'),
    (35, 'Ingeniería de Sistemas', 2, '101596', 'Bucaramanga', 'Presencial'),
    (36, 'Ingeniería de Telecomunicaciones', 2, '53092', 'Bucaramanga', 'Presencial'),
    (37, 'Ingeniería Eléctrica', 2, '106412', 'Bucaramanga', 'Presencial'),
    (38, 'Ingeniería Electromecánica', 2, '90937', 'Bucaramanga', 'Presencial'),
    (39, 'Ingeniería Electrónica', 2, '53390', 'Bucaramanga', 'Presencial'),
    (40, 'Ingeniería en Sistemas de Transporte', 2, '111646', 'Bucaramanga', 'Presencial'),
    (41, 'Ingeniería en Topografía', 2, '109226', 'Bucaramanga', 'Presencial'),
    (42, 'Ingeniería Industrial', 2, '107257', 'Bucaramanga', 'Presencial'),
    (43, 'Mercadeo', 2, '110617', 'Bucaramanga', 'Presencial'),
    (44, 'Profesional en Cultura Física y Deporte', 2, '110922', 'Bucaramanga', 'Presencial'),
    (45, 'Profesional en Diseño de Modas', 2, '106407', 'Bucaramanga', 'Presencial'),
    (46, 'Economía', 2, '116932', 'Piedecuesta', 'Presencial'),
    (47, 'Ingeniería Civil', 2, '111356', 'Piedecuesta', 'Presencial'),
    (48, 'Administración de Empresas', 2, '116816', 'Vélez', 'Presencial'),
    (49, 'Contaduría Pública', 2, '117161', 'Vélez', 'Presencial'),
    (50, 'Ingeniería Agroforestal', 2, '111743', 'Vélez', 'Presencial'),
    (51, 'Administración de Empresas', 2, '103265', 'Barrancabermeja', 'Presencial'),
    (52, 'Contaduría Pública', 2, '116768', 'Barrancabermeja', 'Presencial'),
    (53, 'Ingeniería Electromecánica', 2, '103234', 'Barrancabermeja', 'Presencial'),
    (54, 'Ingeniería en Energías', 2, '111123', 'Barrancabermeja', 'Presencial'),
    (55, 'Administración de Empresas', 2, '107432', 'Campus Virtual', 'Virtual'),
    (56, 'Administración de Empresas Turísticas y Hoteleras', 2, '118607', 'Campus Virtual', 'Virtual'),
    (57, 'Contaduría Pública', 2, '107060', 'Campus Virtual', 'Virtual'),
    (58, 'Ingeniería en Inteligencia Artificial y Ciencia de Datos', 2, '119105', 'Campus Virtual', 'Virtual'),
    (59, 'Negocios Internacionales', 2, NULL, 'Campus Virtual', 'Virtual');

INSERT INTO modalidades (id, nombre, descripcion, max_integrantes) VALUES
    (1, 'Proyecto de investigación', 'Proyecto de investigación', 3),
    (2, 'Desarrollo tecnológico',    'Desarrollo tecnológico',    3),
    (3, 'Monografía',                'Monografía',                2),
    (4, 'Emprendimiento',            'Emprendimiento',            2),
    (5, 'Seminario',                 'Seminario',                 2);

INSERT INTO lineas_investigacion (id, nombre, descripcion) VALUES
    (1, 'Arquitectura y diseño de software', 'Línea de investigación relacionada con arquitectura y diseño de software'),
    (2, 'Internet de las cosas',             'Línea de investigación relacionada con internet de las cosas'),
    (3, 'Realidad aumentada',                'Línea de investigación relacionada con realidad aumentada'),
    (4, 'Transformación digital',            'Línea de investigación relacionada con transformación digital');

-- Fases (RF37), según la pantalla del sistema actual de la UTS y el texto del
-- equipo (2026-10-10). El proyecto se crea en la fase 1, cuando el estudiante toma
-- la idea aprobada; la fase 0 es la aprobación de la idea por el comité. Las
-- descripciones son cortas porque se muestran en las tarjetas del seguimiento; las
-- reglas completas (devoluciones a la fase 2 y a la 3, inicio del FDC-125) están en
-- docs/requerimientos.md, RF37 y Anexo H.
INSERT INTO fases (id, orden, nombre, descripcion, formato) VALUES
    (1, 0, 'Aprobación de la idea', 'El comité aprueba la idea del proyecto', NULL),
    (2, 1, 'Pago',                  'El estudiante toma su idea del banco y sube el pago', NULL),
    (3, 2, 'Propuesta I',           'El estudiante diligencia el FDC-124 y envía la propuesta al director', 'FDC-124'),
    (4, 3, 'Propuesta II',          'El director revisa la propuesta y la pasa por Turnitin; la envía al evaluador y al comité', 'FDC-124'),
    (5, 4, 'Informe I',             'El evaluador analiza la propuesta; con el FDC-124 aprobado, el estudiante envía el informe al director', 'FDC-125'),
    (6, 5, 'Informe II',            'El director envía el informe al evaluador y al comité', 'FDC-125'),
    (7, 6, 'Sustentación',          'Estudiantes, director y evaluador programan la sustentación', NULL);

-- Rejilla del F-DC-124 versión 2.0 (septiembre de 2023), "Propuesta de trabajo de
-- grado: Investigación, Desarrollo Tecnológico, Monografía y Emprendimiento" (RF23).
-- Criterios e indicadores transcritos tal cual del formato.
INSERT INTO criterios_rejilla (id, formato, orden, nombre) VALUES
    (1,  'FDC-124', 1,  'Ficha técnica'),
    (2,  'FDC-124', 2,  'Descripción del problema'),
    (3,  'FDC-124', 3,  'Justificación'),
    (4,  'FDC-124', 4,  'Objetivos'),
    (5,  'FDC-124', 5,  'Estado del arte'),
    (6,  'FDC-124', 6,  'Fundamento teórico'),
    (7,  'FDC-124', 7,  'Resultados esperados'),
    (8,  'FDC-124', 8,  'Plan de actividades'),
    (9,  'FDC-124', 9,  'Presupuesto'),
    (10, 'FDC-124', 10, 'Consideraciones éticas'),
    (11, 'FDC-124', 11, 'Referencias bibliográficas'),
    (12, 'FDC-124', 12, 'Resumen de similitud');

INSERT INTO indicadores_rejilla (criterio_id, orden, pregunta) VALUES
    (1,  1, '¿La ficha técnica relaciona toda la información requerida?'),
    (2,  1, '¿Cumple el máximo de 20 líneas?'),
    (2,  2, '¿Describe claramente la problemática a resolver?'),
    (2,  3, '¿Se evidencia la pregunta concreta de investigación? (expresa la relación entre dos o más variables)'),
    (2,  4, '¿Se ilustran citas bibliográficas en la redacción texto relevantes con respecto a la problemática?'),
    (3,  1, '¿Se evidencia por qué se debe realizar este trabajo de grado?'),
    (3,  2, '¿Se argumenta la necesidad, la conveniencia, las implicaciones tecnológicas, sociales, económicas, entre otras?, es decir el para qué del trabajo a desarrollar?'),
    (3,  3, '¿Genera un aporte al desarrollo de la investigación o al DTeI, del grupo de investigación o de las UTS?'),
    (4,  1, '¿El objetivo general plantea una solución clara la problemática?'),
    (4,  2, 'En el objetivo general y los específicos se evidencia: el ¿qué? ¿Cómo? y el ¿Para qué?'),
    (4,  3, '¿El objetivo general tiene relación con el título de la propuesta de trabajo de grado?'),
    (4,  4, '¿Hay relación entre el cómo del objetivo general y los objetivos específicos?'),
    (4,  5, '¿Se mantiene un orden cronológico en los objetivos específicos?'),
    (5,  1, '¿Se referencian otros casos o estudios a nivel nacional e internacional relacionados con el tema?'),
    (5,  2, '¿Se manejan las citas de acuerdo a la norma APA vigente?'),
    (6,  1, '¿Se evidencian los diferentes fundamentos teóricos, en el desarrollo de la propuesta de trabajo de grado?'),
    (6,  2, '¿Los fundamentos teóricos son coherentes con la solución de la problemática?'),
    (7,  1, '¿Se definen los resultados que se quieren obtener de acuerdo a la metodología planteada?'),
    (8,  1, '¿El tiempo de duración total del trabajo de grado está acorde con lo estipulado en el Reglamento de Trabajo de Grado?'),
    (8,  2, '¿La duración planteada para cada actividad es razonable?'),
    (8,  3, '¿Las actividades planteadas son las necesarias para cumplir con el objetivo general del trabajo de grado?'),
    (9,  1, '¿El presupuesto estipula claramente los costos en recurso humano?'),
    (9,  2, '¿El presupuesto estipula los costos en recursos tecnológicos?'),
    (9,  3, '¿El presupuesto estipula los costos en materiales requeridos?'),
    (9,  4, '¿Se discrimina en el presupuesto el aporte realizado por los autores, las UTS y otras instituciones patrocinadoras, en cada uno de los rubros costeados?'),
    (10, 1, '¿Se evidencia dentro del informe el detalle de las consideraciones éticas que se pueden presentar en su desarrollo?'),
    (11, 1, '¿Las referencias aplican el estándar APA de la edición vigente?'),
    (12, 1, 'El resultado del informe de similitud evidencia un porcentaje de similitud entre el 0 y 10%');

-- Rejilla del F-DC-129 versión 2, "Rejilla de evaluación informe final de trabajo de
-- grado" (RF23). Criterios e indicadores transcritos tal cual del formato.
INSERT INTO criterios_rejilla (id, formato, orden, nombre) VALUES
    (13, 'FDC-129', 1,  'Formato'),
    (14, 'FDC-129', 2,  'Resumen'),
    (15, 'FDC-129', 3,  'Introducción'),
    (16, 'FDC-129', 4,  'Planteamiento de la problemática'),
    (17, 'FDC-129', 5,  'Justificación'),
    (18, 'FDC-129', 6,  'Objetivos'),
    (19, 'FDC-129', 7,  'Estado del arte o Antecedentes'),
    (20, 'FDC-129', 8,  'Marcos referenciales'),
    (21, 'FDC-129', 9,  'Desarrollo del trabajo de grado'),
    (22, 'FDC-129', 10, 'Resultados'),
    (23, 'FDC-129', 11, 'Conclusiones y recomendaciones'),
    (24, 'FDC-129', 12, 'Consideraciones éticas'),
    (25, 'FDC-129', 13, 'Referencias bibliográficas'),
    (26, 'FDC-129', 14, 'Anexos (en caso de aplicar)'),
    (27, 'FDC-129', 15, 'Certificados'),
    (28, 'FDC-129', 16, 'Sustentación'),
    (29, 'FDC-129', 17, 'Índice de similitud');

INSERT INTO indicadores_rejilla (criterio_id, orden, pregunta) VALUES
    (13, 1, '¿El documento cumple con la plantilla establecida?'),
    (13, 2, '¿La portada y la contraportada cumplen con la totalidad de la información solicitada en el formato?'),
    (13, 3, '¿Tiene Tabla de contenido, lista de Figuras y lista de Tablas correctamente diligenciada?'),
    (13, 4, '¿Se cita y referencia las fuentes consultadas para el desarrollo de todos los componentes del documento, de acuerdo con la norma APA?'),
    (13, 5, '¿La redacción del documento se ajusta a las normas sobre escritura de documentos técnicos?'),
    (14, 1, '¿Se cumple con el máximo de 300 palabras?'),
    (14, 2, '¿Presenta un máximo de 5 palabras clave correctas?'),
    (14, 3, '¿El resumen describe claramente: ¿los objetivos, la metodología los resultados y las conclusiones más relevantes del trabajo de grado?'),
    (15, 1, '¿El documento establece los antecedentes suficientes para cubrir el tema?'),
    (15, 2, '¿Se deja claro el método y la técnica empleados para la solución de la problemática?'),
    (16, 1, '¿Se describe las causas que lo ocasionan y los efectos que se generan al no resolver la problemática?'),
    (16, 2, '¿Se evidencia la pregunta concreta que soporta la problemática?'),
    (17, 1, '¿Se evidencia por qué se debe realizar este trabajo de grado?'),
    (17, 2, '¿Se argumenta la necesidad, la conveniencia, las implicaciones tecnológicas, sociales, económicas, entre otras?'),
    (18, 1, '¿Los objetivos generales y específicos son coherentes con el planteamiento del problema y la justificación descrita en el documento?'),
    (18, 2, 'Se encuentran formulados de manera adecuada, inician con un verbo en infinitivo y responden las preguntas ¿qué?, ¿cómo? y ¿para qué?'),
    (18, 3, '¿Cumple con la ejecución o desarrollo total de los objetivos?'),
    (19, 1, '¿Se referencian otros casos o estudios a nivel nacional e internacional relacionados con el tema?'),
    (19, 2, '¿Se manejan las citas de acuerdo a la norma APA vigente?'),
    (20, 1, '¿Se evidencian los diferentes marcos que aplican (teórico, histórico, conceptual, legal y ambiental), en el desarrollo de la propuesta de trabajo de grado?'),
    (20, 2, '¿Los marcos referenciales se soportan en una amplia búsqueda de información?'),
    (20, 3, '¿Los marcos de referencia son coherentes con la solución de la problemática?'),
    (21, 1, '¿Describe cronológicamente todas las fases que se requirieron para ejecutar correctamente el trabajo de grado?'),
    (21, 2, '¿Se consigna la totalidad de información necesaria para que otro estudiante realice el trabajo de grado obteniendo los mismos resultados?'),
    (21, 3, '¿Se detallan todas las pruebas que fueren requeridas para ejecutar el trabajo de grado?'),
    (22, 1, '¿Se evidencian claramente los resultados obtenidos durante la ejecución del trabajo de grado, mediante tablas, ecuaciones, tabulaciones, entre otros?'),
    (22, 2, '¿Se documentan los resultados cuantitativa y cualitativamente?'),
    (22, 3, 'Al leer la sección de resultados ¿se aprecia claramente el cumplimiento de todos los objetivos que requieren validación?'),
    (23, 1, '¿Se describen claramente cuáles fueron los resultados más relevantes del trabajo de grado?'),
    (23, 2, '¿Se indica claramente los resultados obtenidos sin las indicaciones numéricas?'),
    (23, 3, '¿Las conclusiones aportan al lector, conocimiento que solo se obtiene con la realización de ese trabajo de grado?'),
    (23, 4, '¿Se plantean recomendaciones con respecto a trabajos futuros, temas de investigación, aplicación de estrategias, etc.?'),
    (24, 1, 'El documento incluye de forma detallada los anexos correspondientes a las consideraciones éticas (de no ser necesario indicar con N/A)'),
    (25, 1, '¿Las referencias citadas cumplen la norma de citación APA vigente?'),
    (25, 2, '¿Las referencias corresponden a la totalidad de las citas incluidas en el documento?'),
    (25, 3, '¿Emplea un gestor de referencias?'),
    (26, 1, '¿Presenta todos los anexos que se consideren pertinentes para el entendimiento o aclaración del trabajo de grado?'),
    (27, 1, '¿Presenta los certificados propios del producto de investigación asociado al trabajo de grado (Acta de conformidad de la empresa, cámara de comercio, etc.)? Si no presenta productos como resultado de la investigación marcar N/A'),
    (28, 1, '¿Se cumple con los requerimientos establecidos por el evaluador y director?'),
    (29, 1, 'El documento incluye el informe arrojado por la herramienta institucional anti plagio, con un porcentaje de similitud menor o igual al 10%.');

-- Criterios por modalidad.
-- F-DC-124: "El estado del arte aplica para las modalidades de investigación,
-- desarrollo tecnológico. La monografía y emprendimiento no llevan estado de arte".
-- Seminario (5) no usa el F-DC-124 (lo confirmó el equipo el 2026-10-08).
-- F-DC-129: todos los criterios para todas las modalidades; "si algún ítem no aplica
-- dependiendo de la modalidad se debe marcar con N/A".
INSERT INTO criterio_modalidades (criterio_id, modalidad_id)
    SELECT c.id, m.id FROM criterios_rejilla c CROSS JOIN modalidades m
    WHERE (c.formato = 'FDC-124' AND m.id <> 5 AND NOT (c.nombre = 'Estado del arte' AND m.id IN (3, 4)))
       OR c.formato = 'FDC-129';

-- Festivos de Colombia de 2026 y 2027 (RNF19). Hay que agregar los de cada año.
INSERT INTO festivos (fecha, nombre) VALUES
    ('2026-01-01', 'Año Nuevo'),
    ('2026-01-12', 'Día de los Reyes Magos'),
    ('2026-03-23', 'Día de San José'),
    ('2026-04-02', 'Jueves Santo'),
    ('2026-04-03', 'Viernes Santo'),
    ('2026-05-01', 'Día del Trabajo'),
    ('2026-05-18', 'Ascensión del Señor'),
    ('2026-06-08', 'Corpus Christi'),
    ('2026-06-15', 'Sagrado Corazón'),
    ('2026-06-29', 'San Pedro y San Pablo'),
    ('2026-07-20', 'Día de la Independencia'),
    ('2026-08-07', 'Batalla de Boyacá'),
    ('2026-08-17', 'Asunción de la Virgen'),
    ('2026-10-12', 'Día de la Raza'),
    ('2026-11-02', 'Todos los Santos'),
    ('2026-11-16', 'Independencia de Cartagena'),
    ('2026-12-08', 'Inmaculada Concepción'),
    ('2026-12-25', 'Navidad'),
    ('2027-01-01', 'Año Nuevo'),
    ('2027-01-11', 'Día de los Reyes Magos'),
    ('2027-03-22', 'Día de San José'),
    ('2027-03-25', 'Jueves Santo'),
    ('2027-03-26', 'Viernes Santo'),
    ('2027-05-01', 'Día del Trabajo'),
    ('2027-05-10', 'Ascensión del Señor'),
    ('2027-05-31', 'Corpus Christi'),
    ('2027-06-07', 'Sagrado Corazón'),
    ('2027-07-05', 'San Pedro y San Pablo'),
    ('2027-07-20', 'Día de la Independencia'),
    ('2027-08-07', 'Batalla de Boyacá'),
    ('2027-08-16', 'Asunción de la Virgen'),
    ('2027-10-18', 'Día de la Raza'),
    ('2027-11-01', 'Todos los Santos'),
    ('2027-11-15', 'Independencia de Cartagena'),
    ('2027-12-08', 'Inmaculada Concepción'),
    ('2027-12-25', 'Navidad');

-- -----------------------------------------------------------------------------
-- Usuarios de prueba (ficticios). Contraseña de todos: 123456
-- El id 2 queda libre: era el usuario de Coordinación, que ya no es un rol.
-- -----------------------------------------------------------------------------

INSERT INTO usuarios (id, nombre, tipo_documento_id, numero_documento, correo, contrasena, celular, nivel_id, carrera_id, plan_estudios, porcentaje_creditos) VALUES
    (1, 'Administrador de Prueba', 2, '1000000001', 'admin.prueba@uts.edu.co',              SHA2('123456', 256), NULL, NULL, NULL, NULL, NULL),
    (3, 'Director de Prueba',      2, '1000000003', 'director.prueba@uts.edu.co',           SHA2('123456', 256), NULL, NULL, NULL, NULL, NULL),
    (4, 'Evaluador de Prueba',     2, '1000000004', 'evaluador.prueba@uts.edu.co',          SHA2('123456', 256), NULL, NULL, NULL, NULL, NULL),
    (5, 'Estudiante de Prueba',    1, '1000000005', 'estudiante.prueba@correo.uts.edu.co',  SHA2('123456', 256), NULL, 1,    1, 'Anterior', 80),
    (6, 'Docente de Prueba',       2, '1000000006', 'docente.prueba@uts.edu.co',            SHA2('123456', 256), NULL, NULL, NULL, NULL, NULL);

INSERT INTO usuario_roles (usuario_id, rol_id) VALUES
    (1, 1),
    (3, 3),
    (4, 4),
    (5, 5),
    (6, 3),  -- El docente de prueba tiene dos roles: Director
    (6, 4);  -- y Evaluador (para probar el login con varios roles).
