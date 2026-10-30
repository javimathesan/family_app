import 'package:flutter/material.dart';

import '../data/app_session.dart';

/// Pide un PIN de 4 dígitos. Devuelve el PIN o `null` si se canceló.
Future<String?> showPinDialog(BuildContext context, {required String title, String? message}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PinDialog(title: title, message: message),
  );
}

/// Pide el PIN del modo adulto si este teléfono tiene uno. Devuelve `true`
/// si se puede seguir (sin PIN o PIN correcto).
Future<bool> confirmAdultPin(BuildContext context) async {
  final session = SessionScope.of(context);
  if (!session.hasPin) return true;
  final pin = await showPinDialog(context, title: 'PIN del modo adulto', message: 'Ingresá el PIN para entrar.');
  if (pin == null) return false;
  if (session.checkPin(pin)) return true;
  if (context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('PIN incorrecto')));
  }
  return false;
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.title, this.message});

  final String title;
  final String? message;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = AppSession.isValidPin(_pin.text);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(widget.message!),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _pin,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w800),
            decoration: const InputDecoration(border: OutlineInputBorder(), counterText: '', hintText: '••••'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (AppSession.isValidPin(_pin.text)) Navigator.pop(context, _pin.text);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: valid ? () => Navigator.pop(context, _pin.text) : null, child: const Text('Aceptar')),
      ],
    );
  }
}
