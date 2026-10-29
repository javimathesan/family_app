import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// Alta de un miembro nuevo en 3 pasos: escanear, apodo y esperar confirmación.
///
/// El escaneo real con cámara (paquete mobile_scanner) queda para la próxima
/// iteración; por ahora se puede escribir el código o simular el escaneo.
class JoinHomeScreen extends StatefulWidget {
  const JoinHomeScreen({super.key});

  @override
  State<JoinHomeScreen> createState() => _JoinHomeScreenState();
}

class _JoinHomeScreenState extends State<JoinHomeScreen> {
  int _step = 0;
  final _code = TextEditingController();
  final _nick = TextEditingController();
  String? _memberId;

  @override
  void dispose() {
    _code.dispose();
    _nick.dispose();
    super.dispose();
  }

  static final _codePattern = RegExp(r'^FAM-[A-Z0-9]{4}$');

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final approved = _memberId != null && !store.isPendingMember(_memberId!);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('PASO ${_step + 1} DE 3', style: mutedText(context).copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: _step >= i ? accent : const Color(0xFFD5D9E4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: switch (_step) {
                  0 => _scanStep(context),
                  1 => _nickStep(context, store),
                  _ => _waitStep(context, store, approved),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scanStep(BuildContext context) {
    final valid = _codePattern.hasMatch(_code.text.trim().toUpperCase());
    return ListView(
      children: [
        Text('Unirme a mi hogar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Apuntá la cámara al código QR que te muestra el adulto a cargo, o escribí el código.',
            style: mutedText(context).copyWith(fontSize: 16)),
        const SizedBox(height: 16),
        Container(
          height: 220,
          decoration: BoxDecoration(color: const Color(0xFF1E2235), borderRadius: BorderRadius.circular(28)),
          child: const Center(child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 96, semanticLabel: 'Visor de la cámara')),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Código de invitación', hintText: 'FAM-XXXX', border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: valid ? () => setState(() => _step = 1) : null, child: const Text('Continuar')),
        TextButton(
          onPressed: () => setState(() {
            _code.text = 'FAM-DEMO';
            _step = 1;
          }),
          child: const Text('Simular escaneo (demo)'),
        ),
      ],
    );
  }

  Widget _nickStep(BuildContext context, FamilyStore store) {
    final nick = _nick.text.trim();
    return ListView(
      children: [
        Text('¡Te invitaron!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        InfoCard(
          child: Row(
            children: [
              const Icon(Icons.home_outlined, size: 36, color: Color(0xFF9A6700)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.homeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('Entrás como hijo/a · modo Junior', style: mutedText(context).copyWith(fontWeight: FontWeight.w700)),
                    Text('Ya hay ${store.members.length} miembros', style: mutedText(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nick,
          maxLength: 16,
          decoration: const InputDecoration(
            labelText: '¿Cómo querés que te llamen?',
            helperText: 'Usá un apodo, no tu nombre completo.',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: nick.isEmpty
              ? null
              : () {
                  final m = store.addPendingMember(nickname: nick, role: MemberRole.child, mode: AgeMode.junior);
                  setState(() {
                    _memberId = m.id;
                    _step = 2;
                  });
                },
          child: const Text('Unirme al hogar'),
        ),
        TextButton(onPressed: () => setState(() => _step = 0), child: const Text('No es mi hogar')),
      ],
    );
  }

  Widget _waitStep(BuildContext context, FamilyStore store, bool approved) {
    final nick = _nick.text.trim();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: approved ? const Color(0xFF16A34A) : const Color(0xFFEEF3FF),
          child: Icon(approved ? Icons.check : Icons.schedule, size: 56, color: approved ? Colors.white : const Color(0xFF1D4ED8)),
        ),
        const SizedBox(height: 16),
        Text(approved ? '¡Bienvenido, $nick!' : 'Casi listo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          approved
              ? 'Ya sos parte del ${store.homeName}. Ahora armá tu avatar.'
              : 'Le avisamos al adulto del hogar. Cuando confirme tu alta, vas a poder empezar.',
          textAlign: TextAlign.center,
          style: mutedText(context).copyWith(fontSize: 16),
        ),
        const SizedBox(height: 20),
        if (!approved)
          OutlinedButton(onPressed: () => store.confirmMember(_memberId!), child: const Text('Simular: el adulto aprueba'))
        else
          FilledButton(
            onPressed: () {
              store.signInAs(_memberId!);
              Navigator.of(context).pushReplacementNamed(Routes.avatar);
            },
            child: const Text('Crear mi avatar'),
          ),
      ],
    );
  }
}
