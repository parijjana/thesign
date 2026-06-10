import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/test_room.dart';
import 'config.dart';
import 'input/game_input.dart';
import 'input/keyboard_input.dart';
import 'palette.dart';
import 'ui/hud.dart';

/// The game shell: fixed-resolution letterboxed camera, active palette,
/// input plumbing (ARCHITECTURE.md §5).
class EscapeGame extends FlameGame with HasKeyboardHandlerComponents {
  EscapeGame()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: Config.viewportWidth,
            height: Config.viewportHeight,
          ),
        );

  /// The active palette; rooms swap this when they declare a discipline
  /// palette (LEVEL_FORMAT.md §3).
  Palette palette = Palettes.amber;

  /// Normalized input intents — the only input game logic ever reads.
  final GameInput input = GameInput();

  /// Letterbox bars render in ink, framing the room like a sign's border.
  @override
  Color backgroundColor() => palette.ink;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    add(KeyboardInput(input));
    world.add(TestRoom());
    camera.viewport.add(Hud());
  }

  @override
  void update(double dt) {
    super.update(dt); // components read edges during their update...
    input.clearEdges(); // ...then edges expire, lasting exactly one tick
  }
}
