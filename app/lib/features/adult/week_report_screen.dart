import 'package:flutter/material.dart';

import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';

/// Resumen de los últimos 7 días de cada hijo.
class WeekReportScreen extends StatelessWidget {
  const WeekReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final children = [for (final c in store.children) if (!store.isPendingMember(c.id)) c];
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de la semana', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Últimos 7 días, incluido hoy.', style: mutedText(context)),
            const SizedBox(height: 12),
            if (children.isEmpty) Text('Todavía no hay hijos en el hogar.', style: mutedText(context).copyWith(fontSize: 15)),
            for (final c in children) _ChildWeek(member: c),
          ],
        ),
      ),
    );
  }
}

class _ChildWeek extends StatelessWidget {
  const _ChildWeek({required this.member});

  final Member member;

  static Color colorFor(double ratio) {
    if (ratio >= .85) return const Color(0xFF2E7D32);
    if (ratio >= .5) return const Color(0xFFF9A825);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final days = store.lastDays(member.id);
    final withData = [for (final d in days) if (d.summary != null) d];
    final avg = withData.isEmpty ? 0.0 : withData.map((d) => d.summary!.completionRatio).reduce((a, b) => a + b) / withData.length;
    final points = withData.fold<int>(0, (sum, d) => sum + d.summary!.points);
    final waterDays = withData.where((d) => d.summary!.glasses >= 8).length;
    final moods = <String, int>{};
    for (final d in withData) {
      final m = d.summary!.mood;
      if (m != null) moods[m] = (moods[m] ?? 0) + 1;
    }
    final topMood = moods.isEmpty ? null : (moods.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    final best = withData.isEmpty
        ? null
        : (withData.toList()..sort((a, b) => b.summary!.completionRatio.compareTo(a.summary!.completionRatio))).first;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarView(config: member.avatar, size: 44),
                const SizedBox(width: 10),
                Expanded(child: Text(member.nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                Text('${(avg * 100).round()}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: colorFor(avg))),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in days)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Tooltip(
                              message: d.summary == null ? 'Sin datos' : '${(d.summary!.completionRatio * 100).round()}% · ${d.summary!.points} pts',
                              child: Container(
                                height: d.summary == null ? 4 : 4 + 76 * d.summary!.completionRatio,
                                decoration: BoxDecoration(
                                  color: d.summary == null ? Colors.black12 : colorFor(d.summary!.completionRatio),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(weekdayName(d.date).substring(0, 2).toUpperCase(), style: mutedText(context).copyWith(fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(avatar: const Icon(Icons.star_outline, size: 18), label: Text('$points pts en la semana')),
                Chip(avatar: const Icon(Icons.local_drink_outlined, size: 18), label: Text('$waterDays días con 8 vasos')),
                Chip(avatar: const Icon(Icons.savings_outlined, size: 18), label: Text('${store.balanceOf(member.id)} pts para canjear')),
                if (store.challenge != null)
                  Chip(
                    avatar: const Icon(Icons.emoji_events_outlined, size: 18),
                    label: Text(store.challengeClaimed(member.id)
                        ? 'Reto cumplido 🏅'
                        : 'Reto: ${store.challengeProgress(member.id)} de ${store.challenge!.target}'),
                  ),
                if (topMood != null) Chip(avatar: const Icon(Icons.mood, size: 18), label: Text('Ánimo: ${topMood.toLowerCase()}')),
              ],
            ),
            if (best != null && best.summary!.completionRatio > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Mejor día: ${weekdayName(best.date)} (${(best.summary!.completionRatio * 100).round()}%)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
