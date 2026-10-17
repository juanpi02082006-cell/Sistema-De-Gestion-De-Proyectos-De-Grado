// Pruebas de usuario (2026-10-14): el sistema se usa como lo usaría la gente, en Chrome, desde
// la base recién creada (solo los usuarios de prueba). Todo se hace con la pantalla: llenar
// formularios, escoger archivos, oprimir botones y aceptar las confirmaciones. La base solo se
// lee para comprobar cómo quedó y, como en la demostración, para adelantar el tiempo
// (bd\demo-adelantar-tiempo.bat y el vencimiento del plazo del informe).
//   1. El comité crea y activa el periodo; el docente registra ideas y el comité las revisa.
//   2. Ocho estudiantes se registran (dos desde el celular); errores del registro y del login.
//   3. Camino completo (Ana y Beto): toman la idea, pagan (un recibo devuelto), el comité asigna
//      director, evaluador y codirector; el FDC-124 va y vuelve (devuelto por el director,
//      aplazado por el comité) hasta aprobarse; seguimientos, el FDC-125 (devuelto y aprobado),
//      la rejilla del F-DC-129, la sustentación y la aprobación final: Finalizado.
//   4. Propuesta no aprobada (Dani): se cancela, la idea vuelve al banco y la vuelve a tomar.
//   5. Idea propia (Fer): rechazada, corregida y aprobada; cambio de modalidad; exoneración por
//      Saber TyT: el proyecto termina sin informe.
//   6. Prórroga (Gabi): una aprobada, otra rechazada; vence el plazo y se cancela la modalidad.
//   7. Seminario (Eli y Hugo): documentos, validación del comité y nota final.
//   8. Habilitación (Caro no cumple), PQR respondida, avisos y que el estudiante nunca ve a su
//      evaluador.
// Lo corre pruebas/usuario.sh dentro de correr-pruebas.sh (respalda la base y la devuelve).
const { chromium } = require(process.env.PLAYWRIGHT || 'playwright-core');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const B = 'http://localhost:8080/segundo-parcial';
const PROYECTO = path.join(__dirname, '..');
const CLAVE = '123456';
let ok = 0, falla = 0;
const revisar = (nombre, bien, detalle) => {
    if (bien) ok++; else { falla++; console.log(`  FALLA ${nombre}${detalle ? ' (' + detalle + ')' : ''}`); }
    return bien;
};

// ---------- Base de datos: solo para comprobar y para adelantar el tiempo ----------
const sql = consulta => execFileSync('C:/xampp/mysql/bin/mysql.exe',
    ['-u', 'root', '-N', '-B', '-D', 'sistemas_proyectos_grado', '--default-character-set=utf8mb4', '-e', consulta],
    { encoding: 'utf8' }).replace(/\r/g, '').trim();
const adelantar = codigo => execFileSync('cmd.exe', ['/c', 'bd\\demo-adelantar-tiempo.bat', codigo], { cwd: PROYECTO, encoding: 'utf8' });
// Proyecto vigente de un estudiante: id, código, fase (orden) y estado
const proyectoDe = correo => {
    const [id, codigo, fase, estado] = sql(`SELECT p.id, p.codigo, f.orden, p.estado FROM proyectos p JOIN fases f ON f.id = p.fase_id
        JOIN proyecto_estudiantes pe ON pe.proyecto_id = p.id JOIN usuarios u ON u.id = pe.estudiante_id
        WHERE u.correo = '${correo}' AND pe.vigente = 1`).split('\t');
    return { id, codigo, fase: Number(fase), estado };
};
const estadoProyecto = id => {
    const [fase, estado] = sql(`SELECT f.orden, p.estado FROM proyectos p JOIN fases f ON f.id = p.fase_id WHERE p.id = ${Number(id)}`).split('\t');
    return { fase: Number(fase), estado };
};

// ---------- Archivos que escoge la gente ----------
const TMP = path.join(__dirname, 'tmp', 'usuario');
fs.mkdirSync(TMP, { recursive: true });
const pdf = nombre => { const f = path.join(TMP, nombre); fs.writeFileSync(f, '%PDF-1.4\n1 0 obj << /Type /Catalog >> endobj\ntrailer << /Root 1 0 R >>\n%%EOF\n'); return f; };
const word = nombre => { const f = path.join(TMP, nombre); fs.writeFileSync(f, 'PK\u0003\u0004 documento de Word de prueba'); return f; };

// Fechas como las escribe el navegador (aaaa-mm-dd, hora local)
const dia = (dias = 0) => {
    const d = new Date(); d.setDate(d.getDate() + dias);
    const z = n => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${z(d.getMonth() + 1)}-${z(d.getDate())}`;
};

let navegador;
const erroresJs = [];

// ---------- Una persona con su propio navegador (contexto) y su sesión ----------
class Persona {
    constructor(nombre, correo, opciones = {}) {
        this.nombre = nombre; this.correo = correo;
        this.celular = !!opciones.celular; this.rol = opciones.rol;
    }
    async abrir() {
        if (this.p) return this.p;
        this.contexto = await navegador.newContext({
            viewport: this.celular ? { width: 390, height: 844 } : { width: 1366, height: 900 }, locale: 'es-CO' });
        this.p = await this.contexto.newPage();
        this.p.setDefaultTimeout(15000);
        this.dialogos = [];
        this.p.on('dialog', d => { this.dialogos.push(d.message()); d.accept(); });
        this.p.on('pageerror', e => erroresJs.push(`${this.nombre}: ${e.message}`));
        await this.p.goto(B + '/index.jsp');
        await this.p.fill('#correo', this.correo);
        await this.p.fill('#clave', CLAVE);
        await Promise.all([this.p.waitForNavigation(), this.p.click('button[type=submit]')]);
        // Nadie escoge rol: todos tienen un rol, o los dos de docente (entra directo)
        revisar(`${this.nombre}: inicia sesión${this.celular ? ' desde el celular' : ''}`, this.p.url().includes('/panel/inicio.jsp'), this.p.url());
        return this.p;
    }
    // Opciones de docente que muestra el menú lateral ("Docente director", "Docente evaluador")
    async opcionesDocente() {
        const p = await this.abrir();
        return (await p.locator('.app-lateral-menu a').allInnerTexts()).map(t => t.trim()).filter(t => t.startsWith('Docente'));
    }
    // Abre una opción del menú lateral (en el celular, primero el botón del menú)
    async menu(ruta) {
        const p = await this.abrir();
        const enlace = p.locator(`.app-lateral a[href$="${ruta}"]`).first();
        // En el celular el menú está corrido fuera de la pantalla hasta oprimir el botón
        if (await p.locator('#botonMenu').isVisible()) await p.click('#botonMenu');
        await Promise.all([p.waitForNavigation(), enlace.click()]);
        return p;
    }
    // Desde la lista del menú, abre el proyecto con el botón de su fila
    async proyecto(lista, id) {
        const p = await this.menu(lista);
        await Promise.all([p.waitForNavigation(), p.locator(`a[href$="proyecto.jsp?id=${id}"]`).first().click()]);
        return p;
    }
    async texto() { return (await this.abrir()).locator('body').innerText(); }
    async recargar() { await this.p.reload(); return this.p; }
}

// Lo que dijo el sistema después de una acción: ?ok=, ?error= o el aviso de la pantalla
async function resultado(p) {
    const u = new URL(p.url());
    if (u.searchParams.get('ok')) return 'ok=' + u.searchParams.get('ok');
    if (u.searchParams.get('error')) return 'error=' + u.searchParams.get('error');
    const aviso = p.locator('.alert-danger, .alert-success').first();
    return (await aviso.count()) ? 'aviso: ' + (await aviso.innerText()).trim() : 'sin aviso';
}

// Oprime un botón que envía un formulario y revisa el mensaje. esperado: 'ok=x', 'error=x',
// 'error=*' (cualquier error) o 'aviso: texto' (formularios que vuelven con el error en pantalla)
async function hacer(persona, nombre, boton, esperado) {
    const p = persona.p;
    try {
        await Promise.all([p.waitForNavigation({ timeout: 20000 }), boton.click()]);
    } catch (e) {
        return revisar(`${persona.nombre}: ${nombre}`, false, 'no se pudo: ' + e.message.split('\n')[0]);
    }
    const real = await resultado(p);
    const visible = await p.locator('.alert-danger, .alert-success').first().isVisible().catch(() => false);
    const coincide = esperado.startsWith('aviso:') ? real.includes(esperado.slice(6).trim())
        : esperado.endsWith('*') ? real.startsWith(esperado.slice(0, -1)) : real === esperado;
    return revisar(`${persona.nombre}: ${nombre}`, coincide && visible,
        `esperaba ${esperado}, quedó ${real}${visible ? '' : ', sin aviso en pantalla'}`);
}

// Formulario cuyo action termina en la página dada (y, si se da, que contenga un texto)
const formulario = (p, accion, contiene) => {
    const f = p.locator(`form[action$="${accion}"]`);
    return contiene ? f.filter({ hasText: contiene }).first() : f.first();
};

// Llena la rejilla del evaluador: todos "si", salvo las posiciones de cambios ({ 0: 'no', 3: 'na' })
async function llenarRejilla(p, cambios = {}, todos = 'si') {
    const nombres = await p.$$eval('form[action$="evaluacion-guardar.jsp"] input[type=radio]',
        els => [...new Set(els.map(e => e.name))]);
    for (let i = 0; i < nombres.length; i++) {
        const valor = cambios[i] || todos;
        await p.locator(`label.app-casilla:has(input[name="${nombres[i]}"][value="${valor}"])`).click();
    }
    return nombres.length;
}

// ---------- Pasos que se repiten ----------
async function registrarDocenteIdea(docente, idea) {
    const p = await docente.menu('/ideas/banco.jsp');
    await Promise.all([p.waitForNavigation(), p.click('a[href$="/ideas/idea-form.jsp"]')]);
    await p.fill('#titulo', idea.titulo);
    await p.fill('#descripcion', idea.descripcion);
    await p.selectOption('#nivel', '1');
    await p.selectOption('#modalidad', idea.modalidad || '');
    await hacer(docente, `registra la idea "${idea.titulo}"`, p.locator('form[action$="idea-guardar.jsp"] button[type=submit]'), 'ok=idea-creada');
}

async function revisarIdea(comite, titulo, decision, observacion) {
    const p = await comite.menu('/ideas/banco.jsp');
    const fila = p.locator('tr', { hasText: titulo });
    await fila.locator('textarea[name=observacion]').fill(observacion);
    await hacer(comite, `${decision === 'aprobar' ? 'aprueba' : 'rechaza'} la idea "${titulo}"`,
        fila.locator(`button[name=decision][value=${decision}]`), decision === 'aprobar' ? 'ok=idea-aprobada' : 'ok=idea-rechazada');
}

async function tomarIdea(estudiante, titulo, modalidad) {
    const p = await estudiante.menu('/ideas/banco.jsp');
    const ficha = p.locator('.app-ficha', { hasText: titulo });
    if (modalidad) await ficha.locator('select[name=modalidad]').selectOption(modalidad);
    return hacer(estudiante, `toma la idea "${titulo}"`, ficha.locator('button', { hasText: 'Tomar esta idea' }), 'ok=idea-tomada');
}

async function subirRecibo(estudiante) {
    const p = await estudiante.menu('/estudiante/proyecto.jsp');
    await p.setInputFiles('#recibo', pdf(`recibo-${estudiante.nombre}.pdf`));
    await hacer(estudiante, 'sube su recibo de pago', p.locator('button', { hasText: 'Subir recibo' }), 'ok=pago-subido');
}

async function revisarPago(comite, idProyecto, nombreEstudiante, decision, esperado) {
    const p = await comite.proyecto('/admin/proyectos.jsp', idProyecto);
    const f = p.locator('form[action$="pago-revisar.jsp"]').filter({ has: p.locator(`textarea[aria-label*="${nombreEstudiante}"]`) });
    await f.locator('textarea').fill(decision === 'aprobar' ? 'Recibo con la marca de pagado' : 'El recibo no tiene la marca de pagado');
    await hacer(comite, `${decision === 'aprobar' ? 'aprueba' : 'devuelve'} el recibo de ${nombreEstudiante}`,
        f.locator(`button[value=${decision}]`), esperado);
}

async function asignar(comite, idProyecto, director, evaluador, esperado, extra = {}) {
    const p = await comite.proyecto('/admin/proyectos.jsp', idProyecto);
    const f = p.locator('form[action$="proyecto-asignar.jsp"]').first();
    if (!(await f.isVisible())) await p.locator('summary', { hasText: 'Director y evaluador' }).click();
    await f.locator('#director').selectOption({ label: director });
    await f.locator('#evaluador').selectOption(evaluador ? { label: evaluador } : '');
    if (extra.interdisciplinario) await f.locator('#interdisciplinario').check();
    if (extra.codirector) await f.locator('#codirector1').selectOption({ label: extra.codirector });
    await hacer(comite, `asigna director ${director}${evaluador ? ' y evaluador ' + evaluador : ''}`, f.locator('button[type=submit]'), esperado);
}

async function subirPropuesta(estudiante, version) {
    const p = await estudiante.menu('/estudiante/proyecto.jsp');
    await p.setInputFiles('#propuesta', word(`FDC-124 ${estudiante.nombre} v${version}.docx`));
    await hacer(estudiante, `sube la versión ${version} del FDC-124`, p.locator('button', { hasText: 'Subir versión' }), 'ok=propuesta-subida');
    await hacer(estudiante, `envía la versión ${version} al director`, p.locator('button', { hasText: 'al director' }), 'ok=propuesta-enviada');
}

async function directorRevisa(director, idProyecto, decision, observacion) {
    const p = await director.proyecto('/director/proyectos.jsp', idProyecto);
    const f = formulario(p, 'propuesta-revisar.jsp');
    await f.locator('textarea[name=observacion]').fill(observacion);
    if (decision === 'aprobar') await f.locator('input[name=turnitin]').setInputFiles(pdf('turnitin-propuesta.pdf'));
    await hacer(director, `${decision === 'aprobar' ? 'aprueba con Turnitin' : 'devuelve'} la propuesta`, f.locator(`button[value=${decision}]`),
        decision === 'aprobar' ? 'ok=propuesta-aprobada-director' : 'ok=propuesta-devuelta-director');
}

async function evaluadorEnvia(evaluador, idProyecto, concepto, cambios = {}, documento = 'propuesta', todos = 'si') {
    const p = await evaluador.proyecto('/evaluador/proyectos.jsp', idProyecto);
    const n = await llenarRejilla(p, cambios, todos);
    const f = formulario(p, 'evaluacion-guardar.jsp', 'Rejilla');
    await f.locator('#concepto').selectOption(concepto);
    await f.locator('#observacionGeneral').fill(`Concepto ${concepto} sobre ${documento === 'propuesta' ? 'la propuesta' : 'el informe'}`);
    await hacer(evaluador, `envía la rejilla del ${documento === 'propuesta' ? 'F-DC-124' : 'F-DC-129'} (${n} indicadores) con concepto ${concepto}`,
        f.locator('button[value=enviar]'), 'ok=evaluacion-enviada');
}

let numeroActa = 0;
async function comiteDecide(comite, idProyecto, documento, decision, esperado) {
    const p = await comite.proyecto('/admin/proyectos.jsp', idProyecto);
    const f = formulario(p, documento === 'propuesta' ? 'propuesta-decidir.jsp' : 'informe-decidir.jsp');
    await f.locator('input[name=acta]').fill(String(++numeroActa));
    await f.locator('textarea[name=observacion]').fill(`Decisión del comité en el acta ${numeroActa}`);
    await hacer(comite, `${decision} ${documento === 'propuesta' ? 'la propuesta' : 'el informe'} (acta ${numeroActa})`,
        f.locator(`button[value=${decision}]`), esperado);
}

// Lleva un proyecto de la fase 1 a la fase 4 con la propuesta aprobada, sin rodeos
async function propuestaAprobada(estudiante, comite, director, evaluador, nombreDirector, nombreEvaluador) {
    await subirRecibo(estudiante);
    const pr = proyectoDe(estudiante.correo);
    await revisarPago(comite, pr.id, estudiante.nombreCompleto, 'aprobar', 'ok=pago-aprobado');
    await asignar(comite, pr.id, nombreDirector, nombreEvaluador, 'ok=asignacion-fase-2');
    await subirPropuesta(estudiante, 1);
    await directorRevisa(director, pr.id, 'aprobar', 'Propuesta lista para el evaluador');
    await evaluadorEnvia(evaluador, pr.id, 'Aprobado');
    await comiteDecide(comite, pr.id, 'propuesta', 'aprobar', 'ok=propuesta-aprobar-comite');
    revisar(`${estudiante.nombre}: su proyecto queda en la fase 4 con la propuesta aprobada`, estadoProyecto(pr.id).fase === 4);
    return pr;
}

// ---------- Registro desde la pantalla ----------
async function registrar(datos, esperado) {
    const contexto = await navegador.newContext({ viewport: datos.celular ? { width: 390, height: 844 } : { width: 1366, height: 900 }, locale: 'es-CO' });
    const p = await contexto.newPage();
    p.setDefaultTimeout(15000);
    await p.goto(B + '/index.jsp');
    await Promise.all([p.waitForNavigation(), p.click('a[href$="registro.jsp"]')]);
    await p.fill('#nombre', datos.nombre);
    await p.selectOption('#tipo_documento', '2');
    await p.fill('#numero_documento', datos.documento);
    await p.fill('#correo', datos.correo);
    await p.fill('#celular', '3001234567');
    await p.fill('#clave', CLAVE);
    await p.fill('#clave2', datos.clave2 || CLAVE);
    await p.selectOption('#carrera', '1');
    await p.selectOption('#plan_estudios', 'Anterior');
    await p.fill('#porcentaje_creditos', String(datos.creditos));
    if (datos.metodologia !== false) await p.check('#metodologia');
    const persona = { nombre: datos.corto, p };
    if (esperado === 'bloqueado') {
        // El navegador no deja enviar un correo que no es institucional
        await p.click('button[type=submit]');
        await p.waitForTimeout(300);
        revisar(`registro: el navegador no deja usar ${datos.correo}`, p.url().endsWith('/registro.jsp') && !(await p.$eval('#correo', e => e.checkValidity())));
    } else {
        const conError = !esperado.includes('Tu cuenta quedó creada');
        await hacer(persona, `se registra${datos.celular ? ' desde el celular' : ''}${conError ? ' con un error' : ''}`,
            p.locator('button[type=submit]'), esperado);
        if (conError) revisar(`registro: el formulario conserva lo escrito (${datos.corto})`, (await p.inputValue('#nombre')) === datos.nombre);
    }
    await contexto.close();
}

(async () => {
    navegador = await chromium.launch({ channel: 'chrome' });
    console.log(`== Chrome ${navegador.version()}`);
    const comite = new Persona('Comité', 'admin.prueba@uts.edu.co');
    const director = new Persona('Director', 'director.prueba@uts.edu.co');
    const evaluador = new Persona('Evaluador', 'evaluador.prueba@uts.edu.co');
    const docente = new Persona('Docente (director y evaluador)', 'docente.prueba@uts.edu.co');
    const est = {};
    const ESTUDIANTES = [
        ['ana', 'Ana Lucia Torres Mejia', 85], ['beto', 'Alberto Jose Rueda Pinto', 80, true], ['caro', 'Carolina Diaz Ardila', 50],
        ['dani', 'Daniel Felipe Rojas Leal', 90], ['eli', 'Elizabeth Gomez Prada', 78], ['fer', 'Fernando Vargas Silva', 88],
        ['gabi', 'Gabriela Nino Castro', 82], ['hugo', 'Hugo Andres Mantilla Ruiz', 95, true],
    ];
    const escenario = async (nombre, fn) => {
        console.log(`-- ${nombre}`);
        try { await fn(); } catch (e) { revisar(`${nombre}: se detuvo`, false, e.message.split('\n')[0]); }
    };

    await escenario('1. Periodo e ideas', async () => {
        let p = await comite.menu('/admin/periodos.jsp');
        revisar('Comité: no tiene el botón de PQR (las responde, no las envía)', (await p.locator('.app-cabecera a[href$="/panel/pqr.jsp"]').count()) === 0);
        await Promise.all([p.waitForNavigation(), p.click('a[href$="/admin/periodo-form.jsp"]')]);
        await p.fill('#nombre', '2026-2');
        await p.fill('#fecha_inicio_semestre', dia(-30));
        await p.fill('#fecha_cierre_banco', dia(30));
        await p.fill('#fecha_limite_pago', dia(30));
        await p.fill('#fecha_limite_propuestas', dia(60));
        await p.fill('#fecha_inicio_informe_final', dia(200));
        await p.fill('#fecha_fin_informe_final', dia(100));
        await hacer(comite, 'crea el periodo con el informe final al revés', p.locator('form[action$="periodo-guardar.jsp"] button[type=submit]'),
            'aviso: La fecha de inicio del informe final debe ser anterior');
        await p.fill('#fecha_inicio_informe_final', '');
        await p.fill('#fecha_fin_informe_final', '');
        await hacer(comite, 'crea el periodo 2026-2', p.locator('form[action$="periodo-guardar.jsp"] button[type=submit]'), 'ok=periodo-creado');
        await hacer(comite, 'activa el periodo', p.locator('tr', { hasText: '2026-2' }).locator('button', { hasText: 'Activar' }), 'ok=periodo-activado');
        await Promise.all([p.waitForNavigation(), p.click('a[href$="/admin/periodo-form.jsp"]')]);
        await p.fill('#nombre', '2026-2');
        await hacer(comite, 'intenta crear otro periodo 2026-2', p.locator('form[action$="periodo-guardar.jsp"] button[type=submit]'),
            'aviso: Ya existe un periodo con ese nombre');

        for (const idea of [
            { titulo: 'Sistema de turnos para la cafeteria', descripcion: 'Turnos con aviso en el celular', modalidad: '2' },
            { titulo: 'Monografia sobre seguridad en redes', descripcion: 'Estado del arte de la seguridad en redes', modalidad: '3' },
            { titulo: 'Reservas de laboratorios', descripcion: 'Reservas de equipos y salas', modalidad: '2' },
            { titulo: 'Analitica de datos academicos', descripcion: 'Sin modalidad: la escoge el estudiante' },
            { titulo: 'Idea sin alcance definido', descripcion: 'Para que el comite la rechace', modalidad: '1' },
        ]) await registrarDocenteIdea(director, idea);
        for (const t of ['Sistema de turnos para la cafeteria', 'Monografia sobre seguridad en redes', 'Reservas de laboratorios', 'Analitica de datos academicos'])
            await revisarIdea(comite, t, 'aprobar', 'Idea pertinente para el programa');
        await revisarIdea(comite, 'Idea sin alcance definido', 'rechazar', 'No define el alcance');
        p = await director.menu('/ideas/banco.jsp');
        revisar('Director: ve la observación de la idea rechazada', (await director.texto()).includes('No define el alcance'));
    });

    await escenario('1b. Menú de los docentes (decisión del 2026-10-16)', async () => {
        const opciones = async persona => JSON.stringify(await persona.opcionesDocente());
        revisar('Docente con los dos roles: entra directo y ve "Docente director" y "Docente evaluador"',
            (await opciones(docente)) === '["Docente director","Docente evaluador"]', await opciones(docente));
        revisar('Docente con los dos roles: bajo su nombre dice "Docente director y evaluador"', (await docente.texto()).includes('Docente director y evaluador'));
        revisar('Director de prueba (un solo rol): solo ve "Docente director"', (await opciones(director)) === '["Docente director"]', await opciones(director));
        revisar('Evaluador de prueba (un solo rol): solo ve "Docente evaluador"', (await opciones(evaluador)) === '["Docente evaluador"]', await opciones(evaluador));
        const p = await docente.menu('/evaluador/proyectos.jsp');
        revisar('Docente: abre "Docente evaluador" sin cambiar de rol a mano', (await p.locator('h1').innerText()) === 'Docente evaluador');
        await docente.menu('/director/proyectos.jsp');
        revisar('Docente: y vuelve a "Docente director"', (await docente.p.locator('h1').innerText()) === 'Docente director');
    });

    await escenario('2. Registro e inicio de sesión', async () => {
        const CREADA = 'aviso: Tu cuenta quedó creada';
        ESTUDIANTES.forEach(([corto, nombre, creditos, celular], i) => {
            est[corto] = new Persona(corto[0].toUpperCase() + corto.slice(1), `${corto}.uat@correo.uts.edu.co`, { celular });
            est[corto].nombreCompleto = nombre;
            est[corto].datos = { corto, nombre, correo: est[corto].correo, documento: String(8000000010 + i), creditos, celular };
        });
        // Errores del registro antes de crear las cuentas
        await registrar({ ...est.ana.datos, correo: 'ana.torres@gmail.com' }, 'bloqueado');
        await registrar({ ...est.ana.datos, clave2: '654321' }, 'aviso: Las dos contraseñas no coinciden');
        for (const corto of Object.keys(est)) await registrar(est[corto].datos, CREADA);
        await registrar({ ...est.ana.datos, documento: '9999999999' }, 'aviso: Ya hay una cuenta con ese correo');
        await registrar({ ...est.ana.datos, correo: 'otra.ana@correo.uts.edu.co' }, 'aviso: Ya hay una cuenta con ese número de documento');
        revisar('registro: quedaron 8 estudiantes con su rol', sql(`SELECT COUNT(*) FROM usuarios u JOIN usuario_roles r ON r.usuario_id = u.id AND r.rol_id = 5 WHERE u.correo LIKE '%.uat@%'`) === '8');
        revisar('registro: el nivel sale de la carrera (tecnológico)', sql(`SELECT COUNT(*) FROM usuarios WHERE correo LIKE '%.uat@%' AND nivel_id = 1`) === '8');
        // Contraseña equivocada
        const contexto = await navegador.newContext();
        const p = await contexto.newPage();
        await p.goto(B + '/index.jsp');
        await p.fill('#correo', est.ana.correo);
        await p.fill('#clave', 'clave-mala');
        await hacer({ nombre: 'Ana', p }, 'inicia sesión con una contraseña equivocada', p.locator('button[type=submit]'), 'error=credenciales');
        await contexto.close();
    });

    await escenario('3. Habilitación', async () => {
        let p = await est.caro.menu('/estudiante/habilitacion.jsp');
        revisar('Caro (50 % de créditos): no está habilitada', (await est.caro.texto()).includes('Todavía no estás habilitado'));
        p = await est.caro.menu('/ideas/banco.jsp');
        revisar('Caro: el banco le avisa y no le deja tomar ideas', (await est.caro.texto()).includes('Todavía no cumples los requisitos')
            && (await p.locator('button', { hasText: 'Tomar esta idea' }).count()) === 0);
        await est.ana.menu('/estudiante/habilitacion.jsp');
        revisar('Ana: está habilitada', (await est.ana.texto()).includes('Estás habilitado'));
    });

    let ana;
    await escenario('4. Camino completo: fase 1 (idea, integrantes y pago)', async () => {
        await tomarIdea(est.ana, 'Sistema de turnos para la cafeteria');
        ana = proyectoDe(est.ana.correo);
        revisar(`Ana: su proyecto ${ana.codigo} queda en la fase 1`, ana.fase === 1 && ana.estado === 'Pendiente', JSON.stringify(ana));
        let p = await est.ana.menu('/estudiante/proyecto.jsp');
        await p.fill('#correoCompanero', est.caro.correo);
        await hacer(est.ana, 'intenta agregar a Caro (no habilitada)', p.locator('form[action$="integrante-agregar.jsp"] button'), 'error=integrante-no-habilitado');
        await p.fill('#correoCompanero', est.beto.correo);
        await hacer(est.ana, 'agrega a Beto', p.locator('form[action$="integrante-agregar.jsp"] button'), 'ok=integrante-agregado');
        await p.setInputFiles('#recibo', word('recibo.docx'));
        await hacer(est.ana, 'intenta subir el recibo en Word', p.locator('button', { hasText: 'Subir recibo' }), 'error=archivo-invalido');
        await subirRecibo(est.ana);
        await subirRecibo(est.beto);
        await revisarPago(comite, ana.id, est.beto.nombreCompleto, 'devolver', 'ok=pago-devuelto');
        await revisarPago(comite, ana.id, est.ana.nombreCompleto, 'aprobar', 'ok=pago-aprobado');
        await asignar(comite, ana.id, 'Docente de Prueba', 'Docente de Prueba', 'error=director-evaluador');
        await asignar(comite, ana.id, 'Director de Prueba', 'Evaluador de Prueba', 'ok=asignacion-guardada', { interdisciplinario: true, codirector: 'Docente de Prueba' });
        p = await est.beto.menu('/estudiante/proyecto.jsp');
        revisar('Beto (celular): ve que el comité devolvió su recibo y por qué', (await est.beto.texto()).includes('El recibo no tiene la marca de pagado'));
        await subirRecibo(est.beto);
        await revisarPago(comite, ana.id, est.beto.nombreCompleto, 'aprobar', 'ok=pago-aprobado-fase-2');
        revisar('el proyecto pasa a la fase 2 con los dos pagos y el director', estadoProyecto(ana.id).fase === 2);
        p = await est.ana.menu('/estudiante/proyecto.jsp');
        revisar('Ana: ve a su director', (await est.ana.texto()).includes('Director de Prueba'));
    });

    await escenario('5. Camino completo: propuesta (fases 2 a 4)', async () => {
        let p = await est.ana.menu('/estudiante/proyecto.jsp');
        await p.setInputFiles('#propuesta', pdf('propuesta.pdf'));
        await hacer(est.ana, 'intenta subir la propuesta en PDF', p.locator('button', { hasText: 'Subir versión' }), 'error=archivo-no-word');
        await p.setInputFiles('#anexo', pdf('anexo-encuesta.pdf'));
        await hacer(est.ana, 'sube un anexo', p.locator('button', { hasText: 'Subir anexo' }), 'ok=anexo-subido');
        await subirPropuesta(est.ana, 1);
        revisar('Ana: confirmó el envío en la ventana del navegador', est.ana.dialogos.some(d => d.includes('director')));
        revisar('el proyecto pasa a la fase 3', estadoProyecto(ana.id).fase === 3);
        p = await est.ana.menu('/estudiante/proyecto.jsp');
        revisar('Ana: con la propuesta enviada ya no puede agregar integrantes', (await p.locator('#correoCompanero').count()) === 0);

        p = await docente.proyecto('/director/proyectos.jsp', ana.id);
        await p.fill('#observacionCodirector', 'Sugiero ampliar el marco teorico');
        await hacer(docente, 'deja su observación de codirector', p.locator('form[action$="propuesta-observar.jsp"] button'), 'ok=observacion-codirector');

        p = await director.proyecto('/director/proyectos.jsp', ana.id);
        await formulario(p, 'propuesta-revisar.jsp').locator('textarea[name=observacion]').fill('Bien');
        await hacer(director, 'intenta aprobar sin el reporte de Turnitin', formulario(p, 'propuesta-revisar.jsp').locator('button[value=aprobar]'), 'error=turnitin-requerido');
        await directorRevisa(director, ana.id, 'devolver', 'Falta el cronograma');
        revisar('el proyecto vuelve a la fase 2', estadoProyecto(ana.id).fase === 2);
        p = await est.ana.menu('/estudiante/proyecto.jsp');
        let texto = await est.ana.texto();
        revisar('Ana: ve que su director la devolvió, con su observación y la del codirector',
            texto.includes('Tu director devolvió') && texto.includes('Falta el cronograma') && texto.includes('Sugiero ampliar el marco teorico'));
        await subirPropuesta(est.ana, 2);
        await directorRevisa(director, ana.id, 'aprobar', 'Cronograma completo');
        revisar('el proyecto pasa a la fase 4', estadoProyecto(ana.id).fase === 4);

        // El evaluador: borrador, un concepto que no cuadra con la rejilla y el aplazamiento
        p = await evaluador.proyecto('/evaluador/proyectos.jsp', ana.id);
        await llenarRejilla(p, { 0: 'no' });
        const rejilla = formulario(p, 'evaluacion-guardar.jsp', 'Rejilla');
        await rejilla.locator('#concepto').selectOption('Aplazado');
        await rejilla.locator('#observacionGeneral').fill('Borrador de la evaluacion');
        await hacer(evaluador, 'guarda la rejilla en borrador', rejilla.locator('button[value=borrador]'), 'ok=evaluacion-borrador');
        revisar('Evaluador: el borrador conserva lo marcado', (await p.locator('text=Tienes un borrador guardado').count()) > 0
            && (await p.locator('form[action$="evaluacion-guardar.jsp"] input[type=radio][value=no]:checked').count()) === 1);
        await formulario(p, 'evaluacion-guardar.jsp', 'Rejilla').locator('#concepto').selectOption('Aprobado');
        await hacer(evaluador, 'intenta dar "Aprobado" con un indicador en No', formulario(p, 'evaluacion-guardar.jsp', 'Rejilla').locator('button[value=enviar]'), 'error=aprobado-con-no');
        await evaluadorEnvia(evaluador, ana.id, 'Aplazado', { 0: 'no' });
        await comiteDecide(comite, ana.id, 'propuesta', 'aplazar', 'ok=propuesta-aplazar-comite');
        revisar('aplazada, vuelve a la fase 2', estadoProyecto(ana.id).fase === 2);
        p = await est.ana.menu('/estudiante/proyecto.jsp');
        texto = await est.ana.texto();
        revisar('Ana: ve que el comité aplazó y el concepto del evaluador, sin su nombre',
            texto.includes('El comité aplazó') && texto.includes('Concepto Aplazado') && !texto.includes('Evaluador de Prueba'));
        await subirPropuesta(est.ana, 3);
        await directorRevisa(director, ana.id, 'aprobar', 'Correcciones del comite hechas');
        await evaluadorEnvia(evaluador, ana.id, 'Aprobado');
        await comiteDecide(comite, ana.id, 'propuesta', 'aprobar', 'ok=propuesta-aprobar-comite');
        revisar('aprobada: fase 4 con la fecha de aprobación de hoy', sql(`SELECT f.orden, p.fecha_aprobacion_124 = CURDATE(), p.fecha_limite = CURDATE() + INTERVAL 180 DAY
            FROM proyectos p JOIN fases f ON f.id = p.fase_id WHERE p.id = ${ana.id}`) === '4\t1\t1');
    });

    await escenario('6. Camino completo: informe final (fases 4 y 5)', async () => {
        let p = await est.ana.menu('/estudiante/proyecto.jsp');
        let texto = await est.ana.texto();
        revisar('Ana: el informe todavía no se puede enviar (faltan los 90 días y los seguimientos)', texto.includes('Pasaron 90 días desde la aprobación')
            && (await p.locator('button', { hasText: 'al director' }).count()) === 0);
        for (const s of ['Primer avance: capitulo uno', 'Segundo avance: pruebas']) {
            p = await director.proyecto('/director/proyectos.jsp', ana.id);
            await p.fill('#seguimiento', s);
            await hacer(director, `registra el seguimiento "${s}"`, p.locator('form[action$="seguimiento-registrar.jsp"] button'), 'ok=seguimiento-registrado');
        }
        p = await est.ana.menu('/estudiante/proyecto.jsp');
        await p.setInputFiles('#informe', word('FDC-125 v1.docx'));
        await hacer(est.ana, 'sube la versión 1 del FDC-125', p.locator('form[action$="informe-guardar.jsp"] button'), 'ok=informe-subido');
        revisar('Ana: antes del día 90 no sale el botón de enviar', (await p.locator('button', { hasText: 'al director' }).count()) === 0);
        adelantar(ana.codigo);
        p = await est.ana.recargar();
        await hacer(est.ana, 'envía el informe al director (día 90, con el tiempo adelantado)', p.locator('button', { hasText: 'al director' }), 'ok=informe-enviado');
        revisar('el proyecto pasa a la fase 5', estadoProyecto(ana.id).fase === 5);

        p = await director.proyecto('/director/proyectos.jsp', ana.id);
        let f = formulario(p, 'informe-revisar.jsp');
        await f.locator('textarea[name=observacion]').fill('Ajustar las conclusiones');
        await hacer(director, 'devuelve el informe', f.locator('button[value=devolver]'), 'ok=informe-devuelto-director');
        p = await est.ana.menu('/estudiante/proyecto.jsp');
        revisar('Ana: ve que el director devolvió el informe', (await est.ana.texto()).includes('Tu director devolvió la versión 1 del informe final'));
        await p.setInputFiles('#informe', word('FDC-125 v2.docx'));
        await hacer(est.ana, 'sube la versión 2 del FDC-125', p.locator('form[action$="informe-guardar.jsp"] button'), 'ok=informe-subido');
        await hacer(est.ana, 'envía la versión 2 al director', p.locator('button', { hasText: 'al director' }), 'ok=informe-enviado');
        p = await director.proyecto('/director/proyectos.jsp', ana.id);
        f = formulario(p, 'informe-revisar.jsp');
        await f.locator('textarea[name=observacion]').fill('Informe listo');
        await f.locator('input[name=turnitin]').setInputFiles(pdf('turnitin-informe.pdf'));
        await hacer(director, 'aprueba el informe con Turnitin', f.locator('button[value=aprobar]'), 'ok=informe-aprobado-director');
        await evaluadorEnvia(evaluador, ana.id, 'Aprobado', { 1: 'na' }, 'informe');
        await comiteDecide(comite, ana.id, 'informe', 'aprobar', 'ok=informe-aprobar-comite');
        revisar('el proyecto pasa a la fase final', estadoProyecto(ana.id).fase === 6);
    });

    await escenario('7. Camino completo: sustentación y aprobación final', async () => {
        await est.ana.menu('/estudiante/proyecto.jsp');
        revisar('Ana: espera a que el comité programe la sustentación', (await est.ana.texto()).includes('El comité todavía no programa la sustentación'));
        let p = await comite.proyecto('/admin/proyectos.jsp', ana.id);
        await p.fill('#fechaSustentacion', `${dia(1)}T10:00`);
        await p.fill('#lugarSustentacion', 'Sala de juntas del bloque B');
        await hacer(comite, 'programa la sustentación', p.locator('button', { hasText: 'Programar la sustentación' }), 'ok=sustentacion-programada');
        await p.locator('summary', { hasText: 'Reprograma la sustentación' }).click();
        await p.fill('#fechaSustentacion', `${dia(2)}T15:30`);
        await p.fill('#lugarSustentacion', 'Auditorio menor');
        await hacer(comite, 'la reprograma', p.locator('button', { hasText: 'Reprogramar' }), 'ok=sustentacion-reprogramada');
        revisar('Comité: antes de la fecha no puede registrar la aprobación final', (await p.locator('form[action$="proyecto-finalizar.jsp"]').count()) === 0);
        for (const [quien, persona, lista] of [['Ana', est.ana, '/estudiante/proyecto.jsp'], ['Beto', est.beto, '/estudiante/proyecto.jsp'],
                                                ['Director', director, null], ['Evaluador', evaluador, null]]) {
            if (lista) await persona.menu(lista);
            else await persona.proyecto(quien === 'Director' ? '/director/proyectos.jsp' : '/evaluador/proyectos.jsp', ana.id);
            const texto = await persona.texto();
            revisar(`${quien}: ve la sustentación reprogramada, programada por "El comité"`, texto.includes('Auditorio menor') && texto.includes('El comité'));
        }
        adelantar(ana.codigo);
        p = await comite.recargar();
        await p.fill('#actaAprobacionFinal', String(++numeroActa));
        await p.fill('#observacionFinal', 'Sustentacion realizada; cumple las condiciones');
        await hacer(comite, 'registra la aprobación final', p.locator('button', { hasText: 'Registrar la aprobación final' }), 'ok=proyecto-finalizado');
        revisar('el proyecto queda Finalizado', estadoProyecto(ana.id).estado === 'Finalizado');
        await est.ana.menu('/estudiante/proyecto.jsp');
        const texto = await est.ana.texto();
        revisar('Ana: ve su trabajo de grado finalizado', texto.includes('Tu trabajo de grado quedó finalizado'));
        revisar('Ana: en ningún momento ve el nombre de su evaluador', !texto.includes('Evaluador de Prueba'));
    });

    await escenario('8. Avisos', async () => {
        const p = await est.beto.menu('/panel/inicio.jsp');
        const numero = Number(await p.locator('.app-campana-numero').innerText().catch(() => '0'));
        revisar(`Beto (celular): la campana tiene avisos sin leer (${numero})`, numero > 0);
        await Promise.all([p.waitForNavigation(), p.click('a.app-campana')]);
        const texto = await est.beto.texto();
        revisar('Beto: los avisos cuentan lo que pasó y no nombran al evaluador', texto.includes('sustentación') && !texto.includes('Evaluador de Prueba'));
        await Promise.all([p.waitForNavigation(), p.click('button:has-text("Marcar todos como leídos")')]);
        revisar('Beto: marcó todos como leídos y la campana queda en cero', (await p.locator('.app-campana-numero').count()) === 0);
    });

    await escenario('9. Propuesta no aprobada (Dani)', async () => {
        await tomarIdea(est.dani, 'Monografia sobre seguridad en redes');
        const dani = proyectoDe(est.dani.correo);
        await subirRecibo(est.dani);
        await revisarPago(comite, dani.id, est.dani.nombreCompleto, 'aprobar', 'ok=pago-aprobado');
        await asignar(comite, dani.id, 'Docente de Prueba', 'Evaluador de Prueba', 'ok=asignacion-fase-2');
        await subirPropuesta(est.dani, 1);
        await directorRevisa(docente, dani.id, 'aprobar', 'Lista para el evaluador');
        await evaluadorEnvia(evaluador, dani.id, 'No aprobado', {}, 'propuesta', 'no');
        await comiteDecide(comite, dani.id, 'propuesta', 'no-aprobar', 'ok=propuesta-no-aprobar-comite');
        revisar('no aprobada: el proyecto se cancela', estadoProyecto(dani.id).estado === 'Cancelado');
        revisar('la idea vuelve al banco', sql(`SELECT estado FROM ideas WHERE titulo = 'Monografia sobre seguridad en redes'`) === 'Aprobada');
        await est.dani.menu('/estudiante/proyecto.jsp');
        revisar('Dani: queda sin proyecto vigente', (await est.dani.texto()).includes('Todavía no tienes un proyecto'));
        await tomarIdea(est.dani, 'Monografia sobre seguridad en redes');
        const nuevo = proyectoDe(est.dani.correo);
        revisar(`Dani: vuelve a tomar la idea con otro código (${nuevo.codigo})`, nuevo.id !== dani.id && nuevo.fase === 1);
    });

    await escenario('10. Idea propia, cambio de modalidad y exoneración (Fer)', async () => {
        let p = await est.fer.menu('/ideas/banco.jsp');
        await Promise.all([p.waitForNavigation(), p.click('a:has-text("Formular mi propuesta")')]);
        await p.fill('#titulo', 'Asistente para matricula en linea');
        await p.fill('#descripcion', 'Propuesta propia');
        await hacer(est.fer, 'formula su propia idea', p.locator('form[action$="idea-guardar.jsp"] button[type=submit]'), 'ok=idea-creada');
        await revisarIdea(comite, 'Asistente para matricula en linea', 'rechazar', 'Falta delimitar el alcance');
        p = await est.fer.menu('/ideas/banco.jsp');
        revisar('Fer: ve por qué le rechazaron la idea', (await est.fer.texto()).includes('Falta delimitar el alcance'));
        await Promise.all([p.waitForNavigation(), p.locator('tr', { hasText: 'Asistente para matricula en linea' }).locator('a', { hasText: 'Editar' }).click()]);
        await p.fill('#descripcion', 'Propuesta propia: solo la matricula de primer semestre');
        await hacer(est.fer, 'corrige la idea', p.locator('form[action$="idea-guardar.jsp"] button[type=submit]'), 'ok=idea-actualizada');
        await revisarIdea(comite, 'Asistente para matricula en linea', 'aprobar', 'Alcance claro');
        await tomarIdea(est.fer, 'Asistente para matricula en linea', '2');
        const fer = proyectoDe(est.fer.correo);
        p = await est.fer.menu('/estudiante/proyecto.jsp');
        await p.locator('summary', { hasText: 'Cambio de modalidad' }).click();
        await p.selectOption('#modalidadNueva', '3');
        await p.fill('#motivoCambio', 'El trabajo es documental');
        await hacer(est.fer, 'pide cambiar a Monografía', p.locator('button', { hasText: 'Pedir el cambio' }), 'ok=modalidad-solicitada');
        p = await comite.proyecto('/admin/proyectos.jsp', fer.id);
        const f = formulario(p, 'modalidad-decidir.jsp');
        await f.locator('textarea').fill('Cambio justificado');
        await hacer(comite, 'aprueba el cambio de modalidad', f.locator('button[value=aprobar]'), 'ok=modalidad-aprobada');
        revisar('el proyecto queda en Monografía', sql(`SELECT modalidad_id FROM proyectos WHERE id = ${fer.id}`) === '3');
        // El docente, que fue codirector de Ana y director de Dani, evalúa a Fer desde la opción
        // "Docente evaluador" del menú, sin cambiar de rol a mano
        await propuestaAprobada(est.fer, comite, director, docente, 'Director de Prueba', 'Docente de Prueba');
        p = await est.fer.menu('/estudiante/proyecto.jsp');
        await p.fill('#puntaje', '160');
        await p.setInputFiles('#certificado', pdf('certificado-saber-tyt.pdf'));
        await hacer(est.fer, 'pide la exoneración con 160 puntos en Saber TyT', p.locator('button', { hasText: 'Pedir la exoneración' }), 'ok=exoneracion-solicitada');
        p = await comite.proyecto('/admin/proyectos.jsp', fer.id);
        const fx = formulario(p, 'exoneracion-revisar.jsp');
        await fx.locator('textarea').fill('Certificado verificado');
        await hacer(comite, 'aprueba la exoneración', fx.locator('button[value=aprobar]'), 'ok=exoneracion-proyecto-terminado');
        await est.fer.menu('/estudiante/proyecto.jsp');
        const texto = await est.fer.texto();
        revisar('Fer: su proyecto terminó con concepto Aprobado y su estímulo (4.7 y 50 % de beca)',
            texto.includes('Tu proyecto terminó con concepto Aprobado') && texto.includes('4.7 y 50 % de beca'));
        revisar('Fer: no ve a su evaluador (el docente)', !texto.includes('Docente de Prueba'));
        revisar('el proyecto de Fer queda Finalizado', estadoProyecto(fer.id).estado === 'Finalizado');
    });

    await escenario('11. Prórroga y plazo vencido (Gabi)', async () => {
        await tomarIdea(est.gabi, 'Reservas de laboratorios');
        const gabi = await propuestaAprobada(est.gabi, comite, director, evaluador, 'Director de Prueba', 'Evaluador de Prueba');
        const limite = sql(`SELECT fecha_limite FROM proyectos WHERE id = ${gabi.id}`);
        for (const [n, decision] of [[1, 'aprobar'], [2, 'rechazar']]) {
            const p = await est.gabi.menu('/estudiante/proyecto.jsp');
            await p.locator('summary', { hasText: 'Pide una prórroga' }).click();
            await p.fill('#motivoProrroga', `Solicitud ${n}: la empresa cambio el cronograma`);
            await p.setInputFiles('#soporteProrroga', pdf(`soporte-prorroga-${n}.pdf`));
            await hacer(est.gabi, `pide la prórroga ${n}`, p.locator('button', { hasText: 'Pedir la prórroga' }), 'ok=prorroga-solicitada');
            const c = await comite.proyecto('/admin/proyectos.jsp', gabi.id);
            const f = formulario(c, 'prorroga-decidir.jsp');
            await f.locator('textarea').fill(decision === 'aprobar' ? 'Soporte valido' : 'No justifica otra prorroga');
            await hacer(comite, `${decision === 'aprobar' ? 'aprueba' : 'rechaza'} la prórroga ${n}`, f.locator(`button[value=${decision}]`),
                decision === 'aprobar' ? 'ok=prorroga-aprobada' : 'ok=prorroga-rechazada');
        }
        revisar('la prórroga aprobada corre 180 días la fecha límite', sql(`SELECT fecha_limite = DATE('${limite}') + INTERVAL 180 DAY FROM proyectos WHERE id = ${gabi.id}`) === '1');
        // Se adelanta el tiempo hasta el día después del plazo
        // Se adelanta el tiempo hasta el día después del plazo; la primera página que abre ya
        // debe mostrar el proyecto cancelado
        sql(`UPDATE proyectos SET fecha_limite = CURDATE() - INTERVAL 1 DAY WHERE id = ${gabi.id}`);
        await est.gabi.recargar();
        revisar('vencido el plazo sin prórroga pendiente, se cancela la modalidad', estadoProyecto(gabi.id).estado === 'Cancelado');
        revisar('Gabi: queda sin proyecto vigente y con un aviso', (await est.gabi.texto()).includes('Todavía no tienes un proyecto')
            && sql(`SELECT COUNT(*) > 0 FROM avisos a JOIN usuarios u ON u.id = a.usuario_id WHERE u.correo = '${est.gabi.correo}' AND a.leido = 0`) === '1');
    });

    await escenario('12. Seminario (Eli y Hugo)', async () => {
        await tomarIdea(est.eli, 'Analitica de datos academicos', '5');
        const eli = proyectoDe(est.eli.correo);
        let p = await est.eli.menu('/estudiante/proyecto.jsp');
        await p.fill('#correoCompanero', est.hugo.correo);
        await hacer(est.eli, 'agrega a Hugo', p.locator('form[action$="integrante-agregar.jsp"] button'), 'ok=integrante-agregado');
        for (const persona of [est.eli, est.hugo]) {
            await subirRecibo(persona);
            for (const [doc, nombre] of [['f-am-04', 'Formato F-AM-04'], ['cedula', 'cédula']]) {
                p = await persona.menu('/estudiante/proyecto.jsp');
                await p.selectOption('#documentoInscripcion', doc);
                await p.setInputFiles('#archivoInscripcion', pdf(`${doc}-${persona.nombre}.pdf`));
                await hacer(persona, `sube su ${nombre}`, p.locator('button', { hasText: 'Subir documento' }), 'ok=inscripcion-documento');
            }
        }
        p = await comite.proyecto('/admin/proyectos.jsp', eli.id);
        let f = formulario(p, 'inscripcion-validar.jsp');
        await f.locator('textarea').fill('Validada');
        await hacer(comite, 'intenta validar la inscripción sin los pagos aprobados', f.locator('button[value=aprobar]'), 'error=*');
        await revisarPago(comite, eli.id, est.eli.nombreCompleto, 'aprobar', 'ok=pago-aprobado');
        await revisarPago(comite, eli.id, est.hugo.nombreCompleto, 'aprobar', 'ok=pago-aprobado');
        await asignar(comite, eli.id, 'Director de Prueba', null, 'ok=*');
        p = await comite.proyecto('/admin/proyectos.jsp', eli.id);
        f = formulario(p, 'inscripcion-validar.jsp');
        await f.locator('textarea').fill('Documentos completos');
        await hacer(comite, 'valida la inscripción', f.locator('button[value=aprobar]'), 'ok=inscripcion-validada');
        revisar('el seminario queda En curso', estadoProyecto(eli.id).estado === 'En curso');
        p = await director.proyecto('/director/proyectos.jsp', eli.id);
        await p.fill('#nota', '4.2');
        await p.fill('#observacionNota', 'Entregable completo');
        await hacer(director, 'registra la nota final 4.2', p.locator('button', { hasText: 'Registrar la nota' }), 'ok=nota-aprobada');
        revisar('el seminario queda Finalizado', estadoProyecto(eli.id).estado === 'Finalizado');
        await est.hugo.menu('/estudiante/proyecto.jsp');
        revisar('Hugo (celular): ve que aprobó el seminario con 4,2', (await est.hugo.texto()).includes('Aprobaste el seminario con nota 4,2'));
    });

    await escenario('13. PQR', async () => {
        let p = await est.beto.abrir();
        await Promise.all([p.waitForNavigation(), p.click('.app-cabecera a[href$="/panel/pqr.jsp"]')]);
        await p.selectOption('#tipo', { index: 1 });
        await p.fill('#comentario', 'No me llego el aviso de la sustentacion a tiempo');
        await hacer(est.beto, 'envía una PQR', p.locator('form[action$="pqr-guardar.jsp"] button'), 'ok=pqr-enviada');
        p = await comite.menu('/admin/pqrs.jsp');
        const f = p.locator('form[action$="pqr-responder.jsp"]').first();
        await f.locator('textarea').fill('Revisamos los avisos: ya llegan al programar la sustentacion');
        await hacer(comite, 'responde la PQR', f.locator('button'), 'ok=pqr-respondida');
        p = await est.beto.abrir();
        await Promise.all([p.waitForNavigation(), p.click('.app-cabecera a[href$="/panel/pqr.jsp"]')]);
        revisar('Beto: ve la respuesta del comité', (await est.beto.texto()).includes('ya llegan al programar la sustentacion'));
        revisar('Beto: le llegó un aviso de la respuesta', (await p.locator('.app-campana-numero').count()) > 0);
    });

    revisar('sin errores de JavaScript en todo el recorrido', erroresJs.length === 0, [...new Set(erroresJs)].slice(0, 3).join(' | '));
    console.log(`\nEstado final: ${sql(`SELECT GROUP_CONCAT(CONCAT(codigo, ' ', estado) ORDER BY id SEPARATOR ', ') FROM proyectos`)}`);
    console.log(`\nResultado: ${ok} OK, ${falla} fallas`);
    await navegador.close();
    process.exit(falla === 0 ? 0 : 1);
})().catch(e => { console.log(`  FALLA error inesperado: ${e.message.split('\n')[0]}`); console.log(`\nResultado: ${ok} OK, ${falla + 1} fallas`); process.exit(1); });
