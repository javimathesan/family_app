import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_cloud.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  DateTime clock() => DateTime(2026, 10, 30, 7, 25);

  late FakeFirebaseFirestore db;
  late FamilyCloud adultCloud;
  late FamilyStore adultStore;
  late String homeId;
  late String childId;

  setUp(() async {
    db = FakeFirebaseFirestore();
    adultCloud = FamilyCloud(db: db, uid: 'tel-adulto', clock: clock);
    adultStore = FamilyStore.empty(clock: clock);
    final home = await adultCloud.createHome(homeName: 'Familia Test', nickname: 'Papá');
    homeId = home.homeId;
    adultCloud.attach(adultStore, homeId);
    adultStore.signInAs(home.memberId);

    // Tomi se une con su primer teléfono y gana puntos.
    final oldPhone = FamilyCloud(db: db, uid: 'tel-viejo', clock: clock);
    final invite = await adultCloud.createInvite(homeId: homeId, homeName: 'Familia Test', role: MemberRole.child, mode: AgeMode.junior);
    childId = await oldPhone.joinHome(await oldPhone.lookupInvite(invite.code), 'Tomi');
    await settle();
    adultStore.confirmMember(childId);
    await settle();
    await db.collection('homes').doc(homeId).collection('members').doc(childId).update({'balance': 120});
    await settle();
  });

  tearDown(() => adultCloud.detach());

  test('el teléfono nuevo vuelve a entrar con el mismo perfil y el viejo pierde acceso', () async {
    final tomi = adultStore.memberById(childId)!;
    final invite = await adultCloud.createInvite(
      homeId: homeId,
      homeName: 'Familia Test',
      role: tomi.role,
      mode: tomi.mode,
      relink: tomi,
    );
    var home = (await db.collection('homes').doc(homeId).get()).data()!;
    expect(home['memberUids'], isNot(contains('tel-viejo')));

    final newPhone = FamilyCloud(db: db, uid: 'tel-nuevo', clock: clock);
    final found = await newPhone.lookupInvite(invite.code);
    expect(found.isRelink, isTrue);
    expect(found.memberName, 'Tomi');

    final id = await newPhone.joinHome(found, '');
    expect(id, childId);
    await settle();
    expect(adultStore.isRelinking(childId), isTrue);
    expect(adultStore.isPendingMember(childId), isTrue);

    final approvals = <bool?>[];
    final sub = newPhone.watchApproval(homeId, childId).listen(approvals.add);
    adultStore.confirmMember(childId);
    await settle();
    await sub.cancel();

    home = (await db.collection('homes').doc(homeId).get()).data()!;
    expect(home['memberUids'], contains('tel-nuevo'));
    expect(adultStore.isRelinking(childId), isFalse);
    expect(adultStore.memberById(childId)!.uid, 'tel-nuevo');
    expect(adultStore.balanceOf(childId), 120, reason: 'conserva los puntos');
    expect(approvals.last, isTrue);
  });

  test('rechazar el teléfono nuevo no borra el perfil', () async {
    final tomi = adultStore.memberById(childId)!;
    final invite = await adultCloud.createInvite(homeId: homeId, homeName: 'Familia Test', role: tomi.role, relink: tomi);
    final stranger = FamilyCloud(db: db, uid: 'tel-raro', clock: clock);
    await stranger.joinHome(await stranger.lookupInvite(invite.code), '');
    await settle();

    final approvals = <bool?>[];
    final sub = stranger.watchApproval(homeId, childId).listen(approvals.add);
    adultStore.cancelRelink(childId);
    await settle();
    await sub.cancel();

    expect(adultStore.memberById(childId), isNotNull);
    expect(adultStore.memberById(childId)!.uid, isNull);
    expect(adultStore.isPendingMember(childId), isFalse);
    expect(approvals.last, isNull, reason: 'el teléfono raro ve que no lo aprobaron');
  });

  test('a los chicos les avisa cuando les aprueban algo', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FamilyStore.demo(clock: clock);
    final session = AppSession(store: store, prefs: prefs, storage: FamilyStorage(prefs));
    session.deviceMemberId = 'tomi';
    store.signInAs('tomi');
    final t = clock();
    expect(session.shouldNotify(FamilyNotice(time: t, text: 'Papá aprobó "Helado" para Tomi', kind: NoticeKind.approval, memberId: 'tomi')), isTrue);
    expect(session.shouldNotify(FamilyNotice(time: t, text: 'Tomi completó: Aseo', kind: NoticeKind.task, memberId: 'tomi')), isFalse);
  });
}
