import 'package:flutter/material.dart';

import '../../data/app_session.dart';
import '../../services/android_settings.dart';
import '../../services/local_notifier.dart';
import '../../widgets/common.dart';

/// Guía para que avisos, recordatorios y alarmas lleguen siempre.
class ReliabilityScreen extends StatefulWidget {
  const ReliabilityScreen({super.key});

  @override
  State<ReliabilityScreen> createState() => _ReliabilityScreenState();
}

class _ReliabilityScreenState extends State<ReliabilityScreen> with WidgetsBindingObserver {
  bool? _notifications;
  bool? _exact;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (!session.flag('tour_battery')) {
      WidgetsBinding.instance.addPostFrameCallback((_) => session.setFlag('tour_battery'));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Al volver de los ajustes de Android, se revisa de nuevo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final n = LocalNotifier.instance;
    final notifications = await n?.notificationsEnabled();
    final exact = await n?.exactAlarmsAllowed();
    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _exact = exact;
    });
  }

  Widget _status(bool? ok) => switch (ok) {
        true => const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
        false => const Icon(Icons.error, color: Color(0xFFE53935)),
        null => const Icon(Icons.help_outline),
      };

  @override
  Widget build(BuildContext context) {
    Widget step(int n, String title, String body, {Widget? status, String? action, VoidCallback? onAction}) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 14, child: Text('$n', style: const TextStyle(fontWeight: FontWeight.w900))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                    if (status != null) status,
                  ],
                ),
                const SizedBox(height: 6),
                Text(body),
                if (action != null) ...[
                  const SizedBox(height: 8),
                  FilledButton.tonal(onPressed: onAction, child: Text(action)),
                ],
              ],
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Que los avisos lleguen', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Hacelo una vez en cada teléfono de la familia. Así los recordatorios de la agenda, las alarmas y los avisos llegan aunque la app esté cerrada.',
              style: mutedText(context).copyWith(fontSize: 15),
            ),
            const SizedBox(height: 16),
            step(
              1,
              'Permitir notificaciones',
              'Sin este permiso no se ve ningún aviso.',
              status: _status(_notifications),
              action: _notifications == true ? null : 'Permitir',
              onAction: () async {
                await LocalNotifier.instance?.askPermission();
                await _refresh();
              },
            ),
            step(
              2,
              'Alarmas y recordatorios',
              'Para que las alarmas de la agenda suenen a la hora justa (Android 12 o más nuevo).',
              status: _status(_exact),
              action: _exact == true ? null : 'Permitir alarmas',
              onAction: () async {
                await LocalNotifier.instance?.askExactAlarms();
                await _refresh();
              },
            ),
            step(
              3,
              'Sacar Family App del ahorro de batería',
              'Es lo más importante. Buscá Family App en la lista y elegí "No optimizar" o "Sin restricciones".\n\n'
                  '• Samsung: Batería → Límites de uso en segundo plano → sacarla de "Apps en suspensión".\n'
                  '• Xiaomi / Redmi: Ajustes de la app → Ahorro de batería → "Sin restricciones", y activar "Inicio automático".\n'
                  '• Motorola y otros: Batería → Optimización → Todas las apps → Family App → "No optimizar".',
              action: 'Abrir ahorro de batería',
              onAction: () async {
                if (!await AndroidSettings.open('battery')) await AndroidSettings.open('app');
              },
            ),
            step(
              4,
              'Voces para Palabras',
              'Para escuchar inglés, portugués y coreano, instalá esas voces en "Texto a voz" (Google).',
              action: 'Abrir voces',
              onAction: () => AndroidSettings.open('tts'),
            ),
            step(
              5,
              'Probar',
              'Agregá en la agenda algo para dentro de 5 minutos con aviso "A la hora", cerrá la app y esperá.',
            ),
          ],
        ),
      ),
    );
  }
}
