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

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final session = SessionScope.of(context);
    final me = store.currentMember;
    // En la nube la lista vive en el hogar: la editan los administradores.
    final canEdit = !session.isCloud || (me?.role.canManage ?? false);
    final items = store.shopping;
    final bought = items.where((i) => i.done).length;
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
                              onChanged: canEdit ? (_) => store.toggleShopping(i.id) : null,
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
