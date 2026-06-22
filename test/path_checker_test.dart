import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thesign/game/level/level_model.dart';
import 'package:thesign/game/level/path_checker.dart';

/// THE LEVEL GUARD: every node in the real world.json must let the player
/// physically reach every door (LEVEL_FORMAT.md §6). A new level with a
/// dead end fails here before it can ever ship — no more unreachable doors.
void main() {
  final world = WorldData.fromJson(
    jsonDecode(File('assets/levels/world.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  for (final node in world.nodes.values) {
    test('every door in ${node.id} is reachable by the player', () {
      final level = LevelData.fromJson(
        jsonDecode(File('assets/levels/${node.file}').readAsStringSync())
            as Map<String, dynamic>,
      );
      final result = checkDoorReachability(level);
      expect(
        result.unreachableDoors,
        isEmpty,
        reason: '${node.id}: the player cannot reach door(s) '
            '${result.unreachableDoors} from the start point — '
            'fix the geometry (or the start) before shipping this level.',
      );
    });

    // No portal soft-locks: a reachable room must always let the player
    // activate its portal and reach it from every way in (the exit_hall trap).
    test('every portal in ${node.id} is a guaranteed way out', () {
      final level = LevelData.fromJson(
        jsonDecode(File('assets/levels/${node.file}').readAsStringSync())
            as Map<String, dynamic>,
      );
      final result = checkPortalSafety(level);
      expect(
        result.violations,
        isEmpty,
        reason: '${node.id}: ${result.violations.join('; ')}',
      );
    });
  }

  test('world start node exists and its level parses', () {
    expect(world.nodes.containsKey(world.start), isTrue);
  });
}
