# Pasos legales para publicar Family App

> Guía práctica para ordenar el trabajo, **no es asesoramiento legal**. Family App trata datos de menores y datos que pueden considerarse de salud: conviene que un abogado especializado en datos personales revise todo antes de abrirla a otras familias.

## Documentos

| Documento | Estado | Dónde |
| --- | --- | --- |
| Política de privacidad | Borrador | [politica-de-privacidad.md](politica-de-privacidad.md) |
| Términos y condiciones | Borrador | [terminos-y-condiciones.md](terminos-y-condiciones.md) |
| Pantalla "Privacidad y datos" en la app | Hecha (resumen) | Menú del adulto |

## Pendientes

### Argentina (Ley 25.326 de Protección de Datos Personales)

- [ ] **Responsable de los datos:** decidir si es una persona física o una empresa, y completar nombre, domicilio y email en los documentos.
- [ ] **Inscribir la base de datos** en el Registro Nacional de Bases de Datos de la Agencia de Acceso a la Información Pública (AAIP). Es un trámite en línea de dos pasos: primero el responsable y después la base.
- [ ] **Consentimiento expreso** del adulto al crear el hogar: una casilla "Acepto los términos y la política de privacidad", con enlace a ambos. Hace falta sobre todo por los datos de salud y por la transferencia internacional (servidores de Google fuera del país).
- [ ] **Derechos de acceso, rectificación y supresión:** un email de contacto que se responda y, en la app, "Borrar el hogar y todos sus datos".
- [ ] Incluir en la app y en la web las **leyendas obligatorias** de la AAIP (ya están en la política).
- [ ] Seguir el proyecto de **nueva ley de datos personales**: hay proyectos en el Congreso que reemplazarían la 25.326.

### Google Play (política de Familias)

Como la app la usan chicos, Google pide:

- [ ] **Política de privacidad publicada en una dirección web** (puede ser GitHub Pages o un sitio propio) y enlazada en la ficha y en la app.
- [ ] Declarar el **público objetivo** (rangos de edad) y responder el formulario de **seguridad de los datos** con lo mismo que dice la política.
- [ ] **No usar el identificador de publicidad** ni otros identificadores del teléfono (IMEI, MAC, etc.), y no pedir ubicación. Family App hoy no los usa: hay que verificar el manifiesto final antes de cada publicación.
- [ ] Usar solo librerías aptas para apps de chicos. Firebase Analytics o publicidad requieren configuración especial; hoy la app no los incluye.
- [ ] **Borrado de cuenta y datos** desde la app y por una página web. Lo exige Google para apps donde se crean cuentas.
- [ ] Si algún día se suma chat o juego con otras familias: recordatorio de seguridad en línea, controles del adulto y acción del adulto antes de que los chicos intercambien datos.

### Cobro de Plus (cuando se habilite)

- [ ] Cobrar solo con **Google Play Billing**: es obligatorio para contenido digital.
- [ ] Mostrar precio, período y renovación antes de pagar; botón o enlace claro para **dar de baja** (Ley 24.240 y normas de "botón de baja") y **derecho de arrepentimiento** de 10 días.
- [ ] Que la compra la haga un adulto. Google Play ya pide la autorización del adulto en cuentas de chicos, pero conviene además el PIN del modo adulto.
- [ ] Facturación e impuestos según cómo se cobre (persona física o empresa).

### Otros

- [ ] **Marca:** buscar si "Family App" se puede registrar en el INPI, o elegir un nombre propio y registrable. "Family App" es muy genérico.
- [ ] Mantener los disfraces y juegos sin personajes ni marcas de terceros (ya es así).
- [ ] Guardar constancia de las versiones de la política y de las aceptaciones.

## Fuentes

- [Google Play: requisitos para apps de Familias](https://support.google.com/googleplay/android-developer/answer/9893335)
- [Ley 25.326 de Protección de Datos Personales](https://www.unc.edu.ar/sites/default/files/Ley-de-Proteccion-de-Datos-Personales-Nro-25326.pdf)
- [Guía de protección de datos de Argentina (Multilaw)](https://www.multilaw.com/AMERICAS26/Multilaw/Data_Protection_Laws_Guide/DataProtection_Guide_Argentina.aspx)
