part of 'family_store.dart';

/// Una medalla de la vitrina: se gana sola, mirando lo que hizo cada uno.
class Medal {
  const Medal(this.id, this.emoji, this.title, this.how, {required this.earned});
  final String id;
  final String emoji;
  final String title;

  /// Cómo se gana (se muestra mientras no la tiene).
  final String how;
  final bool earned;
}

extension FamilyMedals on FamilyStore {
  /// Días seguidos (hasta hoy) con la rutina casi completa.
  int bestStreak(String memberId) {
    var best = 0;
    var run = 0;
    for (final d in lastDays(memberId, days: 60)) {
      if ((d.summary?.completionRatio ?? 0) >= .85) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
    }
    return best;
  }

  List<Medal> medalsOf(String memberId) {
    final m = memberById(memberId);
    if (m == null) return const [];
    final days = lastDays(memberId, days: 60);
    final anyTask = days.any((d) => (d.summary?.points ?? 0) > 0);
    final streak = bestStreak(memberId);
    final waterDays = days.where((d) => (d.summary?.glasses ?? 0) >= FamilyStore.waterGoal).length;
    final rewards = _redemptions.where((r) => r.memberId == memberId && r.status == RedemptionStatus.approved).length;
    bool won({required bool vsBot}) => _matches.any((g) =>
        g.winner != null &&
        g.players[g.winner!] == memberId &&
        (vsBot ? g.players.contains(botPlayerId) : !g.players.contains(botPlayerId)));
    final quizzes = m.unlocked.where((u) => u.startsWith('quiz:')).length;
    final outfits = m.unlocked.where((u) => u.startsWith('outfit_')).length;
    final challenges = m.unlocked.where((u) => u.startsWith('reto:')).length;
    return [
      Medal('primera', '🌟', 'Primera tarea', 'Completá tu primera tarea.', earned: anyTask),
      Medal('racha3', '🔥', 'Racha de 3', '3 días seguidos con la rutina completa.', earned: streak >= 3),
      Medal('racha7', '🏆', 'Semana perfecta', '7 días seguidos con la rutina completa.', earned: streak >= 7),
      Medal('agua', '💧', 'Bien hidratado', '5 días con 8 vasos de agua.', earned: waterDays >= 5),
      Medal('premio', '🎁', 'Primer premio', 'Canjeá tu primer premio.', earned: rewards >= 1),
      Medal('premios5', '💝', 'Coleccionista', 'Canjeá 5 premios.', earned: rewards >= 5),
      Medal('robi', '🤖', 'Le gané a Robi', 'Ganale una partida a Robi.', earned: won(vsBot: true)),
      Medal('familia', '👑', 'Campeón de la familia', 'Ganale una partida a alguien de tu familia.', earned: won(vsBot: false)),
      Medal('palabras', '🌍', 'Políglota', 'Hacé el quiz de palabras 5 días.', earned: quizzes >= 5),
      Medal('reto', '🏅', 'Reto cumplido', 'Cumplí un reto de la semana.', earned: challenges >= 1),
      Medal('moda', '👗', 'A la moda', 'Desbloqueá 3 disfraces.', earned: outfits >= 3),
      Medal('deco', '🛋️', 'Decorador', 'Poné 4 cosas en tu cuarto.', earned: roomItemsPlaced(memberId) >= 4),
      Medal('mascota', '🐾', 'Gran cuidador', 'Llevá a tu mascota al nivel 3.', earned: hasPet(memberId) && petLevel(memberId) >= 3),
    ];
  }
}
