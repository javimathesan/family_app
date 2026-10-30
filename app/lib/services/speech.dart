import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Lee palabras en voz alta con la voz del teléfono.
///
/// Si el teléfono no tiene la voz de ese idioma, no pasa nada (no se rompe).
class Speech {
  Speech._();
  static final instance = Speech._();

  FlutterTts? _tts;

  Future<void> say(String text, String locale) async {
    try {
      final tts = _tts ??= FlutterTts();
      await tts.stop();
      await tts.setLanguage(locale);
      await tts.setSpeechRate(0.4);
      await tts.speak(text);
    } catch (error) {
      debugPrint('No se pudo leer en voz alta: $error');
    }
  }
}
