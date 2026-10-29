import 'package:flutter/material.dart';

import '../data/family_store.dart';
import '../theme/app_theme.dart';

const _accentNames = ['Azul', 'Verde agua', 'Violeta', 'Naranja'];

/// Hoja inferior para que cada miembro elija su color de acento.
Future<void> showAccentPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final store = FamilyScope.of(sheetContext);
      final me = store.currentMember;
      if (me == null) return const SizedBox.shrink();
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mi color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Cambia los botones y las tarjetas principales de tu app.',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (var i = 0; i < AppColors.accents.length; i++)
                    Semantics(
                      button: true,
                      selected: me.accent == AppColors.accents[i],
                      label: _accentNames[i],
                      child: InkResponse(
                        radius: 32,
                        onTap: () => store.setAccent(me.id, AppColors.accents[i]),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.accents[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: me.accent == AppColors.accents[i] ? AppColors.ink : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: me.accent == AppColors.accents[i]
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
