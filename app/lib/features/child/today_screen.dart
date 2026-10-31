import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/family_store.dart';
import '../../learning/vocabulary.dart';
import '../../models/models.dart';
import '../learning/words_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/accent_picker.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';
import '../../widgets/celebration.dart';
import 'room_screen.dart';

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
    // Lo que los adultos aprobaron (o dejaron para otro momento) hoy.
    final forMe = [
      for (final n in store.notices)
        if (n.memberId == me.id && n.kind == NoticeKind.approval && DateUtils.isSameDay(n.time, store.now)) n,
    ].take(3).toList();
    final agendaToday = store.eventsOn(store.now, me.id);
    final challenge = store.challenge;
    final langs = homeLanguages(store);
    final wotd = wordOfTheDay(store.now, langs);

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
              tooltip: 'Personalizar',
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(Routes.room),
                icon: const Text('🏠'),
                label: const Text('Mi cuarto'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(Routes.medals),
                icon: const Text('🏅'),
                label: const Text('Medallas'),
              ),
            ),
          ],
        ),
        for (final id in todayOrder(me.look))
          if (!me.look.hidden.contains(id)) ...switch (id) {
            'paravos' => [
        if (forMe.isNotEmpty) ...[
          const SizedBox(height: 16),
          InfoCard(
            color: const Color(0xFFE8F8EE),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Para vos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1B7F3B))),
                const SizedBox(height: 4),
                for (final n in forMe)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(n.text.contains('aprobó') ? Icons.celebration : Icons.schedule, size: 20, color: const Color(0xFF1B7F3B)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(n.text, style: const TextStyle(fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
            'mascota' => [const SizedBox(height: 16), _PetCard(memberId: me.id)],
            'reto' => [
        if (challenge != null) ...[
          const SizedBox(height: 16),
          InfoCard(
            color: const Color(0xFFF3E5F5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(challenge.type.icon, color: const Color(0xFF7B1FA2)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('RETO DE LA SEMANA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF7B1FA2))),
                    ),
                    Text('+${challenge.bonus} pts', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(challenge.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (store.challengeProgress(me.id) / challenge.target).clamp(0, 1).toDouble(),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                if (store.challengeClaimed(me.id))
                  const Text('¡Reto cumplido! 🏅 El lunes empieza otro.', style: TextStyle(fontWeight: FontWeight.w700))
                else if (store.canClaimChallenge(me.id))
                  FilledButton.icon(
                    onPressed: () {
                      if (store.claimChallenge(me.id)) celebrate(context, text: '¡Reto cumplido! 🏅');
                    },
                    icon: const Icon(Icons.emoji_events),
                    label: Text('¡Cobrar +${challenge.bonus} pts!'),
                  )
                else
                  Text('Llevás ${store.challengeProgress(me.id)} de ${challenge.target}', style: mutedText(context)),
              ],
            ),
          ),
        ],
      ],
            'agenda' => [
        const SizedBox(height: 16),
        InfoCard(
          color: const Color(0xFFFFF8E1),
          child: InkWell(
            onTap: () => Navigator.of(context).pushNamed(Routes.agenda),
            child: Row(
              children: [
                const Icon(Icons.event_note, size: 32, color: Color(0xFFB26A00)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HOY EN LA AGENDA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFB26A00))),
                      if (agendaToday.isEmpty) const Text('Nada especial. ¡Día tranquilo!'),
                      for (final e in agendaToday)
                        Text('${hhmm(TimeOfDay.fromDateTime(e.at))} · ${e.title}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ],
            'palabra' => [
        const SizedBox(height: 16),
        InfoCard(
          color: const Color(0xFFE3F2FD),
          child: Row(
            children: [
              Text(wotd.word.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PALABRA DEL DÍA ${wotd.lang.flag}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1565C0))),
                    Text('${wotd.word.es} = ${wotd.word.inLang(wotd.lang)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    if (wotd.word.hint(wotd.lang) != null) Text('Se lee: ${wotd.word.hint(wotd.lang)}', style: mutedText(context)),
                  ],
                ),
              ),
              SpeakButton(text: wotd.word.inLang(wotd.lang), lang: wotd.lang, size: 24),
            ],
          ),
        ),
      ],
            'cuerpo' => [
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
            _ => const <Widget>[],
          },
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => showTodayOrder(context),
            icon: const Icon(Icons.tune),
            label: const Text('Ordenar mi pantalla'),
          ),
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

/// Tarjetas de la pantalla Hoy que se pueden ordenar u ocultar.
const todayCards = <String, String>{
  'paravos': 'Para vos (lo que te aprobaron)',
  'mascota': 'Mi mascota',
  'reto': 'Reto de la semana',
  'agenda': 'Hoy en la agenda',
  'palabra': 'Palabra del día',
  'cuerpo': 'Mi cuerpo hoy (agua, popó y pipí)',
};

/// Orden de las tarjetas: el elegido y, al final, las que falten.
List<String> todayOrder(MemberLook look) => [
      for (final id in look.home) if (todayCards.containsKey(id)) id,
      for (final id in todayCards.keys) if (!look.home.contains(id)) id,
    ];

/// Hoja para ordenar y ocultar las tarjetas de Hoy.
Future<void> showTodayOrder(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => ListenableBuilder(
      listenable: FamilyScope.of(context),
      builder: (ctx, _) {
        final store = FamilyScope.of(context);
        final me = store.currentMember;
        if (me == null) return const SizedBox.shrink();
        final order = todayOrder(me.look);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text('Ordenar mi pantalla', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Arrastrá para cambiar el orden y apagá lo que no quieras ver.'),
              ),
              Flexible(
                child: ReorderableListView(
                  shrinkWrap: true,
                  onReorder: (from, to) {
                    final next = [...order];
                    final item = next.removeAt(from);
                    next.insert(to > from ? to - 1 : to, item);
                    store.setLook(me.id, me.look.copyWith(home: next));
                  },
                  children: [
                    for (final id in order)
                      SwitchListTile(
                        key: ValueKey(id),
                        value: !me.look.hidden.contains(id),
                        title: Text(todayCards[id]!, style: const TextStyle(fontWeight: FontWeight.w700)),
                        secondary: const Icon(Icons.drag_handle),
                        onChanged: (on) => store.setLook(
                          me.id,
                          me.look.copyWith(hidden: on ? [...me.look.hidden]..remove(id) : [...me.look.hidden, id]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Tarjeta de la mascota: cómo está hoy y acceso al cuarto.
class _PetCard extends StatelessWidget {
  const _PetCard({required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    void open() => Navigator.of(context).pushNamed(Routes.room);
    if (!store.hasPet(memberId)) {
      return InfoCard(
        color: const Color(0xFFFFF0E6),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Text('🐾', style: TextStyle(fontSize: 34)),
          title: const Text('Adoptá una mascota', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('Vive en tu cuarto y crece cuando cumplís tu rutina.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: open,
        ),
      );
    }
    return InkWell(
      onTap: open,
      borderRadius: BorderRadius.circular(20),
      child: RoomView(memberId: memberId),
    );
  }
}
