# Hoja de ruta de Family App

Misión: que los más chicos tomen conciencia de sus tareas y responsabilidades, que los padres sepan con quién juegan (familias amigas) y que los premios y juegos los mantengan activos.

## Etapa 1 · Antes de publicar
- [ ] Notificaciones push reales (Firebase Cloud Messaging): avisos al adulto y al chico con la app cerrada.
- [ ] Simplificar el inicio del adulto: lo esencial a la vista, lo secundario en Ajustes.
- [ ] Validar los puntos en el servidor (Cloud Functions) para evitar trampas.
- [ ] Probar en un celular de gama baja.
- [ ] Pasar a Flutter 3.50: cambiar `package:flutter/material.dart` por `package:material_ui` en toda la app y quitar la versión fija (3.47.9) del armado en GitHub.
- [ ] Activar la exigencia de App Check en la consola de Firebase cuando la app esté en Play (frena a quien intente leer la base sin la app original).
- [ ] Limpiar el campo `mood` (ánimo) del modelo: la app ya no lo registra ni lo muestra.
- [ ] Prueba cerrada en Play (12 personas, 14 días) y ajustes con lo que digan.

## Etapa 2 · Primeros meses publicados
- [ ] Chicos con dos hogares (padres separados).
- [ ] Meta familiar cooperativa (los hermanos suman para un premio común).
- [ ] Alcancía: ahorrar puntos para un premio grande.
- [ ] Panel de amistades para padres (con quién juega, cuánto, pausar una amistad).
- [ ] Widget en la pantalla del teléfono con las tareas de hoy.
- [ ] Lanzamientos escalonados en Play y funciones con Remote Config.

## Etapa 3 · Para escalar
- [ ] Versión para iPhone.
- [ ] App en portugués e inglés.
- [ ] Cobro de Family App Plus con prueba gratis.
- [ ] Panel web para padres.
- [ ] Cumplimiento legal por país (COPPA, LGPD, política de familias de Play).

## Herramientas del hogar (la "guinda")
Que la app conecte a toda la casa, no solo a los chicos: herramientas útiles en un solo lugar, **siempre opcionales** (cada adulto activa las que quiere en Mi día).
- [x] Mi día personal con metas que se cuentan.
- [x] Lista de compras con fecha probable y precios.
- [ ] Ideas: gastos del hogar por mes, menú semanal, vencimientos (servicios, impuestos), turnos médicos de la familia, cumpleaños.

## Control de pantallas (opcional, más adelante)
Ideas anotadas, **no obligatorias por ahora**. La app no bloquea otras apps (TikTok, YouTube, Instagram): eso ya lo hace Google Family Link, gratis y sin que el chico lo pueda saltear.
- [ ] Guía dentro de la app para que el jefe de familia configure Family Link paso a paso (no pide permisos nuevos).
- [ ] Premios de tiempo de pantalla ("30 minutos de YouTube") que se canjean con puntos y el adulto habilita en Family Link.
- [ ] "Modo concentración" opcional que bloquee apps hasta terminar la rutina. Evaluar recién con la app publicada: necesita permisos delicados (acceso al uso, accesibilidad), revisión especial de Google Play y cambios en la política de privacidad.

## Juegos nuevos
Solo si suman a la misión: educativos (tablas, sopa de letras, memoria, rompecabezas) o para jugar entre familias (damas, batalla naval, dibujos). Siempre como premio, respetando "primero la rutina".

## Proyectos aparte
- Página web del producto (presentación, política de privacidad, términos y borrado de datos), en su propio repositorio.

## Proyectos futuros: la familia de apps
Una marca, tres apps separadas, **una sola cuenta y el mismo hogar** (mismo proyecto de Firebase) y el mismo diseño.

1. **Family App** (esta): publicarla primero.
2. **Family Mascotas**: controles, vacunas, desparasitación, peluquería, paseos y agenda de cada mascota. Para familias sin hijos o con hijos ya grandes. Reutiliza la agenda y las alarmas.
3. **Family Bebé**: embarazo (citas, fecha de parto, medicación, consultas, tamaño), después nacimiento, peso, vacunas y crecimiento. Datos de salud: consentimiento expreso, sin consejos médicos y política propia.

- [ ] **Graduación**: el bebé pasa a Family App con su nombre, fecha de nacimiento y avatar, sin volver a cargar nada.
- [ ] **Monorepo** al empezar la segunda app: `paquetes/base` (cuenta, hogar, diseño, avatares, agenda, recordatorios) y `apps/family`, `apps/mascotas`, `apps/bebe`.
- [ ] Sección chica "Mascotas de la casa" en Family App, vinculada a Family Mascotas.
