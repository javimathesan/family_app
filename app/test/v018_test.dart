import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('rutina por días', () {
    test('el colegio es de lunes a viernes y el finde tiene sus tareas', () {
      final viernes = FamilyStore.demo(clock: () => DateTime(2026, 10, 30, 9));
      final sabado = FamilyStore.demo(clock: () => DateTime(2026, 10, 31, 9));
      expect(viernes.tasksFor(DayBlock.school, memberId: 'tomi'), isNotEmpty);
      expect(sabado.tasksFor(DayBlock.school, memberId: 'tomi'), isEmpty);
      expect(sabado.templatesFor('tomi').any((t) => t.id == 'utiles'), isFalse);
      expect(sabado.templatesFor('tomi').any((t) => t.id == 'cuarto'), isTrue);
      expect(viernes.templatesFor('tomi').any((t) => t.id == 'cuarto'), isFalse);
      expect(sabado.isWeekend(), isTrue);
      // El editor muestra todas, sin importar el día.
      expect(sabado.tasksFor(DayBlock.school), isNotEmpty);
    });

    test('las rutinas guardadas sin días pasan el colegio a lunes a viernes', () {
      final t = FamilyStore.templateFromJson({
        'id': 'entrada', 'name': 'Entrar al colegio', 'block': 'school', 'hour': 8, 'minute': 0, 'points': 10,
      });
      expect(t.days, TaskTemplate.weekdays);
      final propia = FamilyStore.templateFromJson({
        'id': 't1', 'name': 'Regar', 'block': 'morning', 'hour': 8, 'minute': 0, 'points': 5,
      });
      expect(propia.days, isEmpty);
      final ida = FamilyStore.templateFromJson(FamilyStore.templateToJson(propia.copyWith(days: {6, 7})));
      expect(ida.days, {6, 7});
      expect(ida.daysLabel, 'Fin de semana');
      expect(TaskTemplate.daysText({1, 3}), 'Lun, Mié');
    });

    test('el resumen del día cuenta solo las tareas de ese día', () {
      final store = FamilyStore.demo(clock: () => DateTime(2026, 10, 31, 9));
      final sabado = DateTime(2026, 10, 31);
      final ids = store.templatesFor('tomi', on: sabado).map((t) => t.id);
      final done = {for (final id in ids) id: TaskCompletion(taskId: id, completedAt: sabado, pointsAwarded: 1)};
      expect(store.summarizeDay(sabado, done, null, memberId: 'tomi').completionRatio, 1);
    });
  });

  group('Mis hábitos opcional', () {
    test('de entrada: agua para todos, baño solo para los más chicos', () {
      final store = FamilyStore.demo(clock: () => DateTime(2026, 10, 30, 9));
      expect(store.memberById('luli')!.bathroomOn, isTrue);
      expect(store.memberById('tomi')!.bathroomOn, isFalse);
      expect(store.memberById('mati')!.waterOn, isTrue);
      store.setHabits('mati', water: false);
      expect(store.memberById('mati')!.habitsOn, isFalse);
      final copia = FamilyStore.memberFromJson(FamilyStore.memberToJson(store.memberById('mati')!));
      expect(copia.water, isFalse);
      expect(copia.bathroom, isNull);
      expect(FamilyStore.memberToJson(store.memberById('tomi')!).containsKey('water'), isFalse);
    });
  });

  group('partidas repetidas', () {
    test('encuentra la partida abierta con los mismos jugadores', () {
      final store = FamilyStore.demo(clock: () => DateTime(2026, 10, 30, 9));
      final m = store.createMatch(GameKind.tateti, ['tomi', 'luli']);
      expect(store.activeMatchWith(GameKind.tateti, ['luli', 'tomi'])?.id, m.id);
      expect(store.activeMatchWith(GameKind.cuatro, ['tomi', 'luli']), isNull);
      expect(store.activeMatchWith(GameKind.tateti, ['tomi', 'mati']), isNull);
    });

    testWidgets('avisa que ya hay una partida y deja seguirla', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = FamilyStore.empty(clock: () => DateTime(2026, 10, 30, 7, 25));
      final session = AppSession(store: store, prefs: prefs, storage: FamilyStorage(prefs));
      await session.restore();
      await session.startDemo();
      store.setGamesRule(GamesRule.free);
      store.createMatch(GameKind.tateti, ['tomi', botPlayerId]);
      final before = store.matches.length;

      await tester.pumpWidget(FamilyApp(store: store, session: session));
      await tester.tap(find.text('Tomi'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NavigationDestination, 'Juegos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tres en raya').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Robi (la compu)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('¡A jugar!'));
      await tester.pumpAndSettle();

      expect(find.text('Ya tenés una partida de Tres en raya'), findsOneWidget);
      await tester.tap(find.text('Seguir esa partida'));
      await tester.pumpAndSettle();
      expect(store.matches.length, before);
    });
  });
}
