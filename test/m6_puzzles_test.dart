import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
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
Lever lever(String id) =>
    Lever(Vector2.zero(), Vector2.all(32), entityId: id);
LightSensor sensor(String id) =>
    LightSensor(Vector2.zero(), Vector2.all(32), entityId: id);

void main() {
  test('sokoban: solved only when ALL plates pressed (latched)', () {
    final a = plate();
    final b = plate();
    final puzzle = SokobanPuzzle()..onLoad(FakeRoom({'a': a, 'b': b}));
    a.pressed = true;
    puzzle.onUpdate(0.016);
    expect(puzzle.isSolved, isFalse);
    b.pressed = true;
    puzzle.onUpdate(0.016);
    expect(puzzle.isSolved, isTrue);
    a.pressed = false; // latched
    puzzle.onUpdate(0.016);
    expect(puzzle.isSolved, isTrue);
  });

  test('splitter: both sensors must be lit at once', () {
    final s1 = sensor('s1');
    final s2 = sensor('s2');
    final puzzle = SplitterPuzzle()..onLoad(FakeRoom({'s1': s1, 's2': s2}));
    s1.lit = true;
    puzzle.onUpdate(0.016);
    expect(puzzle.isSolved, isFalse);
    s2.lit = true;
    puzzle.onUpdate(0.016);
    expect(puzzle.isSolved, isTrue);
  });

  test('sequence: right order solves; wrong flip resets all levers', () {
    final l1 = lever('lev1');
    final l2 = lever('lev2');
    final l3 = lever('lev3');
    final room = FakeRoom({'lev1': l1, 'lev2': l2, 'lev3': l3});
    final puzzle = SequencePuzzle()..onLoad(room);

    l1.on = true;
    puzzle.onInteract('lev1');
    l3.on = true;
    puzzle.onInteract('lev3'); // wrong — expected lev2
    expect(room.errors, ['lev3']);
    expect(l1.on, isFalse); // everything reset
    expect(l3.on, isFalse);
    expect(puzzle.isSolved, isFalse);

    puzzle.onInteract('lev1');
    puzzle.onInteract('lev2');
    puzzle.onInteract('lev3');
    expect(puzzle.isSolved, isTrue);
  });
}
