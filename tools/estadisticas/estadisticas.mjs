// Estadísticas de uso de Family App. Solo cuenta: no imprime apodos ni contenido.
//
// Uso:  node estadisticas.mjs ruta/a/clave-de-servicio.json
// (o con la variable GOOGLE_APPLICATION_CREDENTIALS).
import { readFileSync } from 'node:fs';
import { cert, initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const keyPath = process.argv[2];
initializeApp({
  credential: keyPath ? cert(JSON.parse(readFileSync(keyPath, 'utf8'))) : applicationDefault(),
});
const db = getFirestore();
const auth = getAuth();

const count = async (query) => (await query.count().get()).data().count;

const DAY = 24 * 60 * 60 * 1000;
const now = Date.now();

// Teléfonos (sesiones anónimas) y actividad reciente.
let phones = 0;
let active7 = 0;
let active30 = 0;
let pageToken;
do {
  const page = await auth.listUsers(1000, pageToken);
  for (const user of page.users) {
    phones++;
    const last = Date.parse(user.metadata.lastRefreshTime ?? user.metadata.lastSignInTime ?? user.metadata.creationTime);
    if (now - last <= 7 * DAY) active7++;
    if (now - last <= 30 * DAY) active30++;
  }
  pageToken = page.pageToken;
} while (pageToken);

// Miembros: solo rol, si tiene teléfono y si está pendiente.
const members = await db.collectionGroup('members').select('role', 'uid', 'pending').get();
const roles = { adultos: 0, hijos: 0, hijosSinCelular: 0, pendientes: 0 };
for (const doc of members.docs) {
  const { role, uid, pending } = doc.data();
  if (pending) roles.pendientes++;
  if (role === 'child') {
    roles.hijos++;
    if (!uid) roles.hijosSinCelular++;
  } else {
    roles.adultos++;
  }
}

const homes = await count(db.collection('homes'));
const invites = await count(db.collection('invites'));
const invitesUsed = await count(db.collection('invites').where('usedBy', '!=', null));
const games = await count(db.collectionGroup('games'));
const events = await count(db.collectionGroup('events'));

console.log(`
Family App · ${new Date().toLocaleString('es-AR')}

Hogares ............................ ${homes}
Miembros ........................... ${members.size}
  adultos .......................... ${roles.adultos}
  hijos ............................ ${roles.hijos} (sin celular: ${roles.hijosSinCelular})
  esperando aprobación ............. ${roles.pendientes}
Teléfonos (sesiones) ............... ${phones}
  activos últimos 7 días ........... ${active7}
  activos últimos 30 días .......... ${active30}
Invitaciones creadas / usadas ...... ${invites} / ${invitesUsed}
Partidas guardadas ................. ${games}
Eventos de agenda .................. ${events}
`);
