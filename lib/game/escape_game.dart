import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

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
import 'save/settings.dart';
import 'ui/debug_hud.dart';
import 'ui/feedback_popups.dart';
import 'ui/hud.dart';
import 'ui/interact_prompt.dart';
import 'ui/powerup_hud.dart';
import 'ui/spine_hud.dart';
import 'ui/touch_controls.dart';

/// App-level phase (M7 shell, GDD §10b). The play space only ticks in
/// [playing]; [title], [profileSelect], [paused] and [won] freeze it behind a
/// Flutter overlay.
enum GamePhase { title, profileSelect, playing, paused, won }

/// The game shell: fixed-resolution letterboxed camera, active palette,
/// input plumbing, collision world, the world graph, and the no-death reset
/// orchestration (ARCHITECTURE.md §5).
class EscapeGame extends FlameGame with HasKeyboardHandlerComponents {
  EscapeGame() : super(camera: CameraComponent());

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
  // Reassigned when the player picks an avatar slot (M7 profile select).
  SaveService _saves = SaveService();

  /// App-wide settings (sound/music toggles, touch-control size). Loaded in
  /// [onLoad]; global, not per-profile.
  AppSettings settings = AppSettings();

  /// The mounted touch controls (touch platforms only) — held so a size-preset
  /// change can remount them at the new size.
  TouchControls? _touch;

  RoomComponent? _room;
  String currentNodeId = '';

  /// Short code of the current node (debug overlay).
  String get currentNodeCode => _room?.data.code ?? '?';

  /// DEV: F3 toggles the room-id overlay.
  bool showDebug = false;

  /// App phase (M7 shell). Starts at the title; the play space ticks only in
  /// [GamePhase.playing]. Overlay names match `main.dart`'s overlayBuilderMap.
  GamePhase phase = GamePhase.title;

  static const titleOverlay = 'title';
  static const profileOverlay = 'profile';
  static const pauseOverlay = 'pause';
  static const mapOverlay = 'map';
  static const winOverlay = 'win';
  static const settingsOverlay = 'settings';
  static const inventoryOverlay = 'inventory';

  /// Bumped whenever a setting changes so the SettingsOverlay rebuilds.
  final ValueNotifier<int> settingsVersion = ValueNotifier<int>(0);

  /// Which menu button the keyboard cursor is on (M7 keyboard nav). Overlays
  /// listen to this to highlight the selection; mouse taps act directly. Reset
  /// to 0 whenever a menu opens.
  final ValueNotifier<int> shellSelection = ValueNotifier<int>(0);

  /// Profile slots that already hold a saved run — the select screen shows a
  /// resume dot on these. Refreshed each time the screen opens.
  final ValueNotifier<Set<String>> profilesWithSaves =
      ValueNotifier<Set<String>>(const {});

  /// Title → avatar/profile select (GDD §10b screen flow).
  void startGame() => showProfileSelect();

  /// Show the avatar-select screen; pre-highlight the last-played slot.
  Future<void> showProfileSelect() async {
    phase = GamePhase.profileSelect;

    overlays.remove(titleOverlay);
    overlays.add(profileOverlay);
    profilesWithSaves.value = await SaveService.profilesWithSaves();
    final last = await SaveService.lastProfile();
    final i = last == null ? 0 : SaveService.profileIds.indexOf(last);
    shellSelection.value = i < 0 ? 0 : i;
  }

  /// Pick an avatar slot: bind saves to it, load its run (or start fresh), and
  /// drop into play. Clears any in-memory progress from a prior slot first.
  Future<void> chooseProfile(String id) async {
    _saves = SaveService(profile: id);
    await _saves.markActive();
    solvedRooms.clear();
    foundEtchings.clear();
    discoveredSecrets.clear();
    visitedNodes.clear();
    powerups.clear();
    final progress = await _saves.load();
    if (progress != null) {
      solvedRooms.addAll(progress.solvedRooms);
      foundEtchings.addAll(progress.foundEtchings);
      discoveredSecrets.addAll(progress.discoveredSecrets);
      visitedNodes.addAll(progress.visitedNodes);
      powerups
          .addAll(progress.powerups.map(Powerup.byId).whereType<Powerup>());
    }
    await loadNode(registry.world.start);
    setPlaying();
  }

  void setPlaying() {
    phase = GamePhase.playing;
    overlays.remove(titleOverlay);
    overlays.remove(profileOverlay);
    overlays.remove(pauseOverlay);
    overlays.remove(mapOverlay);
    overlays.remove(winOverlay);
    overlays.remove(settingsOverlay);
    overlays.remove(inventoryOverlay);
  }

  void pauseGame() {
    if (phase != GamePhase.playing) return;
    phase = GamePhase.paused;
    shellSelection.value = 0;
    overlays.add(pauseOverlay);
  }

  void resumeGame() {
    if (phase != GamePhase.paused) return;
    setPlaying();
  }

  /// Leave the run and show the title (the play space stays loaded behind it).
  void exitToTitle() {
    phase = GamePhase.title;

    shellSelection.value = 0;
    overlays.remove(pauseOverlay);
    overlays.remove(winOverlay);
    overlays.remove(profileOverlay);
    overlays.add(titleOverlay);
  }

  void togglePause() =>
      phase == GamePhase.paused ? resumeGame() : pauseGame();

  /// Castle map (MAZE.md §5) — opened from pause, returns to pause on close.
  void showMap() {
    overlays.remove(pauseOverlay);
    overlays.add(mapOverlay);
  }

  void hideMap() {
    overlays.remove(mapOverlay);
    overlays.add(pauseOverlay);
  }

  /// Field Kit / inventory (GDD §9b) — the powerup shelf, opened from pause.
  void showInventory() {
    overlays.remove(pauseOverlay);
    overlays.add(inventoryOverlay);
  }

  void hideInventory() {
    overlays.remove(inventoryOverlay);
    overlays.add(pauseOverlay);
  }

  /// You escaped the castle (GDD §3 twist): arriving back in the meadow from a
  /// castle node. A celebratory ending — but the exit stays free, so the
  /// player can dive back in and keep exploring (ICEBOX replayability).
  void _winEscape() {
    phase = GamePhase.won;
    shellSelection.value = 0;
    overlays.add(winOverlay);
  }

  /// A key press routed from the **visible shell overlay's own Flutter focus**
  /// (`_ShellKeys` in shell_overlays.dart) — the reliable way to drive the
  /// frozen menus, since Flame's GameWidget only gets keyboard focus after the
  /// first click (so the launch title / settings would otherwise be keyboard-
  /// dead). The overlay on top always has focus and forwards keys here. Returns
  /// true if consumed. Arrows/A-D/W-S move the cursor; Enter/Space/E confirm;
  /// Esc backs out.
  bool handleShellKey(LogicalKeyboardKey key) {
    final next = {
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyS,
    };
    final prev = {
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyW,
    };
    final confirm = {
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.keyE,
    };
    return _shellNav(
      next.contains(key),
      prev.contains(key),
      confirm.contains(key),
      key == LogicalKeyboardKey.escape,
    );
  }

  /// Shared menu dispatch for the frozen shell phases — the single source of
  /// truth for keyboard nav. The overlays' taps call the same action lists.
  bool _shellNav(bool next, bool prev, bool confirm, bool back) {
    void move(int count) {
      if (next) shellSelection.value = (shellSelection.value + 1) % count;
      if (prev) {
        shellSelection.value = (shellSelection.value - 1 + count) % count;
      }
    }

    // Settings floats over either the title or the pause menu, so handle it
    // before the phase switch.
    if (overlays.isActive(settingsOverlay)) {
      if (back) {
        hideSettings();
      } else {
        move(settingsActions.length);
        if (confirm) settingsActions[shellSelection.value]();
      }
      return true;
    }

    switch (phase) {
      case GamePhase.title:
        move(titleActions.length);
        if (confirm) titleActions[shellSelection.value]();
        return true;
      case GamePhase.profileSelect:
        if (back) {
          exitToTitle(); // Esc backs out to the title
        } else {
          move(profileActions.length);
          if (confirm) profileActions[shellSelection.value]();
        }
        return true;
      case GamePhase.won:
        move(winActions.length);
        if (confirm) winActions[shellSelection.value]();
        return true;
      case GamePhase.paused:
        if (overlays.isActive(mapOverlay)) {
          if (back || confirm) hideMap();
          return true;
        }
        if (overlays.isActive(inventoryOverlay)) {
          if (back || confirm) hideInventory();
          return true;
        }
        if (back) {
          resumeGame();
          return true;
        }
        move(pauseActions.length);
        if (confirm) pauseActions[shellSelection.value]();
        return true;
      case GamePhase.playing:
        return false;
    }
  }

  /// Title-screen actions (same-order contract with TitleOverlay): play (→
  /// avatar select) or open settings.
  late final List<void Function()> titleActions = [startGame, showSettings];

  /// Pause-menu actions, in row order. The PauseOverlay draws its icons in the
  /// SAME order, so taps and the keyboard cursor stay in lockstep.
  late final List<void Function()> pauseActions = [
    resumeGame,
    () {
      requestReset();
      resumeGame();
    },
    showMap,
    showInventory,
    showSettings,
    exitToTitle,
  ];

  /// Win-screen actions (same-order contract with WinOverlay): keep exploring
  /// the free meadow, or return to the title.
  late final List<void Function()> winActions = [setPlaying, exitToTitle];

  /// Profile-select actions, one per avatar slot (same-order contract with
  /// ProfileOverlay): pick that slot and drop into play.
  late final List<void Function()> profileActions = [
    for (final id in SaveService.profileIds) () => chooseProfile(id),
  ];

  // Where to return when the settings screen closes ('title' or 'pause') —
  // settings is reachable from both, and the phase stays put while it's open.
  String _settingsReturn = 'title';

  /// Open settings over the title or the pause menu (whichever is showing).
  void showSettings() {
    _settingsReturn = phase == GamePhase.paused ? 'pause' : 'title';

    shellSelection.value = 0;
    overlays.remove(_settingsReturn == 'pause' ? pauseOverlay : titleOverlay);
    overlays.add(settingsOverlay);
  }

  void hideSettings() {
    overlays.remove(settingsOverlay);

    shellSelection.value = 0;
    overlays.add(_settingsReturn == 'pause' ? pauseOverlay : titleOverlay);
  }

  /// Settings-screen actions, in row order (same-order contract with
  /// SettingsOverlay): toggle sound, toggle music, cycle touch size, back.
  late final List<void Function()> settingsActions = [
    () {
      settings.soundOn = !settings.soundOn;
      _settingsChanged();
    },
    () {
      settings.musicOn = !settings.musicOn;
      _settingsChanged();
    },
    () {
      settings.touchScale = settings.touchScale.next;
      _settingsChanged();
      _applyTouchScale();
    },
    hideSettings,
  ];

  void _settingsChanged() {
    settings.save(); // fire-and-forget
    settingsVersion.value++;
  }

  /// Remount the touch controls so a new size preset takes effect immediately
  /// (no-op on desktop, where they aren't mounted).
  void _applyTouchScale() {
    final touch = _touch;
    if (touch == null) return;
    touch.removeFromParent();
    _touch = TouchControls();
    camera.viewport.add(_touch!);
  }

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

  /// Show on-screen touch controls on touch-first platforms (ROADMAP M5).
  /// v1 is platform-gated (Android/iOS); web touch-vs-mouse runtime detection
  /// is a documented follow-up.
  bool get useTouchControls =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

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

  /// Any uncovered margin renders in ink, framing the room like a sign's border.
  @override
  Color backgroundColor() => palette.ink;

  /// Cover-fit the fixed 24×14 logical room to the device screen: zoom so the
  /// room fills the whole viewport (no bars), centred — the screen crops the
  /// decorative top/bottom (ceiling brick, floor base) on tall/wide aspects
  /// while the play area stays framed. (Replaces the M1 letterbox now that
  /// mobile makes pillarboxing waste too much of a small screen — ROADMAP M5.)
  void _fitCamera(Vector2 size) {
    if (size.x <= 0 || size.y <= 0) return;
    camera.viewfinder.zoom = math.max(
      size.x / Config.viewportWidth,
      size.y / Config.viewportHeight,
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _fitCamera(size);
  }

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position =
        Vector2(Config.viewportWidth / 2, Config.viewportHeight / 2);
    _fitCamera(size);
    add(KeyboardInput(input));
    settings = await AppSettings.load();
    registry = await RoomRegistry.load(assets);
    player = Player();
    claw = ClawReset();
    feedback = FeedbackPopups();

    // Default the save binding to the last-played slot so the world frozen
    // behind the title matches a returning player (they confirm the slot on
    // the select screen, which reloads it anyway). Fresh installs stay on p1.
    final last = await SaveService.lastProfile();
    if (last != null) _saves = SaveService(profile: last);

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
    // Always boot at the meadow HUB (world.start), not the last room — the
    // meadow is home base (M7). Progress (solved/visited/powerups, and so the
    // lit teleporters) is restored above, so you resume by re-entering a portal
    // rather than mid-room. Kinder and consistent with "you start in the meadow".
    await loadNode(registry.world.start);

    world.add(player);
    world.add(claw);
    world.add(InteractPrompt());
    world.add(feedback);
    // The top-right meta row (claw/settings/pause) is a desktop display row;
    // on touch the TouchControls overlay owns the (tappable) claw, so showing
    // both would duplicate the glyph — pick one per platform.
    if (useTouchControls) {
      _touch = TouchControls();
      camera.viewport.add(_touch!);
    } else {
      camera.viewport.add(Hud());
    }
    camera.viewport.add(PowerupHud());
    camera.viewport.add(SpineHud());
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
    // Escaping = arriving at the meadow (world.start) FROM a castle node. The
    // only such edge is exit_hall's "out" portal (meadow→castle edges are
    // one-way re-entries), so this is precisely THE win.
    final escaping = currentNodeId != registry.world.start &&
        transition.targetId == registry.world.start;
    loadNode(transition.targetId, entryKey: transition.entryKey);
    if (escaping) _winEscape();
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
    // Title/pause/win freeze the play space behind a Flutter overlay; the
    // shell is driven entirely by the keyboard (and mouse taps) here, so the
    // whole game is playable without a pointer (GDD §10 keyboard nav).
    if (phase != GamePhase.playing) {
      // The play space is frozen; the visible shell overlay owns the keyboard
      // (via its own Flutter focus → handleShellKey), so nothing to do here.
      input.clearEdges();
      return;
    }
    // Playing: Esc / touch pause button opens the pause menu.
    if (input.pausePressed) {
      pauseGame();
      input.clearEdges();
      return;
    }
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
