import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'family_store.dart';

/// Guarda el hogar de demostración en el teléfono (un JSON).
///
/// Conectado a la nube no se usa: Firestore ya guarda una copia local y
/// funciona sin conexión.
class FamilyStorage {
  FamilyStorage(this._prefs);

  static const key = 'family_state_v1';

  final SharedPreferences _prefs;

  /// Si es `false`, los cambios no se guardan (modo nube o sin hogar).
  bool enabled = true;

  bool _listening = false;

  static Future<FamilyStorage> open() async => FamilyStorage(await SharedPreferences.getInstance());

  /// Carga lo guardado (si hay) y guarda automáticamente cada cambio.
  void attach(FamilyStore store) {
    load(store);
    listen(store);
  }

  /// Guarda automáticamente cada cambio mientras [enabled] sea `true`.
  void listen(FamilyStore store) {
    if (_listening) return;
    _listening = true;
    store.addListener(() {
      if (enabled) save(store);
    });
  }

  /// Devuelve `true` si había datos guardados y se pudieron leer.
  bool load(FamilyStore store) {
    final raw = _prefs.getString(key);
    if (raw == null) return false;
    try {
      store.restoreFrom(jsonDecode(raw) as Map<String, dynamic>);
      return true;
    } catch (error) {
      // Datos corruptos o de un formato viejo: se descartan y se sigue con la demo.
      debugPrint('No se pudieron leer los datos guardados: $error');
      _prefs.remove(key);
      return false;
    }
  }

  Future<void> save(FamilyStore store) => _prefs.setString(key, jsonEncode(store.toJson()));

  Future<void> clear() => _prefs.remove(key);
}
