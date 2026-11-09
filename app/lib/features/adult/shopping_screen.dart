import 'package:flutter/material.dart';

import '../../data/app_session.dart';
import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// Lista de compras del hogar, compartida entre los adultos.
class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(FamilyStore store, String? by) {
    if (_text.text.trim().isEmpty) return;
    store.addShopping(_text.text, by: by);
    _text.clear();
    _focus.requestFocus();
  }

  /// Pide cantidad y precio por unidad (precio vacío = sin precio).
  Future<void> _askAmount(FamilyStore store, ShoppingItem item) async {
    final qtyText = TextEditingController(text: qtyLabel(item.qty));
    final priceText = TextEditingController(text: item.price == null ? '' : money(item.price!).replaceAll(r'$ ', ''));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final qty = parseMoney(qtyText.text) ?? 1;
          final price = parseMoney(priceText.text);
          return AlertDialog(
            title: Text(item.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton.outlined(
                      tooltip: 'Una menos',
                      onPressed: qty > 1 ? () => setLocal(() => qtyText.text = qtyLabel(qty - 1)) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextField(
                          key: const ValueKey('cantidad_campo'),
                          controller: qtyText,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder(), isDense: true),
                          onChanged: (_) => setLocal(() {}),
                        ),
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: 'Una más',
                      onPressed: () => setLocal(() => qtyText.text = qtyLabel(qty + 1)),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('precio_campo'),
                  controller: priceText,
                  autofocus: item.price == null,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Precio por unidad',
                    prefixText: '\$ ',
                    hintText: 'Aproximado',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setLocal(() {}),
                ),
                const SizedBox(height: 12),
                Text(
                  price == null ? 'Sin precio' : '${qtyLabel(qty)} × ${money(price)} = ${money(qty * price)}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Saltear')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    store.setShoppingAmount(item.id, qty: parseMoney(qtyText.text) ?? 1, price: parseMoney(priceText.text));
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final session = SessionScope.of(context);
    final me = store.currentMember;
    // En la nube la lista vive en el hogar: la editan los administradores.
    final canEdit = !session.isCloud || (me?.role.canManage ?? false);
    final items = store.shopping;
    final bought = items.where((i) => i.done).length;
    final prices = me != null && store.usesTool(me.id, 'compras_precios');
    final date = store.shoppingDate;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de compras', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (canEdit && bought > 0)
            TextButton.icon(
              onPressed: store.clearBoughtShopping,
              icon: const Icon(Icons.cleaning_services_outlined),
              label: Text('Borrar comprados ($bought)'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            ListTile(
              key: const ValueKey('fecha_compra'),
              leading: const Icon(Icons.event_outlined),
              title: Text(date == null ? 'Sin fecha de compra' : 'Próxima compra: ${longDate(date)}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(canEdit ? (date == null ? 'Tocá para elegir una fecha probable' : 'Tocá para cambiarla') : 'La elige un administrador'),
              trailing: date != null && canEdit
                  ? IconButton(tooltip: 'Quitar la fecha', icon: const Icon(Icons.close), onPressed: () => store.setShoppingDate(null))
                  : null,
              onTap: !canEdit
                  ? null
                  : () async {
                      final now = store.now;
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date != null && !date.isBefore(DateTime(now.year, now.month, now.day)) ? date : now,
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: now.add(const Duration(days: 120)),
                      );
                      if (picked != null) store.setShoppingDate(picked);
                    },
            ),
            if (canEdit)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('compra_nueva'),
                        controller: _text,
                        focusNode: _focus,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _add(store, me?.nickname),
                        decoration: const InputDecoration(
                          hintText: 'Leche, pan, manzanas…',
                          helperText: 'Varias separadas por coma; cantidad al final: "arroz x4".',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: FilledButton(onPressed: () => _add(store, me?.nickname), child: const Text('Agregar')),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const Text('🛒', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text('La lista está vacía. Lo que agregues lo ven todos los adultos de la casa, '
                            'y en el súper cada uno va tildando lo que compra.',
                            textAlign: TextAlign.center, style: mutedText(context)),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
                      children: [
                        for (final i in items)
                          Dismissible(
                            key: ValueKey('compra_${i.id}'),
                            direction: canEdit ? DismissDirection.endToStart : DismissDirection.none,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete_outline),
                            ),
                            onDismissed: (_) => store.removeShopping(i.id),
                            child: CheckboxListTile(
                              controlAffinity: ListTileControlAffinity.leading,
                              value: i.done,
                              secondary: prices
                                  ? TextButton(
                                      key: ValueKey('precio_${i.id}'),
                                      onPressed: canEdit ? () => _askAmount(store, i) : null,
                                      child: Text(i.price == null ? '\$ —' : money(i.subtotal),
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                    )
                                  : null,
                              onChanged: !canEdit
                                  ? null
                                  : (_) {
                                      store.toggleShopping(i.id);
                                      // Al tildar algo sin precio, pregunta cuánto salió (se puede saltear).
                                      if (prices && !i.done && i.price == null) _askAmount(store, i);
                                    },
                              title: Text(
                                i.qty == 1 ? i.name : '${i.name} · ${qtyLabel(i.qty)}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  decoration: i.done ? TextDecoration.lineThrough : null,
                                  color: i.done ? Theme.of(context).disabledColor : null,
                                ),
                              ),
                              subtitle: _subtitle(i, prices),
                            ),
                          ),
                        if (prices && store.shoppingTotal > 0)
                          InfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('En el carrito: ${money(store.shoppingInCart)}',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                                Text('Total aproximado de la lista: ${money(store.shoppingTotal)}', style: mutedText(context)),
                                Text('${store.shopping.length} productos · ${qtyLabel(store.shoppingUnits)} unidades',
                                    style: mutedText(context)),
                              ],
                            ),
                          ),
                        if (canEdit)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text('Deslizá a la izquierda para borrar.', style: mutedText(context), textAlign: TextAlign.center),
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

/// "4 × $ 900 = $ 3.600 · Lo agregó Papá" (o nada).
Widget? _subtitle(ShoppingItem i, bool prices) {
  final parts = [
    if (prices && i.price != null) '${qtyLabel(i.qty)} × ${money(i.price!)} = ${money(i.subtotal)}',
    if (i.by != null) 'Lo agregó ${i.by}',
  ];
  return parts.isEmpty ? null : Text(parts.join(' · '));
}
