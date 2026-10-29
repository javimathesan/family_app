import 'package:flutter/material.dart';

import '../domain/points.dart';

/// Carita del calendario según el cumplimiento del día.
class MoodFace extends StatelessWidget {
  const MoodFace({super.key, required this.mood, this.size = 28});

  final Mood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: mood.label,
      child: CustomPaint(size: Size.square(size), painter: _FacePainter(mood)),
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter(this.mood);
  final Mood mood;

  static const _ink = Color(0xFF1E2235);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24);
    canvas.drawCircle(const Offset(12, 12), 11, Paint()..color = mood.faceColor);
    canvas.drawCircle(
      const Offset(12, 12),
      11,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _ink,
    );
    final eye = Paint()..color = _ink;
    canvas.drawCircle(const Offset(8.5, 9.5), 1.4, eye);
    canvas.drawCircle(const Offset(15.5, 9.5), 1.4, eye);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = _ink;
    final mouth = Path();
    switch (mood) {
      case Mood.veryHappy:
        mouth
          ..moveTo(7, 13.5)
          ..quadraticBezierTo(12, 20, 17, 13.5)
          ..close();
        canvas.drawPath(mouth, Paint()..color = Colors.white);
      case Mood.happy:
        mouth
          ..moveTo(8, 14)
          ..quadraticBezierTo(12, 17.8, 16, 14);
      case Mood.neutral:
        mouth
          ..moveTo(8.5, 15.5)
          ..lineTo(15.5, 15.5);
      case Mood.sad:
        mouth
          ..moveTo(8, 16.5)
          ..quadraticBezierTo(12, 13.8, 16, 16.5);
      case Mood.verySad:
        mouth
          ..moveTo(7.5, 17.5)
          ..quadraticBezierTo(12, 12.5, 16.5, 17.5);
    }
    canvas.drawPath(mouth, line);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FacePainter old) => old.mood != mood;
}
