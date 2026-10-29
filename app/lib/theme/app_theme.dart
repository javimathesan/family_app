import 'package:flutter/material.dart';

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
  static ThemeData light(Color accent) => _build(accent, Brightness.light);
  static ThemeData dark(Color accent) => _build(accent, Brightness.dark);

  static ThemeData _build(Color accent, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      surface: isDark ? const Color(0xFF1B1E2B) : AppColors.card,
      onSurface: isDark ? const Color(0xFFF2F3F7) : AppColors.ink,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? const Color(0xFF12141D) : AppColors.ground,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          side: const BorderSide(color: AppColors.line, width: 2),
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
