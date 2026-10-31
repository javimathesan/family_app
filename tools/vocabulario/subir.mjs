// Sube los paquetes de palabras de la carpeta paquetes/ a Firestore (colección vocab).
//
// Uso:  node subir.mjs ruta/a/clave-de-servicio.json
import { readFileSync, readdirSync } from 'node:fs';
import { cert, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const keyPath = process.argv[2];
if (!keyPath) {
  console.error('Falta la ruta a la clave de servicio de Firebase.');
  process.exit(1);
}
initializeApp({ credential: cert(JSON.parse(readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();

const required = ['es', 'en', 'pt', 'ko', 'ko_r', 'emoji'];
for (const file of readdirSync(new URL('./paquetes/', import.meta.url)).filter((f) => f.endsWith('.json'))) {
  const pack = JSON.parse(readFileSync(new URL(`./paquetes/${file}`, import.meta.url), 'utf8'));
  const problems = [];
  if (!pack.id || !pack.label) problems.push('falta id o label');
  if (!['basico', 'medio', 'avanzado'].includes(pack.level)) problems.push('level tiene que ser basico, medio o avanzado');
  if (!Array.isArray(pack.words) || pack.words.length < 4) problems.push('hacen falta al menos 4 palabras');
  for (const [i, w] of (pack.words ?? []).entries()) {
    for (const k of required) if (!w[k]) problems.push(`palabra ${i + 1}: falta "${k}"`);
  }
  if (problems.length) {
    console.error(`✗ ${file}: ${problems.join('; ')}`);
    continue;
  }
  await db.collection('vocab').doc(pack.id).set({ ...pack, active: pack.active ?? true });
  console.log(`✓ ${file}: ${pack.words.length} palabras (${pack.label})`);
}
