import 'dart:math';

/// Tres en raya. Casillas 0..8 de izquierda a derecha y de arriba abajo;
/// cada una vale -1 (vacía) o el número de jugador (0 o 1).
class Tateti {
  static const lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // filas
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // columnas
    [0, 4, 8], [2, 4, 6], // diagonales
  ];

  static List<int> initial() => List.filled(9, -1);

  /// Línea ganadora o `null`.
  static List<int>? winningLine(List<int> cells) {
    for (final l in lines) {
      final v = cells[l[0]];
      if (v >= 0 && v == cells[l[1]] && v == cells[l[2]]) return l;
    }
    return null;
  }

  static int? winner(List<int> cells) {
    final l = winningLine(cells);
    return l == null ? null : cells[l[0]];
  }

  static bool isFull(List<int> cells) => !cells.contains(-1);

  static bool canPlay(List<int> cells, int index) =>
      index >= 0 && index < 9 && cells[index] == -1 && winner(cells) == null;

  static List<int> play(List<int> cells, int index, int player) {
    if (!canPlay(cells, index)) throw ArgumentError('Casilla ocupada');
    return [...cells]..[index] = player;
  }

  /// Robi: gana si puede, si no bloquea, si no centro, esquina o lo que haya.
  static int botMove(List<int> cells, int me, [Random? random]) {
    final r = random ?? Random();
    final free = [for (var i = 0; i < 9; i++) if (cells[i] == -1) i];
    for (final who in [me, 1 - me]) {
      for (final i in free) {
        if (winner([...cells]..[i] = who) != null) return i;
      }
    }
    // A veces se equivoca a propósito para que los chicos puedan ganarle.
    if (r.nextInt(5) == 0) return free[r.nextInt(free.length)];
    if (cells[4] == -1) return 4;
    final corners = [0, 2, 6, 8].where((i) => cells[i] == -1).toList();
    if (corners.isNotEmpty) return corners[r.nextInt(corners.length)];
    return free[r.nextInt(free.length)];
  }
}
