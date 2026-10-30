# Family App · app Flutter

App familiar de hábitos y puntos. Funciona sin backend: los datos se guardan en el propio teléfono.

- Identificador: `com.javimathesan.familyapp`
- Nombre visible: **Family App**

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

Cada vez que se sube un cambio, GitHub compila la app. En la pestaña **Actions** del repositorio, abrí la última ejecución y descargá **family-app-debug-apk** (se guarda 7 días). Ese APK se puede instalar directo en un Android.

## Cómo probarla

Al abrir aparece "¿Quién usa la app?". En la app real cada persona usa su propio celular; acá podés entrar como cualquiera para probar:

- **Papá** (adulto P1): panel Mi familia, aprobaciones, Invitar con QR y, en el menú de tres puntos, "Restablecer datos de ejemplo".
- **Tomi, Luli o Mati** (hijos): Hoy, Rutina, Calendario y Premios. El ícono de paleta en Hoy cambia el color.
- **Me invitaron: unirme a un hogar**: tocá "Abrir la cámara" y escaneá el QR que muestra la pantalla Invitar en otro teléfono, o escribí el código `FAM-XXXX`. Después se crea el avatar.

Todo lo que hagas queda guardado aunque cierres la app. Al abrirla otro día, el día anterior pasa al calendario y la rutina empieza de cero.

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
│   └── family_storage.dart Guardado en el teléfono (shared_preferences)
├── widgets/                Avatar Funko, caritas, selector de color, tarjetas
└── features/
    ├── child/              Hoy, Rutina, Calendario, Premios
    ├── adult/              Mi familia
    └── onboarding/         Perfil, Invitar QR, Escanear QR, Unirse, Avatar
test/                       Pruebas de reglas, estado, guardado y navegación
```

## Pendiente para próximas iteraciones

- Backend y cuentas reales, para que cada miembro use su propio teléfono y se sincronicen.
- Notificaciones push al adulto.
- Que el adulto pueda editar tareas, horarios, puntos y premios.
- Ícono propio de la app y pantalla de inicio.
- Modo oscuro elegible y más personalización (fondo, tamaño de texto, temas).
