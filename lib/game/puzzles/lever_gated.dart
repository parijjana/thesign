import '../components/gate.dart';
import '../components/lever.dart';
import 'puzzle_script.dart';

/// The castle's one consistent rule (GDD §6, PUZZLES.md): **a goal lever opens
/// every exit door, and the room's puzzle is only the way to reach that lever.**
///
/// This base captures the shared half of that pattern — the door side. A
/// subclass supplies [mechanismSatisfied] (its actual puzzle: a lit sensor, a
/// full set of plates, a completed sequence…); when that becomes true the
/// internal `leverGate` blocking the lever's nook latches OPEN, so the player
/// can walk in and pull `goalSwitch`. The room is solved only once the lever is
/// on — never by the mechanism alone (that is what makes the lever *needed*).
///
/// `P1PressurePlates` predates this and hand-rolls the same shape; the physical
/// rooms (stacking/seesaw/counterweight) need no gate at all — their geometry IS
/// the way to the lever — so they use [StubSwitchPuzzle] instead.
abstract class LeverGatedPuzzle extends PuzzleScript {
  Lever? _lever;
  Gate? _leverGate;
  bool _exposed = false;

  /// The room's own puzzle condition. Subclasses resolve their entities in
  /// [onLoadMechanism] and report progress here.
  bool get mechanismSatisfied;

  /// Subclass hook: grab mechanism entities (called from [onLoad]).
  void onLoadMechanism(PuzzleRoom room) {}

  @override
  void onLoad(PuzzleRoom room) {
    _lever = room.byId<Lever>('goalSwitch');
    _leverGate = room.byId<Gate>('leverGate');
    onLoadMechanism(room);
    assert(_lever != null && _leverGate != null,
        'a lever-gated puzzle needs a goalSwitch lever and a leverGate gate');
  }

  @override
  void onUpdate(double dt) {
    // Latch: once earned, the way to the lever stays open (no re-solving on the
    // walk over — kindness, GDD §8).
    if (mechanismSatisfied) _exposed = true;
    _leverGate?.open = _exposed;
  }

  @override
  bool get isSolved => _lever?.on ?? false;
}
