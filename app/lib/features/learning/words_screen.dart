import 'dart:math';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/app_session.dart';
import '../../data/family_store.dart';
import '../../learning/vocabulary.dart';
import '../../services/speech.dart';
import '../../widgets/celebration.dart';
import '../../widgets/common.dart';

/// Idiomas que ve el hogar (en el orden de [Lang]).
List<Lang> homeLanguages(FamilyStore store) =>
    [for (final l in Lang.values) if (store.languages.contains(l.name)) l];

/// Aprender palabras: idioma, tema y modo (tarjetas o quiz).
class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  Lang? _lang;
  WordLevel _level = WordLevel.basico;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final session = SessionScope.of(context);
    final me = store.currentMember;
    final langs = homeLanguages(store);
    final lang = langs.contains(_lang) ? _lang! : (langs.isEmpty ? Lang.en : langs.first);
    final isAdmin = (me?.role.isAdult ?? false) && session.isAdmin;
    // En la demostración se puede probar todo; en un hogar real, el avanzado es de Plus.
    final advancedOpen = store.hasPlus || !session.isCloud;
    final locked = _level == WordLevel.avanzado && !advancedOpen;

    return Scaffold(
      appBar: AppBar(title: const Text('Aprender palabras', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Idioma', style: sectionTitle(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final l in langs)
                  ChoiceChip(
                    label: Text('${l.flag} ${l.label}'),
                    selected: l == lang,
                    onSelected: (_) => setState(() => _lang = l),
                  ),
              ],
            ),
            if (me != null && !me.role.isAdult) ...[
              const SizedBox(height: 8),
              Text(
                store.wordQuizDoneToday(me.id)
                    ? 'Ya ganaste los puntos del quiz de hoy. ¡Podés seguir practicando!'
                    : 'Hacé un quiz y ganá 1 punto por cada respuesta correcta (una vez por día).',
                style: mutedText(context),
              ),
            ],
            const SizedBox(height: 16),
            Text('Nivel', style: sectionTitle(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final l in WordLevel.values)
                  ChoiceChip(
                    avatar: l == WordLevel.avanzado && !advancedOpen ? const Icon(Icons.lock_outline, size: 18) : null,
                    label: Text(l.label),
                    selected: l == _level,
                    onSelected: (_) => setState(() => _level = l),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_level.description, style: mutedText(context)),
            const SizedBox(height: 16),
            if (locked)
              InfoCard(
                color: const Color(0xFFF3E5F5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.workspace_premium, color: Color(0xFF7B1FA2), size: 32),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Nivel avanzado: Family App Plus',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Incluye ${[for (final t in topicsOf(WordLevel.avanzado)) t.label.toLowerCase()].join(', ')}. '
                        'Muy pronto se va a poder activar desde la app.'),
                  ],
                ),
              ),
            Text('Temas', style: sectionTitle(context)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                for (final t in topicsOf(_level))
                  Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: locked ? null : () => _chooseMode(context, lang, t),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(t.emoji, style: const TextStyle(fontSize: 28)),
                                const Spacer(),
                                if (locked) const Icon(Icons.lock_outline),
                              ],
                            ),
                            const Spacer(),
                            Text(t.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            Text('${t.words.length} palabras', style: mutedText(context)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isAdmin) ...[
              const SizedBox(height: 20),
              Text('Idiomas del hogar', style: sectionTitle(context)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final l in Lang.values)
                    FilterChip(
                      label: Text('${l.flag} ${l.label}'),
                      selected: store.languages.contains(l.name),
                      onSelected: (on) {
                        final next = [...store.languages];
                        if (on) {
                          next.add(l.name);
                        } else if (next.length > 1) {
                          next.remove(l.name);
                        }
                        store.setLanguages(next);
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _chooseMode(BuildContext context, Lang lang, Topic topic) async {
    final mode = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.style_outlined),
              title: const Text('Tarjetas', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('Mirá y escuchá las palabras de ${topic.label.toLowerCase()} en ${lang.label.toLowerCase()}'),
              onTap: () => Navigator.pop(ctx, 'tarjetas'),
            ),
            ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: const Text('Quiz de 5 preguntas', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Elegí la palabra correcta'),
              onTap: () => Navigator.pop(ctx, 'quiz'),
            ),
          ],
        ),
      ),
    );
    if (mode == null || !context.mounted) return;
    Navigator.of(context).pushNamed('${Routes.words}/$mode?lang=${lang.name}&topic=${topic.id}');
  }
}

/// Botón para escuchar una palabra.
class SpeakButton extends StatelessWidget {
  const SpeakButton({super.key, required this.text, required this.lang, this.size = 32});

  final String text;
  final Lang lang;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
        tooltip: 'Escuchar',
        iconSize: size,
        onPressed: () => Speech.instance.say(text, lang.ttsLocale),
        icon: const Icon(Icons.volume_up),
      );
}

/// Tarjetas: dibujo, palabra en español y en el otro idioma, con su sonido.
class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key, required this.lang, required this.topic});

  final Lang lang;
  final Topic topic;

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.topic.words;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.lang.flag} ${widget.topic.label}', style: const TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: words.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final w = words[i];
                  final hint = w.hint(widget.lang);
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: InfoCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(w.emoji, style: const TextStyle(fontSize: 96)),
                          const SizedBox(height: 12),
                          Text(w.es, style: mutedText(context).copyWith(fontSize: 20)),
                          const SizedBox(height: 8),
                          Text(w.inLang(widget.lang),
                              textAlign: TextAlign.center, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
                          if (hint != null) Text('Se lee: $hint', style: mutedText(context).copyWith(fontSize: 16)),
                          const SizedBox(height: 16),
                          SpeakButton(text: w.inLang(widget.lang), lang: widget.lang, size: 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _index == 0 ? null : () => _pages.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                    icon: const Icon(Icons.chevron_left, size: 36),
                  ),
                  Expanded(child: Text('${_index + 1} de ${words.length}', textAlign: TextAlign.center)),
                  IconButton(
                    onPressed: _index == words.length - 1
                        ? null
                        : () => _pages.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                    icon: const Icon(Icons.chevron_right, size: 36),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiz de 5 preguntas: se ve el dibujo y la palabra en español, y se elige la traducción.
class WordQuizScreen extends StatefulWidget {
  const WordQuizScreen({super.key, required this.lang, required this.topic, this.random});

  final Lang lang;
  final Topic topic;
  final Random? random;

  @override
  State<WordQuizScreen> createState() => _WordQuizScreenState();
}

class _WordQuizScreenState extends State<WordQuizScreen> {
  static const questions = 5;
  late final Random _random = widget.random ?? Random();
  late List<({Word word, List<Word> options})> _quiz;
  int _index = 0;
  int _correct = 0;
  Word? _picked;
  int? _awarded;

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    final words = [...widget.topic.words]..shuffle(_random);
    _quiz = [
      for (final w in words.take(questions))
        (
          word: w,
          options: ([w, ...([...widget.topic.words]..remove(w)..shuffle(_random)).take(3)]..shuffle(_random)),
        ),
    ];
    _index = 0;
    _correct = 0;
    _picked = null;
    _awarded = null;
  }

  void _pick(Word w) {
    if (_picked != null) return;
    final q = _quiz[_index];
    setState(() {
      _picked = w;
      if (w == q.word) _correct++;
    });
    Speech.instance.say(q.word.inLang(widget.lang), widget.lang.ttsLocale);
  }

  void _next() {
    if (_index < _quiz.length - 1) {
      setState(() {
        _index++;
        _picked = null;
      });
      return;
    }
    final store = FamilyScope.of(context);
    final me = store.currentMember;
    final points = me == null ? 0 : store.awardWordQuiz(me.id, _correct, widget.lang.label.toLowerCase());
    setState(() {
      _index = _quiz.length;
      _awarded = points;
    });
    if (points > 0) celebrate(context, text: '+$points pts');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.lang.flag} Quiz: ${widget.topic.label}', style: const TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(child: _index >= _quiz.length ? _result(context) : _question(context)),
    );
  }

  Widget _question(BuildContext context) {
    final q = _quiz[_index];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LinearProgressIndicator(value: (_index + 1) / _quiz.length),
        const SizedBox(height: 16),
        Center(child: Text(q.word.emoji, style: const TextStyle(fontSize: 80))),
        const SizedBox(height: 8),
        Text('¿Cómo se dice "${q.word.es}" en ${widget.lang.label.toLowerCase()}?',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        for (final o in q.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              height: 60,
              child: FilledButton.tonal(
                key: ValueKey('opcion_${o.es}'),
                style: FilledButton.styleFrom(
                  backgroundColor: _picked == null
                      ? null
                      : o == q.word
                          ? Colors.green.shade300
                          : (o == _picked ? Colors.red.shade300 : null),
                ),
                onPressed: () => _pick(o),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(o.inLang(widget.lang), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    if (o.hint(widget.lang) != null) Text(o.hint(widget.lang)!, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        if (_picked != null) ...[
          const SizedBox(height: 8),
          Text(_picked == q.word ? '¡Muy bien! 🎉' : 'Era "${q.word.inLang(widget.lang)}"',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          FilledButton(onPressed: _next, child: Text(_index < _quiz.length - 1 ? 'Siguiente' : 'Ver resultado')),
        ],
      ],
    );
  }

  Widget _result(BuildContext context) {
    final points = _awarded ?? 0;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_correct >= 4 ? '🏆' : (_correct >= 2 ? '⭐' : '💪'), style: const TextStyle(fontSize: 80)),
          Text('$_correct de ${_quiz.length}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            points > 0 ? '¡Ganaste $points puntos!' : 'Seguí practicando para aprender más palabras.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => setState(_build),
            icon: const Icon(Icons.replay),
            label: const Text('Otra vez'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Volver')),
        ],
      ),
    );
  }
}
