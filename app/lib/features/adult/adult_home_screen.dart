import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/family_store.dart';
import '../../domain/points.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';
import '../../widgets/mood_face.dart';

/// Panel del adulto: miembros, aprobaciones pendientes y avisos.
class AdultHomeScreen extends StatelessWidget {
  const AdultHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final pendingMembers = store.members.where((m) => store.isPendingMember(m.id)).toList();
    final hasApprovals = pendingMembers.isNotEmpty ||
        store.pendingRedemptions.isNotEmpty ||
        store.pendingTaskApprovals.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${store.homeName} · ${store.members.length} miembros', style: mutedText(context)),
                      Text('Mi familia', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cambiar de usuario',
                  onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.welcome),
                  icon: const Icon(Icons.switch_account_outlined),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  onSelected: (value) async {
                    if (value != 'reset') return;
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('¿Volver a los datos de ejemplo?'),
                        content: const Text('Se borran los puntos, tareas, premios y miembros guardados en este teléfono.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restablecer')),
                        ],
                      ),
                    );
                    if (ok != true || !context.mounted) return;
                    store.resetToDemo();
                    Navigator.of(context).pushReplacementNamed(Routes.welcome);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'reset', child: Text('Restablecer datos de ejemplo')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(Routes.invite),
              style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Invitar con QR'),
            ),
            const SizedBox(height: 16),
            for (final child in store.children.where((c) => !store.isPendingMember(c.id))) ...[
              _ChildCard(member: child, accent: accent),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
            Text('Para aprobar', style: sectionTitle(context)),
            const SizedBox(height: 10),
            if (!hasApprovals)
              InfoCard(child: Text('Todo al día. No hay pedidos pendientes.', style: mutedText(context).copyWith(fontSize: 15))),
            for (final m in pendingMembers)
              _ApprovalCard(
                kind: 'ALTA NUEVA',
                text: '${m.nickname} quiere unirse como ${m.role.label.toLowerCase()}',
                onApprove: () => store.confirmMember(m.id),
                onReject: null,
              ),
            for (final r in store.pendingRedemptions)
              _ApprovalCard(
                kind: 'PREMIO PEDIDO · ${store.memberById(r.memberId)?.nickname ?? ''}',
                text: '${store.rewardById(r.rewardId).name} (${store.rewardById(r.rewardId).cost} pts)',
                onApprove: () => store.approveRedemption(r.id),
                onReject: () => store.rejectRedemption(r.id),
              ),
            for (final p in store.pendingTaskApprovals)
              _ApprovalCard(
                kind: '${p.task.validation == Validation.photo ? 'TAREA CON FOTO' : 'TAREA A VALIDAR'} · ${p.member.nickname}',
                text: p.task.name,
                onApprove: () => store.approveTask(p.member.id, p.task.id),
                onReject: () => store.rejectTask(p.member.id, p.task.id),
              ),
            const SizedBox(height: 10),
            Text('Últimos avisos', style: sectionTitle(context)),
            const SizedBox(height: 10),
            InfoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final n in store.notices.take(6))
                    ListTile(
                      dense: true,
                      leading: Text(
                        n.isAlert ? 'Aviso' : hhmm(TimeOfDay.fromDateTime(n.time)),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: n.isAlert ? AppColors.warmInk : AppColors.muted,
                        ),
                      ),
                      title: Text(n.text, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.member, required this.accent});

  final Member member;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final ratio = store.completionRatio(member.id);
    final health = store.healthOf(member.id);
    return InfoCard(
      child: Row(
        children: [
          AvatarView(config: member.avatar, size: 52, background: member.accent.withValues(alpha: 0.15)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${member.nickname} · ${member.mode?.label ?? ''}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text('${store.doneToday(member.id)} tareas · ${health.glasses} vasos de agua', style: mutedText(context)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: ratio, minHeight: 8, color: accent, backgroundColor: const Color(0xFFE9ECF4)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              MoodFace(mood: Mood.fromRatio(ratio), size: 30),
              Text('${store.pointsToday(member.id)} pts', style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.kind, required this.text, required this.onApprove, required this.onReject});

  final String kind;
  final String text;
  final VoidCallback onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kind, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.warmInk)),
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                if (onReject != null) ...[
                  Expanded(child: OutlinedButton(onPressed: onReject, child: const Text('Ahora no'))),
                  const SizedBox(width: 8),
                ],
                Expanded(child: FilledButton(onPressed: onApprove, child: const Text('Aprobar'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
