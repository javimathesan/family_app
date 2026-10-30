# Registro de cambios

Formato: fecha · qué se hizo. Lo más nuevo arriba.

## 0.6.0 — 2026-10-30 · Tareas por hijo, Mi día del adulto y PIN

- **Tareas por hijo:** en Rutina y premios, "¿Para quién?" permite que una tarea sea para todos o solo para algunos hijos. La rutina, el progreso, la próxima tarea y el calendario de cada hijo cuentan solo sus tareas.
- **Mi día del adulto:** metas diarias (ejercicio, lectura, jugar con los hijos, comida en familia sin celulares, amigos, menos pantallas). Se sincronizan, no dan puntos, y algunas avisan al hogar.
- **PIN del modo adulto:** 4 números por teléfono para abrir perfiles de adulto desde "¿Quién usa la app?". Se pone, cambia o quita desde el menú del panel. Se guarda solo un resumen (SHA-256).
- Los chicos ven un mensaje cuando no tienen tareas en un momento del día.

## 0.5.0 — 2026-10-30 · Rutina y premios editables

- **Rutina y premios:** el adulto crea, edita y borra tareas (nombre, momento del día, hora, puntos y quién la valida) y premios (nombre, puntos e ícono). Se sincronizan con todos los teléfonos del hogar.
- **Panel del adulto:** muestra su avatar (tocarlo abre el editor), la sección **Adultos del hogar** y mensajes de ayuda cuando todavía no hay hijos ni avisos.
- Al crear el hogar, el adulto arma primero su avatar.
- Los adultos tienen todos los disfraces libres; los chicos los desbloquean con puntos.
- Versión de prueba automática: GitHub compila con Firebase real y la clave de firma, y publica el APK en un enlace fijo.

## 0.4.0 — 2026-10-30 · Avatares con disfraces

- Disfraces originales que se desbloquean una vez con puntos: superhéroe, princesa, ninja, astronauta, pirata, dinosaurio, unicornio y uniforme estilo anime (sin personajes con marca registrada).
- Corona: accesorio que se desbloquea con puntos.
- Dibujo mejorado: contornos, manos, zapatos, orejas y brillo; peinados puntiagudo, coletas y rodete; ojos brillantes estilo anime; más colores.
- Lo desbloqueado se guarda en el teléfono y en la nube.
- Tocar el avatar en Hoy abre el editor.

## 0.3.0 — 2026-10-30 · Hogar compartido entre teléfonos (Firebase)

### Agregado
- Hogar compartido en Cloud Firestore: cada teléfono entra con una sesión anónima de Firebase, sin email ni contraseña.
- Primeros pasos: "Crear mi hogar", "Me invitaron" o "Probar con datos de ejemplo".
- Invitaciones reales: el QR crea un código de un solo uso en el servidor que vence en 15 minutos.
- Unirse con aprobación real: el teléfono nuevo queda esperando y el adulto aprueba o rechaza desde "Para aprobar".
- Sincronización en vivo entre teléfonos: tareas, aprobaciones, puntos, agua y salud, canjes, avatares, colores y avisos.
- "Hijo sin celular": el adulto lo agrega y lo maneja desde su teléfono.
- "Desvincular este teléfono" y "Salir de la demostración".
- Escanear el QR con la cámara del teléfono abre Family App en la pantalla para unirse.
- Reglas de seguridad de Firestore en `firebase/firestore.rules`.

### Técnico
- `google-services.json` no está en el repo (es público): el plugin de Firebase se aplica solo si el archivo está en `app/android/app/`.
- Android mínimo: 7.0 (API 24), lo que pide Firebase.
- Pruebas de sincronización con Firestore simulado (`fake_cloud_firestore`).
- La verificación de GitHub compila con una configuración de Firebase de prueba: el APK de Actions funciona solo en modo demostración.

## 0.2.0 — 2026-10-30 · Cámara, guardado y listo para tiendas

### Cambios importantes
- **Nuevo identificador:** `com.javimathesan.familyapp` (antes `com.example.family_app`, que las tiendas no aceptan). En el teléfono se instala como una app nueva llamada **Family App**: desinstalá la vieja "family_app".

### Agregado
- Escaneo real del QR de invitación con la cámara (`mobile_scanner`), con linterna y aviso si el QR no es de Family App.
- Permiso de cámara en Android, iOS y macOS con texto que explica para qué se usa.
- Los datos se guardan en el teléfono (`shared_preferences`): miembros, avatares, colores, puntos, alcancía, tareas del día, salud, canjes, avisos y calendario.
- Cierre del día: al abrir la app otro día, el día anterior pasa al calendario y la rutina arranca vacía.
- Opción "Restablecer datos de ejemplo" en el panel del adulto (menú de tres puntos).
- La verificación de GitHub ahora también compila la app para Android y deja un APK de prueba para descargar.

### Cambiado
- El botón "Simular escaneo" solo aparece en modo desarrollo.

## 0.1.1 — 2026-10-30 · Primera corrida en un celular real
- Carpetas de plataformas generadas con `flutter create` (Android, iOS, web, Windows, macOS, Linux).
- `pubspec.lock` versionado para que todos usen las mismas versiones de paquetes.
- El analizador ignora las carpetas generadas de cada plataforma.
- `.gitattributes` para unificar los fines de línea entre Windows y el resto.

## 0.1.0 — 2026-10-29 · Primera versión navegable

### App (Flutter, carpeta `app/`)
- Estructura base del proyecto, rutas y tema claro/oscuro con acento por miembro.
- Modelos del dominio: hogar, miembros y roles (P1, P2, hijo, conviviente), modos por edad, tareas, salud, premios, canjes y avatar.
- Reglas de puntos: puntos completos a tiempo y mitad fuera de horario, bonus de racha, tienda de viernes a domingo, caritas por cumplimiento y alerta tras 2 días sin popó.
- Datos de ejemplo en memoria (`FamilyStore.demo`) iguales a las maquetas.
- Pantallas del hijo: Hoy, Rutina, Calendario de caritas y Premios.
- Pantallas del adulto: Mi familia con aprobaciones y avisos, e Invitar con QR.
- Alta de miembros: unirse al hogar en 3 pasos y editor de avatar estilo Funko.
- Cada miembro elige su color de acento desde Hoy (ícono de paleta).
- Pruebas unitarias, de estado y de navegación, y CI con GitHub Actions (`flutter analyze` + `flutter test` en verde).
- Corregido: tarjetas como `Material` para que los `ListTile` muestren el toque, e invitación sin desbordes en pantallas angostas.

### Diseño (carpeta `diseno/`)
- 8 maquetas interactivas: Hoy, Rutina, Calendario, Premios, Mi familia, Invitar con QR, Unirse y Avatar.

### Documentación (carpeta `docs/`)
- Borrador de la idea v1 con funcionalidades, privacidad, arquitectura y hoja de ruta.
