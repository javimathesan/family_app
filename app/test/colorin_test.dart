import 'dart:math';

import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/features/games/target_game.dart';
import 'package:family_app/games/colorin.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ColorinState fixed({required List<List<String>> hands, String top = 'r5', List<String>? deck}) => ColorinState(
      deck: deck ?? ['g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7', 'g8'],
      discard: [top],
      hands: {for (var i = 0; i < hands.length; i++) '$i': [...hands[i]]},
      color: Colorin.colorOf(top),
    );

void main() {
  test('mazo de 108 cartas y reparto', () {
    expect(Colorin.newDeck().length, 108);
    final s = ColorinState.deal(4, Random(1));
    expect(s.hand(0).length, 7);
    expect(s.deck.length + s.discard.length + 28, 108);
    expect(RegExp(r'^[rygb][0-9]$').hasMatch(s.top), isTrue);
    expect(ColorinState.fromJson(s.toJson()).toJson(), s.toJson());
  });

  test('se tira por color o por número; los comodines siempre', () {
    final s = fixed(hands: [['r1', 'b5', 'g2', 'wW'], ['y1']]);
    expect(s.playable(0), [0, 1, 3]);
    final step = s.play(0, 3, chosen: 'g');
    expect(step.state.color, 'g');
    expect(step.nextTurn, 1);
  });

  test('bloqueo, reversa, +2 y +4', () {
    final skip = fixed(hands: [['rS', 'b1'], ['y1'], ['y2']]).play(0, 0);
    expect(skip.nextTurn, 2);

    final rev = fixed(hands: [['rR', 'b1'], ['y1'], ['y2']]).play(0, 0);
    expect(rev.nextTurn, 2, reason: 'con 3 jugadores la reversa vuelve para atrás');
    expect(rev.state.direction, -1);

    final rev2 = fixed(hands: [['rR', 'b1'], ['y1']]).play(0, 0);
    expect(rev2.nextTurn, 0, reason: 'de a 2, la reversa es como un bloqueo');

    final plus2 = fixed(hands: [['rD', 'b1'], ['y1'], ['y2']]).play(0, 0);
    expect(plus2.state.hand(1).length, 3);
    expect(plus2.nextTurn, 2);

    final plus4 = fixed(hands: [['wF', 'b1'], ['y1']]).play(0, 0, chosen: 'b');
    expect(plus4.state.hand(1).length, 5);
    expect(plus4.nextTurn, 0);
  });

  test('¡Última! y ganar', () {
    final forgot = fixed(hands: [['r1', 'b2'], ['y1']]).play(0, 0);
    expect(forgot.state.hand(0).length, 3, reason: 'no dijo Última: roba 2');
    final said = fixed(hands: [['r1', 'b2'], ['y1']]).play(0, 0, saidLast: true);
    expect(said.state.hand(0).length, 1);
    final win = fixed(hands: [['r1'], ['y1']]).play(0, 0);
    expect(win.winner, 0);
  });

  test('robar: si sirve sigue, si no pasa; el mazo se rearma', () {
    final good = fixed(hands: [['b1'], ['y1']], deck: ['r9']).draw(0);
    expect(good.nextTurn, 0);
    expect(good.state.drew, isTrue);
    expect(good.state.pass(0).nextTurn, 1);

    final bad = fixed(hands: [['b1'], ['y1']], deck: ['g9']).draw(0);
    expect(bad.nextTurn, 1);

    final empty = ColorinState(deck: [], discard: ['g1', 'g2', 'r5'], hands: {'0': ['b1'], '1': ['y1']}, color: 'r').draw(0, random: Random(2));
    expect(empty.state.discard, ['r5']);
    expect(empty.state.hand(0).length, 2);
  });

  test('Robi elige una carta que se puede tirar y un color', () {
    final s = fixed(hands: [['wW', 'b1', 'r7', 'rS'], ['y1']]);
    final c = s.botChoice(0);
    expect(c.card, 3, reason: 'prefiere la acción del mismo color');
    final w = fixed(hands: [['wW', 'b1', 'b2'], ['y1']]).botChoice(0);
    expect(w.color, 'b');
  });

  Future<(FamilyStore, AppSession)> demo() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FamilyStore.empty(clock: () => DateTime(2026, 10, 30, 7, 25));
    final session = AppSession(store: store, prefs: prefs, storage: FamilyStorage(prefs));
    await session.restore();
    await session.startDemo();
    return (store, session);
  }

  testWidgets('Colorín contra Robi y tiro al blanco', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (store, session) = await demo();
    store.signInAs('adulto');
    final match = store.createMatch(GameKind.colorin, ['adulto', botPlayerId]);
    await tester.pumpWidget(FamilyApp(store: store, session: session));
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pushNamed(Routes.matchOf(match.id));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('colorin_mazo')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('colorin_mazo')));
    await tester.pump();
    final m = store.matchById(match.id)!;
    expect(m.lastBy, 'adulto');
    // Si pasó el turno, Robi juega solo.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    nav.pop();
    await tester.pumpAndSettle();

    nav.push(MaterialPageRoute<void>(builder: (_) => const TargetGameScreen(seconds: 1)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('¡Empezar!'));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('¡Se terminó el tiempo!'), findsOneWidget);
  });
}
