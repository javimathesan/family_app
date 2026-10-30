import 'package:family_app/app.dart';
import 'package:family_app/data/app_session.dart';
import 'package:family_app/data/family_storage.dart';
import 'package:family_app/data/family_store.dart';
import 'package:family_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  var now = DateTime(2026, 10, 30, 7, 25);
  DateTime clock() => now;

  Future<(FamilyStore, AppSession)> demo() async {
    now = DateTime(2026, 10, 30, 7, 25);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FamilyStore.empty(clock: clock);
    final session = AppSession(store: store, prefs: prefs, storage: FamilyStorage(prefs));
    await session.restore();
    await session.startDemo();
    return (store, session);
  }

  test('los avisos guardan tipo y miembro', () async {
    final (store, _) = await demo();
    store.toggleTask('tomi', 'aseo');
    expect(store.notices.first.kind, NoticeKind.task);
    expect(store.notices.first.memberId, 'tomi');

    store.toggleTask('tomi', 'cama');
    expect(store.notices.first.kind, NoticeKind.toApprove);
    expect(store.notices.first.isImportant, isTrue);

    now = now.add(const Duration(minutes: 1));
    store.requestReward('tomi', 'helado');
    expect(store.notices.first.kind, NoticeKind.reward);
    expect(store.notices.first.text, contains('Helado'));
  });

  test('aprobar avisa con el nombre de quien aprueba', () async {
    final (store, _) = await demo();
    store.signInAs('adulto');
    store.requestReward('tomi', 'helado');
    store.approveRedemption(store.pendingRedemptions.single.id);
    expect(store.notices.first.text, 'Papá aprobó "Helado" para Tomi');
    expect(store.notices.first.kind, NoticeKind.approval);
  });

  test('sin leer: cuenta lo nuevo de otros y se limpia al abrir Novedades', () async {
    final (store, session) = await demo();
    store.signInAs('adulto');
    expect(session.unreadNotices, 0, reason: 'lo anterior a instalar no cuenta');

    now = now.add(const Duration(minutes: 5));
    store.toggleTask('tomi', 'aseo');
    store.toggleTask('luli', 'aseo');
    store.toggleAdultGoal('adulto', 'meta_jugar');
    expect(session.unreadNotices, 2, reason: 'lo que hace el propio adulto no es novedad');

    await session.markNoticesSeen();
    expect(session.unreadNotices, 0);
  });

  test('preferencia de avisos: importantes, todo o nada', () async {
    final (store, session) = await demo();
    store.signInAs('adulto');
    final t = DateTime(2026, 10, 30, 8);
    final tarea = FamilyNotice(time: t, text: 'Tomi completó: Aseo', kind: NoticeKind.task, memberId: 'tomi');
    final premio = FamilyNotice(time: t, text: 'Tomi pidió el premio: Helado', kind: NoticeKind.reward, memberId: 'tomi');
    final propio = FamilyNotice(time: t, text: 'Papá jugó con sus hijos', kind: NoticeKind.goal, memberId: 'adulto');

    expect(session.notifyMode, NotifyMode.important);
    expect(session.shouldNotify(tarea), isFalse);
    expect(session.shouldNotify(premio), isTrue);

    await session.setNotifyMode(NotifyMode.all);
    expect(session.shouldNotify(tarea), isTrue);
    expect(session.shouldNotify(propio), isFalse, reason: 'nunca avisa lo propio');

    await session.setNotifyMode(NotifyMode.none);
    expect(session.shouldNotify(premio), isFalse);
  });

  testWidgets('Novedades junta las tareas de cada hijo en una línea', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final (store, session) = await demo();
    now = now.add(const Duration(minutes: 5));
    for (final t in ['levantarse', 'aseo', 'desayuno']) {
      store.toggleTask('tomi', t);
    }
    store.requestReward('luli', 'helado');
    await tester.pumpWidget(FamilyApp(store: store, session: session));

    await tester.tap(find.text('Papá'));
    await tester.pumpAndSettle();
    expect(find.byType(Badge), findsOneWidget);

    await tester.tap(find.byTooltip('Novedades'));
    await tester.pumpAndSettle();
    expect(find.text('Tomi completó 3 tareas'), findsOneWidget);
    expect(find.text('Luli pidió el premio: Helado'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(session.unreadNotices, 0);
  });
}
