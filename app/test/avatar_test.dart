import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:family_app/widgets/avatar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('todos los disfraces, peinados y ojos se dibujan sin errores', (tester) async {
    final configs = <AvatarConfig>[
      for (var outfit = 0; outfit < AvatarOptions.outfits.length; outfit++)
        for (var hair = 0; hair < AvatarOptions.hairStyles.length; hair++)
          AvatarConfig(
            outfit: outfit,
            hairStyle: hair,
            eyes: hair % AvatarOptions.eyes.length,
            accessory: outfit % AvatarOptions.accessories.length,
            glasses: hair.isEven,
            shirt: outfit % AvatarOptions.shirts.length,
            hairColor: hair % AvatarOptions.hairColors.length,
          ),
    ];
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: Wrap(children: [
          for (final c in configs) ...[
            AvatarView.full(config: c, size: 80),
            AvatarView(config: c, size: 40, background: Colors.white),
          ],
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(AvatarView), findsNWidgets(configs.length * 2));
  });

  test('los ids de disfraces y accesorios son únicos', () {
    final ids = [...AvatarOptions.outfits, ...AvatarOptions.accessories].map((i) => i.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(AvatarOptions.outfits.first.free, isTrue);
  });

  group('desbloquear con puntos', () {
    late FamilyStore store;
    setUp(() => store = FamilyStore.demo(clock: () => DateTime(2026, 10, 30, 7, 25)));

    test('descuenta los puntos una sola vez y queda guardado', () {
      final antes = store.balanceOf('tomi');
      expect(store.unlockItem('tomi', 'outfit_heroe', 80), isTrue);
      expect(store.balanceOf('tomi'), antes - 80);
      expect(store.hasUnlocked('tomi', 'outfit_heroe'), isTrue);

      expect(store.unlockItem('tomi', 'outfit_heroe', 80), isFalse);
      expect(store.balanceOf('tomi'), antes - 80);
    });

    test('sin puntos suficientes no se desbloquea', () {
      expect(store.unlockItem('mati', 'outfit_dino', 150), isFalse);
      expect(store.hasUnlocked('mati', 'outfit_dino'), isFalse);
      expect(store.balanceOf('mati'), 95);
    });

    test('el disfraz y lo desbloqueado se guardan y se recuperan', () {
      store.unlockItem('tomi', 'outfit_ninja', 100);
      store.updateAvatar('tomi', const AvatarConfig(outfit: 3, hairStyle: 5, eyes: 3));
      final copia = FamilyStore.demo(clock: () => DateTime(2026, 10, 30, 7, 25))..restoreFrom(store.toJson());
      expect(copia.memberById('tomi')!.avatar.outfit, 3);
      expect(copia.memberById('tomi')!.avatar.hairStyle, 5);
      expect(copia.hasUnlocked('tomi', 'outfit_ninja'), isTrue);
    });
  });

  test('disfraces nuevos y de Plus', () {
    expect(AvatarOptions.outfits.length, 19);
    final plus = [for (final o in AvatarOptions.outfits) if (o.premium) o.label];
    expect(plus, ['Sirena', 'Dragón', 'Hada', 'Caballero']);
    expect(AvatarOptions.outfits.where((o) => o.premium).every((o) => !o.free), isTrue);
    expect(AvatarOptions.accessories.last.premium, isTrue);
  });
}
