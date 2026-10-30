import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/points.dart';
import '../models/models.dart';
import 'family_sync.dart';

/// Estado del hogar en memoria.
///
/// Es la fuente de datos de la UI. En modo demostración se guarda en el
/// teléfono ([toJson]); conectado a la nube, cada cambio se avisa a [sync] y
/// lo que llega de otros teléfonos entra por [applyRemote].
class FamilyStore extends ChangeNotifier {
  FamilyStore({
    required this.homeName,
    required List<Member> members,
    required List<TaskTemplate> templates,
    required List<Reward> rewards,
    Map<String, int>? balances,
    Map<String, int>? piggyBank,
    Map<String, List<DaySummary>>? history,
    List<FamilyNotice>? notices,
    DateTime Function()? clock,
  })  : _members = members,
        _templates = [...templates],
        _rewards = [...rewards],
        _balances = balances ?? {},
        _piggy = piggyBank ?? {},
        _history = history ?? {},
        _notices = notices ?? [],
        _clock = clock ?? DateTime.now;

  /// Hogar vacío con la rutina y los premios por defecto.
  factory FamilyStore.empty({String homeName = '', DateTime Function()? clock}) => FamilyStore(
        homeName: homeName,
        members: [],
        templates: defaultTemplates,
        rewards: defaultRewards,
        clock: clock,
      );

  String homeName;
  final List<Member> _members;
  final List<TaskTemplate> _templates;
  final List<Reward> _rewards;
  final Map<String, int> _balances;
  final Map<String, int> _piggy;
  final Map<String, List<DaySummary>> _history;
  final List<FamilyNotice> _notices;
  final DateTime Function() _clock;

  final Map<String, Map<String, TaskCompletion>> _today = {};
  final Map<String, HealthLog> _health = {};
  final List<Redemption> _redemptions = [];
  final Set<String> _pendingMembers = {};
  final _random = Random();

  /// Destino de los cambios locales cuando el hogar está en la nube.
  FamilySync? sync;

  String? _currentMemberId;

  static const waterGoal = 8;

  String get _todayKey => dayKey(_clock());

  // ---------------------------------------------------------------- miembros

  List<Member> get members => List.unmodifiable(_members);
  List<Member> get children => _members.where((m) => m.role == MemberRole.child).toList();

  Member? get currentMember =>
      _currentMemberId == null ? null : memberById(_currentMemberId!);

  Member? memberById(String id) {
    for (final m in _members) {
      if (m.id == id) return m;
    }
    return null;
  }

  void signInAs(String memberId) {
    _currentMemberId = memberId;
    notifyListeners();
  }

  void updateAvatar(String memberId, AvatarConfig avatar) {
    final m = memberById(memberId);
    if (m == null) return;
    m.avatar = avatar;
    sync?.memberUpdated(m);
    notifyListeners();
  }

  void setAccent(String memberId, Color accent) {
    final m = memberById(memberId);
    if (m == null) return;
    m.accent = accent;
    sync?.memberUpdated(m);
    notifyListeners();
  }

  bool hasUnlocked(String memberId, String itemId) =>
      memberById(memberId)?.unlocked.contains(itemId) ?? false;

  /// Desbloquea un disfraz o accesorio pagando con puntos.
  /// Devuelve `false` si ya lo tenía o no le alcanzan los puntos.
  bool unlockItem(String memberId, String itemId, int cost) {
    final m = memberById(memberId);
    if (m == null || m.unlocked.contains(itemId) || balanceOf(memberId) < cost) return false;
    _addBalance(memberId, -cost);
    m.unlocked.add(itemId);
    sync?.memberUpdated(m);
    _addNotice('${m.nickname} desbloqueó algo nuevo para su avatar');
    notifyListeners();
    return true;
  }

  String _newId(String prefix) => '$prefix${_clock().microsecondsSinceEpoch.toRadixString(36)}${_random.nextInt(1296).toRadixString(36)}';

  /// Agrega un miembro aprobado, por ejemplo un hijo sin celular propio que
  /// se maneja desde el teléfono de un adulto.
  Member addMember({required String nickname, required MemberRole role, AgeMode? mode, String? uid}) {
    final member = Member(id: _newId('m'), nickname: nickname.trim(), role: role, mode: mode, uid: uid);
    _members.add(member);
    sync?.memberAdded(member);
    notifyListeners();
    return member;
  }

  /// Alta pendiente en modo demostración (en la nube la crea quien escanea).
  Member addPendingMember({required String nickname, required MemberRole role, AgeMode? mode}) {
    final member = Member(id: _newId('m'), nickname: nickname.trim(), role: role, mode: mode);
    _members.add(member);
    _pendingMembers.add(member.id);
    _addNotice('${member.nickname} quiere unirse al hogar');
    notifyListeners();
    return member;
  }

  bool isPendingMember(String id) => _pendingMembers.contains(id);

  void confirmMember(String id) {
    final m = memberById(id);
    if (m == null || !_pendingMembers.remove(id)) return;
    sync?.memberConfirmed(m);
    notifyListeners();
  }

  /// Rechaza un alta pendiente o quita a un miembro del hogar.
  void removeMember(String id) {
    final m = memberById(id);
    if (m == null) return;
    _members.remove(m);
    _pendingMembers.remove(id);
    sync?.memberRemoved(m);
    notifyListeners();
  }

  // ------------------------------------------------------------- invitaciones

  /// Código de invitación local (modo demostración). Vence a los 15 minutos.
  Invitation createInvitation({required MemberRole role, AgeMode? mode}) {
    return Invitation(
      code: Invitation.randomCode(_random),
      role: role,
      mode: mode,
      expiresAt: _clock().add(Invitation.lifetime),
      homeName: homeName,
    );
  }

  // ----------------------------------------------------------------- rutina

  List<TaskTemplate> get templates => List.unmodifiable(_templates);

  List<TaskTemplate> tasksFor(DayBlock block) =>
      _templates.where((t) => t.block == block).toList();

  bool isDone(String memberId, String taskId) => _today[memberId]?.containsKey(taskId) ?? false;

  TaskCompletion? completionOf(String memberId, String taskId) => _today[memberId]?[taskId];

  /// Marca o desmarca una tarea. Devuelve los puntos otorgados (0 si se desmarcó).
  int toggleTask(String memberId, String taskId) {
    final day = _today.putIfAbsent(memberId, () => {});
    final existing = day.remove(taskId);
    if (existing != null) {
      if (!existing.pendingApproval) _addBalance(memberId, -existing.pointsAwarded);
      sync?.taskChanged(memberId, _todayKey, taskId, null);
      notifyListeners();
      return 0;
    }
    final task = _templates.firstWhere((t) => t.id == taskId);
    final now = _clock();
    final points = PointsRules.pointsFor(task, now);
    final needsAdult = task.validation != Validation.self;
    final completion = TaskCompletion(
      taskId: taskId,
      completedAt: now,
      pointsAwarded: points,
      pendingApproval: needsAdult,
    );
    day[taskId] = completion;
    sync?.taskChanged(memberId, _todayKey, taskId, completion);
    if (!needsAdult) _addBalance(memberId, points);
    final who = memberById(memberId)?.nickname ?? 'Alguien';
    _addNotice('$who completó: ${task.name}');
    notifyListeners();
    return points;
  }

  /// Tareas con foto o validación de adulto que esperan aprobación.
  List<({Member member, TaskTemplate task})> get pendingTaskApprovals {
    final result = <({Member member, TaskTemplate task})>[];
    _today.forEach((memberId, day) {
      final member = memberById(memberId);
      if (member == null) return;
      for (final c in day.values.where((c) => c.pendingApproval)) {
        final task = _templateById(c.taskId);
        if (task != null) result.add((member: member, task: task));
      }
    });
    return result;
  }

  TaskTemplate? _templateById(String id) {
    for (final t in _templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  void approveTask(String memberId, String taskId) {
    final c = _today[memberId]?[taskId];
    if (c == null || !c.pendingApproval) return;
    final approved = TaskCompletion(
      taskId: taskId,
      completedAt: c.completedAt,
      pointsAwarded: c.pointsAwarded,
    );
    _today[memberId]![taskId] = approved;
    sync?.taskChanged(memberId, _todayKey, taskId, approved);
    _addBalance(memberId, c.pointsAwarded);
    notifyListeners();
  }

  void rejectTask(String memberId, String taskId) {
    if (_today[memberId]?.remove(taskId) == null) return;
    sync?.taskChanged(memberId, _todayKey, taskId, null);
    notifyListeners();
  }

  int pointsToday(String memberId) => (_today[memberId]?.values ?? const <TaskCompletion>[])
      .where((c) => !c.pendingApproval)
      .fold(0, (sum, c) => sum + c.pointsAwarded);

  int doneToday(String memberId) => _today[memberId]?.length ?? 0;

  double completionRatio(String memberId) =>
      _templates.isEmpty ? 0 : doneToday(memberId) / _templates.length;

  /// Próxima tarea sin hacer a partir de la hora actual.
  TaskTemplate? nextTask(String memberId) {
    final now = TimeOfDay.fromDateTime(_clock());
    final pending = _templates.where((t) => !isDone(memberId, t.id)).toList()
      ..sort((a, b) => _minutes(a.time).compareTo(_minutes(b.time)));
    for (final t in pending) {
      if (_minutes(t.time) + t.windowMinutes >= _minutes(now)) return t;
    }
    return pending.isEmpty ? null : pending.first;
  }

  static int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  // ---------------------------------------------------- editar la rutina

  String newTemplateId() => _newId('t');
  String newRewardId() => _newId('p');

  static int _byTime(TaskTemplate a, TaskTemplate b) => _minutes(a.time).compareTo(_minutes(b.time));

  /// Crea o actualiza una tarea de la rutina (solo adultos).
  void saveTemplate(TaskTemplate template) {
    final i = _templates.indexWhere((t) => t.id == template.id);
    if (i >= 0) {
      _templates[i] = template;
    } else {
      _templates.add(template);
    }
    _templates.sort(_byTime);
    sync?.routineChanged(List.unmodifiable(_templates));
    notifyListeners();
  }

  void removeTemplate(String id) {
    final before = _templates.length;
    _templates.removeWhere((t) => t.id == id);
    if (_templates.length == before) return;
    sync?.routineChanged(List.unmodifiable(_templates));
    notifyListeners();
  }

  /// Crea o actualiza un premio de la tienda (solo adultos).
  void saveReward(Reward reward) {
    final i = _rewards.indexWhere((r) => r.id == reward.id);
    if (i >= 0) {
      _rewards[i] = reward;
    } else {
      _rewards.add(reward);
    }
    _rewards.sort((a, b) => a.cost.compareTo(b.cost));
    sync?.rewardsChanged(List.unmodifiable(_rewards));
    notifyListeners();
  }

  void removeReward(String id) {
    final before = _rewards.length;
    _rewards.removeWhere((r) => r.id == id);
    if (_rewards.length == before) return;
    sync?.rewardsChanged(List.unmodifiable(_rewards));
    notifyListeners();
  }

  // ------------------------------------------------------------------ salud

  HealthLog healthOf(String memberId) => _health.putIfAbsent(memberId, HealthLog.new);

  void addGlass(String memberId) {
    final log = healthOf(memberId);
    if (log.glasses >= waterGoal) return;
    log.glasses++;
    sync?.healthChanged(memberId, _todayKey, log);
    if (HealthRules.reachedWaterGoal(log.glasses, waterGoal)) {
      _addBalance(memberId, 5);
      final who = memberById(memberId)?.nickname ?? 'Alguien';
      _addNotice('$who llegó a su meta de agua');
    }
    notifyListeners();
  }

  void togglePoop(String memberId) {
    final log = healthOf(memberId);
    log.poop = !log.poop;
    sync?.healthChanged(memberId, _todayKey, log);
    notifyListeners();
  }

  void addPee(String memberId) {
    final log = healthOf(memberId);
    log.pee++;
    sync?.healthChanged(memberId, _todayKey, log);
    notifyListeners();
  }

  void setMood(String memberId, String mood) {
    final log = healthOf(memberId);
    log.mood = mood;
    sync?.healthChanged(memberId, _todayKey, log);
    notifyListeners();
  }

  // ---------------------------------------------------------------- premios

  List<Reward> get rewards => List.unmodifiable(_rewards);
  int balanceOf(String memberId) => _balances[memberId] ?? 0;
  int piggyOf(String memberId) => _piggy[memberId] ?? 0;

  void _addBalance(String memberId, int delta) {
    final before = balanceOf(memberId);
    final after = max(0, before + delta);
    _balances[memberId] = after;
    if (after != before) sync?.balanceChanged(memberId, after - before);
  }

  void _addNotice(String text, {bool alert = false}) {
    final notice = FamilyNotice(time: _clock(), text: text, isAlert: alert);
    _notices.insert(0, notice);
    sync?.noticeAdded(notice);
  }

  List<Redemption> redemptionsOf(String memberId) =>
      _redemptions.where((r) => r.memberId == memberId).toList();

  List<Redemption> get pendingRedemptions =>
      _redemptions.where((r) => r.status == RedemptionStatus.pending).toList();

  bool hasPendingRedemption(String memberId, String rewardId) => _redemptions.any(
        (r) => r.memberId == memberId && r.rewardId == rewardId && r.status == RedemptionStatus.pending,
      );

  /// El hijo pide un premio: se descuentan los puntos y queda pendiente.
  bool requestReward(String memberId, String rewardId) {
    final reward = rewardById(rewardId);
    if (reward == null || !PointsRules.canRedeem(balance: balanceOf(memberId), reward: reward)) return false;
    _addBalance(memberId, -reward.cost);
    final redemption = Redemption(
      id: _newId('r'),
      memberId: memberId,
      rewardId: rewardId,
      requestedAt: _clock(),
    );
    _redemptions.add(redemption);
    sync?.redemptionSaved(redemption);
    notifyListeners();
    return true;
  }

  void approveRedemption(String redemptionId) {
    final r = _redemptionById(redemptionId);
    if (r == null || r.status != RedemptionStatus.pending) return;
    r.status = RedemptionStatus.approved;
    sync?.redemptionSaved(r);
    notifyListeners();
  }

  /// Si el adulto rechaza, se devuelven los puntos.
  void rejectRedemption(String redemptionId) {
    final r = _redemptionById(redemptionId);
    if (r == null || r.status != RedemptionStatus.pending) return;
    r.status = RedemptionStatus.rejected;
    sync?.redemptionSaved(r);
    final reward = rewardById(r.rewardId);
    if (reward != null) _addBalance(r.memberId, reward.cost);
    notifyListeners();
  }

  Redemption? _redemptionById(String id) {
    for (final r in _redemptions) {
      if (r.id == id) return r;
    }
    return null;
  }

  Reward? rewardById(String id) {
    for (final r in _rewards) {
      if (r.id == id) return r;
    }
    return null;
  }

  // ------------------------------------------------------- calendario/avisos

  List<DaySummary> historyOf(String memberId) => List.unmodifiable(_history[memberId] ?? const []);

  List<FamilyNotice> get notices => List.unmodifiable(_notices);

  DateTime get now => _clock();

  /// Resumen de un día terminado para el calendario de caritas.
  DaySummary summarizeDay(DateTime date, Map<String, TaskCompletion> done, HealthLog? log) => DaySummary(
        date: date,
        completionRatio: _templates.isEmpty ? 0 : (done.length / _templates.length).clamp(0, 1).toDouble(),
        points: done.values.where((c) => !c.pendingApproval).fold(0, (sum, c) => sum + c.pointsAwarded),
        glasses: log?.glasses ?? 0,
        mood: log?.mood,
      );

  // ------------------------------------------------------------- nube

  /// Reemplaza datos con lo que llegó del servidor. No vuelve a avisar a [sync].
  void applyRemote({
    String? homeName,
    List<Member>? members,
    Set<String>? pendingMembers,
    Map<String, int>? balances,
    Map<String, int>? piggyBank,
    Map<String, Map<String, TaskCompletion>>? today,
    Map<String, HealthLog>? health,
    Map<String, List<DaySummary>>? history,
    List<Redemption>? redemptions,
    List<FamilyNotice>? notices,
    List<TaskTemplate>? templates,
    List<Reward>? rewards,
  }) {
    if (homeName != null) this.homeName = homeName;
    if (templates != null) {
      _templates
        ..clear()
        ..addAll(templates)
        ..sort(_byTime);
    }
    if (rewards != null) {
      _rewards
        ..clear()
        ..addAll(rewards)
        ..sort((a, b) => a.cost.compareTo(b.cost));
    }
    if (members != null) {
      _members
        ..clear()
        ..addAll(members);
    }
    if (pendingMembers != null) {
      _pendingMembers
        ..clear()
        ..addAll(pendingMembers);
    }
    if (balances != null) {
      _balances
        ..clear()
        ..addAll(balances);
    }
    if (piggyBank != null) {
      _piggy
        ..clear()
        ..addAll(piggyBank);
    }
    if (today != null) {
      _today
        ..clear()
        ..addAll(today);
    }
    if (health != null) {
      _health
        ..clear()
        ..addAll(health);
    }
    if (history != null) {
      _history
        ..clear()
        ..addAll(history);
    }
    if (redemptions != null) {
      _redemptions
        ..clear()
        ..addAll(redemptions);
    }
    if (notices != null) {
      _notices
        ..clear()
        ..addAll(notices);
    }
    notifyListeners();
  }

  /// Deja el store vacío, listo para un hogar nuevo.
  void clearAll({String homeName = ''}) {
    _currentMemberId = null;
    applyRemote(
      homeName: homeName,
      members: const [],
      pendingMembers: const {},
      balances: const {},
      piggyBank: const {},
      today: const {},
      health: const {},
      history: const {},
      redemptions: const [],
      notices: const [],
      templates: defaultTemplates,
      rewards: defaultRewards,
    );
  }

  // ------------------------------------------------------------ persistencia

  /// Versión del formato guardado. Si cambia, los datos viejos se ignoran.
  static const schemaVersion = 1;

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Estado completo para guardar en el teléfono (modo demostración). Las
  /// plantillas de tareas y premios no se guardan: vienen de la configuración.
  Map<String, dynamic> toJson() => {
        'v': schemaVersion,
        'day': dayKey(_clock()),
        'homeName': homeName,
        'templates': [for (final t in _templates) templateToJson(t)],
        'rewards': [for (final r in _rewards) rewardToJson(r)],
        'members': [for (final m in _members) memberToJson(m)],
        'pending': _pendingMembers.toList(),
        'balances': _balances,
        'piggy': _piggy,
        'history': {
          for (final e in _history.entries) e.key: [for (final s in e.value) _summaryToJson(s)],
        },
        'notices': [
          for (final n in _notices.take(50))
            {'time': n.time.toIso8601String(), 'text': n.text, 'alert': n.isAlert},
        ],
        'redemptions': [
          for (final r in _redemptions)
            {
              'id': r.id,
              'member': r.memberId,
              'reward': r.rewardId,
              'at': r.requestedAt.toIso8601String(),
              'status': r.status.name,
            },
        ],
        'today': {
          for (final e in _today.entries)
            e.key: [
              for (final c in e.value.values)
                {
                  'task': c.taskId,
                  'at': c.completedAt.toIso8601String(),
                  'pts': c.pointsAwarded,
                  'pending': c.pendingApproval,
                },
            ],
        },
        'health': {
          for (final e in _health.entries)
            e.key: {'glasses': e.value.glasses, 'poop': e.value.poop, 'pee': e.value.pee, 'mood': e.value.mood},
        },
      };

  /// Restaura lo guardado. Si el guardado es de otro día, ese día se archiva
  /// en el calendario y la rutina de hoy arranca vacía.
  void restoreFrom(Map<String, dynamic> json) {
    if (json['v'] != schemaVersion) return;

    if (json['homeName'] is String) homeName = json['homeName'] as String;
    if (json['templates'] is List) {
      _templates
        ..clear()
        ..addAll([for (final t in json['templates'] as List) templateFromJson((t as Map).cast<String, dynamic>())])
        ..sort(_byTime);
    }
    if (json['rewards'] is List) {
      _rewards
        ..clear()
        ..addAll([for (final r in json['rewards'] as List) rewardFromJson((r as Map).cast<String, dynamic>())]);
    }
    _members
      ..clear()
      ..addAll([for (final m in json['members'] as List) memberFromJson(m as Map<String, dynamic>)]);
    _pendingMembers
      ..clear()
      ..addAll((json['pending'] as List).cast<String>());
    _balances
      ..clear()
      ..addAll((json['balances'] as Map).cast<String, int>());
    _piggy
      ..clear()
      ..addAll((json['piggy'] as Map).cast<String, int>());
    _history
      ..clear()
      ..addAll({
        for (final e in (json['history'] as Map).entries)
          e.key as String: [for (final s in e.value as List) _summaryFromJson(s as Map<String, dynamic>)],
      });
    _notices
      ..clear()
      ..addAll([
        for (final n in json['notices'] as List)
          FamilyNotice(
            time: DateTime.parse(n['time'] as String),
            text: n['text'] as String,
            isAlert: n['alert'] as bool,
          ),
      ]);
    _redemptions
      ..clear()
      ..addAll([
        for (final r in json['redemptions'] as List)
          Redemption(
            id: r['id'] as String,
            memberId: r['member'] as String,
            rewardId: r['reward'] as String,
            requestedAt: DateTime.parse(r['at'] as String),
            status: RedemptionStatus.values.byName(r['status'] as String),
          ),
      ]);

    final savedToday = <String, Map<String, TaskCompletion>>{
      for (final e in (json['today'] as Map).entries)
        e.key as String: {
          for (final c in e.value as List)
            c['task'] as String: TaskCompletion(
              taskId: c['task'] as String,
              completedAt: DateTime.parse(c['at'] as String),
              pointsAwarded: c['pts'] as int,
              pendingApproval: c['pending'] as bool,
            ),
        },
    };
    final savedHealth = <String, HealthLog>{
      for (final e in (json['health'] as Map).entries)
        e.key as String: HealthLog(
          glasses: e.value['glasses'] as int,
          poop: e.value['poop'] as bool,
          pee: e.value['pee'] as int,
          mood: e.value['mood'] as String?,
        ),
    };

    _today.clear();
    _health.clear();
    final savedDay = json['day'] as String;
    if (savedDay == dayKey(_clock())) {
      _today.addAll(savedToday);
      _health.addAll(savedHealth);
    } else {
      _archiveDay(DateTime.parse(savedDay), savedToday, savedHealth);
    }

    if (_currentMemberId != null && memberById(_currentMemberId!) == null) {
      _currentMemberId = null;
    }
    notifyListeners();
  }

  /// Pasa un día terminado al calendario de cada hijo.
  void _archiveDay(
    DateTime date,
    Map<String, Map<String, TaskCompletion>> completions,
    Map<String, HealthLog> health,
  ) {
    for (final child in children) {
      final done = completions[child.id] ?? const <String, TaskCompletion>{};
      final log = health[child.id];
      if (done.isEmpty && log == null) continue;
      final list = _history.putIfAbsent(child.id, () => []);
      if (list.any((s) => DateUtils.isSameDay(s.date, date))) continue;
      list.add(summarizeDay(date, done, log));
    }
  }

  /// Vuelve a los datos de ejemplo (útil para probar desde cero).
  void resetToDemo() {
    final demo = FamilyStore.demo(clock: _clock);
    _currentMemberId = null;
    restoreFrom(demo.toJson());
  }

  static Map<String, dynamic> memberToJson(Member m) => {
        'id': m.id,
        'nickname': m.nickname,
        'role': m.role.name,
        'mode': m.mode?.name,
        'accent': m.accent.toARGB32(),
        'uid': m.uid,
        'avatar': avatarToJson(m.avatar),
        'unlocked': m.unlocked.toList(),
      };

  static Map<String, dynamic> avatarToJson(AvatarConfig a) => {
        'skin': a.skin,
        'hairStyle': a.hairStyle,
        'hairColor': a.hairColor,
        'eyes': a.eyes,
        'glasses': a.glasses,
        'shirt': a.shirt,
        'accessory': a.accessory,
        'outfit': a.outfit,
      };

  static Member memberFromJson(Map<String, dynamic> j) {
    final a = (j['avatar'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return Member(
      id: j['id'] as String,
      nickname: j['nickname'] as String,
      role: MemberRole.values.byName(j['role'] as String),
      mode: j['mode'] == null ? null : AgeMode.values.byName(j['mode'] as String),
      accent: Color((j['accent'] as num?)?.toInt() ?? 0xFF2563EB),
      uid: j['uid'] as String?,
      unlocked: {...?(j['unlocked'] as List?)?.cast<String>()},
      avatar: AvatarConfig(
        skin: (a['skin'] as num?)?.toInt() ?? 1,
        hairStyle: (a['hairStyle'] as num?)?.toInt() ?? 0,
        hairColor: (a['hairColor'] as num?)?.toInt() ?? 1,
        eyes: (a['eyes'] as num?)?.toInt() ?? 0,
        glasses: a['glasses'] as bool? ?? false,
        shirt: (a['shirt'] as num?)?.toInt() ?? 0,
        accessory: (a['accessory'] as num?)?.toInt() ?? 0,
        outfit: (a['outfit'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  static Map<String, dynamic> templateToJson(TaskTemplate t) => {
        'id': t.id,
        'name': t.name,
        'block': t.block.name,
        'hour': t.time.hour,
        'minute': t.time.minute,
        'points': t.points,
        'validation': t.validation.name,
        'window': t.windowMinutes,
      };

  static TaskTemplate templateFromJson(Map<String, dynamic> j) => TaskTemplate(
        id: j['id'] as String,
        name: j['name'] as String,
        block: DayBlock.values.asNameMap()[j['block']] ?? DayBlock.morning,
        time: TimeOfDay(hour: (j['hour'] as num).toInt(), minute: (j['minute'] as num).toInt()),
        points: (j['points'] as num).toInt(),
        validation: Validation.values.asNameMap()[j['validation']] ?? Validation.self,
        windowMinutes: (j['window'] as num?)?.toInt() ?? 30,
      );

  static Map<String, dynamic> rewardToJson(Reward r) => {
        'id': r.id,
        'name': r.name,
        'cost': r.cost,
        'icon': r.iconKey,
        'monthly': r.monthly,
      };

  static Reward rewardFromJson(Map<String, dynamic> j) => Reward(
        id: j['id'] as String,
        name: j['name'] as String,
        cost: (j['cost'] as num).toInt(),
        iconKey: j['icon'] as String? ?? 'regalo',
        monthly: j['monthly'] as bool? ?? false,
      );

  static Map<String, dynamic> _summaryToJson(DaySummary s) => {
        'date': s.date.toIso8601String(),
        'ratio': s.completionRatio,
        'points': s.points,
        'glasses': s.glasses,
        'screen': s.screenMinutes,
        'mood': s.mood,
      };

  static DaySummary _summaryFromJson(Map<String, dynamic> j) => DaySummary(
        date: DateTime.parse(j['date'] as String),
        completionRatio: (j['ratio'] as num).toDouble(),
        points: j['points'] as int,
        glasses: j['glasses'] as int,
        screenMinutes: j['screen'] as int,
        mood: j['mood'] as String?,
      );

  // ----------------------------------------------------------- datos demo

  /// Rutina por defecto de un hogar nuevo.
  static final List<TaskTemplate> defaultTemplates = _buildDefaultTemplates();

  static List<TaskTemplate> _buildDefaultTemplates() {
    TimeOfDay t(int h, int m) => TimeOfDay(hour: h, minute: m);
    return [
      TaskTemplate(id: 'levantarse', name: 'Levantarme', block: DayBlock.morning, time: t(7, 0), points: 5),
      TaskTemplate(id: 'aseo', name: 'Aseo personal', block: DayBlock.morning, time: t(7, 10), points: 5),
      TaskTemplate(id: 'cama', name: 'Tender la cama', block: DayBlock.morning, time: t(7, 20), points: 5, validation: Validation.photo),
      TaskTemplate(id: 'desayuno', name: 'Desayunar', block: DayBlock.morning, time: t(7, 30), points: 5),
      TaskTemplate(id: 'mesa', name: 'Recoger la mesa', block: DayBlock.morning, time: t(7, 45), points: 3),
      TaskTemplate(id: 'vajilla', name: 'Lavar mi vajilla', block: DayBlock.morning, time: t(7, 50), points: 5, validation: Validation.adult),
      TaskTemplate(id: 'dientes_am', name: 'Cepillarme los dientes', block: DayBlock.morning, time: t(7, 55), points: 5),
      TaskTemplate(id: 'utiles', name: 'Útiles del colegio listos', block: DayBlock.morning, time: t(8, 0), points: 5),
      TaskTemplate(id: 'entrada', name: 'Entrar al colegio a horario', block: DayBlock.school, time: t(8, 15), points: 10),
      TaskTemplate(id: 'salida', name: 'Salida del colegio', block: DayBlock.school, time: t(13, 0), points: 5),
      TaskTemplate(id: 'deporte', name: 'Actividad extracurricular', block: DayBlock.afternoon, time: t(15, 0), points: 10, windowMinutes: 60),
      TaskTemplate(id: 'llegar', name: 'Llegar a casa', block: DayBlock.afternoon, time: t(17, 0), points: 5),
      TaskTemplate(id: 'banio', name: 'Bañarme', block: DayBlock.afternoon, time: t(17, 30), points: 5),
      TaskTemplate(id: 'estudiar', name: 'Estudiar / repasar', block: DayBlock.night, time: t(18, 0), points: 10, windowMinutes: 120),
      TaskTemplate(id: 'cena', name: 'Comer, recoger y lavar', block: DayBlock.night, time: t(20, 0), points: 8, windowMinutes: 60),
      TaskTemplate(id: 'dientes_pm', name: 'Cepillarme los dientes', block: DayBlock.night, time: t(21, 0), points: 5),
    ];
  }

  /// Premios por defecto de un hogar nuevo.
  static const List<Reward> defaultRewards = [
    Reward(id: 'helado', name: 'Helado', cost: 50, iconKey: 'helado'),
    Reward(id: 'peli', name: 'Elijo la película del sábado', cost: 60, iconKey: 'pelicula'),
    Reward(id: 'pantalla', name: '1 hora extra de pantalla', cost: 80, iconKey: 'pantalla'),
    Reward(id: 'salida', name: 'Salida especial', cost: 150, iconKey: 'paseo'),
    Reward(id: 'libre', name: 'Pase libre: finde sin tareas', cost: 300, iconKey: 'libre'),
  ];

  /// Hogar de ejemplo con los mismos datos que las maquetas.
  factory FamilyStore.demo({DateTime Function()? clock}) {
    final members = [
      Member(id: 'adulto', nickname: 'Papá', role: MemberRole.admin),
      Member(
        id: 'tomi',
        nickname: 'Tomi',
        role: MemberRole.child,
        mode: AgeMode.junior,
        avatar: const AvatarConfig(skin: 1, hairStyle: 0, hairColor: 1, shirt: 0),
      ),
      Member(
        id: 'luli',
        nickname: 'Luli',
        role: MemberRole.child,
        mode: AgeMode.peques,
        avatar: const AvatarConfig(skin: 2, hairStyle: 2, hairColor: 0, shirt: 4, eyes: 1),
        accent: const Color(0xFF7C3AED),
      ),
      Member(
        id: 'mati',
        nickname: 'Mati',
        role: MemberRole.child,
        mode: AgeMode.teen,
        avatar: const AvatarConfig(skin: 3, hairStyle: 4, hairColor: 0, shirt: 1, accessory: 3),
        accent: const Color(0xFF0F766E),
      ),
    ];

    final today = (clock ?? DateTime.now)();
    const levels = [1.0, .85, .85, 1.0, .6, 1.0, 1.0, .9, 1.0, 1.0, .3, .85, 1.0, 1.0, .9, 1.0, 1.0, .55, .8, 1.0, 1.0, .85, 1.0, 1.0, 1.0, .6, .8, 1.0];
    const moods = ['Contento', 'Tranquilo', 'Cansado'];
    List<DaySummary> buildHistory(int shift) => [
          for (var i = 0; i < 28; i++)
            DaySummary(
              date: DateTime(today.year, today.month, today.day).subtract(Duration(days: 28 - i)),
              completionRatio: levels[(i + shift) % levels.length],
              points: (levels[(i + shift) % levels.length] * 118).round(),
              glasses: (levels[(i + shift) % levels.length] * 8).round(),
              screenMinutes: 180 - (levels[(i + shift) % levels.length] * 105).round(),
              mood: moods[(i + shift) % moods.length],
            ),
        ];

    final store = FamilyStore(
      homeName: 'Hogar Los Girasoles',
      members: members,
      templates: defaultTemplates,
      rewards: defaultRewards,
      balances: {'tomi': 210, 'luli': 140, 'mati': 95},
      piggyBank: {'tomi': 640, 'luli': 420, 'mati': 310},
      history: {'tomi': buildHistory(0), 'luli': buildHistory(5), 'mati': buildHistory(11)},
      notices: [
        FamilyNotice(time: today.subtract(const Duration(minutes: 40)), text: 'Tomi salió del colegio a horario'),
        FamilyNotice(time: today.subtract(const Duration(hours: 1)), text: 'Luli llegó a su meta de agua'),
        FamilyNotice(time: today.subtract(const Duration(hours: 2)), text: 'Mati lleva 2 días sin registrar popó', isAlert: true),
      ],
      clock: clock,
    );
    store._health['tomi'] = HealthLog(glasses: 4, pee: 3);
    store._health['luli'] = HealthLog(glasses: 8, poop: true, pee: 4);
    return store;
  }
}

/// Invitación por QR, de un solo uso.
@immutable
class Invitation {
  const Invitation({
    required this.code,
    required this.role,
    required this.expiresAt,
    this.mode,
    this.homeId,
    this.homeName = '',
  });

  final String code;
  final MemberRole role;
  final AgeMode? mode;
  final DateTime expiresAt;

  /// Hogar al que invita (solo en la nube).
  final String? homeId;
  final String homeName;

  static const lifetime = Duration(minutes: 15);

  /// Contenido del QR. No incluye datos personales: solo el código.
  /// Escaneado con la cámara del teléfono, abre Family App.
  String get qrPayload => 'familyapp://app/unirse?code=$code';

  static final codePattern = RegExp(r'^FAM-[A-Z0-9]{4}$');

  static String randomCode(Random random) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return 'FAM-${List.generate(4, (_) => alphabet[random.nextInt(alphabet.length)]).join()}';
  }

  /// Extrae el código de lo que leyó la cámara o escribió la persona.
  ///
  /// Acepta el enlace del QR (`familyapp://app/unirse?code=FAM-XXXX`, o el
  /// formato anterior `familyapp://unirse?code=...`) o solo el código.
  /// Devuelve `null` si no es una invitación de Family App.
  static String? parseCode(String raw) {
    final text = raw.trim();
    final uri = Uri.tryParse(text);
    if (uri != null && uri.scheme == 'familyapp') {
      final isJoinLink = (uri.host == 'app' && uri.path == '/unirse') || uri.host == 'unirse';
      final code = uri.queryParameters['code']?.toUpperCase();
      return isJoinLink && code != null && codePattern.hasMatch(code) ? code : null;
    }
    final code = text.toUpperCase();
    return codePattern.hasMatch(code) ? code : null;
  }
}

/// Da acceso al [FamilyStore] desde cualquier widget y lo reconstruye al cambiar.
class FamilyScope extends InheritedNotifier<FamilyStore> {
  const FamilyScope({super.key, required FamilyStore store, required super.child})
      : super(notifier: store);

  static FamilyStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FamilyScope>();
    assert(scope != null, 'FamilyScope no encontrado en el árbol de widgets');
    return scope!.notifier!;
  }
}
