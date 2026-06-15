import '../components/gate.dart';
import '../components/lever.dart';
import 'puzzle_script.dart';

/// The castle's one consistent rule (GDD §6, PUZZLES.md): **a goal lever opens
/// every exit door, and the room's puzzle is only the way to reach that lever.**
///
/// This base captures the shared half of that pattern — the door side. A
/// subclass supplies [mechanismSatisfied] (its actual puzzle: a lit sensor, a
/// full set of plates, a completed sequence…); while that holds, the internal
/// `leverGate` portcullis blocking the lever's nook stands OPEN so the player
/// can walk in and pull `goalSwitch`. The room is solved only once the lever is
/// on — never by the mechanism alone (that is what makes the lever *needed*).
///
/// **LIVE-GATE RULE (game-wide):** a mechanism gate is a *live* readout of its
/// inputs — the portcullis is up only WHILE the condition holds and drops again
/// the moment an input is removed (lift a block off a plate → it comes back
/// down). It never latches. Only the `goalSwitch` lever latches — it is the
/// commit. (So a room must keep its mechanism satisfied passively — blocks left
/// on plates, mirrors cranked into place — not by the player standing on it and
/// then walking away.)
///
/// `P1PressurePlates` predates this and hand-rolls the same live shape; the
/// physical rooms (stacking/counterweight) need no gate at all — their geometry
/// IS the way to the lever — so they use [StubSwitchPuzzle] instead.
abstract class LeverGatedPuzzle extends PuzzleScript {
  Lever? _lever;
  Gate? _leverGate;

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
    // Live while solving — up only while the mechanism holds; release an input
    // and the portcullis drops again. BUT once the goal lever is thrown the
    // room is solved for good: the portcullis stays open regardless of the
    // mechanism, so the player can never be trapped behind it and can always
    // retrace their steps (the lever overrides the mechanism — anti-soft-lock).
    _leverGate?.open = isSolved || mechanismSatisfied;
  }

  @override
  bool get isSolved => _lever?.on ?? false;
}
