# Family App

App móvil familiar que convierte la rutina diaria de los hijos en hábitos y responsabilidades. Cada tarea cumplida suma puntos que se canjean por premios, y los adultos siguen el progreso, la salud básica, la agenda y el ánimo del día desde su propio panel.

- **Paquete:** `com.javimathesan.familyapp` (Android; iOS más adelante).
- **Versión actual:** 0.13 (prueba). [Registro de cambios](CHANGELOG.md).
- **Versión de prueba:** cada cambio en `main` publica el APK firmado en [la versión `prueba`](https://github.com/javimathesan/family_app/releases/tag/prueba).

## Qué tiene hoy (v0.13)

| Área | Qué hace |
| --- | --- |
| **Hogar y teléfonos** | Crear hogar, invitar por QR (código de un solo uso, vence en 15 min), aprobar altas, roles P1/P2/conviviente/hijo, hijo sin celular, PIN del modo adulto, **teléfono nuevo de alguien** (vuelve con su perfil) y desvincular. Sincronización en vivo con Firebase. |
| **Rutina y puntos** | Tareas por momento del día, por hijo, con hora, puntos y validación (sola, foto o adulto). Puntos completos a tiempo, mitad fuera de horario. El adulto edita tareas y premios. |
| **Premios** | Tienda con pedido y aprobación, puntos devueltos si se rechaza, alcancía mensual. |
| **Salud y ánimo** | Agua (meta 8 vasos), popó/pipí con alerta a los 2 días, ánimo del día, calendario de caritas. |
| **Panel del adulto** | Mi día (metas del adulto), Para aprobar, Novedades con campanita, **resumen de la semana**, **reto de la semana**. |
| **Avisos** | Novedades agrupadas por día e hijo; avisos del sistema con la app abierta o minimizada; preferencia por teléfono (importante / todo / nada); avisos a los chicos cuando les aprueban algo. |
| **Agenda** | Turnos, exámenes, cumpleaños con lugar, día, hora, para quién y notas. Aviso o **alarma** que suena aunque la app esté cerrada. Los chicos agendan lo suyo y los padres lo ven; los adultos pueden marcar "solo para mí". |
| **Juegos** | Tres en raya, 4 en línea, ludo, ajedrez y **Mi Barrio** (juego propio de propiedades); contra la familia (cada uno en su celular o pasando el teléfono) o contra Robi. Regla "primero la rutina", minutos por día y borrar partidas terminadas. |
| **Palabras** | Inglés, portugués y coreano en 3 niveles (básico, medio y avanzado de Plus), tarjetas con voz, quiz con puntos una vez por día y palabra del día. |
| **Avatar y personalización** | Avatar estilo Funko con 19 disfraces (4 de Plus) y accesorios que se desbloquean con puntos. Modo claro/oscuro, colores, fondos y tarjetas por miembro (opciones extra de Plus). Ícono propio. |
| **Privacidad** | Sin email, teléfono, ubicación ni fotos; solo apodos. Pantalla "Privacidad y datos" en la app. |

## Qué falta, por prioridad

### 1. Legal (antes de mostrarla fuera de la familia)

Ver [docs/legal/](docs/legal/): borradores de **política de privacidad** y **términos y condiciones**, y la [lista de pasos legales](docs/legal/checklist-legal.md).

- [ ] Completar los datos del responsable (nombre o razón social, domicilio y email de contacto) en los borradores.
- [ ] Revisión por un abogado (datos de menores y de salud).
- [ ] Publicar la política en una dirección web pública (la pide Play Store).
- [ ] Inscribir la base de datos en el Registro Nacional de Bases de Datos (AAIP).
- [ ] Consentimiento del adulto dentro de la app al crear el hogar (aceptar términos y política).
- [ ] **Borrar mis datos / borrar el hogar** desde la app y por web (Play Store lo exige).

### 2. Publicación en Google Play

- [ ] Cuenta de desarrollador de Google Play.
- [ ] Ficha: textos, capturas, ícono 512 px, gráfico destacado.
- [ ] Formulario de **seguridad de los datos** y público objetivo (incluye menores: política de Familias).
- [ ] Prueba cerrada con familias conocidas.
- [ ] Revisar que ninguna librería use el identificador de publicidad.

### 3. Producto

- [ ] Cobro de **Family App Plus** con Google Play (nivel avanzado de palabras, disfraces y personalización extra). La app ya marca qué es de Plus.
- [ ] Avisos con la app cerrada para novedades y turnos de juego (plan Blaze de Firebase + Cloud Functions).
- [ ] Validación con foto real (Firebase Storage, también requiere Blaze).
- [ ] Mascotas como tareas especiales y control de tiempo de pantallas.
- [ ] Estadísticas de uso para el administrador sin rastrear a los chicos (ver [docs/admin/](docs/admin/usuarios-y-estadisticas.md)).
- [ ] Más juegos (sopa de letras, memoria) y jugar con amigos de otras familias con doble autorización.
- [ ] iOS.

### 4. Técnico

- [ ] Índices y reglas de Firestore revisados con el emulador.
- [ ] Copias de seguridad de Firestore.
- [ ] Limpieza de sesiones anónimas viejas (sin borrar las de hogares activos).

## Carpetas

| Carpeta | Contenido |
| --- | --- |
| [`app/`](app/) | App Flutter: [cómo correrla, probarla y compilarla](app/README.md) |
| [`firebase/`](firebase/) | Reglas de seguridad de Firestore (se pegan en la consola de Firebase) |
| [`docs/`](docs/) | [Borrador de la idea](docs/borrador-idea-v1.md), [legal](docs/legal/) y [administración](docs/admin/) |
| [`tools/`](tools/) | [Estadísticas de uso](tools/estadisticas/) para el administrador |
| [`diseno/`](diseno/) | Maquetas originales de la v1 |

## Cómo se trabaja

- Cada cambio se sube a `main`; GitHub Actions analiza, corre las pruebas, compila el APK firmado y lo publica en la versión `prueba`.
- Los archivos secretos (`google-services.json`, `key.properties`, `upload-keystore.jks`, `secretos-github.txt`, claves de servicio) **nunca** se suben: el repositorio es público.
- Las reglas de `firebase/firestore.rules` se publican a mano en la consola de Firebase cada vez que cambian.

## Stack

Flutter (Material 3) · Firebase Authentication (anónima) · Cloud Firestore · avisos locales (flutter_local_notifications) · voz del teléfono (flutter_tts) · GitHub Actions.
