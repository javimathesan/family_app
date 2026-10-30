import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/points.dart';
import '../models/models.dart';

/// Estado del hogar en memoria.
///
/// En la v1 sirve de fuente de datos de ejemplo para la UI. Más adelante se
/// reemplaza por un repositorio con base local (SQLite) y sincronización con
/// el backend, manteniendo esta misma interfaz pública.
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
        _templates = templates,
        _rewards = rewards,
        _balances = balances ?? {},
        _piggy = piggyBank ?? {},
        _history = history ?? {},
        _notices = notices ?? [],
        _clock = clock ?? DateTime.now;

  final String homeName;
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
  final _random = Random();

  String? _currentMemberId;

  static const waterGoal = 8;

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
    memberById(memberId)?.avatar = avatar;
    notifyListeners();
  }

  void setAccent(String memberId, Color accent) {
    memberById(memberId)?.accent = accent;
    notifyListeners();
  }

  /// Alta de un miembro nuevo que escaneó el QR. Queda pendiente hasta que
  /// un adulto lo confirme ([confirmMember]).
  Member addPendingMember({required String nickname, required MemberRole role, AgeMode? mode}) {
    final member = Member(
      id: 'm${_members.length + 1}-${_random.nextInt(9999)}',
      nickname: nickname.trim(),
      role: role,
      mode: mode,
    );
    _members.add(member);
    _pendingMembers.add(member.id);
    _notices.insert(0, FamilyNotice(time: _clock(), text: '${member.nickname} quiere unirse al hogar'));
    notifyListeners();
    return member;
  }

  final Set<String> _pendingMembers = {};
  bool isPendingMember(String id) => _pendingMembers.contains(id);

  void confirmMember(String id) {
    _pendingMembers.remove(id);
    notifyListeners();
  }

  // ------------------------------------------------------------- invitaciones

  /// Código de invitación de un solo uso. Vence a los 15 minutos.
  Invitation createInvitation({required MemberRole role, AgeMode? mode}) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final suffix = List.generate(4, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
    return Invitation(
      code: 'FAM-$suffix',
      role: role,
      mode: mode,
      expiresAt: _clock().add(const Duration(minutes: 15)),
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
      notifyListeners();
      return 0;
    }
    final task = _templates.firstWhere((t) => t.id == taskId);
    final now = _clock();
    final points = PointsRules.pointsFor(task, now);
    final needsAdult = task.validation != Validation.self;
    day[taskId] = TaskCompletion(
      taskId: taskId,
      completedAt: now,
      pointsAwarded: points,
      pendingApproval: needsAdult,
    );
    if (!needsAdult) _addBalance(memberId, points);
    final who = memberById(memberId)?.nickname ?? 'Alguien';
    _notices.insert(0, FamilyNotice(time: now, text: '$who completó: ${task.name}'));
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
        result.add((member: member, task: _templates.firstWhere((t) => t.id == c.taskId)));
      }
    });
    return result;
  }

  void approveTask(String memberId, String taskId) {
    final c = _today[memberId]?[taskId];
    if (c == null || !c.pendingApproval) return;
    _today[memberId]![taskId] = TaskCompletion(
      taskId: taskId,
      completedAt: c.completedAt,
      pointsAwarded: c.pointsAwarded,
    );
    _addBalance(memberId, c.pointsAwarded);
    notifyListeners();
  }

  void rejectTask(String memberId, String taskId) {
    _today[memberId]?.remove(taskId);
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

  // ------------------------------------------------------------------ salud

  HealthLog healthOf(String memberId) => _health.putIfAbsent(memberId, HealthLog.new);

  void addGlass(String memberId) {
    final log = healthOf(memberId);
    if (log.glasses >= waterGoal) return;
    log.glasses++;
    if (HealthRules.reachedWaterGoal(log.glasses, waterGoal)) {
      _addBalance(memberId, 5);
      final who = memberById(memberId)?.nickname ?? 'Alguien';
      _notices.insert(0, FamilyNotice(time: _clock(), text: '$who llegó a su meta de agua'));
    }
    notifyListeners();
  }

  void togglePoop(String memberId) {
    final log = healthOf(memberId);
    log.poop = !log.poop;
    notifyListeners();
  }

  void addPee(String memberId) {
    healthOf(memberId).pee++;
    notifyListeners();
  }

  void setMood(String memberId, String mood) {
    healthOf(memberId).mood = mood;
    notifyListeners();
  }

  // ---------------------------------------------------------------- premios

  List<Reward> get rewards => List.unmodifiable(_rewards);
  int balanceOf(String memberId) => _balances[memberId] ?? 0;
  int piggyOf(String memberId) => _piggy[memberId] ?? 0;

  void _addBalance(String memberId, int delta) {
    _balances[memberId] = max(0, balanceOf(memberId) + delta);
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
    final reward = _rewards.firstWhere((r) => r.id == rewardId);
    if (!PointsRules.canRedeem(balance: balanceOf(memberId), reward: reward)) return false;
    _addBalance(memberId, -reward.cost);
    _redemptions.add(Redemption(
      id: 'r${_redemptions.length + 1}',
      memberId: memberId,
      rewardId: rewardId,
      requestedAt: _clock(),
    ));
    notifyListeners();
    return true;
  }

  void approveRedemption(String redemptionId) {
    _redemptions.firstWhere((r) => r.id == redemptionId).status = RedemptionStatus.approved;
    notifyListeners();
  }

  /// Si el adulto rechaza, se devuelven los puntos.
  void rejectRedemption(String redemptionId) {
    final r = _redemptions.firstWhere((r) => r.id == redemptionId);
    if (r.status != RedemptionStatus.pending) return;
    r.status = RedemptionStatus.rejected;
    final reward = _rewards.firstWhere((w) => w.id == r.rewardId);
    _addBalance(r.memberId, reward.cost);
    notifyListeners();
  }

  Reward rewardById(String id) => _rewards.firstWhere((r) => r.id == id);

  // ------------------------------------------------------- calendario/avisos

  List<DaySummary> historyOf(String memberId) => List.unmodifiable(_history[memberId] ?? const []);

  List<FamilyNotice> get notices => List.unmodifiable(_notices);

  DateTime get now => _clock();

  // ------------------------------------------------------------ persistencia

  /// Versión del formato guardado. Si cambia, los datos viejos se ignoran.
  static const schemaVersion = 1;

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Estado completo para guardar en el teléfono. Las plantillas de tareas y
  /// premios no se guardan: vienen de la configuración de la app.
  Map<String, dynamic> toJson() => {
        'v': schemaVersion,
        'day': dayKey(_clock()),
        'members': [for (final m in _members) _memberToJson(m)],
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

    _members
      ..clear()
      ..addAll([for (final m in json['members'] as List) _memberFromJson(m as Map<String, dynamic>)]);
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
      final done = completions[child.id] ?? const {};
      final log = health[child.id];
      if (done.isEmpty && log == null) continue;
      final list = _history.putIfAbsent(child.id, () => []);
      if (list.any((s) => DateUtils.isSameDay(s.date, date))) continue;
      list.add(DaySummary(
        date: date,
        completionRatio: _templates.isEmpty ? 0 : done.length / _templates.length,
        points: done.values.where((c) => !c.pendingApproval).fold(0, (sum, c) => sum + c.pointsAwarded),
        glasses: log?.glasses ?? 0,
        mood: log?.mood,
      ));
    }
  }

  /// Vuelve a los datos de ejemplo (útil para probar desde cero).
  void resetToDemo() {
    final demo = FamilyStore.demo(clock: _clock);
    _currentMemberId = null;
    restoreFrom(demo.toJson());
  }

  static Map<String, dynamic> _memberToJson(Member m) => {
        'id': m.id,
        'nickname': m.nickname,
        'role': m.role.name,
        'mode': m.mode?.name,
        'accent': m.accent.toARGB32(),
        'avatar': {
          'skin': m.avatar.skin,
          'hairStyle': m.avatar.hairStyle,
          'hairColor': m.avatar.hairColor,
          'eyes': m.avatar.eyes,
          'glasses': m.avatar.glasses,
          'shirt': m.avatar.shirt,
          'accessory': m.avatar.accessory,
        },
      };

  static Member _memberFromJson(Map<String, dynamic> j) {
    final a = j['avatar'] as Map<String, dynamic>;
    return Member(
      id: j['id'] as String,
      nickname: j['nickname'] as String,
      role: MemberRole.values.byName(j['role'] as String),
      mode: j['mode'] == null ? null : AgeMode.values.byName(j['mode'] as String),
      accent: Color(j['accent'] as int),
      avatar: AvatarConfig(
        skin: a['skin'] as int,
        hairStyle: a['hairStyle'] as int,
        hairColor: a['hairColor'] as int,
        eyes: a['eyes'] as int,
        glasses: a['glasses'] as bool,
        shirt: a['shirt'] as int,
        accessory: a['accessory'] as int,
      ),
    );
  }

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

    TimeOfDay t(int h, int m) => TimeOfDay(hour: h, minute: m);
    final templates = [
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
      TaskTemplate(id: 'deporte', name: 'Fútbol en el club', block: DayBlock.afternoon, time: t(15, 0), points: 10, windowMinutes: 60),
      TaskTemplate(id: 'llegar', name: 'Llegar a casa', block: DayBlock.afternoon, time: t(17, 0), points: 5),
      TaskTemplate(id: 'banio', name: 'Bañarme', block: DayBlock.afternoon, time: t(17, 30), points: 5),
      TaskTemplate(id: 'estudiar', name: 'Estudiar / repasar', block: DayBlock.night, time: t(18, 0), points: 10, windowMinutes: 120),
      TaskTemplate(id: 'cena', name: 'Comer, recoger y lavar', block: DayBlock.night, time: t(20, 0), points: 8, windowMinutes: 60),
      TaskTemplate(id: 'dientes_pm', name: 'Cepillarme los dientes', block: DayBlock.night, time: t(21, 0), points: 5),
    ];

    const rewards = [
      Reward(id: 'helado', name: 'Helado', cost: 50, icon: Icons.icecream_outlined),
      Reward(id: 'peli', name: 'Elijo la película del sábado', cost: 60, icon: Icons.movie_outlined),
      Reward(id: 'pantalla', name: '1 hora extra de pantalla', cost: 80, icon: Icons.tv_outlined),
      Reward(id: 'salida', name: 'Salida especial', cost: 150, icon: Icons.park_outlined),
      Reward(id: 'libre', name: 'Pase libre: finde sin tareas', cost: 300, icon: Icons.beach_access_outlined),
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
      templates: templates,
      rewards: rewards,
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
  const Invitation({required this.code, required this.role, required this.expiresAt, this.mode});

  final String code;
  final MemberRole role;
  final AgeMode? mode;
  final DateTime expiresAt;

  /// Contenido del QR. No incluye datos personales: solo el código y el rol.
  String get qrPayload => 'familyapp://unirse?code=$code&rol=${role.name}';

  static final codePattern = RegExp(r'^FAM-[A-Z0-9]{4}$');

  /// Extrae el código de lo que leyó la cámara o escribió la persona.
  ///
  /// Acepta el enlace completo del QR (`familyapp://unirse?code=FAM-XXXX`) o
  /// solo el código. Devuelve `null` si no es una invitación de family_app.
  static String? parseCode(String raw) {
    final text = raw.trim();
    final uri = Uri.tryParse(text);
    if (uri != null && uri.scheme == 'familyapp' && uri.host == 'unirse') {
      final code = uri.queryParameters['code']?.toUpperCase();
      return code != null && codePattern.hasMatch(code) ? code : null;
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
