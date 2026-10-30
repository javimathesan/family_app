part of 'family_store.dart';

/// Área de juegos: partidas por turnos entre miembros del hogar.
extension FamilyGames on FamilyStore {
  /// Partidas, la más reciente primero.
  List<GameMatch> get matches => [..._matches]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  GameMatch? matchById(String id) {
    for (final m in _matches) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<GameMatch> matchesOf(String memberId) => [for (final m in matches) if (m.players.contains(memberId)) m];

  /// Partidas en las que le toca jugar.
  int myTurnCount(String memberId) =>
      _matches.where((m) => !m.finished && m.currentPlayer == memberId).length;

  /// Nombre para mostrar de un jugador.
  String playerName(String id) => id == botPlayerId ? 'Robi' : (memberById(id)?.nickname ?? 'Alguien');

  /// Los adultos juegan siempre; los chicos según la regla del hogar.
  bool canPlayGames(String memberId) {
    final m = memberById(memberId);
    if (m == null || m.role.isAdult) return true;
    if (templatesFor(memberId).isEmpty) return true;
    return completionRatio(memberId) >= _gamesRule.minRatio - 0.001;
  }

  GamesRule get gamesRule => _gamesRule;

  void setGamesRule(GamesRule rule) {
    if (rule == _gamesRule) return;
    _gamesRule = rule;
    sync?.gamesRuleChanged(rule);
    _changed();
  }

  /// Arranca una partida. [players] en orden de turno: el primero empieza.
  GameMatch createMatch(GameKind kind, List<String> players, {bool sameDevice = false}) {
    if (players.length < kind.minPlayers || players.length > kind.maxPlayers) {
      throw ArgumentError('${kind.label} es para ${kind.minPlayers} a ${kind.maxPlayers} jugadores');
    }
    final now = _clock();
    final creator = currentMember?.id ?? players.first;
    final match = GameMatch(
      id: _newId('g'),
      kind: kind,
      players: [...players],
      createdBy: creator,
      createdAt: now,
      updatedAt: now,
      state: initialGameState(kind, players.length),
      sameDevice: sameDevice || players.contains(botPlayerId),
    );
    _matches.add(match);
    sync?.matchSaved(match);
    final others = [for (final p in players) if (p != creator) playerName(p)];
    _addNotice(
      '${playerName(creator)} empezó ${kind.label} con ${_joinNames(others)}',
      kind: NoticeKind.game,
      memberId: creator,
    );
    _changed();
    return match;
  }

  /// Guarda una jugada: el estado nuevo, a quién le toca y si terminó.
  void playMove(
    String matchId,
    Map<String, dynamic> state, {
    required int nextTurn,
    int? winner,
    bool draw = false,
    String? by,
  }) {
    final m = matchById(matchId);
    if (m == null || m.finished) return;
    final mover = by ?? m.currentPlayer;
    m
      ..state = state
      ..turn = nextTurn
      ..winner = winner
      ..draw = draw
      ..lastBy = mover
      ..updatedAt = _clock();
    sync?.matchSaved(m);
    if (m.finished) {
      final text = draw
          ? '${m.kind.label}: empate entre ${_joinNames([for (final p in m.players) playerName(p)])}'
          : '${playerName(m.players[winner!])} ganó al ${m.kind.label.toLowerCase()} 🏆';
      _addNotice(text, kind: NoticeKind.game, memberId: winner == null ? m.createdBy : m.players[winner]);
    }
    _changed();
  }

  /// Borra la partida (abandonar o limpiar terminadas).
  void removeMatch(String matchId) {
    final before = _matches.length;
    _matches.removeWhere((m) => m.id == matchId);
    if (_matches.length == before) return;
    sync?.matchRemoved(matchId);
    _changed();
  }

  static String _joinNames(List<String> names) {
    if (names.isEmpty) return 'nadie';
    if (names.length == 1) return names.first;
    return '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
  }
}

Map<String, dynamic> _matchToJson(GameMatch m) => {
      'id': m.id,
      'kind': m.kind.name,
      'players': m.players,
      'createdBy': m.createdBy,
      'createdAt': m.createdAt.millisecondsSinceEpoch,
      'updatedAt': m.updatedAt.millisecondsSinceEpoch,
      'state': m.state,
      'turn': m.turn,
      'winner': m.winner,
      'draw': m.draw,
      'sameDevice': m.sameDevice,
      'lastBy': m.lastBy,
    };

GameMatch? _matchFromJson(Map<String, dynamic> j) {
  final kind = GameKind.values.asNameMap()[j['kind']];
  if (kind == null) return null;
  return GameMatch(
    id: j['id'] as String,
    kind: kind,
    players: (j['players'] as List).cast<String>(),
    createdBy: j['createdBy'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch((j['createdAt'] as num).toInt()),
    updatedAt: DateTime.fromMillisecondsSinceEpoch((j['updatedAt'] as num).toInt()),
    state: _deepCast(j['state']),
    turn: (j['turn'] as num?)?.toInt() ?? 0,
    winner: (j['winner'] as num?)?.toInt(),
    draw: j['draw'] as bool? ?? false,
    sameDevice: j['sameDevice'] as bool? ?? false,
    lastBy: j['lastBy'] as String?,
  );
}

/// Convierte lo que llega de Firestore o JSON a tipos simples (int, listas, mapas).
Map<String, dynamic> _deepCast(Object? raw) {
  Object? fix(Object? v) => switch (v) {
        Map() => {for (final e in v.entries) e.key as String: fix(e.value)},
        List() => [for (final x in v) fix(x)],
        double() when v == v.roundToDouble() => v.toInt(),
        _ => v,
      };
  return raw is Map ? (fix(raw) as Map<String, dynamic>) : <String, dynamic>{};
}
