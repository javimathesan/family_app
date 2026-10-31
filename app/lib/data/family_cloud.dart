import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'family_store.dart';
import 'family_sync.dart';

/// Error que se le muestra a la persona al unirse a un hogar.
class JoinException implements Exception {
  const JoinException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Hogar compartido en Cloud Firestore.
///
/// Estructura:
/// - `invites/{code}`: invitación de un solo uso (hogar, rol, vencimiento).
/// - `homes/{homeId}`: nombre, adminUids y memberUids (teléfonos aprobados).
/// - `homes/{homeId}/members/{memberId}`: perfil, puntos y si está pendiente.
/// - `homes/{homeId}/days/{memberId}_{día}`: tareas hechas y salud del día.
/// - `homes/{homeId}/redemptions/{id}` y `homes/{homeId}/notices/{id}`.
class FamilyCloud implements FamilySync {
  FamilyCloud({required this.db, required this.uid, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final FirebaseFirestore db;

  /// Usuario anónimo de Firebase de este teléfono.
  final String uid;
  final DateTime Function() _clock;
  final _random = Random();

  String? _homeId;
  FamilyStore? _store;
  final List<StreamSubscription<dynamic>> _subs = [];

  /// Días de historial que se cargan para el calendario.
  static const historyDays = 35;

  String? get homeId => _homeId;
  bool get isAttached => _store != null;

  /// Inicia Firebase y la sesión anónima de este teléfono. Devuelve `null`
  /// si Firebase no está configurado (falta google-services.json) o si no
  /// hay conexión la primera vez: la app sigue funcionando sin la nube.
  static Future<FamilyCloud?> connect() async {
    try {
      await Firebase.initializeApp();
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser ??
          (await auth.signInAnonymously().timeout(const Duration(seconds: 15))).user;
      if (user == null) return null;
      return FamilyCloud(db: FirebaseFirestore.instance, uid: user.uid);
    } catch (error) {
      debugPrint('Family App sin conexión con la nube: $error');
      return null;
    }
  }

  // ------------------------------------------------------------- referencias

  DocumentReference<Map<String, dynamic>> _homeRef(String id) => db.collection('homes').doc(id);
  CollectionReference<Map<String, dynamic>> _members(String home) => _homeRef(home).collection('members');
  CollectionReference<Map<String, dynamic>> _days(String home) => _homeRef(home).collection('days');
  CollectionReference<Map<String, dynamic>> _redemptions(String home) => _homeRef(home).collection('redemptions');
  CollectionReference<Map<String, dynamic>> _notices(String home) => _homeRef(home).collection('notices');
  CollectionReference<Map<String, dynamic>> _games(String home) => _homeRef(home).collection('games');
  CollectionReference<Map<String, dynamic>> _events(String home) => _homeRef(home).collection('events');

  String _newMemberId() =>
      'm${_clock().microsecondsSinceEpoch.toRadixString(36)}${_random.nextInt(1296).toRadixString(36)}';

  Map<String, dynamic> _memberData(Member m, {required bool pending, String? inviteCode}) => {
        'nickname': m.nickname,
        'role': m.role.name,
        'mode': m.mode?.name,
        'accent': m.accent.toARGB32(),
        'avatar': FamilyStore.avatarToJson(m.avatar),
        'uid': m.uid,
        'unlocked': m.unlocked.toList(),
        'pending': pending,
        if (inviteCode != null) 'inviteCode': inviteCode,
        'balance': 0,
        'piggy': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

  // --------------------------------------------------------- hogar y altas

  /// Crea un hogar con este teléfono como administrador. Devuelve los ids.
  Future<({String homeId, String memberId})> createHome({
    required String homeName,
    required String nickname,
  }) async {
    final home = db.collection('homes').doc();
    await home.set({
      'name': homeName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'adminUids': [uid],
      'memberUids': [uid],
      'templates': [for (final t in FamilyStore.defaultTemplates) FamilyStore.templateToJson(t)],
      'rewards': [for (final r in FamilyStore.defaultRewards) FamilyStore.rewardToJson(r)],
    });
    final memberId = _newMemberId();
    final admin = Member(id: memberId, nickname: nickname, role: MemberRole.admin, uid: uid);
    await _members(home.id).doc(memberId).set(_memberData(admin, pending: false));
    return (homeId: home.id, memberId: memberId);
  }

  /// Crea una invitación de un solo uso para el hogar actual.
  Future<Invitation> createInvite({
    required String homeId,
    required String homeName,
    required MemberRole role,
    AgeMode? mode,
    Member? relink,
  }) async {
    if (relink != null && relink.uid != null) {
      // El teléfono viejo deja de tener acceso al hogar.
      await _homeRef(homeId).update({
        'memberUids': FieldValue.arrayRemove([relink.uid]),
        'adminUids': FieldValue.arrayRemove([relink.uid]),
      });
    }
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = Invitation.randomCode(_random);
      final ref = db.collection('invites').doc(code);
      if ((await ref.get()).exists) continue;
      final expiresAt = _clock().add(Invitation.lifetime);
      await ref.set({
        'homeId': homeId,
        'homeName': homeName,
        'role': role.name,
        'mode': mode?.name,
        'createdBy': uid,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'usedBy': null,
        if (relink != null) 'memberId': relink.id,
        if (relink != null) 'memberName': relink.nickname,
      });
      return Invitation(
        code: code,
        role: role,
        mode: mode,
        expiresAt: expiresAt,
        homeId: homeId,
        homeName: homeName,
        memberId: relink?.id,
        memberName: relink?.nickname,
      );
    }
    throw const JoinException('No se pudo generar un código. Probá de nuevo.');
  }

  /// Busca una invitación por código y verifica que siga vigente.
  Future<Invitation> lookupInvite(String code) async {
    final DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await db.collection('invites').doc(code).get();
    } on FirebaseException catch (error) {
      throw JoinException('No se pudo consultar la invitación (${error.code}). Revisá la conexión.');
    }
    final data = snap.data();
    if (!snap.exists || data == null) {
      throw const JoinException('Ese código no existe. Revisá que esté bien escrito.');
    }
    final usedBy = data['usedBy'] as String?;
    if (usedBy != null && usedBy != uid) {
      throw const JoinException('Esa invitación ya se usó. Pedile al adulto un código nuevo.');
    }
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    if (expiresAt.isBefore(_clock())) {
      throw const JoinException('La invitación venció. Pedile al adulto un código nuevo.');
    }
    return Invitation(
      code: code,
      role: MemberRole.values.byName(data['role'] as String),
      mode: data['mode'] == null ? null : AgeMode.values.byName(data['mode'] as String),
      expiresAt: expiresAt,
      homeId: data['homeId'] as String,
      homeName: data['homeName'] as String? ?? 'tu hogar',
      memberId: data['memberId'] as String?,
      memberName: data['memberName'] as String?,
    );
  }

  /// Se suma al hogar de la invitación como miembro pendiente de aprobación.
  Future<String> joinHome(Invitation invite, String nickname) async {
    final homeId = invite.homeId!;
    if (invite.isRelink) {
      // Vuelve a entrar con su perfil de siempre (puntos, avatar, historial).
      final batch = db.batch()
        ..update(db.collection('invites').doc(invite.code), {'usedBy': uid})
        ..update(_members(homeId).doc(invite.memberId), {
          'uid': uid,
          'pending': true,
          'relink': true,
          'inviteCode': invite.code,
        });
      await batch.commit();
      return invite.memberId!;
    }
    final memberId = _newMemberId();
    final member = Member(id: memberId, nickname: nickname.trim(), role: invite.role, mode: invite.mode, uid: uid);
    final batch = db.batch()
      ..update(db.collection('invites').doc(invite.code), {'usedBy': uid})
      ..set(_members(homeId).doc(memberId), _memberData(member, pending: true, inviteCode: invite.code));
    await batch.commit();
    return memberId;
  }

  /// Avisa cuando un adulto aprueba (`true`) o rechaza (`null`, perfil borrado).
  Stream<bool?> watchApproval(String homeId, String memberId) {
    return _members(homeId).doc(memberId).snapshots().map((snap) {
      if (!snap.exists) return null;
      // Si rechazaron el teléfono nuevo, el perfil ya no apunta a este teléfono.
      if (snap.data()?['uid'] != uid) return null;
      return snap.data()?['pending'] != true;
    });
  }

  // ------------------------------------------------------------ sincronizar

  /// Conecta el [store] con el hogar: escucha los cambios del servidor y
  /// envía los cambios locales.
  void attach(FamilyStore store, String homeId) {
    detach();
    _homeId = homeId;
    _store = store;
    store.sync = this;

    void onError(Object error) => debugPrint('Error de sincronización: $error');

    _subs.add(_homeRef(homeId).snapshots().listen((snap) {
      final data = snap.data();
      if (data == null) return;
      final templates = data['templates'];
      final rewards = data['rewards'];
      store.applyRemote(
        homeName: data['name'] as String?,
        templates: templates is List
            ? [for (final t in templates) FamilyStore.templateFromJson((t as Map).cast<String, dynamic>())]
            : null,
        rewards: rewards is List
            ? [for (final r in rewards) FamilyStore.rewardFromJson((r as Map).cast<String, dynamic>())]
            : null,
        gamesRule: GamesRule.values.asNameMap()[data['gamesRule']],
        gamesMinutes: (data['gamesMinutes'] as num?)?.toInt(),
        plus: data['plus'] == true,
        challenge: WeeklyChallenge.fromJson(data['challenge']),
        clearChallenge: data['challenge'] == null,
        crest: FamilyCrest.fromJson(data['crest']),
        languages: data['languages'] is List ? (data['languages'] as List).cast<String>() : null,
      );
    }, onError: onError));

    _subs.add(_members(homeId).snapshots().listen((snap) {
      final members = <Member>[];
      final pending = <String>{};
      final relinking = <String>{};
      final balances = <String, int>{};
      final piggy = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        members.add(FamilyStore.memberFromJson({...data, 'id': doc.id}));
        if (data['pending'] == true) pending.add(doc.id);
        if (data['pending'] == true && data['relink'] == true) relinking.add(doc.id);
        balances[doc.id] = (data['balance'] as num?)?.toInt() ?? 0;
        piggy[doc.id] = (data['piggy'] as num?)?.toInt() ?? 0;
      }
      store.applyRemote(members: members, pendingMembers: pending, relinking: relinking, balances: balances, piggyBank: piggy);
    }, onError: onError));

    final since = FamilyStore.dayKey(_clock().subtract(const Duration(days: historyDays)));
    _subs.add(_days(homeId).where('day', isGreaterThanOrEqualTo: since).snapshots().listen((snap) {
      final todayKey = FamilyStore.dayKey(_clock());
      final today = <String, Map<String, TaskCompletion>>{};
      final health = <String, HealthLog>{};
      final history = <String, List<DaySummary>>{};
      final gameSeconds = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final memberId = data['memberId'] as String?;
        final day = data['day'] as String?;
        if (memberId == null || day == null) continue;
        final completions = _completionsFrom(data['completions']);
        final log = _healthFrom(data['health']);
        if (day == todayKey) {
          if (data['gameSeconds'] is num) gameSeconds[memberId] = (data['gameSeconds'] as num).toInt();
          today[memberId] = completions;
          if (log != null) health[memberId] = log;
        } else {
          history.putIfAbsent(memberId, () => []).add(store.summarizeDay(DateTime.parse(day), completions, log, memberId: memberId));
        }
      }
      for (final list in history.values) {
        list.sort((a, b) => a.date.compareTo(b.date));
      }
      store.applyRemote(today: today, health: health, history: history, gameSeconds: gameSeconds);
    }, onError: onError));

    _subs.add(_redemptions(homeId).snapshots().listen((snap) {
      store.applyRemote(redemptions: [
        for (final doc in snap.docs)
          Redemption(
            id: doc.id,
            memberId: doc.data()['memberId'] as String,
            rewardId: doc.data()['rewardId'] as String,
            requestedAt: (doc.data()['requestedAt'] as Timestamp).toDate(),
            status: RedemptionStatus.values.byName(doc.data()['status'] as String),
          ),
      ]);
    }, onError: onError));

    _subs.add(_notices(homeId).orderBy('time', descending: true).limit(150).snapshots().listen((snap) {
      store.applyRemote(notices: [
        for (final doc in snap.docs)
          FamilyStore.noticeFromJson(doc.data(), time: (doc.data()['time'] as Timestamp).toDate()),
      ]);
    }, onError: onError));

    // Agenda: desde hace 30 días en adelante.
    final agendaSince = _clock().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    _subs.add(_events(homeId).where('at', isGreaterThanOrEqualTo: agendaSince).snapshots().listen((snap) {
      store.applyRemote(events: [
        for (final doc in snap.docs) FamilyStore.eventFromJson({...doc.data(), 'id': doc.id}),
      ]);
    }, onError: onError));

    _subs.add(_games(homeId).orderBy('updatedAt', descending: true).limit(30).snapshots().listen((snap) {
      store.applyRemote(matches: [
        for (final doc in snap.docs)
          if (FamilyStore.matchFromJson({...doc.data(), 'id': doc.id}) case final match?) match,
      ]);
    }, onError: onError));
  }

  /// Deja de sincronizar (al desvincular el teléfono).
  void detach() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    if (_store?.sync == this) _store!.sync = null;
    _store = null;
    _homeId = null;
  }

  static Map<String, TaskCompletion> _completionsFrom(Object? raw) {
    if (raw is! Map) return {};
    return {
      for (final e in raw.entries)
        if (e.value is Map)
          e.key as String: TaskCompletion(
            taskId: e.key as String,
            completedAt: (e.value['at'] as Timestamp).toDate(),
            pointsAwarded: (e.value['pts'] as num).toInt(),
            pendingApproval: e.value['pending'] as bool? ?? false,
          ),
    };
  }

  static HealthLog? _healthFrom(Object? raw) {
    if (raw is! Map) return null;
    return HealthLog(
      glasses: (raw['glasses'] as num?)?.toInt() ?? 0,
      poop: raw['poop'] as bool? ?? false,
      pee: (raw['pee'] as num?)?.toInt() ?? 0,
      mood: raw['mood'] as String?,
    );
  }

  // ---------------------------------------------------- FamilySync (envíos)

  void _write(Future<void> Function(String homeId) action) {
    final home = _homeId;
    if (home == null) return;
    action(home).catchError((Object error) => debugPrint('No se pudo guardar en la nube: $error'));
  }

  @override
  void memberAdded(Member member) =>
      _write((h) => _members(h).doc(member.id).set(_memberData(member, pending: false)));

  @override
  void memberUpdated(Member member) => _write((h) => _members(h).doc(member.id).update({
        'nickname': member.nickname,
        'mode': member.mode?.name,
        'accent': member.accent.toARGB32(),
        'avatar': FamilyStore.avatarToJson(member.avatar),
        'unlocked': member.unlocked.toList(),
        'look': member.look.toJson(),
        'room': member.room,
        'progress': member.progress,
      }));

  @override
  void memberConfirmed(Member member) => _write((h) {
        final batch = db.batch()..update(_members(h).doc(member.id), {'pending': false, 'relink': FieldValue.delete()});
        final phone = member.uid;
        if (phone != null) {
          batch.update(_homeRef(h), {
            'memberUids': FieldValue.arrayUnion([phone]),
            if (member.role.canManage) 'adminUids': FieldValue.arrayUnion([phone]),
          });
        }
        return batch.commit();
      });

  @override
  void memberRemoved(Member member) => _write((h) {
        final batch = db.batch()..delete(_members(h).doc(member.id));
        final phone = member.uid;
        if (phone != null) {
          batch.update(_homeRef(h), {
            'memberUids': FieldValue.arrayRemove([phone]),
            'adminUids': FieldValue.arrayRemove([phone]),
          });
        }
        return batch.commit();
      });

  String _dayId(String memberId, String day) => '${memberId}_$day';

  @override
  void taskChanged(String memberId, String day, String taskId, TaskCompletion? completion) => _write((h) {
        final ref = _days(h).doc(_dayId(memberId, day));
        if (completion == null) {
          return ref.update({'completions.$taskId': FieldValue.delete()});
        }
        return ref.set({
          'memberId': memberId,
          'day': day,
          'completions': {
            taskId: {
              'at': Timestamp.fromDate(completion.completedAt),
              'pts': completion.pointsAwarded,
              'pending': completion.pendingApproval,
            },
          },
        }, SetOptions(merge: true));
      });

  @override
  void healthChanged(String memberId, String day, HealthLog log) => _write((h) => _days(h).doc(_dayId(memberId, day)).set({
        'memberId': memberId,
        'day': day,
        'health': {'glasses': log.glasses, 'poop': log.poop, 'pee': log.pee, 'mood': log.mood},
      }, SetOptions(merge: true)));

  @override
  void balanceChanged(String memberId, int delta) =>
      _write((h) => _members(h).doc(memberId).update({'balance': FieldValue.increment(delta)}));

  @override
  void redemptionSaved(Redemption redemption) => _write((h) => _redemptions(h).doc(redemption.id).set({
        'memberId': redemption.memberId,
        'rewardId': redemption.rewardId,
        'requestedAt': Timestamp.fromDate(redemption.requestedAt),
        'status': redemption.status.name,
      }));

  @override
  void noticeAdded(FamilyNotice notice) => _write((h) => _notices(h).add({
        ...FamilyStore.noticeToJson(notice, iso: false),
        'time': Timestamp.fromDate(notice.time),
      }));

  @override
  void routineChanged(List<TaskTemplate> templates) => _write((h) => _homeRef(h).update({
        'templates': [for (final t in templates) FamilyStore.templateToJson(t)],
      }));

  @override
  void rewardsChanged(List<Reward> rewards) => _write((h) => _homeRef(h).update({
        'rewards': [for (final r in rewards) FamilyStore.rewardToJson(r)],
      }));

  @override
  void matchSaved(GameMatch match) => _write((h) => _games(h).doc(match.id).set(FamilyStore.matchToJson(match)));

  @override
  void matchRemoved(String matchId) => _write((h) => _games(h).doc(matchId).delete());

  @override
  void gamesRuleChanged(GamesRule rule) => _write((h) => _homeRef(h).update({'gamesRule': rule.name}));

  @override
  void relinkCancelled(Member member) => _write((h) => _members(h).doc(member.id).update({
        'pending': false,
        'relink': FieldValue.delete(),
        'uid': null,
      }));

  @override
  void homeSettingsChanged(Map<String, dynamic> fields) => _write((h) => _homeRef(h).update(fields));

  @override
  void gameTimeChanged(String memberId, String day, int seconds) => _write((h) => _days(h).doc(_dayId(memberId, day)).set({
        'memberId': memberId,
        'day': day,
        'gameSeconds': seconds,
      }, SetOptions(merge: true)));

  @override
  void eventSaved(AgendaEvent event) => _write((h) => _events(h).doc(event.id).set(FamilyStore.eventToJson(event)));

  @override
  void eventRemoved(String eventId) => _write((h) => _events(h).doc(eventId).delete());

  @override
  void noticesDeleted(DateTime before) => _write((h) async {
        final old = await _notices(h).where('time', isLessThan: Timestamp.fromDate(before)).limit(450).get();
        final batch = db.batch();
        for (final doc in old.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      });
}
