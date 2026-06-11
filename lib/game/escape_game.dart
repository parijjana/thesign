import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/claw_reset.dart';
import 'components/player.dart';
import 'config.dart';
import 'core/collision_world.dart';
import 'core/interactable.dart';
import 'core/reset_controller.dart';
import 'input/game_input.dart';
import 'input/keyboard_input.dart';
import 'level/level_loader.dart';
import 'level/level_model.dart';
import 'level/room_registry.dart';
import 'palette.dart';
import 'puzzles/puzzle_script.dart';
import 'ui/hud.dart';

/// The game shell: fixed-resolution letterboxed camera, active palette,
/// input plumbing, collision world, the world graph, and the no-death reset
/// orchestration (ARCHITECTURE.md §5).
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

  /// Interactables in the current node (doors, levers) — registered by the
  /// components themselves on mount/remove.
  final List<Interactable> interactables = [];

  late final Player player;
  late final ClawReset claw;
  late final RoomRegistry registry;

  RoomComponent? _room;
  String currentNodeId = '';

  /// Rooms solved this session (persisted by the save service in M4).
  final Set<String> solvedRooms = {};

  /// The node `start` in px — the NO-DEATH reset point the claw returns to.
  final Vector2 startPoint = Vector2.zero();

  bool _resetting = false;
  double _clock = 0;
  double _lastResetDone = -10;

  /// True while the claw sequence runs — player control is locked.
  bool get resetting => _resetting;

  PuzzleScript? get roomPuzzle => _room?.puzzle;

  /// Letterbox bars render in ink, framing the room like a sign's border.
  @override
  Color backgroundColor() => palette.ink;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    add(KeyboardInput(input));
    registry = await RoomRegistry.load(assets);
    player = Player();
    claw = ClawReset();
    await loadNode(registry.world.start);
    world.add(player);
    world.add(claw);
    camera.viewport.add(Hud());
  }

  /// Tears down the current node and builds [nodeId] from its JSON, placing
  /// the player at [entryKey] (or the node's `start`).
  Future<void> loadNode(String nodeId, {String? entryKey}) async {
    _room?.removeFromParent();
    collisionWorld.solids.clear();
    interactables.clear();

    final data = await registry.level(nodeId, assets);
    currentNodeId = nodeId;
    palette = Palettes.byId[data.palette] ?? Palettes.amber;

    final room = RoomComponent(data);
    _room = room;
    world.add(room);

    startPoint.setFrom(_feetToTopLeft(data.start));
    final entry =
        (entryKey != null ? data.entryPoints[entryKey] : null) ?? data.start;
    player.teleport(_feetToTopLeft(entry));
  }

  /// Entry/start points are authored as the tile the player STANDS ON
  /// (feet position); convert to the player's top-left in px.
  Vector2 _feetToTopLeft(TilePoint p) {
    const t = Config.tileSize;
    return Vector2(
      (p.x + 0.5) * t - player.size.x / 2,
      (p.y + 1) * t - player.size.y,
    );
  }

  /// Walk through a door (called by Door.onInteract).
  void goThrough(String exitName) {
    if (_resetting) return;
    final transition = registry.resolve(currentNodeId, exitName);
    if (transition == null) return; // dead exit — author error, fail soft
    loadNode(transition.targetId, entryKey: transition.entryKey);
  }

  /// Is the current hub's unlock rule satisfied? (Doors with
  /// `lockedByRule` ask this every frame — GDD §4, default anyOf-1.)
  bool isUnlockSatisfied() {
    final node = registry.node(currentNodeId);
    final rule = node.unlock;
    if (rule == null) return false; // locked door, no rule, no key yet (M4)
    return rule.isSatisfied(solvedRooms, node.rooms);
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
      onWhirlwind: () {
        resetController.reset();
        roomPuzzle?.onReset();
      },
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

    // Interact: the context button acts on the first overlapping target.
    if (input.interactPressed && !_resetting) {
      final box = player.aabb;
      for (final i in List.of(interactables)) {
        if (i.interactZone.overlaps(box)) {
          i.onInteract();
          break;
        }
      }
    }

    // A flipped puzzle marks the room solved (feeds the hub unlock rule).
    final puzzle = roomPuzzle;
    if (puzzle != null && puzzle.isSolved) solvedRooms.add(currentNodeId);

    if (input.restartPressed) requestReset(); // R = voluntary claw
    // Failsafe: should the player ever escape the room bounds, the claw
    // retrieves them — nobody falls out of the world.
    if (!_resetting && player.position.y > Config.viewportHeight + 60) {
      requestReset();
    }
    input.clearEdges(); // ...then edges expire, lasting exactly one tick
  }
}
