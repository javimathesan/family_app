# Registro de cambios

Formato: fecha · qué se hizo. Lo más nuevo arriba.

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
