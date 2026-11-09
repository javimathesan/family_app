import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals, mapEquals, setEquals;

/// Rol de un miembro dentro del hogar.
enum MemberRole {
  admin('Administrador (P1)'),
  coAdmin('Co-administrador (P2)'),
  child('Hijo/a'),
  otherAdult('Otro adulto conviviente');

  const MemberRole(this.label);
  final String label;

  bool get isAdult => this != MemberRole.child;
  bool get canManage => this == MemberRole.admin || this == MemberRole.coAdmin;
}

/// Modo de interfaz según la edad del hijo.
enum AgeMode {
  peques('Peques', '4 a 8'),
  junior('Junior', '9 a 12'),
  teen('Teen', '13 a 17');

  const AgeMode(this.label, this.ages);
  final String label;
  final String ages;
}

/// Bloques del día en que se agrupan las tareas.
enum DayBlock {
  morning('Mañana'),
  school('Colegio'),
  afternoon('Tarde'),
  night('Noche');

  const DayBlock(this.label);
  final String label;
}

/// Cómo se valida una tarea.
enum Validation {
  self('lo marco yo'),
  photo('con foto'),
  adult('valida un adulto');

  const Validation(this.label);
  final String label;
}

/// Configuración del avatar estilo Funko. Solo índices: el dibujo vive en la UI.
@immutable
class AvatarConfig {
  const AvatarConfig({
    this.skin = 1,
    this.hairStyle = 0,
    this.hairColor = 1,
    this.eyes = 0,
    bool glasses = false,
    int? eyewear,
    this.shirt = 0,
    this.accessory = 0,
    this.outfit = 0,
    this.brows = 0,
    this.freckles = false,
    this.facialHair = 0,
  }) : eyewear = eyewear ?? (glasses ? 1 : 0);

  /// Anteojos y parches (ver `AvatarOptions.eyewear`): 0 nada, 1 anteojos,
  /// 2 de sol, 3 parche en el ojo izquierdo, 4 en el derecho.
  final int eyewear;

  /// Barba y bigote (ver `AvatarOptions.facialHair`).
  final int facialHair;

  /// Compatibilidad con los avatares guardados antes (solo "anteojos sí/no").
  bool get glasses => eyewear == 1;

  /// Cejas: 0 sin, 1 finas, 2 gruesas.
  final int brows;
  final bool freckles;

  final int skin;
  final int hairStyle;
  final int hairColor;
  final int eyes;
  final int shirt;
  final int accessory;

  /// Disfraz (0 = remera). Ver `AvatarOptions.outfits`.
  final int outfit;

  AvatarConfig copyWith({
    int? skin,
    int? hairStyle,
    int? hairColor,
    int? eyes,
    int? eyewear,
    int? facialHair,
    int? shirt,
    int? accessory,
    int? outfit,
    int? brows,
    bool? freckles,
  }) {
    return AvatarConfig(
      brows: brows ?? this.brows,
      freckles: freckles ?? this.freckles,
      skin: skin ?? this.skin,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      eyes: eyes ?? this.eyes,
      eyewear: eyewear ?? this.eyewear,
      facialHair: facialHair ?? this.facialHair,
      shirt: shirt ?? this.shirt,
      accessory: accessory ?? this.accessory,
      outfit: outfit ?? this.outfit,
    );
  }
}

/// Un miembro del hogar. De los menores solo se guarda apodo y avatar.
class Member {
  Member({
    required this.id,
    required this.nickname,
    required this.role,
    this.mode,
    this.avatar = const AvatarConfig(),
    this.accent = const Color(0xFF2563EB),
    this.uid,
    Set<String>? unlocked,
    this.look = const MemberLook(),
    Map<String, dynamic>? room,
    Map<String, int>? progress,
    this.water,
    this.bathroom,
  })  : unlocked = unlocked ?? {},
        room = room ?? {},
        progress = progress ?? {};

  final String id;

  /// Teléfono (usuario anónimo de Firebase) que usa este miembro.
  /// `null` si no tiene celular propio y se maneja desde el de un adulto.
  final String? uid;
  String nickname;
  final MemberRole role;
  AgeMode? mode;
  AvatarConfig avatar;
  Color accent;

  /// Disfraces y accesorios que desbloqueó con puntos.
  final Set<String> unlocked;

  /// Cómo ve su app: modo claro u oscuro, fondo y tarjetas.
  MemberLook look;

  /// Su cuarto y su mascota: qué eligió en cada lugar y el nombre de la mascota.
  final Map<String, dynamic> room;

  /// Avance en Palabras (estrellas por tema, palabras para repasar) y récords.
  final Map<String, int> progress;

  /// "Mis hábitos": si registra el agua y el baño. Lo decide un adulto
  /// administrador. `null` = lo de siempre según la edad (ver [waterOn]).
  bool? water;
  bool? bathroom;

  /// Agua: activada para todos los hijos salvo que un adulto la apague.
  bool get waterOn => role == MemberRole.child && (water ?? true);

  /// Baño (pipí y popó): de entrada solo para los más chicos.
  bool get bathroomOn => role == MemberRole.child && (bathroom ?? mode == AgeMode.peques);

  /// Si tiene la tarjeta "Mis hábitos".
  bool get habitsOn => waterOn || bathroomOn;
}

/// Modo de color de la app.
enum LookMode {
  system('Automático'),
  light('Claro'),
  dark('Oscuro');

  const LookMode(this.label);
  final String label;
}

/// Personalización de cada miembro. Algunas opciones son de Family App Plus.
@immutable
class MemberLook {
  const MemberLook({
    this.mode = LookMode.system,
    this.background = 0,
    this.cards = 0,
    this.party = 0,
    this.world = 0,
    this.home = const [],
    this.hidden = const [],
    this.tints = const {},
    this.goals,
    this.tools = const [],
  });

  /// Herramientas del hogar que el adulto eligió ver en su inicio
  /// (por ejemplo `compras`, `compras_precios`). Todas arrancan apagadas.
  final List<String> tools;

  final LookMode mode;

  /// Metas de "Mi día" que eligió el adulto (`null` = todavía no armó su día).
  /// Viajan dentro de `look` para no tocar las reglas de la base.
  final List<AdultGoal>? goals;

  /// Color de cada tarjeta de Hoy (id → índice de [LookOptions.tints]). Plus.
  final Map<String, int> tints;

  /// Índice de [LookOptions.backgrounds].
  final int background;

  /// Índice de [LookOptions.cards].
  final int cards;

  /// Festejo al completar algo: índice de [LookOptions.parties].
  final int party;

  /// Mundo temático (0 = ninguno): índice de [LookOptions.worlds].
  final int world;

  /// Orden de las tarjetas de la pantalla Hoy (ids) y las que se ocultan.
  final List<String> home;
  final List<String> hidden;

  MemberLook copyWith({
    LookMode? mode,
    int? background,
    int? cards,
    int? party,
    int? world,
    List<String>? home,
    List<String>? hidden,
    Map<String, int>? tints,
    List<AdultGoal>? goals,
    List<String>? tools,
  }) =>
      MemberLook(
        tools: tools ?? this.tools,
        tints: tints ?? this.tints,
        goals: goals ?? this.goals,
        mode: mode ?? this.mode,
        background: background ?? this.background,
        cards: cards ?? this.cards,
        party: party ?? this.party,
        world: world ?? this.world,
        home: home ?? this.home,
        hidden: hidden ?? this.hidden,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'bg': background,
        'cards': cards,
        'party': party,
        'world': world,
        'home': home,
        'hidden': hidden,
        if (tints.isNotEmpty) 'tints': tints,
        if (goals != null) 'goals': [for (final g in goals!) g.toJson()],
        if (tools.isNotEmpty) 'tools': tools,
      };

  static MemberLook fromJson(Object? raw) {
    if (raw is! Map) return const MemberLook();
    return MemberLook(
      mode: LookMode.values.asNameMap()[raw['mode']] ?? LookMode.system,
      background: (raw['bg'] as num?)?.toInt() ?? 0,
      cards: (raw['cards'] as num?)?.toInt() ?? 0,
      party: (raw['party'] as num?)?.toInt() ?? 0,
      world: (raw['world'] as num?)?.toInt() ?? 0,
      home: ((raw['home'] as List?) ?? const []).cast<String>().toList(),
      hidden: ((raw['hidden'] as List?) ?? const []).cast<String>().toList(),
      tints: {for (final e in ((raw['tints'] as Map?) ?? const {}).entries) e.key as String: (e.value as num).toInt()},
      goals: raw['goals'] is List
          ? [for (final g in raw['goals'] as List) AdultGoal.fromJson((g as Map).cast<String, dynamic>())]
          : null,
      tools: ((raw['tools'] as List?) ?? const []).cast<String>().toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MemberLook &&
      other.mode == mode &&
      other.background == background &&
      other.cards == cards &&
      other.party == party &&
      other.world == world &&
      listEquals(other.home, home) &&
      listEquals(other.hidden, hidden) &&
      mapEquals(other.tints, tints) &&
      listEquals(other.goals, goals) &&
      listEquals(other.tools, tools);

  @override
  int get hashCode => Object.hash(mode, background, cards, party, world, Object.hashAll(home), Object.hashAll(hidden), Object.hashAll(tints.entries.map((e) => '${e.key}${e.value}')));
}

/// Opciones de personalización. Las marcadas `plus` son de Family App Plus.
abstract final class LookOptions {
  static const backgrounds = <({String name, Color color, bool plus})>[
    (name: 'Gris claro', color: Color(0xFFF5F6FA), plus: false),
    (name: 'Crema', color: Color(0xFFFFF8EC), plus: false),
    (name: 'Celeste', color: Color(0xFFEAF4FF), plus: false),
    (name: 'Lila', color: Color(0xFFF3EEFF), plus: false),
    (name: 'Menta', color: Color(0xFFE6F7EE), plus: true),
    (name: 'Rosa', color: Color(0xFFFFEDF4), plus: true),
    (name: 'Durazno', color: Color(0xFFFFEBDD), plus: true),
    (name: 'Cielo noche', color: Color(0xFFE3E7FF), plus: true),
  ];

  /// Festejos al completar una tarea, un reto o ganar.
  static const parties = <({String name, String emoji, bool plus})>[
    (name: 'Confeti', emoji: '🎉', plus: false),
    (name: 'Estrellas', emoji: '⭐', plus: false),
    (name: 'Globos', emoji: '🎈', plus: false),
    (name: 'Corazones', emoji: '💖', plus: true),
    (name: 'Fuegos artificiales', emoji: '🎆', plus: true),
  ];

  /// Mundos temáticos de Family App Plus: color, fondo y dibujitos.
  static const worlds = <({String name, String emojis, Color accent, Color background})>[
    (name: 'Ninguno', emojis: '', accent: Color(0xFF2563EB), background: Color(0xFFF5F6FA)),
    (name: 'Espacio', emojis: '🚀🪐⭐🌙👽', accent: Color(0xFF4338CA), background: Color(0xFFE6E8FF)),
    (name: 'Océano', emojis: '🐠🐙🐚🌊🐬', accent: Color(0xFF0369A1), background: Color(0xFFE0F2FE)),
    (name: 'Dinosaurios', emojis: '🦖🦕🌋🌿🥚', accent: Color(0xFF15803D), background: Color(0xFFE7F7E9)),
    (name: 'Castillo', emojis: '🏰👑🦄✨🌸', accent: Color(0xFFBE185D), background: Color(0xFFFFEAF3)),
    (name: 'Selva', emojis: '🐒🦜🌴🐯🍌', accent: Color(0xFFB45309), background: Color(0xFFFFF3DC)),
  ];

  static const cards = <({String name, bool plus})>[
    (name: 'Blancas', plus: false),
    (name: 'De mi color', plus: true),
    (name: 'Con borde', plus: false),
    (name: 'Bien redondas', plus: true),
  ];

  /// Colores suaves para pintar cada tarjeta de Hoy (Plus).
  static const tints = <({String name, Color color})>[
    (name: 'Celeste', color: Color(0xFFE0F2FE)),
    (name: 'Menta', color: Color(0xFFDCFCE7)),
    (name: 'Amarillo', color: Color(0xFFFEF9C3)),
    (name: 'Durazno', color: Color(0xFFFFEDD5)),
    (name: 'Rosa', color: Color(0xFFFCE7F3)),
    (name: 'Lila', color: Color(0xFFEDE9FE)),
    (name: 'Gris', color: Color(0xFFF1F5F9)),
  ];

  /// Temas listos: color, fondo, mundo y estilo de tarjeta de un toque.
  static const themes = <({String name, String emoji, Color accent, int background, int world, int cards, bool plus})>[
    (name: 'Clásico', emoji: '✨', accent: Color(0xFF2563EB), background: 0, world: 0, cards: 0, plus: false),
    (name: 'Cielo', emoji: '☁️', accent: Color(0xFF2563EB), background: 2, world: 0, cards: 2, plus: false),
    (name: 'Lavanda', emoji: '💜', accent: Color(0xFF7C3AED), background: 3, world: 0, cards: 2, plus: false),
    (name: 'Atardecer', emoji: '🌅', accent: Color(0xFFC2410C), background: 1, world: 0, cards: 0, plus: false),
    (name: 'Océano', emoji: '🌊', accent: Color(0xFF0369A1), background: 2, world: 2, cards: 1, plus: true),
    (name: 'Espacio', emoji: '🚀', accent: Color(0xFF4338CA), background: 7, world: 1, cards: 3, plus: true),
    (name: 'Selva', emoji: '🌴', accent: Color(0xFFB45309), background: 1, world: 5, cards: 1, plus: true),
    (name: 'Dinosaurios', emoji: '🦖', accent: Color(0xFF15803D), background: 4, world: 3, cards: 2, plus: true),
    (name: 'Dulce', emoji: '🍭', accent: Color(0xFFDB2777), background: 5, world: 0, cards: 3, plus: true),
    (name: 'Castillo', emoji: '🏰', accent: Color(0xFFBE185D), background: 5, world: 4, cards: 3, plus: true),
  ];

  /// Colores extra de Family App Plus (los 4 básicos están en AppColors.accents).
  static const plusAccents = <(String, Color)>[
    ('Rosa', Color(0xFFDB2777)),
    ('Rojo', Color(0xFFDC2626)),
    ('Verde', Color(0xFF15803D)),
    ('Celeste', Color(0xFF0369A1)),
    ('Marrón', Color(0xFF92400E)),
    ('Noche', Color(0xFF1E2235)),
  ];
}

/// Plantilla de una tarea de la rutina.
@immutable
class TaskTemplate {
  const TaskTemplate({
    required this.id,
    required this.name,
    required this.block,
    required this.time,
    required this.points,
    this.validation = Validation.self,
    this.windowMinutes = 30,
    this.assignedTo = const {},
    this.emoji,
    this.days = const {},
    this.weekendTime,
    this.custom = const {},
  });

  final String id;
  final String name;
  final DayBlock block;

  /// Hora del sábado y domingo, si es distinta (por ejemplo, levantarse más tarde).
  final TimeOfDay? weekendTime;

  /// Horario propio de algunos hijos (hora, días y puntos). El resto usa el de la tarea.
  final Map<String, TaskSlot> custom;

  /// El horario que usa [memberId] (el propio o el general).
  TaskSlot slotFor(String memberId) =>
      custom[memberId] ?? TaskSlot(time: time, weekendTime: weekendTime, days: days, points: points);

  /// La tarea como la ve [memberId] el día [date]: con su hora, sus días y sus puntos.
  TaskTemplate resolvedFor(String memberId, DateTime date) {
    final slot = slotFor(memberId);
    return TaskTemplate(
      id: id,
      name: name,
      block: block,
      time: slot.timeOn(date),
      points: slot.points,
      validation: validation,
      windowMinutes: windowMinutes,
      assignedTo: assignedTo,
      emoji: emoji,
      days: slot.days,
      weekendTime: slot.weekendTime,
      custom: custom,
    );
  }

  /// Días de la semana en que toca (1 = lunes … 7 = domingo). Vacío = todos.
  final Set<int> days;

  bool onDay(DateTime date) => days.isEmpty || days.contains(date.weekday);

  static const weekdays = {1, 2, 3, 4, 5};
  static const weekend = {6, 7};

  /// "Todos los días", "Lunes a viernes", "Fin de semana" o "Lun, Mié…".
  String get daysLabel => daysText(days);

  static String daysText(Set<int> days) {
    if (days.isEmpty || days.length == 7) return 'Todos los días';
    if (setEquals(days, weekdays)) return 'Lunes a viernes';
    if (setEquals(days, weekend)) return 'Fin de semana';
    const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return [for (final d in days.toList()..sort()) names[d - 1]].join(', ');
  }

  /// Dibujito de la tarea (lo puede elegir la familia).
  final String? emoji;

  /// El emoji elegido o uno según el nombre de la tarea.
  String get icon => emoji ?? taskEmojiFor(id, name);

  /// Hijos a los que les toca. Vacío = a todos.
  final Set<String> assignedTo;

  bool appliesTo(String memberId) => assignedTo.isEmpty || assignedTo.contains(memberId);

  /// Hora sugerida del día.
  final TimeOfDay time;
  final int points;
  final Validation validation;

  /// Minutos después de [time] en los que la tarea todavía cuenta "a tiempo".
  final int windowMinutes;

  TaskTemplate copyWith({
    String? name,
    DayBlock? block,
    TimeOfDay? time,
    int? points,
    Validation? validation,
    int? windowMinutes,
    Set<String>? assignedTo,
    String? emoji,
    Set<int>? days,
    Map<String, TaskSlot>? custom,
    TimeOfDay? Function()? weekendTime,
  }) =>
      TaskTemplate(
        id: id,
        emoji: emoji ?? this.emoji,
        days: days ?? this.days,
        custom: custom ?? this.custom,
        weekendTime: weekendTime == null ? this.weekendTime : weekendTime(),
        name: name ?? this.name,
        block: block ?? this.block,
        time: time ?? this.time,
        points: points ?? this.points,
        validation: validation ?? this.validation,
        windowMinutes: windowMinutes ?? this.windowMinutes,
        assignedTo: assignedTo ?? this.assignedTo,
      );
}

/// Cuándo hace una tarea un hijo: hora (y otra para el finde), días y puntos.
@immutable
class TaskSlot {
  const TaskSlot({required this.time, this.weekendTime, this.days = const {}, required this.points});

  final TimeOfDay time;
  final TimeOfDay? weekendTime;
  final Set<int> days;
  final int points;

  TimeOfDay timeOn(DateTime date) => date.weekday >= DateTime.saturday && weekendTime != null ? weekendTime! : time;

  /// "7:00 · finde 9:30 · L-V" para mostrar en listas.
  String label(String Function(TimeOfDay) hhmm) => [
        hhmm(time),
        if (weekendTime != null && weekendTime != time) 'finde ${hhmm(weekendTime!)}',
        if (days.isNotEmpty) TaskTemplate.daysText(days),
      ].join(' · ');

  Map<String, dynamic> toJson() => {
        'hour': time.hour,
        'minute': time.minute,
        if (weekendTime != null) 'wHour': weekendTime!.hour,
        if (weekendTime != null) 'wMinute': weekendTime!.minute,
        'days': days.toList()..sort(),
        'points': points,
      };

  static TaskSlot fromJson(Map<String, dynamic> j) => TaskSlot(
        time: TimeOfDay(hour: (j['hour'] as num).toInt(), minute: (j['minute'] as num).toInt()),
        weekendTime: j['wHour'] is num
            ? TimeOfDay(hour: (j['wHour'] as num).toInt(), minute: ((j['wMinute'] as num?) ?? 0).toInt())
            : null,
        days: {...((j['days'] as List?) ?? const []).map((d) => (d as num).toInt())},
        points: (j['points'] as num).toInt(),
      );
}

/// Meta diaria del adulto ("Mi día"). No da puntos: es para dar el ejemplo.
@immutable
class AdultGoal {
  const AdultGoal(this.id, this.label, this.emoji, {this.notice, this.target = 1});

  /// Siempre empieza con `meta_` para no mezclarse con las tareas de los chicos.
  final String id;
  final String label;
  final String emoji;

  /// Si no es `null`, al marcarla se avisa al hogar: "<apodo> <notice>".
  final String? notice;

  /// Cuántas veces hay que hacerla para cumplirla (1 = se marca y listo).
  /// Se puede pasar: 10 vasos de 8 también vale.
  final int target;

  bool get counted => target > 1;

  /// Ideas para armar "Mi día". Cada adulto elige las suyas y crea otras.
  static const all = <AdultGoal>[
    AdultGoal('meta_ejercicio', 'Hice ejercicio', '🏃'),
    AdultGoal('meta_lectura', 'Leí o estudié', '📖'),
    AdultGoal('meta_jugar', 'Jugué con mis hijos', '🧸', notice: 'jugó con sus hijos'),
    AdultGoal('meta_mesa', 'Comida en familia sin celulares', '🍽️', notice: 'propuso comer en familia sin celulares'),
    AdultGoal('meta_amigos', 'Tiempo con amigos', '👥'),
    AdultGoal('meta_pantalla', 'Menos de 2 horas de pantalla', '📵'),
    AdultGoal('meta_agua', 'Vasos de agua', '💧', target: 8),
    AdultGoal('meta_caminar', 'Salí a caminar', '🚶'),
    AdultGoal('meta_dormir', 'Dormí 8 horas', '😴'),
    AdultGoal('meta_llamar', 'Llamé a un familiar', '📞'),
    AdultGoal('meta_cuento', 'Les leí un cuento', '📚', notice: 'les leyó un cuento'),
    AdultGoal('meta_respirar', 'Un rato para mí', '🧘'),
  ];

  Map<String, dynamic> toJson() =>
      {'id': id, 'label': label, 'emoji': emoji, if (notice != null) 'notice': notice, if (target > 1) 'target': target};

  static AdultGoal fromJson(Map<String, dynamic> j) => AdultGoal(j['id'] as String, j['label'] as String, (j['emoji'] as String?) ?? '⭐',
      notice: j['notice'] as String?, target: (j['target'] as num?)?.toInt() ?? 1);

  @override
  bool operator ==(Object other) =>
      other is AdultGoal &&
      other.id == id &&
      other.label == label &&
      other.emoji == emoji &&
      other.notice == notice &&
      other.target == target;

  @override
  int get hashCode => Object.hash(id, label, emoji, notice, target);

  static bool isGoalId(String id) => id.startsWith('meta_');
}

/// Registro de una tarea hecha en un día.
@immutable
class TaskCompletion {
  const TaskCompletion({
    required this.taskId,
    required this.completedAt,
    required this.pointsAwarded,
    this.pendingApproval = false,
    this.count = 1,
  });

  final String taskId;
  final DateTime completedAt;
  final int pointsAwarded;
  final bool pendingApproval;

  /// Cuántas veces se hizo (metas que se cuentan, como los vasos de agua).
  final int count;
}

/// Algo para comprar en la lista del hogar.
@immutable
class ShoppingItem {
  const ShoppingItem({required this.id, required this.name, this.done = false, this.by, required this.at, this.price});

  final String id;
  final String name;
  final bool done;

  /// Apodo de quien lo agregó.
  final String? by;
  final DateTime at;

  /// Precio aproximado (opcional), para llevar la cuenta.
  final double? price;

  ShoppingItem copyWith({bool? done, double? Function()? price}) =>
      ShoppingItem(id: id, name: name, done: done ?? this.done, by: by, at: at, price: price == null ? this.price : price());

  Map<String, dynamic> toJson() =>
      {'name': name, 'done': done, if (by != null) 'by': by, 'at': at.toIso8601String(), if (price != null) 'price': price};

  static ShoppingItem fromJson(String id, Map<String, dynamic> j) => ShoppingItem(
        id: id,
        name: j['name'] as String? ?? '',
        done: j['done'] as bool? ?? false,
        by: j['by'] as String?,
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime(2026),
        price: (j['price'] as num?)?.toDouble(),
      );
}

/// Registro de salud del día (sin diagnósticos, solo conteos).
class HealthLog {
  HealthLog({this.glasses = 0, this.poop = false, this.pee = 0, this.mood});

  int glasses;
  bool poop;
  int pee;
  String? mood;
}

/// Premio canjeable en la tienda.
@immutable
class Reward {
  const Reward({
    required this.id,
    required this.name,
    required this.cost,
    this.iconKey = 'regalo',
    this.monthly = false,
    this.assignedTo = const {},
    this.costs = const {},
  });

  final String id;
  final String name;
  final int cost;

  /// Hijos que lo pueden pedir. Vacío = todos.
  final Set<String> assignedTo;

  /// Costo distinto para algunos hijos (si no, [cost]).
  final Map<String, int> costs;

  bool appliesTo(String memberId) => assignedTo.isEmpty || assignedTo.contains(memberId);

  int costFor(String memberId) => costs[memberId] ?? cost;

  /// Clave del ícono en [rewardIcons] (se guarda como texto en la nube).
  final String iconKey;
  final bool monthly;

  IconData get icon => rewardIcons[iconKey] ?? Icons.card_giftcard_outlined;

  Reward copyWith({String? name, int? cost, String? iconKey, Set<String>? assignedTo, Map<String, int>? costs}) => Reward(
        id: id,
        name: name ?? this.name,
        cost: cost ?? this.cost,
        iconKey: iconKey ?? this.iconKey,
        monthly: monthly,
        assignedTo: assignedTo ?? this.assignedTo,
        costs: costs ?? this.costs,
      );

  /// El premio como lo ve [memberId] (con su costo).
  Reward resolvedFor(String memberId) => copyWith(cost: costFor(memberId));
}

/// Íconos que el adulto puede elegir para un premio.
const rewardIcons = <String, IconData>{
  'regalo': Icons.card_giftcard_outlined,
  'helado': Icons.icecream_outlined,
  'pelicula': Icons.movie_outlined,
  'pantalla': Icons.tv_outlined,
  'juego': Icons.sports_esports_outlined,
  'paseo': Icons.park_outlined,
  'comida': Icons.lunch_dining_outlined,
  'dinero': Icons.savings_outlined,
  'libre': Icons.beach_access_outlined,
  'juguete': Icons.toys_outlined,
  'deporte': Icons.sports_soccer_outlined,
  'estrella': Icons.star_outline,
};

enum RedemptionStatus { pending, approved, rejected }

/// Pedido de canje de un premio, que el adulto aprueba o rechaza.
class Redemption {
  Redemption({
    required this.id,
    required this.memberId,
    required this.rewardId,
    required this.requestedAt,
    this.status = RedemptionStatus.pending,
  });

  final String id;
  final String memberId;
  final String rewardId;
  final DateTime requestedAt;
  RedemptionStatus status;
}

/// Resumen de un día para el calendario de caritas.
@immutable
class DaySummary {
  const DaySummary({
    required this.date,
    required this.completionRatio,
    required this.points,
    this.glasses = 0,
    this.screenMinutes = 0,
    this.mood,
  });

  final DateTime date;

  /// Fracción de tareas cumplidas, de 0 a 1.
  final double completionRatio;
  final int points;
  final int glasses;
  final int screenMinutes;
  final String? mood;
}

/// Aviso para el adulto.
@immutable
class FamilyNotice {
  const FamilyNotice({
    required this.time,
    required this.text,
    this.isAlert = false,
    this.kind = NoticeKind.info,
    this.memberId,
  });

  final DateTime time;
  final String text;
  final bool isAlert;
  final NoticeKind kind;

  /// Miembro del que trata el aviso (el que hizo la tarea, pidió el premio…).
  final String? memberId;

  /// Los que conviene avisar aunque el teléfono esté en "solo lo importante".
  bool get isImportant => isAlert || kind.important;
}

/// Tipo de aviso, para agrupar, filtrar y elegir qué notificar.
enum NoticeKind {
  task(false, Icons.check_circle_outline),
  toApprove(true, Icons.fact_check_outlined),
  health(false, Icons.local_drink_outlined),
  reward(true, Icons.card_giftcard_outlined),
  approval(false, Icons.thumb_up_alt_outlined),
  join(true, Icons.person_add_alt),
  goal(false, Icons.favorite_border),
  alert(true, Icons.warning_amber_outlined),
  game(false, Icons.sports_esports_outlined),
  info(false, Icons.info_outline);

  const NoticeKind(this.important, this.icon);
  final bool important;
  final IconData icon;
}

// ------------------------------------------------------------------ juegos

/// Juegos del Área de juegos.
enum GameKind {
  tateti('Tres en raya', 'Rápido, para todas las edades', Icons.grid_3x3, 2, 2),
  cuatro('4 en línea', 'Soltá fichas y uní 4', Icons.view_column_outlined, 2, 2),
  ludo('Ludo', 'De 2 a 4: dados, fichas y carrera a la meta', Icons.casino_outlined, 2, 4),
  ajedrez('Ajedrez', 'El clásico, con ayuda de movimientos', Icons.castle, 2, 2),
  barrio('Mi Barrio', 'Comprá lugares del barrio y cobrá alquiler', Icons.location_city, 2, 4),
  colorin('Colorín', 'Cartas de colores: bloqueo, reversa, +2 y +4', Icons.style, 2, 4);

  const GameKind(this.label, this.description, this.icon, this.minPlayers, this.maxPlayers);
  final String label;
  final String description;
  final IconData icon;
  final int minPlayers;
  final int maxPlayers;
}

/// Identificador de Robi, la compu, como jugador.
const botPlayerId = 'robi';

/// Partida entre miembros del hogar (o contra Robi).
class GameMatch {
  GameMatch({
    required this.id,
    required this.kind,
    required this.players,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.state,
    this.turn = 0,
    this.winner,
    this.draw = false,
    this.sameDevice = false,
    this.lastBy,
    this.friendshipId,
    Map<String, String>? names,
    this.reaction,
    this.reactionBy,
  }) : names = names ?? {};

  final String id;
  final GameKind kind;

  /// Si es una partida con una familia amiga: la amistad que la permite.
  final String? friendshipId;

  /// Apodos de los jugadores de la otra familia.
  final Map<String, String> names;

  /// Última reacción (frase o emoji fijo, sin chat libre) y quién la mandó.
  String? reaction;
  String? reactionBy;

  bool get withFriends => friendshipId != null;

  /// Ids de los jugadores en orden de turno (puede incluir [botPlayerId]).
  final List<String> players;
  final String createdBy;
  final DateTime createdAt;
  DateTime updatedAt;

  /// Estado propio de cada juego (tablero, dado, fichas…).
  Map<String, dynamic> state;

  /// Posición en [players] del que tiene que jugar.
  int turn;

  /// Posición en [players] del ganador.
  int? winner;
  bool draw;

  /// Se juega pasando un solo teléfono de mano en mano.
  bool sameDevice;

  /// Quién hizo la última jugada.
  String? lastBy;

  bool get finished => winner != null || draw;
  String get currentPlayer => players[turn];
  bool get vsBot => players.contains(botPlayerId);
}

/// Cuándo pueden jugar los chicos.
enum GamesRule {
  free('Siempre', 'Pueden jugar en cualquier momento.', 0),
  half('Con media rutina', 'Cuando completaron la mitad de las tareas del día.', .5),
  all('Con la rutina completa', 'Primero todas las tareas del día, después a jugar.', 1);

  const GamesRule(this.label, this.description, this.minRatio);
  final String label;
  final String description;
  final double minRatio;
}

/// Por qué un chico no puede jugar ahora.
enum GamesLock { routine, time }

// ------------------------------------------------------------------ agenda

/// Nota o recordatorio de la agenda familiar (turno médico, cumpleaños…).
class AgendaEvent {
  AgendaEvent({
    required this.id,
    required this.title,
    required this.at,
    required this.createdBy,
    this.place = '',
    this.notes = '',
    Set<String>? memberIds,
    this.remindMinutes,
    this.alarm = false,
    this.private = false,
  }) : memberIds = memberIds ?? {};

  final String id;
  String title;
  String place;
  String notes;
  DateTime at;

  /// Para quiénes es. Vacío = toda la familia.
  Set<String> memberIds;

  /// Minutos antes para avisar (`null` = sin aviso, 0 = a la hora).
  int? remindMinutes;

  /// Que suene como alarma (insistente) en vez de un aviso común.
  bool alarm;

  /// Solo lo ve quien lo creó (los demás no lo ven en la app).
  bool private;
  final String createdBy;

  bool isFor(String memberId) => memberIds.isEmpty || memberIds.contains(memberId);

  DateTime? get remindAt => remindMinutes == null ? null : at.subtract(Duration(minutes: remindMinutes!));

  AgendaEvent copy() => AgendaEvent(
        id: id,
        title: title,
        at: at,
        createdBy: createdBy,
        place: place,
        notes: notes,
        memberIds: {...memberIds},
        remindMinutes: remindMinutes,
        alarm: alarm,
        private: private,
      );

  /// Opciones de aviso para elegir en el formulario.
  static const remindOptions = <int?, String>{
    null: 'Sin aviso',
    0: 'A la hora',
    10: '10 minutos antes',
    30: '30 minutos antes',
    60: '1 hora antes',
    120: '2 horas antes',
    1440: '1 día antes',
  };
}

// ------------------------------------------------------- reto de la semana

enum ChallengeType {
  rutina('Rutina completa', 'días con la rutina completa', Icons.task_alt, [3, 5, 7]),
  agua('Tomar agua', 'días con 8 vasos de agua', Icons.local_drink_outlined, [3, 5, 7]),
  puntos('Juntar puntos', 'puntos en la semana', Icons.star_outline, [200, 400, 600]);

  const ChallengeType(this.label, this.unit, this.icon, this.targets);
  final String label;
  final String unit;
  final IconData icon;

  /// Metas sugeridas para elegir.
  final List<int> targets;
}

/// Reto de la semana para todos los chicos, con puntos extra al cumplirlo.
@immutable
class WeeklyChallenge {
  const WeeklyChallenge({required this.type, required this.target, required this.bonus});

  final ChallengeType type;
  final int target;
  final int bonus;

  String get title => '${type.label}: $target ${type.unit}';

  Map<String, dynamic> toJson() => {'type': type.name, 'target': target, 'bonus': bonus};

  static WeeklyChallenge? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final type = ChallengeType.values.asNameMap()[raw['type']];
    if (type == null) return null;
    return WeeklyChallenge(type: type, target: (raw['target'] as num).toInt(), bonus: (raw['bonus'] as num).toInt());
  }
}

/// Emojis para elegir en las tareas.
const taskEmojis = [
  '⏰', '🪥', '🛏️', '🥣', '🍽️', '🧽', '🎒', '🏫', '⚽', '🏠', '🛁', '📚', '✏️', '🌙',
  '🐶', '🐱', '🌱', '🧹', '👕', '🧸', '🎹', '🎨', '💧', '🍎', '🚲', '📖', '🗑️', '🧺',
];

/// Emoji por defecto según la tarea.
String taskEmojiFor(String id, String name) {
  const byId = {
    'levantarse': '⏰',
    'aseo': '🧼',
    'cama': '🛏️',
    'desayuno': '🥣',
    'mesa': '🍽️',
    'vajilla': '🧽',
    'dientes_am': '🪥',
    'dientes_pm': '🪥',
    'utiles': '🎒',
    'entrada': '🏫',
    'salida': '🚸',
    'deporte': '⚽',
    'llegar': '🏠',
    'banio': '🛁',
    'estudiar': '📚',
    'cena': '🍽️',
  };
  if (byId[id] case final e?) return e;
  final n = name.toLowerCase();
  const byWord = {
    'perro': '🐶', 'gato': '🐱', 'mascota': '🐾', 'planta': '🌱', 'regar': '🌱', 'ropa': '👕',
    'juguete': '🧸', 'leer': '📖', 'estudi': '📚', 'tarea': '✏️', 'diente': '🪥', 'baño': '🛁',
    'cama': '🛏️', 'basura': '🗑️', 'agua': '💧', 'comer': '🍽️', 'música': '🎹', 'piano': '🎹',
  };
  for (final e in byWord.entries) {
    if (n.contains(e.key)) return e.value;
  }
  return '⭐';
}

// ------------------------------------------------------- escudo familiar

/// Escudo de la familia: forma, color y dibujo.
@immutable
class FamilyCrest {
  const FamilyCrest({this.shape = 0, this.color = 0xFF2563EB, this.emoji = '🏠', this.motto = ''});

  /// 0 escudo, 1 círculo, 2 estrella, 3 corazón.
  final int shape;
  final int color;
  final String emoji;

  /// Lema corto (opcional), por ejemplo "Juntos podemos".
  final String motto;

  static const shapes = ['Escudo', 'Círculo', 'Estrella', 'Corazón'];
  static const emojis = ['🏠', '🦁', '🐻', '🦉', '🌻', '⭐', '🌈', '⚽', '🎵', '🚀', '🌳', '❤️', '🐬', '🦊', '🍀', '👑'];
  static const colors = [0xFF2563EB, 0xFF0F766E, 0xFF7C3AED, 0xFFC2410C, 0xFFDB2777, 0xFFDC2626, 0xFF15803D, 0xFF1E2235];

  FamilyCrest copyWith({int? shape, int? color, String? emoji, String? motto}) => FamilyCrest(
        shape: shape ?? this.shape,
        color: color ?? this.color,
        emoji: emoji ?? this.emoji,
        motto: motto ?? this.motto,
      );

  Map<String, dynamic> toJson() => {'shape': shape, 'color': color, 'emoji': emoji, 'motto': motto};

  static FamilyCrest? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return FamilyCrest(
      shape: (raw['shape'] as num?)?.toInt() ?? 0,
      color: (raw['color'] as num?)?.toInt() ?? 0xFF2563EB,
      emoji: raw['emoji'] as String? ?? '🏠',
      motto: raw['motto'] as String? ?? '',
    );
  }
}

// ------------------------------------------------------- familias amigas

/// Un chico (o adulto) que una familia comparte con una familia amiga: solo
/// apodo y avatar.
@immutable
class FriendKid {
  const FriendKid({required this.id, required this.nickname, required this.avatar});
  final String id;
  final String nickname;
  final AvatarConfig avatar;
}

/// Amistad entre dos hogares, aprobada por un adulto de cada uno.
class Friendship {
  Friendship({required this.id, required this.otherHome, required this.mine, required this.theirs, this.active = true});
  final String id;

  /// Nombre del otro hogar.
  final String otherHome;

  /// Quiénes de mi hogar pueden jugar con ellos.
  final List<FriendKid> mine;

  /// Quiénes del otro hogar pueden jugar con nosotros.
  final List<FriendKid> theirs;
  final bool active;
}

/// Reacciones fijas en las partidas: no hay chat libre.
const gameReactions = ['👍 ¡Buena jugada!', '😄', '😮', '🤔', '⏰ ¡Te toca!', '🏆 ¡Bien jugado!', '🙌 ¡Revancha!'];
