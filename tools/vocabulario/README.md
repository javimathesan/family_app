# Paquetes de palabras

Los temas de **Aprender palabras** que vienen dentro de la app se pueden ampliar con **paquetes** guardados en Firebase. Los teléfonos los bajan solos al abrir la app: no hace falta publicar una versión nueva.

## Cómo es un paquete

Un archivo `.json` en `paquetes/` (mirá `fiestas.json` de ejemplo):

| Campo | Qué es |
| --- | --- |
| `id` | Identificador único, sin espacios (`fiestas`) |
| `label` | Nombre que se ve (`Cumpleaños y fiestas`) |
| `emoji` | Dibujo del tema |
| `level` | `basico`, `medio` o `avanzado` (el avanzado es de Plus) |
| `order` | Orden entre los paquetes del mismo nivel |
| `active` | `false` para ocultarlo sin borrarlo |
| `words` | Palabras: `emoji`, `es`, `en`, `pt`, `ko` y `ko_r` (cómo se lee el coreano) |

Antes de subir un paquete, que alguien que sepa el idioma revise las traducciones.

## Subirlos

1. Una sola vez: `npm install` en esta carpeta, y la clave de servicio de Firebase (ver `tools/estadisticas/README.md`). **Nunca la subas a GitHub.**
2. `node subir.mjs C:\DevP\Personal\Claves\family-app-admin.json`

El script revisa cada paquete y avisa si le falta algo. También se pueden cargar a mano en la consola: **Firestore → colección `vocab`**.
