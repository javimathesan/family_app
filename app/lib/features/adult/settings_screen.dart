import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/app_session.dart';
import '../../data/family_store.dart';
import '../../widgets/accent_picker.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';
import '../agenda/agenda_screen.dart';
import '../games/games_hub.dart';
import 'adult_home_screen.dart';

/// Todo lo configurable en un solo lugar.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final session = SessionScope.of(context);
    final me = store.currentMember;
    final admin = session.isAdmin;
    final nav = Navigator.of(context);

    Widget section(String title, List<Widget> tiles) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                child: Text(title.toUpperCase(), style: mutedText(context).copyWith(fontWeight: FontWeight.w800, letterSpacing: .5)),
              ),
              Card(child: Column(children: tiles)),
            ],
          ),
        );

    ListTile tile(IconData icon, String title, VoidCallback onTap, {String? subtitle, Widget? trailing}) => ListTile(
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: subtitle == null ? null : Text(subtitle),
          trailing: trailing ?? const Icon(Icons.chevron_right),
          onTap: onTap,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            if (me != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: AvatarView(config: me.avatar, size: 56, background: me.accent.withValues(alpha: .15)),
                    title: Text(me.nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    subtitle: Text('${me.role.label} · ${store.homeName}'),
                    trailing: TextButton(onPressed: () => nav.pushNamed(Routes.avatar), child: const Text('Mi avatar')),
                  ),
                ),
              ),
            section('Mi app', [
              tile(Icons.palette_outlined, 'Personalizar', () => showAccentPicker(context),
                  subtitle: 'Modo oscuro, color, fondo y tarjetas'),
            ]),
            section('Este teléfono', [
              tile(Icons.notifications_outlined, 'Avisos', () => _pickNotifyMode(context), subtitle: session.notifyMode.label),
              tile(Icons.battery_charging_full, 'Que los avisos lleguen siempre', () => nav.pushNamed(Routes.reliability),
                  subtitle: 'Permisos y ahorro de batería'),
              tile(Icons.pin_outlined, session.hasPin ? 'Cambiar o quitar el PIN' : 'Poner PIN al modo adulto',
                  () => AdultHomeScreen.managePin(context)),
              tile(Icons.tablet_android, 'Modo tablet familiar', () => nav.pushNamed(Routes.tablet),
                  subtitle: 'Para la tablet de la casa: todos los chicos en una pantalla'),
              tile(Icons.switch_account_outlined, 'Cambiar de usuario', () => AdultHomeScreen.sessionAction(context, 'switch')),
            ]),
            if (admin)
              section('Hogar', [
                tile(Icons.checklist, 'Rutina y premios', () => nav.pushNamed(Routes.routine)),
                tile(Icons.rule, 'Reglas de juego de los chicos', () => showGameRules(context),
                    subtitle: '${store.gamesRule.label} · ${store.gamesMinutes == 0 ? 'sin límite' : '${store.gamesMinutes} min por día'}'),
                tile(Icons.emoji_events_outlined, 'Reto de la semana', () => AdultHomeScreen.editChallenge(context),
                    subtitle: store.challenge?.title ?? 'Sin reto'),
                tile(Icons.translate, 'Idiomas de Palabras', () => nav.pushNamed(Routes.words),
                    subtitle: store.languages.map((c) => switch (c) { 'en' => 'Inglés', 'pt' => 'Portugués', _ => 'Coreano' }).join(', ')),
                tile(Icons.shield_outlined, 'Escudo de la familia', () => nav.pushNamed(Routes.crest)),
                tile(Icons.qr_code_2, 'Invitar con QR', () => nav.pushNamed(Routes.invite)),
                tile(Icons.person_add_alt, 'Hijo sin celular', () => AdultHomeScreen.addChildWithoutPhone(context)),
                if (session.isCloud) tile(Icons.phonelink_setup, 'Teléfono nuevo de alguien', () => AdultHomeScreen.relinkPhone(context)),
              ]),
            section('Información', [
              tile(Icons.bar_chart, 'Resumen de la semana', () => nav.pushNamed(Routes.week)),
              tile(Icons.privacy_tip_outlined, 'Privacidad y datos', () => nav.pushNamed(Routes.privacy)),
            ]),
            section('Sesión', [
              if (session.isDemo) ...[
                tile(Icons.restart_alt, 'Restablecer datos de ejemplo', () => AdultHomeScreen.sessionAction(context, 'reset')),
                tile(Icons.logout, 'Salir de la demostración', () => AdultHomeScreen.sessionAction(context, 'leave')),
              ] else
                tile(Icons.link_off, 'Desvincular este teléfono', () => AdultHomeScreen.sessionAction(context, 'leave')),
            ]),
            Center(child: Text('Family App · versión de prueba', style: mutedText(context))),
          ],
        ),
      ),
    );
  }

  Future<void> _pickNotifyMode(BuildContext context) {
    final session = SessionScope.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: RadioGroup<NotifyMode>(
          groupValue: session.notifyMode,
          onChanged: (m) {
            if (m != null) session.setNotifyMode(m);
            Navigator.pop(ctx);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Avisos en este teléfono', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              for (final m in NotifyMode.values)
                RadioListTile<NotifyMode>(
                  value: m,
                  title: Text(m.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(m.description),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra inferior del adulto: Inicio, Agenda, Juegos y Ajustes.
class AdultShell extends StatefulWidget {
  const AdultShell({super.key});

  @override
  State<AdultShell> createState() => _AdultShellState();
}

class _AdultShellState extends State<AdultShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final me = store.currentMember;
    final myTurn = me == null ? 0 : store.myTurnCount(me.id);
    final today = me == null ? 0 : store.eventsOn(store.now, me.id).where((e) => e.at.isAfter(store.now)).length;
    return Scaffold(
      body: Stack(
        children: [
          for (final (i, page) in const [AdultHomeScreen(), AgendaScreen(), GamesScreen(), SettingsScreen()].indexed)
            Offstage(
              offstage: i != _index,
              child: TickerMode(enabled: i == _index, child: page),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(
            icon: Badge(isLabelVisible: today > 0, label: Text('$today'), child: const Icon(Icons.event_note_outlined)),
            selectedIcon: const Icon(Icons.event_note),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Badge(isLabelVisible: myTurn > 0, label: Text('$myTurn'), child: const Icon(Icons.sports_esports_outlined)),
            selectedIcon: const Icon(Icons.sports_esports),
            label: 'Juegos',
          ),
          const NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
