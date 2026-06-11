import '../components/gate.dart';
import '../components/lever.dart';
import '../components/pressure_plate.dart';
import 'puzzle_script.dart';

/// P1 — Pressure plates (Mechanics, GDD §6 seed set): weigh down `plateA`
/// (carry the block onto it) to hold `gateA` open, reach `goalSwitch`
/// behind it, pull it → solved.
class P1PressurePlates extends PuzzleScript {
  PressurePlate? _plate;
  Gate? _gate;
  Lever? _lever;

  @override
  void onLoad(PuzzleRoom room) {
    _plate = room.byId<PressurePlate>('plateA');
    _gate = room.byId<Gate>('gateA');
    _lever = room.byId<Lever>('goalSwitch');
    assert(_plate != null && _gate != null && _lever != null,
        'p1 needs plateA, gateA, goalSwitch');
  }

  @override
  void onUpdate(double dt) {
    _gate?.open = _plate?.pressed ?? false;
  }

  @override
  bool get isSolved => _lever?.on ?? false;
}
