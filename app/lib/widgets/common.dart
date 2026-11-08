import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Zona con fondo claro fijo (tableros, cielo de Tiro al blanco): adentro se
/// usa siempre el tema claro, para que en modo oscuro el texto no quede
/// blanco sobre celeste.
class LightZone extends StatelessWidget {
  const LightZone({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.light) return child;
    return Theme(
      data: AppTheme.light(theme.colorScheme.primary),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: AppColors.ink),
        child: IconTheme.merge(data: const IconThemeData(color: AppColors.ink), child: child),
      ),
    );
  }
}

/// Tarjeta blanca redondeada, base de casi todas las pantallas.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color});

  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Material (no Container) para que ListTile e InkWell muestren su efecto al tocar.
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    // Si el chico pintó esta tarjeta (Plus), manda su color.
    final color = CardTint.maybeOf(context) ?? this.color;
    // En modo oscuro los colores claros de las tarjetas se vuelven un tinte suave.
    final bg = color == null
        ? surface
        : (theme.brightness == Brightness.dark ? Color.alphaBlend(color.withValues(alpha: 0.16), surface) : color);
    final shape = theme.cardTheme.shape;
    return Material(
      color: bg,
      shape: shape is RoundedRectangleBorder ? shape : RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Pinta las [InfoCard] de adentro con un color elegido por el chico.
class CardTint extends InheritedWidget {
  const CardTint({super.key, required this.color, required super.child});

  final Color color;

  static Color? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<CardTint>()?.color;

  @override
  bool updateShouldNotify(CardTint old) => old.color != color;
}

/// Ícono dentro de un cuadrado de color suave.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.background, required this.color, this.size = 48});

  final IconData icon;
  final Color background;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

TextStyle mutedText(BuildContext context) => TextStyle(
      fontSize: 13,
      // En modo oscuro el gris es más claro para que se lea bien.
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFA6ACC0) : AppColors.muted,
    );

TextStyle? sectionTitle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);

String hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

const _weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String weekdayName(DateTime d) => _weekdays[d.weekday - 1];
String monthName(int month) => _months[month - 1];

/// "Jueves 29 de octubre".
String longDate(DateTime d) {
  final w = weekdayName(d);
  return '${w[0].toUpperCase()}${w.substring(1)} ${d.day} de ${monthName(d.month)}';
}
