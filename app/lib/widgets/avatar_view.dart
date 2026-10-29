import 'package:flutter/material.dart';

import '../models/models.dart';

/// Opciones del avatar. Los índices de [AvatarConfig] apuntan a estas listas.
abstract final class AvatarOptions {
  static const skins = <(String, Color)>[
    ('Piel muy clara', Color(0xFFFCE3D0)),
    ('Piel clara', Color(0xFFF2C9A5)),
    ('Piel media', Color(0xFFE0A97E)),
    ('Piel trigueña', Color(0xFFC98E62)),
    ('Piel morena', Color(0xFF9C6440)),
    ('Piel oscura', Color(0xFF6B4128)),
  ];
  static const hairStyles = ['Corto', 'Flequillo', 'Largo', 'Rulos', 'Rapado'];
  static const hairColors = <(String, Color)>[
    ('Negro', Color(0xFF1E1E1E)),
    ('Castaño oscuro', Color(0xFF4A3426)),
    ('Castaño claro', Color(0xFF8A5A35)),
    ('Rubio', Color(0xFFD9A93F)),
    ('Pelirrojo', Color(0xFFB4471F)),
    ('Azul fantasía', Color(0xFF3B6FD8)),
  ];
  static const eyes = ['Redondos', 'Felices', 'Dormilones'];
  static const shirts = <(String, Color)>[
    ('Azul', Color(0xFF2563EB)),
    ('Verde agua', Color(0xFF0F766E)),
    ('Violeta', Color(0xFF7C3AED)),
    ('Naranja', Color(0xFFEA7A2B)),
    ('Rosa', Color(0xFFDB2777)),
    ('Gris', Color(0xFF5B6178)),
  ];

  /// Accesorios: nombre y puntos necesarios para desbloquearlo (0 = libre).
  static const accessories = <(String, int)>[
    ('Ninguno', 0),
    ('Gorra', 0),
    ('Vincha', 0),
    ('Auriculares', 0),
    ('Corona', 120),
  ];
}

/// Avatar estilo Funko: cabeza grande, cuerpo chico, ojos negros grandes.
class AvatarView extends StatelessWidget {
  const AvatarView({super.key, required this.config, this.size = 56, this.background});

  final AvatarConfig config;
  final double size;
  final Color? background;

  /// Versión de cuerpo entero para el editor.
  const AvatarView.full({super.key, required this.config, this.size = 240})
      : background = null;

  @override
  Widget build(BuildContext context) {
    final painter = _FunkoPainter(config, headOnly: background != null);
    final drawing = CustomPaint(size: Size.square(size), painter: painter);
    return Semantics(
      label: 'Avatar',
      image: true,
      child: background == null
          ? drawing
          : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: background, shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: drawing,
            ),
    );
  }
}

class _FunkoPainter extends CustomPainter {
  _FunkoPainter(this.c, {required this.headOnly});

  final AvatarConfig c;
  final bool headOnly;

  static const _ink = Color(0xFF1E2235);

  @override
  void paint(Canvas canvas, Size size) {
    // Lienzo de referencia 300 x 252 (igual que el diseño), escalado al tamaño.
    canvas.save();
    if (headOnly) {
      final s = size.width / 190;
      canvas.scale(s);
      canvas.translate(-55, -10);
    } else {
      final s = size.width / 300;
      canvas.scale(s);
    }

    final skin = AvatarOptions.skins[c.skin].$2;
    final hair = AvatarOptions.hairColors[c.hairColor].$2;
    final shirt = AvatarOptions.shirts[c.shirt].$2;
    final fill = Paint()..style = PaintingStyle.fill;

    // Pelo largo: va detrás de la cabeza.
    if (c.hairStyle == 2) {
      canvas.drawPath(
        Path()
          ..moveTo(64, 204)
          ..quadraticBezierTo(50, 28, 150, 24)
          ..quadraticBezierTo(250, 28, 236, 204)
          ..close(),
        fill..color = hair,
      );
    }

    // Cuerpo.
    final legs = Paint()..color = const Color(0xFF3B3F55);
    canvas.drawRRect(RRect.fromLTRBR(126, 214, 146, 236, const Radius.circular(8)), legs);
    canvas.drawRRect(RRect.fromLTRBR(154, 214, 174, 236, const Radius.circular(8)), legs);
    canvas.drawRRect(RRect.fromLTRBR(104, 174, 122, 214, const Radius.circular(9)), fill..color = skin);
    canvas.drawRRect(RRect.fromLTRBR(178, 174, 196, 214, const Radius.circular(9)), fill..color = skin);
    canvas.drawRRect(RRect.fromLTRBR(116, 166, 184, 222, const Radius.circular(18)), fill..color = shirt);

    // Cabeza y orejas.
    canvas.drawCircle(const Offset(74, 112), 13, fill..color = skin);
    canvas.drawCircle(const Offset(226, 112), 13, fill..color = skin);
    canvas.drawRRect(RRect.fromLTRBR(75, 36, 225, 174, const Radius.circular(62)), fill..color = skin);

    // Cachetes.
    final blush = Paint()..color = const Color(0xFFF28AA5).withValues(alpha: 0.45);
    canvas.drawCircle(const Offset(106, 138), 9, blush);
    canvas.drawCircle(const Offset(194, 138), 9, blush);

    _eyes(canvas);

    // Boca.
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = _ink
      ..strokeWidth = 4;
    canvas.drawPath(Path()..moveTo(140, 142)..quadraticBezierTo(150, 150, 160, 142), stroke);

    _hairFront(canvas, hair);

    if (c.glasses) {
      final g = Paint()
        ..style = PaintingStyle.stroke
        ..color = _ink
        ..strokeWidth = 4;
      canvas.drawCircle(const Offset(125, 112), 22, g);
      canvas.drawCircle(const Offset(175, 112), 22, g);
      canvas.drawLine(const Offset(147, 110), const Offset(153, 110), g);
    }

    _accessory(canvas);
    canvas.restore();
  }

  void _eyes(Canvas canvas) {
    final dark = Paint()..color = _ink;
    if (c.eyes == 0) {
      canvas.drawCircle(const Offset(125, 112), 14, dark);
      canvas.drawCircle(const Offset(175, 112), 14, dark);
      final glint = Paint()..color = Colors.white;
      canvas.drawCircle(const Offset(130, 106), 4.5, glint);
      canvas.drawCircle(const Offset(180, 106), 4.5, glint);
      return;
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6
      ..color = _ink;
    final happy = c.eyes == 1;
    for (final x in [125.0, 175.0]) {
      final path = Path()..moveTo(x - 14, happy ? 116 : 110);
      path.quadraticBezierTo(x, happy ? 98 : 124, x + 14, happy ? 116 : 110);
      canvas.drawPath(path, line);
    }
  }

  void _hairFront(Canvas canvas, Color color) {
    final paint = Paint()..color = color;
    final p = Path();
    switch (c.hairStyle) {
      case 1: // flequillo
        p
          ..moveTo(70, 112)
          ..quadraticBezierTo(66, 26, 150, 26)
          ..quadraticBezierTo(234, 26, 230, 112)
          ..quadraticBezierTo(222, 74, 196, 62)
          ..quadraticBezierTo(170, 84, 128, 78)
          ..quadraticBezierTo(96, 74, 78, 104)
          ..close();
      case 3: // rulos
        p
          ..moveTo(70, 110)
          ..quadraticBezierTo(58, 84, 74, 70)
          ..quadraticBezierTo(66, 44, 94, 40)
          ..quadraticBezierTo(102, 20, 128, 28)
          ..quadraticBezierTo(150, 12, 172, 28)
          ..quadraticBezierTo(198, 20, 206, 40)
          ..quadraticBezierTo(234, 44, 226, 70)
          ..quadraticBezierTo(242, 84, 230, 110)
          ..quadraticBezierTo(220, 76, 150, 70)
          ..quadraticBezierTo(80, 76, 70, 110)
          ..close();
      case 4: // rapado
        p
          ..moveTo(78, 92)
          ..quadraticBezierTo(82, 40, 150, 38)
          ..quadraticBezierTo(218, 40, 222, 92)
          ..quadraticBezierTo(200, 64, 150, 62)
          ..quadraticBezierTo(100, 64, 78, 92)
          ..close();
      default: // corto y la parte de arriba del largo
        p
          ..moveTo(72, 104)
          ..quadraticBezierTo(70, 30, 150, 28)
          ..quadraticBezierTo(230, 30, 228, 104)
          ..quadraticBezierTo(214, 66, 150, 64)
          ..quadraticBezierTo(86, 66, 72, 104)
          ..close();
    }
    canvas.drawPath(p, paint);
  }

  void _accessory(Canvas canvas) {
    switch (c.accessory) {
      case 1: // gorra
        canvas.drawPath(
          Path()
            ..moveTo(70, 86)
            ..quadraticBezierTo(72, 20, 150, 20)
            ..quadraticBezierTo(228, 20, 230, 86)
            ..close(),
          Paint()..color = const Color(0xFFDC2626),
        );
        canvas.drawRRect(
          RRect.fromLTRBR(64, 78, 236, 92, const Radius.circular(7)),
          Paint()..color = const Color(0xFF991B1B),
        );
      case 2: // vincha
        canvas.drawPath(
          Path()
            ..moveTo(78, 88)
            ..quadraticBezierTo(86, 38, 150, 36)
            ..quadraticBezierTo(214, 38, 222, 88),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 11
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFEC4899),
        );
      case 3: // auriculares
        canvas.drawPath(
          Path()
            ..moveTo(66, 112)
            ..quadraticBezierTo(66, 16, 150, 16)
            ..quadraticBezierTo(234, 16, 234, 112),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9
            ..strokeCap = StrokeCap.round
            ..color = _ink,
        );
        final cup = Paint()..color = const Color(0xFF2563EB);
        canvas.drawRRect(RRect.fromLTRBR(54, 94, 78, 134, const Radius.circular(11)), cup);
        canvas.drawRRect(RRect.fromLTRBR(222, 94, 246, 134, const Radius.circular(11)), cup);
      case 4: // corona
        canvas.drawPath(
          Path()
            ..moveTo(102, 42)
            ..lineTo(112, 10)
            ..lineTo(130, 30)
            ..lineTo(150, 4)
            ..lineTo(170, 30)
            ..lineTo(188, 10)
            ..lineTo(198, 42)
            ..close(),
          Paint()..color = const Color(0xFFF5B800),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _FunkoPainter old) => old.c != c || old.headOnly != headOnly;
}
