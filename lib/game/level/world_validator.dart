/// THE NO-SOFT-LOCK VALIDATOR (GDD §4 kindness law, spec: docs/MAZE.md §3).
///
/// A player who can never solve some puzzle room must still be able to reach
/// every other node of the castle — i.e. **no puzzle room may be a cut
/// vertex** of the world graph. Locks are ignored on purpose: a lock is
/// solve-state, not topology; what we guard is that *some* route always
/// exists for a player to whom one room is forever unsolvable.
///
/// Runs in `flutter test` over the real world.json. `allowedGates` lists the
/// deliberately gated nodes (the final-exit region) that MAY depend on a
/// single room.
library;

import 'level_model.dart';

/// Human-readable violations; empty = the world is kind.
List<String> findKindnessViolations(
  WorldData world, {
  Set<String> allowedGates = const {},
}) {
  final adjacency = _buildAdjacency(world);
  final violations = <String>[];

  // Rule 1: the whole castle is reachable at all.
  final all = _reach(adjacency, world.start);
  final unreachable =
      world.nodes.keys.toSet().difference(all)..removeAll(allowedGates);
  if (unreachable.isNotEmpty) {
    violations.add(
        'world is not connected — unreachable from ${world.start}: '
        '${(unreachable.toList()..sort()).join(', ')}');
  }

  // Rule 2: no puzzle room is a cut vertex.
  for (final node in world.nodes.values) {
    if (node.type != NodeType.room) continue;
    if (node.id == world.start) continue;
    final without = _reach(adjacency, world.start, without: node.id);
    final stranded = all.difference(without)
      ..remove(node.id)
      ..removeAll(allowedGates);
    if (stranded.isNotEmpty) {
      violations.add(
          '${node.id} is a cut vertex — a player who can never solve it is '
          'locked out of: ${(stranded.toList()..sort()).join(', ')}');
    }
  }
  return violations;
}

/// DIRECTION-OF-TRAVEL VALIDATOR (the fix for "entered via the closed door
/// and got stuck"): every room must declare a valid entry side, the graph
/// must be symmetric (every exit has a reverse), and a room's entry neighbor
/// must itself be reachable without solving that room (else you could never
/// legitimately enter).
List<String> findDirectionViolations(WorldData world) {
  final v = <String>[];
  final adjacency = _buildAdjacency(world);

  for (final n in world.nodes.values) {
    // Graph symmetry: a door must exist on both ends of every connection.
    for (final e in n.exits.entries) {
      final target = world.nodes[e.value];
      if (target == null) {
        v.add('${n.id}: exit "${e.key}" points at unknown node "${e.value}"');
        continue;
      }
      if (!target.exits.values.contains(n.id)) {
        v.add('${n.id} → ${e.value} ("${e.key}") has no return door — '
            'one-way connections trap the player');
      }
    }

    if (n.type != NodeType.room) continue;

    if (n.entries.isEmpty) {
      v.add('${n.id}: room declares no entry side (add "entry" to world.json)');
      continue;
    }
    for (final entry in n.entries) {
      if (!n.exits.containsKey(entry)) {
        v.add('${n.id}: entry "$entry" is not one of its exits');
        continue;
      }
      // You must be able to reach the entry neighbour without solving THIS
      // room (the whole point of an entry side).
      final neighbour = n.exits[entry]!;
      final reachable = _reach(adjacency, world.start, without: n.id);
      if (!reachable.contains(neighbour)) {
        v.add('${n.id}: its entry neighbour "$neighbour" is unreachable '
            'without solving ${n.id} — the entry is a trap');
      }
    }
  }
  return v;
}

/// CORRIDOR-LIVENESS VALIDATOR: every corridor and plaza must offer at least
/// one ALWAYS-OPEN door (to another corridor/hub, or into a room via that
/// room's entry side) besides being a dead end — so however the player
/// arrives, there is always an open way onward (their entry door + this one
/// = ≥2 open). Secret doors don't count (they're hidden bonus).
List<String> findCorridorLivenessViolations(WorldData world) {
  final v = <String>[];
  for (final n in world.nodes.values) {
    if (n.type == NodeType.room) continue;
    var total = 0;
    var alwaysOpen = 0;
    for (final e in n.exits.entries) {
      if (_isSecretExit(world, e.key, e.value)) continue;
      total++;
      if (!world.isSolveGated(n.id, e.key)) alwaysOpen++;
    }
    if (total < 2) {
      v.add('${n.id}: only $total non-secret door(s) — a dead-end corridor');
    }
    if (alwaysOpen < 1) {
      v.add('${n.id}: every door is puzzle-locked — the player could arrive '
          'and have no open way onward');
    }
  }
  return v;
}

bool _isSecretExit(WorldData world, String exitName, String target) =>
    exitName == 'secret' || target.startsWith('secret_');

Map<String, Set<String>> _buildAdjacency(WorldData world) {
  final adjacency = <String, Set<String>>{};
  void link(String a, String b) {
    adjacency.putIfAbsent(a, () => <String>{}).add(b);
    adjacency.putIfAbsent(b, () => <String>{}).add(a);
  }

  for (final node in world.nodes.values) {
    adjacency.putIfAbsent(node.id, () => <String>{});
    for (final target in node.exits.values) {
      link(node.id, target);
    }
    // Legacy hub conventions (rooms list / parent) count as connections too.
    for (final room in node.rooms) {
      link(node.id, room);
    }
    final parent = node.parent;
    if (parent != null) link(node.id, parent);
  }
  return adjacency;
}

Set<String> _reach(
  Map<String, Set<String>> adjacency,
  String start, {
  String? without,
}) {
  if (start == without) return {};
  final seen = <String>{start};
  final stack = <String>[start];
  while (stack.isNotEmpty) {
    final current = stack.removeLast();
    for (final neighbor in adjacency[current] ?? const <String>{}) {
      if (neighbor == without || seen.contains(neighbor)) continue;
      seen.add(neighbor);
      stack.add(neighbor);
    }
  }
  return seen;
}
