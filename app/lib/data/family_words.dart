part of 'family_store.dart';

/// Avance en Palabras: estrellas por tema, escalera de temas y repaso.
extension FamilyWords on FamilyStore {
  static String _starKey(Lang lang, String topicId) => 's:${lang.name}:$topicId';
  static String _missKey(Lang lang, String topicId, String es) => 'm:${lang.name}:$topicId:$es';

  /// Estrellas de un tema (0 a 3): 3 con 5 de 5, 2 con 4, 1 con 3.
  int topicStars(String memberId, Lang lang, String topicId) {
    final best = memberById(memberId)?.progress[_starKey(lang, topicId)] ?? 0;
    return best >= 5 ? 3 : (best == 4 ? 2 : (best == 3 ? 1 : 0));
  }

  int starsInLevel(String memberId, Lang lang, WordLevel level) =>
      topicsOf(level).fold(0, (sum, t) => sum + topicStars(memberId, lang, t.id));

  /// Los adultos tienen todo abierto; los chicos avanzan en escalera: el
  /// siguiente tema se abre con 2 estrellas (4 de 5) en el anterior.
  bool topicUnlocked(String memberId, Lang lang, Topic topic) {
    if (memberById(memberId)?.role.isAdult ?? true) return true;
    if (!levelUnlocked(memberId, lang, topic.level)) return false;
    final list = topicsOf(topic.level);
    final i = list.indexWhere((t) => t.id == topic.id);
    if (i <= 0) return true;
    return topicStars(memberId, lang, list[i - 1].id) >= 2;
  }

  /// El nivel medio se abre con 2 estrellas en 5 temas del básico. El
  /// avanzado depende de Family App Plus (se controla en la pantalla).
  bool levelUnlocked(String memberId, Lang lang, WordLevel level) {
    if (memberById(memberId)?.role.isAdult ?? true) return true;
    if (level != WordLevel.medio) return true;
    final good = topicsOf(WordLevel.basico).where((t) => topicStars(memberId, lang, t.id) >= 2).length;
    return good >= 5;
  }

  /// Guarda el resultado de un quiz: el mejor puntaje y qué palabras repasar.
  void recordQuiz(String memberId, Lang lang, String topicId, {required int score, required List<Word> right, required List<Word> wrong}) {
    final m = memberById(memberId);
    if (m == null) return;
    if (topicId != reviewTopicId) {
      final key = _starKey(lang, topicId);
      if (score > (m.progress[key] ?? 0)) m.progress[key] = score;
    }
    for (final w in right) {
      m.progress.removeWhere((k, _) => k.startsWith('m:${lang.name}:') && k.endsWith(':${w.es}'));
    }
    final misses = m.progress.keys.where((k) => k.startsWith('m:')).length;
    for (final w in wrong.take(max(0, 60 - misses))) {
      final topic = topicId == reviewTopicId ? _topicOf(w)?.id ?? 'x' : topicId;
      m.progress[_missKey(lang, topic, w.es)] = 1;
    }
    sync?.memberUpdated(m);
    _changed();
  }

  Topic? _topicOf(Word w) {
    for (final t in topics) {
      if (t.words.contains(w)) return t;
    }
    return null;
  }

  /// Palabras que se equivocó y conviene repasar.
  List<Word> reviewWords(String memberId, Lang lang) {
    final m = memberById(memberId);
    if (m == null) return const [];
    final out = <Word>[];
    for (final k in m.progress.keys.where((k) => k.startsWith('m:${lang.name}:'))) {
      final parts = k.split(':');
      if (parts.length < 4) continue;
      final es = parts.sublist(3).join(':');
      for (final t in topics.where((t) => t.id == parts[2])) {
        out.addAll(t.words.where((w) => w.es == es));
      }
    }
    return out;
  }

  /// Récord personal de un juego (por ejemplo, tiro al blanco).
  int bestScore(String memberId, String game) => memberById(memberId)?.progress['r:$game'] ?? 0;

  /// Guarda un puntaje. Devuelve `true` si es un récord nuevo.
  bool saveScore(String memberId, String game, int score) {
    final m = memberById(memberId);
    if (m == null || score <= bestScore(memberId, game)) return false;
    m.progress['r:$game'] = score;
    sync?.memberUpdated(m);
    _changed();
    return true;
  }
}

/// Tema especial para el repaso.
const reviewTopicId = 'repaso';
