import 'dart:math';

import 'package:family_app/games/chess.dart';
import 'package:family_app/games/cuatro.dart';
import 'package:family_app/games/ludo.dart';
import 'package:family_app/games/tateti.dart';
import 'package:flutter_test/flutter_test.dart';

Chess _play(List<String> moves) {
  var pos = Chess.initial();
  for (final m in moves) {
    final from = Chess.square(m.substring(0, 2));
    final to = Chess.square(m.substring(2, 4));
    final promo = m.length > 4 ? m[4] : null;
    final legal = pos.legalMoves();
    final move = ChessMove(from, to, promo);
    expect(legal, contains(move), reason: 'jugada ilegal: $m');
    pos = pos.apply(move);
  }
  return pos;
}

void main() {
  group('Tres en raya', () {
    test('detecta ganador y empate', () {
      var c = Tateti.initial();
      for (final (i, p) in [(0, 0), (3, 1), (1, 0), (4, 1), (2, 0)]) {
        c = Tateti.play(c, i, p);
      }
      expect(Tateti.winner(c), 0);
      expect(Tateti.winningLine(c), [0, 1, 2]);
      expect(Tateti.isFull([0, 1, 0, 0, 1, 1, 1, 0, 0]), isTrue);
      expect(Tateti.winner([0, 1, 0, 0, 1, 1, 1, 0, 0]), isNull);
    });

    test('Robi gana si puede y si no bloquea', () {
      expect(Tateti.botMove([1, 1, -1, 0, 0, -1, -1, -1, -1], 1, Random(1)), 2);
      expect(Tateti.botMove([0, 0, -1, -1, 1, -1, -1, -1, -1], 1, Random(1)), 2);
    });
  });

  group('4 en línea', () {
    test('las fichas caen y se gana en diagonal', () {
      var c = Cuatro.initial();
      for (final (col, p) in [(0, 0), (1, 1), (1, 0), (2, 1), (2, 0), (3, 1), (2, 0), (3, 1), (3, 0), (6, 1), (3, 0)]) {
        c = Cuatro.play(c, col, p);
      }
      expect(Cuatro.winner(c), 0);
      expect(Cuatro.winningLine(c)!.length, 4);
    });

    test('columna llena no se puede jugar', () {
      var c = Cuatro.initial();
      for (var i = 0; i < 6; i++) {
        c = Cuatro.play(c, 0, i % 2);
      }
      expect(Cuatro.dropRow(c, 0), -1);
      expect(Cuatro.canPlay(c, 0), isFalse);
    });

    test('Robi bloquea 3 en fila', () {
      var c = Cuatro.initial();
      for (final col in [0, 1, 2]) {
        c = Cuatro.play(c, col, 0);
      }
      expect(Cuatro.botMove(c, 1, Random(2)), 3);
    });
  });

  group('Ludo', () {
    test('el recorrido tiene 52 casillas distintas', () {
      // Se prueba a través de las salidas: cada color sale 13 casillas después.
      expect([for (final s in [0, 1, 2, 3]) Ludo.absolute(s, 0)], [0, 13, 26, 39]);
      expect(Ludo.absolute(1, 50), 11);
    });

    test('hace falta un 6 para salir; sin movimientos pasa el turno', () {
      final s = LudoState.initial(2);
      final step = s.roll(0, 3);
      expect(step.nextTurn, 1);
      expect(step.state.dice, isNull);
      expect(step.state.message, contains('Sin movimientos'));

      final six = s.roll(0, 6);
      expect(six.nextTurn, 0);
      expect(six.state.movable(0), [0, 1, 2, 3]);
      final out = six.state.move(0, 0);
      expect(out.state.tokens[0][0], 0);
      expect(out.nextTurn, 0, reason: 'con 6 vuelve a tirar');
    });

    test('come una ficha rival y vuelve a tirar', () {
      // Rojo (asiento 0) en la casilla 10; amarillo (asiento 2) a 2 de ahí:
      // la casilla 10 es el avance 36 del amarillo (26 + 36 = 62 → 10).
      final s = LudoState(seats: const [0, 2], tokens: [
        [10, -1, -1, -1],
        [34, -1, -1, -1],
      ], dice: 2);
      final step = s.move(1, 0);
      expect(step.state.tokens[1][0], 36);
      expect(step.state.tokens[0][0], -1, reason: 'la ficha roja vuelve a la base');
      expect(step.nextTurn, 1);
    });

    test('en casilla segura no se come y a la meta se entra justo', () {
      final s = LudoState(seats: const [0, 2], tokens: [
        [8, 54, -1, -1],
        [32, -1, -1, -1],
      ], dice: 2);
      expect(s.movable(0), [0, 1]);
      final safe = LudoState(seats: s.seats, tokens: s.tokens, dice: 2).move(1, 0);
      expect(safe.state.tokens[0][0], 8, reason: '8 es una estrella');
      final tooFar = LudoState(seats: s.seats, tokens: s.tokens, dice: 3);
      expect(tooFar.movable(0), [0], reason: 'la ficha en 54 necesita 2 justo');
    });

    test('gana quien mete las 4 fichas', () {
      final s = LudoState(seats: const [0, 2], tokens: [
        [56, 56, 56, 53],
        [-1, -1, -1, -1],
      ], dice: 3);
      final step = s.move(0, 3);
      expect(step.winner, 0);
    });

    test('se guarda sin listas anidadas', () {
      final json = LudoState.initial(4).toJson();
      expect(json['tokens'], everyElement(isA<int>()));
      expect(LudoState.fromJson(json).tokens.length, 4);
    });
  });

  group('Ajedrez', () {
    test('20 jugadas al empezar', () {
      expect(Chess.initial().legalMoves().length, 20);
    });

    test('mate del pastor', () {
      final pos = _play(['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7']);
      expect(pos.status, ChessStatus.checkmate);
      expect(pos.inCheck(), isTrue);
    });

    test('enroque corto', () {
      final pos = _play(['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6', 'e1g1']);
      expect(pos.board[Chess.square('g1')], 'K');
      expect(pos.board[Chess.square('f1')], 'R');
      expect(pos.castling.contains('K'), isFalse);
    });

    test('captura al paso', () {
      final pos = _play(['e2e4', 'a7a6', 'e4e5', 'd7d5', 'e5d6']);
      expect(pos.board[Chess.square('d6')], 'P');
      expect(pos.board[Chess.square('d5')], isNull);
    });

    test('coronación', () {
      final pos = _play(['h2h4', 'g7g5', 'h4g5', 'h7h6', 'g5h6', 'g8f6', 'h6h7', 'f6g8', 'h7g8n']);
      expect(pos.board[Chess.square('g8')], 'N');
    });

    test('en jaque solo valen jugadas que lo resuelven', () {
      final pos = _play(['e2e4', 'e7e5', 'f1c4', 'd7d6', 'c4f7']);
      expect(pos.inCheck(), isTrue);
      final moves = pos.legalMoves();
      expect(moves, isNotEmpty);
      expect(moves.every((m) => m.from == Chess.square('e8')), isTrue);
    });

    test('ahogado', () {
      final board = List<String?>.filled(64, null);
      board[Chess.square('a8')] = 'k';
      board[Chess.square('c7')] = 'Q';
      board[Chess.square('c6')] = 'K';
      final pos = Chess(board: board, whiteToMove: false, castling: '');
      expect(pos.status, ChessStatus.stalemate);
    });

    test('Robi come la dama regalada', () {
      final pos = _play(['e2e4', 'd7d5', 'd1g4']);
      final move = pos.botMove(Random(3));
      expect(move.to, Chess.square('g4'));
    });

    test('guardar y leer', () {
      final pos = _play(['e2e4', 'c7c5']);
      final back = Chess.fromJson(pos.toJson());
      expect(back.toJson(), pos.toJson());
      expect(back.ep, Chess.square('c6'));
    });
  });
}
