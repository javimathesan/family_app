import 'package:family_app/app.dart';
import 'package:family_app/data/family_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('se puede entrar como hijo y navegar las 4 secciones', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final store = FamilyStore.demo(clock: () => DateTime(2026, 10, 30, 7, 25));
    await tester.pumpWidget(FamilyApp(store: store));

    expect(find.text('¿Quién usa la app?'), findsOneWidget);
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
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final store = FamilyStore.demo(clock: () => DateTime(2026, 10, 30, 7, 25));
    await tester.pumpWidget(FamilyApp(store: store));
    await tester.tap(find.text('Papá'));
    await tester.pumpAndSettle();
    expect(find.text('Mi familia'), findsOneWidget);

    await tester.tap(find.text('Invitar con QR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Sumar a alguien'), findsOneWidget);
  });
}
