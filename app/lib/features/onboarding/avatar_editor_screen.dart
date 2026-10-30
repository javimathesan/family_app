import 'dart:math';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';

/// Editor del avatar estilo Funko con vista previa en vivo.
///
/// Los disfraces y accesorios con precio se desbloquean una vez pagando con
/// puntos y quedan para siempre.
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

  /// Los adultos tienen todo libre; los chicos desbloquean con puntos.
  bool _owns(FamilyStore store, Member? me, AvatarItem item) =>
      item.free || (me != null && (me.role.isAdult || store.hasUnlocked(me.id, item.id)));

  void _surprise(FamilyStore store, Member? me) {
    final outfits = [
      for (var i = 0; i < AvatarOptions.outfits.length; i++)
        if (_owns(store, me, AvatarOptions.outfits[i])) i,
    ];
    final accessories = [
      for (var i = 0; i < AvatarOptions.accessories.length; i++)
        if (_owns(store, me, AvatarOptions.accessories[i])) i,
    ];
    _set(AvatarConfig(
      skin: _config!.skin,
      hairStyle: _random.nextInt(AvatarOptions.hairStyles.length),
      hairColor: _random.nextInt(AvatarOptions.hairColors.length),
      eyes: _random.nextInt(AvatarOptions.eyes.length),
      glasses: _random.nextDouble() > 0.7,
      shirt: _random.nextInt(AvatarOptions.shirts.length),
      outfit: outfits[_random.nextInt(outfits.length)],
      accessory: accessories[_random.nextInt(accessories.length)],
    ));
  }

  /// Elige un disfraz o accesorio; si está bloqueado, ofrece desbloquearlo.
  Future<void> _pick(FamilyStore store, Member? me, AvatarItem item, AvatarConfig Function() apply) async {
    if (_owns(store, me, item)) {
      _set(apply());
      return;
    }
    if (me == null) return;
    final balance = store.balanceOf(me.id);
    if (balance < item.cost) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Te faltan ${item.cost - balance} puntos para ${item.label}. ¡Seguí sumando!')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Desbloquear ${item.label}?'),
        content: Text('Cuesta ${item.cost} puntos y queda tuyo para siempre. Tenés $balance puntos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Todavía no')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desbloquear')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (store.unlockItem(me.id, item.id, item.cost)) _set(apply());
  }

  void _save(FamilyStore store, Member me) {
    store.updateAvatar(me.id, _config!);
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(me.role.isAdult ? Routes.adult : Routes.child);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final me = store.currentMember;
    final c = _config!;
    final balance = me == null ? 0 : store.balanceOf(me.id);

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi avatar', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            TextButton.icon(
              onPressed: () => _surprise(store, me),
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Sorpresa'),
            ),
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
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Text(me.nickname, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                      ),
                    ),
                  if (me != null)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Text('$balance pts', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                      ),
                    ),
                ],
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Disfraz'),
                Tab(text: 'Piel'),
                Tab(text: 'Pelo'),
                Tab(text: 'Ojos'),
                Tab(text: 'Color'),
                Tab(text: 'Extras'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _Pane(children: [
                    Text('Disfraces', style: sectionTitle(context)),
                    const SizedBox(height: 4),
                    Text('Los que tienen candado se desbloquean una vez con tus puntos.', style: mutedText(context)),
                    const SizedBox(height: 10),
                    _ItemGrid(
                      items: AvatarOptions.outfits,
                      selected: c.outfit,
                      owns: (item) => _owns(store, me, item),
                      onPick: (i) => _pick(store, me, AvatarOptions.outfits[i], () => _config!.copyWith(outfit: i)),
                    ),
                  ]),
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
                      title: 'Color de la ropa o del disfraz',
                      options: AvatarOptions.shirts,
                      selected: c.shirt,
                      onPick: (i) => _set(c.copyWith(shirt: i)),
                    ),
                  ]),
                  _Pane(children: [
                    Text('Accesorios', style: sectionTitle(context)),
                    const SizedBox(height: 4),
                    Text('Con disfraces que cubren la cabeza, el accesorio no se ve.', style: mutedText(context)),
                    const SizedBox(height: 10),
                    _ItemGrid(
                      items: AvatarOptions.accessories,
                      selected: c.accessory,
                      owns: (item) => _owns(store, me, item),
                      onPick: (i) => _pick(store, me, AvatarOptions.accessories[i], () => _config!.copyWith(accessory: i)),
                    ),
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
                  onPressed: me == null ? null : () => _save(store, me),
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

/// Grilla de disfraces o accesorios con miniatura, precio y candado.
class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.items, required this.selected, required this.owns, required this.onPick});

  final List<AvatarItem> items;
  final int selected;
  final bool Function(AvatarItem item) owns;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < items.length; i++)
          Semantics(
            button: true,
            selected: selected == i,
            label: owns(items[i]) ? items[i].label : '${items[i].label}, bloqueado, ${items[i].cost} puntos',
            child: Material(
              color: owns(items[i]) ? Theme.of(context).colorScheme.surface : AppColors.soft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: selected == i ? accent : AppColors.line, width: 2),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onPick(i),
                child: Container(
                  width: 104,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Column(
                    children: [
                      Text(items[i].label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.ink)),
                      const SizedBox(height: 4),
                      if (owns(items[i]))
                        Text(items[i].free ? 'Libre' : 'Tuyo', style: mutedText(context).copyWith(fontSize: 12))
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline, size: 14, color: AppColors.muted),
                            const SizedBox(width: 2),
                            Text('${items[i].cost} pts', style: mutedText(context).copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
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
