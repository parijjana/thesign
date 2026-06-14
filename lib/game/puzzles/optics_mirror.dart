import '../components/optics.dart';
import 'lever_gated.dart';
import 'puzzle_script.dart';

/// Optics — Mirror routing (the first "wow" room, worked example doc):
/// rotate the mirrors until the beam lands on `sensorA`. The lit sensor opens
/// the way to the goal lever ([LeverGatedPuzzle]); the latch means once the
/// light has touched the sensor, un-aiming it doesn't re-close the way.
class OpticsMirrorPuzzle extends LeverGatedPuzzle {
  LightSensor? _sensor;

  @override
  void onLoadMechanism(PuzzleRoom room) {
    _sensor = room.byId<LightSensor>('sensorA');
    assert(_sensor != null, 'optics_mirror needs sensorA');
  }

  @override
  bool get mechanismSatisfied => _sensor?.lit ?? false;
}
