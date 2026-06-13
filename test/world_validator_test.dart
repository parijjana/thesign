import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thesign/game/level/level_model.dart';
import 'package:thesign/game/level/world_validator.dart';

/// THE KINDNESS GUARD (GDD §4, MAZE.md §3): the shipped world must never
/// contain a puzzle room whose failure locks a player out of anywhere else.
void main() {
  WorldData realWorld() => WorldData.fromJson(
        jsonDecode(File('assets/levels/world.json').readAsStringSync())
            as Map<String, dynamic>,
      );

  test('the real world.json obeys the kindness law', () {
    expect(
      findKindnessViolations(realWorld(),
          allowedGates: {'exit_hall', 'secret_stack'}),
      isEmpty,
      reason: 'exit_hall sits behind the capstone (the one sanctioned gate); '
          'secret_stack is leaf bonus content inside its host room.',
    );
  });

  test('the real world.json obeys direction-of-travel rules', () {
    expect(findDirectionViolations(realWorld()), isEmpty);
  });

  test('every real corridor stays live (always an open way onward)', () {
    expect(findCorridorLivenessViolations(realWorld()), isEmpty);
  });

  test('a room with no entry declared is caught', () {
    final world = WorldData.fromJson({
      'version': 1,
      'start': 'cor_a',
      'nodes': [
        {'id': 'cor_a', 'type': 'corridor', 'file': 'a.json',
         'exits': {'east': 'room_x', 'west': 'cor_b'}},
        {'id': 'cor_b', 'type': 'corridor', 'file': 'b.json',
         'exits': {'east': 'cor_a'}},
        {'id': 'room_x', 'type': 'room', 'file': 'x.json',
         'exits': {'west': 'cor_a'}},
      ],
    });
    expect(findDirectionViolations(world).join(),
        contains('room_x: room declares no entry side'));
  });

  test('a one-way connection is caught', () {
    final world = WorldData.fromJson({
      'version': 1,
      'start': 'cor_a',
      'nodes': [
        {'id': 'cor_a', 'type': 'corridor', 'file': 'a.json',
         'exits': {'east': 'cor_b'}},
        {'id': 'cor_b', 'type': 'corridor', 'file': 'b.json',
         'exits': <String, String>{}},
      ],
    });
    expect(findDirectionViolations(world).join(), contains('no return door'));
  });

  test('a corridor whose every door is puzzle-locked is caught', () {
    // cor_trap only touches two rooms, both via their LOCKED (non-entry)
    // sides → you could land there with no open exit.
    final world = WorldData.fromJson({
      'version': 1,
      'start': 'cor_a',
      'nodes': [
        {'id': 'cor_a', 'type': 'corridor', 'file': 'a.json',
         'exits': {'r1': 'room_1', 'r2': 'room_2'}},
        {'id': 'cor_trap', 'type': 'corridor', 'file': 't.json',
         'exits': {'r1': 'room_1', 'r2': 'room_2'}},
        {'id': 'room_1', 'type': 'room', 'file': 'r1.json', 'entry': 'a',
         'exits': {'a': 'cor_a', 'b': 'cor_trap'}},
        {'id': 'room_2', 'type': 'room', 'file': 'r2.json', 'entry': 'a',
         'exits': {'a': 'cor_a', 'b': 'cor_trap'}},
      ],
    });
    expect(findCorridorLivenessViolations(world).join(),
        contains('cor_trap'));
  });

  test('a bottleneck room is caught and named', () {
    // corridor → ROOM (only passage) → far corridor: room_choke is a cut
    // vertex stranding corridor_far.
    final world = WorldData.fromJson({
      'version': 1,
      'start': 'corridor_a',
      'nodes': [
        {
          'id': 'corridor_a',
          'type': 'corridor',
          'file': 'a.json',
          'exits': {'east': 'room_choke'},
        },
        {
          'id': 'room_choke',
          'type': 'room',
          'file': 'choke.json',
          'exits': {'west': 'corridor_a', 'east': 'corridor_far'},
        },
        {
          'id': 'corridor_far',
          'type': 'corridor',
          'file': 'far.json',
          'exits': {'west': 'room_choke'},
        },
      ],
    });
    final violations = findKindnessViolations(world);
    expect(violations, hasLength(1));
    expect(violations.single, contains('room_choke'));
    expect(violations.single, contains('corridor_far'));
  });

  test('declared final gates are exempt', () {
    final world = WorldData.fromJson({
      'version': 1,
      'start': 'corridor_a',
      'nodes': [
        {
          'id': 'corridor_a',
          'type': 'corridor',
          'file': 'a.json',
          'exits': {'east': 'room_final'},
        },
        {
          'id': 'room_final',
          'type': 'room',
          'file': 'final.json',
          'exits': {'west': 'corridor_a', 'east': 'exit_hall'},
        },
        {
          'id': 'exit_hall',
          'type': 'room',
          'file': 'exit.json',
          'exits': {'west': 'room_final'},
        },
      ],
    });
    expect(
      findKindnessViolations(world, allowedGates: {'exit_hall'}),
      isEmpty,
    );
  });

  test('a disconnected node is reported', () {
    final world = WorldData.fromJson({
      'version': 1,
      'start': 'corridor_a',
      'nodes': [
        {
          'id': 'corridor_a',
          'type': 'corridor',
          'file': 'a.json',
          'exits': <String, String>{},
        },
        {
          'id': 'room_island',
          'type': 'room',
          'file': 'island.json',
          'exits': <String, String>{},
        },
      ],
    });
    final violations = findKindnessViolations(world);
    expect(violations.single, contains('room_island'));
  });
}
