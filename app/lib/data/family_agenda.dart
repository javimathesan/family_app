part of 'family_store.dart';

/// Agenda familiar: turnos, cumpleaños, actos del colegio…
extension FamilyAgenda on FamilyStore {
  /// Todos los eventos, del más próximo al más lejano.
  List<AgendaEvent> get events => [..._events]..sort((a, b) => a.at.compareTo(b.at));

  AgendaEvent? eventById(String id) {
    for (final e in _events) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Eventos que ve un miembro: los suyos, los de toda la familia y, si es
  /// adulto, también los de los chicos. Los privados solo los ve quien los creó.
  List<AgendaEvent> eventsFor(String memberId) {
    final adult = memberById(memberId)?.role.isAdult ?? true;
    return [
      for (final e in events)
        if (e.createdBy == memberId || (!e.private && (adult || e.isFor(memberId)))) e,
    ];
  }

  /// Quién puede editar o borrar un evento: quien lo creó y, si no es
  /// privado, cualquier adulto.
  bool canEditEvent(AgendaEvent e, String memberId) =>
      e.createdBy == memberId || (!e.private && (memberById(memberId)?.role.isAdult ?? false));

  /// Eventos de un día para un miembro.
  List<AgendaEvent> eventsOn(DateTime day, String memberId) =>
      [for (final e in eventsFor(memberId)) if (DateUtils.isSameDay(e.at, day)) e];

  String newEventId() => _newId('e');

  /// Crea o actualiza un evento.
  void saveEvent(AgendaEvent event) {
    final i = _events.indexWhere((e) => e.id == event.id);
    final isNew = i < 0;
    if (isNew) {
      _events.add(event);
    } else {
      _events[i] = event;
    }
    sync?.eventSaved(event);
    if (isNew && !event.private) {
      final who = playerName(event.createdBy);
      final kid = !(memberById(event.createdBy)?.role.isAdult ?? true);
      _addNotice(
        '$who ${kid ? 'agendó' : 'agregó a la agenda'}: ${event.title} (${_shortDate(event.at)})',
        // Lo que agenda un chico (un examen, por ejemplo) les llega a los adultos.
        kind: kid ? NoticeKind.toApprove : NoticeKind.info,
        memberId: event.createdBy,
      );
    }
    _changed();
  }

  void removeEvent(String id) {
    final before = _events.length;
    _events.removeWhere((e) => e.id == id);
    if (_events.length == before) return;
    sync?.eventRemoved(id);
    _changed();
  }

  static String _shortDate(DateTime d) =>
      '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

Map<String, dynamic> _eventToJson(AgendaEvent e) => {
      'id': e.id,
      'title': e.title,
      'place': e.place,
      'notes': e.notes,
      'at': e.at.millisecondsSinceEpoch,
      'members': e.memberIds.toList(),
      'remind': e.remindMinutes,
      'alarm': e.alarm,
      'private': e.private,
      'createdBy': e.createdBy,
    };

AgendaEvent _eventFromJson(Map<String, dynamic> j) => AgendaEvent(
      id: j['id'] as String,
      title: j['title'] as String? ?? '',
      place: j['place'] as String? ?? '',
      notes: j['notes'] as String? ?? '',
      at: DateTime.fromMillisecondsSinceEpoch((j['at'] as num).toInt()),
      memberIds: ((j['members'] as List?) ?? const []).cast<String>().toSet(),
      remindMinutes: (j['remind'] as num?)?.toInt(),
      alarm: j['alarm'] as bool? ?? false,
      private: j['private'] as bool? ?? false,
      createdBy: j['createdBy'] as String? ?? '',
    );
