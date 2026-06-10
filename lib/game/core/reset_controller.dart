/// The no-death reset, as pure logic (ARCHITECTURE.md §5.6).
///
/// Anything that must snap back to its authored start state (moving hazards,
/// platforms — later, opted-in puzzle objects) registers as a [Resettable].
/// The claw animation is presentation ONLY: it calls [reset] on its whirlwind
/// beat. Headless tests (and a force-skip path) call [reset] directly — same
/// resulting state, no claw required.
abstract interface class Resettable {
  void resetToStart();
}

class ResetController {
  final List<Resettable> _bodies = [];

  void register(Resettable body) => _bodies.add(body);

  void unregister(Resettable body) => _bodies.remove(body);

  /// Snaps every registered body back to its authored start state.
  /// (The player's teleport to the node `start` is handled by the caller —
  /// the claw places the player as part of its animation.)
  void reset() {
    for (final body in _bodies) {
      body.resetToStart();
    }
  }
}
