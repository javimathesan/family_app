import 'dart:convert';

import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:family_app/widgets/avatar_view.dart';
import 'package:family_app/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('metas que se cuentan: el agua del adulto se puede pasar', () {
    final store = FamilyStore.demo(clock: () => DateTime(2026, 11, 9, 9));
    final agua = AdultGoal.all.firstWhere((g) => g.id == 'meta_agua');
    store.setMyGoals('adulto', [agua]);
    for (var i = 0; i < 7; i++) {
      store.addGoalCount('adulto', agua.id);
    }
    expect(store.isGoalMet('adulto', agua), isFalse);
    store.addGoalCount('adulto', agua.id);
    store.addGoalCount('adulto', agua.id);
    expect(store.goalCount('adulto', agua.id), 9);
    expect(store.isGoalMet('adulto', agua), isTrue);
    expect(store.adultGoalsDone('adulto'), 1);
    store.addGoalCount('adulto', agua.id, delta: -1);
    expect(store.goalCount('adulto', agua.id), 8);
    final ida = AdultGoal.fromJson(agua.toJson());
    expect(ida.target, 8);
  });

  test('lista de compras: agregar varias, tildar y borrar compradas', () {
    final store = FamilyStore.demo(clock: () => DateTime(2026, 11, 9, 9));
    store.addShopping('Leche, pan,  manzanas', by: 'Papá');
    expect(store.shopping.length, 3);
    expect(store.shoppingPending, 3);
    final pan = store.shopping.firstWhere((i) => i.name == 'pan');
    store.toggleShopping(pan.id);
    expect(store.shoppingPending, 2);
    store.addShopping('Pan');
    expect(store.shopping.length, 3, reason: 'no se repite: vuelve a la lista');
    expect(store.shoppingPending, 3);
    store.toggleShopping(pan.id);
    store.clearBoughtShopping();
    expect(store.shopping.map((i) => i.name), isNot(contains('pan')));
    final copia = FamilyStore.demo(clock: () => DateTime(2026, 11, 9, 9))
      ..restoreFrom(jsonDecode(jsonEncode(store.toJson())) as Map<String, dynamic>);
    expect(copia.shopping.length, 2);
  });

  test('precios: se leen como los escribe la gente y suman', () {
    expect(parseMoney('1.234,50'), 1234.5);
    expect(parseMoney('1234'), 1234);
    expect(parseMoney(r'$ 900'), 900);
    expect(parseMoney('2.500'), 2500);
    expect(parseMoney('12.5'), 12.5);
    expect(parseMoney(''), isNull);
    expect(money(1234.5), r'$ 1.234,50');
    expect(money(900), r'$ 900');
    final store = FamilyStore.demo(clock: () => DateTime(2026, 11, 9, 9));
    store.addShopping('Leche, Pan');
    final leche = store.shopping.firstWhere((i) => i.name == 'Leche');
    final pan = store.shopping.firstWhere((i) => i.name == 'Pan');
    store.setShoppingPrice(leche.id, 1200);
    store.setShoppingPrice(pan.id, 800);
    store.toggleShopping(leche.id);
    expect(store.shoppingTotal, 2000);
    expect(store.shoppingInCart, 1200);
    store.setShoppingDate(DateTime(2026, 11, 14, 18));
    expect(store.shoppingDate, DateTime(2026, 11, 14));
  });

  test('renombrar el hogar', () {
    final store = FamilyStore.demo(clock: () => DateTime(2026, 11, 9, 9));
    store.renameHome('  Familia Matheus ');
    expect(store.homeName, 'Familia Matheus');
  });

  test('avatar: barba, anteojos de sol y parches se guardan; los viejos siguen igual', () {
    const a = AvatarConfig(eyewear: 3, facialHair: 3);
    final m = FamilyStore.memberFromJson(FamilyStore.memberToJson(Member(id: 'x', nickname: 'X', role: MemberRole.admin, avatar: a)));
    expect(m.avatar.eyewear, 3);
    expect(m.avatar.facialHair, 3);
    final viejo = FamilyStore.memberFromJson({
      'id': 'y', 'nickname': 'Y', 'role': 'child',
      'avatar': {'glasses': true},
    });
    expect(viejo.avatar.eyewear, 1);
    expect(viejo.avatar.glasses, isTrue);
    expect(AvatarOptions.hairStyles.length, 20);
  });

  testWidgets('todos los avatares nuevos se dibujan sin errores', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Wrap(children: [
        for (var h = 0; h < AvatarOptions.hairStyles.length; h++)
          AvatarView(config: AvatarConfig(hairStyle: h, facialHair: h % AvatarOptions.facialHair.length, eyewear: h % 5), size: 40),
      ]),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lista de compras desde el inicio del adulto', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FamilyStore.empty(clock: () => DateTime(2026, 11, 9, 9));
    final session = AppSession(store: store, prefs: prefs, storage: FamilyStorage(prefs));
    await session.restore();
    await session.startDemo();
    expect(store.usesTool('adulto', 'compras'), isFalse, reason: 'la lista arranca apagada');
    store.setTool('adulto', 'compras', true);

    await tester.pumpWidget(FamilyApp(store: store, session: session));
    await tester.tap(find.text('Papá'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('ir_compras')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('ir_compras')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('compra_nueva')), 'Yerba, azúcar');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('Yerba'), findsOneWidget);
    expect(store.shoppingPending, 2);
  });
}
