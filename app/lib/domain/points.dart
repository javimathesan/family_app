import 'package:flutter/material.dart';

import '../models/models.dart';

/// Reglas de puntos. Funciones puras para poder probarlas sin UI.
abstract final class PointsRules {
  /// Puntos que otorga una tarea según la hora en que se marcó.
  ///
  /// Dentro de la ventana horaria da los puntos completos; fuera de ella,
  /// la mitad redondeada hacia arriba. Marcarla antes de hora cuenta a tiempo.
  static int pointsFor(TaskTemplate task, DateTime completedAt) {
    final scheduled = DateTime(
      completedAt.year,
      completedAt.month,
      completedAt.day,
      task.time.hour,
      task.time.minute,
    );
    final deadline = scheduled.add(Duration(minutes: task.windowMinutes));
    final onTime = !completedAt.isAfter(deadline);
    return onTime ? task.points : (task.points / 2).ceil();
  }

  /// Bonus de racha: +10% de los puntos de la semana por cada semana completa
  /// en la que todos los días se cumplió al menos el 80%.
  static int streakBonus({required int weekPoints, required int streakDays}) {
    final fullWeeks = streakDays ~/ 7;
    if (fullWeeks == 0) return 0;
    return (weekPoints * 0.10 * fullWeeks).round();
  }

  /// La tienda semanal abre de viernes a domingo.
  static bool isStoreOpen(DateTime now) => now.weekday >= DateTime.friday;

  static bool canRedeem({required int balance, required Reward reward}) =>
      balance >= reward.cost;
}

/// Las cinco caritas del calendario.
enum Mood {
  veryHappy('Muy feliz'),
  happy('Feliz'),
  neutral('Neutral'),
  sad('Triste'),
  verySad('Muy triste');

  const Mood(this.label);
  final String label;

  /// Carita según la fracción de tareas cumplidas (0 a 1).
  static Mood fromRatio(double ratio) {
    if (ratio >= 1.0) return Mood.veryHappy;
    if (ratio >= 0.8) return Mood.happy;
    if (ratio >= 0.5) return Mood.neutral;
    if (ratio >= 0.25) return Mood.sad;
    return Mood.verySad;
  }

  Color get faceColor => switch (this) {
        Mood.veryHappy => const Color(0xFFFACC15),
        Mood.happy => const Color(0xFFFEF08A),
        Mood.neutral => const Color(0xFFE5E7EB),
        Mood.sad => const Color(0xFFDBEAFE),
        Mood.verySad => const Color(0xFFC7D2FE),
      };
}

/// Alertas suaves de salud para el adulto. La app no diagnostica.
abstract final class HealthRules {
  static const daysWithoutPoopAlert = 2;

  static bool shouldAlertPoop(List<bool> lastDaysPoop) {
    if (lastDaysPoop.length < daysWithoutPoopAlert) return false;
    final recent = lastDaysPoop.sublist(lastDaysPoop.length - daysWithoutPoopAlert);
    return recent.every((did) => !did);
  }

  static bool reachedWaterGoal(int glasses, int goal) => glasses >= goal;
}
