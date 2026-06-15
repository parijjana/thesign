import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesign/game/components/gate.dart';
import 'package:thesign/game/components/lever.dart';
import 'package:thesign/game/components/optics.dart';
import 'package:thesign/game/components/pressure_plate.dart';
import 'package:thesign/game/puzzles/m6_puzzles.dart';
import 'package:thesign/game/puzzles/puzzle_script.dart';

class FakeRoom implements PuzzleRoom {
  FakeRoom(this.entities);

  final Map<String, Object> entities;
  final List<String> errors = [];

  @override
  T? byId<T>(String id) {
    final e = entities[id];
    if (e is T) return e;
    return null;
  }

  @override
  List<T> allOf<T>() => entities.values.whereType<T>().toList();

  @override
  void emitError(String entityId) => errors.add(entityId);

  @override
  void emitSuccess(String entityId) {}
}

PressurePlate plate() => PressurePlate(Vector2.zero(), Vector2(64, 8));
Lever lever(String id) => Lever(Vector2.zero(), Vector2.all(32), entityId: id);
LightSensor sensor(String id) =>
    LightSensor(Vector2.zero(), Vector2.all(32), entityId: id);
Gate gate() => Gate(Vector2.zero(), Vector2(8, 64));

/// Every M6 room is lever-gated: the mechanism opens `leverGate`, the room is
/// solved only once `goalSwitch` is pulled.
void main() {
  test('sokoban: all plates open the lever gate (live); the lever solves', () {
    final a = plate();
    final b = plate();
    final gateL = gate();
    final goal = lever('goalSwitch');
    final puzzle = SokobanPuzzle()
      ..onLoad(FakeRoom(
          {'a': a, 'b': b, 'leverGate': gateL, 'goalSwitch': goal}));

    a.pressed = true;
    puzzle.onUpdate(0.016);
    expect(gateL.open, isFalse, reason: 'one plate is not enough');
    expect(puzzle.isSolved, isFalse);

    b.pressed = true;
    puzzle.onUpdate(0.016);
    expect(gateL.open, isTrue, reason: 'both plates open the way to the lever');
    expect(puzzle.isSolved, isFalse, reason: 'the mechanism alone never solves');

    a.pressed = false; // LIVE gate: lift a plate and the portcullis drops
    puzzle.onUpdate(0.016);
    expect(gateL.open, isFalse, reason: 'live gate closes when a plate frees');

    a.pressed = true; // press it again — the way reopens
    puzzle.onUpdate(0.016);
    expect(gateL.open, isTrue);

    goal.on = true; // pull the goal lever
    expect(puzzle.isSolved, isTrue);

    // Anti-soft-lock: solved overrides the mechanism — lift a plate now and the
    // portcullis STAYS up, so the player can retrace and isn't trapped.
    a.pressed = false;
    b.pressed = false;
    puzzle.onUpdate(0.016);
    expect(gateL.open, isTrue, reason: 'solved gate stays open for retracing');
  });

  test('splitter: both sensors open the lever gate; the lever solves', () {
    final s1 = sensor('s1');
    final s2 = sensor('s2');
    final gateL = gate();
    final goal = lever('goalSwitch');
    final puzzle = SplitterPuzzle()
      ..onLoad(FakeRoom(
          {'s1': s1, 's2': s2, 'leverGate': gateL, 'goalSwitch': goal}));

    s1.lit = true;
    puzzle.onUpdate(0.016);
    expect(gateL.open, isFalse);
    expect(puzzle.isSolved, isFalse);

    s2.lit = true;
    puzzle.onUpdate(0.016);
    expect(gateL.open, isTrue);
    expect(puzzle.isSolved, isFalse);

    goal.on = true;
    expect(puzzle.isSolved, isTrue);
  });

  test('sequence: right order opens the gate; wrong flip resets; lever solves',
      () {
    final l1 = lever('lev1');
    final l2 = lever('lev2');
    final l3 = lever('lev3');
    final gateL = gate();
    final goal = lever('goalSwitch');
    final room = FakeRoom({
      'lev1': l1,
      'lev2': l2,
      'lev3': l3,
      'leverGate': gateL,
      'goalSwitch': goal,
    });
    final puzzle = SequencePuzzle()..onLoad(room);

    l1.on = true;
    puzzle.onInteract('lev1');
    l3.on = true;
    puzzle.onInteract('lev3'); // wrong — expected lev2
    expect(room.errors, ['lev3']);
    expect(l1.on, isFalse); // everything reset
    expect(l3.on, isFalse);
    puzzle.onUpdate(0.016);
    expect(gateL.open, isFalse);
    expect(puzzle.isSolved, isFalse);

    puzzle.onInteract('lev1');
    puzzle.onInteract('lev2');
    puzzle.onInteract('lev3');
    puzzle.onUpdate(0.016);
    expect(gateL.open, isTrue, reason: 'the sequence opens the way to the lever');
    expect(puzzle.isSolved, isFalse, reason: 'still need to pull the lever');

    goal.on = true;
    expect(puzzle.isSolved, isTrue);
  });
}
