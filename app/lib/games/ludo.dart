import 'dart:math';

/// Ludo para 2 a 4 jugadores.
///
/// Cada ficha guarda su avance desde la salida de su color:
/// - `-1`: en la base (sale con un 6);
/// - `0..50`: en el recorrido común de 52 casillas;
/// - `51..55`: en el pasillo de su color;
/// - `56`: llegó a la meta.
///
/// Reglas: con 6 se vuelve a tirar (al tercer 6 seguido se pierde el turno);
/// comer una ficha o llegar a la meta también da otro tiro; en las casillas
/// seguras (salidas y estrellas) no se come; para entrar a la meta hace
/// falta el número justo.
class Ludo {
  static const trackLength = 52;
  static const lastTrack = 50;
  static const goal = 56;

  /// Casillas del recorrido donde no se puede comer: salidas y estrellas.
  static const safeSquares = {0, 8, 13, 21, 26, 34, 39, 47};

  /// Colores que se usan según la cantidad de jugadores (enfrentados si son 2).
  static List<int> seatsFor(int players) => switch (players) {
        2 => const [0, 2],
        3 => const [0, 1, 2],
        _ => const [0, 1, 2, 3],
      };

  /// Casilla del recorrido común (0..51) de una ficha, o `null` si no está en él.
  static int? absolute(int seat, int progress) =>
      progress < 0 || progress > lastTrack ? null : (seat * 13 + progress) % trackLength;

  /// Adónde llegaría la ficha con ese dado, o `null` si no puede moverse.
  static int? target(int progress, int dice) {
    if (progress == goal) return null;
    if (progress < 0) return dice == 6 ? 0 : null;
    final next = progress + dice;
    return next > goal ? null : next;
  }
}

/// Estado de una partida de ludo.
class LudoState {
  LudoState({required this.seats, required this.tokens, this.dice, this.sixes = 0, this.lastRoll, this.message});

  factory LudoState.initial(int players) => LudoState(
        seats: Ludo.seatsFor(players),
        tokens: [for (var i = 0; i < players; i++) List.filled(4, -1)],
      );

  factory LudoState.fromJson(Map<String, dynamic> j) => LudoState(
        seats: (j['seats'] as List).cast<int>(),
        tokens: _unflatten((j['tokens'] as List).cast<int>()),
        dice: j['dice'] as int?,
        sixes: j['sixes'] as int? ?? 0,
        lastRoll: j['lastRoll'] as int?,
        message: j['message'] as String?,
      );

  /// Color de cada jugador (0 rojo, 1 verde, 2 amarillo, 3 azul).
  final List<int> seats;

  /// Avance de las 4 fichas de cada jugador.
  final List<List<int>> tokens;

  /// Dado tirado que falta usar; `null` si toca tirar.
  final int? dice;

  /// Seises seguidos del jugador de turno.
  final int sixes;

  /// Último dado tirado (para mostrarlo).
  final int? lastRoll;

  /// Qué pasó en la última jugada ("¡Comió!", "Sin movimientos"…).
  final String? message;

  Map<String, dynamic> toJson() => {
        'seats': seats,
        // Firestore no acepta listas dentro de listas: se guardan en fila.
        'tokens': [for (final t in tokens) ...t],
        'dice': dice,
        'sixes': sixes,
        'lastRoll': lastRoll,
        'message': message,
      };

  static List<List<int>> _unflatten(List<int> flat) => [
        for (var i = 0; i < flat.length; i += 4) flat.sublist(i, i + 4),
      ];

  bool hasWon(int player) => tokens[player].every((p) => p == Ludo.goal);

  /// Fichas que el jugador puede mover con el dado actual.
  List<int> movable(int player) {
    final d = dice;
    if (d == null) return const [];
    return [
      for (var i = 0; i < 4; i++)
        if (Ludo.target(tokens[player][i], d) != null) i,
    ];
  }
}

/// Resultado de tirar o mover: el estado nuevo y a quién le toca.
class LudoStep {
  const LudoStep(this.state, this.nextTurn, {this.winner});
  final LudoState state;
  final int nextTurn;
  final int? winner;
}

extension LudoRules on LudoState {
  int _next(int player) => (player + 1) % tokens.length;

  /// Tira el dado. Si no hay fichas para mover, pasa el turno.
  LudoStep roll(int player, int value) {
    if (dice != null) throw StateError('Ya tiraste: mové una ficha');
    final sixesNow = value == 6 ? sixes + 1 : 0;
    if (sixesNow == 3) {
      return LudoStep(
        LudoState(seats: seats, tokens: tokens, lastRoll: value, message: 'Tres 6 seguidos: pierde el turno'),
        _next(player),
      );
    }
    final rolled = LudoState(seats: seats, tokens: tokens, dice: value, sixes: sixesNow, lastRoll: value);
    if (rolled.movable(player).isEmpty) {
      return LudoStep(
        LudoState(seats: seats, tokens: tokens, lastRoll: value, message: 'Sin movimientos con $value'),
        _next(player),
      );
    }
    return LudoStep(rolled, player);
  }

  /// Mueve una ficha con el dado tirado.
  LudoStep move(int player, int token) {
    final d = dice;
    if (d == null) throw StateError('Primero tirá el dado');
    final to = Ludo.target(tokens[player][token], d);
    if (to == null) throw ArgumentError('Esa ficha no se puede mover');

    final next = [for (final t in tokens) [...t]];
    next[player][token] = to;
    var captured = false;
    final square = Ludo.absolute(seats[player], to);
    if (square != null && !Ludo.safeSquares.contains(square)) {
      for (var p = 0; p < next.length; p++) {
        if (p == player) continue;
        for (var i = 0; i < 4; i++) {
          if (Ludo.absolute(seats[p], next[p][i]) == square) {
            next[p][i] = -1;
            captured = true;
          }
        }
      }
    }
    final arrived = to == Ludo.goal;
    final state = LudoState(
      seats: seats,
      tokens: next,
      sixes: d == 6 ? sixes : 0,
      lastRoll: d,
      message: captured ? '¡Comió una ficha!' : (arrived ? '¡Una ficha llegó a la meta!' : null),
    );
    if (state.hasWon(player)) return LudoStep(state, player, winner: player);
    final again = d == 6 || captured || arrived;
    return LudoStep(
      again && d != 6 ? LudoState(seats: seats, tokens: next, lastRoll: d, message: state.message) : state,
      again ? player : _next(player),
    );
  }

  /// Robi elige: comer, llegar a la meta, salir de la base, escapar o avanzar la más adelantada.
  int botToken(int player) {
    final options = movable(player);
    final d = dice!;
    int score(int i) {
      final from = tokens[player][i];
      final to = Ludo.target(from, d)!;
      final square = Ludo.absolute(seats[player], to);
      var s = to;
      if (to == Ludo.goal) s += 200;
      if (from < 0) s += 150;
      if (square != null && !Ludo.safeSquares.contains(square)) {
        for (var p = 0; p < tokens.length; p++) {
          if (p != player && tokens[p].any((t) => Ludo.absolute(seats[p], t) == square)) s += 300;
        }
      }
      if (square != null && Ludo.safeSquares.contains(square)) s += 30;
      return s;
    }

    options.sort((a, b) => score(b).compareTo(score(a)));
    return options.first;
  }
}

/// Dado de 1 a 6.
int rollDice([Random? random]) => (random ?? Random()).nextInt(6) + 1;
