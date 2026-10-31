import 'package:flutter/material.dart';

import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/crest_badge.dart';

/// El adulto arma el escudo de la familia.
class CrestScreen extends StatefulWidget {
  const CrestScreen({super.key});

  @override
  State<CrestScreen> createState() => _CrestScreenState();
}

class _CrestScreenState extends State<CrestScreen> {
  FamilyCrest? _crest;
  late final TextEditingController _motto = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_crest == null) {
      _crest = FamilyScope.of(context).crest ?? const FamilyCrest();
      _motto.text = _crest!.motto;
    }
  }

  @override
  void dispose() {
    _motto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final crest = _crest!;
    void set(FamilyCrest c) => setState(() => _crest = c);
    return Scaffold(
      appBar: AppBar(title: const Text('Escudo de la familia', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: CrestBadge(crest: crest, size: 140)),
            const SizedBox(height: 8),
            Center(child: Text(store.homeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
            if (_motto.text.trim().isNotEmpty) Center(child: Text('"${_motto.text.trim()}"', style: mutedText(context).copyWith(fontSize: 15))),
            const SizedBox(height: 16),
            Text('Forma', style: sectionTitle(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < FamilyCrest.shapes.length; i++)
                  ChoiceChip(label: Text(FamilyCrest.shapes[i]), selected: crest.shape == i, onSelected: (_) => set(crest.copyWith(shape: i))),
              ],
            ),
            const SizedBox(height: 16),
            Text('Color', style: sectionTitle(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in FamilyCrest.colors)
                  InkResponse(
                    onTap: () => set(crest.copyWith(color: c)),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(color: crest.color == c ? const Color(0xFFF5B800) : Colors.transparent, width: 4),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Dibujo', style: sectionTitle(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in FamilyCrest.emojis)
                  ChoiceChip(
                    label: Text(e, style: const TextStyle(fontSize: 22)),
                    selected: crest.emoji == e,
                    onSelected: (_) => set(crest.copyWith(emoji: e)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _motto,
              maxLength: 30,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Lema (opcional)', hintText: 'Juntos podemos', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                store.setCrest(crest.copyWith(motto: _motto.text.trim()));
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: const Text('Guardar escudo'),
            ),
          ],
        ),
      ),
    );
  }
}
