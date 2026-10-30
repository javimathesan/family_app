import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<(FamilyStore, AppSession)> demoApp() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FamilyStore.empty(clock: () => DateTime(2026, 10, 30, 7, 25));
    final session = AppSession(store: store, prefs: prefs, storage: FamilyStorage(prefs));
    await session.restore();
    return (store, session);
  }

  void phoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('sin servidor, la primera vez ofrece la demostración', (tester) async {
    phoneSize(tester);
    final (store, session) = await demoApp();
    await tester.pumpWidget(FamilyApp(store: store, session: session));

    expect(find.text('Crear mi hogar'), findsOneWidget);
    expect(find.textContaining('Sin conexión con el servidor'), findsOneWidget);

    await tester.tap(find.text('Probar con datos de ejemplo'));
    await tester.pumpAndSettle();
    expect(find.text('¿Quién usa la app?'), findsOneWidget);
    expect(find.text('Tomi'), findsOneWidget);
  });

  testWidgets('se puede entrar como hijo y navegar las 4 secciones', (tester) async {
    phoneSize(tester);
    final (store, session) = await demoApp();
    await session.startDemo();
    await tester.pumpWidget(FamilyApp(store: store, session: session));

    await tester.tap(find.text('Tomi'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Tomi'), findsOneWidget);

    for (final tab in ['Rutina', 'Calendario', 'Premios']) {
      await tester.tap(find.widgetWithText(NavigationDestination, tab));
      await tester.pumpAndSettle();
    }
    expect(find.text('Mis premios'), findsOneWidget);
  });

  testWidgets('el adulto ve su panel y abre la invitación por QR', (tester) async {
    phoneSize(tester);
    final (store, session) = await demoApp();
    await session.startDemo();
    await tester.pumpWidget(FamilyApp(store: store, session: session));

    await tester.tap(find.text('Papá'));
    await tester.pumpAndSettle();
    expect(find.text('Mi familia'), findsOneWidget);

    await tester.tap(find.text('Invitar con QR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Sumar a alguien'), findsOneWidget);
    await tester.dragUntilVisible(
      find.textContaining('Estás en la demostración'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.textContaining('Estás en la demostración'), findsOneWidget);
  });

  testWidgets('el adulto agrega un hijo sin celular', (tester) async {
    phoneSize(tester);
    final (store, session) = await demoApp();
    await session.startDemo();
    await tester.pumpWidget(FamilyApp(store: store, session: session));

    await tester.tap(find.text('Papá'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hijo sin celular'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Juli');
    await tester.pump();
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(store.children.map((c) => c.nickname), contains('Juli'));
  });
}
