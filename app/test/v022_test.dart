import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Mi día: cada adulto arma, suma y borra sus metas', () {
    final store = FamilyStore.demo(clock: () => DateTime(2026, 11, 9, 9));
    final mama = store.addMember(nickname: 'Mamá', role: MemberRole.admin);
    expect(store.myGoals(mama.id), isEmpty, reason: 'arranca sin metas');
    expect(store.myGoals('adulto').length, 6, reason: 'la demo trae ideas de ejemplo');

    final propia = AdultGoal(store.newGoalId(), 'Revisar la agenda del colegio', '📒');
    store.setMyGoals(mama.id, [AdultGoal.all.first, propia]);
    expect(store.myGoals(mama.id).length, 2);
    expect(store.toggleAdultGoal(mama.id, propia.id), isTrue);
    expect(store.adultGoalsDone(mama.id), 1);

    store.setMyGoals(mama.id, [propia]);
    expect(store.myGoals(mama.id).single.label, 'Revisar la agenda del colegio');
    expect(store.myGoals('adulto').length, 6, reason: 'no toca las de otro adulto');

    final ida = MemberLook.fromJson(store.memberById(mama.id)!.look.toJson());
    expect(ida.goals, [propia]);
    expect(store.memberById(mama.id)!.unlocked.contains('paso:color'), isFalse);
  });
}
