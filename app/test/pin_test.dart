import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
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

  test('el PIN se guarda como resumen y se verifica', () async {
    final (_, session) = await demo();
    expect(session.hasPin, isFalse);
    expect(session.checkPin('0000'), isTrue, reason: 'sin PIN, se puede entrar');

    await session.setPin('4821');
    expect(session.hasPin, isTrue);
    expect(session.checkPin('4821'), isTrue);
    expect(session.checkPin('1111'), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('session_pin'), isNot(contains('4821')));

    await session.clearPin();
    expect(session.hasPin, isFalse);
  });

  test('solo acepta 4 números', () async {
    final (_, session) = await demo();
    expect(AppSession.isValidPin('12a4'), isFalse);
    expect(AppSession.isValidPin('123'), isFalse);
    expect(() => session.setPin('12345'), throwsArgumentError);
  });

  testWidgets('con PIN, el perfil del adulto no se abre sin el número correcto', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final (store, session) = await demo();
    await session.setPin('4821');
    await tester.pumpWidget(FamilyApp(store: store, session: session));

    await tester.tap(find.text('Papá'));
    await tester.pumpAndSettle();
    expect(find.text('PIN del modo adulto'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1111');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing, reason: 'el diálogo se cierra');
    expect(find.text('Mi familia'), findsNothing);
    // Espera a que se vaya el aviso de PIN incorrecto.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Papá'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '4821');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
    await tester.pumpAndSettle();
    expect(find.text('Mi familia'), findsOneWidget);
    expect(find.text('Mi día'), findsOneWidget);

    // Los chicos entran sin PIN.
    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cambiar de usuario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomi'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Tomi'), findsOneWidget);
  });
}
