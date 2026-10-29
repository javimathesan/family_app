import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarjeta blanca redondeada, base de casi todas las pantallas.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color});

  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
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

TextStyle mutedText(BuildContext context) =>
    const TextStyle(fontSize: 13, color: AppColors.muted);

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
