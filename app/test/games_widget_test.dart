import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<(FamilyStore, AppSession)> demo() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FamilyStore.empty(clock: () => DateTime(2026, 10, 30, 7, 25));
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

  testWidgets('el hijo ve el candado hasta hacer su rutina', (tester) async {
    bigScreen(tester);
    final (store, session) = await demo();
    await tester.pumpWidget(FamilyApp(store: store, session: session));
    await tester.tap(find.text('Tomi'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Juegos'));
    await tester.pumpAndSettle();
    expect(find.text('Primero la rutina'), findsOneWidget);
  });

  testWidgets('tres en raya contra Robi: juega el chico y responde Robi', (tester) async {
    bigScreen(tester);
    final (store, session) = await demo();
    store.setGamesRule(GamesRule.free);
    await tester.pumpWidget(FamilyApp(store: store, session: session));
    await tester.tap(find.text('Tomi'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Juegos'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tres en raya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Robi (la compu)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('¡A jugar!'));
    await tester.pumpAndSettle();

    expect(find.text('Te toca'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tateti_4')));
    await tester.pump();
    expect(find.text('Robi está pensando…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Te toca'), findsOneWidget);
    final match = store.matchesOf('tomi').single;
    expect((match.state['cells'] as List).where((c) => c != -1).length, 2);
  });

  testWidgets('el adulto abre Juegos y cambia la regla', (tester) async {
    bigScreen(tester);
    final (store, session) = await demo();
    await tester.pumpWidget(FamilyApp(store: store, session: session));
    await tester.tap(find.text('Papá'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Juegos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reglas de juego de los chicos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siempre'));
    await tester.pumpAndSettle();
    expect(store.gamesRule, GamesRule.free);
    await tester.tap(find.text('30 min'));
    await tester.pumpAndSettle();
    expect(store.gamesMinutes, 30);

    for (final game in ['4 en línea', 'Ludo', 'Ajedrez']) {
      expect(find.text(game), findsOneWidget);
    }
  });

  testWidgets('ajedrez y ludo se abren y se puede mover', (tester) async {
    bigScreen(tester);
    final (store, session) = await demo();
    store.signInAs('adulto');
    final chess = store.createMatch(GameKind.ajedrez, ['adulto', 'tomi'], sameDevice: true);
    final ludo = store.createMatch(GameKind.ludo, ['adulto', 'tomi', 'luli'], sameDevice: true);
    await tester.pumpWidget(FamilyApp(store: store, session: session));
    await tester.tap(find.text('Papá'));
    await tester.pumpAndSettle();

    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pushNamed(Routes.matchOf(chess.id));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chess_e2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('chess_e4')));
    await tester.pumpAndSettle();
    expect(store.matchById(chess.id)!.turn, 1);
    expect(find.textContaining('pasale el teléfono'), findsOneWidget);

    nav.pushNamed(Routes.matchOf(ludo.id));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tirar el dado'));
    await tester.pumpAndSettle();
    expect(store.matchById(ludo.id)!.lastBy, 'adulto');
  });
}
