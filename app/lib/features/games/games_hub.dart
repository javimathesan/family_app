import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/app_session.dart';
import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';

/// Área de juegos como pantalla propia (desde el panel del adulto).
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Juegos', style: TextStyle(fontWeight: FontWeight.w800))),
      body: const SafeArea(child: GamesHub(showTitle: false)),
    );
  }
}

/// Área de juegos: juegos para empezar y partidas en curso.
class GamesHub extends StatelessWidget {
  const GamesHub({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final session = SessionScope.of(context);
    final me = store.currentMember;
    if (me == null) return const SizedBox.shrink();
    final lock = store.gamesLock(me.id);
    final locked = lock != null;
    final minutesLeft = store.gameMinutesLeft(me.id);
    final mine = store.matchesOf(me.id);
    final active = mine.where((m) => !m.finished).toList()
      ..sort((a, b) => (b.currentPlayer == me.id ? 1 : 0).compareTo(a.currentPlayer == me.id ? 1 : 0));
    final finished = mine.where((m) => m.finished).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (showTitle) ...[
          Text('Juegos', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
        ],
        if (lock == GamesLock.routine) _LockCard(memberId: me.id),
        if (lock == GamesLock.time)
          const InfoCard(
            color: Color(0xFFFFF3E0),
            child: Row(
              children: [
                Icon(Icons.timer_off_outlined, size: 36, color: Color(0xFFEF6C00)),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Se terminó el tiempo de juego de hoy. ¡Mañana hay más!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        if (!locked && minutesLeft != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 20),
                const SizedBox(width: 6),
                Text('Te quedan $minutesLeft minutos de juego hoy', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        if (me.role.isAdult && session.isAdmin) _RuleCard(rule: store.gamesRule, minutes: store.gamesMinutes),
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        Text('Para practicar', style: sectionTitle(context)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                emoji: '🔤',
                title: 'Palabras',
                subtitle: 'Inglés, portugués y coreano · no gasta tiempo de juego',
                color: const Color(0xFFBBDEFB),
                onTap: () => Navigator.of(context).pushNamed(Routes.words),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickCard(
                emoji: '🎯',
                title: 'Tiro al blanco',
                subtitle: '30 segundos · tu récord: ${store.bestScore(me.id, 'tiro')}',
                color: const Color(0xFFB2EBF2),
                onTap: locked ? null : () => Navigator.of(context).pushNamed(Routes.target),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Nuevo juego', style: sectionTitle(context)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: [
            for (final kind in GameKind.values)
              _GameCard(kind: kind, enabled: !locked, onTap: () => _newGame(context, kind)),
          ],
        ),
        const SizedBox(height: 20),
        Text('Partidas', style: sectionTitle(context)),
        const SizedBox(height: 8),
        if (active.isEmpty && finished.isEmpty)
          Text('Todavía no hay partidas. ¡Elegí un juego y desafiá a alguien de la familia o a Robi!', style: mutedText(context)),
        for (final m in active) _MatchTile(match: m, me: me.id),
        if (finished.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Terminadas (${finished.length}) · deslizá para borrar una',
                    style: mutedText(context).copyWith(fontWeight: FontWeight.w700)),
              ),
              TextButton.icon(
                onPressed: () => _clearFinished(context, me.id, finished.length),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Borrar todas'),
              ),
            ],
          ),
          for (final m in finished)
            Dismissible(
              key: ValueKey('fin_${m.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              onDismissed: (_) => store.removeMatch(m.id),
              child: _MatchTile(match: m, me: me.id),
            ),
        ],
      ],
    );
  }

  Future<void> _clearFinished(BuildContext context, String memberId, int count) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Borrar las $count partidas terminadas?'),
        content: const Text('Se borran para todos los jugadores. Las partidas en curso no se tocan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (ok == true && context.mounted) FamilyScope.of(context).removeFinishedMatches(memberId);
  }

  Future<void> _newGame(BuildContext context, GameKind kind) async {
    final store = FamilyScope.of(context);
    final session = SessionScope.of(context);
    final me = store.currentMember!;
    final candidates = [
      for (final m in store.members)
        if (m.id != me.id && !store.isPendingMember(m.id)) m,
    ];
    final result = await showModalBottomSheet<({List<String> rivals, bool sameDevice, String? friendshipId})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _NewGameSheet(
        kind: kind,
        candidates: candidates,
        friends: store.friendRivalsOf(me.id),
        isDemo: !session.isCloud,
      ),
    );
    if (result == null || !context.mounted) return;
    // La primera vez que un chico juega con otra familia, un recordatorio de seguridad.
    if (result.friendshipId != null && !me.role.isAdult && !session.flag('seguridad_${me.id}')) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('🛡️ Jugar con otras familias'),
          content: const Text(
            'Solo jugás con familias que aprobaron tus papás.\n\n'
            '• Nunca compartas tu nombre completo, dirección, colegio ni teléfono.\n'
            '• No hay chat: solo reacciones.\n'
            '• Si algo te hace sentir mal, contale a un adulto de tu casa.',
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('¡Entendido!'))],
        ),
      );
      await session.setFlag('seguridad_${me.id}');
      if (!context.mounted) return;
    }
    final match = store.createMatch(kind, [me.id, ...result.rivals], sameDevice: result.sameDevice, friendshipId: result.friendshipId);
    Navigator.of(context).pushNamed(Routes.matchOf(match.id));
  }
}

/// Acceso grande a Palabras o a un juego rápido, con el mismo estilo que los juegos.
class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.emoji, required this.title, required this.subtitle, required this.color, required this.onTap});

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? .45 : 1,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 160,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const Spacer(),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.kind, required this.enabled, required this.onTap});

  final GameKind kind;
  final bool enabled;
  final VoidCallback onTap;

  static const _colors = {
    GameKind.tateti: Color(0xFFFFE0B2),
    GameKind.cuatro: Color(0xFFBBDEFB),
    GameKind.ludo: Color(0xFFC8E6C9),
    GameKind.ajedrez: Color(0xFFD7CCC8),
    GameKind.barrio: Color(0xFFF8BBD0),
    GameKind.colorin: Color(0xFFFFF59D),
  };

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: Material(
        color: _colors[kind],
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(kind.icon, size: 30, color: Colors.black87),
                const Spacer(),
                Text(kind.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
                Text(kind.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match, required this.me});

  final GameMatch match;
  final String me;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final rivals = [for (final p in match.players) if (p != me) store.playerName(p)];
    final myTurn = !match.finished && match.currentPlayer == me;
    final String status;
    if (match.draw) {
      status = 'Empate';
    } else if (match.winner != null) {
      final w = match.players[match.winner!];
      status = w == me ? 'Ganaste 🏆' : 'Ganó ${store.playerName(w)}';
    } else if (myTurn) {
      status = 'Te toca';
    } else {
      status = 'Turno de ${store.playerName(match.currentPlayer)}';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(match.kind.icon)),
        title: Text('${match.kind.label} con ${rivals.join(', ')}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(status),
        trailing: myTurn
            ? const Chip(label: Text('¡Jugá!'), visualDensity: VisualDensity.compact)
            : const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed(Routes.matchOf(match.id)),
      ),
    );
  }
}

class _LockCard extends StatelessWidget {
  const _LockCard({required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final total = store.templatesFor(memberId).length;
    final needed = (total * store.gamesRule.minRatio).ceil();
    final done = store.doneToday(memberId);
    return InfoCard(
      color: const Color(0xFFFFF3E0),
      child: Row(
        children: [
          const Icon(Icons.lock_clock, size: 36, color: Color(0xFFEF6C00)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Primero la rutina', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text('Completá $needed tareas para jugar. Llevás $done.'),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: needed == 0 ? 1 : (done / needed).clamp(0, 1).toDouble()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.minutes});

  final GamesRule rule;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.rule),
        title: const Text('Reglas de juego de los chicos', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${rule.label} · ${minutes == 0 ? 'sin límite de tiempo' : '$minutes min por día'}'),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => showGameRules(context),
      ),
    );
  }
}

class _NewGameSheet extends StatefulWidget {
  const _NewGameSheet({required this.kind, required this.candidates, required this.friends, required this.isDemo});

  /// Chicos de familias amigas con los que puede jugar.
  final List<({Friendship friendship, FriendKid kid})> friends;

  final GameKind kind;
  final List<Member> candidates;
  final bool isDemo;

  @override
  State<_NewGameSheet> createState() => _NewGameSheetState();
}

class _NewGameSheetState extends State<_NewGameSheet> {
  final List<String> _rivals = [];
  bool? _sameDevice;

  /// Si eligió amigos de otra familia, la amistad (no se mezcla con Robi ni con otras).
  String? _friendshipId;

  int get _maxRivals => widget.kind.maxPlayers - 1;

  void _toggleFriend(Friendship f, String id) {
    setState(() {
      if (_friendshipId != f.id) {
        _rivals.clear();
        _friendshipId = f.id;
      }
      if (_rivals.contains(id)) {
        _rivals.remove(id);
        if (_rivals.isEmpty) _friendshipId = null;
      } else if (_maxRivals == 1) {
        _rivals
          ..clear()
          ..add(id);
      } else if (_rivals.length < _maxRivals) {
        _rivals.add(id);
      }
    });
  }

  void _toggle(String id) {
    if (_friendshipId != null) {
      _rivals.clear();
      _friendshipId = null;
    }
    setState(() {
      if (_rivals.contains(id)) {
        _rivals.remove(id);
      } else if (_maxRivals == 1) {
        _rivals
          ..clear()
          ..add(id);
      } else if (_rivals.length < _maxRivals) {
        _rivals.add(id);
      }
    });
  }

  /// En la demo o con quien no tiene celular, se juega pasando el teléfono.
  bool get _defaultSameDevice =>
      widget.isDemo ||
      _rivals.any((id) => id != botPlayerId && widget.candidates.firstWhere((m) => m.id == id).uid == null);

  @override
  Widget build(BuildContext context) {
    final withBot = _rivals.contains(botPlayerId);
    final withFriends = _friendshipId != null;
    final sameDevice = !withFriends && (withBot || (_sameDevice ?? _defaultSameDevice));
    final ready = _rivals.length >= widget.kind.minPlayers - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.kind.label, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(_maxRivals == 1 ? '¿Contra quién?' : '¿Con quiénes? (hasta $_maxRivals)', style: mutedText(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  avatar: const Icon(Icons.smart_toy_outlined, size: 18),
                  label: const Text('Robi (la compu)'),
                  selected: withBot,
                  onSelected: (_) => _toggle(botPlayerId),
                ),
                for (final m in widget.candidates)
                  FilterChip(
                    label: Text(m.nickname),
                    selected: _rivals.contains(m.id),
                    onSelected: (_) => _toggle(m.id),
                  ),
              ],
            ),
            if (widget.friends.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Familias amigas', style: mutedText(context).copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in widget.friends)
                    FilterChip(
                      avatar: AvatarView(config: f.kid.avatar, size: 22),
                      label: Text('${f.kid.nickname} · ${f.friendship.otherHome}'),
                      selected: _friendshipId == f.friendship.id && _rivals.contains(f.kid.id),
                      onSelected: (_) => _toggleFriend(f.friendship, f.kid.id),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (!withFriends)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: sameDevice,
              onChanged: withBot ? null : (v) => setState(() => _sameDevice = v),
              title: const Text('Jugar en este teléfono', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(sameDevice
                  ? 'Se pasan el teléfono en cada turno.'
                  : 'Cada uno juega desde su celular; le aparece "Te toca" en Juegos.'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: ready ? () => Navigator.pop(context, (rivals: [..._rivals], sameDevice: sameDevice, friendshipId: _friendshipId)) : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('¡A jugar!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reglas de juego de los chicos: cuándo pueden jugar y cuántos minutos.
Future<void> showGameRules(BuildContext context) {
  return showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (ctx) => ListenableBuilder(
            listenable: FamilyScope.of(context),
            builder: (ctx, _) {
              final store = FamilyScope.of(context);
              return SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text('Cuándo pueden jugar (los adultos juegan siempre)', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      RadioGroup<GamesRule>(
                        groupValue: store.gamesRule,
                        onChanged: (r) {
                          if (r != null) store.setGamesRule(r);
                        },
                        child: Column(
                          children: [
                            for (final r in GamesRule.values)
                              RadioListTile<GamesRule>(
                                value: r,
                                title: Text(r.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(r.description),
                              ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text('Tiempo de juego por día', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final m in _minuteOptions)
                              ChoiceChip(
                                label: Text(_minutesLabel(m)),
                                selected: store.gamesMinutes == m,
                                onSelected: (_) => store.setGamesMinutes(m),
                              ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text('Cuenta el tiempo con una partida abierta. Aprender palabras no gasta tiempo de juego.'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
}

const _minuteOptions = [0, 15, 30, 45, 60, 90];

String _minutesLabel(int m) => m == 0 ? 'Sin límite' : '$m min';
