import 'dart:math';

/// Colorín: juego de cartas de colores, con reglas propias del estilo de
/// los clásicos de "descartar por color o número".
///
/// Cartas: `<color><valor>`. Colores `r` rojo, `y` amarillo, `g` verde, `b`
/// azul y `w` comodín. Valores: `0`–`9`, `S` bloqueo (pierde el turno el
/// siguiente), `R` reversa, `D` +2, `W` cambio de color y `F` +4.
///
/// Reglas: se tira una carta del mismo color o del mismo valor, o un comodín.
/// Si no podés, robás una; si sirve la podés tirar, si no pasás. Quien se
/// queda con una carta tiene que decir "¡Última!" al tirar la anteúltima;
/// si se olvida, roba 2. Gana el primero que se queda sin cartas.
abstract final class Colorin {
  static const colors = ['r', 'y', 'g', 'b'];
  static const handSize = 7;

  static List<String> newDeck() => [
        for (final c in colors) ...[
          '${c}0',
          for (final v in ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'S', 'R', 'D']) ...['$c$v', '$c$v'],
        ],
        for (var i = 0; i < 4; i++) ...['wW', 'wF'],
      ];

  static String colorOf(String card) => card[0];
  static String valueOf(String card) => card.substring(1);
  static bool isWild(String card) => card[0] == 'w';

  static bool canPlay(String card, {required String top, required String color}) =>
      isWild(card) || colorOf(card) == color || valueOf(card) == valueOf(top);
}

class ColorinState {
  ColorinState({
    required this.deck,
    required this.discard,
    required this.hands,
    required this.color,
    this.direction = 1,
    this.drew = false,
    this.message,
  });

  /// Reparte 7 cartas a cada uno y da vuelta la primera (un número).
  factory ColorinState.deal(int players, [Random? random]) {
    final r = random ?? Random();
    final deck = Colorin.newDeck()..shuffle(r);
    final hands = <String, List<String>>{
      for (var p = 0; p < players; p++) '$p': [for (var i = 0; i < Colorin.handSize; i++) deck.removeLast()],
    };
    var first = deck.removeLast();
    while (!RegExp(r'^[rygb][0-9]$').hasMatch(first)) {
      deck.insert(0, first);
      first = deck.removeLast();
    }
    return ColorinState(deck: deck, discard: [first], hands: hands, color: Colorin.colorOf(first));
  }

  factory ColorinState.fromJson(Map<String, dynamic> j) => ColorinState(
        deck: (j['deck'] as List).cast<String>().toList(),
        discard: (j['discard'] as List).cast<String>().toList(),
        hands: {for (final e in (j['hands'] as Map).entries) e.key as String: (e.value as List).cast<String>().toList()},
        color: j['color'] as String,
        direction: j['dir'] as int? ?? 1,
        drew: j['drew'] as bool? ?? false,
        message: j['message'] as String?,
      );

  final List<String> deck;
  final List<String> discard;
  final Map<String, List<String>> hands;
  String color;
  int direction;

  /// El jugador de turno ya robó (puede tirar la que robó o pasar).
  bool drew;

  /// Qué pasó (usa `{p0}`, `{p1}`… para los nombres).
  String? message;

  Map<String, dynamic> toJson() => {
        'deck': deck,
        'discard': discard,
        'hands': hands,
        'color': color,
        'dir': direction,
        'drew': drew,
        'message': message,
      };

  ColorinState copy() => ColorinState.fromJson(toJson());

  int get players => hands.length;
  String get top => discard.last;
  List<String> hand(int p) => hands['$p']!;

  List<int> playable(int p) => [
        for (var i = 0; i < hand(p).length; i++)
          if (Colorin.canPlay(hand(p)[i], top: top, color: color)) i,
      ];
}

class ColorinStep {
  const ColorinStep(this.state, this.nextTurn, {this.winner});
  final ColorinState state;
  final int nextTurn;
  final int? winner;
}

extension ColorinRules on ColorinState {
  int _seat(int from, int steps) => ((from + direction * steps) % players + players) % players;

  /// Roba una carta del mazo (si se termina, se mezcla el descarte).
  String _take(Random r) {
    if (deck.isEmpty) {
      final keep = discard.removeLast();
      deck.addAll(discard..shuffle(r));
      discard
        ..clear()
        ..add(keep);
    }
    return deck.isEmpty ? 'r0' : deck.removeLast();
  }

  void _give(int p, int n, Random r) {
    for (var i = 0; i < n; i++) {
      hand(p).add(_take(r));
    }
  }

  /// Tira la carta [index]. Para comodines hace falta [chosen] (r, y, g o b).
  ColorinStep play(int p, int index, {String? chosen, bool saidLast = false, Random? random}) {
    final r = random ?? Random();
    final s = copy();
    final card = s.hand(p)[index];
    if (!Colorin.canPlay(card, top: s.top, color: s.color)) throw ArgumentError('Esa carta no se puede tirar');
    if (Colorin.isWild(card) && !Colorin.colors.contains(chosen)) throw ArgumentError('Elegí un color');
    s.hand(p).removeAt(index);
    s.discard.add(card);
    s.color = Colorin.isWild(card) ? chosen! : Colorin.colorOf(card);
    s.drew = false;
    final notes = <String>[];
    if (s.hand(p).isEmpty) {
      s.message = '¡{p$p} se quedó sin cartas!';
      return ColorinStep(s, p, winner: p);
    }
    if (s.hand(p).length == 1) {
      if (saidLast) {
        notes.add('{p$p}: ¡Última!');
      } else {
        s._give(p, 2, r);
        notes.add('{p$p} no dijo "¡Última!" y roba 2');
      }
    }
    var next = s._seat(p, 1);
    switch (Colorin.valueOf(card)) {
      case 'S':
        notes.add('{p$next} pierde el turno');
        next = s._seat(p, 2);
      case 'R':
        s.direction = -s.direction;
        notes.add('¡Reversa!');
        next = s.players == 2 ? p : s._seat(p, 1);
      case 'D':
        s._give(next, 2, r);
        notes.add('{p$next} roba 2 y pierde el turno');
        next = s._seat(p, 2);
      case 'F':
        s._give(next, 4, r);
        notes.add('{p$next} roba 4 y pierde el turno');
        next = s._seat(p, 2);
    }
    s.message = notes.isEmpty ? null : notes.join(' · ');
    return ColorinStep(s, next);
  }

  /// Roba una carta. Si sirve, sigue jugando el mismo; si no, pasa.
  ColorinStep draw(int p, {Random? random}) {
    if (drew) throw StateError('Ya robaste: tirá o pasá');
    final s = copy();
    final card = s._take(random ?? Random());
    s.hand(p).add(card);
    if (Colorin.canPlay(card, top: s.top, color: s.color)) {
      s.drew = true;
      s.message = '{p$p} robó una carta';
      return ColorinStep(s, p);
    }
    s.message = '{p$p} robó y pasa';
    return ColorinStep(s, s._seat(p, 1));
  }

  /// Pasa después de robar.
  ColorinStep pass(int p) {
    final s = copy()
      ..drew = false
      ..message = '{p$p} pasa';
    return ColorinStep(s, s._seat(p, 1));
  }

  /// Robi: tira del mismo color (primero las cartas de acción), después los
  /// números iguales y al final los comodines; elige el color que más tiene.
  ({int? card, String? color}) botChoice(int p) {
    final options = playable(p);
    if (options.isEmpty) return (card: null, color: null);
    int rank(int i) {
      final c = hand(p)[i];
      if (Colorin.isWild(c)) return c == 'wF' ? 0 : 1;
      if (Colorin.colorOf(c) == color) return RegExp(r'[SRD]').hasMatch(Colorin.valueOf(c)) ? 4 : 3;
      return 2;
    }

    options.sort((a, b) => rank(b).compareTo(rank(a)));
    final pick = options.first;
    String? chosen;
    if (Colorin.isWild(hand(p)[pick])) {
      final counts = {for (final c in Colorin.colors) c: hand(p).where((x) => x[0] == c).length};
      chosen = counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    }
    return (card: pick, color: chosen);
  }
}
