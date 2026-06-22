import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import 'game/escape_game.dart';
import 'game/ui/shell/map_overlay.dart';
import 'game/ui/shell/shell_overlays.dart';

void main() {
  final game = EscapeGame();
  // Autofocus so gameplay keys work without a first click. The frozen shell
  // screens don't rely on this — each owns the keyboard via its own Flutter
  // focus (ShellKeys → handleShellKey), which is robust against the GameWidget
  // not having focus yet at launch.
  runApp(
    GameWidget(
      game: game,
      autofocus: true,
      // The play space starts frozen behind the title (GDD §10b shell flow).
      initialActiveOverlays: const [EscapeGame.titleOverlay],
      // Each overlay is wrapped in ShellKeys so the visible menu owns the
      // keyboard (autofocusing Focus → handleShellKey) regardless of whether
      // the GameWidget itself has focus yet.
      overlayBuilderMap: {
        EscapeGame.titleOverlay: (_, EscapeGame g) =>
            ShellKeys(game: g, child: TitleOverlay(g)),
        EscapeGame.profileOverlay: (_, EscapeGame g) =>
            ShellKeys(game: g, child: ProfileOverlay(g)),
        EscapeGame.pauseOverlay: (_, EscapeGame g) =>
            ShellKeys(game: g, child: PauseOverlay(g)),
        EscapeGame.mapOverlay: (_, EscapeGame g) =>
            ShellKeys(game: g, child: MapOverlay(g)),
        EscapeGame.winOverlay: (_, EscapeGame g) =>
            ShellKeys(game: g, child: WinOverlay(g)),
        EscapeGame.settingsOverlay: (_, EscapeGame g) =>
            ShellKeys(game: g, child: SettingsOverlay(g)),
      },
    ),
  );
}
