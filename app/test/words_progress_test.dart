import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/learning/vocabulary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  DateTime clock() => DateTime(2026, 10, 30, 7, 25);

  test('estrellas, escalera de temas y nivel medio', () {
    final store = FamilyStore.demo(clock: clock);
    final basic = topicsOf(WordLevel.basico);
    expect(store.topicUnlocked('tomi', Lang.en, basic[0]), isTrue);
    expect(store.topicUnlocked('tomi', Lang.en, basic[1]), isFalse);
    expect(store.topicUnlocked('adulto', Lang.en, basic[3]), isTrue, reason: 'los adultos tienen todo abierto');

    store.recordQuiz('tomi', Lang.en, basic[0].id, score: 4, right: basic[0].words.take(4).toList(), wrong: [basic[0].words[4]]);
    expect(store.topicStars('tomi', Lang.en, basic[0].id), 2);
    expect(store.topicUnlocked('tomi', Lang.en, basic[1]), isTrue);
    expect(store.reviewWords('tomi', Lang.en).single.es, basic[0].words[4].es);

    // Un puntaje peor no baja las estrellas.
    store.recordQuiz('tomi', Lang.en, basic[0].id, score: 1, right: const [], wrong: const []);
    expect(store.topicStars('tomi', Lang.en, basic[0].id), 2);

    expect(store.levelUnlocked('tomi', Lang.en, WordLevel.medio), isFalse);
    for (final t in basic.take(5)) {
      store.recordQuiz('tomi', Lang.en, t.id, score: 5, right: const [], wrong: const []);
    }
    expect(store.levelUnlocked('tomi', Lang.en, WordLevel.medio), isTrue);
    expect(store.topicStars('tomi', Lang.pt, basic[0].id), 0, reason: 'cada idioma avanza por separado');

    // Acertar en el repaso saca la palabra de la lista.
    store.recordQuiz('tomi', Lang.en, reviewTopicId, score: 1, right: [basic[0].words[4]], wrong: const []);
    expect(store.reviewWords('tomi', Lang.en), isEmpty);

    final copy = FamilyStore.empty(clock: clock)..restoreFrom(store.toJson());
    expect(copy.topicStars('tomi', Lang.en, basic[2].id), 3);
  });

  test('récords de juegos', () {
    final store = FamilyStore.demo(clock: clock);
    expect(store.saveScore('tomi', 'tiro', 120), isTrue);
    expect(store.saveScore('tomi', 'tiro', 80), isFalse);
    expect(store.bestScore('tomi', 'tiro'), 120);
  });

  test('paquetes de palabras', () {
    final t = topicFromJson({
      'id': 'fiestas',
      'label': 'Fiestas',
      'level': 'medio',
      'words': [
        for (final es in ['torta', 'regalo', 'vela', 'fiesta']) {'emoji': '🎉', 'es': es, 'en': es, 'pt': es, 'ko': es, 'ko_r': es},
      ],
    });
    expect(t, isNotNull);
    extraTopics = [t!];
    addTearDown(() => extraTopics = []);
    expect(topicsOf(WordLevel.medio).last.id, 'fiestas');
    expect(topicFromJson({'id': 'x', 'words': []}), isNull);
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

  testWidgets('juegos de palabras: escuchar, memoria y letras', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (store, session) = await demo();
    store.signInAs('tomi');
    await tester.pumpWidget(FamilyApp(store: store, session: session));
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);

    nav.pushNamed('${Routes.words}/escuchar?lang=en&topic=animales');
    await tester.pumpAndSettle();
    expect(find.text('Escuchar otra vez'), findsOneWidget);
    await tester.tap(find.byType(InkWell).at(1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    nav.pop();
    await tester.pumpAndSettle();

    nav.pushNamed('${Routes.words}/memoria?lang=en&topic=animales');
    await tester.pumpAndSettle();
    expect(find.textContaining('Parejas: 0 de 6'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mem_0')));
    await tester.pump();
    nav.pop();
    await tester.pumpAndSettle();

    nav.pushNamed('${Routes.words}/letras?lang=en&topic=colores');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('letra_0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('letra_0')));
    await tester.pump();
    expect(find.text('Borrar'), findsOneWidget);
    nav.pop();
    await tester.pumpAndSettle();

    nav.pushNamed(Routes.words);
    await tester.pumpAndSettle();
    expect(find.textContaining('☆☆☆'), findsWidgets);
  });
}
