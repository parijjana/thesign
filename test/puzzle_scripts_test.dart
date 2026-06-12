import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesign/game/components/gate.dart';
import 'package:thesign/game/components/lever.dart';
import 'package:thesign/game/components/optics.dart';
import 'package:thesign/game/components/pressure_plate.dart';
import 'package:thesign/game/puzzles/optics_mirror.dart';
import 'package:thesign/game/puzzles/p1_pressure_plates.dart';
import 'package:thesign/game/puzzles/puzzle_script.dart';

class FakeRoom implements PuzzleRoom {
  FakeRoom(this.entities);

  final Map<String, Object> entities;

  @override
  T? byId<T>(String id) {
    final e = entities[id];
    if (e is T) return e;
    return null;
  }

  @override
  List<T> allOf<T>() => entities.values.whereType<T>().toList();

  @override
  void emitError(String entityId) {}

  @override
  void emitSuccess(String entityId) {}
}

void main() {
  group('P1PressurePlates (headless)', () {
    late PressurePlate plate;
    late Gate gate;
    late Lever lever;
    late P1PressurePlates puzzle;

    setUp(() {
      plate = PressurePlate(Vector2.zero(), Vector2(64, 8));
      gate = Gate(Vector2.zero(), Vector2(32, 128));
      lever = Lever(Vector2.zero(), Vector2(32, 40), entityId: 'goalSwitch');
      puzzle = P1PressurePlates()
        ..onLoad(FakeRoom(
            {'plateA': plate, 'gateA': gate, 'goalSwitch': lever}));
    });

    test('gate follows the plate', () {
      expect(gate.open, isFalse);
      plate.pressed = true;
      puzzle.onUpdate(0.016);
      expect(gate.open, isTrue);
      plate.pressed = false;
      puzzle.onUpdate(0.016);
      expect(gate.open, isFalse);
    });

    test('solved by the goal lever, not the plate', () {
      plate.pressed = true;
      puzzle.onUpdate(0.016);
      expect(puzzle.isSolved, isFalse);
      lever.on = true;
      expect(puzzle.isSolved, isTrue);
    });
  });

  group('OpticsMirrorPuzzle (headless)', () {
    test('solved latches once the sensor has been lit', () {
      final sensor =
          LightSensor(Vector2.zero(), Vector2.all(32), entityId: 'sensorA');
      final puzzle = OpticsMirrorPuzzle()
        ..onLoad(FakeRoom({'sensorA': sensor}));

      expect(puzzle.isSolved, isFalse);
      sensor.lit = true;
      puzzle.onUpdate(0.016);
      expect(puzzle.isSolved, isTrue);
      // Un-aiming the beam later doesn't unsolve the room.
      sensor.lit = false;
      puzzle.onUpdate(0.016);
      expect(puzzle.isSolved, isTrue);
    });
  });
}
