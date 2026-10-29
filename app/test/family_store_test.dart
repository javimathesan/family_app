import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Viernes 30/10/2026 a las 07:25: tienda abierta y "cama" a tiempo.
  DateTime clock() => DateTime(2026, 10, 30, 7, 25);

  late FamilyStore store;
  setUp(() => store = FamilyStore.demo(clock: clock));

  test('marcar una tarea propia suma puntos y genera un aviso', () {
    final before = store.balanceOf('tomi');
    final avisos = store.notices.length;
    final pts = store.toggleTask('tomi', 'aseo');
    expect(pts, 5);
    expect(store.pointsToday('tomi'), 5);
    expect(store.balanceOf('tomi'), before + 5);
    expect(store.notices.length, avisos + 1);
  });

  test('desmarcar devuelve los puntos', () {
    final before = store.balanceOf('tomi');
    store.toggleTask('tomi', 'aseo');
    store.toggleTask('tomi', 'aseo');
    expect(store.balanceOf('tomi'), before);
    expect(store.isDone('tomi', 'aseo'), isFalse);
  });

  test('una tarea con foto queda pendiente hasta que el adulto la aprueba', () {
    final before = store.balanceOf('tomi');
    store.toggleTask('tomi', 'cama');
    expect(store.balanceOf('tomi'), before);
    expect(store.pendingTaskApprovals, hasLength(1));

    store.approveTask('tomi', 'cama');
    expect(store.balanceOf('tomi'), before + 5);
    expect(store.pendingTaskApprovals, isEmpty);
  });

  test('canjear descuenta puntos y rechazar los devuelve', () {
    final before = store.balanceOf('tomi');
    expect(store.requestReward('tomi', 'helado'), isTrue);
    expect(store.balanceOf('tomi'), before - 50);

    final pedido = store.pendingRedemptions.single;
    store.rejectRedemption(pedido.id);
    expect(store.balanceOf('tomi'), before);
    expect(pedido.status, RedemptionStatus.rejected);
  });

  test('no se puede canjear sin puntos suficientes', () {
    expect(store.requestReward('mati', 'libre'), isFalse);
    expect(store.pendingRedemptions, isEmpty);
  });

  test('la meta de agua suma 5 puntos una sola vez', () {
    final before = store.balanceOf('tomi');
    for (var i = 0; i < 10; i++) {
      store.addGlass('tomi');
    }
    expect(store.healthOf('tomi').glasses, FamilyStore.waterGoal);
    expect(store.balanceOf('tomi'), before + 5);
  });

  test('un miembro nuevo queda pendiente hasta que lo confirman', () {
    final m = store.addPendingMember(nickname: ' Juli ', role: MemberRole.child, mode: AgeMode.peques);
    expect(m.nickname, 'Juli');
    expect(store.isPendingMember(m.id), isTrue);
    store.confirmMember(m.id);
    expect(store.isPendingMember(m.id), isFalse);
  });

  test('cada miembro puede cambiar su color', () {
    store.setAccent('tomi', const Color(0xFF7C3AED));
    expect(store.memberById('tomi')!.accent, const Color(0xFF7C3AED));
  });

  test('la invitación vence a los 15 minutos y no lleva datos personales', () {
    final inv = store.createInvitation(role: MemberRole.child, mode: AgeMode.junior);
    expect(inv.expiresAt, clock().add(const Duration(minutes: 15)));
    expect(inv.code, matches(RegExp(r'^FAM-[A-Z0-9]{4}$')));
    expect(inv.qrPayload, isNot(contains('Tomi')));
  });
}
