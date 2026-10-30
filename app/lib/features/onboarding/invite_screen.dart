import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/app_session.dart';
import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// El adulto genera un QR de invitación de un solo uso que vence en 15 minutos.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key, this.relinkMemberId});

  /// Si viene, el QR es para que ese perfil vuelva a entrar desde un teléfono nuevo.
  final String? relinkMemberId;

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  MemberRole _role = MemberRole.child;
  AgeMode _mode = AgeMode.junior;
  Invitation? _invitation;
  bool _loading = false;
  String? _error;
  Timer? _ticker;
  int _request = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_invitation == null && !_loading && _error == null) _regenerate();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _regenerate() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final relink = widget.relinkMemberId == null ? null : FamilyScope.of(context).memberById(widget.relinkMemberId!);
      final inv = await SessionScope.of(context).createInvitation(
        role: relink?.role ?? _role,
        ageMode: relink?.mode ?? (_role == MemberRole.child ? _mode : null),
        relink: relink,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _invitation = inv;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo crear la invitación. Revisá la conexión a internet.';
      });
      debugPrint('Error al crear la invitación: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final session = SessionScope.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final inv = _invitation;
    final relinkName = widget.relinkMemberId == null ? null : store.memberById(widget.relinkMemberId!)?.nickname;

    return Scaffold(
      appBar: AppBar(
        title: Text(relinkName == null ? 'Sumar a alguien' : 'Teléfono nuevo', style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          if (relinkName != null)
            InfoCard(
              color: const Color(0xFFE8F1FF),
              child: Text(
                '$relinkName vuelve a entrar con su perfil de siempre: puntos, avatar e historial. '
                'El teléfono anterior deja de tener acceso al hogar.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          if (relinkName == null) ...[
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
          ],
          const SizedBox(height: 16),
          InfoCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'En el otro celular: instalá Family App, tocá "Me invitaron" y escaneá este código. '
                  'También lo podés escanear con la cámara del teléfono.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 12),
                if (_loading && inv == null)
                  const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()))
                else if (_error != null)
                  SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w700)),
                    ),
                  )
                else if (inv != null)
                  _QrBlock(invitation: inv, now: store.now, accent: accent, faded: _loading),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _regenerate,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generar código nuevo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InfoCard(
            color: const Color(0xFFEEF3FF),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF1D4ED8)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    session.isDemo
                        ? 'Estás en la demostración: el código no conecta otros teléfonos. Para eso, creá tu hogar real.'
                        : 'El código sirve una sola vez y vence en 15 minutos. Antes de que entre al hogar, '
                            'vas a tener que aprobar el alta desde tu panel.',
                    style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
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

class _QrBlock extends StatelessWidget {
  const _QrBlock({required this.invitation, required this.now, required this.accent, required this.faded});

  final Invitation invitation;
  final DateTime now;
  final Color accent;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final left = invitation.expiresAt.difference(now);
    final expired = left.isNegative;
    final mm = left.inMinutes;
    final ss = (left.inSeconds % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: accent, width: 3),
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Opacity(
            opacity: expired || faded ? 0.2 : 1,
            child: QrImageView(
              data: invitation.qrPayload,
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
              SelectableText(invitation.code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
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
      ],
    );
  }
}
