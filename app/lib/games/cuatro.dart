import 'dart:math';

/// 4 en línea: 6 filas por 7 columnas. Casilla = fila * 7 + columna, la
/// fila 0 es la de arriba. Cada casilla vale -1 (vacía) o el jugador (0 o 1).
class Cuatro {
  static const rows = 6;
  static const cols = 7;

  static List<int> initial() => List.filled(rows * cols, -1);

  /// Fila donde cae la ficha en esa columna, o -1 si está llena.
  static int dropRow(List<int> cells, int col) {
    for (var r = rows - 1; r >= 0; r--) {
      if (cells[r * cols + col] == -1) return r;
    }
    return -1;
  }

  static bool canPlay(List<int> cells, int col) =>
      col >= 0 && col < cols && dropRow(cells, col) >= 0 && winningLine(cells) == null;

  static List<int> play(List<int> cells, int col, int player) {
    if (!canPlay(cells, col)) throw ArgumentError('Columna llena');
    return [...cells]..[dropRow(cells, col) * cols + col] = player;
  }

  static bool isFull(List<int> cells) => !cells.contains(-1);

  /// Las 4 casillas ganadoras, o `null`.
  static List<int>? winningLine(List<int> cells) {
    const dirs = [(0, 1), (1, 0), (1, 1), (1, -1)];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final v = cells[r * cols + c];
        if (v < 0) continue;
        for (final (dr, dc) in dirs) {
          final line = <int>[];
          for (var k = 0; k < 4; k++) {
            final rr = r + dr * k, cc = c + dc * k;
            if (rr < 0 || rr >= rows || cc < 0 || cc >= cols || cells[rr * cols + cc] != v) break;
            line.add(rr * cols + cc);
          }
          if (line.length == 4) return line;
        }
      }
    }
    return null;
  }

  static int? winner(List<int> cells) {
    final l = winningLine(cells);
    return l == null ? null : cells[l.first];
  }

  /// Robi: gana si puede, bloquea, evita regalar la jugada y prefiere el centro.
  static int botMove(List<int> cells, int me, [Random? random]) {
    final r = random ?? Random();
    final free = [for (var c = 0; c < cols; c++) if (dropRow(cells, c) >= 0) c];
    for (final who in [me, 1 - me]) {
      for (final c in free) {
        if (winner(play(cells, c, who)) == me && who == me) return c;
        if (who != me && winner(play(cells, c, who)) == who) return c;
      }
    }
    final safe = [
      for (final c in free)
        if (!_givesWin(play(cells, c, me), 1 - me)) c,
    ];
    final options = safe.isEmpty ? free : safe;
    if (r.nextInt(6) == 0) return options[r.nextInt(options.length)];
    options.sort((a, b) => (a - 3).abs().compareTo((b - 3).abs()));
    final best = options.where((c) => (c - 3).abs() == (options.first - 3).abs()).toList();
    return best[r.nextInt(best.length)];
  }

  static bool _givesWin(List<int> cells, int rival) {
    for (var c = 0; c < cols; c++) {
      if (dropRow(cells, c) >= 0 && winner(play(cells, c, rival)) == rival) return true;
    }
    return false;
  }
}
