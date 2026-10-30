# Family App · app Flutter

App familiar de hábitos y puntos. Los teléfonos del hogar se sincronizan con Firebase (Cloud Firestore); también hay un modo de demostración que funciona sin conexión.

- Identificador: `com.javimathesan.familyapp`
- Nombre visible: **Family App**

## Configurar Firebase (una sola vez)

El archivo de configuración no está en el repositorio porque es público.

1. Copiá `google-services.json` (de la consola de Firebase, proyecto `family-app-f180f`) en `app/android/app/`.
2. En la consola: **Authentication → Método de acceso → Anónimo**: habilitado, **sin** limpieza automática.
3. **Firestore Database → Crear base de datos**: ubicación `southamerica-east1`, modo producción.
4. **Firestore → Reglas**: pegá el contenido de [`../firebase/firestore.rules`](../firebase/firestore.rules) y publicá. Repetilo cada vez que cambie ese archivo.

Sin `google-services.json`, la app compila igual y solo ofrece la demostración.

## Cómo correrla en tu PC

Requisitos: [Flutter](https://docs.flutter.dev/get-started/install) estable y un celular Android con depuración USB (o un emulador).

Cada vez que retomes el proyecto:

```bash
git pull
cd app
flutter pub get
flutter run
```

Si `flutter run` falla después de un cambio grande (por ejemplo, el cambio de identificador), limpiá y volvé a intentar:

```bash
flutter clean
flutter pub get
flutter run
```

Para correr las verificaciones:

```bash
flutter analyze
flutter test
```

### APK de prueba sin compilar

Cada vez que se sube un cambio, GitHub compila la app. En la pestaña **Actions** del repositorio, abrí la última ejecución y descargá **family-app-debug-apk** (se guarda 7 días). Ese APK se compila sin la configuración real de Firebase: sirve para probar la demostración, no para conectar teléfonos.

## Cómo probarla

**Con dos teléfonos (hogar real):**

1. Teléfono del adulto: **Crear mi hogar** → nombre del hogar y cómo te llaman → entrás a **Mi familia**.
2. **Invitar con QR** → elegí Hijo/a y el modo por edad.
3. Otro teléfono con Family App instalada: **Me invitaron** → **Abrir la cámara** y escaneá el QR, o escribí el código `FAM-XXXX`. También se puede escanear con la cámara del teléfono: abre Family App.
4. Escribí el apodo → **Unirme al hogar**. Queda esperando.
5. Teléfono del adulto: en **Para aprobar** aparece el alta → **Aprobar**.
6. El otro teléfono pasa a crear su avatar. Desde ahí, lo que marca se ve en el panel del adulto al instante.

**Hijo sin celular:** en Mi familia → **Hijo sin celular**. Su perfil aparece en "¿Quién usa la app?" del teléfono del adulto.

**Demostración:** **Probar con datos de ejemplo** carga una familia inventada que queda solo en ese teléfono. "Restablecer datos de ejemplo" y "Salir de la demostración" están en el menú de tres puntos del panel del adulto.

La tienda de premios solo deja canjear de viernes a domingo.

## Estructura

```
lib/
├── main.dart               Punto de entrada: carga los datos guardados
├── app.dart                MaterialApp, rutas y tema
├── theme/                  Colores y tema claro/oscuro
├── models/                 Modelos del dominio
├── domain/                 Reglas puras (puntos, caritas, salud)
├── data/
│   ├── family_store.dart   Estado del hogar + datos de ejemplo + formato de guardado
│   ├── family_sync.dart    Interfaz de cambios hacia la nube
│   ├── family_cloud.dart   Hogar compartido en Cloud Firestore
│   ├── app_session.dart    Modo del teléfono (demo / nube), hogar y perfil propio
│   └── family_storage.dart Guardado de la demostración (shared_preferences)
├── widgets/                Avatar Funko, caritas, selector de color, tarjetas
└── features/
    ├── child/              Hoy, Rutina, Calendario, Premios
    ├── adult/              Mi familia
    └── onboarding/         Primeros pasos, Crear hogar, Invitar QR, Escanear, Unirse, Avatar
test/                       Pruebas de reglas, estado, guardado y navegación
```

## Pendiente para próximas iteraciones

- Notificaciones push al adulto (Firebase Cloud Messaging).
- PIN para el modo adulto en un teléfono compartido.
- Recuperar el acceso si se reinstala la app (hoy hay que volver a invitar al teléfono).
- Que el adulto pueda editar tareas, horarios, puntos y premios.
- Ícono propio de la app y pantalla de inicio.
- Modo oscuro elegible y más personalización (fondo, tamaño de texto, temas).
