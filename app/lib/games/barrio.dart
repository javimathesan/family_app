import 'dart:math';

/// Tipo de casilla de Mi Barrio.
enum BarrioType { start, property, surprise, tax, plaza, siesta, fountain }

class BarrioSquare {
  const BarrioSquare(this.name, this.emoji, this.type, {this.price = 0, this.group = -1});
  final String name;
  final String emoji;
  final BarrioType type;
  final int price;

  /// Grupo de color (las propiedades del mismo grupo cobran doble si son del mismo dueño).
  final int group;
}

/// Tarjeta de Sorpresa.
enum BarrioCard {
  couch('Encontraste monedas en el sillón: +20', 20),
  neighbor('Ayudaste a un vecino: +15', 15),
  lemonade('Vendiste limonada: +25', 25),
  icecream('Se te cayó el helado: pagás 10 al pozo', -10),
  toStart('Volvé a la Salida y cobrá 20', 0),
  back('Te olvidaste la mochila: retrocedé 3 casillas', 0),
  birthday('¡Es tu cumple! Cada jugador te da 10', 0),
  sleepy('Te dio sueño: perdés el próximo turno', 0);

  const BarrioCard(this.text, this.money);
  final String text;
  final int money;
}

/// Mi Barrio: juego de comprar lugares del barrio y cobrar alquiler.
///
/// Tablero de 20 casillas. Cada uno tira dos dados; si cae en un lugar
/// libre lo puede comprar; si es de otro, le paga alquiler (doble si el dueño
/// tiene todo el grupo de color). Quien se queda sin monedas sale del juego.
/// Termina cuando queda uno o se acaban las vueltas: gana el más rico
/// (monedas más el precio de sus lugares).
class Barrio {
  static const startCash = 200;
  static const passStart = 20;
  static const tax = 10;

  /// Turnos por jugador antes de contar quién es el más rico.
  static const turnsPerPlayer = 12;

  static const squares = [
    BarrioSquare('Salida', '🏁', BarrioType.start),
    BarrioSquare('Kiosco', '🍬', BarrioType.property, price: 20, group: 0),
    BarrioSquare('Panadería', '🥐', BarrioType.property, price: 25, group: 0),
    BarrioSquare('Sorpresa', '🎁', BarrioType.surprise),
    BarrioSquare('Impuesto', '🧾', BarrioType.tax),
    BarrioSquare('Plaza', '🌳', BarrioType.plaza),
    BarrioSquare('Biblioteca', '📚', BarrioType.property, price: 35, group: 1),
    BarrioSquare('Heladería', '🍦', BarrioType.property, price: 40, group: 1),
    BarrioSquare('Sorpresa', '🎁', BarrioType.surprise),
    BarrioSquare('Club', '⚽', BarrioType.property, price: 45, group: 2),
    BarrioSquare('Siesta', '😴', BarrioType.siesta),
    BarrioSquare('Cine', '🎬', BarrioType.property, price: 50, group: 2),
    BarrioSquare('Pileta', '🏊', BarrioType.property, price: 55, group: 3),
    BarrioSquare('Sorpresa', '🎁', BarrioType.surprise),
    BarrioSquare('Zoológico', '🦁', BarrioType.property, price: 60, group: 3),
    BarrioSquare('Fuente', '⛲', BarrioType.fountain),
    BarrioSquare('Estadio', '🏟️', BarrioType.property, price: 70, group: 4),
    BarrioSquare('Impuesto', '🧾', BarrioType.tax),
    BarrioSquare('Parque de diversiones', '🎡', BarrioType.property, price: 80, group: 4),
    BarrioSquare('Castillo', '🏰', BarrioType.property, price: 90, group: 4),
  ];

  static int baseRent(int square) => (squares[square].price * .3).round();

  static int rentOf(int square, List<int> owners) {
    final owner = owners[square];
    final group = squares[square].group;
    final all = [for (var i = 0; i < squares.length; i++) if (squares[i].group == group) i];
    final full = all.every((i) => owners[i] == owner);
    return baseRent(square) * (full ? 2 : 1);
  }
}

/// Estado de una partida de Mi Barrio. Los mensajes usan `{p0}`, `{p1}`…
/// en lugar de nombres; la pantalla los reemplaza.
class BarrioState {
  BarrioState({
    required this.pos,
    required this.cash,
    required this.owners,
    required this.out,
    required this.skip,
    required this.turnsLeft,
    this.pot = 0,
    this.buying = false,
    this.dice = const [],
    this.message,
  });

  factory BarrioState.initial(int players) => BarrioState(
        pos: List.filled(players, 0),
        cash: List.filled(players, Barrio.startCash),
        owners: List.filled(Barrio.squares.length, -1),
        out: List.filled(players, false),
        skip: List.filled(players, false),
        turnsLeft: Barrio.turnsPerPlayer * players,
      );

  factory BarrioState.fromJson(Map<String, dynamic> j) => BarrioState(
        pos: (j['pos'] as List).cast<int>().toList(),
        cash: (j['cash'] as List).cast<int>().toList(),
        owners: (j['owners'] as List).cast<int>().toList(),
        out: (j['out'] as List).cast<bool>().toList(),
        skip: (j['skip'] as List).cast<bool>().toList(),
        turnsLeft: j['turnsLeft'] as int,
        pot: j['pot'] as int? ?? 0,
        buying: j['buying'] as bool? ?? false,
        dice: ((j['dice'] as List?) ?? const []).cast<int>().toList(),
        message: j['message'] as String?,
      );

  final List<int> pos;
  final List<int> cash;

  /// Dueño de cada casilla (-1 si no tiene).
  final List<int> owners;
  final List<bool> out;

  /// Pierde el próximo turno (siesta).
  final List<bool> skip;
  int turnsLeft;
  int pot;

  /// El jugador de turno está decidiendo si compra donde cayó.
  bool buying;
  List<int> dice;
  String? message;

  Map<String, dynamic> toJson() => {
        'pos': pos,
        'cash': cash,
        'owners': owners,
        'out': out,
        'skip': skip,
        'turnsLeft': turnsLeft,
        'pot': pot,
        'buying': buying,
        'dice': dice,
        'message': message,
      };

  BarrioState copy() => BarrioState.fromJson(toJson());

  int get players => pos.length;

  int netWorth(int p) =>
      cash[p] + [for (var i = 0; i < owners.length; i++) if (owners[i] == p) Barrio.squares[i].price].fold(0, (a, b) => a + b);

  List<int> propertiesOf(int p) => [for (var i = 0; i < owners.length; i++) if (owners[i] == p) i];
}

/// Resultado de una acción: estado nuevo, a quién le toca y si terminó.
class BarrioStep {
  const BarrioStep(this.state, this.nextTurn, {this.winner, this.draw = false});
  final BarrioState state;
  final int nextTurn;
  final int? winner;
  final bool draw;
}

extension BarrioRules on BarrioState {
  /// Tira los dados y aplica la casilla donde cae. [card] elige la Sorpresa.
  BarrioStep roll(int player, int d1, int d2, int card) {
    if (buying) throw StateError('Primero decidí si comprás');
    final s = copy()..dice = [d1, d2];
    final notes = <String>[];
    final from = s.pos[player];
    final to = (from + d1 + d2) % Barrio.squares.length;
    if (to < from) {
      s.cash[player] += Barrio.passStart;
      notes.add('{p$player} pasó por la Salida: +${Barrio.passStart}');
    }
    s.pos[player] = to;
    s._land(player, card, notes);
    s.message = notes.join(' · ');
    if (s.buying) return BarrioStep(s, player);
    return s._endTurn(player);
  }

  /// Decide si compra el lugar donde cayó.
  BarrioStep decide(int player, {required bool buy}) {
    if (!buying) throw StateError('No hay nada para comprar');
    final s = copy()..buying = false;
    final sq = s.pos[player];
    final square = Barrio.squares[sq];
    if (buy) {
      s.cash[player] -= square.price;
      s.owners[sq] = player;
      s.message = '{p$player} compró ${square.name} ${square.emoji}';
    } else {
      s.message = '{p$player} no compró ${square.name}';
    }
    return s._endTurn(player);
  }

  /// Robi compra si después le quedan al menos 30 monedas.
  bool botWantsToBuy(int player) => cash[player] - Barrio.squares[pos[player]].price >= 30;

  void _land(int player, int card, List<String> notes, {int depth = 0}) {
    final sq = pos[player];
    final square = Barrio.squares[sq];
    switch (square.type) {
      case BarrioType.property:
        final owner = owners[sq];
        if (owner == -1) {
          if (cash[player] >= square.price) {
            buying = true;
            notes.add('{p$player} cayó en ${square.name}: ¿lo compra por ${square.price}?');
          } else {
            notes.add('{p$player} no tiene monedas para comprar ${square.name}');
          }
        } else if (owner == player) {
          notes.add('{p$player} está en su ${square.name}');
        } else if (out[owner]) {
          notes.add('{p$player} está en ${square.name}');
        } else {
          final rent = Barrio.rentOf(sq, owners);
          _pay(player, owner, rent, notes);
          notes.add('{p$player} le pagó $rent de alquiler a {p$owner}');
        }
      case BarrioType.surprise:
        final c = BarrioCard.values[card % BarrioCard.values.length];
        notes.add('🎁 ${c.text}');
        switch (c) {
          case BarrioCard.couch || BarrioCard.neighbor || BarrioCard.lemonade:
            cash[player] += c.money;
          case BarrioCard.icecream:
            _pay(player, null, -c.money, notes);
          case BarrioCard.toStart:
            pos[player] = 0;
            cash[player] += Barrio.passStart;
          case BarrioCard.back:
            pos[player] = (sq - 3 + Barrio.squares.length) % Barrio.squares.length;
            if (depth == 0) _land(player, card + 1, notes, depth: 1);
          case BarrioCard.birthday:
            for (var p = 0; p < players; p++) {
              if (p != player && !out[p]) _pay(p, player, 10, notes);
            }
          case BarrioCard.sleepy:
            skip[player] = true;
        }
      case BarrioType.tax:
        _pay(player, null, Barrio.tax, notes);
        notes.add('{p$player} pagó ${Barrio.tax} de impuesto al pozo');
      case BarrioType.fountain:
        if (pot > 0) notes.add('{p$player} se llevó el pozo: +$pot ⛲');
        cash[player] += pot;
        pot = 0;
      case BarrioType.siesta:
        skip[player] = true;
        notes.add('{p$player} se durmió una siesta: pierde el próximo turno 😴');
      case BarrioType.start || BarrioType.plaza:
        break;
    }
  }

  /// Paga a otro jugador o al pozo (`to == null`). Si no le alcanza, queda afuera.
  void _pay(int from, int? to, int amount, List<String> notes) {
    final paid = min(amount, cash[from]);
    cash[from] -= paid;
    if (to == null) {
      pot += paid;
    } else {
      cash[to] += paid;
    }
    if (paid < amount) {
      out[from] = true;
      for (var i = 0; i < owners.length; i++) {
        if (owners[i] == from) owners[i] = -1;
      }
      notes.add('{p$from} se quedó sin monedas y sale del juego');
    }
  }

  BarrioStep _endTurn(int player) {
    turnsLeft--;
    final alive = [for (var p = 0; p < players; p++) if (!out[p]) p];
    if (alive.length == 1) return BarrioStep(this, player, winner: alive.first);
    if (turnsLeft <= 0) {
      final best = alive.map(netWorth).reduce(max);
      final top = alive.where((p) => netWorth(p) == best).toList();
      message = '${message ?? ''} · Se terminaron las vueltas: gana el más rico'.replaceFirst(RegExp(r'^ · '), '');
      return top.length == 1 ? BarrioStep(this, player, winner: top.first) : BarrioStep(this, player, draw: true);
    }
    var next = player;
    for (var guard = 0; guard < players * 2; guard++) {
      next = (next + 1) % players;
      if (out[next]) continue;
      if (skip[next]) {
        skip[next] = false;
        turnsLeft--;
        continue;
      }
      break;
    }
    return BarrioStep(this, next);
  }
}

/// Dos dados y una tarjeta al azar.
({int d1, int d2, int card}) barrioRoll([Random? random]) {
  final r = random ?? Random();
  return (d1: r.nextInt(6) + 1, d2: r.nextInt(6) + 1, card: r.nextInt(BarrioCard.values.length));
}
