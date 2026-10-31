import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/app_session.dart';
import 'data/family_store.dart';
import 'features/adult/crest_screen.dart';
import 'features/adult/reliability_screen.dart';
import 'features/adult/settings_screen.dart';
import 'features/adult/tablet_mode_screen.dart';
import 'features/child/medals_screen.dart';
import 'features/child/room_screen.dart';
import 'features/adult/notices_screen.dart';
import 'features/adult/routine_editor_screen.dart';
import 'features/adult/week_report_screen.dart';
import 'features/onboarding/privacy_screen.dart';
import 'features/agenda/agenda_screen.dart';
import 'features/child/child_shell.dart';
import 'features/games/game_screen.dart';
import 'features/games/games_hub.dart';
import 'features/learning/word_games.dart';
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
  static const reliability = '/ajustes/avisos';
  static const crest = '/ajustes/escudo';
  static const tablet = '/tablet';
  static const medals = '/medallas';
  static const room = '/mi-cuarto';
  static const match = '/juegos/partida';

  /// Ruta de una partida.
  static String matchOf(String id) => '$match?id=$id';
}

/// Juegos de palabras: `/palabras/<modo>?lang=en&topic=animales`.
Widget _wordGame(String mode, Uri uri) {
  final lang = Lang.byCode(uri.queryParameters['lang'] ?? '') ?? Lang.en;
  final id = uri.queryParameters['topic'] ?? '';
  final topic = id == reviewTopicId ? const Topic(reviewTopicId, 'Repaso', '🔁', []) : topicById(id);
  return switch (mode) {
    'tarjetas' => FlashcardsScreen(lang: lang, topic: topic),
    'escuchar' => ListenGameScreen(lang: lang, topic: topic),
    'memoria' => MemoryGameScreen(lang: lang, topic: topic),
    'letras' => LettersGameScreen(lang: lang, topic: topic),
    _ => WordQuizScreen(lang: lang, topic: topic),
  };
}

class FamilyApp extends StatefulWidget {
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
      Routes.adult => const AdultShell(),
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
      Routes.reliability => const ReliabilityScreen(),
      Routes.crest => const CrestScreen(),
      Routes.tablet => const TabletModeScreen(),
      Routes.medals => MedalsScreen(memberId: uri.queryParameters['id']),
      Routes.room => const RoomScreen(),
      final p when p.startsWith('${Routes.words}/') => _wordGame(p.substring(Routes.words.length + 1), uri),
      Routes.match => GameScreen(matchId: uri.queryParameters['id'] ?? ''),
      _ => const WelcomeScreen(),
    };
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }

  @override
  State<FamilyApp> createState() => _FamilyAppState();
}

/// Colores de quien usa la app. Solo avisa cuando cambian, así marcar una
/// tarea no vuelve a armar toda la app.
typedef _Looks = ({Color accent, MemberLook look});

class _FamilyAppState extends State<FamilyApp> {
  late final ValueNotifier<_Looks> _looks = ValueNotifier(_current());

  _Looks _current() {
    final member = widget.store.currentMember;
    final look = member?.look ?? const MemberLook();
    // Un mundo temático (Plus) trae su propio color.
    final world = look.world > 0 && look.world < LookOptions.worlds.length ? LookOptions.worlds[look.world] : null;
    return (accent: world?.accent ?? member?.accent ?? AppColors.defaultAccent, look: look);
  }

  void _onStore() {
    final next = _current();
    if (next != _looks.value) _looks.value = next;
  }

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _looks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: widget.session,
      child: FamilyScope(
        store: widget.store,
        child: ValueListenableBuilder<_Looks>(
          valueListenable: _looks,
          builder: (context, looks, _) {
            final accent = looks.accent;
            final look = looks.look;
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
              onGenerateRoute: FamilyApp.onGenerateRoute,
              // En tablets el contenido queda centrado y no se estira de lado a lado.
              builder: (context, child) => LayoutBuilder(
                builder: (context, box) => box.maxWidth <= 900
                    ? child!
                    : ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Center(child: SizedBox(width: 900, child: child)),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
