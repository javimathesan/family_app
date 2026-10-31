import 'package:flutter/material.dart';

import '../../data/family_store.dart';
import '../../widgets/world_backdrop.dart';
import '../games/games_hub.dart';
import 'calendar_screen.dart';
import 'rewards_screen.dart';
import 'routine_screen.dart';
import 'today_screen.dart';

/// Contenedor de la app del hijo con la barra de navegación inferior.
class ChildShell extends StatefulWidget {
  const ChildShell({super.key});

  @override
  State<ChildShell> createState() => _ChildShellState();
}

class _ChildShellState extends State<ChildShell> {
  int _index = 0;

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(onOpenRoutine: () => _go(1)),
      const RoutineScreen(),
      const CalendarScreen(),
      const RewardsScreen(),
      const GamesHub(),
    ];
    final store = FamilyScope.of(context);
    final me = store.currentMember;
    final myTurn = me == null ? 0 : store.myTurnCount(me.id);
    return Scaffold(
      body: WorldBackdrop(
        world: me?.look.world ?? 0,
        child: SafeArea(child: IndexedStack(index: _index, children: pages)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Hoy'),
          const NavigationDestination(icon: Icon(Icons.check_box_outlined), selectedIcon: Icon(Icons.check_box), label: 'Rutina'),
          const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendario'),
          const NavigationDestination(icon: Icon(Icons.card_giftcard_outlined), selectedIcon: Icon(Icons.card_giftcard), label: 'Premios'),
          NavigationDestination(
            icon: Badge(isLabelVisible: myTurn > 0, label: Text('$myTurn'), child: const Icon(Icons.sports_esports_outlined)),
            selectedIcon: Badge(isLabelVisible: myTurn > 0, label: Text('$myTurn'), child: const Icon(Icons.sports_esports)),
            label: 'Juegos',
          ),
        ],
      ),
    );
  }
}
