import 'package:flutter/material.dart';

import '../../data/app_session.dart';
import '../../data/family_store.dart';
import '../../widgets/celebration.dart';
import '../../widgets/common.dart';

/// Dibujo del cuarto de un miembro, con su mascota.
class RoomView extends StatelessWidget {
  const RoomView({super.key, required this.memberId, this.showPetLabel = true});

  final String memberId;
  final bool showPetLabel;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final wall = store.roomItem(memberId, 'wall').color!;
    final floor = store.roomItem(memberId, 'floor').color!;
    final pet = store.roomItem(memberId, 'pet');
    final mood = store.petMood(memberId);
    final level = store.petLevel(memberId);
    final night = wall.computeLuminance() < .2;

    return AspectRatio(
      aspectRatio: 1.35,
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        Widget at(double x, double y, String emoji, double size) => emoji.isEmpty
            ? const SizedBox.shrink()
            : Align(alignment: Alignment(x, y), child: Text(emoji, style: TextStyle(fontSize: w * size)));
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(flex: 62, child: Container(color: wall)),
                  Expanded(flex: 38, child: Container(color: floor)),
                ],
              ),
              if (night)
                for (final (x, y) in const [(-.6, -.8), (.1, -.9), (.5, -.6), (-.2, -.5), (.85, -.85)])
                  Align(alignment: Alignment(x, y), child: Text('✦', style: TextStyle(color: Colors.white70, fontSize: w * .03))),
              at(-.75, -.6, '🪟', .14),
              at(.6, -.65, store.roomItem(memberId, 'poster').emoji, .11),
              at(0, -.95, store.roomItem(memberId, 'lamp').emoji, .08),
              at(.85, -.05, store.roomItem(memberId, 'shelf').emoji, .09),
              at(-.7, .55, store.roomItem(memberId, 'bed').emoji, .2),
              at(.45, .75, store.roomItem(memberId, 'toy').emoji, .09),
              at(.9, .6, store.roomItem(memberId, 'plant').emoji, .1),
              if (pet.emoji.isNotEmpty)
                Align(
                  alignment: const Alignment(-.05, .55),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Text(mood.face, style: TextStyle(fontSize: w * .04)),
                      ),
                      Text(pet.emoji, style: TextStyle(fontSize: w * (.1 + (level.clamp(1, 6) * .012)))),
                      if (showPetLabel)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                          child: Text('${store.petName(memberId)} · nivel $level',
                              style: TextStyle(color: Colors.white, fontSize: w * .03, fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

/// Mi cuarto: decorarlo con puntos y cuidar a la mascota.
class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  String _slot = 'pet';

  Future<void> _pick(FamilyStore store, String memberId, int index, bool plusOpen) async {
    final item = RoomCatalog.slots[_slot]!.items[index];
    if (store.ownsRoomItem(memberId, _slot, index, plusOpen: plusOpen)) {
      store.setRoom(memberId, _slot, index);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (item.premium) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('⭐ ${item.name} es de Family App Plus. Muy pronto se va a poder activar.')));
      return;
    }
    final balance = store.balanceOf(memberId);
    if (balance < item.cost) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Te faltan ${item.cost - balance} puntos para ${item.name}. ¡Seguí sumando!')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Comprar ${item.name}?'),
        content: Text('Cuesta ${item.cost} puntos y queda tuyo. Tenés $balance puntos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Todavía no')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Comprar')),
        ],
      ),
    );
    if (ok == true && mounted && store.buyRoomItem(memberId, _slot, index)) {
      celebrate(context, text: '¡${item.name}!');
    }
  }

  Future<void> _renamePet(FamilyStore store, String memberId) async {
    final controller = TextEditingController(text: store.petName(memberId));
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cómo se llama tu mascota?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 14,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Guardar')),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) store.setRoom(memberId, 'petName', name);
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final plusOpen = SessionScope.of(context).plusOpen;
    final me = store.currentMember;
    if (me == null) return const Scaffold(body: SizedBox.shrink());
    final items = RoomCatalog.slots[_slot]!.items;
    final mood = store.petMood(me.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi cuarto', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('${store.balanceOf(me.id)} pts', style: const TextStyle(fontWeight: FontWeight.w900))),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RoomView(memberId: me.id),
            const SizedBox(height: 10),
            if (store.hasPet(me.id))
              InfoCard(
                child: Row(
                  children: [
                    Text(mood.face, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${store.petName(me.id)} está ${mood.label.toLowerCase()}. '
                        'Crece un nivel cada 3 días que completás tu rutina.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cambiar el nombre',
                      onPressed: () => _renamePet(store, me.id),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final e in RoomCatalog.slots.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(e.value.label),
                        selected: _slot == e.key,
                        onSelected: (_) => setState(() => _slot = e.key),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < items.length; i++)
                  _ItemChip(
                    item: items[i],
                    selected: store.roomChoice(me.id, _slot) == i,
                    owned: store.ownsRoomItem(me.id, _slot, i, plusOpen: plusOpen),
                    onTap: () => _pick(store, me.id, i, plusOpen),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({required this.item, required this.selected, required this.owned, required this.onTap});

  final RoomItem item;
  final bool selected;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: owned ? scheme.surface : scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? scheme.primary : Colors.black12, width: selected ? 3 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 96,
          height: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.color != null)
                Container(width: 34, height: 34, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle, border: Border.all(color: Colors.black12)))
              else
                Text(item.emoji.isEmpty ? '✖️' : item.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 4),
              Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              Text(
                owned ? (selected ? 'Puesto' : 'Tuyo') : (item.premium ? '⭐ Plus' : '🔒 ${item.cost} pts'),
                style: mutedText(context).copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
