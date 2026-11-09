import 'package:flutter/material.dart';

import '../../widgets/common.dart';

/// Qué datos guarda Family App y dónde (para las familias y para Play Store).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const sections = [
    (
      'Qué guardamos',
      'Apodos (no nombres completos), avatares, rutina y tareas hechas, puntos, premios y pedidos, '
          'hábitos opcionales (agua y baño), partidas de juegos, agenda, avisos del hogar y amistades con otras familias.'
    ),
    (
      'Qué NO pedimos',
      'Ni email, ni teléfono, ni dirección, ni colegio, ni ubicación, ni fotos. Cada teléfono entra con una '
          'sesión anónima.'
    ),
    (
      'Dónde se guarda',
      'En la demostración, solo en este teléfono. En un hogar compartido, en Google Firebase (Cloud Firestore), '
          'y solo lo pueden ver los teléfonos aprobados de ese hogar.'
    ),
    (
      'Quién decide',
      'Los adultos administradores aprueban cada teléfono, pueden quitar miembros y desvincular teléfonos. '
          'Para sumar un teléfono se usa un QR de un solo uso que vence en 15 minutos. '
          'El modo adulto se puede proteger con un PIN.'
    ),
    (
      'Familias amigas',
      'Los chicos solo juegan con familias amigas aprobadas por un adulto de cada hogar, con un código de amistad '
          'que vence en 24 horas. Cada adulto elige qué miembros pueden jugar. Se comparte solo el nombre del hogar, '
          'el apodo y el avatar de esos miembros, y las jugadas de las partidas. No hay chat libre: solo reacciones '
          'predefinidas. Rutinas, hábitos, agenda y puntos nunca se comparten.'
    ),
    (
      'Hábitos de los chicos',
      'El agua y el baño son opcionales y arrancan apagados: un adulto administrador los activa para cada hijo en '
          'Ajustes → Hogar, y al hacerlo da su consentimiento. Solo los ven el chico y los adultos de su hogar, y nunca '
          'se comparten con familias amigas ni con terceros. Son orientativos: Family App no es un dispositivo médico.'
    ),
    (
      'Informes de fallos',
      'Si la app se cierra por un error, se envía un informe técnico a Firebase Crashlytics (Google): qué pantalla '
          'falló, modelo de teléfono, versión de Android y de la app. No incluye apodos, rutinas ni hábitos. '
          'La app también se identifica ante Firebase con App Check (Play Integrity) para confirmar que es la original.'
    ),
    (
      'Avisos y alarmas',
      'Los avisos de la agenda los programa el propio teléfono. No se usan para publicidad.'
    ),
    (
      'Publicidad',
      'Family App no muestra publicidad ni vende datos.'
    ),
    (
      'Borrar los datos',
      'Un adulto administrador puede borrar el hogar y todos sus datos en Ajustes → Sesión → "Borrar el hogar y '
          'todos sus datos". El borrado es inmediato y no se puede deshacer. También se puede pedir por email a '
          'familyapps.oficial@gmail.com, y se resuelve dentro de los 30 días. Desvincular un teléfono lo saca del hogar.'
    ),
    (
      'Contacto',
      'Consultas, pedidos de acceso, corrección o borrado: familyapps.oficial@gmail.com'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad y datos', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final (title, body) in sections) ...[
              Text(title, style: sectionTitle(context)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(fontSize: 15, height: 1.35)),
              const SizedBox(height: 16),
            ],
            Text('Family App · versión de prueba', style: mutedText(context)),
          ],
        ),
      ),
    );
  }
}
