import 'dart:math';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';

/// Editor del avatar estilo Funko con vista previa en vivo.
class AvatarEditorScreen extends StatefulWidget {
  const AvatarEditorScreen({super.key});

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  AvatarConfig? _config;
  final _random = Random();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _config ??= FamilyScope.of(context).currentMember?.avatar ?? const AvatarConfig();
  }

  void _set(AvatarConfig c) => setState(() => _config = c);

  void _surprise() => _set(AvatarConfig(
        skin: _random.nextInt(AvatarOptions.skins.length),
        hairStyle: _random.nextInt(AvatarOptions.hairStyles.length),
        hairColor: _random.nextInt(AvatarOptions.hairColors.length),
        eyes: _random.nextInt(AvatarOptions.eyes.length),
        glasses: _random.nextDouble() > 0.6,
        shirt: _random.nextInt(AvatarOptions.shirts.length),
        accessory: _random.nextInt(4), // solo accesorios libres
      ));

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final me = store.currentMember;
    final c = _config!;
    final balance = me == null ? 0 : store.balanceOf(me.id);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi avatar', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            TextButton.icon(onPressed: _surprise, icon: const Icon(Icons.casino_outlined), label: const Text('Sorpresa')),
          ],
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 250,
              decoration: BoxDecoration(color: const Color(0xFFDCE7FF), borderRadius: BorderRadius.circular(28)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AvatarView.full(config: c, size: 260),
                  if (me != null)
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Text(me.nickname, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                      ),
                    ),
                ],
              ),
            ),
            const TabBar(
              isScrollable: false,
              tabs: [Tab(text: 'Piel'), Tab(text: 'Pelo'), Tab(text: 'Ojos'), Tab(text: 'Ropa'), Tab(text: 'Extras')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _Pane(children: [
                    _Swatches(
                      title: 'Tono de piel',
                      options: AvatarOptions.skins,
                      selected: c.skin,
                      onPick: (i) => _set(c.copyWith(skin: i)),
                    ),
                  ]),
                  _Pane(children: [
                    _Chips(
                      title: 'Peinado',
                      options: AvatarOptions.hairStyles,
                      selected: c.hairStyle,
                      onPick: (i) => _set(c.copyWith(hairStyle: i)),
                    ),
                    _Swatches(
                      title: 'Color de pelo',
                      options: AvatarOptions.hairColors,
                      selected: c.hairColor,
                      onPick: (i) => _set(c.copyWith(hairColor: i)),
                    ),
                  ]),
                  _Pane(children: [
                    _Chips(
                      title: 'Ojos',
                      options: AvatarOptions.eyes,
                      selected: c.eyes,
                      onPick: (i) => _set(c.copyWith(eyes: i)),
                    ),
                    SwitchListTile(
                      title: const Text('Anteojos', style: TextStyle(fontWeight: FontWeight.w800)),
                      value: c.glasses,
                      onChanged: (v) => _set(c.copyWith(glasses: v)),
                    ),
                  ]),
                  _Pane(children: [
                    _Swatches(
                      title: 'Color de la remera',
                      options: AvatarOptions.shirts,
                      selected: c.shirt,
                      onPick: (i) => _set(c.copyWith(shirt: i)),
                    ),
                  ]),
                  _Pane(children: [
                    Text('Accesorios', style: sectionTitle(context)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < AvatarOptions.accessories.length; i++)
                          ChoiceChip(
                            label: Text(AvatarOptions.accessories[i].$2 > balance
                                ? '${AvatarOptions.accessories[i].$1} · ${AvatarOptions.accessories[i].$2} pts'
                                : AvatarOptions.accessories[i].$1),
                            avatar: AvatarOptions.accessories[i].$2 > balance ? const Icon(Icons.lock_outline, size: 18) : null,
                            selected: c.accessory == i,
                            onSelected: AvatarOptions.accessories[i].$2 > balance ? null : (_) => _set(c.copyWith(accessory: i)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Los accesorios bloqueados se ganan con puntos.', style: mutedText(context)),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  onPressed: me == null
                      ? null
                      : () {
                          store.updateAvatar(me.id, c);
                          Navigator.of(context).pushReplacementNamed(me.role.isAdult ? Routes.adult : Routes.child);
                        },
                  child: const Text('Guardar mi avatar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        children: children,
      );
}

class _Swatches extends StatelessWidget {
  const _Swatches({required this.title, required this.options, required this.selected, required this.onPick});

  final String title;
  final List<(String, Color)> options;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: sectionTitle(context)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < options.length; i++)
                Semantics(
                  button: true,
                  selected: selected == i,
                  label: options[i].$1,
                  child: InkResponse(
                    onTap: () => onPick(i),
                    radius: 28,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: options[i].$2,
                        shape: BoxShape.circle,
                        border: Border.all(color: selected == i ? accent : AppColors.line, width: 3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.title, required this.options, required this.selected, required this.onPick});

  final String title;
  final List<String> options;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: sectionTitle(context)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < options.length; i++)
                ChoiceChip(label: Text(options[i]), selected: selected == i, onSelected: (_) => onPick(i)),
            ],
          ),
        ],
      ),
    );
  }
}
