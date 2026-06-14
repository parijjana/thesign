import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/claw_reset.dart';
import 'components/player.dart';
import 'components/pushable_block.dart';
import 'components/water_pool.dart';
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
import 'powerups.dart';
import 'puzzles/puzzle_script.dart';
import 'save/progress.dart';
import 'save/save_service.dart';
import 'ui/debug_hud.dart';
import 'ui/feedback_popups.dart';
import 'ui/hud.dart';
import 'ui/interact_prompt.dart';
import 'ui/powerup_hud.dart';

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

  /// What the player can act on right now (drives the hand-glyph prompt and
  /// the interact dispatch). Recomputed every frame.
  Interactable? focusedInteractable;

  /// Blocks in the current node (registered on mount; plates query them).
  final List<PushableBlock> blocks = [];

  /// Water pools in the current node — the player queries these to know if
  /// it's submerged (swim with Flippers, else reset).
  final List<WaterPool> waterPools = [];

  late final Player player;
  late final ClawReset claw;
  late final RoomRegistry registry;
  late final FeedbackPopups feedback;
  final SaveService _saves = SaveService();

  RoomComponent? _room;
  String currentNodeId = '';

  /// Short code of the current node (debug overlay).
  String get currentNodeCode => _room?.data.code ?? '?';

  /// DEV: F3 toggles the room-id overlay.
  bool showDebug = false;

  /// Rooms solved this session (persisted by the save service in M4).
  final Set<String> solvedRooms = {};

  /// Collected lore etchings (gallery arrives with the M7 legend screen).
  final Set<String> foundEtchings = {};

  /// Discovered secret passages ('node/exit' keys).
  final Set<String> discoveredSecrets = {};

  /// Every node ever entered — feeds the M7 castle map.
  final Set<String> visitedNodes = {};

  /// Permanent Metroidvania abilities owned (docs/POWERUPS.md).
  final Set<Powerup> powerups = {};

  bool hasPowerup(Powerup p) => powerups.contains(p);

  /// The node `start` in px — the NO-DEATH reset point the claw returns to.
  final Vector2 startPoint = Vector2.zero();

  bool _resetting = false;
  double _clock = 0;
  double _lastResetDone = -10;

  /// Waterlogged blocks waiting for the claw (it serves one job at a time;
  /// the player always preempts).
  final List<PushableBlock> _blockRescueQueue = [];

  /// True while the claw sequence runs — player control is locked.
  bool get resetting => _resetting;

  PuzzleScript? get roomPuzzle => _room?.puzzle;

  /// World-y of the current node's ceiling underside (thin in rooms, deep
  /// in corridors) — the claw's trolley rail hangs from here, never from
  /// the window edge.
  double get ceilingY =>
      synthesizedCeilingTiles(registry.node(currentNodeId).type) *
      Config.tileSize;

  /// Entity lookup in the current room (cranks resolve their targets here).
  T? roomEntity<T>(String id) => _room?.byId<T>(id);

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
    feedback = FeedbackPopups();

    // Resume where the player left off (GDD §9); fresh start otherwise.
    final progress = await _saves.load();
    if (progress != null) {
      solvedRooms.addAll(progress.solvedRooms);
      foundEtchings.addAll(progress.foundEtchings);
      discoveredSecrets.addAll(progress.discoveredSecrets);
      visitedNodes.addAll(progress.visitedNodes);
      powerups.addAll(
          progress.powerups.map(Powerup.byId).whereType<Powerup>());
    }
    final startNode =
        (progress != null && registry.world.nodes.containsKey(progress.currentNode))
            ? progress.currentNode
            : registry.world.start;
    await loadNode(startNode);

    world.add(player);
    world.add(claw);
    world.add(InteractPrompt());
    world.add(feedback);
    camera.viewport.add(Hud());
    camera.viewport.add(PowerupHud());
    camera.viewport.add(DebugHud());
  }

  /// DEV: wipe the save and restart from the very beginning (F2).
  /// (Room state needs no clearing — every node rebuilds from data on load.)
  void _devFullReset() {
    _saves.wipe();
    solvedRooms.clear();
    foundEtchings.clear();
    discoveredSecrets.clear();
    visitedNodes.clear();
    powerups.clear();
    loadNode(registry.world.start);
  }

  void _autosave() {
    _saves.save(Progress(
      currentNode: currentNodeId,
      solvedRooms: solvedRooms,
      foundEtchings: foundEtchings,
      discoveredSecrets: discoveredSecrets,
      visitedNodes: visitedNodes,
      powerups: powerups.map((p) => p.id).toSet(),
    )); // fire-and-forget; nothing blocks on the disk
  }

  /// Etching collected: persist + a quiet green celebration.
  void collectEtching(String etchingId, Vector2 at) {
    if (!foundEtchings.add(etchingId)) return;
    feedback.emit(FeedbackKind.success, at);
    _autosave();
  }

  /// Powerup collected: gained forever; green celebration + a teaching pulse.
  void collectPowerup(Powerup powerup, Vector2 at) {
    if (!powerups.add(powerup)) return;
    feedback.emit(FeedbackKind.success, at);
    _autosave();
  }

  bool isSecretDiscovered(String exitName) =>
      discoveredSecrets.contains('$currentNodeId/$exitName');

  /// A secret passage used for the first time.
  void discoverSecret(String exitName, PositionComponent door) {
    if (!discoveredSecrets.add('$currentNodeId/$exitName')) return;
    feedback.emit(
      FeedbackKind.success,
      Vector2(door.position.x + door.size.x / 2, door.position.y - 14),
    );
    _autosave();
  }

  /// Tears down the current node and builds [nodeId] from its JSON, placing
  /// the player at [entryKey] (or the node's `start`).
  Future<void> loadNode(String nodeId, {String? entryKey}) async {
    player.carrying = null; // carried objects stay in their room
    claw.abortBlockJob(); // cargo jobs don't survive a room change
    _blockRescueQueue.clear();
    _room?.removeFromParent();
    collisionWorld.solids.clear();
    collisionWorld.ramps.clear();
    interactables.clear();
    blocks.clear();
    waterPools.clear();

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
    visitedNodes.add(nodeId); // the M7 map remembers where you've been
    _autosave();
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

  /// Is the current node's `unlock` rule satisfied? (Optional special gates.)
  bool isUnlockSatisfied() {
    final node = registry.node(currentNodeId);
    final rule = node.unlock;
    if (rule == null) return false; // locked door, no rule, no key yet
    return rule.isSatisfied(solvedRooms, node.rooms);
  }

  /// Is the door using [exitName] open? (Passage doors, GDD §4: open unless
  /// the room that gates it is still unsolved — which room, from either
  /// endpoint, is resolved by the world graph's direction-of-travel rule.)
  bool isSolvedSide(String exitName) {
    final gating = registry.gatingRoomId(currentNodeId, exitName);
    return gating == null || solvedRooms.contains(gating);
  }

  /// A waterlogged block needs fishing out — queue a claw cargo run.
  void requestBlockRescue(PushableBlock block) {
    if (!_blockRescueQueue.contains(block)) _blockRescueQueue.add(block);
  }

  /// The no-death reset (GDD.md §8): hazard contact or the restart button.
  /// The claw performs it; state snaps back on the whirlwind beat.
  void requestReset() {
    if (_resetting) return;
    claw.abortBlockJob(); // the player always outranks cargo
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

    // What can the player act on? (Drives the prompt + the dispatch.)
    // While carrying, the verb means "place" — so nothing else focuses.
    focusedInteractable = null;
    final box = player.aabb;
    if (!player.isCarrying) {
      for (final i in interactables) {
        if (i.canInteract && i.interactZone.overlaps(box)) {
          focusedInteractable = i;
          break;
        }
      }
    }
    // Interact: place what we carry, else act on the focused target,
    // else — if something locked is in range — an honest red "nope".
    if (input.interactPressed && !_resetting) {
      if (player.isCarrying) {
        player.tryPlace();
      } else if (focusedInteractable != null) {
        focusedInteractable!.onInteract();
      } else {
        for (final i in interactables) {
          if (!i.canInteract && i.interactZone.overlaps(box)) {
            final z = i.interactZone;
            feedback.emit(
                FeedbackKind.error, Vector2(z.x + z.w / 2, z.y - 10));
            break;
          }
        }
      }
    }

    // A flipped puzzle marks the room solved (feeds the hub unlock rule).
    final puzzle = roomPuzzle;
    if (puzzle != null &&
        puzzle.isSolved &&
        !solvedRooms.contains(currentNodeId)) {
      solvedRooms.add(currentNodeId);
      feedback.emit(
        FeedbackKind.success,
        Vector2(player.position.x + player.size.x / 2, player.position.y - 18),
      );
      _autosave();
    }

    if (input.restartPressed) requestReset(); // R = voluntary claw
    if (input.devResetPressed && !_resetting) _devFullReset(); // F2 = new game
    if (input.debugTogglePressed) showDebug = !showDebug; // F3 = room id

    // The claw works through its cargo backlog when free.
    if (!claw.busy && _blockRescueQueue.isNotEmpty) {
      final block = _blockRescueQueue.removeAt(0);
      if (block.isMounted && block.waterlogged) {
        claw.playBlockRescue(block: block, onDone: () {});
      }
    }
    // Failsafe: should the player ever escape the room bounds, the claw
    // retrieves them — nobody falls out of the world.
    if (!_resetting && player.position.y > Config.viewportHeight + 60) {
      requestReset();
    }
    input.clearEdges(); // ...then edges expire, lasting exactly one tick
  }
}
