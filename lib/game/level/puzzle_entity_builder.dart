import 'package:flame/components.dart';

import '../components/gate.dart';
import '../components/lever.dart';
import '../components/optics.dart';
import '../components/pressure_plate.dart';
import 'level_model.dart';

/// Builds the **puzzle-queryable** components from level data — the entity
/// types a [PuzzleScript] resolves via `room.byId<T>()` / `room.allOf<T>()`
/// (levers, plates, gates, and the optics pieces).
///
/// WHY THIS EXISTS (single source of truth): the game's level loader AND the
/// `level_wiring_test` both build these entities through this one function, so
/// an entity a puzzle resolves in-game is guaranteed identical to the one the
/// test builds. That closes the seam that let `room_counter` ship a lever
/// named `goalSwitch` while its script looked for `switch` — the script's
/// `onLoad` would now fail at `flutter test` time, not in play.
///
/// EXTENDING — when you add a new entity type that a puzzle script will look
/// up by id (`room.byId<NewThing>('x')` or `room.allOf<NewThing>()`):
///   1. add its `case` HERE (so the loader and the wiring test build it the
///      same way), and
///   2. construct it WITHOUT needing a game/`HasGameReference` — only
///      `pos`/`size`/`props`, like the others (the game ref is fine to use in
///      `update`/`render`, just not in the constructor, so it stays
///      headless-buildable).
/// Entity types a puzzle NEVER queries (floor, wall, door, decorations,
/// hazards, platforms) stay in the loader's own switch — don't add them here.
Component? buildPuzzleEntity(EntityData e, double t) {
  final pos = Vector2(e.x * t, e.y * t);
  final size = Vector2(e.w * t, e.h * t);
  return switch (e.type) {
    'lever' => Lever(
        pos,
        size,
        entityId: e.id ?? 'lever',
        startsOn: e.props['startsOn'] as bool? ?? false,
      ),
    'pressure_plate' => PressurePlate(pos, size),
    'gate' => Gate(pos, size),
    'light_source' =>
      LightSource(pos, size, dir: e.props['dir'] as String? ?? 'east'),
    'mirror' => Mirror(
        pos,
        size,
        entityId: e.id ?? 'mirror',
        state: e.props['start'] as String? ?? '/',
        rotatable: e.props['rotatable'] as bool? ?? true,
      ),
    'beam_splitter' =>
      Splitter(pos, size, state: e.props['state'] as String? ?? '/'),
    'light_sensor' => LightSensor(pos, size, entityId: e.id ?? 'sensor'),
    _ => null, // not puzzle-queryable — the loader handles it
  };
}
