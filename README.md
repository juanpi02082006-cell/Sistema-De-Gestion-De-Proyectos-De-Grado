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
| `director.prueba@uts.edu.co` | Director |
| `evaluador.prueba@uts.edu.co` | Evaluador |
| `estudiante.prueba@correo.uts.edu.co` | Estudiante |
| `docente.prueba@uts.edu.co` | Director y Evaluador |

Los estudiantes nuevos se registran solos desde el enlace "Regístrate" del inicio de sesión.

## Pruebas

Con MySQL y Tomcat encendidos, desde la carpeta del proyecto. Antes de cada prueba hay que importar la base, y al final otra vez para dejarla limpia:

```bash
C:/xampp/mysql/bin/mysql.exe -u root --default-character-set=utf8mb4 < pruebas/base-de-datos.sql
bash pruebas/sprints2-3.sh
bash pruebas/sprint4.sh
bash pruebas/sprint5.sh
bash pruebas/sprint5b.sh
```

## Estructura del proyecto

```
.
├── index.jsp, registro.jsp   # inicio de sesión y registro del estudiante
├── acceso/                   # validar, registrar, elegir rol, salir
├── panel/                    # inicio, calendario y modalidades (todos los roles)
├── admin/                    # usuarios, roles, periodos y modalidades (administrador)
├── ideas/                    # banco de ideas
├── estudiante/               # habilitación, mi proyecto y pago
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
