import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/app_session.dart';
import 'data/family_store.dart';
import 'features/adult/adult_home_screen.dart';
import 'features/adult/notices_screen.dart';
import 'features/adult/routine_editor_screen.dart';
import 'features/adult/week_report_screen.dart';
import 'features/onboarding/privacy_screen.dart';
import 'features/agenda/agenda_screen.dart';
import 'features/child/child_shell.dart';
import 'features/games/game_screen.dart';
import 'features/games/games_hub.dart';
import 'features/learning/words_screen.dart';
import 'learning/vocabulary.dart';
import 'models/models.dart';
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
  static const games = '/juegos';
  static const words = '/palabras';
  static const agenda = '/agenda';
  static const week = '/adulto/semana';
  static const privacy = '/privacidad';
  static const match = '/juegos/partida';

  /// Ruta de una partida.
  static String matchOf(String id) => '$match?id=$id';
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
      Routes.invite => InviteScreen(relinkMemberId: uri.queryParameters['relink']),
      Routes.routine => const RoutineEditorScreen(),
      Routes.notices => const NoticesScreen(),
      Routes.createHome => const CreateHomeScreen(),
      Routes.join => JoinHomeScreen(initialCode: uri.queryParameters['code']),
      Routes.avatar => const AvatarEditorScreen(),
      Routes.games => const GamesScreen(),
      Routes.words => const WordsScreen(),
      Routes.agenda => const AgendaScreen(),
      Routes.week => const WeekReportScreen(),
      Routes.privacy => const PrivacyScreen(),
      '${Routes.words}/tarjetas' => FlashcardsScreen(
          lang: Lang.byCode(uri.queryParameters['lang'] ?? '') ?? Lang.en,
          topic: topicById(uri.queryParameters['topic'] ?? ''),
        ),
      '${Routes.words}/quiz' => WordQuizScreen(
          lang: Lang.byCode(uri.queryParameters['lang'] ?? '') ?? Lang.en,
          topic: topicById(uri.queryParameters['topic'] ?? ''),
        ),
      Routes.match => GameScreen(matchId: uri.queryParameters['id'] ?? ''),
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
            final look = store.currentMember?.look ?? const MemberLook();
            return MaterialApp(
              title: 'Family App',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(accent, look),
              darkTheme: AppTheme.dark(accent, look),
              themeMode: switch (look.mode) {
                LookMode.light => ThemeMode.light,
                LookMode.dark => ThemeMode.dark,
                LookMode.system => ThemeMode.system,
              },
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
