# Cuántos usan Family App

Family App **no tiene analítica ni rastreo** a propósito: la usan chicos, y Google Play y la ley piden mucho cuidado con eso. Igual se puede saber cuánta gente la usa sin mirar los datos de nadie.

## Hoy, desde la consola de Firebase

1. **Teléfonos conectados:** consola de Firebase → **Authentication → Usuarios**. Cada fila es un teléfono (sesión anónima), con la fecha de creación y de último ingreso. Ojo: si alguien reinstala la app, aparece como un teléfono nuevo.
2. **Hogares creados:** **Firestore Database → Datos → colección `homes`**. Cada documento es un hogar.
3. **Miembros de un hogar:** dentro de cada hogar, la subcolección `members`. **Solo mirar números:** abrir los datos de una familia es acceder a datos personales y requiere un motivo (soporte o pedido de la familia).
4. **Uso y costos:** **Firestore → Uso** muestra lecturas y escrituras por día. Sirve para saber si la app se usa y para controlar el plan gratuito.

## Con el script de estadísticas (recomendado)

En [`tools/estadisticas/`](../../tools/estadisticas/) hay un script que **solo cuenta**: no muestra apodos ni contenido. Informa:

- hogares;
- miembros (adultos, hijos, hijos sin celular);
- teléfonos activos en los últimos 7 y 30 días;
- partidas jugadas y eventos de agenda.

Las instrucciones están en su [README](../../tools/estadisticas/README.md).

## ¿Cuántas veces se compartió la app?

- **Invitaciones:** la colección `invites` guarda cada QR generado y si se usó (`usedBy`). El script cuenta las creadas y las usadas.
- **Descargas:** cuando esté en Play Store, la **Play Console** muestra instalaciones, desinstalaciones, países y calificaciones, sin datos personales.
- El enlace de GitHub **no sirve para contar descargas**: cada compilación reemplaza el APK y el contador vuelve a cero. Para contar instalaciones de verdad, usá el script (teléfonos) o la Play Console.

## Más adelante

Si hace falta más detalle (qué pantallas se usan más, por ejemplo), se puede sumar Firebase Analytics **solo en los teléfonos de adultos** y con la configuración para Familias: sin identificador de publicidad y sin datos de chicos. Hay que reflejarlo en la política de privacidad antes de activarlo.
