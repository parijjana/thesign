import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thesign/game/level/level_model.dart';
import 'package:thesign/game/level/world_validator.dart';

/// THE KINDNESS GUARD (GDD §4, MAZE.md §3): the shipped world must never
/// contain a puzzle room whose failure locks a player out of anywhere else.
void main() {
  test('the real world.json obeys the kindness law', () {
    final world = WorldData.fromJson(
      jsonDecode(File('assets/levels/world.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    expect(findKindnessViolations(world), isEmpty);
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
