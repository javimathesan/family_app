import 'dart:async';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/app_session.dart';
import '../../data/family_cloud.dart';
import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'qr_scan_screen.dart';

/// Alta de un miembro nuevo en 3 pasos: código, apodo y aprobación del adulto.
///
/// El código se lee con la cámara ([QrScanScreen]), se escribe a mano o llega
/// en el enlace al escanear el QR con la cámara del teléfono ([initialCode]).
class JoinHomeScreen extends StatefulWidget {
  const JoinHomeScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  State<JoinHomeScreen> createState() => _JoinHomeScreenState();
}

class _JoinHomeScreenState extends State<JoinHomeScreen> {
  int _step = 0;
  final _code = TextEditingController();
  final _nick = TextEditingController();
  Invitation? _invite;
  bool _busy = false;
  String? _error;
  bool _approved = false;
  bool _rejected = false;
  StreamSubscription<bool?>? _watch;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final session = SessionScope.of(context);
    if (session.pendingApproval) {
      _step = 2;
      _listenApproval();
      return;
    }
    final code = widget.initialCode == null ? null : Invitation.parseCode(widget.initialCode!);
    if (code != null) {
      _code.text = code;
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookup(code));
    }
  }

  @override
  void dispose() {
    _watch?.cancel();
    _code.dispose();
    _nick.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (!mounted || code == null) return;
    _code.text = code;
    await _lookup(code);
  }

  Future<void> _lookup(String code) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final invite = await SessionScope.of(context).lookupInvite(code);
      if (!mounted) return;
      setState(() {
        _invite = invite;
        if (invite.isRelink) _nick.text = invite.memberName ?? '';
        _busy = false;
        _step = 1;
      });
    } on JoinException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'No se pudo consultar la invitación. Revisá la conexión a internet.';
      });
    }
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SessionScope.of(context).joinHome(_invite!, _nick.text);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = 2;
      });
      _listenApproval();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'No se pudo completar el alta. Pedí un código nuevo e intentá otra vez.';
      });
      debugPrint('Error al unirse: $e');
    }
  }

  void _listenApproval() {
    _watch?.cancel();
    _watch = SessionScope.of(context).watchApproval().listen(
      (approved) {
        if (!mounted) return;
        setState(() {
          _approved = approved == true;
          _rejected = approved == null;
        });
      },
      onError: (Object _) {
        // Al borrar el perfil pendiente, el servidor deja de permitir leerlo.
        if (mounted) setState(() => _rejected = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
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
                  0 => _codeStep(context),
                  1 => _nickStep(context),
                  _ => _waitStep(context),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorText() => _error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(_error!, style: const TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w700)),
        );

  Widget _codeStep(BuildContext context) {
    final session = SessionScope.of(context);
    final code = Invitation.parseCode(_code.text);
    if (!session.cloudAvailable) {
      return Center(
        child: Text(
          'Para unirte a un hogar hace falta conexión con el servidor. Revisá internet y volvé a abrir la app.',
          textAlign: TextAlign.center,
          style: mutedText(context).copyWith(fontSize: 16),
        ),
      );
    }
    return ListView(
      children: [
        Text('Unirme a mi hogar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Escaneá el código QR que te muestra el adulto a cargo, o escribí el código.',
            style: mutedText(context).copyWith(fontSize: 16)),
        const SizedBox(height: 16),
        Material(
          color: const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _busy ? null : _openScanner,
            child: const SizedBox(
              height: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 88),
                  SizedBox(height: 8),
                  Text('Abrir la cámara', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Código de invitación', hintText: 'FAM-XXXX', border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        _errorText(),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: code != null && !_busy ? () => _lookup(code) : null,
          child: _busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              : const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _nickStep(BuildContext context) {
    final invite = _invite!;
    final nick = _nick.text.trim();
    final who = invite.role == MemberRole.child
        ? 'hijo/a${invite.mode == null ? '' : ' · modo ${invite.mode!.label}'}'
        : invite.role.label.toLowerCase();
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
                    Text(invite.homeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('Entrás como $who', style: mutedText(context).copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (invite.isRelink)
          InfoCard(
            color: const Color(0xFFE8F1FF),
            child: Text(
              'Volvés a entrar como ${invite.memberName}, con tus puntos, tu avatar y tu historial. '
              'Un adulto del hogar lo tiene que aprobar.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          )
        else
        TextField(
          controller: _nick,
          maxLength: 16,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: '¿Cómo querés que te llamen?',
            helperText: 'Usá un apodo, no tu nombre completo.',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        _errorText(),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: nick.isEmpty || _busy ? null : _join,
          child: _busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              : Text(invite.isRelink ? 'Volver a entrar como ${invite.memberName}' : 'Unirme al hogar'),
        ),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _step = 0),
          child: const Text('No es mi hogar'),
        ),
      ],
    );
  }

  Widget _waitStep(BuildContext context) {
    final session = SessionScope.of(context);
    final store = FamilyScope.of(context);
    if (_rejected) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, size: 64, color: Color(0xFFB42318)),
          const SizedBox(height: 12),
          Text('El alta no fue aprobada', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Pedile al adulto del hogar un código nuevo.', textAlign: TextAlign.center, style: mutedText(context).copyWith(fontSize: 16)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              await session.leave();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(Routes.welcome, (_) => false);
            },
            child: const Text('Volver al inicio'),
          ),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: _approved ? const Color(0xFF16A34A) : const Color(0xFFEEF3FF),
          child: Icon(_approved ? Icons.check : Icons.schedule, size: 56, color: _approved ? Colors.white : const Color(0xFF1D4ED8)),
        ),
        const SizedBox(height: 16),
        Text(_approved ? '¡Ya sos parte del hogar!' : 'Casi listo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          _approved
              ? 'Te aprobaron en ${store.homeName}. Ahora armá tu avatar.'
              : 'Le avisamos al adulto del hogar. Pedile que abra Family App y apruebe tu alta en "Para aprobar".',
          textAlign: TextAlign.center,
          style: mutedText(context).copyWith(fontSize: 16),
        ),
        const SizedBox(height: 20),
        if (_approved)
          FilledButton(
            onPressed: () async {
              await session.markApproved();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(Routes.avatar, (_) => false);
            },
            child: const Text('Crear mi avatar'),
          )
        else
          const CircularProgressIndicator(),
      ],
    );
  }
}
