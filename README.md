# family_app

App móvil familiar que convierte la rutina diaria de los hijos en hábitos sanos y responsabilidades. Cada tarea cumplida suma puntos que se canjean por premios los fines de semana y a fin de mes, y el adulto sigue el progreso, la salud básica y el ánimo del día desde su propio panel.

## Estado

**Etapa actual: v0.12.** Family App (`com.javimathesan.familyapp`) corre en Android y sincroniza los teléfonos del hogar con Firebase: crear hogar, invitar por QR, aprobar altas y ver en vivo lo que hace cada hijo. El adulto edita la rutina y los premios, asigna tareas a cada hijo y registra su propio día. Novedades con campanita y avisos mientras la app está abierta; y un Área de juegos (tres en raya, 4 en línea, ludo y ajedrez) para jugar en familia o contra Robi. Faltan los avisos con la app cerrada (push). Ver el [registro de cambios](CHANGELOG.md).

| Carpeta | Contenido |
| --- | --- |
| [`app/`](app/) | App Flutter: [cómo correrla y probarla](app/README.md) |
| [`docs/`](docs/) | [Borrador de la idea v1](docs/borrador-idea-v1.md): funcionalidades, roles, puntos, privacidad, arquitectura y hoja de ruta |
| [`diseno/`](diseno/) | Maquetas de las 8 pantallas de la v1 en formato de lienzo de diseño (`.dc.html`) |

## Pantallas diseñadas (v1)

| Archivo | Pantalla | Para quién |
| --- | --- | --- |
| `Main.dc.html` | Hoy: puntos del día, próxima tarea, agua, popó y pipí | Hijo |
| `Rutina.dc.html` | Rutina por bloques con tareas para marcar | Hijo |
| `Calendario.dc.html` | Calendario mensual de caritas según cumplimiento | Hijo |
| `Premios.dc.html` | Tienda de premios semanal, alcancía del mes y reto | Hijo |
| `Adulto.dc.html` | Mi familia: miembros, aprobaciones y avisos | Adulto |
| `Invitar.dc.html` | Invitar con QR: rol, modo por edad, código de un solo uso que vence en 15 min | Adulto |
| `Unirse.dc.html` | Unirse al hogar en 3 pasos: escanear, elegir apodo, esperar confirmación | Nuevo miembro |
| `Avatar.dc.html` | Editor de avatar estilo Funko: piel, pelo, ojos, anteojos, ropa y accesorios | Miembro |

Los nombres y números de las maquetas son datos de ejemplo.

## Hoja de ruta

1. **v1 – Núcleo familiar:** hogar y alta por QR, roles P1/P2, rutina con puntos, notificaciones al adulto, tienda de premios, calendario de caritas, agua/popó/pipí, colores básicos y avatar simple.
2. **v1.1 – Cuidado y salud:** mascotas, pantallas, retos, alcancía mensual, reportes.
3. **v2 – Comunicación:** mensajes grupales, chats internos, notas y agenda.
4. **v2.1 – Diversión y aprendizaje:** minijuegos y palabras en 4 idiomas, avatar estilo Funko.
5. **v3 – Fuera del hogar:** contactos entre familias con doble autorización, temas descargables.

## Stack previsto

Flutter (Android e iOS) · NestJS + PostgreSQL · WebSocket + Redis · Firebase Cloud Messaging / APNs.

## Próximos pasos

- [x] Diseñar alta por QR y editor de avatar.
- [ ] Resolver las preguntas abiertas del borrador.
- [x] Crear el proyecto Flutter con la estructura base y los temas de color.
- [x] Construir las 8 pantallas de la v1 con datos de ejemplo y pruebas.
- [x] Escaneo real del QR con la cámara.
- [x] Guardar los datos en el teléfono.
- [x] Identificador definitivo para publicar en tiendas.
- [x] Backend y cuentas para sincronizar los teléfonos del hogar (Firebase).
- [x] Que el adulto edite tareas, horarios, puntos y premios.
- [x] Tareas por hijo, Mi día del adulto y PIN del modo adulto.
- [x] Novedades y avisos con la app abierta.
- [ ] Avisos con la app cerrada (push, requiere plan Blaze).
- [x] Volver a vincular un teléfono sin perder el perfil.
- [x] Área de juegos en familia: tres en raya, 4 en línea, ludo y ajedrez.
- [x] Ícono propio y Mi Barrio (juego de propiedades propio).
- [x] Agenda con avisos y alarmas, palabras en inglés, portugués y coreano, y tiempo de juego por día.
- [x] Niveles de palabras, resumen semanal, reto de la semana y pantalla de privacidad.
- [ ] Cobro de Family App Plus con Google Play (requiere la cuenta de desarrollador).
- [ ] Jugar con amigos de otras familias.
