/// The "logic hooks" of the authoring model: JSON describes geometry, a
/// PuzzleScript holds the room's bespoke behavior (LEVEL_FORMAT.md §5,
/// ARCHITECTURE.md §5.7).
library;

/// What a script may ask of its room — kept minimal and abstract so scripts
/// are headless-testable with a fake room.
abstract interface class PuzzleRoom {
  /// Look up an entity by its JSON `id` (null if absent/of the wrong type).
  T? byId<T>(String id);

  /// Every entity of a type (e.g. all pressure plates for a sokoban check).
  List<T> allOf<T>();

  /// Feedback popups over an entity (SYMBOLS §6b) — red "nope".
  void emitError(String entityId);

  /// Feedback popups over an entity — green "yes!".
  void emitSuccess(String entityId);
}

abstract class PuzzleScript {
  /// Grab entities by id, wire initial state.
  void onLoad(PuzzleRoom room) {}

  /// Per-frame logic (timers, sequences).
  void onUpdate(double dt) {}

  /// Player pressed interact on the entity with this JSON id.
  void onInteract(String entityId) {}

  /// A trigger zone fired (M4+).
  void onTrigger(String zoneId, {required bool entered}) {}

  /// Flipping true marks the room solved (the loader/game reacts).
  bool get isSolved;

  /// Claw reset: puzzle progress is PRESERVED by default (GDD §8);
  /// override to opt in to clearing state.
  void onReset() {}
}
