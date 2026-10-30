import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'family_store.dart';

/// Guarda el estado del hogar en el teléfono.
///
/// Usa shared_preferences (un JSON por hogar). Alcanza para la v1; cuando haya
/// backend se reemplaza por una base local con sincronización.
class FamilyStorage {
  FamilyStorage(this._prefs);

  static const key = 'family_state_v1';

  final SharedPreferences _prefs;

  static Future<FamilyStorage> open() async => FamilyStorage(await SharedPreferences.getInstance());

  /// Carga lo guardado (si hay) y guarda automáticamente cada cambio.
  void attach(FamilyStore store) {
    load(store);
    store.addListener(() => save(store));
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
