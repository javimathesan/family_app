import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/app_session.dart';
import 'data/family_store.dart';
import 'features/adult/adult_home_screen.dart';
import 'features/adult/notices_screen.dart';
import 'features/adult/routine_editor_screen.dart';
import 'features/child/child_shell.dart';
import 'features/onboarding/avatar_editor_screen.dart';
import 'features/onboarding/create_home_screen.dart';
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
  static const routine = '/adulto/rutina';
  static const notices = '/novedades';
  static const createHome = '/crear-hogar';
  static const join = '/unirse';
  static const avatar = '/avatar';
}

class FamilyApp extends StatelessWidget {
  const FamilyApp({super.key, required this.store, required this.session});

  final FamilyStore store;
  final AppSession session;

  /// Arma cada pantalla a partir del nombre de la ruta. Acepta enlaces con
  /// parámetros, por ejemplo `/unirse?code=FAM-XXXX` al abrir el QR desde la
  /// cámara del teléfono.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? Routes.welcome) ?? Uri();
    final Widget page = switch (uri.path) {
      Routes.child => const ChildShell(),
      Routes.adult => const AdultHomeScreen(),
      Routes.invite => const InviteScreen(),
      Routes.routine => const RoutineEditorScreen(),
      Routes.notices => const NoticesScreen(),
      Routes.createHome => const CreateHomeScreen(),
      Routes.join => JoinHomeScreen(initialCode: uri.queryParameters['code']),
      Routes.avatar => const AvatarEditorScreen(),
      _ => const WelcomeScreen(),
    };
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: session,
      child: FamilyScope(
        store: store,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final accent = store.currentMember?.accent ?? AppColors.defaultAccent;
            return MaterialApp(
              title: 'Family App',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(accent),
              darkTheme: AppTheme.dark(accent),
              locale: const Locale('es', 'AR'),
              supportedLocales: const [Locale('es', 'AR'), Locale('en')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              onGenerateRoute: onGenerateRoute,
            );
          },
        ),
      ),
    );
  }
}
