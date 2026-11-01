import 'package:flutter/material.dart';

import '../../widgets/common.dart';

/// Qué datos guarda Family App y dónde (para las familias y para Play Store).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const sections = [
    (
      'Qué guardamos',
      'Apodos (no nombres completos), avatares, rutina y tareas hechas, puntos y premios, vasos de agua, '
          'hábitos (agua y baño) y ánimo del día, partidas de juegos, agenda y avisos del hogar.'
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
          'Los chicos no pueden hablar con personas de fuera del hogar.'
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
      'Desvincular un teléfono lo saca del hogar y los adultos pueden quitar miembros. '
          'El borrado completo de un hogar desde la app llega en una próxima versión.'
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
