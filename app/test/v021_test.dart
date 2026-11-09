import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('el color de cada tarjeta se guarda', () {
    const look = MemberLook(tints: {'mascota': 2, 'reto': 0});
    final ida = MemberLook.fromJson(look.toJson());
    expect(ida, look);
    expect(ida.tints['mascota'], 2);
    expect(LookOptions.cards.where((c) => !c.plus).length, 2, reason: 'dos estilos gratis');
    expect(LookOptions.themes.where((t) => !t.plus), isNotEmpty);
  });

  test('Mis hábitos arranca apagado para un hijo nuevo', () {
    final store = FamilyStore.demo(clock: () => DateTime(2026, 11, 9, 9));
    final nuevo = store.addMember(nickname: 'Pía', role: MemberRole.child, mode: AgeMode.peques);
    expect(nuevo.habitsOn, isFalse);
    expect(store.memberById('luli')!.bathroomOn, isTrue, reason: 'los que ya estaban siguen igual');
    store.setHabits(nuevo.id, water: true);
    expect(store.memberById(nuevo.id)!.waterOn, isTrue);
    final pendiente = store.addPendingMember(nickname: 'Leo', role: MemberRole.child, mode: AgeMode.junior);
    store.confirmMember(pendiente.id);
    expect(store.memberById(pendiente.id)!.habitsOn, isFalse);
  });

  testWidgets('temas de un toque, vista previa y color por tarjeta', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FamilyStore.empty(clock: () => DateTime(2026, 11, 6, 9));
    final session = AppSession(store: store, prefs: prefs, storage: FamilyStorage(prefs));
    await session.restore();
    await session.startDemo();

    await tester.pumpWidget(FamilyApp(store: store, session: session));
    await tester.tap(find.text('Tomi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Personalizar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('vista_previa')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('tema_Océano')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tema_Océano')));
    await tester.pumpAndSettle();
    final tomi = store.memberById('tomi')!;
    expect(tomi.accent, const Color(0xFF0369A1));
    expect(tomi.look.world, 2);

    final swatch = find.byKey(const ValueKey('tinte_mascota_1'));
    await tester.scrollUntilVisible(swatch, 200, scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(swatch);
    await tester.pumpAndSettle();
    await tester.tap(swatch);
    await tester.pumpAndSettle();
    expect(store.memberById('tomi')!.look.tints['mascota'], 1);

    await tester.ensureVisible(find.text('Como estaba'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Como estaba'));
    await tester.pumpAndSettle();
    expect(store.memberById('tomi')!.look.world, 0);
  });
}
