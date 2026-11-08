import 'package:flutter/material.dart';

import '../data/app_session.dart';
import '../data/family_store.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common.dart';

const _accentNames = ['Azul', 'Verde agua', 'Violeta', 'Naranja'];

void _plusSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('⭐ Disponible con Family App Plus. Muy pronto se va a poder activar.')));
}

/// Hoja inferior para personalizar la app de cada miembro: modo, color,
/// fondo y tarjetas. Lo marcado con ⭐ es de Family App Plus.
Future<void> showAccentPicker(BuildContext context) {
  // Se toman ahora: al cambiar de mundo la pantalla de atrás se rearma.
  final store = FamilyScope.of(context);
  final session = SessionScope.of(context);
  final start = store.currentMember;
  // Para "Volver a como estaba".
  final startLook = start?.look;
  final startAccent = start?.accent;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => ListenableBuilder(
      listenable: store,
      builder: (sheetContext, _) {
        final plus = session.plusOpen;
        final me = store.currentMember;
        if (me == null) return const SizedBox.shrink();
        final look = me.look;

        Widget swatch({required Color color, required bool selected, required bool locked, required VoidCallback onTap, String? label}) {
          return Semantics(
            button: true,
            selected: selected,
            label: label,
            child: InkResponse(
              radius: 30,
              onTap: locked ? () => _plusSoon(sheetContext) : onTap,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? AppColors.ink : Colors.black12, width: selected ? 3 : 1),
                ),
                child: selected
                    ? Icon(Icons.check, color: color.computeLuminance() > .5 ? AppColors.ink : Colors.white)
                    : (locked ? const Icon(Icons.star, size: 18, color: Color(0xFFF5B800)) : null),
              ),
            ),
          );
        }

        Widget title(String text) => Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            );

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Personalizar mi app', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                    if (startLook != null && (startLook != look || startAccent != me.accent))
                      TextButton.icon(
                        onPressed: () {
                          store.setLook(me.id, startLook);
                          if (startAccent != null) store.setAccent(me.id, startAccent);
                        },
                        icon: const Icon(Icons.undo),
                        label: const Text('Como estaba'),
                      ),
                  ],
                ),
                if (!plus)
                  const Text('Lo marcado con ⭐ es de Family App Plus.', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 10),
                LookPreview(accent: me.accent, look: look, plus: plus),
                title('Temas'),
                SizedBox(
                  height: 84,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final t in LookOptions.themes)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _ThemeChip(
                            theme: t,
                            selected: me.accent == t.accent && look.background == t.background && look.world == t.world && look.cards == t.cards,
                            locked: t.plus && !plus,
                            onTap: () {
                              if (t.plus && !plus) return _plusSoon(sheetContext);
                              store.setAccent(me.id, t.accent);
                              store.setLook(me.id, look.copyWith(background: t.background, world: t.world, cards: t.cards));
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                title('Modo'),
                SegmentedButton<LookMode>(
                  segments: [
                    for (final m in LookMode.values)
                      ButtonSegment(
                        value: m,
                        label: Text(m.label),
                        icon: Icon(switch (m) {
                          LookMode.system => Icons.brightness_auto,
                          LookMode.light => Icons.light_mode,
                          LookMode.dark => Icons.dark_mode,
                        }),
                      ),
                  ],
                  selected: {look.mode},
                  onSelectionChanged: (s) => store.setLook(me.id, look.copyWith(mode: s.first)),
                ),
                title('Mi color'),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < AppColors.accents.length; i++)
                      swatch(
                        color: AppColors.accents[i],
                        label: _accentNames[i],
                        selected: me.accent == AppColors.accents[i],
                        locked: false,
                        onTap: () => store.setAccent(me.id, AppColors.accents[i]),
                      ),
                    for (final (name, color) in LookOptions.plusAccents)
                      swatch(
                        color: color,
                        label: name,
                        selected: me.accent == color,
                        locked: !plus,
                        onTap: () => store.setAccent(me.id, color),
                      ),
                  ],
                ),
                title('Fondo'),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < LookOptions.backgrounds.length; i++)
                      swatch(
                        color: LookOptions.backgrounds[i].color,
                        label: LookOptions.backgrounds[i].name,
                        selected: look.background == i,
                        locked: LookOptions.backgrounds[i].plus && !plus,
                        onTap: () => store.setLook(me.id, look.copyWith(background: i)),
                      ),
                  ],
                ),
                title('Festejo'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < LookOptions.parties.length; i++)
                      ChoiceChip(
                        avatar: Text(LookOptions.parties[i].emoji),
                        label: Text(LookOptions.parties[i].plus && !plus ? '${LookOptions.parties[i].name} ⭐' : LookOptions.parties[i].name),
                        selected: look.party == i,
                        onSelected: (_) => LookOptions.parties[i].plus && !plus
                            ? _plusSoon(sheetContext)
                            : store.setLook(me.id, look.copyWith(party: i)),
                      ),
                  ],
                ),
                title('Mundo ⭐'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < LookOptions.worlds.length; i++)
                      ChoiceChip(
                        avatar: i == 0 ? null : Text(LookOptions.worlds[i].emojis.characters.first),
                        label: Text(LookOptions.worlds[i].name),
                        selected: look.world == i,
                        onSelected: (_) => i > 0 && !plus
                            ? _plusSoon(sheetContext)
                            : store.setLook(me.id, look.copyWith(world: i)),
                      ),
                  ],
                ),
                title('Tarjetas'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < LookOptions.cards.length; i++)
                      ChoiceChip(
                        avatar: LookOptions.cards[i].plus && !plus ? const Icon(Icons.star, size: 16, color: Color(0xFFF5B800)) : null,
                        label: Text(LookOptions.cards[i].name),
                        selected: look.cards == i,
                        onSelected: (_) => LookOptions.cards[i].plus && !plus
                            ? _plusSoon(sheetContext)
                            : store.setLook(me.id, look.copyWith(cards: i)),
                      ),
                  ],
                ),
                if (!me.role.isAdult) ...[
                  title('Color de cada tarjeta ⭐'),
                  for (final e in todayCardNames.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w700))),
                          for (var i = -1; i < LookOptions.tints.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _MiniSwatch(
                                key: ValueKey('tinte_${e.key}_$i'),
                                color: i < 0 ? null : LookOptions.tints[i].color,
                                label: i < 0 ? 'Sin color' : LookOptions.tints[i].name,
                                selected: (look.tints[e.key] ?? -1) == i,
                                locked: i >= 0 && !plus,
                                onTap: () {
                                  if (i >= 0 && !plus) return _plusSoon(sheetContext);
                                  final tints = {...look.tints};
                                  if (i < 0) {
                                    tints.remove(e.key);
                                  } else {
                                    tints[e.key] = i;
                                  }
                                  store.setLook(me.id, look.copyWith(tints: tints));
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}


/// Nombres cortos de las tarjetas de Hoy que se pueden pintar.
const todayCardNames = <String, String>{
  'mascota': 'Mascota',
  'reto': 'Reto',
  'agenda': 'Agenda',
  'palabra': 'Palabra',
  'cuerpo': 'Hábitos',
};

class _MiniSwatch extends StatelessWidget {
  const _MiniSwatch({super.key, required this.color, required this.label, required this.selected, required this.locked, required this.onTap});

  final Color? color;
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: InkResponse(
            radius: 18,
            onTap: onTap,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color ?? Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppColors.ink : Colors.black26, width: selected ? 2.5 : 1),
              ),
              child: color == null
                  ? const Icon(Icons.block, size: 14, color: Colors.black38)
                  : (locked ? const Icon(Icons.star, size: 12, color: Color(0xFFF5B800)) : null),
            ),
          ),
        ),
      );
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({required this.theme, required this.selected, required this.locked, required this.onTap});

  final ({String name, String emoji, Color accent, int background, int world, int cards, bool plus}) theme;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = theme.world > 0 ? LookOptions.worlds[theme.world].background : LookOptions.backgrounds[theme.background].color;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Tema ${theme.name}',
      child: InkWell(
        key: ValueKey('tema_${theme.name}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 76,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? theme.accent : Colors.black12, width: selected ? 3 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(radius: 16, backgroundColor: theme.accent, child: Text(theme.emoji, style: const TextStyle(fontSize: 16))),
                  if (locked) const Positioned(right: -8, top: -6, child: Icon(Icons.star, size: 16, color: Color(0xFFF5B800))),
                ],
              ),
              const SizedBox(height: 6),
              Text(theme.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vista previa chiquita de la pantalla con lo elegido (se actualiza al tocar).
class LookPreview extends StatelessWidget {
  const LookPreview({super.key, required this.accent, required this.look, required this.plus});

  final Color accent;
  final MemberLook look;
  final bool plus;

  @override
  Widget build(BuildContext context) {
    final dark = switch (look.mode) {
      LookMode.dark => true,
      LookMode.light => false,
      LookMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    final theme = dark ? AppTheme.dark(accent, look) : AppTheme.light(accent, look);
    final world = look.world > 0 && look.world < LookOptions.worlds.length ? LookOptions.worlds[look.world] : null;
    Color? tint(String id) {
      final i = look.tints[id];
      return plus && i != null && i >= 0 && i < LookOptions.tints.length ? LookOptions.tints[i].color : null;
    }

    Widget card(String id, String text) {
      final c = tint(id);
      final child = InfoCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
      );
      return c == null ? child : CardTint(color: c, child: child);
    }

    return Theme(
      data: theme,
      child: Container(
        key: const ValueKey('vista_previa'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (world != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(world.emojis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, letterSpacing: 6)),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(16)),
              child: const Text('Puntos de hoy · 35 pts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: card('mascota', '🐶 Mascota')),
                const SizedBox(width: 8),
                Expanded(child: card('reto', '🏆 Reto')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
