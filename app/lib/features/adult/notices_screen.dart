import 'package:flutter/material.dart';

import '../../data/app_session.dart';
import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Novedades del hogar: lo que pasó mientras no mirabas, agrupado por día.
///
/// Las tareas comunes de un mismo hijo en un mismo día se juntan en una sola
/// línea para que no sea una lista interminable de mensajes.
class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  /// `null` = todo; `'!'` = solo importantes; otro = id del miembro.
  String? _filter;
  DateTime? _seenBefore;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seenBefore == null) {
      final session = SessionScope.of(context);
      // Recordamos qué era nuevo al entrar, y marcamos todo como leído.
      _seenBefore = session.noticesSeenAt;
      WidgetsBinding.instance.addPostFrameCallback((_) => session.markNoticesSeen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final session = SessionScope.of(context);
    final people = store.members.where((m) => !store.isPendingMember(m.id)).toList();
    final notices = session.visibleNotices.where((n) {
      if (_filter == null) return true;
      if (_filter == '!') return n.isImportant;
      return n.memberId == _filter;
    }).toList();
    final days = _groupByDay(notices);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novedades', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Qué avisos recibir',
            onPressed: () => _chooseMode(context, session),
            icon: const Icon(Icons.tune),
          ),
          PopupMenuButton<String>(
            tooltip: 'Limpiar',
            icon: const Icon(Icons.delete_sweep_outlined),
            onSelected: (v) => _clean(context, v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'mine', child: Text('Limpiar todo en este teléfono')),
              if (session.isAdmin)
                const PopupMenuItem(value: 'old', child: Text('Borrar para todos lo de hace más de 7 días')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(label: const Text('Todo'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Importantes'), selected: _filter == '!', onSelected: (_) => setState(() => _filter = '!')),
                for (final m in people) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(label: Text(m.nickname), selected: _filter == m.id, onSelected: (_) => setState(() => _filter = m.id)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (days.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('Deslizá una novedad para sacarla de la lista.', style: mutedText(context)),
            ),
          if (days.isEmpty)
            InfoCard(
              child: Text(
                'Sin novedades por ahora. Acá vas a ver las tareas que completan, los premios que piden y las aprobaciones.',
                style: mutedText(context).copyWith(fontSize: 15),
              ),
            ),
          for (final day in days) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(_dayTitle(store.now, day.date), style: sectionTitle(context)),
            ),
            InfoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final row in _rowsFor(store, day.notices))
                    Dismissible(
                      key: ValueKey('n_${row.time.millisecondsSinceEpoch}_${row.text}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red.shade400,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) => session.hideNotices(row.sources),
                      child: _NoticeTile(row: row, unread: row.time.isAfter(_seenBefore!)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _clean(BuildContext context, String what) async {
    final session = SessionScope.of(context);
    final store = FamilyScope.of(context);
    final everyone = what == 'old';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(everyone ? '¿Borrar el historial viejo?' : '¿Limpiar las novedades?'),
        content: Text(everyone
            ? 'Se borran para todos los teléfonos del hogar las novedades de hace más de 7 días.'
            : 'Se limpian solo en este teléfono. Los demás las siguen viendo y las nuevas van a seguir llegando.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(everyone ? 'Borrar' : 'Limpiar')),
        ],
      ),
    );
    if (ok != true) return;
    if (everyone) {
      store.deleteNoticesBefore(store.now.subtract(const Duration(days: 7)));
    } else {
      await session.clearNotices();
    }
  }

  Future<void> _chooseMode(BuildContext context, AppSession session) async {
    final mode = await showModalBottomSheet<NotifyMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text('Avisos en este teléfono', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Llegan mientras Family App está abierta o minimizada. Todo queda igual en Novedades.'),
            ),
            for (final m in NotifyMode.values)
              ListTile(
                leading: Icon(session.notifyMode == m ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                title: Text(m.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(m.description),
                onTap: () => Navigator.pop(ctx, m),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (mode != null) await session.setNotifyMode(mode);
  }
}

class _Day {
  _Day(this.date);
  final DateTime date;
  final List<FamilyNotice> notices = [];
}

List<_Day> _groupByDay(List<FamilyNotice> notices) {
  final days = <_Day>[];
  for (final n in notices) {
    final date = DateUtils.dateOnly(n.time);
    if (days.isEmpty || days.last.date != date) days.add(_Day(date));
    days.last.notices.add(n);
  }
  return days;
}

String _dayTitle(DateTime now, DateTime date) {
  final today = DateUtils.dateOnly(now);
  if (date == today) return 'Hoy';
  if (date == today.subtract(const Duration(days: 1))) return 'Ayer';
  final w = weekdayName(date);
  return '${w[0].toUpperCase()}${w.substring(1)} ${date.day} de ${monthName(date.month)}';
}

/// Una línea de la lista: un aviso suelto o varias tareas juntas.
class _Row {
  _Row({required this.time, required this.text, required this.kind, required this.sources, this.detail});
  final DateTime time;
  final String text;
  final NoticeKind kind;
  final String? detail;

  /// Avisos que forman esta línea (para sacarlos todos juntos).
  final List<FamilyNotice> sources;
}

/// Junta las tareas comunes de cada miembro del día en una sola línea.
List<_Row> _rowsFor(FamilyStore store, List<FamilyNotice> notices) {
  final rows = <_Row>[];
  final taskGroups = <String, List<FamilyNotice>>{};
  for (final n in notices) {
    if (n.kind == NoticeKind.task && n.memberId != null) {
      taskGroups.putIfAbsent(n.memberId!, () => []).add(n);
    } else {
      rows.add(_Row(time: n.time, text: n.text, kind: n.isAlert ? NoticeKind.alert : n.kind, sources: [n]));
    }
  }
  taskGroups.forEach((memberId, list) {
    final who = store.memberById(memberId)?.nickname ?? 'Alguien';
    if (list.length == 1) {
      rows.add(_Row(time: list.first.time, text: list.first.text, kind: NoticeKind.task, sources: list));
      return;
    }
    final names = [for (final n in list.reversed) n.text.split(': ').last];
    rows.add(_Row(
      time: list.first.time,
      text: '$who completó ${list.length} tareas',
      kind: NoticeKind.task,
      sources: list,
      detail: names.join(' · '),
    ));
  });
  rows.sort((a, b) => b.time.compareTo(a.time));
  return rows;
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.row, required this.unread});

  final _Row row;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final color = switch (row.kind) {
      NoticeKind.alert => AppColors.warmInk,
      NoticeKind.reward || NoticeKind.toApprove || NoticeKind.join => const Color(0xFF7C3AED),
      _ => AppColors.muted,
    };
    return ListTile(
      leading: Icon(row.kind.icon, color: color),
      title: Text(row.text, style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600)),
      subtitle: row.detail == null ? null : Text(row.detail!, maxLines: 3, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(hhmm(TimeOfDay.fromDateTime(row.time)), style: mutedText(context).copyWith(fontSize: 12)),
          if (unread) ...[
            const SizedBox(height: 4),
            Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
          ],
        ],
      ),
    );
  }
}
