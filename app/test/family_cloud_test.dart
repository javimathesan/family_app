import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:family_app/data/family_cloud.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deja que lleguen los cambios del Firestore simulado.
Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  // Viernes 30/10/2026 a las 07:25.
  DateTime clock() => DateTime(2026, 10, 30, 7, 25);

  late FakeFirebaseFirestore db;
  late FamilyCloud adultCloud;
  late FamilyCloud childCloud;
  late FamilyStore adultStore;
  late FamilyStore childStore;

  setUp(() {
    db = FakeFirebaseFirestore();
    adultCloud = FamilyCloud(db: db, uid: 'tel-adulto', clock: clock);
    childCloud = FamilyCloud(db: db, uid: 'tel-hijo', clock: clock);
    adultStore = FamilyStore.empty(clock: clock);
    childStore = FamilyStore.empty(clock: clock);
  });

  tearDown(() {
    adultCloud.detach();
    childCloud.detach();
  });

  /// Crea el hogar, invita, une y aprueba a un hijo. Devuelve los ids.
  Future<({String homeId, String adultId, String childId})> familyWithOneChild() async {
    final home = await adultCloud.createHome(homeName: 'Familia Test', nickname: 'Papá');
    adultCloud.attach(adultStore, home.homeId);
    final invite = await adultCloud.createInvite(
      homeId: home.homeId,
      homeName: 'Familia Test',
      role: MemberRole.child,
      mode: AgeMode.junior,
    );
    final found = await childCloud.lookupInvite(invite.code);
    final childId = await childCloud.joinHome(found, 'Tomi');
    await settle();
    adultStore.confirmMember(childId);
    await settle();
    childCloud.attach(childStore, home.homeId);
    await settle();
    return (homeId: home.homeId, adultId: home.memberId, childId: childId);
  }

  test('crear un hogar deja al teléfono como administrador', () async {
    final home = await adultCloud.createHome(homeName: 'Familia Test', nickname: 'Papá');
    final doc = await db.collection('homes').doc(home.homeId).get();
    expect(doc.data()!['adminUids'], ['tel-adulto']);
    expect(doc.data()!['memberUids'], ['tel-adulto']);

    adultCloud.attach(adultStore, home.homeId);
    await settle();
    expect(adultStore.homeName, 'Familia Test');
    expect(adultStore.memberById(home.memberId)!.role, MemberRole.admin);
  });

  test('invitar, unirse y aprobar conecta el teléfono del hijo', () async {
    final home = await adultCloud.createHome(homeName: 'Familia Test', nickname: 'Papá');
    adultCloud.attach(adultStore, home.homeId);

    final invite = await adultCloud.createInvite(
      homeId: home.homeId,
      homeName: 'Familia Test',
      role: MemberRole.child,
      mode: AgeMode.peques,
    );
    expect(Invitation.parseCode(invite.qrPayload), invite.code);

    final found = await childCloud.lookupInvite(invite.code);
    expect(found.homeId, home.homeId);
    expect(found.homeName, 'Familia Test');
    expect(found.mode, AgeMode.peques);

    final childId = await childCloud.joinHome(found, 'Luli');
    final approvals = <bool?>[];
    final sub = childCloud.watchApproval(home.homeId, childId).listen(approvals.add);
    await settle();

    expect(adultStore.isPendingMember(childId), isTrue);
    expect(adultStore.memberById(childId)!.nickname, 'Luli');
    expect(approvals.last, isFalse);

    adultStore.confirmMember(childId);
    await settle();
    expect(approvals.last, isTrue);
    final homeDoc = await db.collection('homes').doc(home.homeId).get();
    expect(homeDoc.data()!['memberUids'], containsAll(['tel-adulto', 'tel-hijo']));
    expect(homeDoc.data()!['adminUids'], ['tel-adulto']);
    await sub.cancel();
  });

  test('una invitación usada o vencida no sirve', () async {
    final home = await adultCloud.createHome(homeName: 'Familia Test', nickname: 'Papá');
    final invite = await adultCloud.createInvite(homeId: home.homeId, homeName: 'Familia Test', role: MemberRole.child);
    await childCloud.joinHome(await childCloud.lookupInvite(invite.code), 'Tomi');

    final otherPhone = FamilyCloud(db: db, uid: 'tel-otro', clock: clock);
    await expectLater(otherPhone.lookupInvite(invite.code), throwsA(isA<JoinException>()));
    await expectLater(otherPhone.lookupInvite('FAM-ZZZZ'), throwsA(isA<JoinException>()));

    final tardio = FamilyCloud(db: db, uid: 'tel-tarde', clock: () => clock().add(const Duration(minutes: 16)));
    final fresh = await adultCloud.createInvite(homeId: home.homeId, homeName: 'Familia Test', role: MemberRole.child);
    await expectLater(tardio.lookupInvite(fresh.code), throwsA(isA<JoinException>()));
  });

  test('lo que hace el hijo en su teléfono le llega al adulto', () async {
    final ids = await familyWithOneChild();

    childStore.toggleTask(ids.childId, 'aseo');
    childStore.addGlass(ids.childId);
    await settle();

    expect(adultStore.isDone(ids.childId, 'aseo'), isTrue);
    expect(adultStore.balanceOf(ids.childId), 5);
    expect(adultStore.healthOf(ids.childId).glasses, 1);
    expect(adultStore.notices.any((n) => n.text.contains('Tomi completó')), isTrue);
  });

  test('el adulto aprueba una tarea con foto y los puntos le llegan al hijo', () async {
    final ids = await familyWithOneChild();

    childStore.toggleTask(ids.childId, 'cama');
    await settle();
    expect(adultStore.pendingTaskApprovals.single.task.id, 'cama');
    expect(childStore.balanceOf(ids.childId), 0);

    adultStore.approveTask(ids.childId, 'cama');
    await settle();
    expect(childStore.balanceOf(ids.childId), 5);
    expect(childStore.completionOf(ids.childId, 'cama')!.pendingApproval, isFalse);
  });

  test('desmarcar una tarea la borra para todos', () async {
    final ids = await familyWithOneChild();
    childStore.toggleTask(ids.childId, 'aseo');
    await settle();
    childStore.toggleTask(ids.childId, 'aseo');
    await settle();
    expect(adultStore.isDone(ids.childId, 'aseo'), isFalse);
    expect(adultStore.balanceOf(ids.childId), 0);
  });

  test('canje de premio: el hijo pide y el adulto rechaza devolviendo los puntos', () async {
    final ids = await familyWithOneChild();
    for (final t in ['levantarse', 'aseo', 'desayuno', 'dientes_am', 'utiles', 'mesa', 'entrada', 'salida', 'deporte', 'llegar']) {
      childStore.toggleTask(ids.childId, t);
    }
    for (var i = 0; i < 8; i++) {
      childStore.addGlass(ids.childId);
    }
    await settle();
    final saldo = childStore.balanceOf(ids.childId);
    expect(saldo, greaterThanOrEqualTo(50));

    expect(childStore.requestReward(ids.childId, 'helado'), isTrue);
    await settle();
    final pedido = adultStore.pendingRedemptions.single;
    expect(adultStore.balanceOf(ids.childId), saldo - 50);

    adultStore.rejectRedemption(pedido.id);
    await settle();
    expect(childStore.balanceOf(ids.childId), saldo);
    expect(childStore.redemptionsOf(ids.childId).single.status, RedemptionStatus.rejected);
  });

  test('el avatar y el color que elige el hijo se ven en el teléfono del adulto', () async {
    final ids = await familyWithOneChild();
    childStore.updateAvatar(ids.childId, const AvatarConfig(skin: 4, glasses: true));
    childStore.setAccent(ids.childId, const Color(0xFF7C3AED));
    await settle();
    expect(adultStore.memberById(ids.childId)!.avatar.glasses, isTrue);
    expect(adultStore.memberById(ids.childId)!.accent, const Color(0xFF7C3AED));
  });

  test('un hijo sin celular se agrega directo, sin aprobación', () async {
    final home = await adultCloud.createHome(homeName: 'Familia Test', nickname: 'Mamá');
    adultCloud.attach(adultStore, home.homeId);
    final m = adultStore.addMember(nickname: 'Benja', role: MemberRole.child, mode: AgeMode.peques);
    await settle();
    final doc = await db.collection('homes').doc(home.homeId).collection('members').doc(m.id).get();
    expect(doc.data()!['pending'], isFalse);
    expect(doc.data()!['uid'], isNull);
    expect(adultStore.memberById(m.id)!.nickname, 'Benja');
  });

  test('rechazar un alta borra el perfil pendiente', () async {
    final home = await adultCloud.createHome(homeName: 'Familia Test', nickname: 'Papá');
    adultCloud.attach(adultStore, home.homeId);
    final invite = await adultCloud.createInvite(homeId: home.homeId, homeName: 'Familia Test', role: MemberRole.child);
    final childId = await childCloud.joinHome(await childCloud.lookupInvite(invite.code), 'Tomi');
    final approvals = <bool?>[];
    final sub = childCloud.watchApproval(home.homeId, childId).listen(approvals.add);
    await settle();

    adultStore.removeMember(childId);
    await settle();
    expect(adultStore.memberById(childId), isNull);
    expect(approvals.last, isNull);
    await sub.cancel();
  });

  test('la rutina y los premios que edita el adulto le llegan al hijo', () async {
    final ids = await familyWithOneChild();
    adultStore.saveTemplate(TaskTemplate(
      id: 'perro',
      name: 'Pasear al perro',
      block: DayBlock.afternoon,
      time: const TimeOfDay(hour: 16, minute: 0),
      points: 8,
    ));
    adultStore.removeTemplate('aseo');
    adultStore.saveReward(const Reward(id: 'pizza', name: 'Pizza', cost: 70, iconKey: 'comida'));
    await settle();

    expect(childStore.templates.any((t) => t.id == 'perro'), isTrue);
    expect(childStore.templates.any((t) => t.id == 'aseo'), isFalse);
    expect(childStore.rewardById('pizza')!.name, 'Pizza');

    childStore.toggleTask(ids.childId, 'perro');
    await settle();
    expect(adultStore.balanceOf(ids.childId), 8);
  });

  test('un hogar nuevo arranca con la rutina y los premios por defecto en la nube', () async {
    final home = await adultCloud.createHome(homeName: 'Familia Test', nickname: 'Papá');
    final doc = await db.collection('homes').doc(home.homeId).get();
    expect((doc.data()!['templates'] as List).length, FamilyStore.defaultTemplates.length);
    expect((doc.data()!['rewards'] as List).length, FamilyStore.defaultRewards.length);
  });
}
