import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('favoritos: jugadores y juegos, con los favoritos primero', () {
    final store = FamilyStore.demo(clock: () => DateTime(2026, 11, 3, 9));
    expect(store.isFavoritePlayer('tomi', 'luli'), isFalse);
    store.toggleFavoritePlayer('tomi', 'luli');
    expect(store.isFavoritePlayer('tomi', 'luli'), isTrue);
    expect(store.isFavoritePlayer('mati', 'luli'), isFalse);
    store.toggleFavoritePlayer('tomi', 'luli');
    expect(store.isFavoritePlayer('tomi', 'luli'), isFalse);

    store.toggleFavoriteGame('tomi', GameKind.colorin);
    expect(store.gamesFor('tomi').first, GameKind.colorin);
    expect(store.gamesFor('tomi').length, GameKind.values.length);
    expect(store.gamesFor('luli').first, GameKind.values.first);
  });

  testWidgets('la estrella de un juego lo pasa al principio y la hoja marca favoritos', (tester) async {
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

    await tester.pumpWidget(FamilyApp(store: store, session: session));
    await tester.tap(find.text('Tomi'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Juegos'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('fav_ajedrez')));
    await tester.pumpAndSettle();
    expect(store.gamesFor('tomi').first, GameKind.ajedrez);

    await tester.tap(find.text('Tres en raya').first);
    await tester.pumpAndSettle();
    expect(find.text('Tu familia'), findsOneWidget);
    // La estrella del chip de Luli la pasa a Favoritos.
    final luli = find.byKey(const ValueKey('rival_luli'));
    await tester.tap(find.descendant(of: luli, matching: find.byIcon(Icons.star_border_rounded)));
    await tester.pumpAndSettle();
    expect(store.isFavoritePlayer('tomi', 'luli'), isTrue);
    expect(find.text('⭐ Favoritos'), findsOneWidget);
  });
}
