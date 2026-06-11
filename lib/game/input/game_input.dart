/// Platform-agnostic input intents (ARCHITECTURE.md §5.4).
///
/// Sources (keyboard now, touch in M5) WRITE into this; game logic only ever
/// READS it. Game code never sees raw key/touch events — that's what keeps
/// all platforms uniform and rebinding trivial.
///
/// Held state ([moveAxis], [jumpHeld]) reflects the current frame.
/// Edge flags ([jumpPressed], …) are set by a source on the press event and
/// cleared by the game at the end of each update tick via [clearEdges].
class GameInput {
  /// Horizontal movement intent, -1 (left) .. 1 (right).
  double moveAxis = 0;

  /// Jump button currently held (for variable jump height later).
  bool jumpHeld = false;

  /// Edge: jump was pressed this tick (buffered by the player controller).
  bool jumpPressed = false;

  /// Edge: interact/use was pressed this tick.
  bool interactPressed = false;

  /// Edge: restart-room (the claw button) was pressed this tick.
  bool restartPressed = false;

  /// Edge: pause was pressed this tick.
  bool pausePressed = false;

  /// Edge: DEV ONLY — full progress wipe + restart (F2). Not a player verb;
  /// the real "new game" lives in the profile UI (M7).
  bool devResetPressed = false;

  /// Called by the game after each update tick, so edges last exactly one tick.
  void clearEdges() {
    jumpPressed = false;
    interactPressed = false;
    restartPressed = false;
    pausePressed = false;
    devResetPressed = false;
  }
}
