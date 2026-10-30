import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:family_app/data/family_cloud.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/games/game_setup.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  DateTime clock() => DateTime(2026, 10, 30, 7, 25);

  test('crear partida avisa al hogar y contra Robi se juega en el teléfono', () {
    final store = FamilyStore.demo(clock: clock)..signInAs('tomi');
    final match = store.createMatch(GameKind.tateti, ['tomi', botPlayerId]);
    expect(store.matchById(match.id), isNotNull);
    expect(match.sameDevice, isTrue);
    expect(store.notices.first.kind, NoticeKind.game);
    expect(store.notices.first.text, 'Tomi empezó Tres en raya con Robi');
    expect(store.myTurnCount('tomi'), 1);
  });

  test('ludo admite hasta 4 y el resto solo 2', () {
    final store = FamilyStore.demo(clock: clock)..signInAs('adulto');
    expect(() => store.createMatch(GameKind.ajedrez, ['adulto', 'tomi', 'luli']), throwsArgumentError);
    final ludo = store.createMatch(GameKind.ludo, ['adulto', 'tomi', 'luli', 'mati']);
    expect((ludo.state['tokens'] as List).length, 16);
  });

  test('al terminar avisa quién ganó', () {
    final store = FamilyStore.demo(clock: clock)..signInAs('tomi');
    final match = store.createMatch(GameKind.tateti, ['tomi', 'luli']);
    store.playMove(match.id, {'cells': [0, 0, 0, 1, 1, -1, -1, -1, -1]}, nextTurn: 1, winner: 0);
    expect(store.matchById(match.id)!.finished, isTrue);
    expect(store.notices.first.text, 'Tomi ganó en Tres en raya 🏆');
    // Una partida terminada ya no acepta jugadas.
    store.playMove(match.id, {'cells': []}, nextTurn: 0);
    expect((store.matchById(match.id)!.state['cells'] as List).length, 9);
  });

  test('los chicos juegan según la regla; los adultos siempre', () {
    final store = FamilyStore.demo(clock: clock);
    expect(store.gamesRule, GamesRule.half);
    expect(store.canPlayGames('tomi'), isFalse);
    expect(store.canPlayGames('adulto'), isTrue);

    final half = (store.templatesFor('tomi').length / 2).ceil();
    for (final t in store.templatesFor('tomi').take(half)) {
      store.toggleTask('tomi', t.id);
    }
    expect(store.canPlayGames('tomi'), isTrue);

    store.setGamesRule(GamesRule.all);
    expect(store.canPlayGames('tomi'), isFalse);
    store.setGamesRule(GamesRule.free);
    expect(store.canPlayGames('luli'), isTrue);
  });

  test('las partidas y la regla se guardan en el teléfono', () {
    final store = FamilyStore.demo(clock: clock)..signInAs('tomi');
    final match = store.createMatch(GameKind.ajedrez, ['tomi', 'adulto']);
    store.setGamesRule(GamesRule.all);
    final copy = FamilyStore.empty(clock: clock)..restoreFrom(store.toJson());
    expect(copy.matchById(match.id)!.kind, GameKind.ajedrez);
    expect(copy.matchById(match.id)!.state, initialGameState(GameKind.ajedrez, 2));
    expect(copy.gamesRule, GamesRule.all);
  });

  test('una partida se sincroniza entre teléfonos', () async {
    final db = FakeFirebaseFirestore();
    final adultCloud = FamilyCloud(db: db, uid: 'tel-adulto', clock: clock);
    final childCloud = FamilyCloud(db: db, uid: 'tel-hijo', clock: clock);
    final adultStore = FamilyStore.empty(clock: clock);
    final childStore = FamilyStore.empty(clock: clock);
    addTearDown(adultCloud.detach);
    addTearDown(childCloud.detach);

    final home = await adultCloud.createHome(homeName: 'Familia Test', nickname: 'Papá');
    adultCloud.attach(adultStore, home.homeId);
    final invite = await adultCloud.createInvite(homeId: home.homeId, homeName: 'Familia Test', role: MemberRole.child, mode: AgeMode.junior);
    final childId = await childCloud.joinHome(await childCloud.lookupInvite(invite.code), 'Tomi');
    await settle();
    adultStore.confirmMember(childId);
    await settle();
    childCloud.attach(childStore, home.homeId);
    await settle();

    adultStore.signInAs(home.memberId);
    childStore.signInAs(childId);
    final match = adultStore.createMatch(GameKind.ludo, [home.memberId, childId]);
    await settle();

    final remote = childStore.matchById(match.id);
    expect(remote, isNotNull);
    expect(remote!.kind, GameKind.ludo);
    expect(childStore.myTurnCount(childId), 0);

    adultStore.playMove(match.id, {...match.state, 'lastRoll': 3}, nextTurn: 1);
    await settle();
    expect(childStore.myTurnCount(childId), 1);
    expect(childStore.matchById(match.id)!.lastBy, home.memberId);

    adultStore.setGamesRule(GamesRule.free);
    await settle();
    expect(childStore.gamesRule, GamesRule.free);

    childStore.removeMatch(match.id);
    await settle();
    expect(adultStore.matchById(match.id), isNull);
  });

  test('límite de minutos por día y borrar terminadas', () {
    final store = FamilyStore.demo(clock: clock)
      ..setGamesRule(GamesRule.free)
      ..setGamesMinutes(15);
    expect(store.gameMinutesLeft('tomi'), 15);
    store.addGameSeconds('tomi', 14 * 60);
    expect(store.canPlayGames('tomi'), isTrue);
    expect(store.gameMinutesLeft('tomi'), 1);
    store.addGameSeconds('tomi', 60);
    expect(store.gamesLock('tomi'), GamesLock.time);
    store.addGameSeconds('adulto', 9999);
    expect(store.canPlayGames('adulto'), isTrue);
    expect(store.gameMinutesLeft('adulto'), isNull);

    store.signInAs('luli');
    final a = store.createMatch(GameKind.tateti, ['luli', botPlayerId]);
    store.createMatch(GameKind.cuatro, ['luli', botPlayerId]);
    store.playMove(a.id, {'cells': [0, 0, 0, 1, 1, -1, -1, -1, -1]}, nextTurn: 1, winner: 0);
    expect(store.removeFinishedMatches('luli'), 1);
    expect(store.matchesOf('luli').length, 1, reason: 'la partida en curso queda');
  });
}
