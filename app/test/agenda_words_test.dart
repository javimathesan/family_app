import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_cloud.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/learning/vocabulary.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  DateTime clock() => DateTime(2026, 10, 30, 7, 25);

  group('Agenda', () {
    test('cada uno ve lo suyo y los adultos ven todo', () {
      final store = FamilyStore.demo(clock: clock)..signInAs('adulto');
      store.saveEvent(AgendaEvent(
        id: store.newEventId(),
        title: 'Turno médico',
        place: 'Hospital',
        at: DateTime(2026, 11, 3, 16, 30),
        memberIds: {'tomi'},
        remindMinutes: 60,
        createdBy: 'adulto',
      ));
      store.saveEvent(AgendaEvent(id: store.newEventId(), title: 'Cumple de la abuela', at: DateTime(2026, 11, 5, 20), createdBy: 'adulto'));
      expect(store.eventsFor('tomi').length, 2);
      expect(store.eventsFor('luli').map((e) => e.title), ['Cumple de la abuela']);
      expect(store.eventsFor('adulto').length, 2);
      expect(store.events.first.remindAt, DateTime(2026, 11, 3, 15, 30));
      expect(store.notices.first.text, contains('agregó a la agenda: Cumple de la abuela'));

      final copy = FamilyStore.empty(clock: clock)..restoreFrom(store.toJson());
      expect(copy.events.first.place, 'Hospital');
      expect(copy.events.first.memberIds, {'tomi'});

      store.removeEvent(store.events.first.id);
      expect(store.events.length, 1);
    });

    test('se sincroniza entre teléfonos', () async {
      final db = FakeFirebaseFirestore();
      final cloudA = FamilyCloud(db: db, uid: 'tel-a', clock: clock);
      final cloudB = FamilyCloud(db: db, uid: 'tel-b', clock: clock);
      final a = FamilyStore.empty(clock: clock);
      final b = FamilyStore.empty(clock: clock);
      addTearDown(cloudA.detach);
      addTearDown(cloudB.detach);
      final home = await cloudA.createHome(homeName: 'Casa', nickname: 'Papá');
      cloudA.attach(a, home.homeId);
      cloudB.attach(b, home.homeId);
      await settle();
      a.signInAs(home.memberId);
      final e = AgendaEvent(id: a.newEventId(), title: 'Acto del colegio', at: DateTime(2026, 11, 10, 10), alarm: true, remindMinutes: 30, createdBy: home.memberId);
      a.saveEvent(e);
      await settle();
      expect(b.eventById(e.id)?.title, 'Acto del colegio');
      expect(b.eventById(e.id)?.alarm, isTrue);
      a.removeEvent(e.id);
      await settle();
      expect(b.eventById(e.id), isNull);
    });

    testWidgets('el adulto agrega un turno desde el formulario', (tester) async {
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
      await tester.tap(find.widgetWithText(OutlinedButton, 'Agenda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '¿Qué es?'), 'Turno médico');
      await tester.enterText(find.widgetWithText(TextField, 'Lugar (opcional)'), 'Clínica');
      await tester.tap(find.text('Tomi'));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(find.text('Guardar'), find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(store.events.single.title, 'Turno médico');
      expect(store.events.single.memberIds, {'tomi'});
      expect(store.events.single.remindMinutes, 60);
      expect(find.text('Turno médico'), findsOneWidget);
      expect(find.text('Mañana'), findsOneWidget);
    });
  });

  group('Palabras', () {
    test('todas las palabras tienen las 3 traducciones', () {
      for (final w in [for (final t in topics) ...t.words]) {
        for (final l in Lang.values) {
          expect(w.inLang(l), isNotEmpty);
        }
        expect(w.koRoman, isNotEmpty);
      }
      expect(topicsOf(WordLevel.basico).length, 7);
      expect(topicsOf(WordLevel.medio).length, 6);
      expect(topicsOf(WordLevel.avanzado).length, 3);
    });

    test('la palabra del día cambia con el día y respeta los idiomas', () {
      final a = wordOfTheDay(DateTime(2026, 10, 30), [Lang.en]);
      final b = wordOfTheDay(DateTime(2026, 10, 31), [Lang.en]);
      expect(a.lang, Lang.en);
      expect(a.word, isNot(b.word));
    });

    test('el quiz da puntos una sola vez por día y no cuenta como tarea', () {
      final store = FamilyStore.demo(clock: clock);
      final before = store.balanceOf('tomi');
      expect(store.awardWordQuiz('tomi', 4, 'inglés'), 4);
      expect(store.awardWordQuiz('tomi', 5, 'inglés'), 0);
      expect(store.balanceOf('tomi'), before + 4);
      expect(store.doneToday('tomi'), 0);
      expect(store.pointsToday('tomi'), 4);
      expect(store.awardWordQuiz('adulto', 5, 'inglés'), 0);
    });

    testWidgets('quiz completo con todas bien', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = FamilyStore.empty(clock: clock);
      final session = AppSession(store: store, prefs: prefs, storage: FamilyStorage(prefs));
      await session.restore();
      await session.startDemo();
      store.signInAs('tomi');
      await tester.pumpWidget(FamilyApp(store: store, session: session));
      await tester.pumpAndSettle();
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pushNamed('${Routes.words}/quiz?lang=en&topic=animales');
      await tester.pumpAndSettle();

      final question = RegExp(r'¿Cómo se dice "(.+)" en inglés\?');
      for (var i = 0; i < 5; i++) {
        final text = tester.widget<Text>(find.textContaining('¿Cómo se dice')).data!;
        final es = question.firstMatch(text)!.group(1)!;
        await tester.tap(find.byKey(ValueKey('opcion_$es')));
        await tester.pumpAndSettle();
        expect(find.text('¡Muy bien! 🎉'), findsOneWidget);
        await tester.tap(find.text(i < 4 ? 'Siguiente' : 'Ver resultado'));
        await tester.pumpAndSettle();
      }
      expect(find.text('5 de 5'), findsOneWidget);
      expect(find.text('¡Ganaste 5 puntos!'), findsOneWidget);
    });
  });
}
