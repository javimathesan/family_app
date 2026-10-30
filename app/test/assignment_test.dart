import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime clock() => DateTime(2026, 10, 30, 7, 25);
  late FamilyStore store;
  setUp(() => store = FamilyStore.demo(clock: clock));

  group('tareas asignadas por hijo', () {
    test('una tarea solo para Tomi no aparece en la rutina de Luli', () {
      store.saveTemplate(const TaskTemplate(
        id: 'perro',
        name: 'Pasear al perro',
        block: DayBlock.afternoon,
        time: TimeOfDay(hour: 16, minute: 0),
        points: 8,
        assignedTo: {'tomi'},
      ));
      expect(store.tasksFor(DayBlock.afternoon, memberId: 'tomi').any((t) => t.id == 'perro'), isTrue);
      expect(store.tasksFor(DayBlock.afternoon, memberId: 'luli').any((t) => t.id == 'perro'), isFalse);
      expect(store.templatesFor('tomi').length, store.templatesFor('luli').length + 1);
    });

    test('el progreso de cada hijo cuenta solo sus tareas', () {
      for (final t in store.templates) {
        store.saveTemplate(t.copyWith(assignedTo: {'luli'}));
      }
      store.saveTemplate(const TaskTemplate(
        id: 'solo_mati',
        name: 'Ordenar el cuarto',
        block: DayBlock.morning,
        time: TimeOfDay(hour: 7, minute: 0),
        points: 5,
        assignedTo: {'mati'},
      ));
      store.toggleTask('mati', 'solo_mati');
      expect(store.templatesFor('mati').length, 1);
      expect(store.completionRatio('mati'), 1.0);
    });

    test('la asignación se guarda y se recupera', () {
      final cama = store.templates.firstWhere((t) => t.id == 'cama');
      store.saveTemplate(cama.copyWith(assignedTo: {'tomi', 'luli'}));
      final copia = FamilyStore.empty(clock: clock)..restoreFrom(store.toJson());
      expect(copia.templates.firstWhere((t) => t.id == 'cama').assignedTo, {'tomi', 'luli'});
    });
  });

  group('mi día del adulto', () {
    test('marcar metas no da puntos ni cuenta como tarea', () {
      expect(store.toggleAdultGoal('adulto', 'meta_ejercicio'), isTrue);
      expect(store.toggleAdultGoal('adulto', 'meta_lectura'), isTrue);
      expect(store.adultGoalsDone('adulto'), 2);
      expect(store.balanceOf('adulto'), 0);
      expect(store.doneToday('adulto'), 0);
      expect(store.pendingTaskApprovals, isEmpty);
    });

    test('desmarcar una meta la saca', () {
      store.toggleAdultGoal('adulto', 'meta_ejercicio');
      expect(store.toggleAdultGoal('adulto', 'meta_ejercicio'), isFalse);
      expect(store.adultGoalsDone('adulto'), 0);
    });

    test('jugar con los hijos se avisa al hogar', () {
      store.toggleAdultGoal('adulto', 'meta_jugar');
      expect(store.notices.first.text, 'Papá jugó con sus hijos');
    });

    test('todas las metas tienen el prefijo meta_ y son únicas', () {
      final ids = AdultGoal.all.map((g) => g.id).toList();
      expect(ids.every(AdultGoal.isGoalId), isTrue);
      expect(ids.toSet().length, ids.length);
    });
  });
}
