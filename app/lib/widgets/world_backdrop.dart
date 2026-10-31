import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';

/// Fondo con dibujitos del mundo temático elegido (espacio, océano…).
class WorldBackdrop extends StatelessWidget {
  const WorldBackdrop({super.key, required this.world, required this.child});

  final int world;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (world <= 0 || world >= LookOptions.worlds.length) return child;
    final emojis = LookOptions.worlds[world].emojis.characters.toList();
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: Theme.of(context).brightness == Brightness.dark ? .10 : .16,
              child: CustomPaint(painter: _Pattern(emojis)),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _Pattern extends CustomPainter {
  _Pattern(this.emojis);

  final List<String> emojis;

  @override
  void paint(Canvas canvas, Size size) {
    if (emojis.isEmpty) return;
    const step = 84.0;
    var i = 0;
    for (var y = 20.0; y < size.height; y += step) {
      final shift = (y ~/ step).isEven ? 0.0 : step / 2;
      for (var x = 16.0 + shift; x < size.width; x += step) {
        final tp = TextPainter(
          text: TextSpan(text: emojis[i++ % emojis.length], style: const TextStyle(fontSize: 26)),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(((i % 5) - 2) * math.pi / 18);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Pattern old) => old.emojis.join() != emojis.join();
}
