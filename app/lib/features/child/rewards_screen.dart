import 'package:flutter/material.dart';

import '../../data/family_store.dart';
import '../../domain/points.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Tienda de premios semanal y alcancía del mes.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final me = store.currentMember!;
    final accent = Theme.of(context).colorScheme.primary;
    final balance = store.balanceOf(me.id);
    final open = PointsRules.isStoreOpen(store.now);
    final pending = store.redemptionsOf(me.id).where((r) => r.status == RedemptionStatus.pending).length;
    const piggyGoal = 1000;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(open ? 'Tienda abierta · viernes a domingo' : 'La tienda abre el viernes', style: mutedText(context)),
        Text('Mis premios', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(22)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Para gastar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    Text('$balance', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                    const Text('puntos de la semana', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alcancía del mes', style: mutedText(context).copyWith(fontWeight: FontWeight.w700)),
                    Text('${store.piggyOf(me.id)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (store.piggyOf(me.id) / piggyGoal).clamp(0, 1).toDouble(),
                        minHeight: 8,
                        color: const Color(0xFFEA7A2B),
                        backgroundColor: const Color(0xFFE9ECF4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Premio grande: a definir en familia', style: mutedText(context).copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (pending > 0) ...[
          const SizedBox(height: 12),
          InfoCard(
            color: AppColors.warmBg,
            child: Row(
              children: [
                const Icon(Icons.hourglass_top, color: AppColors.warmInk),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pending == 1
                        ? 'Le avisamos a tu papá o mamá. Esperando que lo apruebe.'
                        : 'Tenés $pending premios esperando aprobación.',
                    style: const TextStyle(color: Color(0xFF7C2D12), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Elegí tu premio', style: sectionTitle(context)),
        const SizedBox(height: 10),
        for (final reward in store.rewards) ...[
          _RewardTile(reward: reward, memberId: me.id, storeOpen: open),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.reward, required this.memberId, required this.storeOpen});

  final Reward reward;
  final String memberId;
  final bool storeOpen;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final balance = store.balanceOf(memberId);
    final asked = store.hasPendingRedemption(memberId, reward.id);
    final can = storeOpen && !asked && PointsRules.canRedeem(balance: balance, reward: reward);
    final label = asked
        ? 'Pedido'
        : !storeOpen
            ? 'Viernes'
            : can
                ? 'Canjear'
                : 'Faltan ${reward.cost - balance}';

    return InfoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconBadge(icon: reward.icon, background: const Color(0xFFE8EEFF), color: AppColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text('${reward.cost} pts', style: mutedText(context).copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          FilledButton(
            onPressed: can
                ? () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('¿Canjear ${reward.name}?'),
                        content: Text('Se descuentan ${reward.cost} puntos y le avisamos al adulto para que lo apruebe.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Todavía no')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Canjear')),
                        ],
                      ),
                    );
                    if (ok == true) store.requestReward(memberId, reward.id);
                  }
                : null,
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
