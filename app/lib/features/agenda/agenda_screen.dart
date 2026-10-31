import 'package:flutter/material.dart';

import '../../data/app_session.dart';
import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../services/local_notifier.dart';
import '../../widgets/common.dart';

String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String agendaDayTitle(DateTime now, DateTime day) {
  final today = DateUtils.dateOnly(now);
  final d = DateUtils.dateOnly(day);
  if (d == today) return 'Hoy';
  if (d == today.add(const Duration(days: 1))) return 'Mañana';
  if (d == today.subtract(const Duration(days: 1))) return 'Ayer';
  final w = weekdayName(d);
  return '${w[0].toUpperCase()}${w.substring(1)} ${d.day} de ${monthName(d.month)}';
}

/// Agenda familiar: turnos, cumpleaños, actos… con aviso o alarma.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  bool _showPast = false;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final me = store.currentMember;
    final isAdult = me?.role.isAdult ?? false;
    final all = me == null ? store.events : store.eventsFor(me.id);
    final startOfToday = DateUtils.dateOnly(store.now);
    final upcoming = all.where((e) => !e.at.isBefore(startOfToday)).toList();
    final past = all.where((e) => e.at.isBefore(startOfToday)).toList().reversed.toList();

    final children = <Widget>[];
    DateTime? lastDay;
    for (final e in upcoming) {
      final day = DateUtils.dateOnly(e.at);
      if (day != lastDay) {
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
          child: Text(agendaDayTitle(store.now, day), style: sectionTitle(context)),
        ));
        lastDay = day;
      }
      children.add(_EventTile(event: e, canEdit: me != null && store.canEditEvent(e, me.id)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda', style: TextStyle(fontWeight: FontWeight.w800))),
      floatingActionButton: me == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => openEventForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            if (upcoming.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  isAdult
                      ? 'No hay nada agendado. Tocá "Agregar" para anotar un turno médico, un cumpleaños o un acto del colegio, con aviso o alarma.'
                      : 'No hay nada agendado. Tocá "Agregar" para anotar un examen, una tarea o un cumple, con aviso o alarma.',
                  style: mutedText(context).copyWith(fontSize: 15),
                ),
              ),
            ...children,
            if (past.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => setState(() => _showPast = !_showPast),
                icon: Icon(_showPast ? Icons.expand_less : Icons.expand_more),
                label: Text('Pasados (${past.length})'),
              ),
              if (_showPast)
                for (final e in past) _EventTile(event: e, canEdit: me != null && store.canEditEvent(e, me.id), past: true),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.canEdit, this.past = false});

  final AgendaEvent event;
  final bool canEdit;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final who = event.private
        ? 'Solo vos'
        : event.memberIds.isEmpty
            ? 'Toda la familia'
            : [for (final id in event.memberIds) store.playerName(id)].join(', ');
    final tile = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_hm(event.at), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            if (past) Text('${event.at.day}/${event.at.month}', style: mutedText(context)),
          ],
        ),
        title: Row(
          children: [
            if (event.private) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.lock_outline, size: 16)),
            Expanded(child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
        subtitle: Text([
          if (event.place.isNotEmpty) '📍 ${event.place}',
          '👤 $who',
          if (event.notes.isNotEmpty) event.notes,
        ].join('\n')),
        isThreeLine: event.place.isNotEmpty || event.notes.isNotEmpty,
        trailing: event.remindMinutes == null
            ? null
            : Tooltip(
                message: AgendaEvent.remindOptions[event.remindMinutes] ?? 'Aviso',
                child: Icon(event.alarm ? Icons.alarm : Icons.notifications_active_outlined),
              ),
        onTap: canEdit ? () => openEventForm(context, event: event) : null,
      ),
    );
    if (!canEdit) return tile;
    return Dismissible(
      key: ValueKey('ev_${event.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => store.removeEvent(event.id),
      child: tile,
    );
  }
}

String _creatorOf(AgendaEvent? existing, Member? me) => existing?.createdBy ?? me?.id ?? '';

/// Abre el formulario para crear o editar un evento.
Future<void> openEventForm(BuildContext context, {AgendaEvent? event}) {
  return Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => EventFormScreen(event: event),
  ));
}

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.event});

  final AgendaEvent? event;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  late final TextEditingController _title = TextEditingController(text: widget.event?.title ?? '');
  late final TextEditingController _place = TextEditingController(text: widget.event?.place ?? '');
  late final TextEditingController _notes = TextEditingController(text: widget.event?.notes ?? '');
  late DateTime _at;
  late Set<String> _members = {...?widget.event?.memberIds};
  late int? _remind = widget.event == null ? 60 : widget.event!.remindMinutes;
  late bool _alarm = widget.event?.alarm ?? false;
  late bool _private = widget.event?.private ?? false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.event != null) {
      _at = widget.event!.at;
    } else {
      final now = FamilyScope.of(context).now.add(const Duration(days: 1));
      _at = DateTime(now.year, now.month, now.day, 9);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _at = DateTime(d.year, d.month, d.day, _at.hour, _at.minute));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_at));
    if (t != null) setState(() => _at = DateTime(_at.year, _at.month, _at.day, t.hour, t.minute));
  }

  void _save() {
    final store = FamilyScope.of(context);
    final me = store.currentMember;
    final kid = !(me?.role.isAdult ?? true);
    final event = (widget.event?.copy() ??
        AgendaEvent(id: store.newEventId(), title: '', at: _at, createdBy: me?.id ?? ''))
      ..title = _title.text.trim()
      ..place = _place.text.trim()
      ..notes = _notes.text.trim()
      ..at = _at
      // Los chicos agendan para ellos; lo privado es solo de quien lo crea.
      ..memberIds = kid || _private ? {_creatorOf(widget.event, me)} : {..._members}
      ..private = !kid && _private
      ..remindMinutes = _remind
      ..alarm = _remind != null && _alarm;
    store.saveEvent(event);
    if (event.alarm) LocalNotifier.instance?.askExactAlarms();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final session = SessionScope.of(context);
    final members = [for (final m in store.members) if (!store.isPendingMember(m.id)) m];
    final editing = widget.event != null;
    final kid = !(store.currentMember?.role.isAdult ?? true);
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar' : 'Nuevo en la agenda', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'Borrar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                store.removeEvent(widget.event!.id);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: '¿Qué es?',
                hintText: kid ? 'Examen de matemática, entregar la maqueta…' : 'Turno médico, cumpleaños de la abuela…',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _place,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Lugar (opcional)', prefixIcon: Icon(Icons.place_outlined), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(agendaDayTitle(store.now, _at)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_hm(_at)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (kid)
              InfoCard(
                color: const Color(0xFFE3F2FD),
                child: Text(
                  'Es para vos. Tus papás también lo ven en su agenda y les llega el aviso.',
                  style: mutedText(context).copyWith(fontSize: 14),
                ),
              )
            else ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _private,
              onChanged: (v) => setState(() => _private = v),
              secondary: const Icon(Icons.lock_outline),
              title: const Text('Solo para mí', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Nadie más lo ve en la app ni recibe el aviso.'),
            ),
            if (!_private) ...[
            Text('¿Para quién?', style: sectionTitle(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Toda la familia'),
                  selected: _members.isEmpty,
                  onSelected: (_) => setState(() => _members = {}),
                ),
                for (final m in members)
                  FilterChip(
                    label: Text(m.nickname),
                    selected: _members.contains(m.id),
                    onSelected: (on) => setState(() => on ? _members.add(m.id) : _members.remove(m.id)),
                  ),
              ],
            ),
            ],
            ],
            const SizedBox(height: 16),
            Text('Aviso', style: sectionTitle(context)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: _remind,
              decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.notifications_outlined)),
              items: [
                for (final e in AgendaEvent.remindOptions.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _remind = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _remind != null && _alarm,
              onChanged: _remind == null ? null : (v) => setState(() => _alarm = v),
              secondary: const Icon(Icons.alarm),
              title: const Text('Que suene como alarma', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Suena fuerte hasta que lo toques. Si no, es un aviso común.'),
            ),
            Text(
              session.isCloud
                  ? 'Avisa en el teléfono de cada persona elegida (los adultos reciben todo lo que no es privado), aunque la app esté cerrada.'
                  : 'Avisa en este teléfono aunque la app esté cerrada.',
              style: mutedText(context),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notas (opcional)', hintText: 'Llevar estudios, la libreta…', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _title.text.trim().isEmpty ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
