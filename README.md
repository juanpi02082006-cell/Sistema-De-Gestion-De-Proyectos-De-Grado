# Sistemas de Información Proyectos de Grado

Sistema web para la gestión y el seguimiento de los trabajos de grado de las Unidades Tecnológicas de Santander (UTS). Segundo parcial de Programación en Java (tema: JSTL).

## Estado

Sprints 2, 3 y 4 hechos:
- inicio de sesión con correo institucional;
- usuarios y roles;
- registro del estudiante y su habilitación;
- periodos y calendario;
- modalidades;
- banco de ideas;
- pago de la fase 1 (recibo en PDF) y seguimiento del proyecto por fases;
- calendario de sesiones del comité.

Sprint 5 en progreso, con todas las fases del proyecto:
- pago de cada estudiante, integrantes, director, evaluador y codirectores;
- propuesta (FDC-124) con versiones, revisión del director con Turnitin, evaluación con la rejilla del F-DC-124 y decisión del comité con acta;
- informe final (FDC-125) con los seguimientos del director, evaluación con la rejilla del F-DC-129 y decisión del comité;
- fase final: el comité programa la sustentación y, después de que se hace, registra la aprobación final (el proyecto queda "Finalizado");
- prórrogas, cancelaciones automáticas, exoneración por Saber TyT, Seminario, avisos, PQR y auditoría.

El plan de trabajo está en [docs/sprints.md](docs/sprints.md) y los requerimientos en [docs/requerimientos.md](docs/requerimientos.md).

## Tecnologías

- Java con JSP + JSTL 3.0, sobre Apache Tomcat 11 (Jakarta) de XAMPP.
- MySQL (en local, MariaDB 10.4 de XAMPP).
- Bootstrap 5 y la fuente Plus Jakarta Sans (desde CDN).

## Requisitos previos

- XAMPP con MySQL y Tomcat 11.
- JDK 17 o superior.
- Los `.jar` de `WEB-INF/lib` (ya vienen en el repositorio): JSTL 3.0 y `mysql-connector-j`.

## Instalación

1. Clonar el repositorio dentro de `C:\xampp\tomcat\webapps\` con el nombre `segundo-parcial`:

   ```bat
   cd C:\xampp\tomcat\webapps
   git clone <url-del-repo> segundo-parcial
   ```

2. Encender **MySQL** desde el panel de XAMPP y crear la base. El script borra la base y la vuelve a crear:

   ```bat
   cd C:\xampp\tomcat\webapps\segundo-parcial
   C:\xampp\mysql\bin\mysql.exe -u root < bd\sistemas_proyectos_grado.sql
   ```

3. Encender **Tomcat** desde el panel de XAMPP y abrir `http://localhost:8080/segundo-parcial/`.

La conexión a la base está en `WEB-INF/web.xml` (usuario `root` sin contraseña, como en XAMPP).

## Usuarios de prueba

Todos tienen la contraseña `123456`.

| Correo | Rol |
| --- | --- |
| `admin.prueba@uts.edu.co` | Administrador (es el comité de trabajos de grado) |
| `director.prueba@uts.edu.co` | Docente director |
| `evaluador.prueba@uts.edu.co` | Docente evaluador |
| `estudiante.prueba@correo.uts.edu.co` | Estudiante |
| `docente.prueba@uts.edu.co` | Docente director y Docente evaluador: entra directo y en el menú le salen las dos opciones |

Los estudiantes nuevos se registran solos desde el enlace "Regístrate" del inicio de sesión.

Si tu base ya tiene datos y es de antes del 2026-10-16, los roles de docente todavía se llaman "Director" y "Evaluador". Para ponerles los nombres nuevos sin perder nada:

```bat
C:\xampp\mysql\bin\mysql.exe -u root --default-character-set=utf8mb4 sistemas_proyectos_grado < bd\migracion-roles-docente.sql
```

## Pruebas

Con MySQL y Tomcat encendidos, desde la carpeta del proyecto. Antes de cada prueba hay que importar la base, y al final otra vez para dejarla limpia:

```bash
C:/xampp/mysql/bin/mysql.exe -u root --default-character-set=utf8mb4 < pruebas/base-de-datos.sql
bash pruebas/sprints2-3.sh
bash pruebas/sprint4.sh
bash pruebas/sprint5.sh
bash pruebas/sprint5b.sh
bash pruebas/sprint5c.sh
bash pruebas/sprint5d.sh
bash pruebas/sprint7.sh    # buscador, informes del comité, contador de la fase 4, entregables y búsquedas con 5.000 proyectos
bash pruebas/qa.sh          # permisos de cada rol, datos de otros, XSS, SQL, archivos y sesión
bash pruebas/interfaz.sh    # todas las páginas en Chrome y Brave, en computador y celular
bash pruebas/usuario.sh     # pruebas de usuario: estudiantes que se registran y recorren las fases
```

`bash pruebas/correr-pruebas.sh <carpeta-respaldo>` corre todas: respalda la base y los archivos subidos, importa la base antes de cada suite y al final lo devuelve todo. `interfaz` y `usuario` usan navegadores reales (Node, `playwright-core`, Chrome y Brave), así que se piden por su nombre: `bash pruebas/correr-pruebas.sh <carpeta-respaldo> interfaz usuario`.

Las **pruebas de usuario** (`usuario.sh`) usan el sistema desde Chrome como lo usaría la gente, desde la base recién creada: el comité crea y activa el periodo, el docente registra ideas, ocho estudiantes se registran (dos desde el celular) y cada proyecto recorre sus fases llenando los formularios y escogiendo archivos. Recorren el camino completo hasta "Finalizado" (con un recibo devuelto, la propuesta devuelta por el director y aplazada por el comité, el informe devuelto, la sustentación reprogramada), la propuesta no aprobada, la idea propia con cambio de modalidad y exoneración por Saber TyT, la prórroga con el plazo vencido, el Seminario, la PQR y los avisos. Para adelantar el tiempo usan `bd\demo-adelantar-tiempo.bat`.

## Demostración: adelantar el tiempo

El sistema respeta los plazos del reglamento: el informe final se envía desde el día 90 después de que el comité aprueba la propuesta (RF31), y la aprobación final se registra después de la sustentación (RF39). Para mostrar el flujo completo sin esperar, hay un script **solo para la demostración** que "adelanta el tiempo" de un proyecto (las reglas no cambian):

```bat
bd\demo-adelantar-tiempo.bat 65-2026-2/1
```

Con el código del proyecto (sale en "Datos del proyecto"):

- **En la fase 4**, con la propuesta aprobada: corre las fechas lo que falta para el día 90 (aprobación del FDC-124, notificación, fecha límite y prórrogas aprobadas). El estudiante ya puede enviar el informe y le queda el plazo que tendría en el día 90. Correrlo otra vez no hace nada.
- **En la fase final**, con la sustentación programada: la deja como hecha hace una hora, para que el comité registre la aprobación final.

Solo toca ese proyecto. Para la presentación sirve mostrar primero que el sistema no deja enviar el informe antes del día 90, correr el script y mostrar que ya deja.

## Estructura del proyecto

```
.
├── index.jsp, registro.jsp   # inicio de sesión y registro del estudiante
├── acceso/                   # validar, registrar, elegir rol, salir
├── panel/                    # inicio, calendario, modalidades, avisos, PQR y sustentación (todos los roles)
├── admin/                    # usuarios, roles, periodos, modalidades, proyectos, PQR y auditoría (administrador, que es el comité)
├── director/                 # proyectos que dirige: revisión de la propuesta y del informe, seguimientos
├── evaluador/                # evaluaciones con las rejillas del F-DC-124 y del F-DC-129
├── ideas/                    # banco de ideas
├── estudiante/               # habilitación, mi proyecto, pago, propuesta e informe final
├── archivos/                 # ver un archivo subido (revisa los permisos)
├── css/, img/                # estilo (verde lima y negro) y logo
├── WEB-INF/                  # web.xml, fragmentos .jspf, librerías y archivos subidos (archivos/, fuera de Git)
├── bd/                       # script de la base y diagramas entidad-relación
├── pruebas/                  # pruebas de la base y de punta a punta
└── docs/                     # requerimientos, sprints y base de datos
```

## Documentación

- [Requerimientos](docs/requerimientos.md)
- [Sprints](docs/sprints.md)
- [Base de datos](docs/base-de-datos.md)
