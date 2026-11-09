part of 'family_store.dart';

/// Lista de compras del hogar: la comparten los adultos.
extension FamilyShopping on FamilyStore {
  /// Primero lo que falta comprar (lo más nuevo arriba), después lo comprado.
  List<ShoppingItem> get shopping => [
        ...(_shopping.where((i) => !i.done).toList()..sort((a, b) => b.at.compareTo(a.at))),
        ...(_shopping.where((i) => i.done).toList()..sort((a, b) => b.at.compareTo(a.at))),
      ];

  int get shoppingPending => _shopping.where((i) => !i.done).length;

  /// Agrega uno o varios (separados por coma o renglón: "leche, pan").
  /// La cantidad se puede escribir al final: "arroz x4".
  void addShopping(String text, {String? by}) {
    final entries = text.split(RegExp(r',(?!\d)|\n'))  // la coma seguida de número es decimal (x1,5).map((n) => n.trim()).where((n) => n.isNotEmpty);
    for (final entry in entries) {
      final m = RegExp(r'^(.*?)\s*[xX×]\s*(\d+(?:[.,]\d+)?)$').firstMatch(entry);
      final name = (m == null ? entry : m.group(1)!).trim();
      final qty = m == null ? 1.0 : double.parse(m.group(2)!.replaceAll(',', '.'));
      if (name.isEmpty) continue;
      // Si ya estaba comprado, vuelve a la lista en lugar de repetirse.
      final existing = _shopping.where((i) => i.name.toLowerCase() == name.toLowerCase()).firstOrNull;
      if (existing != null) {
        if (existing.done) toggleShopping(existing.id);
        continue;
      }
      final item = ShoppingItem(id: _newId('c'), name: name, by: by, at: _clock(), qty: qty <= 0 ? 1 : qty);
      _shopping.add(item);
      sync?.shoppingSaved(item);
    }
    _changed();
  }

  void toggleShopping(String id) {
    final i = _shopping.indexWhere((x) => x.id == id);
    if (i < 0) return;
    _shopping[i] = _shopping[i].copyWith(done: !_shopping[i].done);
    sync?.shoppingSaved(_shopping[i]);
    _changed();
  }

  void removeShopping(String id) {
    _shopping.removeWhere((x) => x.id == id);
    sync?.shoppingRemoved([id]);
    _changed();
  }

  /// Precio aproximado de una cosa (`null` lo borra).
  void setShoppingPrice(String id, double? price) {
    final i = _shopping.indexWhere((x) => x.id == id);
    if (i < 0) return;
    _shopping[i] = _shopping[i].copyWith(price: () => price);
    sync?.shoppingSaved(_shopping[i]);
    _changed();
  }

  /// Cantidad y precio por unidad de una cosa.
  void setShoppingAmount(String id, {required double qty, double? price}) {
    final i = _shopping.indexWhere((x) => x.id == id);
    if (i < 0) return;
    _shopping[i] = _shopping[i].copyWith(qty: qty <= 0 ? 1 : qty, price: () => price);
    sync?.shoppingSaved(_shopping[i]);
    _changed();
  }

  /// Total aproximado (cantidad × precio) de todo lo que tiene precio.
  double get shoppingTotal => _shopping.fold(0, (sum, i) => sum + i.subtotal);

  /// Total de lo que ya está en el carrito (tildado).
  double get shoppingInCart => _shopping.where((i) => i.done).fold(0, (sum, i) => sum + i.subtotal);

  /// Unidades en total (sumando las cantidades).
  double get shoppingUnits => _shopping.fold(0, (sum, i) => sum + i.qty);

  /// Fecha probable de la próxima compra (la comparten los adultos).
  DateTime? get shoppingDate => _shoppingDate;

  void setShoppingDate(DateTime? date) {
    _shoppingDate = date == null ? null : DateTime(date.year, date.month, date.day);
    sync?.homeSettingsChanged({'shoppingDate': _shoppingDate?.toIso8601String()});
    _changed();
  }

  /// Si [memberId] eligió ver una herramienta del hogar (por ejemplo `compras`).
  bool usesTool(String memberId, String tool) => memberById(memberId)?.look.tools.contains(tool) ?? false;

  void setTool(String memberId, String tool, bool on) {
    final m = memberById(memberId);
    if (m == null) return;
    final tools = [...m.look.tools]..remove(tool);
    if (on) tools.add(tool);
    m.look = m.look.copyWith(tools: tools);
    sync?.memberUpdated(m);
    _changed();
  }

  /// Borra lo que ya se compró.
  void clearBoughtShopping() {
    final ids = [for (final i in _shopping) if (i.done) i.id];
    if (ids.isEmpty) return;
    _shopping.removeWhere((i) => i.done);
    sync?.shoppingRemoved(ids);
    _changed();
  }
}
