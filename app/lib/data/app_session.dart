import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'family_cloud.dart';
import 'family_storage.dart';
import 'family_store.dart';

/// Cómo está usando este teléfono la app.
enum SessionMode {
  /// Recién instalada: todavía no eligió qué hacer.
  none,

  /// Datos de ejemplo guardados solo en este teléfono.
  demo,

  /// Vinculado a un hogar compartido en la nube.
  cloud,
}

/// Qué avisos del sistema quiere recibir este teléfono.
enum NotifyMode {
  important('Solo lo importante', 'Pedidos de premios, altas, tareas para aprobar y alertas.'),
  all('Todo', 'También cada tarea, meta de agua y aprobación.'),
  none('Nada', 'Sin avisos del sistema. Las novedades quedan en la campanita.');

  const NotifyMode(this.label, this.description);
  final String label;
  final String description;
}

/// Estado de este teléfono: modo, hogar vinculado y perfil propio.
class AppSession extends ChangeNotifier {
  AppSession({
    required this.store,
    required SharedPreferences prefs,
    required this.storage,
    this.cloud,
  }) : _prefs = prefs;

  final FamilyStore store;
  final FamilyStorage storage;

  /// `null` si Firebase no está disponible: solo se puede usar la demostración.
  final FamilyCloud? cloud;
  final SharedPreferences _prefs;

  static const _kMode = 'session_mode';
  static const _kHome = 'session_home';
  static const _kMember = 'session_member';
  static const _kPending = 'session_pending';
  static const _kPin = 'session_pin';
  static const _kNoticesSeen = 'notices_seen';
  static const _kNotifyMode = 'notify_mode';
  static const _kNoticesCleared = 'notices_cleared';
  static const _kNoticesHidden = 'notices_hidden';

  SessionMode mode = SessionMode.none;
  String? homeId;

  /// Se llama cuando el teléfono queda vinculado a un hogar en la nube
  /// (por ejemplo, para pedir permiso de avisos).
  VoidCallback? onCloudLinked;

  /// Perfil de la persona que usa este teléfono.
  String? deviceMemberId;

  /// Se unió con una invitación y espera que un adulto lo apruebe.
  bool pendingApproval = false;

  bool get cloudAvailable => cloud != null;

  /// Contenido de Family App Plus disponible: si el hogar lo tiene o en la
  /// demostración (para probarlo).
  bool get plusOpen => store.hasPlus || !isCloud;
  bool get isDemo => mode == SessionMode.demo;
  bool get isCloud => mode == SessionMode.cloud;

  Member? get deviceMember => deviceMemberId == null ? null : store.memberById(deviceMemberId!);

  /// En la demo todos los adultos administran; en la nube, según el rol.
  bool get isAdmin => isDemo || (deviceMember?.role.canManage ?? false);

  /// Perfiles que se pueden abrir desde este teléfono: el propio y, si es
  /// adulto administrador, los hijos que no tienen celular.
  List<Member> get profilesOnThisDevice {
    final approved = store.members.where((m) => !store.isPendingMember(m.id)).toList();
    if (!isCloud) return approved;
    final mine = cloud?.uid;
    return [
      for (final m in approved)
        if (m.uid != null && m.uid == mine) m else if (m.uid == null && isAdmin) m,
    ];
  }

  // -------------------------------------------------------------- novedades

  /// Última vez que este teléfono abrió Novedades.
  DateTime get noticesSeenAt {
    final ms = _prefs.getInt(_kNoticesSeen);
    return ms == null ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Quién usa este teléfono ahora: sus propias acciones no cuentan como novedad.
  String? get _viewerId => store.currentMember?.id ?? deviceMemberId;

  bool isUnread(FamilyNotice n) => n.time.isAfter(noticesSeenAt) && n.memberId != _viewerId;

  int get unreadNotices => visibleNotices.where(isUnread).length;

  /// Novedades que muestra este teléfono: las de los últimos 30 días que no
  /// se limpiaron ni se borraron acá. Limpiar en un teléfono no las borra
  /// de los demás.
  List<FamilyNotice> get visibleNotices {
    final cleared = _prefs.getInt(_kNoticesCleared);
    final since = store.now.subtract(const Duration(days: 30));
    final hidden = (_prefs.getStringList(_kNoticesHidden) ?? const []).toSet();
    return [
      for (final n in store.notices)
        if (n.time.isAfter(since) &&
            (cleared == null || n.time.millisecondsSinceEpoch > cleared) &&
            !hidden.contains(noticeKey(n)))
          n,
    ];
  }

  static String noticeKey(FamilyNotice n) => '${n.time.millisecondsSinceEpoch}|${n.text}';

  /// Saca estos avisos de la lista de este teléfono.
  Future<void> hideNotices(Iterable<FamilyNotice> notices) async {
    final hidden = [...?_prefs.getStringList(_kNoticesHidden), for (final n in notices) noticeKey(n)];
    // Se guardan los últimos 400 para no crecer sin fin.
    await _prefs.setStringList(_kNoticesHidden, hidden.length > 400 ? hidden.sublist(hidden.length - 400) : hidden);
    notifyListeners();
  }

  /// Limpia todas las novedades de este teléfono (las nuevas siguen llegando).
  Future<void> clearNotices() async {
    await _prefs.setInt(_kNoticesCleared, store.now.millisecondsSinceEpoch);
    await _prefs.remove(_kNoticesHidden);
    notifyListeners();
  }

  Future<void> markNoticesSeen() async {
    await _prefs.setInt(_kNoticesSeen, store.now.millisecondsSinceEpoch);
    notifyListeners();
  }

  /// Qué avisos del sistema muestra este teléfono.
  NotifyMode get notifyMode => NotifyMode.values.asNameMap()[_prefs.getString(_kNotifyMode)] ?? NotifyMode.important;

  Future<void> setNotifyMode(NotifyMode mode) async {
    await _prefs.setString(_kNotifyMode, mode.name);
    notifyListeners();
  }

  /// Si este aviso se muestra como notificación del sistema en este teléfono.
  bool shouldNotify(FamilyNotice n) {
    if (n.memberId != null && n.memberId == _viewerId) {
      // A los chicos sí les avisa cuando les aprueban un premio o una tarea.
      return n.kind == NoticeKind.approval && notifyMode != NotifyMode.none;
    }
    return switch (notifyMode) {
      NotifyMode.all => true,
      NotifyMode.important => n.isImportant,
      NotifyMode.none => false,
    };
  }

  // ------------------------------------------------------------- marcas

  /// Marcas simples de este teléfono (pasos hechos, carteles cerrados…).
  bool flag(String key) => _prefs.getBool('flag_$key') ?? false;

  Future<void> setFlag(String key, [bool value = true]) async {
    await _prefs.setBool('flag_$key', value);
    notifyListeners();
  }

  // -------------------------------------------------------------------- PIN

  /// PIN de 4 dígitos para abrir perfiles de adulto en este teléfono.
  /// Se guarda solo un resumen (hash), nunca el número.
  bool get hasPin => _prefs.getString(_kPin) != null;

  static String _hashPin(String pin) => sha256.convert(utf8.encode('family_app:pin:$pin')).toString();

  static final _pinPattern = RegExp(r'^\d{4}$');

  static bool isValidPin(String pin) => _pinPattern.hasMatch(pin);

  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) throw ArgumentError('El PIN tiene que tener 4 números');
    await _prefs.setString(_kPin, _hashPin(pin));
    notifyListeners();
  }

  Future<void> clearPin() async {
    await _prefs.remove(_kPin);
    notifyListeners();
  }

  bool checkPin(String pin) => !hasPin || _prefs.getString(_kPin) == _hashPin(pin);

  // ----------------------------------------------------------------- inicio

  /// Recupera el modo guardado y conecta lo necesario.
  Future<void> restore() async {
    storage.listen(store);
    // Primera vez en este teléfono: lo anterior no cuenta como novedad.
    if (_prefs.getInt(_kNoticesSeen) == null) {
      await _prefs.setInt(_kNoticesSeen, store.now.millisecondsSinceEpoch);
    }
    final saved = SessionMode.values.asNameMap()[_prefs.getString(_kMode)] ?? SessionMode.none;
    homeId = _prefs.getString(_kHome);
    deviceMemberId = _prefs.getString(_kMember);
    pendingApproval = _prefs.getBool(_kPending) ?? false;

    switch (saved) {
      case SessionMode.demo:
        _enterDemo();
      case SessionMode.cloud:
        if (cloud != null && homeId != null) {
          mode = SessionMode.cloud;
          if (!pendingApproval) {
            cloud!.attach(store, homeId!);
            if (deviceMemberId != null) store.signInAs(deviceMemberId!);
          }
        } else {
          mode = SessionMode.none;
        }
      case SessionMode.none:
        mode = SessionMode.none;
    }
    notifyListeners();
  }

  Future<void> _save() async {
    await _prefs.setString(_kMode, mode.name);
    if (homeId == null) {
      await _prefs.remove(_kHome);
    } else {
      await _prefs.setString(_kHome, homeId!);
    }
    if (deviceMemberId == null) {
      await _prefs.remove(_kMember);
    } else {
      await _prefs.setString(_kMember, deviceMemberId!);
    }
    await _prefs.setBool(_kPending, pendingApproval);
  }

  // ----------------------------------------------------------- demostración

  void _enterDemo() {
    cloud?.detach();
    mode = SessionMode.demo;
    storage.enabled = true;
    if (!storage.load(store)) store.resetToDemo();
  }

  /// Usa el hogar de ejemplo, guardado solo en este teléfono.
  Future<void> startDemo() async {
    _enterDemo();
    homeId = null;
    deviceMemberId = null;
    pendingApproval = false;
    await _save();
    notifyListeners();
  }

  // ------------------------------------------------------------------ nube

  FamilyCloud _requireCloud() {
    final c = cloud;
    if (c == null) {
      throw const JoinException('No hay conexión con el servidor. Revisá internet y volvé a abrir la app.');
    }
    return c;
  }

  void _leaveDemo() {
    storage.enabled = false;
    store.clearAll();
  }

  /// Crea un hogar nuevo con este teléfono como administrador.
  Future<void> createHome({required String homeName, required String nickname}) async {
    final c = _requireCloud();
    final ids = await c.createHome(homeName: homeName, nickname: nickname).timeout(const Duration(seconds: 20));
    _leaveDemo();
    mode = SessionMode.cloud;
    homeId = ids.homeId;
    deviceMemberId = ids.memberId;
    pendingApproval = false;
    store.applyRemote(homeName: homeName.trim());
    c.attach(store, ids.homeId);
    store.signInAs(ids.memberId);
    await _save();
    notifyListeners();
    onCloudLinked?.call();
  }

  /// Invitación para sumar a alguien: en la nube si está vinculado, local en la demo.
  Future<Invitation> createInvitation({required MemberRole role, AgeMode? ageMode, Member? relink}) {
    if (isCloud) {
      return _requireCloud().createInvite(homeId: homeId!, homeName: store.homeName, role: role, mode: ageMode, relink: relink);
    }
    return Future.value(store.createInvitation(role: role, mode: ageMode));
  }

  Future<Invitation> lookupInvite(String code) => _requireCloud().lookupInvite(code);

  // ------------------------------------------------------- familias amigas

  /// Miembros de este hogar como "amigos" para compartir (solo apodo y avatar).
  List<FriendKid> asFriendKids(Iterable<Member> members) => [
        for (final m in members) FriendKid(id: m.id, nickname: m.nickname, avatar: m.avatar),
      ];

  Future<String> createFriendInvite(List<Member> kids) =>
      _requireCloud().createFriendInvite(homeId: homeId!, homeName: store.homeName, kids: asFriendKids(kids));

  Future<({String homeId, String homeName})> lookupFriendInvite(String code) => _requireCloud().lookupFriendInvite(code);

  Future<void> acceptFriendInvite(String code, List<Member> kids) =>
      _requireCloud().acceptFriendInvite(code, homeName: store.homeName, kids: asFriendKids(kids));

  Future<void> setFriendKids(String friendshipId, List<Member> kids) =>
      _requireCloud().setFriendKids(friendshipId, asFriendKids(kids));

  Future<void> endFriendship(String friendshipId) => _requireCloud().endFriendship(friendshipId);

  /// Se une al hogar de la invitación; queda esperando la aprobación.
  Future<void> joinHome(Invitation invite, String nickname) async {
    final c = _requireCloud();
    final memberId = await c.joinHome(invite, nickname).timeout(const Duration(seconds: 20));
    cloud?.detach();
    _leaveDemo();
    mode = SessionMode.cloud;
    homeId = invite.homeId;
    deviceMemberId = memberId;
    pendingApproval = true;
    store.applyRemote(homeName: invite.homeName);
    await _save();
    notifyListeners();
  }

  /// `true` cuando un adulto aprueba; `null` si rechazó el alta.
  Stream<bool?> watchApproval() => _requireCloud().watchApproval(homeId!, deviceMemberId!);

  /// El adulto aprobó: empieza a sincronizar el hogar.
  Future<void> markApproved() async {
    pendingApproval = false;
    _requireCloud().attach(store, homeId!);
    store.signInAs(deviceMemberId!);
    await _save();
    notifyListeners();
    onCloudLinked?.call();
  }

  /// Desvincula este teléfono del hogar (los datos siguen en la nube).
  Future<void> leave() async {
    cloud?.detach();
    storage.enabled = false;
    store.clearAll();
    mode = SessionMode.none;
    homeId = null;
    deviceMemberId = null;
    pendingApproval = false;
    await _save();
    notifyListeners();
  }
}

/// Da acceso a la [AppSession] desde cualquier widget.
class SessionScope extends InheritedNotifier<AppSession> {
  const SessionScope({super.key, required AppSession session, required super.child})
      : super(notifier: session);

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope no encontrado en el árbol de widgets');
    return scope!.notifier!;
  }
}
