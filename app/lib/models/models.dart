import 'package:flutter/material.dart';

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
  });

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
  }) {
    return AvatarConfig(
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
  }) : unlocked = unlocked ?? {};

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
  });

  final String id;
  final String name;
  final DayBlock block;

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
  }) =>
      TaskTemplate(
        id: id,
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
  info(false, Icons.info_outline);

  const NoticeKind(this.important, this.icon);
  final bool important;
  final IconData icon;
}
