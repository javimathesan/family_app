import 'package:flutter/material.dart';

import '../../data/app_session.dart';
import '../../data/family_store.dart';
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

  /// Pide el precio aproximado (vacío = sin precio).
  Future<void> _askPrice(FamilyStore store, String id, String name, double? current) async {
    final controller = TextEditingController(text: current == null ? '' : money(current).replaceAll(r'$ ', ''));
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Cuánto salió $name?'),
        content: TextField(
          key: const ValueKey('precio_campo'),
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Aproximado', border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Saltear')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
    if (result == null) return;
    store.setShoppingPrice(id, parseMoney(result));
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
                          helperText: 'Podés sumar varias separadas por coma.',
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
                                      onPressed: canEdit ? () => _askPrice(store, i.id, i.name, i.price) : null,
                                      child: Text(i.price == null ? '\$ —' : money(i.price!),
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                    )
                                  : null,
                              onChanged: !canEdit
                                  ? null
                                  : (_) {
                                      store.toggleShopping(i.id);
                                      // Al tildar algo sin precio, pregunta cuánto salió (se puede saltear).
                                      if (prices && !i.done && i.price == null) _askPrice(store, i.id, i.name, null);
                                    },
                              title: Text(
                                i.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  decoration: i.done ? TextDecoration.lineThrough : null,
                                  color: i.done ? Theme.of(context).disabledColor : null,
                                ),
                              ),
                              subtitle: i.by == null ? null : Text('Lo agregó ${i.by}'),
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
