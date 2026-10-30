import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';

/// Disfraz o accesorio de la tienda del avatar.
@immutable
class AvatarItem {
  const AvatarItem(this.id, this.label, this.cost);

  /// Identificador estable (se guarda en `Member.unlocked`).
  final String id;
  final String label;

  /// Puntos para desbloquearlo. 0 = libre.
  final int cost;

  bool get free => cost == 0;
}

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
  static const hairStyles = ['Corto', 'Flequillo', 'Largo', 'Rulos', 'Rapado', 'Puntiagudo', 'Coletas', 'Rodete'];
  static const hairColors = <(String, Color)>[
    ('Negro', Color(0xFF1E1E1E)),
    ('Castaño oscuro', Color(0xFF4A3426)),
    ('Castaño claro', Color(0xFF8A5A35)),
    ('Rubio', Color(0xFFD9A93F)),
    ('Pelirrojo', Color(0xFFB4471F)),
    ('Azul fantasía', Color(0xFF3B6FD8)),
    ('Rosa fantasía', Color(0xFFE5579B)),
  ];
  static const eyes = ['Redondos', 'Felices', 'Dormilones', 'Brillantes'];

  /// Color principal de la ropa o del disfraz.
  static const shirts = <(String, Color)>[
    ('Azul', Color(0xFF2563EB)),
    ('Verde agua', Color(0xFF0F766E)),
    ('Violeta', Color(0xFF7C3AED)),
    ('Naranja', Color(0xFFEA7A2B)),
    ('Rosa', Color(0xFFDB2777)),
    ('Rojo', Color(0xFFDC2626)),
    ('Gris', Color(0xFF5B6178)),
  ];

  /// Disfraces originales, inspirados en lo que les gusta a los chicos.
  /// No usan personajes con marca registrada.
  static const outfits = <AvatarItem>[
    AvatarItem('outfit_remera', 'Remera', 0),
    AvatarItem('outfit_heroe', 'Superhéroe', 80),
    AvatarItem('outfit_princesa', 'Princesa', 80),
    AvatarItem('outfit_ninja', 'Ninja', 100),
    AvatarItem('outfit_astronauta', 'Astronauta', 120),
    AvatarItem('outfit_pirata', 'Pirata', 100),
    AvatarItem('outfit_dino', 'Dinosaurio', 150),
    AvatarItem('outfit_unicornio', 'Unicornio', 150),
    AvatarItem('outfit_escolar', 'Uniforme anime', 120),
  ];

  static const accessories = <AvatarItem>[
    AvatarItem('acc_ninguno', 'Ninguno', 0),
    AvatarItem('acc_gorra', 'Gorra', 0),
    AvatarItem('acc_vincha', 'Vincha', 0),
    AvatarItem('acc_auriculares', 'Auriculares', 0),
    AvatarItem('acc_corona', 'Corona', 120),
  ];

  /// Disfraces que ya cubren la cabeza: no se dibuja accesorio encima.
  static bool outfitCoversHead(int outfit) => outfit >= 2 && outfit <= 7;
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

// Índices de disfraz.
const _remera = 0;
const _heroe = 1;
const _princesa = 2;
const _ninja = 3;
const _astronauta = 4;
const _pirata = 5;
const _dino = 6;
const _unicornio = 7;
const _escolar = 8;

class _FunkoPainter extends CustomPainter {
  _FunkoPainter(this.c, {required this.headOnly});

  final AvatarConfig c;
  final bool headOnly;

  static const _ink = Color(0xFF1E2235);

  static Color _shade(Color color, double amount) => Color.lerp(color, Colors.black, amount)!;
  static Color _tint(Color color, double amount) => Color.lerp(color, Colors.white, amount)!;

  static Paint _fill(Color color) => Paint()..color = color;
  static Paint _line(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = color;

  /// Rellena y contornea una forma.
  static void _shape(Canvas canvas, Path path, Color color, {double outline = 3}) {
    canvas.drawPath(path, _fill(color));
    if (outline > 0) canvas.drawPath(path, _line(_shade(color, 0.35), outline));
  }

  static Path _rrect(double l, double t, double r, double b, double radius) =>
      Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)));

  int get _outfit => c.outfit.clamp(0, AvatarOptions.outfits.length - 1);
  bool get _hood => _outfit == _ninja || _outfit == _dino || _outfit == _unicornio;

  @override
  void paint(Canvas canvas, Size size) {
    // Lienzo de referencia 300 x 252, escalado al tamaño pedido.
    canvas.save();
    if (headOnly) {
      final s = size.width / 190;
      canvas.scale(s);
      canvas.translate(-55, -10);
    } else {
      canvas.scale(size.width / 300);
    }

    final skin = AvatarOptions.skins[c.skin.clamp(0, AvatarOptions.skins.length - 1)].$2;
    final hair = AvatarOptions.hairColors[c.hairColor.clamp(0, AvatarOptions.hairColors.length - 1)].$2;
    final main = AvatarOptions.shirts[c.shirt.clamp(0, AvatarOptions.shirts.length - 1)].$2;

    if (_outfit == _heroe) _cape(canvas, main);
    if (!_hood) _hairBack(canvas, hair);
    _legs(canvas, main);
    _arms(canvas, skin, main);
    _body(canvas, main);
    _head(canvas, skin);
    if (_outfit == _heroe) _heroMask(canvas, main);
    _eyes(canvas);
    _mouth(canvas);
    if (_outfit == _ninja) _ninjaMask(canvas);
    if (_hood) {
      _hoodFor(canvas, main);
    } else {
      _hairFront(canvas, hair);
    }
    if (c.glasses && _outfit != _ninja) _glasses(canvas);
    switch (_outfit) {
      case _princesa:
        _crown(canvas, small: true);
      case _pirata:
        _pirateHat(canvas);
        _eyePatch(canvas);
      case _astronauta:
        _helmet(canvas);
    }
    if (!AvatarOptions.outfitCoversHead(_outfit)) _accessory(canvas);
    canvas.restore();
  }

  // ------------------------------------------------------------- cuerpo

  void _cape(Canvas canvas, Color main) {
    final cape = Path()
      ..moveTo(118, 168)
      ..lineTo(92, 242)
      ..quadraticBezierTo(150, 252, 208, 242)
      ..lineTo(182, 168)
      ..close();
    _shape(canvas, cape, _shade(main, 0.3));
  }

  void _legs(Canvas canvas, Color main) {
    final pants = switch (_outfit) {
      _ninja => const Color(0xFF2B2D42),
      _astronauta => const Color(0xFFE2E8F0),
      _dino => const Color(0xFF16A34A),
      _unicornio => const Color(0xFFF9A8D4),
      _escolar => const Color(0xFF1E3A8A),
      _heroe => main,
      _ => const Color(0xFF3B3F55),
    };
    _shape(canvas, _rrect(127, 210, 147, 234, 8), pants, outline: 2);
    _shape(canvas, _rrect(153, 210, 173, 234, 8), pants, outline: 2);
    final shoe = _outfit == _heroe ? _shade(main, 0.3) : const Color(0xFF1E2235);
    _shape(canvas, _rrect(121, 228, 149, 241, 7), shoe, outline: 0);
    _shape(canvas, _rrect(151, 228, 179, 241, 7), shoe, outline: 0);
  }

  void _arms(Canvas canvas, Color skin, Color main) {
    final sleeve = switch (_outfit) {
      _remera => main,
      _princesa => _tint(main, 0.35),
      _ninja => const Color(0xFF2B2D42),
      _astronauta => const Color(0xFFF1F5F9),
      _pirata => const Color(0xFFF8FAFC),
      _dino => const Color(0xFF22C55E),
      _unicornio => const Color(0xFFFBCFE8),
      _escolar => const Color(0xFFF8FAFC),
      _ => main,
    };
    final longSleeve = _outfit != _remera && _outfit != _princesa;
    for (final x in [104.0, 178.0]) {
      _shape(canvas, _rrect(x, 170, x + 18, 210, 9), longSleeve ? sleeve : skin, outline: 2);
      if (!longSleeve) _shape(canvas, _rrect(x, 168, x + 18, 186, 8), sleeve, outline: 2);
      final hand = _outfit == _astronauta ? const Color(0xFFCBD5E1) : skin;
      canvas.drawCircle(Offset(x + 9, 212), 9, _fill(hand));
      canvas.drawCircle(Offset(x + 9, 212), 9, _line(_shade(hand, 0.3), 2));
    }
    if (_outfit == _princesa) {
      // Mangas abullonadas.
      for (final x in [113.0, 187.0]) {
        canvas.drawCircle(Offset(x, 174), 11, _fill(_tint(main, 0.35)));
        canvas.drawCircle(Offset(x, 174), 11, _line(_shade(main, 0.2), 2));
      }
    }
  }

  void _body(Canvas canvas, Color main) {
    final torso = _rrect(116, 164, 184, 222, 18);
    switch (_outfit) {
      case _heroe:
        _shape(canvas, torso, main);
        _star(canvas, const Offset(150, 188), 12, const Color(0xFFFACC15));
        canvas.drawRect(const Rect.fromLTRB(117, 205, 183, 212), _fill(const Color(0xFFFACC15)));
      case _princesa:
        final dress = Path()
          ..moveTo(126, 164)
          ..lineTo(174, 164)
          ..lineTo(206, 236)
          ..quadraticBezierTo(150, 248, 94, 236)
          ..close();
        _shape(canvas, dress, main);
        canvas.drawRect(const Rect.fromLTRB(128, 186, 172, 192), _fill(_tint(main, 0.55)));
        for (final x in [120.0, 150.0, 180.0]) {
          canvas.drawCircle(Offset(x, 226), 3, _fill(_tint(main, 0.7)));
        }
      case _ninja:
        _shape(canvas, torso, const Color(0xFF2B2D42));
        canvas.drawRect(const Rect.fromLTRB(117, 200, 183, 207), _fill(main));
      case _astronauta:
        _shape(canvas, torso, const Color(0xFFF1F5F9));
        canvas.drawCircle(const Offset(150, 186), 9, _fill(main));
        canvas.drawRect(const Rect.fromLTRB(162, 200, 176, 206), _fill(const Color(0xFFDC2626)));
      case _pirata:
        _shape(canvas, torso, const Color(0xFFF8FAFC));
        for (final y in [174.0, 188.0, 202.0]) {
          canvas.drawRect(Rect.fromLTRB(118, y, 182, y + 6), _fill(main));
        }
        _shape(canvas, _rrect(116, 164, 132, 222, 10), const Color(0xFF5B3A1E), outline: 2);
        _shape(canvas, _rrect(168, 164, 184, 222, 10), const Color(0xFF5B3A1E), outline: 2);
      case _dino:
        _shape(canvas, torso, const Color(0xFF22C55E));
        canvas.drawOval(const Rect.fromLTRB(130, 174, 170, 218), _fill(const Color(0xFFBBF7D0)));
      case _unicornio:
        _shape(canvas, torso, const Color(0xFFFBCFE8));
        _star(canvas, const Offset(150, 192), 9, main);
      case _escolar:
        _shape(canvas, torso, const Color(0xFFF8FAFC));
        final collar = Path()
          ..moveTo(116, 166)
          ..lineTo(184, 166)
          ..lineTo(176, 192)
          ..lineTo(150, 178)
          ..lineTo(124, 192)
          ..close();
        _shape(canvas, collar, const Color(0xFF1E3A8A), outline: 2);
        final bow = Path()
          ..moveTo(150, 186)
          ..lineTo(136, 178)
          ..lineTo(136, 194)
          ..close()
          ..moveTo(150, 186)
          ..lineTo(164, 178)
          ..lineTo(164, 194)
          ..close();
        canvas.drawPath(bow, _fill(main));
      default:
        _shape(canvas, torso, main);
    }
  }

  // ------------------------------------------------------------- cabeza

  void _head(Canvas canvas, Color skin) {
    final line = _shade(skin, 0.28);
    for (final x in [74.0, 226.0]) {
      canvas.drawCircle(Offset(x, 112), 13, _fill(skin));
      canvas.drawCircle(Offset(x, 112), 13, _line(line, 3));
      canvas.drawCircle(Offset(x, 112), 6, _fill(_shade(skin, 0.12)));
    }
    final head = RRect.fromLTRBR(75, 36, 225, 174, const Radius.circular(62));
    canvas.drawRRect(head, _fill(skin));
    canvas.drawRRect(head, _line(line, 3));
    // Brillo suave arriba a la izquierda.
    canvas.drawOval(const Rect.fromLTWH(96, 54, 56, 30), _fill(Colors.white.withValues(alpha: 0.10)));
    // Cachetes.
    final blush = _fill(const Color(0xFFF28AA5).withValues(alpha: 0.45));
    canvas.drawCircle(const Offset(106, 140), 9, blush);
    canvas.drawCircle(const Offset(194, 140), 9, blush);
  }

  void _eyes(Canvas canvas) {
    final dark = _fill(_ink);
    final glint = _fill(Colors.white);
    switch (c.eyes) {
      case 1 || 2:
        final happy = c.eyes == 1;
        final line = _line(_ink, 6);
        for (final x in [125.0, 175.0]) {
          final path = Path()..moveTo(x - 14, happy ? 116 : 110);
          path.quadraticBezierTo(x, happy ? 98 : 124, x + 14, happy ? 116 : 110);
          canvas.drawPath(path, line);
        }
      case 3:
        for (final x in [125.0, 175.0]) {
          canvas.drawOval(Rect.fromCenter(center: Offset(x, 114), width: 28, height: 36), dark);
          canvas.drawOval(Rect.fromCenter(center: Offset(x, 121), width: 20, height: 20), _fill(const Color(0xFF4F7BD9)));
          canvas.drawCircle(Offset(x + 5, 104), 5, glint);
          canvas.drawCircle(Offset(x - 5, 125), 2.5, glint);
          canvas.drawLine(Offset(x - 14, 98), Offset(x - 19, 92), _line(_ink, 3));
          canvas.drawLine(Offset(x + 14, 98), Offset(x + 19, 92), _line(_ink, 3));
        }
      default:
        for (final x in [125.0, 175.0]) {
          canvas.drawCircle(Offset(x, 112), 14, dark);
          canvas.drawCircle(Offset(x + 5, 106), 4.5, glint);
          canvas.drawCircle(Offset(x - 4, 117), 2, glint);
        }
    }
  }

  void _mouth(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(140, 144)
        ..quadraticBezierTo(150, 152, 160, 144),
      _line(_ink, 4),
    );
  }

  // --------------------------------------------------------------- pelo

  void _hairBack(Canvas canvas, Color color) {
    switch (c.hairStyle) {
      case 2: // largo
        _shape(
          canvas,
          Path()
            ..moveTo(64, 204)
            ..quadraticBezierTo(50, 28, 150, 24)
            ..quadraticBezierTo(250, 28, 236, 204)
            ..close(),
          color,
        );
      case 6: // coletas
        for (final x in [52.0, 248.0]) {
          _shape(canvas, Path()..addOval(Rect.fromCenter(center: Offset(x, 128), width: 36, height: 64)), color);
          canvas.drawCircle(Offset(x, 96), 7, _fill(const Color(0xFFDB2777)));
        }
      case 7: // rodete
        _shape(canvas, Path()..addOval(Rect.fromCenter(center: const Offset(150, 26), width: 50, height: 44)), color);
    }
  }

  void _hairFront(Canvas canvas, Color color) {
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
      case 5: // puntiagudo, estilo anime
        p
          ..moveTo(68, 110)
          ..lineTo(72, 62)
          ..lineTo(56, 50)
          ..lineTo(90, 44)
          ..lineTo(84, 18)
          ..lineTo(118, 32)
          ..lineTo(132, 4)
          ..lineTo(150, 28)
          ..lineTo(170, 4)
          ..lineTo(182, 32)
          ..lineTo(216, 18)
          ..lineTo(210, 44)
          ..lineTo(244, 50)
          ..lineTo(228, 62)
          ..lineTo(232, 110)
          ..quadraticBezierTo(218, 72, 184, 66)
          ..lineTo(170, 86)
          ..lineTo(158, 64)
          ..lineTo(142, 84)
          ..lineTo(130, 64)
          ..lineTo(110, 82)
          ..quadraticBezierTo(80, 74, 68, 110)
          ..close();
      default: // corto, y la parte de arriba de largo, coletas y rodete
        p
          ..moveTo(72, 104)
          ..quadraticBezierTo(70, 30, 150, 28)
          ..quadraticBezierTo(230, 30, 228, 104)
          ..quadraticBezierTo(214, 66, 150, 64)
          ..quadraticBezierTo(86, 66, 72, 104)
          ..close();
    }
    _shape(canvas, p, color);
  }

  // ---------------------------------------------------- piezas del disfraz

  void _star(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final angle = -1.5708 + i * 0.6283;
      final point = center + Offset(radius * math.cos(angle), radius * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    _shape(canvas, path, color, outline: 1.5);
  }

  void _heroMask(Canvas canvas, Color main) {
    final mask = Path()
      ..moveTo(98, 108)
      ..quadraticBezierTo(150, 90, 202, 108)
      ..quadraticBezierTo(206, 126, 190, 130)
      ..quadraticBezierTo(150, 120, 110, 130)
      ..quadraticBezierTo(94, 126, 98, 108)
      ..close();
    _shape(canvas, mask, _shade(main, 0.45), outline: 2);
  }

  void _ninjaMask(Canvas canvas) {
    _shape(canvas, _rrect(84, 126, 216, 172, 34), const Color(0xFF2B2D42), outline: 2);
  }

  void _hoodFor(Canvas canvas, Color main) {
    final color = switch (_outfit) {
      _ninja => const Color(0xFF2B2D42),
      _dino => const Color(0xFF22C55E),
      _ => const Color(0xFFFFFFFF),
    };
    final hood = Path()
      ..moveTo(64, 132)
      ..quadraticBezierTo(56, 22, 150, 20)
      ..quadraticBezierTo(244, 22, 236, 132)
      ..quadraticBezierTo(226, 80, 150, 74)
      ..quadraticBezierTo(74, 80, 64, 132)
      ..close();
    _shape(canvas, hood, color);
    switch (_outfit) {
      case _ninja:
        canvas.drawRect(const Rect.fromLTRB(70, 78, 230, 90), _fill(main));
        final tails = Path()
          ..moveTo(226, 82)
          ..lineTo(256, 70)
          ..lineTo(250, 86)
          ..lineTo(260, 100)
          ..lineTo(226, 90)
          ..close();
        canvas.drawPath(tails, _fill(main));
      case _dino:
        for (final x in [104.0, 127.0, 150.0, 173.0, 196.0]) {
          final top = 22 + (x - 150) * (x - 150) / 300;
          final spike = Path()
            ..moveTo(x - 11, top + 8)
            ..lineTo(x, top - 16)
            ..lineTo(x + 11, top + 8)
            ..close();
          _shape(canvas, spike, const Color(0xFFF97316), outline: 2);
        }
      case _unicornio:
        final horn = Path()
          ..moveTo(138, 26)
          ..lineTo(150, -8)
          ..lineTo(162, 26)
          ..close();
        _shape(canvas, horn, const Color(0xFFFACC15), outline: 2);
        const mane = [Color(0xFFF472B6), Color(0xFFA78BFA), Color(0xFF60A5FA), Color(0xFF34D399), Color(0xFFFACC15)];
        for (var i = 0; i < mane.length; i++) {
          canvas.drawCircle(Offset(214.0 + i * 4, 40.0 + i * 18), 11, _fill(mane[i]));
        }
    }
  }

  void _glasses(Canvas canvas) {
    final g = _line(_ink, 4);
    canvas.drawCircle(const Offset(125, 112), 22, g);
    canvas.drawCircle(const Offset(175, 112), 22, g);
    canvas.drawLine(const Offset(147, 110), const Offset(153, 110), g);
  }

  void _crown(Canvas canvas, {bool small = false}) {
    final y = small ? 14.0 : 0.0;
    final crown = Path()
      ..moveTo(108, 44 + y)
      ..lineTo(116, 14 + y)
      ..lineTo(132, 32 + y)
      ..lineTo(150, 8 + y)
      ..lineTo(168, 32 + y)
      ..lineTo(184, 14 + y)
      ..lineTo(192, 44 + y)
      ..close();
    _shape(canvas, crown, const Color(0xFFF5B800), outline: 2);
    canvas.drawCircle(Offset(150, 30 + y), 4, _fill(const Color(0xFFDB2777)));
  }

  void _pirateHat(Canvas canvas) {
    final hat = Path()
      ..moveTo(60, 76)
      ..quadraticBezierTo(150, -6, 240, 76)
      ..quadraticBezierTo(150, 52, 60, 76)
      ..close();
    _shape(canvas, hat, const Color(0xFF1E1E1E), outline: 2);
    canvas.drawCircle(const Offset(150, 44), 7, _fill(Colors.white));
  }

  void _eyePatch(Canvas canvas) {
    canvas.drawLine(const Offset(84, 94), const Offset(216, 128), _line(_ink, 3));
    canvas.drawOval(Rect.fromCenter(center: const Offset(175, 114), width: 34, height: 30), _fill(_ink));
  }

  void _helmet(Canvas canvas) {
    final rect = Rect.fromCenter(center: const Offset(150, 104), width: 200, height: 184);
    canvas.drawOval(rect, _fill(const Color(0xFFBFDBFE).withValues(alpha: 0.22)));
    canvas.drawOval(rect, _line(const Color(0xFF93C5FD), 6));
    canvas.drawArc(rect.deflate(16), 3.6, 0.8, false, _line(Colors.white.withValues(alpha: 0.8), 6));
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
          _fill(const Color(0xFFDC2626)),
        );
        canvas.drawRRect(RRect.fromLTRBR(64, 78, 236, 92, const Radius.circular(7)), _fill(const Color(0xFF991B1B)));
      case 2: // vincha
        canvas.drawPath(
          Path()
            ..moveTo(78, 88)
            ..quadraticBezierTo(86, 38, 150, 36)
            ..quadraticBezierTo(214, 38, 222, 88),
          _line(const Color(0xFFEC4899), 11),
        );
      case 3: // auriculares
        canvas.drawPath(
          Path()
            ..moveTo(66, 112)
            ..quadraticBezierTo(66, 16, 150, 16)
            ..quadraticBezierTo(234, 16, 234, 112),
          _line(_ink, 9),
        );
        final cup = _fill(const Color(0xFF2563EB));
        canvas.drawRRect(RRect.fromLTRBR(54, 94, 78, 134, const Radius.circular(11)), cup);
        canvas.drawRRect(RRect.fromLTRBR(222, 94, 246, 134, const Radius.circular(11)), cup);
      case 4: // corona
        _crown(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant _FunkoPainter old) => old.c != c || old.headOnly != headOnly;
}
