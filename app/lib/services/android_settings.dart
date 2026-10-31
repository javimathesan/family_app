import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Abre pantallas de ajustes de Android.
abstract final class AndroidSettings {
  static const _channel = MethodChannel('familyapp/settings');

  /// [screen]: `app` (datos de la app), `battery` (optimización de batería) o `tts` (voces).
  static Future<bool> open(String screen) async {
    try {
      return await _channel.invokeMethod<bool>('open', {'screen': screen}) ?? false;
    } catch (error) {
      debugPrint('No se pudo abrir los ajustes: $error');
      return false;
    }
  }
}
