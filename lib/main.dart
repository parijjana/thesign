import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import 'game/escape_game.dart';
import 'game/ui/shell/shell_overlays.dart';

void main() {
  final game = EscapeGame();
  runApp(
    GameWidget(
      game: game,
      // The play space starts frozen behind the title (GDD §10b shell flow).
      initialActiveOverlays: const [EscapeGame.titleOverlay],
      overlayBuilderMap: {
        EscapeGame.titleOverlay: (_, EscapeGame g) => TitleOverlay(g),
        EscapeGame.pauseOverlay: (_, EscapeGame g) => PauseOverlay(g),
      },
    ),
  );
}
