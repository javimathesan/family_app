import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/family_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/accent_picker.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';

/// Pantalla "Hoy": puntos del día, próxima tarea y registro de salud.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.onOpenRoutine});

  final VoidCallback onOpenRoutine;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final me = store.currentMember!;
    final accent = Theme.of(context).colorScheme.primary;
    final done = store.doneToday(me.id);
    final total = store.templatesFor(me.id).length;
    final next = store.nextTask(me.id);
    final health = store.healthOf(me.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            Tooltip(
              message: 'Cambiar mi avatar',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pushNamed(Routes.avatar),
                child: AvatarView(config: me.avatar, background: const Color(0xFFDCE7FF)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(longDate(store.now), style: mutedText(context)),
                  Text('Hola, ${me.nickname}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Mi color',
              onPressed: () => showAccentPicker(context),
              icon: const Icon(Icons.palette_outlined),
            ),
            IconButton.filledTonal(
              tooltip: 'Cambiar de usuario',
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              icon: const Icon(Icons.switch_account_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(24)),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Puntos de hoy'),
                Text('${store.pointsToday(me.id)} pts',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    minHeight: 12,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    semanticsLabel: 'Progreso del día',
                  ),
                ),
                const SizedBox(height: 10),
                Text('$done de $total tareas hechas'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (next != null)
          InfoCard(
            child: Row(
              children: [
                const IconBadge(icon: Icons.schedule, background: AppColors.warmBg, color: AppColors.warmInk),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SIGUE · ${hhmm(next.time)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warmInk)),
                      Text(next.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text('+${next.points} pts al marcarla a tiempo', style: mutedText(context)),
                    ],
                  ),
                ),
                OutlinedButton(onPressed: onOpenRoutine, child: const Text('Ver')),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Text('Mi cuerpo hoy', style: sectionTitle(context)),
        const SizedBox(height: 10),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Vasos de agua', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('Meta: ${FamilyStore.waterGoal} vasos', style: mutedText(context)),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: health.glasses >= FamilyStore.waterGoal ? null : () => store.addGlass(me.id),
                    child: const Text('+1 vaso'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < FamilyStore.waterGoal; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Icon(
                          i < health.glasses ? Icons.local_drink : Icons.local_drink_outlined,
                          color: i < health.glasses ? const Color(0xFF3B82F6) : const Color(0xFF9DB7F0),
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                health.glasses >= FamilyStore.waterGoal ? '¡Meta cumplida! +5 pts' : '${health.glasses} de ${FamilyStore.waterGoal} vasos',
                style: mutedText(context).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HealthTile(
                icon: Icons.cloud_outlined,
                iconColor: const Color(0xFF7C4A1E),
                title: '¿Hiciste popó?',
                value: health.poop ? 'Sí, ¡bien!' : 'Todavía no',
                selected: health.poop,
                onTap: () => store.togglePoop(me.id),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HealthTile(
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFFB7791F),
                title: 'Pipí',
                value: '${health.pee} veces · tocá para sumar',
                selected: false,
                onTap: () => store.addPee(me.id),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HealthTile extends StatelessWidget {
  const _HealthTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      toggled: selected,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? accent : AppColors.line, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 30),
                const SizedBox(height: 6),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text(value, style: mutedText(context).copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
