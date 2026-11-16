import 'package:flutter/material.dart';

import '../services/android_settings.dart';
import '../services/app_version.dart';

/// Muestra qué versión tiene este teléfono y deja buscar la última.
Future<void> showVersionSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _VersionSheet(),
    );

enum _Check { idle, looking, upToDate, newer, failed }

class _VersionSheet extends StatefulWidget {
  const _VersionSheet();

  @override
  State<_VersionSheet> createState() => _VersionSheetState();
}

class _VersionSheetState extends State<_VersionSheet> {
  var _state = _Check.idle;
  AppRelease? _latest;

  Future<void> _look() async {
    setState(() => _state = _Check.looking);
    final latest = await AppVersion.fetchLatest();
    if (!mounted) return;
    setState(() {
      _latest = latest;
      _state = latest == null
          ? _Check.failed
          : AppVersion.isNewer(latest)
              ? _Check.newer
              : _Check.upToDate;
    });
  }

  Future<void> _download() async {
    final ok = await AndroidSettings.openUrl(AppVersion.downloadUrl);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir la descarga.')));
  }

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Versión de la app', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('En este teléfono: ${AppVersion.label}', key: const ValueKey('version_instalada'), style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            switch (_state) {
              _Check.idle => const SizedBox.shrink(),
              _Check.looking => const Row(children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  SizedBox(width: 12),
                  Text('Buscando…'),
                ]),
              _Check.upToDate => const Row(children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(child: Text('Tenés la última versión.', style: TextStyle(fontWeight: FontWeight.w700))),
                ]),
              _Check.newer => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hay una versión nueva: ${_latest!.version} (compilación ${_latest!.build}).',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Se descarga un archivo: abrilo y aceptá instalar. Se instala encima, sin perder nada.', style: muted),
                  ],
                ),
              _Check.failed => Text('No se pudo consultar. Revisá la conexión y probá de nuevo.', style: muted),
            },
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _state == _Check.newer
                  ? FilledButton.icon(
                      key: const ValueKey('descargar_version'),
                      onPressed: _download,
                      icon: const Icon(Icons.download),
                      label: const Text('Descargar la versión nueva'),
                    )
                  : FilledButton.tonalIcon(
                      key: const ValueKey('buscar_version'),
                      onPressed: _state == _Check.looking ? null : _look,
                      icon: const Icon(Icons.system_update),
                      label: const Text('Buscar actualización'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
