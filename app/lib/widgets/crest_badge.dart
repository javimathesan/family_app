import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';

/// Dibuja el escudo de la familia.
class CrestBadge extends StatelessWidget {
  const CrestBadge({super.key, required this.crest, this.size = 56});

  final FamilyCrest crest;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CrestPainter(crest),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: crest.shape == 0 ? 0 : size * .04, bottom: crest.shape == 0 ? size * .08 : 0),
            child: Text(crest.emoji, style: TextStyle(fontSize: size * (crest.shape == 2 ? .32 : .42))),
          ),
        ),
      ),
    );
  }
}

class _CrestPainter extends CustomPainter {
  _CrestPainter(this.crest);

  final FamilyCrest crest;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = switch (crest.shape) {
      1 => Path()..addOval(Rect.fromLTWH(0, 0, w, h)),
      2 => _star(w, h),
      3 => Path()
        ..moveTo(w / 2, h * .95)
        ..cubicTo(-w * .2, h * .45, w * .2, -h * .1, w / 2, h * .25)
        ..cubicTo(w * .8, -h * .1, w * 1.2, h * .45, w / 2, h * .95)
        ..close(),
      _ => Path()
        ..moveTo(w * .08, h * .06)
        ..lineTo(w * .92, h * .06)
        ..lineTo(w * .92, h * .5)
        ..quadraticBezierTo(w * .9, h * .85, w / 2, h * .98)
        ..quadraticBezierTo(w * .1, h * .85, w * .08, h * .5)
        ..close(),
    };
    final color = Color(crest.color);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .06
        ..color = const Color(0xFFF5B800),
    );
  }

  Path _star(double w, double h) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final r = (i.isEven ? .5 : .28) * w;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(w / 2 + r * math.cos(a), h / 2 + r * math.sin(a) + h * .04);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    return p..close();
  }

  @override
  bool shouldRepaint(covariant _CrestPainter old) => old.crest != crest;
}
