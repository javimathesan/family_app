import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/features/adult/settings_screen.dart';
import 'package:family_app/features/child/today_screen.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  DateTime clock() => DateTime(2026, 10, 30, 7, 25);

  Future<(FamilyStore, AppSession)> demo() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FamilyStore.empty(clock: clock);
    final session = AppSession(store: store, prefs: prefs, storage: FamilyStorage(prefs));
    await session.restore();
    await session.startDemo();
    return (store, session);
  }

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  group('Mi cuarto y mascota', () {
    test('comprar con puntos, mascota y nivel', () {
      final store = FamilyStore.demo(clock: clock);
      final before = store.balanceOf('tomi');
      expect(store.buyRoomItem('tomi', 'poster', 3), isTrue, reason: 'dinosaurio, 40 pts');
      expect(store.balanceOf('tomi'), before - 40);
      expect(store.roomItem('tomi', 'poster').emoji, '🦖');
      expect(store.buyRoomItem('tomi', 'toy', 5), isFalse, reason: 'el robot es de Plus');

      expect(store.hasPet('tomi'), isFalse);
      store.setRoom('tomi', 'pet', 1);
      store.setRoom('tomi', 'petName', 'Firulais');
      expect(store.petName('tomi'), 'Firulais');
      expect(store.petMood('tomi'), PetMood.sleepy);
      expect(store.petLevel('tomi'), greaterThanOrEqualTo(1));

      final copy = FamilyStore.empty(clock: clock)..restoreFrom(store.toJson());
      expect(copy.petName('tomi'), 'Firulais');
      expect(copy.roomChoice('tomi', 'poster'), 3);
    });

    test('medallas', () {
      final store = FamilyStore.demo(clock: clock);
      final medals = store.medalsOf('tomi');
      expect(medals.length, 13);
      expect(medals.firstWhere((m) => m.id == 'primera').earned, isTrue, reason: 'la demo tiene historial');
      expect(medals.firstWhere((m) => m.id == 'robi').earned, isFalse);
      store.signInAs('tomi');
      final g = store.createMatch(GameKind.tateti, ['tomi', botPlayerId]);
      store.playMove(g.id, {'cells': [0, 0, 0, 1, 1, -1, -1, -1, -1]}, nextTurn: 1, winner: 0);
      expect(store.medalsOf('tomi').firstWhere((m) => m.id == 'robi').earned, isTrue);
    });
  });

  test('orden de las tarjetas de Hoy', () {
    const look = MemberLook(home: ['cuerpo', 'reto'], hidden: ['palabra']);
    final order = todayOrder(look);
    expect(order.take(2), ['cuerpo', 'reto']);
    expect(order.length, todayCards.length);
  });

  test('emoji de las tareas', () {
    final store = FamilyStore.demo(clock: clock);
    expect(store.templates.firstWhere((t) => t.id == 'cama').icon, '🛏️');
    expect(taskEmojiFor('x', 'Pasear al perro'), '🐶');
    final t = store.templates.first.copyWith(emoji: '🎹');
    expect(FamilyStore.templateFromJson(FamilyStore.templateToJson(t)).icon, '🎹');
  });

  test('escudo de la familia', () {
    final store = FamilyStore.demo(clock: clock);
    store.setCrest(const FamilyCrest(shape: 2, emoji: '🦁', motto: 'Juntos podemos'));
    final copy = FamilyStore.empty(clock: clock)..restoreFrom(store.toJson());
    expect(copy.crest!.emoji, '🦁');
    expect(copy.crest!.motto, 'Juntos podemos');
  });

  testWidgets('el hijo marca una tarea y hay festejo; abre su cuarto y medallas', (tester) async {
    bigScreen(tester);
    final (store, session) = await demo();
    await tester.pumpWidget(FamilyApp(store: store, session: session));
    await tester.tap(find.text('Tomi'));
    await tester.pumpAndSettle();
    expect(find.text('Adoptá una mascota'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Rutina'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('¡Bien!'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.textContaining('¡Bien!'), findsNothing, reason: 'el festejo se va solo');

    await tester.tap(find.widgetWithText(NavigationDestination, 'Hoy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mi cuarto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perrito'));
    await tester.pumpAndSettle();
    expect(store.hasPet('tomi'), isTrue);
    Navigator.of(tester.element(find.text('Mi cuarto').first)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medallas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('de 13 medallas'), findsOneWidget);
  });

  testWidgets('ajustes del adulto, escudo y modo tablet', (tester) async {
    bigScreen(tester);
    final (store, session) = await demo();
    await tester.pumpWidget(FamilyApp(store: store, session: session));
    await tester.tap(find.text('Papá'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Personalizar'), findsOneWidget);
    expect(find.textContaining('Primeros pasos'), findsOneWidget);
    expect(find.text('Abierto para probar (demostración)'), findsOneWidget);
    await tester.tap(find.textContaining('Primeros pasos'));
    await tester.pumpAndSettle();
    expect(find.text('Sumá a tus hijos'), findsOneWidget);
    Navigator.of(tester.element(find.text('Sumá a tus hijos'))).pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Escudo de la familia'),
      200,
      scrollable: find.descendant(of: find.byType(SettingsScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escudo de la familia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estrella'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(find.text('Guardar escudo'), find.byType(ListView).last, const Offset(0, -300));
    await tester.tap(find.text('Guardar escudo'));
    await tester.pumpAndSettle();
    expect(store.crest!.shape, 2);

    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pushNamed(Routes.tablet);
    await tester.pumpAndSettle();
    expect(find.text('Luli'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tablet_luli')));
    await tester.pumpAndSettle();
    expect(find.text('Tareas de Luli'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(store.doneToday('luli'), 1);

    nav.pushNamed(Routes.reliability);
    await tester.pumpAndSettle();
    expect(find.text('Sacar Family App del ahorro de batería'), findsOneWidget);
  });
}
