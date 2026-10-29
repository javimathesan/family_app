# family_app

App móvil familiar que convierte la rutina diaria de los hijos en hábitos sanos y responsabilidades. Cada tarea cumplida suma puntos que se canjean por premios los fines de semana y a fin de mes, y el adulto sigue el progreso, la salud básica y el ánimo del día desde su propio panel.

## Estado

**Etapa actual: diseño (v1).** Todavía no hay código de la app.

| Carpeta | Contenido |
| --- | --- |
| [`docs/`](docs/) | [Borrador de la idea v1](docs/borrador-idea-v1.md): funcionalidades, roles, puntos, privacidad, arquitectura y hoja de ruta |
| [`diseno/`](diseno/) | Maquetas de las primeras 5 pantallas en formato de lienzo de diseño (`.dc.html`) |

## Pantallas diseñadas (v1)

| Archivo | Pantalla | Para quién |
| --- | --- | --- |
| `Main.dc.html` | Hoy: puntos del día, próxima tarea, agua, popó y pipí | Hijo |
| `Rutina.dc.html` | Rutina por bloques con tareas para marcar | Hijo |
| `Calendario.dc.html` | Calendario mensual de caritas según cumplimiento | Hijo |
| `Premios.dc.html` | Tienda de premios semanal, alcancía del mes y reto | Hijo |
| `Adulto.dc.html` | Mi familia: miembros, aprobaciones y avisos | Adulto |

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

- [ ] Diseñar alta por QR y editor de avatar.
- [ ] Resolver las preguntas abiertas del borrador.
- [ ] Crear el proyecto Flutter con la estructura base y los temas de color.
