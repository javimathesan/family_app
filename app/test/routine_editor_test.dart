import 'dart:convert';

import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  DateTime clock() => DateTime(2026, 10, 30, 7, 25);

  group('editar la rutina y los premios', () {
    late FamilyStore store;
    setUp(() => store = FamilyStore.demo(clock: clock));

    test('agregar una tarea la ubica por horario en su bloque', () {
      final t = TaskTemplate(
        id: store.newTemplateId(),
        name: 'Pasear al perro',
        block: DayBlock.morning,
        time: const TimeOfDay(hour: 7, minute: 5),
        points: 7,
      );
      store.saveTemplate(t);
      final manana = store.tasksFor(DayBlock.morning);
      expect(manana[1].name, 'Pasear al perro');
      expect(store.templates.length, FamilyStore.defaultTemplates.length + 1);
    });

    test('editar y borrar una tarea', () {
      final cama = store.templates.firstWhere((t) => t.id == 'cama');
      store.saveTemplate(cama.copyWith(points: 12, validation: Validation.self));
      expect(store.templates.firstWhere((t) => t.id == 'cama').points, 12);

      store.toggleTask('tomi', 'cama');
      expect(store.pointsToday('tomi'), 12);

      store.removeTemplate('cama');
      expect(store.templates.any((t) => t.id == 'cama'), isFalse);
      expect(store.pendingTaskApprovals, isEmpty);
    });

    test('los cambios no tocan la rutina por defecto de otros hogares', () {
      store.removeTemplate('aseo');
      expect(FamilyStore.defaultTemplates.any((t) => t.id == 'aseo'), isTrue);
      expect(FamilyStore.demo(clock: clock).templates.any((t) => t.id == 'aseo'), isTrue);
    });

    test('premios: crear, editar costo e ícono, y borrar', () {
      final pizza = Reward(id: store.newRewardId(), name: 'Pizza el viernes', cost: 90, iconKey: 'comida');
      store.saveReward(pizza);
      expect(store.rewardById(pizza.id)!.icon, Icons.lunch_dining_outlined);

      store.saveReward(pizza.copyWith(cost: 40));
      expect(store.rewards.first.id, pizza.id, reason: 'ordenados por costo');

      store.removeReward(pizza.id);
      expect(store.rewardById(pizza.id), isNull);
    });

    test('la rutina y los premios editados se guardan en la demostración', () {
      store.removeTemplate('aseo');
      store.saveReward(const Reward(id: 'x', name: 'Cine', cost: 120, iconKey: 'pelicula'));
      final json = jsonDecode(jsonEncode(store.toJson())) as Map<String, dynamic>;
      final copia = FamilyStore.empty(clock: clock)..restoreFrom(json);
      expect(copia.templates.any((t) => t.id == 'aseo'), isFalse);
      expect(copia.rewardById('x')!.name, 'Cine');
    });
  });

  testWidgets('el adulto agrega una tarea desde Rutina y premios', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FamilyStore.empty(clock: clock);
    final session = AppSession(store: store, prefs: prefs, storage: FamilyStorage(prefs));
    await session.restore();
    await session.startDemo();
    await tester.pumpWidget(FamilyApp(store: store, session: session));

    await tester.tap(find.text('Papá'));
    await tester.pumpAndSettle();
    expect(find.text('Adultos del hogar'), findsOneWidget);

    await tester.tap(find.text('Rutina y premios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Pasear al perro');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(store.templates.any((t) => t.name == 'Pasear al perro'), isTrue);
  });
}
