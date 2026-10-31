import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'vocabulary.dart';

/// Paquetes de palabras que se suman desde Firebase (colección `vocab`), sin
/// publicar una versión nueva de la app. Se guardan en el teléfono para que
/// estén aunque no haya internet.
abstract final class VocabPacks {
  static const _key = 'vocab_packs';

  static void loadCached(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      _apply((jsonDecode(raw) as List).cast<Map<String, dynamic>>());
    } catch (error) {
      debugPrint('Paquetes de palabras guardados con error: $error');
    }
  }

  static Future<void> refresh(FirebaseFirestore db, SharedPreferences prefs) async {
    try {
      final snap = await db.collection('vocab').get();
      final packs = [for (final d in snap.docs) if (d.data()['active'] != false) {...d.data(), 'id': d.data()['id'] ?? d.id}];
      packs.sort((a, b) => ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0));
      _apply(packs);
      await prefs.setString(_key, jsonEncode(packs));
    } catch (error) {
      debugPrint('No se pudieron bajar los paquetes de palabras: $error');
    }
  }

  static void _apply(List<Map<String, dynamic>> packs) {
    extraTopics = [for (final p in packs) if (topicFromJson(p) case final t?) t];
  }
}
