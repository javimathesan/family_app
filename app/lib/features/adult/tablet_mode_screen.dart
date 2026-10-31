import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/celebration.dart';
import '../../widgets/common.dart';
import '../../widgets/crest_badge.dart';
import '../../widgets/pin_dialog.dart';

/// Modo tablet familiar: todos los chicos en una pantalla, para la tablet de
/// la casa. Cada uno toca su avatar y marca sus tareas. Para salir hace falta
/// el PIN del modo adulto (si hay uno).
class TabletModeScreen extends StatelessWidget {
  const TabletModeScreen({super.key});

  Future<void> _exit(BuildContext context) async {
    if (!await confirmAdultPin(context)) return;
    if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(Routes.welcome, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final kids = [for (final c in store.children) if (!store.isPendingMember(c.id)) c];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit(context);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              if (store.crest != null) ...[CrestBadge(crest: store.crest!, size: 36), const SizedBox(width: 10)],
              Flexible(child: Text(store.homeName, style: const TextStyle(fontWeight: FontWeight.w900))),
            ],
          ),
          actions: [
            TextButton.icon(onPressed: () => _exit(context), icon: const Icon(Icons.lock_outline), label: const Text('Salir')),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, box) {
            final columns = box.maxWidth > 760 ? 3 : (box.maxWidth > 480 ? 2 : 1);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${longDate(store.now)} · ¿Quién marca sus tareas?', style: mutedText(context).copyWith(fontSize: 16)),
                const SizedBox(height: 12),
                if (kids.isEmpty) Text('Todavía no hay chicos en el hogar.', style: mutedText(context)),
                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  children: [for (final k in kids) _KidCard(member: k)],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _KidCard extends StatelessWidget {
  const _KidCard({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final done = store.doneToday(member.id);
    final total = store.templatesFor(member.id).length;
    final next = store.nextTask(member.id);
    return Material(
      color: member.accent.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: ValueKey('tablet_${member.id}'),
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openTasks(context, member),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AvatarView(config: member.avatar, size: 84, background: Colors.white),
              const SizedBox(height: 6),
              Text(member.nickname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text('${store.pointsToday(member.id)} pts hoy', style: TextStyle(color: member.accent, fontWeight: FontWeight.w800)),
              const Spacer(),
              LinearProgressIndicator(
                value: total == 0 ? 0 : done / total,
                minHeight: 10,
                color: member.accent,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 4),
              Text(next == null ? '¡Todo listo por hoy! 🎉' : 'Sigue: ${next.icon} ${next.name}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  void _openTasks(BuildContext context, Member member) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .85,
        builder: (ctx, controller) => _KidTasks(member: member, controller: controller),
      ),
    );
  }
}

class _KidTasks extends StatelessWidget {
  const _KidTasks({required this.member, required this.controller});

  final Member member;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final health = store.healthOf(member.id);
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(
          children: [
            AvatarView(config: member.avatar, size: 56, background: member.accent.withValues(alpha: .15)),
            const SizedBox(width: 12),
            Expanded(child: Text('Tareas de ${member.nickname}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
            FilledButton.tonalIcon(
              onPressed: health.glasses >= FamilyStore.waterGoal ? null : () => store.addGlass(member.id),
              icon: const Icon(Icons.local_drink),
              label: Text('${health.glasses}/${FamilyStore.waterGoal}'),
            ),
          ],
        ),
        for (final block in DayBlock.values)
          if (store.tasksFor(block, memberId: member.id).isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
              child: Text(block.label, style: sectionTitle(context)),
            ),
            for (final t in store.tasksFor(block, memberId: member.id))
              Builder(builder: (context) {
                final c = store.completionOf(member.id, t.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: c != null,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('${t.icon}  ${t.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    subtitle: Text(c?.pendingApproval ?? false ? 'Esperando a un adulto' : '${hhmm(t.time)} · +${t.points} pts'),
                    onChanged: (_) {
                      final points = store.toggleTask(member.id, t.id);
                      if (points > 0 && t.validation == Validation.self) celebrate(context, text: '¡${member.nickname} +$points!');
                    },
                  ),
                );
              }),
          ],
      ],
    );
  }
}
