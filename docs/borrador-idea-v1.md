# family_app — Borrador de idea v1

Versión editable: https://claude.ai/artifact/UMgUmvbLSq6xXAStoSJe51 · 28 de octubre de 2026

## Visión y objetivos

family_app es una app móvil familiar que convierte la rutina diaria de los hijos en hábitos sanos y responsabilidades, premiando cada tarea cumplida con puntos canjeables los fines de semana y a fin de mes. Los padres no pueden estar encima de sus hijos todo el día; la app les da visibilidad, control de salud y una herramienta de comunicación sin invadir.

**Objetivos de la v1**

- Que cada hijo tenga una rutina clara, con horarios, que pueda marcar como cumplida.
- Que el adulto vea en tiempo real el progreso, el estado de ánimo del día y alertas de salud básicas.
- Que el esfuerzo se traduzca en recompensas concretas y negociadas en familia.
- Que aprender sea divertido: minijuegos en grupo y vocabulario en 4 idiomas.
- Que la privacidad de los menores esté protegida por diseño, sin datos personales expuestos.

**Principios de diseño**

- **Educativa, no punitiva:** se premia lo cumplido; no se resta por lo no hecho (salvo reglas que el adulto active).
- **El adulto decide:** tareas, horarios, premios, retos y contactos externos los configura y autoriza el adulto.
- **Simple por defecto, personalizable a fondo:** colores sobrios de fábrica; temas, colores y avatares a gusto de cada miembro.
- **Para todas las edades:** íconos grandes y pocos textos para los más chicos; más autonomía y estadísticas para adolescentes.

## Usuarios, roles y vinculación por QR

El adulto instala la app, crea el "Hogar" y suma al resto de los convivientes escaneando un QR desde sus celulares; así sabe siempre cuántas personas están bajo su cuidado.

| Rol | Quién es | Puede |
| --- | --- | --- |
| Administrador (P1) | Adulto que crea el hogar | Todo: tareas, horarios, premios, retos, autorizaciones, eliminar miembros |
| Co-administrador (P2) | Segundo adulto responsable | Igual que P1, salvo eliminar el hogar o a P1 |
| Hijo / menor | Niño o adolescente a cargo | Marcar tareas, registrar salud, jugar, chatear con contactos autorizados, canjear premios |
| Otro adulto conviviente | Abuelos, tíos, cuidadores | Gestionar su propio día y, si P1 lo permite, validar tareas |

**Flujo de alta**

1. El adulto descarga la app, crea su cuenta y el Hogar (nombre, zona horaria, idioma).
2. Genera un QR de invitación por rol; el código vence en 15 minutos y es de un solo uso.
3. El miembro instala la app, escanea el QR y crea su perfil y avatar.
4. El adulto confirma el alta y ve al nuevo miembro en su lista.

**Edades sugeridas para la interfaz:** modo Peques (4–8 años, íconos y voz), modo Junior (9–12) y modo Teen (13–17, más autonomía). El adulto elige el modo por hijo.

## Rutina diaria y actividades con puntos

La rutina viene precargada con las actividades base; el adulto ajusta horarios, puntos y cuáles aplican a cada hijo. Los puntos son valores sugeridos por defecto.

| Bloque | Actividad | Hora sugerida | Puntos |
| --- | --- | --- | --- |
| Mañana | Levantarse a horario | 07:00 | 5 |
| Mañana | Aseo personal | 07:10 | 5 |
| Mañana | Tender la cama | 07:20 | 5 |
| Mañana | Desayunar | 07:30 | 5 |
| Mañana | Recoger la mesa | 07:45 | 3 |
| Mañana | Lavar la vajilla usada | 07:50 | 5 |
| Mañana | Cepillarse los dientes | 07:55 | 5 |
| Mañana | Útiles del colegio listos | 08:00 | 5 |
| Colegio | Salir e ingresar al colegio (horario de entrada) | 08:15 | 10 |
| Colegio | Salida del colegio (horario de salida) | 13:00 | 5 |
| Tarde | Actividad extracurricular / deporte | 15:00 | 10 |
| Tarde | Llegar a casa | 17:00 | 5 |
| Tarde | Bañarse | 17:30 | 5 |
| Noche | Comer, recoger y lavar | 20:00 | 8 |
| Noche | Estudiar / repasar | 18:00 | 10 |
| Noche | Cepillarse los dientes | 21:00 | 5 |

**Reglas de la rutina**

- Cada actividad tiene ventana horaria; marcarla a tiempo da puntos completos, tarde da la mitad (configurable).
- **Días sin extracurricular:** la actividad se reemplaza por "Repaso de estudios" con el mismo puntaje.
- **Validación:** el adulto elige por tarea si basta con que el hijo la marque, si requiere foto (cama tendida, mesa limpia) o si la valida él.
- **Plantillas por día:** lunes a viernes, fines de semana y feriados/vacaciones con rutinas distintas.
- Cada tarea completada envía una notificación al adulto (agrupables para no saturar).

## Salud, mascotas y pantallas

Un registro diario y simple permite al adulto detectar cambios de comportamiento o de salud sin estar presente.

**Salud diaria**

- **Vasos de agua:** contador con botón "+1 vaso" y meta diaria por edad (el adulto la fija); da puntos al llegar a la meta.
- **Popó y pipí:** check divertido con íconos animados ("¿Hiciste popó hoy?" sí/no). Si pasan 2 días sin popó o pocas veces de pipí, el adulto recibe un aviso suave.
- **Ánimo del día:** el hijo elige un emoticón al final del día (contento, tranquilo, triste, enojado, cansado).
- **Sueño (opcional):** hora en que se acostó y se levantó.

La app no diagnostica: solo muestra tendencias y sugiere consultar al pediatra si una alerta se repite.

**Mascotas**

Cada hogar puede agregar sus mascotas (nombre, especie, foto) y asignar responsables por día.

| Tarea de mascota | Frecuencia sugerida | Puntos |
| --- | --- | --- |
| Darle de comer | 2 veces al día | 3 c/u |
| Paseo | 1–2 veces al día | 5 |
| Limpieza (arenero, jaula, patio) | Diaria o semanal | 5 |
| Jugar con la mascota | Diaria | 3 |

**Uso de pantallas**

- Registro manual de horas de celular, TV, consola y computadora, con límite diario por hijo.
- Fase 2: lectura automática del tiempo de uso del dispositivo (Android Digital Wellbeing / Apple Screen Time), si el sistema lo permite.
- Respetar el límite suma puntos; superarlo no resta, pero se marca en el calendario.
- Las horas de estudio en pantalla se registran aparte y no cuentan contra el límite.

## Puntos, premios, retos y calendario

Los puntos se suman cada día, se canjean el fin de semana y lo que no se gasta sigue acumulando para los grandes premios de fin de mes.

**Ciclo de puntos**

1. **Diario:** cada tarea suma puntos; se muestra una barra de progreso del día.
2. **Semanal:** de viernes a domingo se abre la "Tienda de premios"; el hijo canjea y el adulto aprueba.
3. **Mensual:** los puntos no canjeados pasan a la "Alcancía del mes" para premios grandes (monto en dinero a definir por la familia).
4. **Racha:** días seguidos cumpliendo el 80% o más dan bonus (ej. +10% por semana completa).

| Premio de ejemplo | Costo sugerido | Tipo |
| --- | --- | --- |
| Helado | 50 pts | Semanal |
| Elegir la película del sábado | 60 pts | Semanal |
| 1 hora extra de pantalla | 80 pts | Semanal |
| Salida especial (parque, cine) | 150 pts | Semanal |
| Pase libre: fin de semana sin tareas | 300 pts | Semanal |
| Premio en dinero | A definir | Mensual |

**Retos**

El adulto crea retos con puntos extra y fecha límite: individuales ("leer un libro esta semana") o familiares ("todos tienden la cama 5 días seguidos"). Pueden ser únicos o repetirse.

**Tarjeta calendario de emoticones**

Una vista mensual donde cada día muestra un emoticón según el porcentaje de tareas cumplidas.

| Cumplimiento del día | Emoticón |
| --- | --- |
| 100% | Muy feliz, con estrella |
| 80–99% | Feliz |
| 50–79% | Neutral |
| 25–49% | Triste |
| Menos de 25% | Muy triste |

Al tocar un día se ve el detalle: tareas hechas, agua, pantallas, ánimo elegido por el hijo y notas. El adulto ve un calendario por hijo y uno combinado.

## Comunicación y conexión entre familias

Dentro del hogar todos se comunican libremente; fuera del hogar, un menor solo puede chatear con otro menor si los adultos de ambas familias lo autorizan.

**Dentro del hogar**

- **Notificaciones al adulto:** tarea completada, reto cumplido, premio pedido, alerta de salud, límite de pantalla superado. Con modo resumen (cada 1 h o al final del día).
- **Mensajes grupales del adulto:** anuncios a todos ("hoy cenamos a las 21"), con confirmación de lectura.
- **Salas de chat internas:** sala familiar general y salas creadas por el adulto (ej. "Hermanos", "Padres").
- **Notas y calendario compartido:** recordatorios, listas y eventos visibles para quien el autor elija.

**Conexión con otras familias (amigos del colegio, primos)**

1. Los dos menores se encuentran en persona y uno escanea el QR del otro.
2. Se genera una solicitud que llega a los adultos de ambas familias (P1 o P2 de cada una).
3. Solo si los dos hogares aprueban, se habilita el chat entre esos dos menores.
4. Cualquier adulto puede revocar el contacto en cualquier momento.

**Lo que nunca se comparte:** apellido, teléfono, dirección, colegio, ubicación ni fotos de perfil reales. Solo se ve el apodo y el avatar. Los chats externos admiten texto y stickers predefinidos; no envían archivos ni enlaces en la v1, y el adulto puede revisar el historial.

## Minijuegos e idiomas

Los juegos son un premio en sí mismos: se desbloquean al completar las tareas de la mañana o de la tarde, y suman pocos puntos para no reemplazar a las responsabilidades.

| Juego | Modo | Cómo gana puntos |
| --- | --- | --- |
| Ta-te-ti (X y 0) | 1 vs 1 en el hogar | Ganador +3, empate +1 |
| Sopa de letras | Grupal en tiempo real | El primero en encontrar cada palabra suma +1 |
| Memoria de parejas | Individual o grupal | Por pareja encontrada |
| Trivia familiar | Grupal | Preguntas que carga el adulto o del banco de la app |

- Límite diario de puntos por juegos (ej. 15 pts) para mantener el foco en los hábitos.
- Las sopas de letras pueden usar las palabras del módulo de idiomas.

**Atajos de palabras (modo aprendizaje)**

- Vocabulario básico en español, inglés, portugués y coreano, por temas: colores, números, animales, comida, familia, la casa, el colegio.
- Tarjetas con la palabra, imagen y audio de pronunciación; en coreano se muestra también la romanización.
- "Palabra del día" en la pantalla de inicio y mini-quiz de 5 preguntas que da puntos.
- El adulto elige qué idiomas ve cada hijo.

## Panel del adulto, agenda y personalización

El adulto tiene un menú propio con su familia de un vistazo y, además, su propio día para dar el ejemplo.

**Menú del adulto**

- **Mi familia:** lista de miembros con avatar, puntos de hoy, emoticón del día y última actividad.
- **Ficha de cada hijo:** rutina, calendario, salud, pantallas, mascotas, premios canjeados.
- **Configuración:** tareas, horarios, puntos, premios, retos, límites y autorizaciones de contactos.
- **Reportes:** resumen semanal y mensual por hijo (cumplimiento, agua, pantallas, ánimo).

**El día del adulto**

- Registrar si hizo ejercicio, estudió, vio TV, jugó con sus hijos o compartió con amigos fuera del horario laboral.
- Metas de vínculo familiar: "cena sin celulares", "juego de mesa del domingo", "paseo juntos".
- Agenda: turnos médicos, reuniones del colegio, cumpleaños y fechas importantes, con recordatorios.

**Personalización**

- Por defecto, una paleta sencilla y clara, con modo oscuro.
- Cada miembro elige color de fondo, de las tarjetas y del acento; también tamaño de texto.
- Los temas nuevos (ej. "Espacio", "Océano", "Dinosaurios") se descargan desde la app sin actualizarla: el diseño se maneja con temas configurables desde el servidor.
- **Avatares estilo Funko:** cabeza grande, cuerpo pequeño; se elige tono de piel, peinado, color de pelo, ojos, anteojos, ropa y accesorios. Se pueden ganar accesorios con puntos.

## Seguridad, privacidad y buenas prácticas

Como la app guarda datos de menores y de salud, la privacidad es un requisito de la v1, no una mejora posterior.

- **Consentimiento parental:** solo un adulto verificado puede crear cuentas de menores (en línea con COPPA en EE. UU., GDPR-K en Europa y la Ley 25.326 de Protección de Datos Personales en Argentina).
- **Datos mínimos:** de los hijos solo se guarda apodo, año de nacimiento y avatar; nada de documento, dirección ni ubicación.
- **Cifrado:** todas las comunicaciones por HTTPS/TLS; datos de salud cifrados en la base de datos.
- **Acceso por PIN o biometría** para el modo adulto en un celular compartido.
- **Moderación de chats:** filtro de palabras inapropiadas, botón "avisar a mi papá/mamá" y bloqueo inmediato.
- **Sin publicidad ni compras dentro de la app para los menores.**
- **Derecho al olvido:** el adulto puede exportar o borrar todos los datos de la familia.
- **Accesibilidad:** contraste suficiente, textos escalables, lectura de pantalla y audio en modo Peques.
- **Calidad de código:** pruebas automáticas, revisión de código, análisis de seguridad y versiones con registro de cambios.

## Arquitectura técnica escalable

Una sola app para Android e iOS, con modo adulto y modo hijo, conectada a un backend dividido en módulos que pueden crecer por separado.

```
App del adulto ─┐
App del hijo ───┼──► Backend modular (NestJS) ──► PostgreSQL · Redis · Almacenamiento · FCM/APNs
Otro hogar (QR) ┘     Cuentas y hogares · Rutinas y puntos · Premios y retos
                      Mensajería · Juegos en vivo · Temas y contenido
```

| Capa | Tecnología propuesta | Por qué |
| --- | --- | --- |
| App móvil | Flutter (Dart) | Un solo código para Android e iOS, buen rendimiento y animaciones |
| Funcionamiento sin conexión | Base local (SQLite) con sincronización | Marcar tareas sin internet; se sube al reconectar |
| Backend | NestJS (Node.js, TypeScript) | Estructura modular, tipado, fácil de mantener |
| Base de datos | PostgreSQL | Relaciones claras entre hogares, miembros, tareas y puntos |
| Tiempo real | WebSocket + Redis | Chats, minijuegos y notificaciones al instante |
| Notificaciones | Firebase Cloud Messaging y APNs | Push en Android e iOS |
| Archivos | Almacenamiento de objetos (tipo S3) | Fotos de validación, temas y avatares |
| Infraestructura | Docker, CI/CD, nube con autoescalado | Despliegues seguros y crecimiento por demanda |

Alternativa para salir más rápido: un MVP sobre Supabase o Firebase (auth, base de datos y tiempo real ya resueltos), migrando a backend propio cuando crezca el uso.

## Hoja de ruta y preguntas abiertas

1. **v1 – Núcleo familiar:** hogar y QR, roles P1/P2, rutina con puntos, notificaciones al adulto, tienda de premios semanal, calendario de emoticones, agua/popó/pipí, temas de color básicos y avatar simple.
2. **v1.1 – Cuidado y salud:** mascotas, registro de pantallas manual, retos, alcancía mensual, reportes semanales.
3. **v2 – Comunicación:** mensajes grupales, salas de chat internas, notas y agenda del adulto con recordatorios.
4. **v2.1 – Diversión y aprendizaje:** ta-te-ti, sopa de letras en tiempo real, palabras en 4 idiomas, avatar estilo Funko completo.
5. **v3 – Fuera del hogar:** contactos entre familias con doble autorización, tienda de temas descargables, lectura automática del tiempo de pantalla.

**Preguntas abiertas**

- [ ] ¿Qué monto o tipo de premios en dinero se darán a fin de mes, y cuántos puntos equivalen?
- [ ] ¿Las tareas no cumplidas restan puntos o solo dejan de sumar?
- [ ] ¿Qué rango de edades es el público principal de la v1?
- [ ] ¿La app será gratuita, con suscripción familiar, o un pago único?
- [ ] ¿Se publica primero en Android, en iOS o en ambas a la vez?
- [ ] ¿Validación con foto obligatoria u opcional por defecto?
