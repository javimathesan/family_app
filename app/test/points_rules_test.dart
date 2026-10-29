import 'package:family_app/domain/points.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cama = TaskTemplate(
    id: 'cama',
    name: 'Tender la cama',
    block: DayBlock.morning,
    time: TimeOfDay(hour: 7, minute: 20),
    points: 5,
  );

  group('PointsRules.pointsFor', () {
    test('a tiempo da los puntos completos', () {
      expect(PointsRules.pointsFor(cama, DateTime(2026, 10, 29, 7, 25)), 5);
    });

    test('antes de hora cuenta a tiempo', () {
      expect(PointsRules.pointsFor(cama, DateTime(2026, 10, 29, 6, 50)), 5);
    });

    test('en el límite de la ventana todavía cuenta a tiempo', () {
      expect(PointsRules.pointsFor(cama, DateTime(2026, 10, 29, 7, 50)), 5);
    });

    test('tarde da la mitad redondeada hacia arriba', () {
      expect(PointsRules.pointsFor(cama, DateTime(2026, 10, 29, 7, 51)), 3);
    });
  });

  group('PointsRules', () {
    test('la racha da +10% por semana completa', () {
      expect(PointsRules.streakBonus(weekPoints: 500, streakDays: 6), 0);
      expect(PointsRules.streakBonus(weekPoints: 500, streakDays: 7), 50);
      expect(PointsRules.streakBonus(weekPoints: 500, streakDays: 14), 100);
    });

    test('la tienda abre de viernes a domingo', () {
      expect(PointsRules.isStoreOpen(DateTime(2026, 10, 29)), isFalse); // jueves
      expect(PointsRules.isStoreOpen(DateTime(2026, 10, 30)), isTrue); // viernes
      expect(PointsRules.isStoreOpen(DateTime(2026, 11, 1)), isTrue); // domingo
      expect(PointsRules.isStoreOpen(DateTime(2026, 11, 2)), isFalse); // lunes
    });
  });

  group('Mood.fromRatio', () {
    test('respeta los rangos del calendario', () {
      expect(Mood.fromRatio(1.0), Mood.veryHappy);
      expect(Mood.fromRatio(0.85), Mood.happy);
      expect(Mood.fromRatio(0.8), Mood.happy);
      expect(Mood.fromRatio(0.6), Mood.neutral);
      expect(Mood.fromRatio(0.3), Mood.sad);
      expect(Mood.fromRatio(0.1), Mood.verySad);
    });
  });

  group('HealthRules', () {
    test('avisa tras 2 días sin popó', () {
      expect(HealthRules.shouldAlertPoop([true, false]), isFalse);
      expect(HealthRules.shouldAlertPoop([true, false, false]), isTrue);
      expect(HealthRules.shouldAlertPoop([false]), isFalse);
    });
  });
}
