part of 'family_store.dart';

/// Una cosa para el cuarto (o una mascota).
class RoomItem {
  const RoomItem(this.name, this.emoji, this.cost, {this.premium = false, this.color});
  final String name;
  final String emoji;
  final int cost;
  final bool premium;

  /// Para paredes y pisos: el color.
  final Color? color;

  bool get free => cost == 0 && !premium;
}

/// Lugares del cuarto y lo que se puede poner en cada uno.
abstract final class RoomCatalog {
  static const slots = <String, ({String label, List<RoomItem> items})>{
    'wall': (label: 'Pared', items: [
      RoomItem('Celeste', '', 0, color: Color(0xFFD6EBFF)),
      RoomItem('Rosa', '', 0, color: Color(0xFFFFE0EC)),
      RoomItem('Verde', '', 30, color: Color(0xFFDDF5E3)),
      RoomItem('Amarillo', '', 30, color: Color(0xFFFFF3C4)),
      RoomItem('Violeta', '', 40, color: Color(0xFFE9DDFF)),
      RoomItem('Noche estrellada', '', 0, premium: true, color: Color(0xFF243064)),
    ]),
    'floor': (label: 'Piso', items: [
      RoomItem('Madera', '', 0, color: Color(0xFFC89B6D)),
      RoomItem('Alfombra gris', '', 20, color: Color(0xFFB8BCC8)),
      RoomItem('Pasto', '', 40, color: Color(0xFF8BC48A)),
      RoomItem('Nubes', '', 0, premium: true, color: Color(0xFFEFF6FF)),
    ]),
    'bed': (label: 'Cama', items: [
      RoomItem('Cama', '🛏️', 0),
      RoomItem('Bolsa de dormir', '🛌', 30),
      RoomItem('Carpa', '⛺', 60),
      RoomItem('Castillo', '🏰', 0, premium: true),
    ]),
    'poster': (label: 'Cuadro', items: [
      RoomItem('Nada', '', 0),
      RoomItem('Estrella', '⭐', 20),
      RoomItem('Arcoíris', '🌈', 30),
      RoomItem('Dinosaurio', '🦖', 40),
      RoomItem('Cohete', '🚀', 40),
      RoomItem('Unicornio', '🦄', 0, premium: true),
    ]),
    'lamp': (label: 'Luz', items: [
      RoomItem('Nada', '', 0),
      RoomItem('Lamparita', '💡', 20),
      RoomItem('Farolito', '🏮', 30),
      RoomItem('Luna', '🌙', 40),
    ]),
    'shelf': (label: 'Estante', items: [
      RoomItem('Nada', '', 0),
      RoomItem('Libros', '📚', 20),
      RoomItem('Trofeo', '🏆', 50),
      RoomItem('Guitarra', '🎸', 50),
      RoomItem('Teclado', '🎹', 60),
    ]),
    'toy': (label: 'Juguete', items: [
      RoomItem('Nada', '', 0),
      RoomItem('Osito', '🧸', 20),
      RoomItem('Tren', '🚂', 30),
      RoomItem('Pelota', '⚽', 20),
      RoomItem('Videojuego', '🎮', 50),
      RoomItem('Robot', '🤖', 0, premium: true),
    ]),
    'plant': (label: 'Planta', items: [
      RoomItem('Nada', '', 0),
      RoomItem('Maceta', '🪴', 20),
      RoomItem('Cactus', '🌵', 20),
      RoomItem('Girasol', '🌻', 30),
    ]),
    'pet': (label: 'Mascota', items: [
      RoomItem('Sin mascota', '', 0),
      RoomItem('Perrito', '🐶', 0),
      RoomItem('Gatito', '🐱', 0),
      RoomItem('Conejo', '🐰', 0),
      RoomItem('Tortuga', '🐢', 0),
      RoomItem('Hámster', '🐹', 0),
      RoomItem('Dragoncito', '🐲', 0, premium: true),
      RoomItem('Unicornio', '🦄', 0, premium: true),
    ]),
  };

  static String unlockId(String slot, int index) => 'room_${slot}_$index';
}

/// Cómo está la mascota hoy.
enum PetMood {
  happy('😄', 'Feliz'),
  ok('🙂', 'Contenta'),
  hungry('😋', 'Con ganas de que hagas tus tareas'),
  sleepy('😴', 'Esperándote');

  const PetMood(this.face, this.label);
  final String face;
  final String label;
}

extension FamilyRoom on FamilyStore {
  int roomChoice(String memberId, String slot) => (memberById(memberId)?.room[slot] as num?)?.toInt() ?? (slot == 'bed' ? 0 : 0);

  RoomItem roomItem(String memberId, String slot) {
    final items = RoomCatalog.slots[slot]!.items;
    return items[roomChoice(memberId, slot).clamp(0, items.length - 1)];
  }

  bool ownsRoomItem(String memberId, String slot, int index, {required bool plusOpen}) {
    final item = RoomCatalog.slots[slot]!.items[index];
    if (item.premium) return plusOpen;
    final m = memberById(memberId);
    return item.free || (m != null && (m.role.isAdult || m.unlocked.contains(RoomCatalog.unlockId(slot, index))));
  }

  /// Pone algo en el cuarto (ya tiene que ser suyo).
  void setRoom(String memberId, String slot, Object value) {
    final m = memberById(memberId);
    if (m == null) return;
    m.room[slot] = value;
    sync?.memberUpdated(m);
    _changed();
  }

  /// Compra algo para el cuarto con puntos. Devuelve si se pudo.
  bool buyRoomItem(String memberId, String slot, int index) {
    final item = RoomCatalog.slots[slot]!.items[index];
    if (item.premium) return false;
    if (!unlockItem(memberId, RoomCatalog.unlockId(slot, index), item.cost)) return false;
    setRoom(memberId, slot, index);
    return true;
  }

  /// Cosas que puso en su cuarto (para las medallas).
  int roomItemsPlaced(String memberId) => [
        for (final slot in ['poster', 'lamp', 'shelf', 'toy', 'plant'])
          if (roomChoice(memberId, slot) > 0) slot,
      ].length;

  bool hasPet(String memberId) => roomChoice(memberId, 'pet') > 0;

  String petName(String memberId) {
    final name = memberById(memberId)?.room['petName'];
    if (name is String && name.trim().isNotEmpty) return name;
    return roomItem(memberId, 'pet').name;
  }

  /// La mascota está feliz si el chico cumple su rutina.
  PetMood petMood(String memberId) {
    final r = completionRatio(memberId);
    if (r >= .85) return PetMood.happy;
    if (r >= .5) return PetMood.ok;
    if (r > 0) return PetMood.hungry;
    return PetMood.sleepy;
  }

  /// Sube un nivel cada 3 días con la rutina casi completa (últimos 60 días).
  int petLevel(String memberId) {
    final good = [for (final d in lastDays(memberId, days: 60)) if ((d.summary?.completionRatio ?? 0) >= .85) d].length;
    return 1 + good ~/ 3;
  }
}
