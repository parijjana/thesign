import '../components/optics.dart';
import 'puzzle_script.dart';

/// Optics — Mirror routing (the first "wow" room, worked example doc):
/// rotate the mirrors until the beam lands on `sensorA`. Solved latches:
/// once the light has touched the sensor, un-aiming it doesn't unsolve.
class OpticsMirrorPuzzle extends PuzzleScript {
  LightSensor? _sensor;
  bool _solved = false;

  @override
  void onLoad(PuzzleRoom room) {
    _sensor = room.byId<LightSensor>('sensorA');
    assert(_sensor != null, 'optics_mirror needs sensorA');
  }

  @override
  void onUpdate(double dt) {
    if (_sensor?.lit ?? false) _solved = true;
  }

  @override
  bool get isSolved => _solved;
}
