import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';

/// Disfraz o accesorio de la tienda del avatar.
@immutable
class AvatarItem {
  const AvatarItem(this.id, this.label, this.cost, {this.premium = false});

  /// De Family App Plus: no se compra con puntos.
  final bool premium;

  /// Identificador estable (se guarda en `Member.unlocked`).
  final String id;
  final String label;

  /// Puntos para desbloquearlo. 0 = libre.
  final int cost;

  bool get free => cost == 0 && !premium;
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
  static const hairStyles = [
    'Corto', 'Flequillo', 'Largo', 'Rulos', 'Rapado', 'Puntiagudo', 'Coletas', 'Rodete',
    'Trenzas', 'Afro', 'Mohicano', 'Colita alta', 'Ondas', 'Melena corta',
  ];
  static const hairColors = <(String, Color)>[
    ('Negro', Color(0xFF1E1E1E)),
    ('Castaño oscuro', Color(0xFF4A3426)),
    ('Castaño claro', Color(0xFF8A5A35)),
    ('Rubio', Color(0xFFD9A93F)),
    ('Pelirrojo', Color(0xFFB4471F)),
    ('Azul fantasía', Color(0xFF3B6FD8)),
    ('Rosa fantasía', Color(0xFFE5579B)),
    ('Canoso', Color(0xFFD1D5DB)),
    ('Violeta fantasía', Color(0xFF8B5CF6)),
    ('Verde fantasía', Color(0xFF10B981)),
  ];
  static const eyes = ['Redondos', 'Felices', 'Dormilones', 'Brillantes', 'Pestañas', 'Guiño', 'Estrellas', 'Corazones'];
  static const brows = ['Sin cejas', 'Finas', 'Gruesas'];

  /// Color principal de la ropa o del disfraz.
  static const shirts = <(String, Color)>[
    ('Azul', Color(0xFF2563EB)),
    ('Verde agua', Color(0xFF0F766E)),
    ('Violeta', Color(0xFF7C3AED)),
    ('Naranja', Color(0xFFEA7A2B)),
    ('Rosa', Color(0xFFDB2777)),
    ('Rojo', Color(0xFFDC2626)),
    ('Gris', Color(0xFF5B6178)),
    ('Amarillo', Color(0xFFCA8A04)),
    ('Celeste', Color(0xFF0284C7)),
    ('Negro', Color(0xFF1F2937)),
    ('Verde', Color(0xFF15803D)),
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
    AvatarItem('outfit_bombero', 'Bombero', 100),
    AvatarItem('outfit_doctora', 'Doctora', 100),
    AvatarItem('outfit_mago', 'Mago', 150),
    AvatarItem('outfit_chef', 'Chef', 80),
    AvatarItem('outfit_futbol', 'Futbolista', 80),
    AvatarItem('outfit_robot', 'Robot', 150),
    // Family App Plus.
    AvatarItem('outfit_sirena', 'Sirena', 0, premium: true),
    AvatarItem('outfit_dragon', 'Dragón', 0, premium: true),
    AvatarItem('outfit_hada', 'Hada', 0, premium: true),
    AvatarItem('outfit_caballero', 'Caballero', 0, premium: true),
  ];

  static const accessories = <AvatarItem>[
    AvatarItem('acc_ninguno', 'Ninguno', 0),
    AvatarItem('acc_gorra', 'Gorra', 0),
    AvatarItem('acc_vincha', 'Vincha', 0),
    AvatarItem('acc_auriculares', 'Auriculares', 0),
    AvatarItem('acc_corona', 'Corona', 120),
    AvatarItem('acc_mono', 'Moño', 40),
    AvatarItem('acc_aureola', 'Aureola', 0, premium: true),
  ];

  /// Disfraces que ya cubren la cabeza: no se dibuja accesorio encima.
  static bool outfitCoversHead(int outfit) => const {2, 3, 4, 5, 6, 7, 9, 11, 12, 14, 15, 16, 17, 18}.contains(outfit);
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
const _bombero = 9;
const _doctora = 10;
const _mago = 11;
const _chef = 12;
const _futbol = 13;
const _robot = 14;
const _sirena = 15;
const _dragon = 16;
const _hada = 17;
const _caballero = 18;

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
  bool get _hood => const {_ninja, _dino, _unicornio, _robot, _dragon, _caballero}.contains(_outfit);

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
    if (_outfit == _hada) _fairyWings(canvas);
    if (_outfit == _dragon) _dragonWings(canvas);
    if (!_hood) _hairBack(canvas, hair);
    _legs(canvas, main);
    _arms(canvas, skin, main);
    _body(canvas, main, skin);
    _head(canvas, skin);
    if (_outfit == _heroe) _heroMask(canvas, main);
    _eyes(canvas);
    _face(canvas, hair, skin);
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
      case _bombero:
        _fireHelmet(canvas);
      case _mago:
        _wizardHat(canvas, main);
      case _chef:
        _chefHat(canvas);
      case _robot:
        _antenna(canvas);
      case _dragon:
        _horns(canvas);
      case _hada:
        _flowerCrown(canvas);
      case _sirena:
        _star(canvas, const Offset(204, 52), 16, const Color(0xFFFB923C));
      case _caballero:
        _plume(canvas);
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
    if (_outfit == _sirena) {
      final tail = Path()
        ..moveTo(122, 204)
        ..quadraticBezierTo(150, 214, 178, 204)
        ..quadraticBezierTo(170, 226, 154, 232)
        ..lineTo(146, 232)
        ..quadraticBezierTo(130, 226, 122, 204)
        ..close();
      _shape(canvas, tail, const Color(0xFF14B8A6));
      final fin = Path()
        ..moveTo(150, 228)
        ..quadraticBezierTo(124, 236, 118, 248)
        ..quadraticBezierTo(140, 246, 150, 238)
        ..quadraticBezierTo(160, 246, 182, 248)
        ..quadraticBezierTo(176, 236, 150, 228)
        ..close();
      _shape(canvas, fin, const Color(0xFF0D9488));
      return;
    }
    final pants = switch (_outfit) {
      _bombero => const Color(0xFF4B5563),
      _doctora => const Color(0xFF1E3A8A),
      _mago => _shade(main, 0.35),
      _chef => const Color(0xFF374151),
      _futbol => const Color(0xFFF8FAFC),
      _robot => const Color(0xFF94A3B8),
      _dragon => const Color(0xFFDC2626),
      _hada => _tint(main, 0.5),
      _caballero => const Color(0xFF9CA3AF),
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
    final shoe = switch (_outfit) {
      _heroe => _shade(main, 0.3),
      _robot || _caballero => const Color(0xFF64748B),
      _dragon => const Color(0xFF991B1B),
      _ => const Color(0xFF1E2235),
    };
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
      _bombero => const Color(0xFFB91C1C),
      _doctora || _chef => const Color(0xFFF8FAFC),
      _mago => _shade(main, 0.2),
      _robot => const Color(0xFFCBD5E1),
      _dragon => const Color(0xFFDC2626),
      _hada => _tint(main, 0.5),
      _caballero => const Color(0xFF9CA3AF),
      _ => main,
    };
    final longSleeve = !const {_remera, _princesa, _futbol, _hada, _sirena}.contains(_outfit);
    for (final x in [104.0, 178.0]) {
      _shape(canvas, _rrect(x, 170, x + 18, 210, 9), longSleeve ? sleeve : skin, outline: 2);
      if (!longSleeve) _shape(canvas, _rrect(x, 168, x + 18, 186, 8), sleeve, outline: 2);
      final hand = switch (_outfit) {
        _astronauta || _robot => const Color(0xFFCBD5E1),
        _caballero => const Color(0xFF6B7280),
        _dragon => const Color(0xFFDC2626),
        _ => skin,
      };
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

  void _body(Canvas canvas, Color main, Color skin) {
    final torso = _rrect(116, 164, 184, 222, 18);
    switch (_outfit) {
      case _bombero:
        _shape(canvas, torso, const Color(0xFFB91C1C));
        final stripe = _fill(const Color(0xFFFACC15));
        canvas.drawRect(const Rect.fromLTRB(117, 196, 183, 203), stripe);
        canvas.drawRect(const Rect.fromLTRB(147, 166, 153, 220), _fill(const Color(0xFF7F1D1D)));
        canvas.drawRect(const Rect.fromLTRB(117, 210, 183, 215), stripe);
      case _doctora:
        _shape(canvas, torso, const Color(0xFFF8FAFC));
        final v = Path()
          ..moveTo(136, 165)
          ..lineTo(150, 190)
          ..lineTo(164, 165)
          ..close();
        canvas.drawPath(v, _fill(main));
        final steth = Path()
          ..moveTo(132, 166)
          ..quadraticBezierTo(128, 196, 146, 200);
        canvas.drawPath(steth, _line(_ink, 3));
        canvas.drawCircle(const Offset(148, 201), 5, _fill(const Color(0xFF94A3B8)));
        canvas.drawRect(const Rect.fromLTRB(164, 196, 176, 204), _fill(const Color(0xFFDC2626)));
      case _mago:
        _shape(canvas, torso, _shade(main, 0.2));
        for (final o in const [Offset(132, 180), Offset(166, 196), Offset(140, 210)]) {
          _star(canvas, o, 6, const Color(0xFFFACC15));
        }
      case _chef:
        _shape(canvas, torso, const Color(0xFFF8FAFC));
        for (final y in [180.0, 194.0, 208.0]) {
          canvas.drawCircle(Offset(140, y), 3, _fill(_ink));
          canvas.drawCircle(Offset(160, y), 3, _fill(_ink));
        }
        final scarf = Path()
          ..moveTo(132, 164)
          ..lineTo(168, 164)
          ..lineTo(150, 178)
          ..close();
        canvas.drawPath(scarf, _fill(main));
      case _futbol:
        _shape(canvas, torso, main);
        final tp = TextPainter(
          text: const TextSpan(text: '10', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(150 - tp.width / 2, 178));
      case _robot:
        _shape(canvas, torso, const Color(0xFFCBD5E1));
        _shape(canvas, _rrect(130, 178, 170, 208, 6), const Color(0xFF334155), outline: 0);
        for (final (x, color) in const [(140.0, Color(0xFFEF4444)), (150.0, Color(0xFFFACC15)), (160.0, Color(0xFF22C55E))]) {
          canvas.drawCircle(Offset(x, 188), 4, _fill(color));
        }
        canvas.drawRect(const Rect.fromLTRB(136, 198, 164, 202), _fill(const Color(0xFF38BDF8)));
      case _sirena:
        _shape(canvas, torso, skin, outline: 2);
        for (final x in [137.0, 163.0]) {
          canvas.drawCircle(Offset(x, 180), 11, _fill(main));
          canvas.drawCircle(Offset(x, 180), 11, _line(_shade(main, 0.35), 2));
        }
        canvas.drawRect(const Rect.fromLTRB(118, 200, 182, 222), _fill(const Color(0xFF14B8A6)));
      case _dragon:
        _shape(canvas, torso, const Color(0xFFDC2626));
        canvas.drawOval(const Rect.fromLTRB(130, 174, 170, 218), _fill(const Color(0xFFFDE68A)));
      case _hada:
        final dress = Path()
          ..moveTo(128, 164)
          ..lineTo(172, 164)
          ..lineTo(196, 228)
          ..quadraticBezierTo(150, 238, 104, 228)
          ..close();
        _shape(canvas, dress, _tint(main, 0.35));
        for (final o in const [Offset(130, 210), Offset(150, 196), Offset(170, 214), Offset(146, 224)]) {
          canvas.drawCircle(o, 2.5, _fill(Colors.white));
        }
      case _caballero:
        _shape(canvas, torso, const Color(0xFF9CA3AF));
        canvas.drawRect(const Rect.fromLTRB(145, 172, 155, 208), _fill(main));
        canvas.drawRect(const Rect.fromLTRB(134, 182, 166, 190), _fill(main));
        canvas.drawRect(const Rect.fromLTRB(117, 208, 183, 214), _fill(const Color(0xFF78350F)));
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
      case 4: // pestañas
        for (final x in [125.0, 175.0]) {
          canvas.drawCircle(Offset(x, 112), 14, dark);
          canvas.drawCircle(Offset(x + 5, 106), 4.5, glint);
          for (final dx in [-10.0, 0.0, 10.0]) {
            canvas.drawLine(Offset(x + dx * .9, 99), Offset(x + dx * 1.4, 90), _line(_ink, 3));
          }
        }
      case 5: // guiño
        canvas.drawCircle(const Offset(125, 112), 14, dark);
        canvas.drawCircle(const Offset(130, 106), 4.5, glint);
        canvas.drawPath(
          Path()
            ..moveTo(161, 114)
            ..quadraticBezierTo(175, 102, 189, 114),
          _line(_ink, 6),
        );
      case 6: // estrellas
        for (final x in [125.0, 175.0]) {
          _star(canvas, Offset(x, 112), 17, _ink);
          canvas.drawCircle(Offset(x + 3, 108), 3, glint);
        }
      case 7: // corazones
        for (final x in [125.0, 175.0]) {
          final h = Path()
            ..moveTo(x, 126)
            ..cubicTo(x - 22, 112, x - 14, 94, x, 104)
            ..cubicTo(x + 14, 94, x + 22, 112, x, 126)
            ..close();
          canvas.drawPath(h, _fill(const Color(0xFFE11D48)));
          canvas.drawCircle(Offset(x - 6, 106), 3, glint);
        }
      default:
        for (final x in [125.0, 175.0]) {
          canvas.drawCircle(Offset(x, 112), 14, dark);
          canvas.drawCircle(Offset(x + 5, 106), 4.5, glint);
          canvas.drawCircle(Offset(x - 4, 117), 2, glint);
        }
    }
  }

  /// Cejas y pecas.
  void _face(Canvas canvas, Color hair, Color skin) {
    if (c.brows > 0) {
      final brow = _line(_shade(hair, 0.15), c.brows == 2 ? 7 : 4);
      for (final x in [125.0, 175.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(x - 15, 88)
            ..quadraticBezierTo(x, 80, x + 15, 88),
          brow,
        );
      }
    }
    if (c.freckles) {
      final dot = _fill(_shade(skin, 0.35));
      for (final o in const [Offset(100, 128), Offset(108, 134), Offset(96, 136), Offset(200, 128), Offset(192, 134), Offset(204, 136)]) {
        canvas.drawCircle(o, 2.2, dot);
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
      case 8: // trenzas
        for (final x in [70.0, 230.0]) {
          for (var i = 0; i < 5; i++) {
            _shape(canvas, Path()..addOval(Rect.fromCenter(center: Offset(x, 120 + i * 20.0), width: 26 - i * 1.5, height: 24)), color, outline: 2);
          }
          canvas.drawCircle(Offset(x, 218), 6, _fill(const Color(0xFF2563EB)));
        }
      case 9: // afro
        _shape(canvas, Path()..addOval(Rect.fromCenter(center: const Offset(150, 92), width: 232, height: 196)), color);
      case 11: // colita alta
        _shape(
          canvas,
          Path()
            ..moveTo(170, 30)
            ..quadraticBezierTo(250, 10, 240, 110)
            ..quadraticBezierTo(232, 60, 182, 52)
            ..close(),
          color,
        );
        canvas.drawCircle(const Offset(178, 36), 8, _fill(const Color(0xFFDB2777)));
      case 12: // ondas
        final w = Path()..moveTo(64, 190);
        w.quadraticBezierTo(50, 28, 150, 24);
        w.quadraticBezierTo(250, 28, 236, 190);
        for (var i = 0; i < 6; i++) {
          final x = 236 - i * 172 / 6;
          w.quadraticBezierTo(x - 14, 206, x - 172 / 6, 190);
        }
        w.close();
        _shape(canvas, w, color);
      case 13: // melena corta
        _shape(
          canvas,
          Path()
            ..moveTo(66, 168)
            ..quadraticBezierTo(52, 28, 150, 26)
            ..quadraticBezierTo(248, 28, 234, 168)
            ..lineTo(66, 168)
            ..close(),
          color,
        );
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
      case 9: // afro: frente con rulitos
        p
          ..moveTo(70, 104)
          ..quadraticBezierTo(60, 50, 100, 40)
          ..quadraticBezierTo(150, 20, 200, 40)
          ..quadraticBezierTo(240, 50, 230, 104)
          ..quadraticBezierTo(216, 70, 150, 68)
          ..quadraticBezierTo(84, 70, 70, 104)
          ..close();
      case 10: // mohicano: costados rapados y cresta
        _shape(
          canvas,
          Path()
            ..moveTo(78, 92)
            ..quadraticBezierTo(82, 40, 150, 38)
            ..quadraticBezierTo(218, 40, 222, 92)
            ..quadraticBezierTo(200, 64, 150, 62)
            ..quadraticBezierTo(100, 64, 78, 92)
            ..close(),
          color.withValues(alpha: 0.45),
          outline: 0,
        );
        p
          ..moveTo(132, 64)
          ..lineTo(126, 30)
          ..lineTo(138, 34)
          ..lineTo(140, 2)
          ..lineTo(152, 26)
          ..lineTo(162, 0)
          ..lineTo(166, 34)
          ..lineTo(176, 30)
          ..lineTo(168, 64)
          ..close();
      case 12 || 13: // ondas y melena: flequillo de costado
        p
          ..moveTo(70, 112)
          ..quadraticBezierTo(66, 26, 150, 26)
          ..quadraticBezierTo(234, 26, 230, 112)
          ..quadraticBezierTo(220, 70, 180, 64)
          ..quadraticBezierTo(120, 92, 74, 100)
          ..close();
      default: // corto, y la parte de arriba de largo, coletas, rodete, trenzas y colita
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
      _robot => const Color(0xFF94A3B8),
      _dragon => const Color(0xFFDC2626),
      _caballero => const Color(0xFF9CA3AF),
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
      case 5: // moño
        final bow = Path()
          ..moveTo(196, 46)
          ..lineTo(176, 32)
          ..lineTo(178, 62)
          ..close()
          ..moveTo(196, 46)
          ..lineTo(216, 30)
          ..lineTo(216, 62)
          ..close();
        _shape(canvas, bow, const Color(0xFFEC4899), outline: 2);
        canvas.drawCircle(const Offset(196, 46), 6, _fill(const Color(0xFFBE185D)));
      case 6: // aureola
        canvas.drawOval(Rect.fromCenter(center: const Offset(150, 8), width: 120, height: 22), _line(const Color(0xFFF5B800), 7));
    }
  }

  // ------------------------------------------------------- disfraces nuevos

  void _fairyWings(Canvas canvas) {
    const wing = Color(0xCCBAE6FD);
    for (final (center, angle) in const [(Offset(98, 168), -0.5), (Offset(202, 168), 0.5), (Offset(108, 204), 0.4), (Offset(192, 204), -0.4)]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final r = Rect.fromCenter(center: Offset.zero, width: 46, height: 30);
      canvas.drawOval(r, _fill(wing));
      canvas.drawOval(r, _line(const Color(0xFF7DD3FC), 2));
      canvas.restore();
    }
  }

  void _dragonWings(Canvas canvas) {
    for (final dir in [-1.0, 1.0]) {
      double x(double v) => 150 + dir * (v - 150);
      final wing = Path()
        ..moveTo(x(122), 172)
        ..lineTo(x(66), 140)
        ..lineTo(x(78), 170)
        ..lineTo(x(58), 180)
        ..lineTo(x(82), 196)
        ..lineTo(x(122), 202)
        ..close();
      _shape(canvas, wing, const Color(0xFF991B1B), outline: 2);
    }
  }

  void _fireHelmet(Canvas canvas) {
    final dome = Path()
      ..moveTo(66, 84)
      ..quadraticBezierTo(70, 14, 150, 12)
      ..quadraticBezierTo(230, 14, 234, 84)
      ..close();
    _shape(canvas, dome, const Color(0xFFDC2626), outline: 2);
    _shape(canvas, _rrect(54, 78, 246, 94, 8), const Color(0xFF991B1B), outline: 0);
    final badge = Path()
      ..moveTo(150, 30)
      ..lineTo(170, 40)
      ..lineTo(164, 70)
      ..lineTo(136, 70)
      ..lineTo(130, 40)
      ..close();
    _shape(canvas, badge, const Color(0xFFFACC15), outline: 2);
  }

  void _wizardHat(Canvas canvas, Color main) {
    final hat = Path()
      ..moveTo(86, 70)
      ..lineTo(168, -24)
      ..lineTo(214, 70)
      ..close();
    _shape(canvas, hat, _shade(main, 0.25));
    canvas.drawOval(const Rect.fromLTRB(64, 58, 236, 84), _fill(_shade(main, 0.4)));
    _star(canvas, const Offset(156, 30), 12, const Color(0xFFFACC15));
  }

  void _chefHat(Canvas canvas) {
    const white = Color(0xFFFFFFFF);
    for (final o in const [Offset(120, 26), Offset(150, 14), Offset(180, 26)]) {
      canvas.drawCircle(o, 26, _fill(white));
      canvas.drawCircle(o, 26, _line(const Color(0xFFCBD5E1), 2));
    }
    _shape(canvas, _rrect(104, 30, 196, 74, 8), white, outline: 0);
    canvas.drawRect(const Rect.fromLTRB(104, 62, 196, 74), _line(const Color(0xFFCBD5E1), 2));
  }

  void _antenna(Canvas canvas) {
    canvas.drawLine(const Offset(150, 22), const Offset(150, -4), _line(const Color(0xFF475569), 5));
    canvas.drawCircle(const Offset(150, -6), 8, _fill(const Color(0xFFEF4444)));
    for (final x in [60.0, 222.0]) {
      _shape(canvas, _rrect(x, 98, x + 18, 128, 4), const Color(0xFF64748B), outline: 0);
    }
  }

  void _horns(Canvas canvas) {
    for (final dir in [-1.0, 1.0]) {
      final horn = Path()
        ..moveTo(150 + dir * 46, 34)
        ..lineTo(150 + dir * 70, -2)
        ..lineTo(150 + dir * 62, 40)
        ..close();
      _shape(canvas, horn, const Color(0xFFFDE68A), outline: 2);
    }
  }

  void _flowerCrown(Canvas canvas) {
    const colors = [Color(0xFFF472B6), Color(0xFFFACC15), Color(0xFFA78BFA), Color(0xFF60A5FA), Color(0xFFF472B6)];
    for (var i = 0; i < colors.length; i++) {
      final x = 98.0 + i * 26;
      final y = 46 - 10 * math.sin(i / 4 * math.pi);
      for (var p = 0; p < 5; p++) {
        final a = p * 2 * math.pi / 5;
        canvas.drawCircle(Offset(x + 7 * math.cos(a), y + 7 * math.sin(a)), 6, _fill(colors[i]));
      }
      canvas.drawCircle(Offset(x, y), 4, _fill(const Color(0xFFFEF3C7)));
    }
  }

  void _plume(Canvas canvas) {
    final plume = Path()
      ..moveTo(150, 22)
      ..quadraticBezierTo(140, -14, 178, -20)
      ..quadraticBezierTo(162, 0, 162, 22)
      ..close();
    _shape(canvas, plume, const Color(0xFFDC2626), outline: 2);
    canvas.drawRect(const Rect.fromLTRB(74, 96, 226, 104), _fill(const Color(0xFF6B7280)));
  }

  @override
  bool shouldRepaint(covariant _FunkoPainter old) => old.c != c || old.headOnly != headOnly;
}
