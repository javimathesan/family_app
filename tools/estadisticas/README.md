# Estadísticas de Family App

Script para el administrador que **solo cuenta** hogares, miembros, teléfonos activos, invitaciones, partidas y eventos. No muestra apodos ni contenido de ninguna familia.

## Una sola vez

1. Instalá [Node.js](https://nodejs.org) (versión 20 o más nueva).
2. En la consola de Firebase: **⚙️ Configuración del proyecto → Cuentas de servicio → Generar nueva clave privada**. Se descarga un archivo `.json`.
3. Guardalo **fuera del repositorio**, por ejemplo en `C:\DevP\Personal\Claves\family-app-admin.json`. **Nunca lo subas a GitHub:** da acceso total a la base de datos.
4. En esta carpeta: `npm install`.

## Cada vez que quieras ver los números

```
node estadisticas.mjs C:\DevP\Personal\Claves\family-app-admin.json
```

Sale algo así:

```
Hogares ............................ 3
Miembros ........................... 11
  adultos .......................... 5
  hijos ............................ 6 (sin celular: 2)
Teléfonos (sesiones) ............... 9
  activos últimos 7 días ........... 7
...
```

Cada teléfono que instala la app es una "sesión". Si alguien reinstala la app, cuenta como un teléfono nuevo.
