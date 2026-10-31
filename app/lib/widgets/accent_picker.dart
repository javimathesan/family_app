import 'package:flutter/material.dart';

import '../data/app_session.dart';
import '../data/family_store.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

const _accentNames = ['Azul', 'Verde agua', 'Violeta', 'Naranja'];

void _plusSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('⭐ Disponible con Family App Plus. Muy pronto se va a poder activar.')));
}

/// Hoja inferior para personalizar la app de cada miembro: modo, color,
/// fondo y tarjetas. Lo marcado con ⭐ es de Family App Plus.
Future<void> showAccentPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => ListenableBuilder(
      listenable: FamilyScope.of(context),
      builder: (sheetContext, _) {
        final store = FamilyScope.of(context);
        final plus = SessionScope.of(context).plusOpen;
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
                const Text('Personalizar mi app', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                if (!plus)
                  const Text('Lo marcado con ⭐ es de Family App Plus.', style: TextStyle(color: AppColors.muted)),
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
              ],
            ),
          ),
        );
      },
    ),
  );
}
