import 'package:family_app/games/barrio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el tablero tiene 20 casillas y las esquinas son especiales', () {
    expect(Barrio.squares.length, 20);
    expect(Barrio.squares[0].type, BarrioType.start);
    expect(Barrio.squares[10].type, BarrioType.siesta);
    expect(Barrio.squares[15].type, BarrioType.fountain);
  });

  test('cae en un lugar libre, lo compra y le toca al otro', () {
    final s = BarrioState.initial(2);
    final step = s.roll(0, 1, 1, 0); // casilla 2: Panadería
    expect(step.state.buying, isTrue);
    expect(step.nextTurn, 0);
    final bought = step.state.decide(0, buy: true);
    expect(bought.state.owners[2], 0);
    expect(bought.state.cash[0], Barrio.startCash - 25);
    expect(bought.nextTurn, 1);
    expect(bought.state.message, contains('compró Panadería'));
  });

  test('alquiler simple y doble con el grupo completo', () {
    final s = BarrioState.initial(2)
      ..owners[2] = 0
      ..pos[1] = 0;
    final simple = s.roll(1, 1, 1, 0);
    expect(simple.state.cash[1], Barrio.startCash - Barrio.baseRent(2));
    expect(simple.state.cash[0], Barrio.startCash + Barrio.baseRent(2));

    final full = BarrioState.initial(2)
      ..owners[1] = 0
      ..owners[2] = 0;
    final doble = full.roll(1, 1, 1, 0);
    expect(doble.state.cash[1], Barrio.startCash - 2 * Barrio.baseRent(2));
  });

  test('pasar por la Salida cobra 20 y el impuesto va al pozo de la fuente', () {
    final s = BarrioState.initial(2)..pos[0] = 15;
    // 15 + 2 = 17: impuesto.
    final tax = s.roll(0, 1, 1, 0);
    expect(tax.state.pot, Barrio.tax);
    // 17 + 3 = 20 → 0: pasa por la Salida.
    final start = tax.state.roll(1, 6, 6, 0); // el otro jugador: 0 + 12 = 12 (Pileta)
    expect(start.state.buying, isTrue);
    final passed = (BarrioState.initial(2)..pos[0] = 18).roll(0, 1, 2, 0);
    expect(passed.state.cash[0], Barrio.startCash + Barrio.passStart);
  });

  test('la fuente entrega el pozo', () {
    final s = BarrioState.initial(2)
      ..pot = 30
      ..pos[0] = 12;
    final step = s.roll(0, 1, 2, 0);
    expect(step.state.pos[0], 15);
    expect(step.state.cash[0], Barrio.startCash + 30);
    expect(step.state.pot, 0);
  });

  test('la siesta hace perder el próximo turno', () {
    final s = BarrioState.initial(3)..pos[0] = 8;
    final sleep = s.roll(0, 1, 1, 0);
    expect(sleep.state.skip[0], isTrue);
    expect(sleep.nextTurn, 1);
    final p1 = sleep.state.roll(1, 2, 3, 0); // 5: Plaza
    final p2 = p1.state.roll(2, 2, 3, 0);
    expect(p2.nextTurn, 1, reason: 'el jugador 0 se saltea');
    expect(p2.state.skip[0], isFalse);
  });

  test('sin monedas sale del juego y gana el que queda', () {
    final s = BarrioState.initial(2)
      ..owners[19] = 0
      ..owners[16] = 0
      ..owners[18] = 0
      ..cash[1] = 10
      ..pos[1] = 17;
    final step = s.roll(1, 1, 1, 0); // Castillo con grupo completo: alquiler 54
    expect(step.state.out[1], isTrue);
    expect(step.winner, 0);
  });

  test('al terminar los turnos gana el más rico', () {
    final s = BarrioState.initial(2)
      ..turnsLeft = 1
      ..cash[0] = 300;
    final step = s.roll(0, 2, 3, 0); // Plaza
    expect(step.winner, 0);
  });

  test('sorpresa de cumpleaños: cada uno le da 10', () {
    final s = BarrioState.initial(3);
    final step = s.roll(0, 1, 2, BarrioCard.birthday.index);
    expect(step.state.cash[0], Barrio.startCash + 20);
    expect(step.state.cash[1], Barrio.startCash - 10);
  });

  test('se guarda y se lee igual', () {
    final s = BarrioState.initial(4).roll(0, 3, 4, 2).state;
    expect(BarrioState.fromJson(s.toJson()).toJson(), s.toJson());
  });
}
