# Registro de cambios

Formato: fecha · qué se hizo. Lo más nuevo arriba.

## 0.13.0 — 2026-10-30 · Agenda personal, más disfraces y personalización

- **Agenda personal:** los chicos también pueden agendar (un examen, entregar una maqueta…) con aviso o alarma. Lo ven ellos y los adultos, y a los adultos les llega en Novedades. Los adultos pueden marcar algo como **"Solo para mí"**: no aparece en la app de los demás ni les avisa. Cada uno edita lo suyo; los adultos, además, lo que no es privado.
- **Disfraces nuevos:** bombero, doctora, mago, chef, futbolista y robot (se desbloquean con puntos), y accesorio moño. **De Family App Plus:** sirena, dragón, hada y caballero, y la aureola.
- **Personalizar mi app** (paleta en Hoy o menú del adulto): modo automático, claro u **oscuro**, 4 colores y 4 fondos libres. Con Plus: 6 colores y 4 fondos más, y tarjetas de mi color, con borde o bien redondas. Cada miembro tiene su propia configuración y se guarda en la nube.
- En la demostración, todo lo de Plus está abierto para probarlo.

## 0.12.0 — 2026-10-30 · Niveles de palabras, resumen semanal y reto de la semana

- **Palabras por niveles:** el básico tiene los 7 temas de antes; el medio suma ropa, el cuerpo, el cielo y el clima, frutas y verduras, acciones y lugares; el avanzado trae frases útiles, días de la semana y emociones. El avanzado queda para **Family App Plus** (contenido pago, todavía sin cobro) y en la demostración está abierto para probarlo.
- **Resumen de la semana** (panel del adulto → "Semana" o menú): por hijo, barras de los últimos 7 días, % de rutina, puntos, días con 8 vasos, ánimo más frecuente, mejor día y avance del reto.
- **Reto de la semana** (menú del adulto): rutina completa, 8 vasos de agua o juntar puntos, con meta y puntos extra. Los chicos ven el progreso en Hoy y lo cobran una vez por semana.
- **Privacidad y datos:** pantalla que explica qué se guarda, dónde y qué no se pide (útil para la publicación en Play Store).

## 0.11.0 — 2026-10-30 · Agenda, palabras en idiomas y tiempo de juego

- **Agenda familiar:** los adultos anotan turnos, cumpleaños o actos con lugar, día, hora, para quién y notas. Se puede elegir un aviso (a la hora, 10 o 30 minutos antes, 1 o 2 horas antes, 1 día antes) o que **suene como alarma** hasta tocarla. Los avisos los programa Android: llegan aunque la app esté cerrada y sin plan Blaze. Los chicos ven "Hoy en la agenda" en su pantalla Hoy y el adulto ve lo de hoy en su panel.
- **Aprender palabras:** inglés, portugués y coreano (con cómo se lee). Hay 7 temas (colores, números, animales, comida, familia, la casa y el colegio) con tarjetas que se escuchan con la voz del teléfono y un quiz de 5 preguntas que da 1 punto por respuesta correcta, una vez por día. "Palabra del día" en la pantalla Hoy. El adulto elige qué idiomas usa el hogar. No gasta tiempo de juego.
- **Tiempo de juego por día:** el adulto elige sin límite, 15, 30, 45, 60 o 90 minutos. Los chicos ven cuánto les queda y, al terminarse, no pueden seguir jugando hasta el otro día.
- **Borrar partidas terminadas:** "Borrar todas" o deslizar una para borrarla.
- **Reglas de Firestore actualizadas:** agregan la colección `events` (agenda).

## 0.10.0 — 2026-10-30 · Ícono propio y Mi Barrio

- **Ícono propio:** una casa con una estrella sobre fondo azul violeta. Incluye ícono adaptable de Android, versión monocromo para los temas de Android 13 o superior, pantalla de carga con el ícono y un ícono blanco para los avisos.
- **Mi Barrio**, juego propio de 2 a 4 jugadores (o contra Robi): se tiran dos dados en un tablero de 20 casillas. Los lugares del barrio (kiosco, heladería, cine, zoológico, castillo…) se pueden comprar; si caés en el de otro, le pagás alquiler, que es doble si tiene todo el grupo de color. Además hay casillas de Sorpresa, impuestos que van al pozo, la Fuente que se lleva el pozo y la Siesta que hace perder un turno. Quien se queda sin monedas sale del juego; al terminar las vueltas gana el más rico.

## 0.9.0 — 2026-10-30 · Teléfono nuevo y avisos para los chicos

- **Teléfono nuevo de alguien:** si alguien borra la app o cambia de celular, un adulto elige "Teléfono nuevo de alguien" en el menú del panel y muestra un QR. En el teléfono nuevo se escanea con "Me invitaron" y vuelve a entrar con el mismo perfil, puntos, avatar e historial. El teléfono anterior pierde el acceso. Si el adulto rechaza, el perfil no se borra: queda sin teléfono propio.
- **Avisos para los chicos:** cuando un adulto les aprueba un premio o una tarea, les llega un aviso (con la app abierta o minimizada) y lo ven en "Para vos" en la pantalla Hoy.
- **Reglas de Firestore actualizadas:** permiten que el teléfono nuevo se vincule a su perfil. Hay que volver a publicarlas.

## 0.8.0 — 2026-10-30 · Área de juegos

- **Juegos:** nueva pestaña para los chicos y botón en el panel del adulto. Cuatro juegos por turnos: **Tres en raya**, **4 en línea**, **Ludo** (2 a 4 jugadores, con dado, casillas seguras, comer fichas y meta justa) y **Ajedrez** (con enroque, captura al paso, coronación, jaque mate y ahogado; muestra los movimientos posibles).
- **Contra la familia o contra Robi:** se puede jugar con otro miembro desde su propio celular (le aparece "Te toca" en Juegos y un aviso si tiene la app minimizada), pasándose un solo teléfono, o contra Robi, la compu, que a veces se equivoca a propósito.
- **Primero la rutina:** el adulto elige cuándo pueden jugar los chicos: siempre, con media rutina hecha (por defecto) o con la rutina completa. Los adultos juegan siempre.
- Las partidas se sincronizan entre teléfonos y avisan en Novedades cuando empiezan y quién ganó. Botón de revancha y de abandonar.
- **Reglas de Firestore actualizadas** (`firebase/firestore.rules`): agregan la colección `games`. Hay que volver a publicarlas en la consola de Firebase.

## 0.7.0 — 2026-10-30 · Novedades y avisos (sin plan Blaze)

- **Novedades:** campanita en el panel del adulto con el número de novedades sin leer. Al tocarla se ve todo lo que pasó, agrupado por día ("Hoy", "Ayer"…) y por hijo: las tareas de cada hijo se juntan en una línea ("Tomi completó 5 tareas") para no llenar la pantalla. Filtros: Todo, Importantes o un miembro.
- **Avisos del sistema** mientras Family App está abierta o minimizada. Cada teléfono elige: **Solo lo importante** (por defecto: pedidos de premios, altas, tareas para aprobar y alertas), **Todo** o **Nada**. Lo que hace uno mismo nunca avisa.
- Nuevos avisos: premio pedido, premio o tarea aprobados (con el nombre de quién aprobó) y premio dejado para otro momento.
- "Cambiar de usuario" pasó al menú de tres puntos.
- Con la app cerrada no llegan avisos (eso necesita el plan Blaze de Firebase); al abrirla, todo aparece en Novedades.

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
