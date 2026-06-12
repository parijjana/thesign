import '../components/gate.dart';
import '../components/lever.dart';
import '../components/optics.dart';
import '../components/pressure_plate.dart';
import 'puzzle_script.dart';

/// M6 puzzle scripts (M6_PLAN.md Phase 2). The seesaw and counterweight
/// rooms are physical puzzles — their logic lives in the components, so a
/// goal lever (StubSwitch) suffices; these are the rooms with real logic.

/// Sokoban: solved when EVERY pressure plate is weighed down at once.
class SokobanPuzzle extends PuzzleScript {
  List<PressurePlate> _plates = const [];
  bool _solved = false;

  @override
  void onLoad(PuzzleRoom room) {
    _plates = room.allOf<PressurePlate>();
    assert(_plates.isNotEmpty, 'sokoban needs pressure plates');
  }

  @override
  void onUpdate(double dt) {
    if (!_solved && _plates.every((p) => p.pressed)) _solved = true;
  }

  @override
  bool get isSolved => _solved;
}

/// Splitter: one beam, two sensors — both must be lit at once.
class SplitterPuzzle extends PuzzleScript {
  List<LightSensor> _sensors = const [];
  bool _solved = false;

  @override
  void onLoad(PuzzleRoom room) {
    _sensors = room.allOf<LightSensor>();
    assert(_sensors.length >= 2, 'splitter room wants two sensors');
  }

  @override
  void onUpdate(double dt) {
    if (!_solved && _sensors.every((s) => s.lit)) _solved = true;
  }

  @override
  bool get isSolved => _solved;
}

/// Sequence: flip the levers in pip order (1, 2, 3 — shown by pip signs).
/// A wrong lever resets them all with a red "nope".
class SequencePuzzle extends PuzzleScript {
  SequencePuzzle({this.order = const ['lev1', 'lev2', 'lev3']});

  /// Lever entity ids in the correct order.
  final List<String> order;

  PuzzleRoom? _room;
  int _next = 0;
  bool _solved = false;

  @override
  void onLoad(PuzzleRoom room) => _room = room;

  @override
  void onInteract(String entityId) {
    if (_solved || !order.contains(entityId)) return;
    if (entityId == order[_next]) {
      _next++;
      _room?.emitSuccess(entityId);
      if (_next >= order.length) _solved = true;
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
  bool get isSolved => _solved;

  @override
  void onReset() {
    // The claw's whirlwind clears a half-entered sequence (opt-in, GDD §8).
    if (_solved) return;
    _next = 0;
    for (final id in order) {
      _room?.byId<Lever>(id)?.on = false;
    }
  }
}

/// Capstone (mech + optics fusion): a block on the plate holds the gate
/// open; the OPEN gate lets the beam through to the sensor (a closed gate is
/// a solid the tracer cannot pass). Two disciplines, one chain — the final
/// exam before the exit.
class CapstonePuzzle extends PuzzleScript {
  PressurePlate? _plate;
  Gate? _gate;
  LightSensor? _sensor;
  bool _solved = false;

  @override
  void onLoad(PuzzleRoom room) {
    _plate = room.byId<PressurePlate>('plateA');
    _gate = room.byId<Gate>('gateA');
    _sensor = room.byId<LightSensor>('sensorA');
    assert(_plate != null && _gate != null && _sensor != null,
        'capstone needs plateA, gateA, sensorA');
  }

  @override
  void onUpdate(double dt) {
    _gate?.open = _plate?.pressed ?? false;
    if (_sensor?.lit ?? false) _solved = true;
  }

  @override
  bool get isSolved => _solved;
}
