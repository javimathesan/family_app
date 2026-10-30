import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/app_session.dart';
import '../data/family_store.dart';
import '../models/models.dart';

/// Muestra avisos del sistema con las novedades del hogar que llegan mientras
/// Family App está abierta o minimizada.
///
/// Sin un servidor que envíe notificaciones push (Cloud Functions, plan
/// Blaze), con la app cerrada no llegan: quedan en Novedades al abrirla.
class LocalNotifier with WidgetsBindingObserver {
  LocalNotifier(this.store, this.session) {
    instance = this;
  }

  /// El notificador de la app (para pedir permisos desde las pantallas).
  static LocalNotifier? instance;

  final FamilyStore store;
  final AppSession session;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _foreground = true;
  final Set<String> _known = {};
  final Map<String, int> _pendingByGroup = {};

  /// Última jugada vista de cada partida, para avisar "te toca" una sola vez.
  final Map<String, DateTime> _turnSeen = {};
  late DateTime _since;

  static const _channelId = 'avisos_hogar';

  Future<void> start() async {
    try {
      await _plugin.initialize(
        const InitializationSettings(android: AndroidInitializationSettings('ic_stat_notify')),
      );
      _ready = true;
    } catch (error) {
      debugPrint('Avisos del sistema no disponibles: $error');
      return;
    }
    _since = DateTime.now();
    _known.addAll(store.notices.map(_key));
    for (final m in store.matches) {
      _turnSeen[m.id] = m.updatedAt;
    }
    WidgetsBinding.instance.addObserver(this);
    store.addListener(_onStoreChanged);
    _scheduleAgenda();
  }

  /// Permiso para que los recordatorios con alarma suenen a la hora exacta.
  Future<void> askExactAlarms() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } catch (error) {
      debugPrint('No se pudo pedir permiso de alarmas: $error');
    }
  }

  // ----------------------------------------------------------------- agenda

  String _agendaSignature = '';
  bool _scheduling = false;

  /// Programa los recordatorios de la agenda en el teléfono. Suenan aunque
  /// la app esté cerrada: los maneja Android, no hace falta internet.
  Future<void> _scheduleAgenda() async {
    if (!_ready || _scheduling) return;
    final viewer = session.deviceMemberId ?? store.currentMember?.id;
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 60));
    final upcoming = [
      for (final e in viewer == null ? store.events : store.eventsFor(viewer))
        if (e.remindAt != null && e.remindAt!.isAfter(now) && e.remindAt!.isBefore(limit)) e,
    ].take(40).toList();
    final signature = [
      for (final e in upcoming) '${e.id}|${e.title}|${e.place}|${e.at.millisecondsSinceEpoch}|${e.remindMinutes}|${e.alarm}',
    ].join(';');
    if (signature == _agendaSignature) return;
    _scheduling = true;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        if (p.payload?.startsWith('agenda:') ?? false) await _plugin.cancel(p.id);
      }
      for (final e in upcoming) {
        await _scheduleEvent(e);
      }
      _agendaSignature = signature;
    } catch (error) {
      debugPrint('No se pudo programar la agenda: $error');
    } finally {
      _scheduling = false;
    }
  }

  static int _eventNotificationId(String eventId) => 100000 + (eventId.hashCode & 0x7fffffff) % 900000;

  Future<void> _scheduleEvent(AgendaEvent e) async {
    final hh = '${e.at.hour.toString().padLeft(2, '0')}:${e.at.minute.toString().padLeft(2, '0')}';
    final when = e.remindMinutes == 0 ? 'Ahora, $hh' : '${e.at.day}/${e.at.month} a las $hh';
    final who = e.memberIds.isEmpty ? '' : ' · ${[for (final id in e.memberIds) store.playerName(id)].join(', ')}';
    final body = '$when${e.place.isEmpty ? '' : ' · ${e.place}'}$who';
    final details = NotificationDetails(
      android: e.alarm
          ? AndroidNotificationDetails(
              'agenda_alarma',
              'Alarmas de la agenda',
              channelDescription: 'Recordatorios que suenan como alarma',
              importance: Importance.max,
              priority: Priority.max,
              category: AndroidNotificationCategory.alarm,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              // Suena hasta que se toca el aviso.
              additionalFlags: Int32List.fromList([4]),
            )
          : const AndroidNotificationDetails(
              'agenda',
              'Recordatorios de la agenda',
              channelDescription: 'Turnos, cumpleaños y otras cosas de la agenda familiar',
              importance: Importance.high,
              priority: Priority.high,
              category: AndroidNotificationCategory.reminder,
            ),
    );
    final at = tz.TZDateTime.from(e.remindAt!, tz.UTC);
    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          _eventNotificationId(e.id),
          '📅 ${e.title}',
          body,
          at,
          details,
          androidScheduleMode: mode,
          payload: 'agenda:${e.id}',
        );
    try {
      await schedule(e.alarm ? AndroidScheduleMode.alarmClock : AndroidScheduleMode.inexactAllowWhileIdle);
    } catch (_) {
      // Sin permiso de alarmas exactas: queda como aviso común (puede demorar unos minutos).
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  /// Pide permiso para mostrar avisos (Android 13 o superior).
  Future<void> askPermission() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (error) {
      debugPrint('No se pudo pedir permiso de avisos: $error');
    }
  }

  static String _key(FamilyNotice n) => '${n.time.microsecondsSinceEpoch}|${n.text}';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && _ready) {
      // Al volver a la app, lo nuevo se ve en Novedades: se limpian los avisos.
      _pendingByGroup.clear();
      _plugin.cancelAll();
    }
  }

  void _onStoreChanged() {
    _scheduleAgenda();
    _checkTurns();
    final fresh = [for (final n in store.notices) if (!_known.contains(_key(n))) n];
    if (fresh.isEmpty) return;
    _known.addAll(fresh.map(_key));
    if (!_ready || _foreground || !session.isCloud) return;
    for (final n in fresh.reversed) {
      if (n.time.isBefore(_since) || !session.shouldNotify(n)) continue;
      _show(n);
    }
  }

  /// "Te toca en Ludo": cuando otro jugó y ahora le toca a este teléfono.
  void _checkTurns() {
    final me = session.deviceMemberId;
    for (final m in store.matches) {
      final seen = _turnSeen[m.id];
      if (seen != null && !m.updatedAt.isAfter(seen)) continue;
      _turnSeen[m.id] = m.updatedAt;
      if (!_ready || _foreground || !session.isCloud || me == null) continue;
      if (session.notifyMode == NotifyMode.none || m.finished || m.sameDevice) continue;
      if (m.currentPlayer != me || m.lastBy == me || m.updatedAt.isBefore(_since)) continue;
      final rival = m.lastBy == null ? null : store.playerName(m.lastBy!);
      _plugin.show(
        m.id.hashCode & 0x7fffffff,
        'Te toca en ${m.kind.label}',
        rival == null ? '¡Empezó una partida nueva!' : '$rival ya jugó. ¡Tu turno!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'turnos_juegos',
            'Turnos de juegos',
            channelDescription: 'Cuando te toca jugar una partida',
          ),
        ),
      );
    }
  }

  /// Un aviso por hijo: si llegan varios, se reemplaza por "Tomi · 3 novedades".
  void _show(FamilyNotice n) {
    final group = n.memberId ?? 'hogar';
    final count = (_pendingByGroup[group] ?? 0) + 1;
    _pendingByGroup[group] = count;
    final who = n.memberId == null ? null : store.memberById(n.memberId!)?.nickname;
    final title = who == null ? store.homeName : (count > 1 ? '$who · $count novedades' : who);
    _plugin.show(
      group.hashCode & 0x7fffffff,
      title.isEmpty ? 'Family App' : title,
      n.text,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Avisos del hogar',
          channelDescription: 'Tareas, premios y aprobaciones de tu familia',
          importance: n.isImportant ? Importance.high : Importance.defaultImportance,
          priority: n.isImportant ? Priority.high : Priority.defaultPriority,
        ),
      ),
    );
  }
}
