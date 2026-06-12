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
