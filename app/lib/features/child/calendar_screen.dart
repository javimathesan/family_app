import 'package:flutter/material.dart';

import '../../data/family_store.dart';
import '../../domain/points.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/mood_face.dart';

/// Calendario mensual con una carita por día según el cumplimiento.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final me = store.currentMember!;
    final accent = Theme.of(context).colorScheme.primary;
    final today = DateUtils.dateOnly(store.now);
    final month = DateTime(today.year, today.month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leading = month.weekday - 1; // semana empieza el lunes

    final byDay = <DateTime, DaySummary>{
      for (final s in store.historyOf(me.id)) DateUtils.dateOnly(s.date): s,
    };
    final selectedDay = _selected ?? byDay.keys.where((d) => d.isBefore(today)).fold<DateTime?>(null, (a, b) => b);
    final selected = selectedDay == null ? null : byDay[selectedDay];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Center(
          child: Column(
            children: [
              Text('${_cap(monthName(month.month))} ${month.year}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              Text('Mi mes en caritas', style: mutedText(context).copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        InfoCard(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
          child: Column(
            children: [
              Row(
                children: [
                  for (final d in const ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
                    Expanded(child: Center(child: Text(d, style: mutedText(context).copyWith(fontWeight: FontWeight.w800)))),
                ],
              ),
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.78,
                children: [
                  for (var i = 0; i < leading; i++) const SizedBox.shrink(),
                  for (var day = 1; day <= daysInMonth; day++)
                    _DayCell(
                      date: DateTime(month.year, month.month, day),
                      summary: byDay[DateTime(month.year, month.month, day)],
                      isToday: day == today.day,
                      isSelected: selectedDay == DateTime(month.year, month.month, day),
                      accent: accent,
                      onTap: () => setState(() => _selected = DateTime(month.year, month.month, day)),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (selected != null) _DayDetail(summary: selected),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final (mood, label) in const [
              (Mood.verySad, '<25%'),
              (Mood.sad, '25%'),
              (Mood.neutral, '50%'),
              (Mood.happy, '80%'),
              (Mood.veryHappy, '100%'),
            ])
              Column(
                children: [
                  MoodFace(mood: mood),
                  Text(label, style: mutedText(context).copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static String _cap(String s) => '${s[0].toUpperCase()}${s.substring(1)}';
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.summary,
    required this.isToday,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final DateTime date;
  final DaySummary? summary;
  final bool isToday;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = summary != null;
    final mood = has ? Mood.fromRatio(summary!.completionRatio) : null;
    return Semantics(
      button: has,
      label: '${date.day} de ${monthName(date.month)}${mood != null ? ', ${mood.label}' : ''}',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: has ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFFEEF3FF) : null,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accent : (isToday ? const Color(0xFF93B7FA) : Colors.transparent),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted)),
              if (mood != null) MoodFace(mood: mood, size: 24) else const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.summary});

  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final mood = Mood.fromRatio(summary.completionRatio);
    final pct = (summary.completionRatio * 100).round();
    final h = summary.screenMinutes ~/ 60;
    final m = summary.screenMinutes % 60;
    final w = weekdayName(summary.date);
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${w[0].toUpperCase()}${w.substring(1)} ${summary.date.day} de ${monthName(summary.date.month)}',
                    style: sectionTitle(context)),
              ),
              Text('${summary.points} pts', style: TextStyle(fontWeight: FontWeight.w800, color: accent)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${mood.label} · cumpliste el $pct% de tus tareas', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              _Stat(label: 'Agua', value: '${summary.glasses} vasos'),
              const SizedBox(width: 8),
              _Stat(label: 'Pantallas', value: m == 0 ? '$h h' : '$h h $m'),
              const SizedBox(width: 8),
              _Stat(label: 'Mi ánimo', value: summary.mood ?? '—'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: mutedText(context).copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
