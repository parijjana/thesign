import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesign/game/components/lever.dart';
import 'package:thesign/game/puzzles/puzzle_script.dart';
import 'package:thesign/game/puzzles/stub_switch.dart';

/// Headless fake room: the script never knows it isn't in a real game.
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
  group('StubSwitchPuzzle (headless)', () {
    test('solves when the switch lever flips on', () {
      final lever = Lever(Vector2.zero(), Vector2.all(32),
          entityId: 'switch', startsOn: false);
      final puzzle = StubSwitchPuzzle()..onLoad(FakeRoom({'switch': lever}));

      expect(puzzle.isSolved, isFalse);
      lever.on = true;
      expect(puzzle.isSolved, isTrue);
    });

    test('a pre-flipped lever counts as already solved', () {
      final lever = Lever(Vector2.zero(), Vector2.all(32),
          entityId: 'switch', startsOn: true);
      final puzzle = StubSwitchPuzzle()..onLoad(FakeRoom({'switch': lever}));
      expect(puzzle.isSolved, isTrue);
    });

    // Regression: RFU/RCO name their lever "goalSwitch", not "switch" — the
    // door must still open (the old code only looked for id "switch").
    test('resolves a goal lever by any id (goalSwitch / first lever)', () {
      final lever = Lever(Vector2.zero(), Vector2.all(32),
          entityId: 'goalSwitch', startsOn: false);
      final puzzle =
          StubSwitchPuzzle()..onLoad(FakeRoom({'goalSwitch': lever}));
      expect(puzzle.isSolved, isFalse);
      lever.on = true;
      expect(puzzle.isSolved, isTrue);
    });
  });
}
