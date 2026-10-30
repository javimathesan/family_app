import '../models/models.dart';

/// Recibe cada cambio local del [FamilyStore] para enviarlo al servidor.
///
/// El store aplica el cambio en el momento (la pantalla responde al instante)
/// y avisa acá; la implementación lo escribe en la nube. Lo que llega desde
/// otros teléfonos entra por `FamilyStore.applyRemote`, que no vuelve a avisar.
abstract class FamilySync {
  void memberAdded(Member member);
  void memberUpdated(Member member);
  void memberConfirmed(Member member);
  void memberRemoved(Member member);

  /// Se rechazó el teléfono nuevo de un perfil existente.
  void relinkCancelled(Member member);
  void taskChanged(String memberId, String day, String taskId, TaskCompletion? completion);
  void healthChanged(String memberId, String day, HealthLog log);
  void balanceChanged(String memberId, int delta);
  void redemptionSaved(Redemption redemption);
  void noticeAdded(FamilyNotice notice);

  /// El adulto cambió la rutina (se envía la lista completa).
  void routineChanged(List<TaskTemplate> templates);

  /// El adulto cambió los premios (se envía la lista completa).
  void rewardsChanged(List<Reward> rewards);

  /// Se creó una partida o alguien jugó.
  void matchSaved(GameMatch match);
  void matchRemoved(String matchId);

  /// El adulto cambió cuándo pueden jugar los chicos.
  void gamesRuleChanged(GamesRule rule);

  /// Cambió una configuración del hogar (minutos de juego, idiomas…).
  void homeSettingsChanged(Map<String, dynamic> fields);

  /// Tiempo de juego de hoy de un chico, en segundos.
  void gameTimeChanged(String memberId, String day, int seconds);
}
