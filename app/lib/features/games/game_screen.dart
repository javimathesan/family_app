import 'dart:async';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/family_store.dart';
import '../../games/barrio.dart';
import '../../games/chess.dart';
import '../../games/cuatro.dart';
import '../../games/ludo.dart';
import '../../games/tateti.dart';
import '../../models/models.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';
import 'boards.dart';

/// Pantalla de una partida: jugadores, turno y tablero.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.matchId});

  final String matchId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  /// Jugada de Robi programada (para no repetirla).
  String? _botScheduledFor;
  Timer? _botTimer;

  /// Cuenta el tiempo de juego de los chicos mientras la partida está abierta.
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final store = FamilyScope.of(context);
      final me = store.currentMember;
      final match = store.matchById(widget.matchId);
      if (me == null || match == null || match.finished) return;
      store.addGameSeconds(me.id, 10);
    });
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final match = store.matchById(widget.matchId);
    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partida')),
        body: const Center(child: Text('Esta partida ya no existe.')),
      );
    }
    final me = store.currentMember?.id ?? '';
    final locked = !store.canPlayGames(me);
    final canAct = !match.finished &&
        !locked &&
        match.currentPlayer != botPlayerId &&
        (match.currentPlayer == me || (match.sameDevice && match.players.contains(me)));
    _maybeBot(store, match, me);

    return Scaffold(
      appBar: AppBar(
        title: Text(match.kind.label, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (!match.finished && match.players.contains(me))
            IconButton(
              tooltip: 'Abandonar',
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => _abandon(context, store, match),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Players(match: match, me: me),
            const SizedBox(height: 12),
            _StatusLine(match: match, me: me, locked: locked),
            const SizedBox(height: 12),
            _board(context, store, match, me, canAct),
            if (match.finished) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _rematch(context, store, match),
                icon: const Icon(Icons.replay),
                label: const Text('Revancha'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _board(BuildContext context, FamilyStore store, GameMatch match, String me, bool canAct) {
    final s = match.state;
    switch (match.kind) {
      case GameKind.tateti:
        final cells = (s['cells'] as List).cast<int>();
        return TatetiBoard(
          cells: cells,
          enabled: canAct,
          winLine: Tateti.winningLine(cells),
          onTap: (i) => _playTateti(store, match, i),
        );
      case GameKind.cuatro:
        final cells = (s['cells'] as List).cast<int>();
        return CuatroBoard(
          cells: cells,
          enabled: canAct,
          winLine: Cuatro.winningLine(cells),
          onDrop: (c) => _playCuatro(store, match, c),
        );
      case GameKind.ludo:
        final state = LudoState.fromJson(s);
        final movable = canAct ? state.movable(match.turn) : const <int>[];
        return Column(
          children: [
            LudoBoard(
              state: state,
              movable: movable,
              activePlayer: match.turn,
              onToken: (t) => _ludoMove(store, match, t),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DiceFace(value: state.dice ?? state.lastRoll),
                const SizedBox(width: 16),
                if (canAct && state.dice == null)
                  FilledButton.icon(
                    onPressed: () => _ludoRoll(store, match),
                    icon: const Icon(Icons.casino),
                    label: const Text('Tirar el dado'),
                  )
                else if (canAct)
                  const Flexible(child: Text('Tocá la ficha que querés mover', style: TextStyle(fontWeight: FontWeight.w700))),
              ],
            ),
            if (state.message != null) ...[
              const SizedBox(height: 8),
              Text(state.message!, style: mutedText(context)),
            ],
          ],
        );
      case GameKind.barrio:
        return _barrio(context, store, match, canAct);
      case GameKind.ajedrez:
        final position = Chess.fromJson(s);
        // Cada uno ve sus piezas abajo; en un solo teléfono, las blancas.
        final flipped = !match.sameDevice && match.players.length > 1 && match.players[1] == me;
        return Column(
          children: [
            ChessBoardView(
              position: position,
              enabled: canAct,
              flipped: flipped,
              onMove: (m) => _chessMove(store, match, m),
            ),
            if (!match.finished && position.inCheck()) ...[
              const SizedBox(height: 8),
              const Text('¡Jaque!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.red)),
            ],
          ],
        );
    }
  }

  Widget _barrio(BuildContext context, FamilyStore store, GameMatch match, bool canAct) {
    final state = BarrioState.fromJson(match.state);
    final colors = [for (var i = 0; i < match.players.length; i++) ludoColors[i]];
    String names(String text) => text.replaceAllMapped(
          RegExp(r'\{p(\d)\}'),
          (m) => store.playerName(match.players[int.parse(m.group(1)!)]),
        );
    final here = Barrio.squares[state.pos[match.turn]];
    return Column(
      children: [
        BarrioBoard(
          state: state,
          playerColors: colors,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DiceFace(value: state.dice.isEmpty ? null : state.dice[0], size: 40),
                  const SizedBox(width: 8),
                  DiceFace(value: state.dice.isEmpty ? null : state.dice[1], size: 40),
                ],
              ),
              const SizedBox(height: 6),
              Text('Pozo de la fuente: ${state.pot} ⛲', style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('Quedan ${state.turnsLeft} turnos', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              if (state.message != null && state.message!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(names(state.message!), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var p = 0; p < match.players.length; p++)
              Chip(
                avatar: CircleAvatar(backgroundColor: colors[p], radius: 8),
                label: Text(
                  state.out[p]
                      ? '${store.playerName(match.players[p])}: afuera'
                      : '${store.playerName(match.players[p])}: ${state.cash[p]} 🪙 · ${state.propertiesOf(p).length} lugares',
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (canAct && !state.buying)
          FilledButton.icon(
            onPressed: () => _barrioRoll(store, match),
            icon: const Icon(Icons.casino),
            label: const Text('Tirar los dados'),
          ),
        if (canAct && state.buying)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _barrioDecide(store, match, true),
                  child: Text('Comprar ${here.name} (${here.price})'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _barrioDecide(store, match, false),
                  child: const Text('No, gracias'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ------------------------------------------------------------ jugadas

  void _barrioStep(FamilyStore store, GameMatch match, BarrioStep step) {
    store.playMove(
      match.id,
      step.state.toJson(),
      nextTurn: step.nextTurn,
      winner: step.winner,
      draw: step.draw,
      by: match.currentPlayer,
    );
  }

  void _barrioRoll(FamilyStore store, GameMatch match) {
    final r = barrioRoll();
    _barrioStep(store, match, BarrioState.fromJson(match.state).roll(match.turn, r.d1, r.d2, r.card));
  }

  void _barrioDecide(FamilyStore store, GameMatch match, bool buy) {
    _barrioStep(store, match, BarrioState.fromJson(match.state).decide(match.turn, buy: buy));
  }

  void _playTateti(FamilyStore store, GameMatch match, int i) {
    final cells = Tateti.play((match.state['cells'] as List).cast<int>(), i, match.turn);
    final winner = Tateti.winner(cells);
    store.playMove(
      match.id,
      {'cells': cells},
      nextTurn: 1 - match.turn,
      winner: winner,
      draw: winner == null && Tateti.isFull(cells),
      by: match.currentPlayer,
    );
  }

  void _playCuatro(FamilyStore store, GameMatch match, int col) {
    final cells = Cuatro.play((match.state['cells'] as List).cast<int>(), col, match.turn);
    final winner = Cuatro.winner(cells);
    store.playMove(
      match.id,
      {'cells': cells},
      nextTurn: 1 - match.turn,
      winner: winner,
      draw: winner == null && Cuatro.isFull(cells),
      by: match.currentPlayer,
    );
  }

  void _ludoRoll(FamilyStore store, GameMatch match) {
    final step = LudoState.fromJson(match.state).roll(match.turn, rollDice());
    store.playMove(match.id, step.state.toJson(), nextTurn: step.nextTurn, by: match.currentPlayer);
  }

  void _ludoMove(FamilyStore store, GameMatch match, int token) {
    final step = LudoState.fromJson(match.state).move(match.turn, token);
    store.playMove(match.id, step.state.toJson(), nextTurn: step.nextTurn, winner: step.winner, by: match.currentPlayer);
  }

  void _chessMove(FamilyStore store, GameMatch match, ChessMove move) {
    final next = Chess.fromJson(match.state).apply(move);
    final status = next.status;
    store.playMove(
      match.id,
      next.toJson(),
      nextTurn: 1 - match.turn,
      winner: status == ChessStatus.checkmate ? match.turn : null,
      draw: status == ChessStatus.stalemate || status == ChessStatus.draw,
      by: match.currentPlayer,
    );
  }

  // --------------------------------------------------------------- Robi

  void _maybeBot(FamilyStore store, GameMatch match, String me) {
    if (match.finished || match.currentPlayer != botPlayerId || !match.players.contains(me)) return;
    final key = '${match.id}:${match.updatedAt.microsecondsSinceEpoch}:${match.turn}';
    if (_botScheduledFor == key) return;
    _botScheduledFor = key;
    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 700), () {
      final m = store.matchById(match.id);
      if (!mounted || m == null || m.finished || m.currentPlayer != botPlayerId) return;
      switch (m.kind) {
        case GameKind.tateti:
          _playTateti(store, m, Tateti.botMove((m.state['cells'] as List).cast<int>(), m.turn));
        case GameKind.cuatro:
          _playCuatro(store, m, Cuatro.botMove((m.state['cells'] as List).cast<int>(), m.turn));
        case GameKind.ludo:
          final state = LudoState.fromJson(m.state);
          if (state.dice == null) {
            _ludoRoll(store, m);
          } else {
            _ludoMove(store, m, state.botToken(m.turn));
          }
        case GameKind.ajedrez:
          _chessMove(store, m, Chess.fromJson(m.state).botMove());
        case GameKind.barrio:
          final state = BarrioState.fromJson(m.state);
          if (state.buying) {
            _barrioDecide(store, m, state.botWantsToBuy(m.turn));
          } else {
            _barrioRoll(store, m);
          }
      }
    });
  }

  // ------------------------------------------------------------- acciones

  Future<void> _abandon(BuildContext context, FamilyStore store, GameMatch match) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Abandonar la partida?'),
        content: const Text('Se borra para todos los jugadores.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir jugando')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Abandonar')),
        ],
      ),
    );
    if (ok != true) return;
    store.removeMatch(match.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  void _rematch(BuildContext context, FamilyStore store, GameMatch match) {
    // En la revancha empieza el que iba segundo.
    final players = [...match.players.skip(1), match.players.first];
    final next = store.createMatch(match.kind, players, sameDevice: match.sameDevice);
    Navigator.of(context).pushReplacementNamed(Routes.matchOf(next.id));
  }
}

class _Players extends StatelessWidget {
  const _Players({required this.match, required this.me});

  final GameMatch match;
  final String me;

  Color _colorOf(int i) {
    if (match.kind == GameKind.ludo) {
      return ludoColors[Ludo.seatsFor(match.players.length)[i]];
    }
    if (match.kind == GameKind.barrio) return ludoColors[i];
    if (match.kind == GameKind.ajedrez) return i == 0 ? Colors.white : Colors.black87;
    return twoPlayerColors[i];
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < match.players.length; i++)
          Builder(builder: (context) {
            final id = match.players[i];
            final member = store.memberById(id);
            final active = !match.finished && match.turn == i;
            final won = match.winner == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: active ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border.all(color: won ? Colors.amber : (active ? Theme.of(context).colorScheme.primary : Colors.transparent), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (member != null)
                    AvatarView(config: member.avatar, size: 32)
                  else
                    const CircleAvatar(radius: 16, child: Icon(Icons.smart_toy_outlined, size: 20)),
                  const SizedBox(width: 6),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: _colorOf(i), shape: BoxShape.circle, border: Border.all(color: Colors.black38)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    id == me ? '${store.playerName(id)} (vos)' : store.playerName(id),
                    style: TextStyle(fontWeight: active || won ? FontWeight.w800 : FontWeight.w600),
                  ),
                  if (won) const Text(' 🏆'),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.match, required this.me, required this.locked});

  final GameMatch match;
  final String me;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final String text;
    if (match.draw) {
      text = '¡Empate!';
    } else if (match.winner != null) {
      final w = match.players[match.winner!];
      text = w == me ? '¡Ganaste! 🎉' : '¡Ganó ${store.playerName(w)}!';
    } else if (locked) {
      text = store.gamesLock(me) == GamesLock.time
          ? 'Se terminó tu tiempo de juego por hoy'
          : 'Terminá tus tareas para seguir jugando';
    } else if (match.currentPlayer == me) {
      text = 'Te toca';
    } else if (match.currentPlayer == botPlayerId) {
      text = 'Robi está pensando…';
    } else if (match.sameDevice) {
      text = 'Turno de ${store.playerName(match.currentPlayer)}: pasale el teléfono';
    } else {
      text = 'Turno de ${store.playerName(match.currentPlayer)}';
    }
    return Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800));
  }
}
