import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/app_session.dart';
import '../../data/family_store.dart';
import '../../domain/points.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/accent_picker.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';
import '../../widgets/mood_face.dart';
import '../../widgets/pin_dialog.dart';

/// Panel del adulto: miembros, aprobaciones pendientes y avisos.
class AdultHomeScreen extends StatelessWidget {
  const AdultHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final session = SessionScope.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final pendingMembers = store.members.where((m) => store.isPendingMember(m.id)).toList();
    final me = store.currentMember ?? session.deviceMember;
    final children = store.children.where((c) => !store.isPendingMember(c.id)).toList();
    final adults = store.members.where((m) => m.role.isAdult && !store.isPendingMember(m.id)).toList();
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
                Tooltip(
                  message: 'Cambiar mi avatar',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: me == null ? null : () => Navigator.of(context).pushNamed(Routes.avatar),
                    child: AvatarView(
                      config: me?.avatar ?? const AvatarConfig(),
                      size: 52,
                      background: (me?.accent ?? accent).withValues(alpha: 0.15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        me == null ? store.homeName : 'Hola, ${me.nickname} · ${store.homeName}',
                        style: mutedText(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Mi familia', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Novedades',
                  onPressed: () => Navigator.of(context).pushNamed(Routes.notices),
                  icon: Badge(
                    isLabelVisible: session.unreadNotices > 0,
                    label: Text('${session.unreadNotices > 99 ? '99+' : session.unreadNotices}'),
                    child: const Icon(Icons.notifications_none),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  onSelected: (value) => _onMenu(context, value),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'switch', child: Text('Cambiar de usuario')),
                    PopupMenuItem(value: 'pin', child: Text(session.hasPin ? 'Cambiar o quitar el PIN' : 'Poner PIN al modo adulto')),
                    const PopupMenuItem(value: 'look', child: Text('Personalizar mi app')),
                    const PopupMenuItem(value: 'week', child: Text('Resumen de la semana')),
                    if (session.isAdmin) const PopupMenuItem(value: 'challenge', child: Text('Reto de la semana')),
                    if (session.isCloud && session.isAdmin)
                      const PopupMenuItem(value: 'relink', child: Text('Teléfono nuevo de alguien')),
                    const PopupMenuItem(value: 'privacy', child: Text('Privacidad y datos')),
                    if (session.isDemo) ...const [
                      PopupMenuItem(value: 'reset', child: Text('Restablecer datos de ejemplo')),
                      PopupMenuItem(value: 'leave', child: Text('Salir de la demostración')),
                    ] else
                      const PopupMenuItem(value: 'leave', child: Text('Desvincular este teléfono')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(session.isCloud ? Icons.cloud_done_outlined : Icons.phone_android, size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    session.isCloud ? 'Sincronizado con los teléfonos del hogar' : 'Demostración: solo en este teléfono',
                    style: mutedText(context),
                  ),
                ),
              ],
            ),
            if (session.isAdmin) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(Routes.invite),
                style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Invitar con QR'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(Routes.routine),
                      icon: const Icon(Icons.checklist),
                      label: const Text('Rutina y premios'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addChildWithoutPhone(context),
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Hijo sin celular'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(Routes.agenda),
                    icon: const Icon(Icons.event_note_outlined),
                    label: const Text('Agenda'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(Routes.games),
                    icon: Badge(
                      isLabelVisible: me != null && store.myTurnCount(me.id) > 0,
                      label: Text('${me == null ? 0 : store.myTurnCount(me.id)}'),
                      child: const Icon(Icons.sports_esports_outlined),
                    ),
                    label: const Text('Juegos'),
                  ),
                ),
              ],
            ),
            if (me != null)
              for (final e in store.eventsOn(store.now, me.id).where((e) => e.at.isAfter(store.now)).take(2))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InfoCard(
                    color: const Color(0xFFFFF8E1),
                    child: Row(
                      children: [
                        const Icon(Icons.event, color: Color(0xFFB26A00)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hoy ${e.at.hour.toString().padLeft(2, '0')}:${e.at.minute.toString().padLeft(2, '0')} · ${e.title}'
                            '${e.place.isEmpty ? '' : ' · ${e.place}'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (me != null) ...[
              const SizedBox(height: 20),
              _MyDay(member: me),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Text('Hijos', style: sectionTitle(context))),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(Routes.week),
                  icon: const Icon(Icons.bar_chart, size: 20),
                  label: const Text('Semana'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (children.isEmpty)
              InfoCard(
                child: Text(
                  session.isAdmin
                      ? 'Todavía no hay hijos en el hogar. Sumalos con "Invitar con QR" si tienen celular, o con "Hijo sin celular" para manejarlos desde tu teléfono.'
                      : 'Todavía no hay hijos en el hogar.',
                  style: mutedText(context).copyWith(fontSize: 15),
                ),
              ),
            for (final child in children) ...[
              _ChildCard(member: child, accent: accent),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
            Text('Adultos del hogar', style: sectionTitle(context)),
            const SizedBox(height: 10),
            InfoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final a in adults)
                    ListTile(
                      leading: AvatarView(config: a.avatar, size: 40, background: a.accent.withValues(alpha: 0.15)),
                      title: Text(a.id == me?.id ? '${a.nickname} (vos)' : a.nickname, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(a.role.label),
                      trailing: a.id == me?.id ? const Icon(Icons.edit_outlined, size: 20) : null,
                      onTap: a.id == me?.id ? () => Navigator.of(context).pushNamed(Routes.avatar) : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Para aprobar', style: sectionTitle(context)),
            const SizedBox(height: 10),
            if (!hasApprovals)
              InfoCard(child: Text('Todo al día. No hay pedidos pendientes.', style: mutedText(context).copyWith(fontSize: 15))),
            for (final m in pendingMembers)
              if (store.isRelinking(m.id))
                _ApprovalCard(
                  kind: 'TELÉFONO NUEVO',
                  text: '${m.nickname} quiere volver a entrar desde otro teléfono',
                  onApprove: session.isAdmin ? () => store.confirmMember(m.id) : null,
                  // Rechazar no borra el perfil: queda sin teléfono propio.
                  onReject: session.isAdmin ? () => store.cancelRelink(m.id) : null,
                )
              else
                _ApprovalCard(
                  kind: 'ALTA NUEVA',
                  text: '${m.nickname} quiere unirse como ${m.role.label.toLowerCase()}',
                  onApprove: session.isAdmin ? () => store.confirmMember(m.id) : null,
                  onReject: session.isAdmin ? () => store.removeMember(m.id) : null,
                ),
            for (final r in store.pendingRedemptions)
              _ApprovalCard(
                kind: 'PREMIO PEDIDO · ${store.memberById(r.memberId)?.nickname ?? ''}',
                text: '${store.rewardById(r.rewardId)?.name ?? 'Premio'} (${store.rewardById(r.rewardId)?.cost ?? 0} pts)',
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
            Row(
              children: [
                Expanded(child: Text('Últimas novedades', style: sectionTitle(context))),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(Routes.notices),
                  child: Text(session.unreadNotices > 0 ? 'Ver todas (${session.unreadNotices} nuevas)' : 'Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (store.notices.isEmpty)
              InfoCard(
                child: Text(
                  'Acá vas a ver cuando tus hijos completen tareas, lleguen a su meta de agua o pidan premios.',
                  style: mutedText(context).copyWith(fontSize: 15),
                ),
              )
            else
              InfoCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final n in store.notices.take(4))
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

  /// El adulto elige el reto de la semana para los chicos.
  Future<void> _editChallenge(BuildContext context) async {
    final store = FamilyScope.of(context);
    var type = store.challenge?.type ?? ChallengeType.rutina;
    var target = store.challenge?.target ?? type.targets[1];
    var bonus = store.challenge?.bonus ?? 50;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reto de la semana', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const Text('Es para todos los chicos, de lunes a domingo. Al cumplirlo cobran puntos extra.'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in ChallengeType.values)
                      ChoiceChip(
                        avatar: Icon(t.icon, size: 18),
                        label: Text(t.label),
                        selected: type == t,
                        onSelected: (_) => setSheet(() {
                          type = t;
                          target = t.targets[1];
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Meta: $target ${type.unit}', style: const TextStyle(fontWeight: FontWeight.w800)),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final v in type.targets)
                      ChoiceChip(label: Text('$v'), selected: target == v, onSelected: (_) => setSheet(() => target = v)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Puntos extra', style: TextStyle(fontWeight: FontWeight.w800)),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final v in const [20, 50, 100])
                      ChoiceChip(label: Text('+$v'), selected: bonus == v, onSelected: (_) => setSheet(() => bonus = v)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (store.challenge != null)
                      TextButton(
                        onPressed: () {
                          store.setChallenge(null);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Sin reto'),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        store.setChallenge(WeeklyChallenge(type: type, target: target, bonus: bonus));
                        Navigator.pop(ctx);
                      },
                      child: const Text('Guardar reto'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Elige a quién se le cambió o borró el teléfono y muestra su QR.
  Future<void> _relinkPhone(BuildContext context) async {
    final store = FamilyScope.of(context);
    final me = store.currentMember?.id;
    final options = [
      for (final m in store.members)
        if (m.id != me && !store.isPendingMember(m.id)) m,
    ];
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('¿Quién cambió de teléfono o borró la app?'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Va a volver a entrar con su perfil, sus puntos y su avatar. El teléfono anterior deja de tener acceso.'),
          ),
          if (options.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Text('No hay otros miembros en el hogar.')),
          for (final m in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, m.id),
              child: Text(m.nickname, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    Navigator.of(context).pushNamed('${Routes.invite}?relink=$picked');
  }

  Future<void> _onMenu(BuildContext context, String value) async {
    if (value == 'switch') {
      Navigator.of(context).pushReplacementNamed(Routes.welcome);
      return;
    }
    if (value == 'pin') return _managePin(context);
    if (value == 'relink') return _relinkPhone(context);
    if (value == 'challenge') return _editChallenge(context);
    if (value == 'look') return showAccentPicker(context);
    if (value == 'week' || value == 'privacy') {
      Navigator.of(context).pushNamed(value == 'week' ? Routes.week : Routes.privacy);
      return;
    }
    final session = SessionScope.of(context);
    final store = FamilyScope.of(context);
    final reset = value == 'reset';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(reset
            ? '¿Volver a los datos de ejemplo?'
            : session.isDemo
                ? '¿Salir de la demostración?'
                : '¿Desvincular este teléfono?'),
        content: Text(reset
            ? 'Se borran los puntos, tareas, premios y miembros guardados en este teléfono.'
            : session.isDemo
                ? 'Vas a poder crear tu hogar real o unirte a uno. La demostración queda guardada.'
                : 'El hogar y sus datos siguen en la nube. Para volver a entrar vas a necesitar una invitación nueva.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(reset ? 'Restablecer' : 'Confirmar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (reset) {
      store.resetToDemo();
    } else {
      await session.leave();
    }
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.welcome, (_) => false);
  }

  /// Poner, cambiar o quitar el PIN que protege los perfiles de adulto en
  /// este teléfono (para cuando los chicos lo usan).
  Future<void> _managePin(BuildContext context) async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (session.hasPin) {
      final current = await showPinDialog(context, title: 'PIN actual', message: 'Para cambiarlo o quitarlo, ingresá el PIN actual.');
      if (current == null || !context.mounted) return;
      if (!session.checkPin(current)) {
        messenger.showSnackBar(const SnackBar(content: Text('PIN incorrecto')));
        return;
      }
      final remove = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('PIN del modo adulto'),
          content: const Text('¿Qué querés hacer?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Quitar PIN')),
            FilledButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cambiar PIN')),
          ],
        ),
      );
      if (remove == null || !context.mounted) return;
      if (remove) {
        await session.clearPin();
        messenger.showSnackBar(const SnackBar(content: Text('Listo: los perfiles de adulto se abren sin PIN.')));
        return;
      }
    }
    final first = await showPinDialog(
      context,
      title: 'Nuevo PIN',
      message: 'Elegí 4 números. Se va a pedir para abrir perfiles de adulto en este teléfono.',
    );
    if (first == null || !context.mounted) return;
    final second = await showPinDialog(context, title: 'Repetí el PIN');
    if (second == null || !context.mounted) return;
    if (first != second) {
      messenger.showSnackBar(const SnackBar(content: Text('Los PIN no coinciden. Probá de nuevo.')));
      return;
    }
    await session.setPin(first);
    messenger.showSnackBar(const SnackBar(content: Text('PIN guardado en este teléfono.')));
  }

  Future<void> _addChildWithoutPhone(BuildContext context) async {
    final store = FamilyScope.of(context);
    final result = await showDialog<(String, AgeMode)>(
      context: context,
      builder: (_) => const _AddChildDialog(),
    );
    if (result == null) return;
    store.addMember(nickname: result.$1, role: MemberRole.child, mode: result.$2);
  }
}

/// Metas del día del adulto: dar el ejemplo y afianzar el vínculo familiar.
class _MyDay extends StatelessWidget {
  const _MyDay({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final done = store.adultGoalsDone(member.id);
    final total = AdultGoal.all.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Mi día', style: sectionTitle(context))),
            Text('$done de $total', style: TextStyle(fontWeight: FontWeight.w800, color: accent)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          done == total ? '¡Día completo! Gran ejemplo para tus hijos.' : 'Tus metas de hoy. Tus hijos ven que también te comprometés.',
          style: mutedText(context),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in AdultGoal.all)
              FilterChip(
                avatar: Icon(g.icon, size: 18),
                label: Text(g.label),
                selected: store.isGoalDone(member.id, g.id),
                onSelected: (_) => store.toggleAdultGoal(member.id, g.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _AddChildDialog extends StatefulWidget {
  const _AddChildDialog();

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final _nick = TextEditingController();
  AgeMode _mode = AgeMode.peques;

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nick = _nick.text.trim();
    return AlertDialog(
      title: const Text('Hijo sin celular'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lo manejás desde tu teléfono: elegís su perfil en "¿Quién usa la app?".'),
          const SizedBox(height: 12),
          TextField(
            controller: _nick,
            maxLength: 16,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Apodo', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in AgeMode.values)
                ChoiceChip(label: Text(m.label), selected: _mode == m, onSelected: (_) => setState(() => _mode = m)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: nick.isEmpty ? null : () => Navigator.pop(context, (nick, _mode)),
          child: const Text('Agregar'),
        ),
      ],
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
  final VoidCallback? onApprove;
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
