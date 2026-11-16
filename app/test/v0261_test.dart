import 'package:family_app/services/app_version.dart';
import 'package:family_app/widgets/version_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lee version.json y descarta lo que no entiende', () {
    final r = AppVersion.parse('{"version":"0.26.1","build":140}');
    expect(r?.version, '0.26.1');
    expect(r?.build, 140);
    expect(AppVersion.parse('<html>'), isNull);
    expect(AppVersion.parse('{"version":1}'), isNull);
  });

  testWidgets('muestra la versión instalada y busca la última', (tester) async {
    final original = AppVersion.fetchLatest;
    addTearDown(() => AppVersion.fetchLatest = original);
    AppVersion.fetchLatest = () async => const AppRelease(version: '9.9.9', build: 0);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => showVersionSheet(context), child: const Text('abrir')),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.textContaining('En este teléfono: ${AppVersion.label}'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buscar_version')));
    await tester.pumpAndSettle();
    expect(find.text('Tenés la última versión.'), findsOneWidget);

    AppVersion.fetchLatest = () async => null;
    await tester.tap(find.byKey(const ValueKey('buscar_version')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo consultar'), findsOneWidget);
  });
}
