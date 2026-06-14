import '../components/gate.dart';
import '../components/lever.dart';
import '../components/optics.dart';
import '../components/pressure_plate.dart';
import 'lever_gated.dart';
import 'puzzle_script.dart';

/// M6 puzzle scripts (M6_PLAN.md Phase 2). Every one is now lever-gated
/// ([LeverGatedPuzzle]): the mechanism only opens the way to the goal lever,
/// and pulling that lever is what opens the exit door. The seesaw and
/// counterweight rooms stay purely physical (a goal lever + geometry, via
/// StubSwitch) — these are the rooms with real logic on top.

/// Sokoban: the way opens when EVERY pressure plate is weighed down at once.
class SokobanPuzzle extends LeverGatedPuzzle {
  List<PressurePlate> _plates = const [];

  @override
  void onLoadMechanism(PuzzleRoom room) {
    _plates = room.allOf<PressurePlate>();
    assert(_plates.isNotEmpty, 'sokoban needs pressure plates');
  }

  @override
  bool get mechanismSatisfied =>
      _plates.isNotEmpty && _plates.every((p) => p.pressed);
}

/// Splitter: one beam, two sensors — the way opens when both are lit at once.
class SplitterPuzzle extends LeverGatedPuzzle {
  List<LightSensor> _sensors = const [];

  @override
  void onLoadMechanism(PuzzleRoom room) {
    _sensors = room.allOf<LightSensor>();
    assert(_sensors.length >= 2, 'splitter room wants two sensors');
  }

  @override
  bool get mechanismSatisfied =>
      _sensors.length >= 2 && _sensors.every((s) => s.lit);
}

/// Sequence: flip the puzzle levers in pip order (1, 2, 3 — shown by pip
/// signs) to open the way to the goal lever. A wrong lever resets them all
/// with a red "nope". The goal lever (`goalSwitch`) is not part of the order.
class SequencePuzzle extends LeverGatedPuzzle {
  SequencePuzzle({this.order = const ['lev1', 'lev2', 'lev3']});

  /// Lever entity ids in the correct order.
  final List<String> order;

  PuzzleRoom? _room;
  int _next = 0;
  bool _done = false;

  @override
  void onLoadMechanism(PuzzleRoom room) => _room = room;

  @override
  bool get mechanismSatisfied => _done;

  @override
  void onInteract(String entityId) {
    if (_done || !order.contains(entityId)) return;
    if (entityId == order[_next]) {
      _next++;
      _room?.emitSuccess(entityId);
      if (_next >= order.length) _done = true;
    } else {
      // Wrong order: everything flips back off — try again, no harm done.
      _next = 0;
      for (final id in order) {
        _room?.byId<Lever>(id)?.on = false;
      }
      _room?.emitError(entityId);
    }
  }

  @override
  void onReset() {
    // The claw's whirlwind clears a half-entered sequence (opt-in, GDD §8).
    if (_done) return;
    _next = 0;
    for (final id in order) {
      _room?.byId<Lever>(id)?.on = false;
    }
  }
}

/// Capstone (mech + optics fusion): a block on the plate holds `gateA` open;
/// the OPEN gate lets the beam through to the sensor (a closed gate is a solid
/// the tracer cannot pass). The lit sensor opens the way to the goal lever —
/// two disciplines, one chain — the final exam before the exit.
class CapstonePuzzle extends LeverGatedPuzzle {
  PressurePlate? _plate;
  Gate? _beamGate;
  LightSensor? _sensor;

  @override
  void onLoadMechanism(PuzzleRoom room) {
    _plate = room.byId<PressurePlate>('plateA');
    _beamGate = room.byId<Gate>('gateA');
    _sensor = room.byId<LightSensor>('sensorA');
    assert(_plate != null && _beamGate != null && _sensor != null,
        'capstone needs plateA, gateA, sensorA');
  }

  @override
  void onUpdate(double dt) {
    // The beam-routing gate tracks the plate every frame (NOT the lever gate).
    _beamGate?.open = _plate?.pressed ?? false;
    super.onUpdate(dt); // latches the lever gate when the sensor lights
  }

  @override
  bool get mechanismSatisfied => _sensor?.lit ?? false;
}
