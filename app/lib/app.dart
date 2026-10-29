import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/family_store.dart';
import 'features/adult/adult_home_screen.dart';
import 'features/child/child_shell.dart';
import 'features/onboarding/avatar_editor_screen.dart';
import 'features/onboarding/invite_screen.dart';
import 'features/onboarding/join_home_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'theme/app_theme.dart';

/// Rutas con nombre de la app. Mantenerlas acá evita strings sueltos.
abstract final class Routes {
  static const welcome = '/';
  static const child = '/hijo';
  static const adult = '/adulto';
  static const invite = '/adulto/invitar';
  static const join = '/unirse';
  static const avatar = '/avatar';
}

class FamilyApp extends StatelessWidget {
  const FamilyApp({super.key, required this.store});

  final FamilyStore store;

  @override
  Widget build(BuildContext context) {
    return FamilyScope(
      store: store,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final accent = store.currentMember?.accent ?? AppColors.defaultAccent;
          return MaterialApp(
            title: 'family_app',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(accent),
            darkTheme: AppTheme.dark(accent),
            locale: const Locale('es', 'AR'),
            supportedLocales: const [Locale('es', 'AR'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            initialRoute: Routes.welcome,
            routes: {
              Routes.welcome: (_) => const WelcomeScreen(),
              Routes.child: (_) => const ChildShell(),
              Routes.adult: (_) => const AdultHomeScreen(),
              Routes.invite: (_) => const InviteScreen(),
              Routes.join: (_) => const JoinHomeScreen(),
              Routes.avatar: (_) => const AvatarEditorScreen(),
            },
          );
        },
      ),
    );
  }
}
