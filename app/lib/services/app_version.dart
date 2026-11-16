import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Versión publicada más nueva.
class AppRelease {
  const AppRelease({required this.version, required this.build});
  final String version;
  final int build;
}

/// Versión instalada en este teléfono y dónde buscar la última.
///
/// La versión y el número de compilación los pone GitHub al armar la app
/// (`--dart-define`). Al correrla desde la PC queda "desarrollo".
abstract final class AppVersion {
  static const name = String.fromEnvironment('APP_VERSION', defaultValue: 'desarrollo');
  static const build = int.fromEnvironment('APP_BUILD');

  static String get label => build == 0 ? name : '$name (compilación $build)';

  // Mientras la app no esté en Google Play, la última versión está en GitHub.
  // Cuando se publique, [downloadUrl] pasa a ser la ficha de Play.
  static const _base = 'https://github.com/javimathesan/family_app/releases/download/prueba';
  static const latestUrl = '$_base/version.json';
  static const downloadUrl = '$_base/family-app.apk';

  /// Hay una más nueva que la instalada.
  static bool isNewer(AppRelease latest) => build != 0 && latest.build > build;

  /// Consulta la última versión publicada. `null` si no se pudo (sin conexión).
  /// Se puede reemplazar en las pruebas.
  static Future<AppRelease?> Function() fetchLatest = _fetch;

  static Future<AppRelease?> _fetch() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(Uri.parse(latestUrl));
      final response = await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 15));
      return parse(body);
    } catch (error) {
      debugPrint('No se pudo consultar la última versión: $error');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static AppRelease? parse(String body) {
    try {
      final j = jsonDecode(body);
      if (j is! Map || j['version'] is! String || j['build'] is! num) return null;
      return AppRelease(version: j['version'] as String, build: (j['build'] as num).toInt());
    } catch (_) {
      return null;
    }
  }
}
