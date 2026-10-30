import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/app_session.dart';
import '../../widgets/common.dart';

/// El adulto crea el hogar compartido; queda como administrador.
class CreateHomeScreen extends StatefulWidget {
  const CreateHomeScreen({super.key});

  @override
  State<CreateHomeScreen> createState() => _CreateHomeScreenState();
}

class _CreateHomeScreenState extends State<CreateHomeScreen> {
  final _home = TextEditingController();
  final _nick = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _home.dispose();
    _nick.dispose();
    super.dispose();
  }

  bool get _valid => _home.text.trim().isNotEmpty && _nick.text.trim().isNotEmpty;

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SessionScope.of(context).createHome(homeName: _home.text, nickname: _nick.text);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.adult, (_) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'No se pudo crear el hogar. Revisá la conexión a internet e intentá de nuevo.';
      });
      debugPrint('Error al crear el hogar: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear mi hogar', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('Vas a ser el administrador. Después sumás al resto con un QR desde tu panel.',
              style: mutedText(context).copyWith(fontSize: 15)),
          const SizedBox(height: 20),
          TextField(
            controller: _home,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre del hogar',
              hintText: 'Por ejemplo: Familia Pérez',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nick,
            maxLength: 16,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: '¿Cómo te llaman en casa?',
              hintText: 'Por ejemplo: Papá, Mamá, Javi',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: _valid && !_busy ? _create : null,
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : const Text('Crear hogar'),
          ),
        ],
      ),
    );
  }
}
