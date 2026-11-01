import 'package:flutter/material.dart';

import '../../widgets/common.dart';

/// Versión de los términos y la política que acepta el adulto.
const legalVersion = '2026-11';

/// Resumen de los términos y condiciones (el texto completo está en la web).
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const sections = [
    ('Quién puede usarla', 'Un adulto mayor de 18 años crea el hogar y aprueba a cada miembro. Los chicos la usan con su supervisión.'),
    ('Puntos y premios', 'Los puntos y las monedas de los juegos no tienen valor en dinero. Los premios los define y entrega cada familia.'),
    ('Salud', 'El registro de agua y baño es orientativo. Family App no es un dispositivo médico ni reemplaza a un profesional.'),
    ('Avisos y alarmas', 'Dependen del teléfono (permisos, batería, No molestar). No uses la app como único recordatorio para algo crítico.'),
    ('Familias amigas', 'Solo con doble aprobación de adultos. Se comparten apodo y avatar; no hay chat libre.'),
    ('Family App Plus', 'Cuando se pueda contratar, será por Google Play, con baja en cualquier momento y derecho de arrepentimiento de 10 días.'),
    ('Tus datos', 'Podés borrar el hogar y todos sus datos desde Ajustes. Más detalles en "Privacidad y datos".'),
    ('Ley aplicable', 'Rigen las leyes de la República Argentina y los derechos de la Ley 24.240 de Defensa del Consumidor.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Términos y condiciones', style: TextStyle(fontWeight: FontWeight.w800))),
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
            Text('Versión $legalVersion · Texto completo: github.com/javimathesan/family_app (docs/legal)', style: mutedText(context)),
          ],
        ),
      ),
    );
  }
}

/// Casilla de aceptación con enlaces a los términos y la privacidad.
class AcceptTermsTile extends StatelessWidget {
  const AcceptTermsTile({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final link = TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, decoration: TextDecoration.underline);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(key: const ValueKey('acepto'), value: value, onChanged: (v) => onChanged(v ?? false)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              children: [
                const Text('Soy mayor de 18 años y acepto los '),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TermsScreen())),
                  child: Text('términos', style: link),
                ),
                const Text(' y la '),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/privacidad'),
                  child: Text('política de privacidad', style: link),
                ),
                const Text(', incluido el registro de hábitos de los chicos y que los datos se guarden en servidores de Google.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
