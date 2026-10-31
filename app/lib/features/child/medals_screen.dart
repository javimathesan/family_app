import 'package:flutter/material.dart';

import '../../data/family_store.dart';
import '../../widgets/common.dart';

/// Vitrina de medallas de un miembro.
class MedalsScreen extends StatelessWidget {
  const MedalsScreen({super.key, this.memberId});

  final String? memberId;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final id = memberId ?? store.currentMember?.id;
    final member = id == null ? null : store.memberById(id);
    final medals = id == null ? const <Medal>[] : store.medalsOf(id);
    final earned = medals.where((m) => m.earned).length;
    return Scaffold(
      appBar: AppBar(title: Text(member == null ? 'Medallas' : 'Medallas de ${member.nickname}', style: const TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('$earned de ${medals.length} medallas', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Se ganan solas, cumpliendo la rutina, jugando y aprendiendo.', style: mutedText(context)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: .78,
              children: [
                for (final m in medals)
                  Tooltip(
                    message: m.how,
                    triggerMode: TooltipTriggerMode.tap,
                    child: InfoCard(
                      padding: const EdgeInsets.all(8),
                      color: m.earned ? const Color(0xFFFFF8E1) : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(opacity: m.earned ? 1 : .25, child: Text(m.emoji, style: const TextStyle(fontSize: 40))),
                          const SizedBox(height: 4),
                          Text(m.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: m.earned ? null : Colors.grey)),
                          if (!m.earned)
                            Text(m.how, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: mutedText(context).copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
