import 'package:flutter/material.dart';

import '../models/models.dart';

/// Paleta base. Simple por defecto; cada miembro puede cambiar su acento.
abstract final class AppColors {
  static const ink = Color(0xFF1E2235);
  static const muted = Color(0xFF5B6178);
  static const ground = Color(0xFFF5F6FA);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE3E6EF);
  static const soft = Color(0xFFF0F2F8);
  static const warmBg = Color(0xFFFFF4E8);
  static const warmInk = Color(0xFF9A3412);

  static const defaultAccent = Color(0xFF2563EB);

  /// Acentos ofrecidos en Ajustes (contraste AA con texto blanco).
  static const accents = <Color>[
    Color(0xFF2563EB), // azul
    Color(0xFF0F766E), // verde agua
    Color(0xFF7C3AED), // violeta
    Color(0xFFC2410C), // naranja
  ];
}

abstract final class AppTheme {
  static ThemeData light(Color accent, [MemberLook look = const MemberLook()]) => _build(accent, Brightness.light, look);
  static ThemeData dark(Color accent, [MemberLook look = const MemberLook()]) => _build(accent, Brightness.dark, look);

  static ThemeData _build(Color accent, Brightness brightness, MemberLook look) {
    final isDark = brightness == Brightness.dark;
    final bgOption = LookOptions.backgrounds[look.background.clamp(0, LookOptions.backgrounds.length - 1)].color;
    // En oscuro, el fondo elegido apenas tiñe el gris noche.
    final ground = isDark ? Color.lerp(const Color(0xFF12141D), bgOption, 0.06)! : bgOption;
    final baseSurface = isDark ? const Color(0xFF1B1E2B) : AppColors.card;
    final cardColor = look.cards == 1 ? Color.lerp(baseSurface, accent, isDark ? 0.14 : 0.07)! : baseSurface;
    final cardRadius = look.cards == 3 ? 30.0 : 20.0;
    final cardSide = look.cards == 2 ? BorderSide(color: accent.withValues(alpha: 0.55), width: 2) : BorderSide.none;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      surface: cardColor,
      onSurface: isDark ? const Color(0xFFF2F3F7) : AppColors.ink,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: ground,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius), side: cardSide),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: isDark ? const Color(0xFF3A3F55) : AppColors.line, width: 2),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: accent.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
