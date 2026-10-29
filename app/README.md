# family_app · app Flutter

Primera versión navegable de la app. Usa datos de ejemplo en memoria: todavía no hay backend ni base de datos.

## Cómo correrla en tu PC

Requisitos: [Flutter](https://docs.flutter.dev/get-started/install) estable (3.22 o superior) y un emulador Android, un iPhone/simulador o Chrome.

```bash
cd app
flutter create . --org com.familyapp --platforms android,ios,web   # solo la primera vez: genera las carpetas de cada plataforma
flutter pub get
flutter run
```

Para correr las pruebas:

```bash
flutter analyze
flutter test
```

## Cómo probarla

Al abrir aparece "¿Quién usa la app?". En la app real cada persona usa su propio celular; acá podés entrar como cualquiera para probar:

- **Papá** (adulto P1): panel Mi familia, aprobaciones e Invitar con QR.
- **Tomi, Luli o Mati** (hijos): Hoy, Rutina, Calendario y Premios.
- **Me invitaron: unirme a un hogar**: flujo de alta con código (`FAM-` + 4 letras o números, o "Simular escaneo") y luego el editor de avatar.

La tienda de premios solo deja canjear de viernes a domingo, como dice el borrador.

## Estructura

```
lib/
├── main.dart               Punto de entrada
├── app.dart                MaterialApp, rutas y tema
├── theme/                  Colores y tema claro/oscuro
├── models/                 Modelos del dominio
├── domain/                 Reglas puras (puntos, caritas, salud)
├── data/                   FamilyStore: estado en memoria + datos demo
├── widgets/                Avatar Funko, caritas y tarjetas comunes
└── features/
    ├── child/              Hoy, Rutina, Calendario, Premios
    ├── adult/              Mi familia
    └── onboarding/         Perfil, Invitar QR, Unirse, Avatar
test/                       Pruebas de reglas, estado y navegación
```

## Pendiente para próximas iteraciones

- Escaneo real del QR con la cámara (`mobile_scanner`).
- Persistencia local (SQLite) y backend con sincronización.
- Notificaciones push al adulto.
- Fuente redondeada propia (Nunito) incluida en el proyecto.
- Ajustes de colores por miembro y modo oscuro elegible.
