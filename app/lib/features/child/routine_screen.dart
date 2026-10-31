import 'package:flutter/material.dart';

import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../services/speech.dart';
import '../../widgets/celebration.dart';
import '../../widgets/common.dart';

/// Rutina del día agrupada por bloques (mañana, colegio, tarde, noche).
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  DayBlock _block = DayBlock.morning;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final me = store.currentMember!;
    final accent = Theme.of(context).colorScheme.primary;
    final tasks = store.tasksFor(_block, memberId: me.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${longDate(store.now)} · día de colegio', style: mutedText(context)),
                  Text('Mi rutina', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${store.pointsToday(me.id)} pts',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: accent)),
                Text('${store.doneToday(me.id)} de ${store.templatesFor(me.id).length} hechas',
                    style: mutedText(context).copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SegmentedButton<DayBlock>(
          segments: [
            for (final b in DayBlock.values) ButtonSegment(value: b, label: Text(b.label)),
          ],
          selected: {_block},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _block = s.first),
        ),
        const SizedBox(height: 16),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No tenés tareas en este momento del día.', style: mutedText(context).copyWith(fontSize: 15)),
          ),
        for (final task in tasks) ...[
          _TaskTile(task: task, memberId: me.id),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        const InfoCard(
          color: AppColors.warmBg,
          child: Row(
            children: [
              Icon(Icons.schedule, color: AppColors.warmInk),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Marcala dentro de su horario para ganar los puntos completos. Fuera de horario suma la mitad.',
                  style: TextStyle(color: Color(0xFF7C2D12), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.memberId});

  final TaskTemplate task;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final completion = store.completionOf(memberId, task.id);
    final done = completion != null;
    final pending = completion?.pendingApproval ?? false;
    final subtitle = pending ? 'Esperando que un adulto lo valide' : '${hhmm(task.time)} · ${task.validation.label} · +${task.points} pts';
    // Los más chicos ven todo más grande y pueden escuchar la tarea.
    final peques = store.memberById(memberId)?.mode == AgeMode.peques;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: done ? accent : AppColors.line, width: 2),
      ),
      child: CheckboxListTile(
        value: done,
        onChanged: (_) {
          final points = store.toggleTask(memberId, task.id);
          if (points > 0 && task.validation == Validation.self) {
            celebrate(context, text: '¡Bien! +$points pts');
          } else if (points > 0) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('Listo. Se suman cuando un adulto lo valide.'), duration: Duration(seconds: 2)));
          }
        },
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Text(task.icon, style: TextStyle(fontSize: peques ? 30 : 22)),
            const SizedBox(width: 8),
            Expanded(child: Text(task.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: peques ? 19 : null))),
          ],
        ),
        subtitle: Text(subtitle, style: mutedText(context)),
        secondary: peques
            ? IconButton(
                tooltip: 'Escuchar',
                onPressed: () => Speech.instance.say(task.name, 'es-ES'),
                icon: const Icon(Icons.volume_up),
              )
            : Text(
                '+${task.points}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: done ? accent : AppColors.muted),
              ),
      ),
    );
  }
}
