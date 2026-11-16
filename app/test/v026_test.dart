import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:family_app/app.dart';
import 'package:family_app/data/family_cloud.dart';
import 'package:family_app/data/family_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  DateTime clock() => DateTime(2026, 11, 16, 10);

  test('un dato que esta versión no entiende no tapa al resto', () async {
    final db = FakeFirebaseFirestore();
    final cloud = FamilyCloud(db: db, uid: 'tel', clock: clock);
    final store = FamilyStore.empty(clock: clock);
    addTearDown(cloud.detach);
    final home = await cloud.createHome(homeName: 'Casa', nickname: 'Papá');
    final ref = db.collection('homes').doc(home.homeId);
    Map<String, dynamic> canje(String status) =>
        {'memberId': home.memberId, 'rewardId': 'r1', 'requestedAt': Timestamp.fromDate(clock()), 'status': status};
    await ref.collection('redemptions').doc('bien').set(canje('pending'));
    await ref.collection('redemptions').doc('raro').set(canje('estado_de_otra_version'));
    await ref.collection('members').doc('raro').set({'nickname': 'X', 'role': 'rol_de_otra_version'});

    final avisos = <String>[];
    FamilyCloud.errorSink = (error, stack, where) => avisos.add(where);
    addTearDown(() => FamilyCloud.errorSink = null);
    cloud.attach(store, home.homeId);
    await settle();

    expect(store.pendingRedemptions.map((r) => r.id), ['bien']);
    expect(store.members.map((m) => m.nickname), ['Papá']);
    expect(avisos, containsAll(['leer un canje', 'leer un perfil']));
    expect(cloud.problem.value, isNull);
  });

  test('borrar el hogar borra también los pedidos de compras', () async {
    final db = FakeFirebaseFirestore();
    final cloud = FamilyCloud(db: db, uid: 'tel', clock: clock);
    final home = await cloud.createHome(homeName: 'Casa', nickname: 'Papá');
    final pedidos = db.collection('homes').doc(home.homeId).collection('shoppingRequests');
    await pedidos.doc('p1').set({'memberId': 'x', 'name': 'Cartulina', 'status': 'pending', 'at': 1});
    await cloud.deleteHome(home.homeId);
    expect((await pedidos.get()).docs, isEmpty);
  });

  test('el código de amistad tiene 6 caracteres al azar', () async {
    final db = FakeFirebaseFirestore();
    final cloud = FamilyCloud(db: db, uid: 'tel', clock: clock);
    final home = await cloud.createHome(homeName: 'Casa', nickname: 'Papá');
    final code = await cloud.createFriendInvite(homeId: home.homeId, homeName: 'Casa', kids: const []);
    expect(code, matches(RegExp(r'^AMI-[A-HJ-NP-Z2-9]{6}$')));
  });

  testWidgets('la franja avisa sin conexión y sin acceso', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Column(children: [
      SyncBanner(problem: SyncProblem.offline),
      SyncBanner(problem: SyncProblem.denied),
    ])));
    expect(find.textContaining('Sin conexión'), findsOneWidget);
    expect(find.textContaining('ya no tiene acceso'), findsOneWidget);
  });
}
