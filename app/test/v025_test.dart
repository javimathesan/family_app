import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('un chico pide, un adulto aprueba y pasa a la lista en su sección', () {
    final store = FamilyStore.demo(clock: () => DateTime(2026, 11, 9, 9));
    final r = store.requestShopping('tomi', 'Cartulina azul', qty: 2, category: 'colegio', due: DateTime(2026, 11, 12));
    expect(store.pendingShoppingRequests.single.id, r.id);
    expect(store.notices.first.text, contains('Tomi pidió para comprar: Cartulina azul'));
    expect(store.requestStatusLabel(store.requestsOf('tomi').single), 'Esperando que un adulto lo vea');

    store.approveShoppingRequest(r.id);
    expect(store.pendingShoppingRequests, isEmpty);
    final item = store.shopping.single;
    expect(item.category, 'colegio');
    expect(item.qty, 2);
    expect(item.due, DateTime(2026, 11, 12));
    expect(item.by, 'pedido de Tomi');
    expect(store.requestStatusLabel(store.requestsOf('tomi').single), 'En la lista de compras');
    store.toggleShopping(item.id);
    expect(store.requestStatusLabel(store.requestsOf('tomi').single), '¡Comprado!');

    final otro = store.requestShopping('luli', 'Shampoo', category: 'personal');
    store.rejectShoppingRequest(otro.id);
    expect(store.requestStatusLabel(store.requestsOf('luli').single), 'Esta vez no');
    final tercero = store.requestShopping('luli', 'Lápices');
    store.cancelShoppingRequest(tercero.id);
    expect(store.requestsOf('luli').length, 1);

    final ida = ShoppingRequest.fromJson('x', r.toJson());
    expect(ida.due, DateTime(2026, 11, 12));
    expect(ida.category, 'colegio');
  });

  testWidgets('el chico pide desde Hoy', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FamilyStore.empty(clock: () => DateTime(2026, 11, 9, 9));
    final session = AppSession(store: store, prefs: prefs, storage: FamilyStorage(prefs));
    await session.restore();
    await session.startDemo();

    await tester.pumpWidget(FamilyApp(store: store, session: session));
    await tester.tap(find.text('Tomi'));
    await tester.pumpAndSettle();
    final pedir = find.byKey(const ValueKey('pedir_compra'));
    await tester.scrollUntilVisible(pedir, 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(pedir);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('pedido_nombre')), 'Témperas');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar pedido'));
    await tester.pumpAndSettle();
    expect(store.pendingShoppingRequests.single.name, 'Témperas');
  });
}
