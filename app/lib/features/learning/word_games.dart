import 'dart:math';

import 'package:flutter/material.dart';

import '../../learning/vocabulary.dart';
import '../../services/speech.dart';
import '../../widgets/celebration.dart';
import '../../widgets/common.dart';

/// Pantalla final común de los juegos de palabras.
Widget _finish(BuildContext context, {required String title, required String detail, required VoidCallback again}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 72)),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: again, icon: const Icon(Icons.replay), label: const Text('Otra vez')),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Volver')),
        ],
      ),
    ),
  );
}

// --------------------------------------------------------- escuchar y elegir

/// Se escucha la palabra en el otro idioma y se toca el dibujo correcto.
class ListenGameScreen extends StatefulWidget {
  const ListenGameScreen({super.key, required this.lang, required this.topic, this.random});

  final Lang lang;
  final Topic topic;
  final Random? random;

  @override
  State<ListenGameScreen> createState() => _ListenGameScreenState();
}

class _ListenGameScreenState extends State<ListenGameScreen> {
  static const rounds = 6;
  late final Random _r = widget.random ?? Random();
  late List<({Word word, List<Word> options})> _qs;
  int _i = 0;
  int _ok = 0;
  Word? _picked;

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    final words = [...widget.topic.words]..shuffle(_r);
    _qs = [
      for (final w in words.take(rounds))
        (word: w, options: [w, ...([...widget.topic.words]..remove(w)..shuffle(_r)).take(3)]..shuffle(_r)),
    ];
    _i = 0;
    _ok = 0;
    _picked = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  void _play() {
    if (_i < _qs.length) Speech.instance.say(_qs[_i].word.inLang(widget.lang), widget.lang.ttsLocale);
  }

  void _pick(Word w) {
    if (_picked != null) return;
    setState(() {
      _picked = w;
      if (w == _qs[_i].word) _ok++;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _i++;
        _picked = null;
      });
      if (_i >= _qs.length) {
        if (_ok >= rounds - 1) celebrate(context, text: '¡Oído de oro! 👂');
      } else {
        _play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.lang.flag} Escuchar: ${widget.topic.label}', style: const TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: _i >= _qs.length
            ? _finish(context, title: '$_ok de ${_qs.length}', detail: 'Escuchaste y elegiste bien $_ok palabras.', again: () => setState(_build))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  LinearProgressIndicator(value: (_i + 1) / _qs.length),
                  const SizedBox(height: 20),
                  Center(
                    child: FilledButton.icon(
                      onPressed: _play,
                      icon: const Icon(Icons.volume_up, size: 36),
                      label: const Text('Escuchar otra vez', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      for (final o in _qs[_i].options)
                        Material(
                          color: _picked == null
                              ? Theme.of(context).colorScheme.surfaceContainerHighest
                              : (o == _qs[_i].word ? Colors.green.shade200 : (o == _picked ? Colors.red.shade200 : Theme.of(context).colorScheme.surfaceContainerHighest)),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            key: ValueKey('oir_${o.es}'),
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _pick(o),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(o.emoji, style: const TextStyle(fontSize: 56)),
                                  if (_picked != null) Text(o.inLang(widget.lang), style: const TextStyle(fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// ------------------------------------------------------------------- memoria

/// Memoria: parejas de dibujo y palabra en el otro idioma.
class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key, required this.lang, required this.topic, this.random});

  final Lang lang;
  final Topic topic;
  final Random? random;

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late final Random _r = widget.random ?? Random();
  late List<({Word word, bool picture})> _cards;
  final Set<int> _found = {};
  final List<int> _open = [];
  int _moves = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    final words = ([...widget.topic.words]..shuffle(_r)).take(6).toList();
    _cards = [for (final w in words) ...[(word: w, picture: true), (word: w, picture: false)]]..shuffle(_r);
    _found.clear();
    _open.clear();
    _moves = 0;
    _busy = false;
  }

  void _tap(int i) {
    if (_busy || _found.contains(i) || _open.contains(i)) return;
    setState(() => _open.add(i));
    final c = _cards[i];
    if (!c.picture) Speech.instance.say(c.word.inLang(widget.lang), widget.lang.ttsLocale);
    if (_open.length < 2) return;
    _moves++;
    final a = _cards[_open[0]], b = _cards[_open[1]];
    if (a.word == b.word) {
      setState(() {
        _found.addAll(_open);
        _open.clear();
      });
      if (_found.length == _cards.length) celebrate(context, text: '¡Memoria de elefante! 🐘');
      return;
    }
    _busy = true;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _open.clear();
        _busy = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _found.length == _cards.length;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.lang.flag} Memoria: ${widget.topic.label}', style: const TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: done
            ? _finish(context, title: '¡Lo lograste!', detail: 'Encontraste las ${_cards.length ~/ 2} parejas en $_moves intentos.', again: () => setState(_build))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Intentos: $_moves · Parejas: ${_found.length ~/ 2} de ${_cards.length ~/ 2}', style: mutedText(context).copyWith(fontSize: 15)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      for (var i = 0; i < _cards.length; i++)
                        Builder(builder: (context) {
                          final shown = _found.contains(i) || _open.contains(i);
                          final c = _cards[i];
                          return Material(
                            color: _found.contains(i)
                                ? Colors.green.shade100
                                : (shown ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primary),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              key: ValueKey('mem_$i'),
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _tap(i),
                              child: Center(
                                child: shown
                                    ? Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: FittedBox(
                                          child: Text(
                                            c.picture ? c.word.emoji : c.word.inLang(widget.lang),
                                            style: TextStyle(fontSize: c.picture ? 48 : 20, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      )
                                    : const Text('❓', style: TextStyle(fontSize: 32)),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// ------------------------------------------------------------ ordenar letras

/// Armar la palabra en el otro idioma tocando las letras en orden.
class LettersGameScreen extends StatefulWidget {
  const LettersGameScreen({super.key, required this.lang, required this.topic, this.random});

  final Lang lang;
  final Topic topic;
  final Random? random;

  @override
  State<LettersGameScreen> createState() => _LettersGameScreenState();
}

class _LettersGameScreenState extends State<LettersGameScreen> {
  static const rounds = 5;
  late final Random _r = widget.random ?? Random();
  late List<Word> _words;
  int _i = 0;
  int _ok = 0;
  late List<String> _letters;
  final List<int> _used = [];
  bool? _right;

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    _words = ([...widget.topic.words]..shuffle(_r)).take(rounds).toList();
    _i = 0;
    _ok = 0;
    _prepare();
  }

  String _target(Word w) => w.inLang(widget.lang).replaceAll(' ', '');

  void _prepare() {
    _used.clear();
    _right = null;
    if (_i >= _words.length) return;
    _letters = _target(_words[_i]).characters.toList()..shuffle(_r);
  }

  void _tap(int k) {
    if (_right != null || _used.contains(k)) return;
    setState(() => _used.add(k));
    if (_used.length == _letters.length) {
      final built = [for (final u in _used) _letters[u]].join();
      final ok = built.toLowerCase() == _target(_words[_i]).toLowerCase();
      setState(() {
        _right = ok;
        if (ok) _ok++;
      });
      Speech.instance.say(_words[_i].inLang(widget.lang), widget.lang.ttsLocale);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          _i++;
          _prepare();
        });
        if (_i >= _words.length && _ok >= rounds - 1) celebrate(context, text: '¡Gran deletreo! 🔤');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.lang.flag} Letras: ${widget.topic.label}', style: const TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: _i >= _words.length
            ? _finish(context, title: '$_ok de ${_words.length}', detail: 'Armaste bien $_ok palabras.', again: () => setState(_build))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  LinearProgressIndicator(value: (_i + 1) / _words.length),
                  const SizedBox(height: 16),
                  Center(child: Text(_words[_i].emoji, style: const TextStyle(fontSize: 72))),
                  Center(child: Text('"${_words[_i].es}" en ${widget.lang.label.toLowerCase()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  if (_words[_i].hint(widget.lang) != null)
                    Center(child: Text('Se lee: ${_words[_i].hint(widget.lang)}', style: mutedText(context))),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _right == null ? scheme.surfaceContainerHighest : (_right! ? Colors.green.shade100 : Colors.red.shade100),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _right == false ? 'Era: ${_words[_i].inLang(widget.lang)}' : [for (final u in _used) _letters[u]].join(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var k = 0; k < _letters.length; k++)
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: FilledButton.tonal(
                            key: ValueKey('letra_$k'),
                            style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                            onPressed: _used.contains(k) ? null : () => _tap(k),
                            child: Text(_letters[k], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _used.isEmpty || _right != null ? null : () => setState(_used.removeLast),
                      icon: const Icon(Icons.backspace_outlined),
                      label: const Text('Borrar'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
