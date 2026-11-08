import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime viernes() => DateTime(2026, 11, 6, 7);
  DateTime sabado() => DateTime(2026, 11, 7, 9);

  test('cada hijo tiene su horario sin repetir la tarea', () {
    final store = FamilyStore.demo(clock: viernes);
    final antes = store.templates.length;
    store.setTaskSlot('levantarse', 'mati',
        const TaskSlot(time: TimeOfDay(hour: 6, minute: 30), weekendTime: TimeOfDay(hour: 10, minute: 0), points: 8));
    expect(store.templates.length, antes);
    final mati = store.templatesFor('mati').firstWhere((t) => t.id == 'levantarse');
    final tomi = store.templatesFor('tomi').firstWhere((t) => t.id == 'levantarse');
    expect(mati.time, const TimeOfDay(hour: 6, minute: 30));
    expect(mati.points, 8);
    expect(tomi.time, const TimeOfDay(hour: 7, minute: 0));
    final finde = store.templatesFor('mati', on: sabado()).firstWhere((t) => t.id == 'levantarse');
    expect(finde.time, const TimeOfDay(hour: 10, minute: 0));
    final tomiFinde = store.templatesFor('tomi', on: sabado()).firstWhere((t) => t.id == 'levantarse');
    expect(tomiFinde.time, const TimeOfDay(hour: 9, minute: 0));

    // Se guarda y vuelve igual.
    final t = store.templates.firstWhere((t) => t.id == 'levantarse');
    final ida = FamilyStore.templateFromJson(FamilyStore.templateToJson(t));
    expect(ida.slotFor('mati').weekendTime, const TimeOfDay(hour: 10, minute: 0));
    expect(ida.weekendTime, const TimeOfDay(hour: 9, minute: 0));

    // "Para todos" deja un solo horario.
    store.setTaskSlot('levantarse', 'mati', const TaskSlot(time: TimeOfDay(hour: 6, minute: 45), points: 5), forAll: true);
    expect(store.templatesFor('tomi').firstWhere((t) => t.id == 'levantarse').time, const TimeOfDay(hour: 6, minute: 45));
  });

  test('quitar, copiar y borrar al quedar sin nadie', () {
    final store = FamilyStore.demo(clock: viernes);
    store.unassignTask('cama', 'luli');
    expect(store.routineOf('luli').any((t) => t.id == 'cama'), isFalse);
    expect(store.routineOf('tomi').any((t) => t.id == 'cama'), isTrue);
    store.unassignTask('cama', 'tomi');
    store.unassignTask('cama', 'mati');
    expect(store.templates.any((t) => t.id == 'cama'), isFalse);

    store.saveTemplate(const TaskTemplate(id: 'perro', name: 'Pasear al perro', block: DayBlock.afternoon,
        time: TimeOfDay(hour: 18, minute: 0), points: 5, assignedTo: {'mati'}));
    store.copyRoutine('mati', ['luli']);
    expect(store.routineOf('luli').any((t) => t.id == 'perro'), isTrue);
    expect(store.routineOf('tomi').any((t) => t.id == 'perro'), isFalse);
  });

  test('premios por hijo con costo propio', () {
    final store = FamilyStore.demo(clock: viernes);
    store.saveReward(const Reward(id: 'cel', name: 'Celular el finde', cost: 200, assignedTo: {'mati'}, costs: {'mati': 250}));
    expect(store.rewardsFor('tomi').any((r) => r.id == 'cel'), isFalse);
    expect(store.rewardsFor('mati').firstWhere((r) => r.id == 'cel').cost, 250);
    final ida = FamilyStore.rewardFromJson(FamilyStore.rewardToJson(store.rewardById('cel')!));
    expect(ida.costFor('mati'), 250);
    expect(ida.assignedTo, {'mati'});
  });

  test('hogar sin tareas: la lista sugerida y los primeros pasos', () {
    final store = FamilyStore.demo(clock: viernes);
    for (final t in [...store.templates]) {
      store.removeTemplate(t.id);
    }
    for (final r in [...store.rewards]) {
      store.removeReward(r.id);
    }
    expect(store.templatesFor('tomi'), isEmpty);
    expect(store.childrenWithoutTasks().length, 3);
    final ideas = [for (final s in FamilyStore.suggestedTasks) if (s.ages.contains(AgeMode.peques)) s.task];
    store.addSuggestedTasks('luli', ideas.take(3));
    expect(store.routineOf('luli').length, 3);
    expect(store.routineOf('tomi'), isEmpty);
    expect(store.childrenWithoutTasks().map((m) => m.id), isNot(contains('luli')));
    store.addSuggestedRewards('luli', [FamilyStore.suggestedRewards.first.reward]);
    expect(store.rewardsFor('luli').length, 1);
    expect(store.childrenWithoutRewards().map((m) => m.id), isNot(contains('luli')));
  });
}
