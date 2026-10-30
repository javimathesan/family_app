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
  void taskChanged(String memberId, String day, String taskId, TaskCompletion? completion);
  void healthChanged(String memberId, String day, HealthLog log);
  void balanceChanged(String memberId, int delta);
  void redemptionSaved(Redemption redemption);
  void noticeAdded(FamilyNotice notice);
}
