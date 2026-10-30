# family_app

App móvil familiar que convierte la rutina diaria de los hijos en hábitos sanos y responsabilidades. Cada tarea cumplida suma puntos que se canjean por premios los fines de semana y a fin de mes, y el adulto sigue el progreso, la salud básica y el ánimo del día desde su propio panel.

## Estado

**Etapa actual: v0.2.** La app (Family App, `com.javimathesan.familyapp`) corre en Android con todas las pantallas de la v1, escaneo de QR con la cámara y datos guardados en el teléfono. Falta backend para sincronizar varios teléfonos y notificaciones. Ver el [registro de cambios](CHANGELOG.md).

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
- [ ] Backend y cuentas para sincronizar los teléfonos del hogar.
- [ ] Que el adulto edite tareas, horarios, puntos y premios.
- [ ] Notificaciones push al adulto.
