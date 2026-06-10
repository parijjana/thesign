import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/claw_reset.dart';
import 'components/player.dart';
import 'components/test_room.dart';
import 'config.dart';
import 'core/collision_world.dart';
import 'core/reset_controller.dart';
import 'input/game_input.dart';
import 'input/keyboard_input.dart';
import 'palette.dart';
import 'ui/hud.dart';

/// The game shell: fixed-resolution letterboxed camera, active palette,
/// input plumbing, collision world, and the no-death reset orchestration
/// (ARCHITECTURE.md §5).
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

  final CollisionWorld collisionWorld = CollisionWorld();
  final ResetController resetController = ResetController();

  late final Player player;
  late final ClawReset claw;

  /// The node `start` (M3 loads this from level JSON; hand-set for now).
  final Vector2 startPoint = Vector2(80, 334);

  bool _resetting = false;
  double _clock = 0;
  double _lastResetDone = -10;

  /// True while the claw sequence runs — player control is locked.
  bool get resetting => _resetting;

  /// Letterbox bars render in ink, framing the room like a sign's border.
  @override
  Color backgroundColor() => palette.ink;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    add(KeyboardInput(input));
    world.add(TestRoom());
    player = Player()..position.setFrom(startPoint);
    world.add(player);
    claw = ClawReset();
    world.add(claw);
    camera.viewport.add(Hud());
  }

  /// The no-death reset (GDD.md §8): hazard contact or the restart button.
  /// The claw performs it; state snaps back on the whirlwind beat.
  void requestReset() {
    if (_resetting) return;
    _resetting = true;
    claw.play(
      player: player,
      start: startPoint,
      abbreviated: _clock - _lastResetDone < 4, // quick again? keep it snappy
      onWhirlwind: resetController.reset,
      onDone: () {
        _resetting = false;
        _lastResetDone = _clock;
      },
    );
  }

  @override
  void update(double dt) {
    _clock += dt;
    super.update(dt); // components read edges during their update...
    if (input.restartPressed) requestReset(); // R = voluntary claw
    input.clearEdges(); // ...then edges expire, lasting exactly one tick
  }
}
