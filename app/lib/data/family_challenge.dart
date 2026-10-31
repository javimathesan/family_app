part of 'family_store.dart';

/// Reto de la semana: lo elige el adulto y lo cumplen los chicos.
extension FamilyChallenge on FamilyStore {
  WeeklyChallenge? get challenge => _challenge;

  void setChallenge(WeeklyChallenge? challenge) {
    _challenge = challenge;
    sync?.homeSettingsChanged({'challenge': challenge?.toJson()});
    _changed();
  }

  /// Lunes de esta semana.
  DateTime get weekStart {
    final today = DateUtils.dateOnly(_clock());
    return today.subtract(Duration(days: today.weekday - 1));
  }

  String get _weekKey => 'reto:${FamilyStore.dayKey(weekStart)}';

  /// Cuánto lleva del reto esta semana (de lunes a hoy).
  int challengeProgress(String memberId) {
    final c = _challenge;
    if (c == null) return 0;
    final week = [for (final d in lastDays(memberId)) if (!d.date.isBefore(weekStart) && d.summary != null) d.summary!];
    return switch (c.type) {
      ChallengeType.rutina => week.where((s) => s.completionRatio >= .999).length,
      ChallengeType.agua => week.where((s) => s.glasses >= 8).length,
      ChallengeType.puntos => week.fold(0, (sum, s) => sum + s.points),
    };
  }

  bool challengeClaimed(String memberId) => memberById(memberId)?.unlocked.contains(_weekKey) ?? false;

  bool canClaimChallenge(String memberId) {
    final c = _challenge;
    return c != null && !challengeClaimed(memberId) && challengeProgress(memberId) >= c.target;
  }

  /// Cobra los puntos extra del reto (una vez por semana).
  bool claimChallenge(String memberId) {
    final m = memberById(memberId);
    final c = _challenge;
    if (m == null || c == null || !canClaimChallenge(memberId)) return false;
    m.unlocked.add(_weekKey);
    sync?.memberUpdated(m);
    _addBalance(memberId, c.bonus);
    _addNotice('${m.nickname} cumplió el reto de la semana (${c.title}): +${c.bonus} pts 🏅',
        kind: NoticeKind.reward, memberId: memberId);
    _changed();
    return true;
  }
}
