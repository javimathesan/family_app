import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:family_app/data/family_cloud.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settle() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  DateTime clock() => DateTime(2026, 10, 30, 7, 25);

  test('dos familias se hacen amigas y juegan una partida compartida', () async {
    final db = FakeFirebaseFirestore();
    final cloudA = FamilyCloud(db: db, uid: 'tel-a', clock: clock);
    final cloudB = FamilyCloud(db: db, uid: 'tel-b', clock: clock);
    final a = FamilyStore.empty(clock: clock);
    final b = FamilyStore.empty(clock: clock);
    addTearDown(cloudA.detach);
    addTearDown(cloudB.detach);

    final homeA = await cloudA.createHome(homeName: 'Los Girasoles', nickname: 'Papá');
    final homeB = await cloudB.createHome(homeName: 'Los Robles', nickname: 'Mamá');
    cloudA.attach(a, homeA.homeId);
    cloudB.attach(b, homeB.homeId);
    await settle();
    a.signInAs(homeA.memberId);
    b.signInAs(homeB.memberId);
    final tomi = a.addMember(nickname: 'Tomi', role: MemberRole.child, mode: AgeMode.junior);
    final juli = b.addMember(nickname: 'Juli', role: MemberRole.child, mode: AgeMode.junior);
    await settle();

    final code = await cloudA.createFriendInvite(
      homeId: homeA.homeId,
      homeName: 'Los Girasoles',
      kids: [FriendKid(id: tomi.id, nickname: 'Tomi', avatar: tomi.avatar)],
    );
    final other = await cloudB.lookupFriendInvite(code);
    expect(other.homeName, 'Los Girasoles');
    await cloudB.acceptFriendInvite(code, homeName: 'Los Robles', kids: [FriendKid(id: juli.id, nickname: 'Juli', avatar: juli.avatar)]);
    await settle();

    expect(a.friendships.single.otherHome, 'Los Robles');
    expect(b.friendships.single.otherHome, 'Los Girasoles');
    expect(a.friendRivalsOf(tomi.id).single.kid.nickname, 'Juli');
    expect(a.friendRivalsOf(homeA.memberId), isEmpty, reason: 'Papá no está compartido');
    await expectLater(cloudB.lookupFriendInvite(code), throwsA(isA<JoinException>()), reason: 'el código es de un solo uso');

    a.signInAs(tomi.id);
    final match = a.createMatch(GameKind.tateti, [tomi.id, juli.id], friendshipId: a.friendships.single.id);
    await settle();
    final remote = b.matchById(match.id);
    expect(remote, isNotNull);
    expect(remote!.withFriends, isTrue);
    expect(b.playerName(tomi.id), 'Tomi');
    expect(a.matchesOf(tomi.id).single.id, match.id);

    a.playMove(match.id, {'cells': [0, -1, -1, -1, -1, -1, -1, -1, -1]}, nextTurn: 1);
    await settle();
    expect(b.myTurnCount(juli.id), 1);
    b.react(match.id, juli.id, gameReactions.first);
    await settle();
    expect(a.matchById(match.id)!.reaction, gameReactions.first);

    await cloudB.endFriendship(b.friendships.single.id);
    await settle();
    expect(a.friendships, isEmpty);
  });

  test('borrar el hogar borra sus datos y termina las amistades', () async {
    final db = FakeFirebaseFirestore();
    final cloud = FamilyCloud(db: db, uid: 'tel-a', clock: clock);
    final store = FamilyStore.empty(clock: clock);
    final home = await cloud.createHome(homeName: 'Casa', nickname: 'Papá');
    expect((await db.collection('homes').doc(home.homeId).get()).data()!['terms']['version'], FamilyCloud.termsVersion);
    cloud.attach(store, home.homeId);
    await settle();
    store.signInAs(home.memberId);
    store.addMember(nickname: 'Tomi', role: MemberRole.child);
    store.toggleAdultGoal(home.memberId, 'meta_ejercicio');
    await settle();
    await cloud.deleteHome(home.homeId);
    expect((await db.collection('homes').doc(home.homeId).get()).exists, isFalse);
    expect((await db.collection('homes').doc(home.homeId).collection('members').get()).docs, isEmpty);
    expect((await db.collection('homes').doc(home.homeId).collection('days').get()).docs, isEmpty);
  });
}
