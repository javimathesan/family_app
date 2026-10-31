import 'package:flutter/material.dart';

import '../../data/family_store.dart';
import '../../games/colorin.dart';
import '../../models/models.dart';

const colorinColors = {
  'r': Color(0xFFE53935),
  'y': Color(0xFFF9A825),
  'g': Color(0xFF43A047),
  'b': Color(0xFF1E88E5),
  'w': Color(0xFF263238),
};
const colorinNames = {'r': 'Rojo', 'y': 'Amarillo', 'g': 'Verde', 'b': 'Azul'};

String _symbol(String card) => switch (Colorin.valueOf(card)) {
      'S' => '⊘',
      'R' => '⇄',
      'D' => '+2',
      'W' => '🌈',
      'F' => '+4',
      final v => v,
    };

/// Una carta de Colorín (o su dorso).
class ColorinCard extends StatelessWidget {
  const ColorinCard({super.key, this.card, this.width = 56, this.glow = false, this.onTap});

  /// `null` = carta boca abajo.
  final String? card;
  final double width;
  final bool glow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = card;
    final color = c == null ? const Color(0xFF5E35B1) : colorinColors[Colorin.colorOf(c)]!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: width * 1.45,
        margin: EdgeInsets.only(bottom: glow ? 10 : 0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(width * .16),
          border: Border.all(color: Colors.white, width: width * .06),
          boxShadow: [BoxShadow(blurRadius: glow ? 10 : 3, color: glow ? Colors.amber : Colors.black26)],
        ),
        alignment: Alignment.center,
        child: c == null
            ? Text('C', style: TextStyle(color: Colors.white70, fontSize: width * .5, fontWeight: FontWeight.w900))
            : Container(
                width: width * .72,
                height: width * .9,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.elliptical(width, width * 1.2))),
                alignment: Alignment.center,
                child: Text(
                  _symbol(c),
                  style: TextStyle(color: Colorin.isWild(c) ? Colors.black87 : color, fontSize: width * .38, fontWeight: FontWeight.w900),
                ),
              ),
      ),
    );
  }
}

/// Mesa de Colorín: mazo, última carta, color actual y la mano de quien juega.
class ColorinView extends StatefulWidget {
  const ColorinView({
    super.key,
    required this.match,
    required this.me,
    required this.canAct,
    required this.onStep,
  });

  final GameMatch match;
  final String me;
  final bool canAct;
  final ValueChanged<ColorinStep> onStep;

  @override
  State<ColorinView> createState() => _ColorinViewState();
}

class _ColorinViewState extends State<ColorinView> {
  bool _saidLast = false;

  /// En un solo teléfono, la mano se tapa hasta que el jugador la quiere ver.
  String? _revealedFor;

  Future<void> _play(ColorinState state, int seat, int index) async {
    String? chosen;
    if (Colorin.isWild(state.hand(seat)[index])) {
      chosen = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('¿Qué color sigue?'),
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in Colorin.colors)
                  InkResponse(
                    onTap: () => Navigator.pop(ctx, c),
                    child: CircleAvatar(radius: 30, backgroundColor: colorinColors[c], child: Text(colorinNames[c]![0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                  ),
              ],
            ),
          ],
        ),
      );
      if (chosen == null) return;
    }
    widget.onStep(state.play(seat, index, chosen: chosen, saidLast: _saidLast));
    setState(() => _saidLast = false);
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final m = widget.match;
    final state = ColorinState.fromJson(m.state);
    String names(String t) => t.replaceAllMapped(RegExp(r'\{p(\d)\}'), (x) => store.playerName(m.players[int.parse(x.group(1)!)]));

    // Qué mano se muestra: la propia o, en un solo teléfono, la del que juega.
    final mySeat = m.players.indexOf(widget.me);
    final seat = m.sameDevice ? m.turn : mySeat;
    final turnKey = '${m.id}:${m.updatedAt.microsecondsSinceEpoch}:${m.turn}';
    final covered = m.sameDevice && !m.finished && m.players[m.turn] != botPlayerId && _revealedFor != turnKey;
    final myTurn = widget.canAct && seat == m.turn;
    final playable = myTurn ? state.playable(seat) : const <int>[];

    return Column(
      children: [
        // Cartas de los demás.
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var p = 0; p < m.players.length; p++)
              if (p != seat)
                Chip(
                  avatar: const Text('🂠'),
                  label: Text('${store.playerName(m.players[p])}: ${state.hand(p).length}${state.hand(p).length == 1 ? ' ¡Última!' : ''}'),
                ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              key: const ValueKey('colorin_mazo'),
              onTap: myTurn && !state.drew ? () => widget.onStep(state.draw(seat)) : null,
              child: Column(
                children: [
                  const ColorinCard(width: 70),
                  const SizedBox(height: 4),
                  Text(myTurn && !state.drew ? 'Robar' : '${state.deck.length} cartas', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 28),
            Column(
              children: [
                ColorinCard(card: state.top, width: 84),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(radius: 8, backgroundColor: colorinColors[state.color]),
                    const SizedBox(width: 4),
                    Text(colorinNames[state.color]!, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Text(state.direction == 1 ? '↻' : '↺', style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ],
            ),
          ],
        ),
        if (state.message != null) ...[
          const SizedBox(height: 10),
          Text(names(state.message!), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 16),
        if (seat >= 0 && !m.finished)
          covered
              ? FilledButton.icon(
                  onPressed: () => setState(() => _revealedFor = turnKey),
                  icon: const Icon(Icons.visibility),
                  label: Text('Soy ${store.playerName(m.players[m.turn])}: ver mis cartas'),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 112,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (var i = 0; i < state.hand(seat).length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: ColorinCard(
                                  key: ValueKey('colorin_carta_$i'),
                                  card: state.hand(seat)[i],
                                  width: 60,
                                  glow: playable.contains(i),
                                  onTap: playable.contains(i) ? () => _play(state, seat, i) : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        if (myTurn && state.hand(seat).length == 2)
                          FilterChip(
                            avatar: const Text('📣'),
                            label: const Text('¡Última!'),
                            selected: _saidLast,
                            onSelected: (v) => setState(() => _saidLast = v),
                          ),
                        if (myTurn && state.drew)
                          OutlinedButton(onPressed: () => widget.onStep(state.pass(seat)), child: const Text('Pasar')),
                      ],
                    ),
                    if (myTurn && playable.isEmpty && !state.drew)
                      const Text('No tenés carta para tirar: tocá el mazo para robar.'),
                  ],
                ),
      ],
    );
  }
}
