import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesign/game/components/gate.dart';
import 'package:thesign/game/components/lever.dart';
import 'package:thesign/game/components/optics.dart';
import 'package:thesign/game/components/pressure_plate.dart';
import 'package:thesign/game/config.dart';
import 'package:thesign/game/level/level_model.dart';
import 'package:thesign/game/level/puzzle_entity_builder.dart';
import 'package:thesign/game/puzzles/puzzle_registry.dart';
import 'package:thesign/game/puzzles/puzzle_script.dart';

/// LEVEL-WIRING TEST — the guard that would have caught the `goalSwitch` bug.
///
/// WHY: the per-puzzle unit tests prove a script's LOGIC against a hand-built
/// fake room; nothing proved that each REAL level actually contains the
/// entities its script resolves. This loads every shipped level that declares
/// a puzzle, builds its puzzle entities through the SAME shared builder the
/// game uses ([buildPuzzleEntity]), and asserts the script:
///   (1) resolves what it needs in onLoad (a missing/mis-named/mis-typed
///       entity throws here, at `flutter test` time, not in play), and
///   (2) starts UNSOLVED and can be driven to SOLVED by satisfying its
///       entities — so a script that can never report solved is caught too.
///
/// EXTENDING — when you add a new puzzle type:
///   • If it's solved by "satisfy every entity" (levers on, plates pressed,
///     sensors lit, gates open), it needs NO change here — [_driveToSolved]
///     already handles it.
///   • If it needs a specific interaction sequence (like the pip-order room),
///     add a `case` to [_driveToSolved] that drives it the right way.
///   • If it queries a NEW entity type by id, add that type to
///     [buildPuzzleEntity] (see its doc) so this test can build it.
void main() {
  final world = WorldData.fromJson(
    jsonDecode(File('assets/levels/world.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  for (final node in world.nodes.values) {
    final level = LevelData.fromJson(
      jsonDecode(File('assets/levels/${node.file}').readAsStringSync())
          as Map<String, dynamic>,
    );
    final puzzleId = level.puzzle;
    if (puzzleId == null) continue;

    test('${level.code} (${node.id}) — puzzle "$puzzleId" is wired & solvable',
        () {
      final factory = puzzleRegistry[puzzleId];
      expect(factory, isNotNull,
          reason: '${node.id}: puzzle "$puzzleId" is not in the registry');

      final room = _WiringRoom.fromLevel(level);
      final script = factory!();

      // (1) Resolves its entities (asserts inside onLoad fire here on a
      //     missing/mis-named/mis-typed entity — e.g. the goalSwitch bug).
      script.onLoad(room);

      // (2a) A fresh room must not start already solved.
      expect(script.isSolved, isFalse,
          reason: '${node.id}: puzzle reports solved before anything is done');

      // (2b) Satisfying its entities must drive it to solved — proving the
      //      script can actually open the door.
      _driveToSolved(puzzleId, script, room);
      for (var i = 0; i < 6; i++) {
        script.onUpdate(1 / 60);
      }
      expect(script.isSolved, isTrue,
          reason: '${node.id}: puzzle never reports solved even when every '
              'entity is satisfied — it can never open the exit');
    });
  }
}

/// Drives a puzzle to its solved state by manipulating its entities. Generic
/// "satisfy everything" covers most puzzles; sequence-style puzzles get a case.
void _driveToSolved(String puzzleId, PuzzleScript script, _WiringRoom room) {
  switch (puzzleId) {
    case 'p_sequence':
      // Pull the levers in the script's expected order.
      for (final id in const ['lev1', 'lev2', 'lev3']) {
        room.byId<Lever>(id)?.on = true;
        script.onInteract(id);
      }
    default:
      for (final l in room.allOf<Lever>()) {
        l.on = true;
      }
      for (final p in room.allOf<PressurePlate>()) {
        p.pressed = true;
      }
      for (final s in room.allOf<LightSensor>()) {
        s.lit = true;
      }
      for (final g in room.allOf<Gate>()) {
        g.open = true;
      }
  }
}

/// A headless room: real puzzle entities built from level data, indexed by id.
class _WiringRoom implements PuzzleRoom {
  final Map<String, Component> _byId = {};
  final List<Component> _all = [];

  _WiringRoom();

  factory _WiringRoom.fromLevel(LevelData level) {
    final room = _WiringRoom();
    for (final e in level.entities) {
      final c = buildPuzzleEntity(e, Config.tileSize);
      if (c == null) continue;
      room._all.add(c);
      if (e.id != null) room._byId[e.id!] = c;
    }
    return room;
  }

  @override
  T? byId<T>(String id) {
    final c = _byId[id];
    if (c is T) return c as T;
    return null;
  }

  @override
  List<T> allOf<T>() => _all.whereType<T>().toList();

  @override
  void emitError(String entityId) {}

  @override
  void emitSuccess(String entityId) {}
}
