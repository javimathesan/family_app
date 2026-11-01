import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;

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
    this.glasses = false,
    this.shirt = 0,
    this.accessory = 0,
    this.outfit = 0,
    this.brows = 0,
    this.freckles = false,
  });

  /// Cejas: 0 sin, 1 finas, 2 gruesas.
  final int brows;
  final bool freckles;

  final int skin;
  final int hairStyle;
  final int hairColor;
  final int eyes;
  final bool glasses;
  final int shirt;
  final int accessory;

  /// Disfraz (0 = remera). Ver `AvatarOptions.outfits`.
  final int outfit;

  AvatarConfig copyWith({
    int? skin,
    int? hairStyle,
    int? hairColor,
    int? eyes,
    bool? glasses,
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
      glasses: glasses ?? this.glasses,
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
  });

  final LookMode mode;

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
  }) =>
      MemberLook(
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
      listEquals(other.hidden, hidden);

  @override
  int get hashCode => Object.hash(mode, background, cards, party, world, Object.hashAll(home), Object.hashAll(hidden));
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
    (name: 'Con borde', plus: true),
    (name: 'Bien redondas', plus: true),
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
  });

  final String id;
  final String name;
  final DayBlock block;

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
  }) =>
      TaskTemplate(
        id: id,
        emoji: emoji ?? this.emoji,
        name: name ?? this.name,
        block: block ?? this.block,
        time: time ?? this.time,
        points: points ?? this.points,
        validation: validation ?? this.validation,
        windowMinutes: windowMinutes ?? this.windowMinutes,
        assignedTo: assignedTo ?? this.assignedTo,
      );
}

/// Meta diaria del adulto ("Mi día"). No da puntos: es para dar el ejemplo.
@immutable
class AdultGoal {
  const AdultGoal(this.id, this.label, this.icon, {this.notice});

  /// Siempre empieza con `meta_` para no mezclarse con las tareas de los chicos.
  final String id;
  final String label;
  final IconData icon;

  /// Si no es `null`, al marcarla se avisa al hogar: "<apodo> <notice>".
  final String? notice;

  static const all = <AdultGoal>[
    AdultGoal('meta_ejercicio', 'Hice ejercicio', Icons.directions_run),
    AdultGoal('meta_lectura', 'Leí o estudié', Icons.menu_book_outlined),
    AdultGoal('meta_jugar', 'Jugué con mis hijos', Icons.toys_outlined, notice: 'jugó con sus hijos'),
    AdultGoal('meta_mesa', 'Comida en familia sin celulares', Icons.dinner_dining_outlined, notice: 'propuso comer en familia sin celulares'),
    AdultGoal('meta_amigos', 'Tiempo con amigos', Icons.groups_outlined),
    AdultGoal('meta_pantalla', 'Menos de 2 horas de pantalla', Icons.phonelink_off_outlined),
  ];

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
  });

  final String taskId;
  final DateTime completedAt;
  final int pointsAwarded;
  final bool pendingApproval;
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
  });

  final String id;
  final String name;
  final int cost;

  /// Clave del ícono en [rewardIcons] (se guarda como texto en la nube).
  final String iconKey;
  final bool monthly;

  IconData get icon => rewardIcons[iconKey] ?? Icons.card_giftcard_outlined;

  Reward copyWith({String? name, int? cost, String? iconKey}) => Reward(
        id: id,
        name: name ?? this.name,
        cost: cost ?? this.cost,
        iconKey: iconKey ?? this.iconKey,
        monthly: monthly,
      );
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
