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
    test('lit sensor opens the lever gate (latched); the lever solves', () {
      final sensor =
          LightSensor(Vector2.zero(), Vector2.all(32), entityId: 'sensorA');
      final gate = Gate(Vector2.zero(), Vector2(32, 128));
      final lever =
          Lever(Vector2.zero(), Vector2(32, 40), entityId: 'goalSwitch');
      final puzzle = OpticsMirrorPuzzle()
        ..onLoad(FakeRoom(
            {'sensorA': sensor, 'leverGate': gate, 'goalSwitch': lever}));

      expect(puzzle.isSolved, isFalse);
      expect(gate.open, isFalse);

      sensor.lit = true;
      puzzle.onUpdate(0.016);
      expect(gate.open, isTrue, reason: 'the light opens the way to the lever');
      expect(puzzle.isSolved, isFalse, reason: 'still need to pull the lever');

      // Un-aiming the beam later doesn't re-close the way (latched).
      sensor.lit = false;
      puzzle.onUpdate(0.016);
      expect(gate.open, isTrue);

      lever.on = true;
      expect(puzzle.isSolved, isTrue);
    });
  });
}
