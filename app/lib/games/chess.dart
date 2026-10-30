import 'dart:math';

/// Jugada de ajedrez: casillas 0..63 (0 = a8, 63 = h1) y coronación opcional.
class ChessMove {
  const ChessMove(this.from, this.to, [this.promo]);
  final int from;
  final int to;

  /// Pieza a la que corona un peón: 'q', 'r', 'b' o 'n'.
  final String? promo;

  @override
  bool operator ==(Object other) => other is ChessMove && other.from == from && other.to == to && other.promo == promo;

  @override
  int get hashCode => Object.hash(from, to, promo);

  @override
  String toString() => '${Chess.squareName(from)}${Chess.squareName(to)}${promo ?? ''}';
}

/// Cómo terminó (o no) la partida.
enum ChessStatus { playing, checkmate, stalemate, draw }

/// Posición de ajedrez con todas las reglas: enroque, captura al paso,
/// coronación, jaque, jaque mate, ahogado y tablas por material o 50 jugadas.
///
/// Piezas: mayúsculas blancas (PNBRQK), minúsculas negras.
class Chess {
  Chess({
    required this.board,
    required this.whiteToMove,
    this.castling = 'KQkq',
    this.ep,
    this.halfmove = 0,
    this.lastFrom,
    this.lastTo,
  });

  factory Chess.initial() {
    const back = ['r', 'n', 'b', 'q', 'k', 'b', 'n', 'r'];
    return Chess(
      board: [
        ...back,
        ...List.filled(8, 'p'),
        ...List<String?>.filled(32, null),
        ...List.filled(8, 'P'),
        ...back.map((p) => p.toUpperCase()),
      ],
      whiteToMove: true,
    );
  }

  factory Chess.fromJson(Map<String, dynamic> j) => Chess(
        board: [for (final c in (j['board'] as String).split('')) c == '.' ? null : c],
        whiteToMove: j['white'] as bool,
        castling: j['castling'] as String? ?? '',
        ep: j['ep'] as int?,
        halfmove: j['half'] as int? ?? 0,
        lastFrom: j['lastFrom'] as int?,
        lastTo: j['lastTo'] as int?,
      );

  final List<String?> board;
  final bool whiteToMove;
  final String castling;

  /// Casilla donde se puede capturar al paso (la que saltó el peón).
  final int? ep;
  final int halfmove;
  final int? lastFrom;
  final int? lastTo;

  Map<String, dynamic> toJson() => {
        'board': board.map((p) => p ?? '.').join(),
        'white': whiteToMove,
        'castling': castling,
        'ep': ep,
        'half': halfmove,
        'lastFrom': lastFrom,
        'lastTo': lastTo,
      };

  static String squareName(int sq) => '${'abcdefgh'[sq % 8]}${8 - sq ~/ 8}';
  static int square(String name) => (8 - int.parse(name[1])) * 8 + 'abcdefgh'.indexOf(name[0]);

  static bool isWhite(String p) => p.toUpperCase() == p;

  // ----------------------------------------------------------- ataques

  static const _knight = [(-2, -1), (-2, 1), (-1, -2), (-1, 2), (1, -2), (1, 2), (2, -1), (2, 1)];
  static const _king = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)];
  static const _rook = [(-1, 0), (1, 0), (0, -1), (0, 1)];
  static const _bishop = [(-1, -1), (-1, 1), (1, -1), (1, 1)];

  /// Si alguna pieza del color indicado ataca esa casilla.
  bool isAttacked(int sq, {required bool byWhite}) {
    final r = sq ~/ 8, c = sq % 8;
    String? at(int rr, int cc) => rr < 0 || rr > 7 || cc < 0 || cc > 7 ? null : board[rr * 8 + cc];
    bool mine(String? p, String type) => p != null && isWhite(p) == byWhite && p.toLowerCase() == type;

    // Peones: atacan en diagonal hacia adelante.
    final pr = byWhite ? r + 1 : r - 1;
    if (mine(at(pr, c - 1), 'p') || mine(at(pr, c + 1), 'p')) return true;
    for (final (dr, dc) in _knight) {
      if (mine(at(r + dr, c + dc), 'n')) return true;
    }
    for (final (dr, dc) in _king) {
      if (mine(at(r + dr, c + dc), 'k')) return true;
    }
    bool slide(List<(int, int)> dirs, String a, String b) {
      for (final (dr, dc) in dirs) {
        var rr = r + dr, cc = c + dc;
        while (rr >= 0 && rr < 8 && cc >= 0 && cc < 8) {
          final p = board[rr * 8 + cc];
          if (p != null) {
            if (mine(p, a) || mine(p, b)) return true;
            break;
          }
          rr += dr;
          cc += dc;
        }
      }
      return false;
    }

    return slide(_rook, 'r', 'q') || slide(_bishop, 'b', 'q');
  }

  int? kingSquare(bool white) {
    final k = white ? 'K' : 'k';
    final i = board.indexOf(k);
    return i < 0 ? null : i;
  }

  bool inCheck([bool? white]) {
    final w = white ?? whiteToMove;
    final k = kingSquare(w);
    return k != null && isAttacked(k, byWhite: !w);
  }

  // ----------------------------------------------------------- jugadas

  List<ChessMove> _pseudoMoves() {
    final moves = <ChessMove>[];
    final white = whiteToMove;
    bool own(String? p) => p != null && isWhite(p) == white;
    bool enemy(String? p) => p != null && isWhite(p) != white;

    for (var sq = 0; sq < 64; sq++) {
      final p = board[sq];
      if (!own(p)) continue;
      final r = sq ~/ 8, c = sq % 8;
      final type = p!.toLowerCase();

      void add(int to) {
        final promoRow = white ? 0 : 7;
        if (type == 'p' && to ~/ 8 == promoRow) {
          for (final pr in const ['q', 'r', 'b', 'n']) {
            moves.add(ChessMove(sq, to, pr));
          }
        } else {
          moves.add(ChessMove(sq, to));
        }
      }

      switch (type) {
        case 'p':
          final dir = white ? -1 : 1;
          final one = r + dir;
          if (one >= 0 && one < 8 && board[one * 8 + c] == null) {
            add(one * 8 + c);
            final startRow = white ? 6 : 1;
            final two = r + 2 * dir;
            if (r == startRow && board[two * 8 + c] == null) add(two * 8 + c);
          }
          for (final dc in const [-1, 1]) {
            final cc = c + dc;
            if (one < 0 || one > 7 || cc < 0 || cc > 7) continue;
            final to = one * 8 + cc;
            if (enemy(board[to]) || to == ep) add(to);
          }
        case 'n' || 'k':
          for (final (dr, dc) in type == 'n' ? _knight : _king) {
            final rr = r + dr, cc = c + dc;
            if (rr < 0 || rr > 7 || cc < 0 || cc > 7) continue;
            if (!own(board[rr * 8 + cc])) add(rr * 8 + cc);
          }
          if (type == 'k') _addCastling(moves, sq);
        default:
          final dirs = switch (type) { 'r' => _rook, 'b' => _bishop, _ => [..._rook, ..._bishop] };
          for (final (dr, dc) in dirs) {
            var rr = r + dr, cc = c + dc;
            while (rr >= 0 && rr < 8 && cc >= 0 && cc < 8) {
              final t = board[rr * 8 + cc];
              if (own(t)) break;
              add(rr * 8 + cc);
              if (t != null) break;
              rr += dr;
              cc += dc;
            }
          }
      }
    }
    return moves;
  }

  void _addCastling(List<ChessMove> moves, int kingSq) {
    final white = whiteToMove;
    final home = white ? 60 : 4;
    if (kingSq != home || inCheck(white)) return;
    final rook = white ? 'R' : 'r';
    bool empty(List<int> sqs) => sqs.every((s) => board[s] == null);
    bool safe(List<int> sqs) => sqs.every((s) => !isAttacked(s, byWhite: !white));
    if (castling.contains(white ? 'K' : 'k') && board[home + 3] == rook && empty([home + 1, home + 2]) && safe([home + 1, home + 2])) {
      moves.add(ChessMove(home, home + 2));
    }
    if (castling.contains(white ? 'Q' : 'q') && board[home - 4] == rook && empty([home - 1, home - 2, home - 3]) && safe([home - 1, home - 2])) {
      moves.add(ChessMove(home, home - 2));
    }
  }

  /// Aplica la jugada (sin revisar si es legal).
  Chess apply(ChessMove m) {
    final b = [...board];
    final p = b[m.from]!;
    final type = p.toLowerCase();
    final white = isWhite(p);
    final captured = b[m.to];
    int? newEp;

    b[m.to] = p;
    b[m.from] = null;
    if (type == 'p') {
      if (m.to == ep) b[(m.from ~/ 8) * 8 + m.to % 8] = null; // captura al paso
      if ((m.to - m.from).abs() == 16) newEp = (m.from + m.to) ~/ 2;
      if (m.to ~/ 8 == 0 || m.to ~/ 8 == 7) {
        final promo = m.promo ?? 'q';
        b[m.to] = white ? promo.toUpperCase() : promo;
      }
    }
    if (type == 'k' && (m.to - m.from).abs() == 2) {
      final kingSide = m.to > m.from;
      final rookFrom = kingSide ? m.from + 3 : m.from - 4;
      final rookTo = kingSide ? m.from + 1 : m.from - 1;
      b[rookTo] = b[rookFrom];
      b[rookFrom] = null;
    }

    var rights = castling;
    void drop(String s) => rights = rights.replaceAll(s, '');
    if (type == 'k') drop(white ? 'K' : 'k');
    if (type == 'k') drop(white ? 'Q' : 'q');
    for (final sq in [m.from, m.to]) {
      if (sq == 63) drop('K');
      if (sq == 56) drop('Q');
      if (sq == 7) drop('k');
      if (sq == 0) drop('q');
    }

    return Chess(
      board: b,
      whiteToMove: !whiteToMove,
      castling: rights,
      ep: newEp,
      halfmove: type == 'p' || captured != null ? 0 : halfmove + 1,
      lastFrom: m.from,
      lastTo: m.to,
    );
  }

  /// Jugadas legales del que mueve (no dejan a su rey en jaque).
  List<ChessMove> legalMoves() => [
        for (final m in _pseudoMoves())
          if (!apply(m).inCheck(whiteToMove)) m,
      ];

  List<ChessMove> movesFrom(int sq) => [for (final m in legalMoves()) if (m.from == sq) m];

  bool get insufficientMaterial {
    final pieces = board.whereType<String>().map((p) => p.toLowerCase()).where((p) => p != 'k').toList();
    return pieces.isEmpty || (pieces.length == 1 && (pieces.first == 'b' || pieces.first == 'n'));
  }

  ChessStatus get status {
    if (legalMoves().isEmpty) return inCheck() ? ChessStatus.checkmate : ChessStatus.stalemate;
    if (insufficientMaterial || halfmove >= 100) return ChessStatus.draw;
    return ChessStatus.playing;
  }

  // ------------------------------------------------------------- Robi

  static const _values = {'p': 1.0, 'n': 3.0, 'b': 3.2, 'r': 5.0, 'q': 9.0, 'k': 0.0};

  /// Material y un poco de centro, desde el punto de vista de las blancas.
  double evaluate() {
    var s = 0.0;
    for (var sq = 0; sq < 64; sq++) {
      final p = board[sq];
      if (p == null) continue;
      final r = sq ~/ 8, c = sq % 8;
      final center = (r >= 2 && r <= 5 && c >= 2 && c <= 5) ? 0.1 : 0.0;
      final v = _values[p.toLowerCase()]! + center;
      s += isWhite(p) ? v : -v;
    }
    return s;
  }

  /// Robi mira dos jugadas: la suya y la mejor respuesta del rival.
  ChessMove botMove([Random? random]) {
    final r = random ?? Random();
    final sign = whiteToMove ? 1.0 : -1.0;
    final moves = legalMoves();
    var best = -double.infinity;
    final bestMoves = <ChessMove>[];
    for (final m in moves) {
      if (m.promo != null && m.promo != 'q') continue;
      final after = apply(m);
      final replies = after.legalMoves();
      double score;
      if (replies.isEmpty) {
        score = after.inCheck() ? 1000 : 0;
      } else {
        score = double.infinity;
        for (final reply in replies) {
          final v = sign * after.apply(reply).evaluate();
          if (v < score) score = v;
        }
      }
      score += r.nextDouble() * 0.05;
      if (score > best + 0.01) {
        best = score;
        bestMoves
          ..clear()
          ..add(m);
      } else if ((score - best).abs() <= 0.01) {
        bestMoves.add(m);
      }
    }
    return bestMoves[r.nextInt(bestMoves.length)];
  }
}
