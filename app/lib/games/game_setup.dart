import '../models/models.dart';
import 'chess.dart';
import 'cuatro.dart';
import 'ludo.dart';
import 'tateti.dart';

/// Tablero inicial de cada juego, listo para guardar.
Map<String, dynamic> initialGameState(GameKind kind, int players) => switch (kind) {
      GameKind.tateti => {'cells': Tateti.initial()},
      GameKind.cuatro => {'cells': Cuatro.initial()},
      GameKind.ludo => LudoState.initial(players).toJson(),
      GameKind.ajedrez => Chess.initial().toJson(),
    };
