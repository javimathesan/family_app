import 'dart:convert';

import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Viernes 30/10/2026 a las 07:25.
  DateTime viernes() => DateTime(2026, 10, 30, 7, 25);
  DateTime sabado() => DateTime(2026, 10, 31, 9, 0);

  /// Simula guardar y volver a abrir la app (pasa por texto JSON real).
  Map<String, dynamic> roundTrip(FamilyStore s) => jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;

  test('lo hecho en el día se recupera al volver a abrir la app', () {
    final a = FamilyStore.demo(clock: viernes);
    a.toggleTask('tomi', 'aseo');
    a.toggleTask('tomi', 'cama'); // queda pendiente de aprobación
    a.addGlass('tomi');
    a.togglePoop('tomi');
    a.requestReward('tomi', 'helado');
    a.setAccent('tomi', const Color(0xFF7C3AED));
    a.updateAvatar('tomi', const AvatarConfig(skin: 4, glasses: true, accessory: 2));
    final nuevo = a.addPendingMember(nickname: 'Juli', role: MemberRole.child, mode: AgeMode.peques);

    final b = FamilyStore.demo(clock: viernes)..restoreFrom(roundTrip(a));

    expect(b.isDone('tomi', 'aseo'), isTrue);
    expect(b.pendingTaskApprovals.single.task.id, 'cama');
    expect(b.pointsToday('tomi'), 5);
    expect(b.balanceOf('tomi'), a.balanceOf('tomi'));
    expect(b.healthOf('tomi').glasses, 5);
    expect(b.healthOf('tomi').poop, isTrue);
    expect(b.pendingRedemptions.single.rewardId, 'helado');
    expect(b.memberById('tomi')!.accent, const Color(0xFF7C3AED));
    expect(b.memberById('tomi')!.avatar.glasses, isTrue);
    expect(b.memberById('tomi')!.avatar.accessory, 2);
    expect(b.memberById(nuevo.id)!.nickname, 'Juli');
    expect(b.isPendingMember(nuevo.id), isTrue);
    expect(b.notices.first.text, a.notices.first.text);
  });

  test('al día siguiente la rutina arranca vacía y el día anterior va al calendario', () {
    final a = FamilyStore.demo(clock: viernes);
    a.toggleTask('tomi', 'aseo');
    a.toggleTask('tomi', 'levantarse');
    a.addGlass('tomi');
    final saldo = a.balanceOf('tomi');
    final diasAntes = a.historyOf('tomi').length;

    final b = FamilyStore.demo(clock: sabado)..restoreFrom(roundTrip(a));

    expect(b.doneToday('tomi'), 0);
    expect(b.healthOf('tomi').glasses, 0);
    expect(b.balanceOf('tomi'), saldo, reason: 'los puntos ganados se conservan');

    final historial = b.historyOf('tomi');
    expect(historial.length, diasAntes + 1);
    final viernesGuardado = historial.last;
    expect(DateUtils.isSameDay(viernesGuardado.date, viernes()), isTrue);
    expect(viernesGuardado.points, 10);
    expect(viernesGuardado.glasses, 5);
  });

  test('restablecer vuelve a los datos de ejemplo', () {
    final a = FamilyStore.demo(clock: viernes);
    a.toggleTask('tomi', 'aseo');
    a.addPendingMember(nickname: 'Juli', role: MemberRole.child);
    a.resetToDemo();
    expect(a.doneToday('tomi'), 0);
    expect(a.members.length, 4);
    expect(a.balanceOf('tomi'), 210);
  });

  group('FamilyStorage', () {
    test('guarda cada cambio y lo vuelve a cargar', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await FamilyStorage.open();

      final a = FamilyStore.demo(clock: viernes);
      storage.attach(a);
      a.toggleTask('luli', 'aseo');
      await Future<void>.delayed(Duration.zero);

      final b = FamilyStore.demo(clock: viernes);
      expect(storage.load(b), isTrue);
      expect(b.isDone('luli', 'aseo'), isTrue);
    });

    test('si los datos guardados están rotos, los descarta sin romper la app', () async {
      SharedPreferences.setMockInitialValues({FamilyStorage.key: '{esto no es json'});
      final storage = await FamilyStorage.open();
      final store = FamilyStore.demo(clock: viernes);

      expect(storage.load(store), isFalse);
      expect(store.members.length, 4);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(FamilyStorage.key), isNull);
    });
  });
}
