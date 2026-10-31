import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/learning/vocabulary.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  DateTime clock() => DateTime(2026, 10, 30, 7, 25);

  test('los últimos 7 días terminan hoy', () {
    final store = FamilyStore.demo(clock: clock);
    store.toggleTask('tomi', 'aseo');
    final days = store.lastDays('tomi');
    expect(days.length, 7);
    expect(days.last.date, DateTime(2026, 10, 30));
    expect(days.last.summary!.points, greaterThan(0));
    expect(days.first.summary, isNotNull, reason: 'la demo tiene historial');
  });

  test('reto de la semana: progreso y cobro una sola vez', () {
    // Viernes 30/10: la semana empezó el lunes 26.
    final store = FamilyStore.demo(clock: clock)..setChallenge(const WeeklyChallenge(type: ChallengeType.puntos, target: 50, bonus: 20));
    expect(store.weekStart, DateTime(2026, 10, 26));
    expect(store.challengeProgress('tomi'), greaterThanOrEqualTo(50), reason: 'la demo tiene días con puntos');
    final before = store.balanceOf('tomi');
    expect(store.claimChallenge('tomi'), isTrue);
    expect(store.balanceOf('tomi'), before + 20);
    expect(store.claimChallenge('tomi'), isFalse);
    expect(store.challengeClaimed('tomi'), isTrue);

    final copy = FamilyStore.empty(clock: clock)..restoreFrom(store.toJson());
    expect(copy.challenge!.target, 50);
    expect(copy.challengeClaimed('tomi'), isTrue);
    store.setChallenge(null);
    expect(store.challenge, isNull);
  });

  Future<(FamilyStore, AppSession)> demo() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FamilyStore.empty(clock: clock);
    final session = AppSession(store: store, prefs: prefs, storage: FamilyStorage(prefs));
    await session.restore();
    await session.startDemo();
    return (store, session);
  }

  testWidgets('resumen de la semana y niveles de palabras', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (store, session) = await demo();
    await tester.pumpWidget(FamilyApp(store: store, session: session));
    await tester.tap(find.text('Papá'));
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);

    nav.pushNamed(Routes.week);
    await tester.pumpAndSettle();
    expect(find.text('Tomi'), findsOneWidget);
    expect(find.textContaining('pts en la semana'), findsWidgets);
    nav.pop();
    await tester.pumpAndSettle();

    nav.pushNamed(Routes.words);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medio'));
    await tester.pumpAndSettle();
    expect(find.text('Ropa'), findsOneWidget);
    await tester.tap(find.text('Avanzado'));
    await tester.pumpAndSettle();
    // En la demostración el avanzado está abierto para probar.
    expect(find.text('Frases útiles'), findsOneWidget);
    expect(find.text('Nivel avanzado: Family App Plus'), findsNothing);
    expect(topicsOf(WordLevel.avanzado).length, 3);

    nav.pushNamed(Routes.privacy);
    await tester.pumpAndSettle();
    expect(find.text('Qué NO pedimos'), findsOneWidget);
  });
}
