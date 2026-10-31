part of 'family_store.dart';

/// Área de juegos: partidas por turnos entre miembros del hogar.
extension FamilyGames on FamilyStore {
  /// Partidas, la más reciente primero.
  List<GameMatch> get matches => [..._matches, ..._sharedMatches]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  GameMatch? matchById(String id) {
    for (final m in [..._matches, ..._sharedMatches]) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _saveMatch(GameMatch m) {
    if (m.withFriends) {
      sync?.sharedMatchSaved(m);
    } else {
      sync?.matchSaved(m);
    }
  }

  List<GameMatch> matchesOf(String memberId) => [for (final m in matches) if (m.players.contains(memberId)) m];

  /// Partidas en las que le toca jugar.
  int myTurnCount(String memberId) =>
      matches.where((m) => !m.finished && m.currentPlayer == memberId).length;

  /// Nombre para mostrar de un jugador (de la familia, de una familia amiga o Robi).
  String playerName(String id) {
    if (id == botPlayerId) return 'Robi';
    if (memberById(id) case final m?) return m.nickname;
    for (final f in _friendships) {
      for (final k in f.theirs) {
        if (k.id == id) return k.nickname;
      }
    }
    for (final g in _sharedMatches) {
      if (g.names[id] case final n?) return n;
    }
    return 'Alguien';
  }

  /// Avatar de un jugador de una familia amiga (`null` si no es de afuera).
  AvatarConfig? friendAvatar(String id) {
    for (final f in _friendships) {
      for (final k in f.theirs) {
        if (k.id == id) return k.avatar;
      }
    }
    return null;
  }

  List<Friendship> get friendships => [for (final f in _friendships) if (f.active) f];

  /// Amigos de otras familias con los que puede jugar este miembro.
  List<({Friendship friendship, FriendKid kid})> friendRivalsOf(String memberId) => [
        for (final f in friendships)
          if (f.mine.any((k) => k.id == memberId))
            for (final k in f.theirs) (friendship: f, kid: k),
      ];

  /// Manda una reacción fija a la partida (sin chat libre).
  void react(String matchId, String by, String text) {
    final m = matchById(matchId);
    if (m == null || !gameReactions.contains(text)) return;
    m
      ..reaction = text
      ..reactionBy = by;
    _saveMatch(m);
    _changed();
  }

  /// Los adultos juegan siempre; los chicos según la regla del hogar.
  bool canPlayGames(String memberId) => gamesLock(memberId) == null;

  /// Por qué no puede jugar ahora, o `null` si puede.
  GamesLock? gamesLock(String memberId) {
    final m = memberById(memberId);
    if (m == null || m.role.isAdult) return null;
    if (_gamesMinutes > 0 && gameSecondsToday(memberId) >= _gamesMinutes * 60) return GamesLock.time;
    if (templatesFor(memberId).isEmpty) return null;
    return completionRatio(memberId) >= _gamesRule.minRatio - 0.001 ? null : GamesLock.routine;
  }

  int get gamesMinutes => _gamesMinutes;
  List<String> get languages => List.unmodifiable(_languages);

  int gameSecondsToday(String memberId) => _gameSeconds[memberId] ?? 0;

  /// Minutos de juego que le quedan hoy, o `null` si no hay límite.
  int? gameMinutesLeft(String memberId) {
    if (_gamesMinutes == 0 || (memberById(memberId)?.role.isAdult ?? true)) return null;
    return ((_gamesMinutes * 60 - gameSecondsToday(memberId)) / 60).ceil().clamp(0, _gamesMinutes);
  }

  /// Suma tiempo de juego de un chico (se guarda en la nube cada minuto).
  void addGameSeconds(String memberId, int seconds) {
    if (memberById(memberId)?.role.isAdult ?? true) return;
    final before = gameSecondsToday(memberId);
    final after = before + seconds;
    _gameSeconds[memberId] = after;
    // Se avisa (y se guarda en la nube) solo al completar cada minuto, para no
    // redibujar las pantallas cada 10 segundos.
    if (after ~/ 60 != before ~/ 60) {
      sync?.gameTimeChanged(memberId, FamilyStore.dayKey(_clock()), after);
      _changed();
    }
  }

  void setGamesMinutes(int minutes) {
    if (minutes == _gamesMinutes) return;
    _gamesMinutes = minutes;
    sync?.homeSettingsChanged({'gamesMinutes': minutes});
    _changed();
  }

  void setLanguages(List<String> codes) {
    _languages = [...codes];
    sync?.homeSettingsChanged({'languages': codes});
    _changed();
  }

  /// Borra las partidas terminadas en las que participó.
  int removeFinishedMatches(String memberId) {
    final ids = [for (final m in matches) if (m.finished && m.players.contains(memberId)) m.id];
    for (final id in ids) {
      removeMatch(id);
    }
    if (ids.isNotEmpty) _changed();
    return ids.length;
  }

  GamesRule get gamesRule => _gamesRule;

  void setGamesRule(GamesRule rule) {
    if (rule == _gamesRule) return;
    _gamesRule = rule;
    sync?.gamesRuleChanged(rule);
    _changed();
  }

  /// Arranca una partida. [players] en orden de turno: el primero empieza.
  GameMatch createMatch(GameKind kind, List<String> players, {bool sameDevice = false, String? friendshipId}) {
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
      sameDevice: friendshipId == null && (sameDevice || players.contains(botPlayerId)),
      friendshipId: friendshipId,
      names: {for (final p in players) p: playerName(p)},
    );
    if (friendshipId != null) {
      _sharedMatches.add(match);
    } else {
      _matches.add(match);
    }
    _saveMatch(match);
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
    _saveMatch(m);
    if (m.finished) {
      final text = draw
          ? '${m.kind.label}: empate entre ${_joinNames([for (final p in m.players) playerName(p)])}'
          : '${playerName(m.players[winner!])} ganó en ${m.kind.label} 🏆';
      _addNotice(text, kind: NoticeKind.game, memberId: winner == null ? m.createdBy : m.players[winner]);
    }
    _changed();
  }

  /// Borra la partida (abandonar o limpiar terminadas).
  void removeMatch(String matchId) {
    final shared = _sharedMatches.where((m) => m.id == matchId).toList();
    if (shared.isNotEmpty) {
      _sharedMatches.removeWhere((m) => m.id == matchId);
      sync?.sharedMatchRemoved(matchId);
      _changed();
      return;
    }
    final before = _matches.length;
    _matches.removeWhere((m) => m.id == matchId);
    if (_matches.length == before) return;
    sync?.matchRemoved(matchId);
    _changed();
  }

  /// Id del registro del día con los puntos del quiz de palabras.
  static const wordQuizId = 'juego_palabras';

  /// Puntos que da el quiz de palabras: 1 por respuesta correcta, una vez por día.
  /// Devuelve los puntos ganados (0 si ya los ganó hoy o es adulto).
  int awardWordQuiz(String memberId, int correct, String language) {
    final m = memberById(memberId);
    if (m == null || m.role.isAdult || correct <= 0) return 0;
    final day = _today.putIfAbsent(memberId, () => {});
    if (day.containsKey(wordQuizId)) return 0;
    final completion = TaskCompletion(taskId: wordQuizId, completedAt: _clock(), pointsAwarded: correct);
    day[wordQuizId] = completion;
    sync?.taskChanged(memberId, FamilyStore.dayKey(_clock()), wordQuizId, completion);
    _addBalance(memberId, correct);
    // Para la medalla de palabras: los días que hizo el quiz.
    m.unlocked.add('quiz:${FamilyStore.dayKey(_clock())}');
    sync?.memberUpdated(m);
    _addNotice('${m.nickname} practicó $language: $correct de 5 en el quiz de palabras', kind: NoticeKind.game, memberId: memberId);
    _changed();
    return correct;
  }

  bool wordQuizDoneToday(String memberId) => _today[memberId]?.containsKey(wordQuizId) ?? false;

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
      'friendshipId': m.friendshipId,
      'names': m.names,
      'reaction': m.reaction,
      'reactionBy': m.reactionBy,
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
    friendshipId: j['friendshipId'] as String?,
    names: (j['names'] as Map?)?.map((k, v) => MapEntry(k as String, '$v')),
    reaction: j['reaction'] as String?,
    reactionBy: j['reactionBy'] as String?,
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
