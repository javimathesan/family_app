import 'dart:async';

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

  SessionMode mode = SessionMode.none;
  String? homeId;

  /// Perfil de la persona que usa este teléfono.
  String? deviceMemberId;

  /// Se unió con una invitación y espera que un adulto lo apruebe.
  bool pendingApproval = false;

  bool get cloudAvailable => cloud != null;
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

  // ----------------------------------------------------------------- inicio

  /// Recupera el modo guardado y conecta lo necesario.
  Future<void> restore() async {
    storage.listen(store);
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
  }

  /// Invitación para sumar a alguien: en la nube si está vinculado, local en la demo.
  Future<Invitation> createInvitation({required MemberRole role, AgeMode? ageMode}) {
    if (isCloud) {
      return _requireCloud().createInvite(homeId: homeId!, homeName: store.homeName, role: role, mode: ageMode);
    }
    return Future.value(store.createInvitation(role: role, mode: ageMode));
  }

  Future<Invitation> lookupInvite(String code) => _requireCloud().lookupInvite(code);

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
