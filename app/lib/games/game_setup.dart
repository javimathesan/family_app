import '../models/models.dart';
import 'barrio.dart';
import 'chess.dart';
import 'colorin.dart';
import 'cuatro.dart';
import 'ludo.dart';
import 'tateti.dart';

/// Tablero inicial de cada juego, listo para guardar.
Map<String, dynamic> initialGameState(GameKind kind, int players) => switch (kind) {
      GameKind.tateti => {'cells': Tateti.initial()},
      GameKind.cuatro => {'cells': Cuatro.initial()},
      GameKind.ludo => LudoState.initial(players).toJson(),
      GameKind.ajedrez => Chess.initial().toJson(),
      GameKind.barrio => BarrioState.initial(players).toJson(),
      GameKind.colorin => ColorinState.deal(players).toJson(),
    };
