import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../data/family_store.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/celebration.dart';
import '../../widgets/common.dart';

/// Tiro al blanco: 30 segundos para tocar todos los blancos que se pueda.
/// En el centro valen más; los dorados valen el triple.
class TargetGameScreen extends StatefulWidget {
  const TargetGameScreen({super.key, this.random, this.seconds = 30});

  final Random? random;
  final int seconds;

  @override
  State<TargetGameScreen> createState() => _TargetGameScreenState();
}

class _Target {
  _Target(this.pos, this.velocity, this.radius, this.born, {this.gold = false});
  Offset pos;
  final Offset velocity;
  final double radius;
  final Duration born;
  final bool gold;
}

class _Pop {
  _Pop(this.pos, this.text, this.born);
  final Offset pos;
  final String text;
  final Duration born;
}

class _TargetGameScreenState extends State<TargetGameScreen> with SingleTickerProviderStateMixin {
  late final Random _r = widget.random ?? Random();
  late final Ticker _ticker = createTicker(_tick);
  final List<_Target> _targets = [];
  final List<_Pop> _pops = [];
  Size _area = Size.zero;
  Duration _now = Duration.zero;
  Duration _lastSpawn = Duration.zero;
  Duration _lastFrame = Duration.zero;
  int _score = 0;
  int _hits = 0;
  bool _playing = false;
  bool _over = false;
  bool _record = false;

  static const _life = Duration(milliseconds: 2600);

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _targets.clear();
      _pops.clear();
      _score = 0;
      _hits = 0;
      _now = Duration.zero;
      _lastSpawn = Duration.zero;
      _lastFrame = Duration.zero;
      _playing = true;
      _over = false;
      _record = false;
    });
    _ticker
      ..stop()
      ..start();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _lastFrame).inMicroseconds / 1e6;
    _lastFrame = elapsed;
    _now = elapsed;
    if (elapsed.inSeconds >= widget.seconds) {
      _finish();
      return;
    }
    // Cada vez aparecen más rápido.
    final every = Duration(milliseconds: max(380, 750 - elapsed.inSeconds * 12));
    if (elapsed - _lastSpawn >= every && _area != Size.zero) {
      _lastSpawn = elapsed;
      final radius = 26.0 + _r.nextDouble() * 18;
      final pos = Offset(radius + _r.nextDouble() * (_area.width - 2 * radius), radius + _r.nextDouble() * (_area.height - 2 * radius));
      final speed = 30 + elapsed.inSeconds * 3.0;
      final angle = _r.nextDouble() * 2 * pi;
      _targets.add(_Target(pos, Offset(cos(angle), sin(angle)) * speed, radius, elapsed, gold: _r.nextInt(8) == 0));
    }
    for (final t in _targets) {
      var p = t.pos + t.velocity * dt;
      p = Offset(p.dx.clamp(t.radius, _area.width - t.radius), p.dy.clamp(t.radius, _area.height - t.radius));
      t.pos = p;
    }
    _targets.removeWhere((t) => elapsed - t.born > _life);
    _pops.removeWhere((p) => elapsed - p.born > const Duration(milliseconds: 700));
    setState(() {});
  }

  void _shoot(Offset at) {
    if (!_playing) return;
    for (final t in _targets.reversed) {
      final d = (t.pos - at).distance;
      if (d <= t.radius) {
        var points = d <= t.radius / 3 ? 20 : 10;
        if (t.gold) points *= 3;
        _score += points;
        _hits++;
        _targets.remove(t);
        _pops.add(_Pop(t.pos, '+$points', _now));
        HapticFeedback.lightImpact();
        return;
      }
    }
  }

  void _finish() {
    _ticker.stop();
    final store = FamilyScope.of(context);
    final me = store.currentMember;
    var record = false;
    if (me != null) {
      record = store.saveScore(me.id, 'tiro', _score);
      store.addGameSeconds(me.id, widget.seconds);
    }
    setState(() {
      _playing = false;
      _over = true;
      _record = record;
      _targets.clear();
    });
    if (record) celebrate(context, text: '¡Récord! $_score 🎯');
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final me = store.currentMember;
    final left = (widget.seconds - _now.inSeconds).clamp(0, widget.seconds);
    final ranking = [
      for (final m in store.members)
        if (store.bestScore(m.id, 'tiro') > 0) (member: m, score: store.bestScore(m.id, 'tiro')),
    ]..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      appBar: AppBar(title: const Text('Tiro al blanco 🎯', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('⏱ $left s', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Text('$_score pts', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 12),
                  if (me != null) Text('Récord: ${store.bestScore(me.id, 'tiro')}', style: mutedText(context)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF87CEEB), Color(0xFFB2EBF2)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(builder: (context, box) {
                  _area = box.biggest;
                  if (!_playing) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if (_over) ...[
                              Text(_record ? '¡Nuevo récord!' : '¡Se terminó el tiempo!', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                              Text('$_score puntos · $_hits blancos', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                            ] else ...[
                              const Text('🎯', style: TextStyle(fontSize: 64)),
                              const Text('Tocá los blancos antes de que desaparezcan.\nEn el centro valen el doble y los dorados, el triple.',
                                  textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                            ],
                            FilledButton.icon(
                              onPressed: me == null || !store.canPlayGames(me.id) ? null : _start,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(_over ? 'Jugar otra vez' : '¡Empezar!'),
                            ),
                            if (me != null && !store.canPlayGames(me.id))
                              const Padding(padding: EdgeInsets.only(top: 8), child: Text('Primero la rutina (o se terminó el tiempo de juego de hoy).')),
                            if (ranking.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text('Récords de la familia', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              for (final (i, e) in ranking.take(5).indexed)
                                ListTile(
                                  dense: true,
                                  leading: Text(['🥇', '🥈', '🥉', '4.', '5.'][i], style: const TextStyle(fontSize: 22)),
                                  title: Row(
                                    children: [
                                      AvatarView(config: e.member.avatar, size: 28),
                                      const SizedBox(width: 8),
                                      Text(e.member.nickname, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                  trailing: Text('${e.score}', style: const TextStyle(fontWeight: FontWeight.w900)),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => _shoot(d.localPosition),
                    child: CustomPaint(painter: _TargetsPainter(_targets, _pops, _now), size: Size.infinite),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetsPainter extends CustomPainter {
  _TargetsPainter(this.targets, this.pops, this.now);

  final List<_Target> targets;
  final List<_Pop> pops;
  final Duration now;

  @override
  void paint(Canvas canvas, Size size) {
    for (final t in targets) {
      final age = (now - t.born).inMilliseconds / 2600;
      final scale = age < .15 ? age / .15 : (age > .85 ? (1 - age) / .15 : 1.0);
      final r = t.radius * scale.clamp(0, 1);
      final rings = t.gold
          ? const [Color(0xFFFFD54F), Color(0xFFFFFFFF), Color(0xFFFFB300)]
          : const [Color(0xFFE53935), Color(0xFFFFFFFF), Color(0xFFE53935)];
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(t.pos, r * (1 - i / 3), Paint()..color = rings[i]);
      }
      canvas.drawCircle(t.pos, r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black26);
    }
    for (final p in pops) {
      final age = (now - p.born).inMilliseconds / 700;
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.deepOrange.withValues(alpha: (1 - age).clamp(0, 1))),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p.pos - Offset(tp.width / 2, 20 + age * 30));
    }
  }

  @override
  bool shouldRepaint(covariant _TargetsPainter old) => true;
}
