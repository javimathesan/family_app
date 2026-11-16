import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dos partidas iguales abiertas a la vez quedan en una', () {
    final store = FamilyStore.demo(clock: () => DateTime(2026, 11, 15, 22));
    final a = store.createMatch(GameKind.colorin, ['tomi', 'luli'], id: 'g1r');
    final b = store.createMatch(GameKind.colorin, ['luli', 'tomi'], id: 'g9');
    // Llegan las dos desde la nube (cada teléfono creó la suya).
    store.applyRemote(matches: [a, b]);
    final abiertas = store.matches.where((m) => m.kind == GameKind.colorin && !m.finished).toList();
    expect(abiertas, hasLength(1));
    // El que tenía abierta la borrada llega a la que quedó.
    final otra = abiertas.single.id == 'g1r' ? 'g9' : 'g1r';
    expect(store.matchById(otra)?.id, abiertas.single.id);
  });

  test('si una ya tiene jugadas, queda esa y no se borra nada jugado', () {
    final store = FamilyStore.demo(clock: () => DateTime(2026, 11, 15, 22));
    final a = store.createMatch(GameKind.tateti, ['tomi', 'luli'], id: 'x1');
    final b = store.createMatch(GameKind.tateti, ['luli', 'tomi'], id: 'x2');
    b.lastBy = 'luli';
    store.applyRemote(matches: [a, b]);
    expect(store.matches.where((m) => m.kind == GameKind.tateti).map((m) => m.id), ['x2']);
  });

  test('los juegos de entrada no llevan la etiqueta Nuevo', () {
    for (final k in GameKind.values) {
      expect(k.isNewOn(DateTime(2026, 11, 15)), isFalse);
    }
  });
}
