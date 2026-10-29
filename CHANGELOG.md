# Registro de cambios

Formato: fecha · qué se hizo. Lo más nuevo arriba.

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
