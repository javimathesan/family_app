import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// El adulto genera un QR de invitación de un solo uso que vence en 15 minutos.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  MemberRole _role = MemberRole.child;
  AgeMode _mode = AgeMode.junior;
  Invitation? _invitation;
  Timer? _ticker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _invitation ??= _create();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Invitation _create() => FamilyScope.of(context).createInvitation(
        role: _role,
        mode: _role == MemberRole.child ? _mode : null,
      );

  void _regenerate() => setState(() => _invitation = _create());

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final inv = _invitation!;
    final left = inv.expiresAt.difference(store.now);
    final expired = left.isNegative;
    final mm = left.inMinutes;
    final ss = (left.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('Sumar a alguien', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('¿Quién se suma?', style: sectionTitle(context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (role, label) in const [
                (MemberRole.child, 'Hijo/a'),
                (MemberRole.coAdmin, 'Adulto P2'),
                (MemberRole.otherAdult, 'Conviviente'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _role == role,
                  onSelected: (_) {
                    _role = role;
                    _regenerate();
                  },
                ),
            ],
          ),
          if (_role == MemberRole.child) ...[
            const SizedBox(height: 16),
            Text('Modo de la app', style: sectionTitle(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in AgeMode.values)
                  ChoiceChip(
                    label: Text('${m.label} · ${m.ages}'),
                    selected: _mode == m,
                    onSelected: (_) {
                      _mode = m;
                      _regenerate();
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          InfoCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Pedile que abra family_app en su celular y escanee este código',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: accent, width: 3),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: Opacity(
                    opacity: expired ? 0.2 : 1,
                    child: QrImageView(
                      data: inv.qrPayload,
                      size: 196,
                      semanticsLabel: 'Código QR de invitación',
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.ink),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.ink),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('o escribí el código', style: mutedText(context).copyWith(fontWeight: FontWeight.w700)),
                      SelectableText(inv.code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  expired ? 'Código vencido · generá uno nuevo' : 'Vence en $mm:$ss',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: expired || left.inSeconds <= 60 ? const Color(0xFFB42318) : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: _regenerate, icon: const Icon(Icons.refresh), label: const Text('Generar código nuevo')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const InfoCard(
            color: Color(0xFFEEF3FF),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF1D4ED8)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'El código sirve una sola vez y vence en 15 minutos. Antes de que entre al hogar, vas a tener que confirmar el alta.',
                    style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
