import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/family_store.dart';
import '../models/models.dart';

/// Festejo corto encima de la pantalla: confeti, estrellas, globos…
/// según lo que eligió cada miembro, con una vibración suave.
void celebrate(BuildContext context, {String? text}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final style = FamilyScope.of(context).currentMember?.look.party ?? 0;
  HapticFeedback.mediumImpact();
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _Celebration(style: style, text: text, onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _Celebration extends StatefulWidget {
  const _Celebration({required this.style, required this.onDone, this.text});

  final int style;
  final String? text;
  final VoidCallback onDone;

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  final _random = math.Random();
  late final List<_Piece> _pieces = List.generate(36, (_) => _Piece.random(_random));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emoji = LookOptions.parties[widget.style.clamp(0, LookOptions.parties.length - 1)].emoji;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _PiecesPainter(_pieces, t, widget.style))),
              if (widget.style != 0)
                for (final p in _pieces.take(14))
                  Positioned(
                    left: p.x * MediaQuery.sizeOf(context).width,
                    top: _y(p, t) * MediaQuery.sizeOf(context).height,
                    child: Opacity(
                      opacity: (1 - t).clamp(0, 1),
                      child: Text(emoji, style: TextStyle(fontSize: 18 + p.size * 14)),
                    ),
                  ),
              if (widget.text != null)
                Center(
                  child: Opacity(
                    opacity: t < .15 ? t / .15 : (t > .8 ? (1 - t) / .2 : 1),
                    child: Transform.scale(
                      scale: .8 + .2 * Curves.elasticOut.transform(math.min(1, t * 2)),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black26)],
                          ),
                          child: Text(
                            widget.text!,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Los globos suben; lo demás cae.
  double _y(_Piece p, double t) => widget.style == 2 ? 1.1 - t * (1.2 + p.speed * .4) : -0.1 + t * (1.1 + p.speed * .5);
}

class _Piece {
  _Piece(this.x, this.speed, this.size, this.spin, this.color);

  factory _Piece.random(math.Random r) => _Piece(
        r.nextDouble(),
        r.nextDouble(),
        r.nextDouble(),
        (r.nextDouble() - .5) * 12,
        _colors[r.nextInt(_colors.length)],
      );

  static const _colors = [Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFF22C55E), Color(0xFF3B82F6), Color(0xFFA855F7), Color(0xFFEC4899)];

  final double x;
  final double speed;
  final double size;
  final double spin;
  final Color color;
}

class _PiecesPainter extends CustomPainter {
  _PiecesPainter(this.pieces, this.t, this.style);

  final List<_Piece> pieces;
  final double t;
  final int style;

  @override
  void paint(Canvas canvas, Size size) {
    if (style == 2) return; // los globos van como emoji
    final paint = Paint();
    for (final p in pieces) {
      final y = (-0.1 + t * (1.1 + p.speed * .5)) * size.height;
      final x = p.x * size.width + math.sin(t * 6 + p.spin) * 18;
      paint.color = p.color.withValues(alpha: (1 - t * .8).clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.spin);
      if (style == 4) {
        // Fuegos artificiales: chispas que se abren.
        canvas.drawCircle(Offset.zero, 3 + p.size * 3, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 8 + p.size * 6, height: 5 + p.size * 3), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PiecesPainter old) => old.t != t;
}
