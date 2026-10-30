import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../games/barrio.dart';
import '../../games/chess.dart';
import '../../games/cuatro.dart';
import '../../games/ludo.dart';

/// Colores de las fichas de cada jugador en tres en raya y 4 en línea.
const twoPlayerColors = [Color(0xFFE53935), Color(0xFFF9A825)];

/// Colores del ludo: rojo, verde, amarillo y azul.
const ludoColors = [Color(0xFFE53935), Color(0xFF43A047), Color(0xFFF9A825), Color(0xFF1E88E5)];
const ludoColorNames = ['rojo', 'verde', 'amarillo', 'azul'];

// ------------------------------------------------------------- tres en raya

class TatetiBoard extends StatelessWidget {
  const TatetiBoard({super.key, required this.cells, required this.enabled, required this.onTap, this.winLine});

  final List<int> cells;
  final bool enabled;
  final ValueChanged<int> onTap;
  final List<int>? winLine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < 9; i++)
            Material(
              color: winLine?.contains(i) ?? false ? scheme.primaryContainer : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                key: ValueKey('tateti_$i'),
                borderRadius: BorderRadius.circular(16),
                onTap: enabled && cells[i] == -1 ? () => onTap(i) : null,
                child: Center(
                  child: cells[i] == -1
                      ? null
                      : Text(
                          cells[i] == 0 ? 'X' : 'O',
                          style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: twoPlayerColors[cells[i]]),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- 4 en línea

class CuatroBoard extends StatelessWidget {
  const CuatroBoard({super.key, required this.cells, required this.enabled, required this.onDrop, this.winLine});

  final List<int> cells;
  final bool enabled;
  final ValueChanged<int> onDrop;
  final List<int>? winLine;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: Cuatro.cols / Cuatro.rows,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            for (var c = 0; c < Cuatro.cols; c++)
              Expanded(
                child: GestureDetector(
                  key: ValueKey('cuatro_$c'),
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled && Cuatro.dropRow(cells, c) >= 0 ? () => onDrop(c) : null,
                  child: Column(
                    children: [
                      for (var r = 0; r < Cuatro.rows; r++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cells[r * Cuatro.cols + c] == -1 ? Colors.white : twoPlayerColors[cells[r * Cuatro.cols + c]],
                                border: winLine?.contains(r * Cuatro.cols + c) ?? false
                                    ? Border.all(color: Colors.white, width: 4)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------- ludo

/// Coordenadas (columna, fila) del tablero de 15 × 15.
class LudoGeometry {
  /// Las 52 casillas del recorrido común, empezando en la salida del rojo.
  static final List<(int, int)> track = () {
    final t = <(int, int)>[];
    for (var c = 1; c <= 5; c++) {
      t.add((c, 6));
    }
    for (var r = 5; r >= 0; r--) {
      t.add((6, r));
    }
    t.add((7, 0));
    for (var r = 0; r <= 5; r++) {
      t.add((8, r));
    }
    for (var c = 9; c <= 14; c++) {
      t.add((c, 6));
    }
    t.add((14, 7));
    for (var c = 14; c >= 9; c--) {
      t.add((c, 8));
    }
    for (var r = 9; r <= 14; r++) {
      t.add((8, r));
    }
    t.add((7, 14));
    for (var r = 14; r >= 9; r--) {
      t.add((6, r));
    }
    for (var c = 5; c >= 0; c--) {
      t.add((c, 8));
    }
    t.add((0, 7));
    t.add((0, 6));
    return t;
  }();

  /// Pasillo de cada color (5 casillas hacia el centro).
  static (int, int) homeLane(int seat, int step) => switch (seat) {
        0 => (1 + step, 7),
        1 => (7, 1 + step),
        2 => (13 - step, 7),
        _ => (7, 13 - step),
      };

  /// Esquina superior izquierda de la base de cada color.
  static (int, int) baseOrigin(int seat) => switch (seat) {
        0 => (0, 0),
        1 => (9, 0),
        2 => (9, 9),
        _ => (0, 9),
      };

  /// Centro (en casillas, con decimales) de una ficha.
  static Offset tokenCenter(int seat, int token, int progress) {
    if (progress < 0) {
      final (bx, by) = baseOrigin(seat);
      final dx = token.isEven ? 2.0 : 4.0;
      final dy = token < 2 ? 2.0 : 4.0;
      return Offset(bx + dx, by + dy);
    }
    if (progress <= Ludo.lastTrack) {
      final (c, r) = track[Ludo.absolute(seat, progress)!];
      return Offset(c + .5, r + .5);
    }
    if (progress < Ludo.goal) {
      final (c, r) = homeLane(seat, progress - Ludo.lastTrack - 1);
      return Offset(c + .5, r + .5);
    }
    const goals = [Offset(6.9, 7.5), Offset(7.5, 6.9), Offset(8.1, 7.5), Offset(7.5, 8.1)];
    return goals[seat];
  }
}

class LudoBoard extends StatelessWidget {
  const LudoBoard({super.key, required this.state, required this.movable, required this.activePlayer, required this.onToken});

  final LudoState state;

  /// Fichas que se pueden tocar ahora (del jugador [activePlayer]).
  final List<int> movable;
  final int activePlayer;
  final ValueChanged<int> onToken;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, box) {
          final cell = box.maxWidth / 15;
          final tokens = <Widget>[];
          for (var p = 0; p < state.tokens.length; p++) {
            final seat = state.seats[p];
            // Fichas en la misma casilla se corren un poco para que se vean.
            for (var i = 0; i < 4; i++) {
              final progress = state.tokens[p][i];
              var center = LudoGeometry.tokenCenter(seat, i, progress);
              if (progress >= 0 && progress < Ludo.goal) {
                final same = [for (var j = 0; j < i; j++) if (state.tokens[p][j] == progress) j].length;
                center += Offset(same * .18, -same * .18);
              }
              final canTap = p == activePlayer && movable.contains(i);
              final size = cell * .8;
              tokens.add(Positioned(
                left: center.dx * cell - size / 2,
                top: center.dy * cell - size / 2,
                width: size,
                height: size,
                child: GestureDetector(
                  key: ValueKey('ludo_${p}_$i'),
                  onTap: canTap ? () => onToken(i) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: ludoColors[seat],
                      shape: BoxShape.circle,
                      border: Border.all(color: canTap ? Colors.black : Colors.white, width: canTap ? 3 : 2),
                      boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black38, offset: Offset(0, 1))],
                    ),
                  ),
                ),
              ));
            }
          }
          return Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _LudoPainter())),
            ...tokens,
          ]);
        },
      ),
    );
  }
}

class _LudoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;
    final fill = Paint();
    final line = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    Rect sq(int c, int r) => Rect.fromLTWH(c * cell, r * cell, cell, cell);

    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(cell * .4)), fill..color = Colors.white);

    // Bases.
    for (var seat = 0; seat < 4; seat++) {
      final (bx, by) = LudoGeometry.baseOrigin(seat);
      final base = Rect.fromLTWH(bx * cell, by * cell, 6 * cell, 6 * cell);
      canvas.drawRect(base, fill..color = ludoColors[seat]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(base.deflate(cell * .8), Radius.circular(cell * .5)),
        fill..color = Colors.white,
      );
      for (var i = 0; i < 4; i++) {
        final c = LudoGeometry.tokenCenter(seat, i, -1);
        canvas.drawCircle(c * cell, cell * .45, fill..color = ludoColors[seat].withValues(alpha: .25));
      }
    }

    // Recorrido.
    for (var i = 0; i < LudoGeometry.track.length; i++) {
      final (c, r) = LudoGeometry.track[i];
      final seatStart = i % 13 == 0 ? i ~/ 13 : null;
      canvas.drawRect(sq(c, r), fill..color = seatStart != null ? ludoColors[seatStart] : Colors.white);
      canvas.drawRect(sq(c, r), line);
      if (Ludo.safeSquares.contains(i) && seatStart == null) {
        _star(canvas, sq(c, r).center, cell * .32, fill..color = Colors.black38);
      }
    }

    // Pasillos.
    for (var seat = 0; seat < 4; seat++) {
      for (var k = 0; k < 5; k++) {
        final (c, r) = LudoGeometry.homeLane(seat, k);
        canvas.drawRect(sq(c, r), fill..color = ludoColors[seat].withValues(alpha: .7));
        canvas.drawRect(sq(c, r), line);
      }
    }

    // Meta: cuatro triángulos en el centro.
    final center = Offset(7.5 * cell, 7.5 * cell);
    final corners = [
      Offset(6 * cell, 6 * cell),
      Offset(9 * cell, 6 * cell),
      Offset(9 * cell, 9 * cell),
      Offset(6 * cell, 9 * cell),
    ];
    // Cada color entra por su lado: rojo izquierda, verde arriba, amarillo derecha, azul abajo.
    const sides = [(3, 0), (0, 1), (1, 2), (2, 3)];
    for (var seat = 0; seat < 4; seat++) {
      final (a, b) = sides[seat];
      final path = Path()
        ..moveTo(corners[a].dx, corners[a].dy)
        ..lineTo(corners[b].dx, corners[b].dy)
        ..lineTo(center.dx, center.dy)
        ..close();
      canvas.drawPath(path, fill..color = ludoColors[seat]);
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * .45;
      final angle = -1.5708 + i * 0.6283;
      final p = c + Offset(radius * math.cos(angle), radius * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dado con puntos.
class DiceFace extends StatelessWidget {
  const DiceFace({super.key, required this.value, this.size = 56, this.color = Colors.white});

  final int? value;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const spots = {
      1: [(1, 1)],
      2: [(0, 0), (2, 2)],
      3: [(0, 0), (1, 1), (2, 2)],
      4: [(0, 0), (2, 0), (0, 2), (2, 2)],
      5: [(0, 0), (2, 0), (1, 1), (0, 2), (2, 2)],
      6: [(0, 0), (2, 0), (0, 1), (2, 1), (0, 2), (2, 2)],
    };
    final dot = size / 6;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * .2),
        border: Border.all(color: Colors.black26),
        boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black26, offset: Offset(0, 2))],
      ),
      child: value == null
          ? const Center(child: Text('?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)))
          : LayoutBuilder(
              builder: (context, box) => Stack(children: [
                for (final (x, y) in spots[value]!)
                  Positioned(
                    left: x * (box.maxWidth - dot) / 2,
                    top: y * (box.maxHeight - dot) / 2,
                    width: dot,
                    height: dot,
                    child: const DecoratedBox(decoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                  ),
              ]),
            ),
    );
  }
}

// ----------------------------------------------------------------- ajedrez

const _glyphs = {'k': '♚', 'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞', 'p': '♟'};

/// Pieza dibujada con el mismo símbolo relleno para los dos colores.
class ChessPiece extends StatelessWidget {
  const ChessPiece({super.key, required this.piece, required this.size});

  final String piece;
  final double size;

  @override
  Widget build(BuildContext context) {
    final white = Chess.isWhite(piece);
    // ︎ pide el símbolo de texto y no el emoji.
    final glyph = '${_glyphs[piece.toLowerCase()]}︎';
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          glyph,
          style: TextStyle(
            fontSize: size,
            height: 1,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * .08
              ..color = white ? Colors.black87 : Colors.white70,
          ),
        ),
        Text(glyph, style: TextStyle(fontSize: size, height: 1, color: white ? Colors.white : Colors.black87)),
      ],
    );
  }
}

class ChessBoardView extends StatefulWidget {
  const ChessBoardView({super.key, required this.position, required this.enabled, required this.onMove, this.flipped = false});

  final Chess position;
  final bool enabled;
  final bool flipped;
  final ValueChanged<ChessMove> onMove;

  @override
  State<ChessBoardView> createState() => _ChessBoardViewState();
}

class _ChessBoardViewState extends State<ChessBoardView> {
  int? _selected;
  List<ChessMove> _targets = const [];

  @override
  void didUpdateWidget(covariant ChessBoardView old) {
    super.didUpdateWidget(old);
    if (old.position.toJson().toString() != widget.position.toJson().toString()) {
      _selected = null;
      _targets = const [];
    }
  }

  Future<void> _tap(int sq) async {
    if (!widget.enabled) return;
    final pos = widget.position;
    final moves = _targets.where((m) => m.to == sq).toList();
    if (_selected != null && moves.isNotEmpty) {
      var move = moves.first;
      if (moves.length > 1) {
        final promo = await _askPromotion(pos.whiteToMove);
        if (promo == null) return;
        move = moves.firstWhere((m) => m.promo == promo);
      }
      setState(() {
        _selected = null;
        _targets = const [];
      });
      widget.onMove(move);
      return;
    }
    final piece = pos.board[sq];
    if (piece != null && Chess.isWhite(piece) == pos.whiteToMove) {
      setState(() {
        _selected = sq;
        _targets = pos.movesFrom(sq);
      });
    } else {
      setState(() {
        _selected = null;
        _targets = const [];
      });
    }
  }

  Future<String?> _askPromotion(bool white) => showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('¿En qué se convierte el peón?'),
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final p in const ['q', 'r', 'b', 'n'])
                  IconButton(
                    iconSize: 48,
                    onPressed: () => Navigator.pop(ctx, p),
                    icon: ChessPiece(piece: white ? p.toUpperCase() : p, size: 40),
                  ),
              ],
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pos = widget.position;
    final checkSq = pos.inCheck() ? pos.kingSquare(pos.whiteToMove) : null;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFF5D4037), width: 4), borderRadius: BorderRadius.circular(6)),
        child: LayoutBuilder(
          builder: (context, box) {
            final cell = box.maxWidth / 8;
            return GridView.count(
              crossAxisCount: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < 64; i++)
                  Builder(builder: (context) {
                    final sq = widget.flipped ? 63 - i : i;
                    final light = (sq ~/ 8 + sq % 8).isEven;
                    var color = light ? const Color(0xFFF0D9B5) : const Color(0xFFB58863);
                    if (sq == pos.lastFrom || sq == pos.lastTo) color = Color.lerp(color, Colors.yellow, .35)!;
                    if (sq == _selected) color = Color.lerp(color, Colors.green, .45)!;
                    if (sq == checkSq) color = Color.lerp(color, Colors.red, .55)!;
                    final isTarget = _targets.any((m) => m.to == sq);
                    final piece = pos.board[sq];
                    return GestureDetector(
                      key: ValueKey('chess_${Chess.squareName(sq)}'),
                      onTap: () => _tap(sq),
                      child: Container(
                        color: color,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (piece != null) ChessPiece(piece: piece, size: cell * .78),
                            if (isTarget)
                              Container(
                                width: piece == null ? cell * .3 : cell * .9,
                                height: piece == null ? cell * .3 : cell * .9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: piece == null ? Colors.black26 : null,
                                  border: piece == null ? null : Border.all(color: Colors.black38, width: 3),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Mi Barrio

/// Colores de los grupos de lugares.
const barrioGroupColors = [Color(0xFF8D6E63), Color(0xFF26C6DA), Color(0xFFEC407A), Color(0xFFFFA726), Color(0xFF7E57C2)];

/// Posición (columna, fila) de cada casilla en el borde de una grilla de 6 × 6:
/// la Salida abajo a la derecha y se avanza hacia la izquierda.
(int, int) barrioCell(int index) {
  if (index <= 5) return (5 - index, 5);
  if (index <= 10) return (0, 10 - index);
  if (index <= 15) return (index - 10, 0);
  return (5, index - 15);
}

class BarrioBoard extends StatelessWidget {
  const BarrioBoard({super.key, required this.state, required this.center, required this.playerColors});

  final BarrioState state;
  final Widget center;
  final List<Color> playerColors;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, box) {
        final cell = box.maxWidth / 6;
        return Stack(
          children: [
            Positioned(
              left: cell,
              top: cell,
              width: cell * 4,
              height: cell * 4,
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(8),
                child: center,
              ),
            ),
            for (var i = 0; i < Barrio.squares.length; i++)
              Builder(builder: (context) {
                final (c, r) = barrioCell(i);
                final square = Barrio.squares[i];
                final owner = state.owners[i];
                final here = [for (var p = 0; p < state.players; p++) if (!state.out[p] && state.pos[p] == i) p];
                return Positioned(
                  left: c * cell,
                  top: r * cell,
                  width: cell,
                  height: cell,
                  child: Container(
                    key: ValueKey('barrio_$i'),
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: owner >= 0 ? playerColors[owner] : Colors.black12, width: owner >= 0 ? 3 : 1),
                    ),
                    child: Column(
                      children: [
                        if (square.group >= 0)
                          Container(height: cell * .1, color: barrioGroupColors[square.group]),
                        Expanded(
                          child: FittedBox(
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(square.emoji, style: const TextStyle(fontSize: 18)),
                                  Text(square.name.split(' ').first, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                                  if (square.price > 0) Text('${square.price}', style: const TextStyle(fontSize: 9, color: Colors.black54)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (here.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final p in here)
                                  Container(
                                    width: cell * .18,
                                    height: cell * .18,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: playerColors[p],
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      }),
    );
  }
}
