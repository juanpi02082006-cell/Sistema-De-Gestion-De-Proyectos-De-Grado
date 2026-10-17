// Pruebas de la interfaz (2026-10-14): todas las páginas de cada rol en Chrome y Brave (RNF11),
// en computador (1366 px) y en celular (390 px). En cada una revisa: que cargue sin error del
// servidor, sin errores de JavaScript, con los estilos (Bootstrap y estilo.css) y sin
// desplazamiento horizontal (RNF9, RNF11); si algo se sale de la pantalla, dice qué. En
// celular, que el botón abra el menú. Y que un estudiante suba su propuesta en máximo 5 clics
// (RNF17). Lo corre pruebas/interfaz.sh, que antes deja un proyecto en cada situación.
const { chromium } = require(process.env.PLAYWRIGHT || 'playwright-core');
const fs = require('fs');
const path = require('path');

const B = 'http://localhost:8080/segundo-parcial';
let ok = 0, falla = 0;
const revisar = (nombre, bien, detalle) => {
    if (bien) ok++; else { falla++; console.log(`  FALLA ${nombre}${detalle ? ' (' + detalle + ')' : ''}`); }
};
// Los navegadores que usa el equipo (decisión del 2026-10-17): Chrome y Brave
const BRAVE = process.env.BRAVE || 'C:/Program Files/BraveSoftware/Brave-Browser/Application/brave.exe';
const NAVEGADORES = [
    { nombre: 'Chrome', lanzar: () => chromium.launch({ channel: 'chrome' }) },
    { nombre: 'Brave', lanzar: () => chromium.launch({ executablePath: BRAVE }) },
];
const ids = (ruta, desde, hasta) => Array.from({ length: hasta - desde + 1 }, (_, i) => `${ruta}?id=${desde + i}`);
const RECORRIDOS = [
    { correo: null, nombre: 'sin sesión', paginas: ['/index.jsp', '/registro.jsp', '/index.jsp?error=credenciales', '/registro.jsp?error=faltan-datos'] },
    { correo: 'admin.prueba@uts.edu.co', nombre: 'comité', paginas: ['/panel/inicio.jsp', '/panel/buscar.jsp', '/panel/buscar.jsp?q=a&fase=4', '/admin/informes.jsp', '/admin/informes.jsp?periodo=todos', '/admin/proyectos.jsp', '/admin/proyectos.jsp?filtro=pago',
        ...ids('/admin/proyecto.jsp', 1, 8), '/admin/usuarios.jsp', '/admin/usuario-form.jsp', '/admin/usuario-form.jsp?id=20', '/admin/roles.jsp',
        '/admin/rol-form.jsp', '/admin/rol-form.jsp?id=3', '/admin/periodos.jsp', '/admin/periodo-form.jsp', '/admin/periodo-form.jsp?id=1',
        '/admin/sesiones.jsp?periodo=1', '/admin/modalidad-form.jsp?id=1', '/admin/pqrs.jsp', '/admin/auditoria.jsp', '/ideas/banco.jsp',
        '/panel/calendario.jsp', '/panel/modalidades.jsp', '/panel/avisos.jsp'] },
    { correo: 'director.prueba@uts.edu.co', nombre: 'director', paginas: ['/panel/inicio.jsp', '/panel/buscar.jsp', '/director/proyectos.jsp', ...ids('/director/proyecto.jsp', 1, 8),
        '/ideas/banco.jsp', '/ideas/idea-form.jsp', '/panel/pqr.jsp', '/panel/calendario.jsp', '/panel/avisos.jsp'] },
    { correo: 'evaluador.prueba@uts.edu.co', nombre: 'evaluador', paginas: ['/panel/inicio.jsp', '/panel/buscar.jsp', '/evaluador/proyectos.jsp', ...ids('/evaluador/proyecto.jsp', 2, 7), '/panel/pqr.jsp'] },
    // Docente director y evaluador: entra directo y el menú le muestra las dos opciones
    { correo: 'docente.prueba@uts.edu.co', nombre: 'docente (director y evaluador)', paginas: ['/panel/inicio.jsp', '/director/proyectos.jsp', '/evaluador/proyectos.jsp', '/ideas/banco.jsp'] },
    { correo: 'ana.ui@correo.uts.edu.co', nombre: 'estudiante fase 1', paginas: ['/panel/inicio.jsp', '/panel/buscar.jsp', '/estudiante/proyecto.jsp', '/estudiante/habilitacion.jsp',
        '/ideas/banco.jsp', '/ideas/idea-form.jsp', '/panel/pqr.jsp', '/panel/avisos.jsp'] },
    ...['beto', 'caro', 'dani', 'eli', 'fer', 'gabi', 'hugo'].map((n, i) => ({ correo: `${n}.ui@correo.uts.edu.co`,
        nombre: `estudiante ${['fase 2', 'fase 3', 'fase 4', 'fase 4 aprobada', 'fase 5', 'fase final', 'seminario'][i]}`,
        paginas: ['/panel/inicio.jsp', '/estudiante/proyecto.jsp'] })),
];

async function entrar(pagina, correo) {
    await pagina.goto(B + '/index.jsp');
    await pagina.fill('#correo', correo);
    await pagina.fill('#clave', '123456');
    await Promise.all([pagina.waitForNavigation(), pagina.click('button[type=submit]')]);
}

// Revisa la página abierta; devuelve los problemas
async function problemas(pagina, respuesta, errores) {
    const p = [];
    if (!respuesta || respuesta.status() >= 400) p.push(`respuesta ${respuesta ? respuesta.status() : 'ninguna'}`);
    const estado = await pagina.evaluate(() => {
        const vista = document.documentElement.clientWidth;
        const sale = [...document.querySelectorAll('body *')].map(e => ({ e, r: e.getBoundingClientRect() }))
            .filter(x => x.r.width > 0 && x.r.right > vista + 1 && !x.e.closest('.table-responsive, .app-lateral'))
            .sort((a, b) => b.r.right - a.r.right).slice(0, 2)
            .map(x => `${x.e.tagName.toLowerCase()}${x.e.id ? '#' + x.e.id : ''}${x.e.className && typeof x.e.className === 'string' ? '.' + x.e.className.trim().split(/\s+/).join('.') : ''}`);
        return {
            bootstrap: getComputedStyle(document.body).boxSizing === 'border-box',
            estilo: getComputedStyle(document.body).fontFamily.includes('Plus Jakarta'),
            desborde: document.documentElement.scrollWidth - vista, sale,
            error: /HTTP Status \d|Estado HTTP \d|Exception/.test(document.body.innerText),
        };
    });
    if (estado.error) p.push('error del servidor');
    if (!estado.bootstrap) p.push('sin Bootstrap');
    if (!estado.estilo) p.push('sin estilo.css');
    if (estado.desborde > 1) p.push(`desborda ${estado.desborde} px: ${estado.sale.join(', ')}`);
    if (errores.length) p.push('JavaScript: ' + [...new Set(errores)].join(' | '));
    errores.length = 0;
    return p;
}

(async () => {
    for (const nav of NAVEGADORES) {
        let navegador;
        try { navegador = await nav.lanzar(); } catch (e) { revisar(`${nav.nombre} abre`, false, e.message.split('\n')[0]); continue; }
        console.log(`== ${nav.nombre} ${navegador.version()}`);
        for (const [ancho, tamano] of [[1366, 'computador'], [390, 'celular']]) {
            let paginas = 0;
            for (const r of RECORRIDOS) {
                const contexto = await navegador.newContext({ viewport: { width: ancho, height: 900 }, locale: 'es-CO' });
                const pagina = await contexto.newPage();
                const errores = [];
                pagina.on('pageerror', e => errores.push(e.message));
                pagina.on('console', m => { if (m.type() === 'error' && !/favicon/i.test(m.text())) errores.push(m.text()); });
                if (r.correo) await entrar(pagina, r.correo);
                for (const ruta of r.paginas) {
                    const respuesta = await pagina.goto(B + ruta);
                    const p = await problemas(pagina, respuesta, errores);
                    revisar(`${nav.nombre}, ${tamano}, ${r.nombre}: ${ruta}`, p.length === 0, p.join('; '));
                    paginas++;
                }
                if (r.correo && ancho === 390) {
                    await pagina.goto(B + '/panel/inicio.jsp');
                    await pagina.click('#botonMenu');
                    revisar(`${nav.nombre}, celular, ${r.nombre}: el botón abre el menú`,
                            await pagina.evaluate(() => document.body.classList.contains('menu-abierto')));
                }
                await contexto.close();
            }
            console.log(`  ${tamano}: ${paginas} páginas revisadas`);
        }
        // RNF17: Beto (fase 2) sube su propuesta desde el inicio. Clics: 1 "Mi proyecto", 2 el
        // campo del archivo, 3 y 4 escoger el archivo y "Abrir" en la ventana de Windows (aquí
        // los hace setFiles), 5 "Subir versión".
        const archivo = path.join(__dirname, 'tmp', 'propuesta-ui.docx');
        fs.mkdirSync(path.dirname(archivo), { recursive: true });
        fs.writeFileSync(archivo, 'documento de Word de prueba');
        const contexto = await navegador.newContext({ viewport: { width: 1366, height: 900 } });
        const pagina = await contexto.newPage();
        await entrar(pagina, 'beto.ui@correo.uts.edu.co');
        let clics = 0;
        await Promise.all([pagina.waitForNavigation(), pagina.click('.app-lateral-menu >> text=Mi proyecto')]); clics++;
        const [elegir] = await Promise.all([pagina.waitForEvent('filechooser'), pagina.click('#propuesta')]); clics++;
        await elegir.setFiles(archivo); clics += 2;
        await Promise.all([pagina.waitForNavigation(), pagina.click('button:has-text("Subir versión")')]); clics++;
        const subida = await pagina.locator('text=La versión del FDC-124 se subió correctamente').count() > 0;
        revisar(`${nav.nombre}: subir la propuesta toma ${clics} clics (máximo 5)`, subida && clics <= 5, subida ? '' : 'no se subió');
        await contexto.close();
        await navegador.close();
    }
    console.log(`\nResultado: ${ok} OK, ${falla} fallas`);
    process.exit(falla === 0 ? 0 : 1);
})().catch(e => { console.log(`  FALLA error inesperado: ${e.message.split('\n')[0]}`); console.log(`\nResultado: ${ok} OK, ${falla + 1} fallas`); process.exit(1); });
