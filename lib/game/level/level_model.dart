/// Parsed level & world-graph data (LEVEL_FORMAT.md). Pure Dart — no Flame —
/// so parsing and graph resolution are headless-testable.
///
/// Malformed data fails loudly in dev (FormatException), never silently.
library;

// --- World graph (world.json) ------------------------------------------------

enum NodeType { corridor, hub, room, meadow }

/// Thickness (tiles) of the brick ceiling synthesized on every node, flush
/// from the very top edge: thin in rooms/hubs (a hall with a roof), massive
/// in corridors (a tunnel at half room height), NONE in the meadow (open sky —
/// the outdoor ending, GDD §3 twist). Shared by the loader AND the path checker
/// so they can never disagree about the playable space.
double synthesizedCeilingTiles(NodeType type) => switch (type) {
      NodeType.corridor => 6.0,
      NodeType.meadow => 0.0,
      _ => 1.5,
    };

class WorldData {
  WorldData({required this.version, required this.start, required this.nodes});

  final int version;
  final String start;
  final Map<String, NodeData> nodes;

  factory WorldData.fromJson(Map<String, dynamic> json) {
    final nodes = <String, NodeData>{};
    for (final n in json['nodes'] as List) {
      final node = NodeData.fromJson(n as Map<String, dynamic>);
      nodes[node.id] = node;
    }
    final start = json['start'] as String;
    if (!nodes.containsKey(start)) {
      throw FormatException('world.json: start node "$start" not in nodes');
    }
    return WorldData(
      version: json['version'] as int,
      start: start,
      nodes: nodes,
    );
  }

  NodeData node(String id) =>
      nodes[id] ?? (throw ArgumentError('unknown node "$id"'));

  /// The room's own exit-name that points back at [neighborId] (its "side"
  /// of that connection), or null if they don't connect.
  String? roomSideTo(NodeData room, String neighborId) {
    for (final e in room.exits.entries) {
      if (e.value == neighborId) return e.key;
    }
    return null;
  }

  /// THE direction-of-travel rule, single source of truth: which ROOM's
  /// solve opens the door from [fromNode] via [exitName] — or null if it's
  /// always open. A door is gated by whichever endpoint room has this side
  /// as its NON-entry (locked) side. Checking BOTH endpoints means the two
  /// sides can never disagree (the bug this kills), and it correctly handles
  /// a room↔room connection (e.g. the capstone/ascent → exit_hall doors).
  String? gatingRoomId(String fromNode, String exitName) {
    final transition = resolve(fromNode, exitName);
    if (transition == null) return null;
    final from = node(fromNode);
    if (from.type == NodeType.room && !from.entries.contains(exitName)) {
      return from.id;
    }
    final to = node(transition.targetId);
    if (to.type == NodeType.room) {
      final side = roomSideTo(to, fromNode);
      if (side != null && !to.entries.contains(side)) return to.id;
    }
    return null;
  }

  /// Is the door from [fromNode] via [exitName] shut until a room is solved?
  bool isSolveGated(String fromNode, String exitName) =>
      gatingRoomId(fromNode, exitName) != null;

  /// Resolves using [exitName] from [sourceId] → where you end up, and which
  /// of the target's entry points to appear at.
  ///
  /// Exit-name conventions (LEVEL_FORMAT.md §2):
  /// - a name in the node's `exits` map → that target;
  /// - `"back"` in a room → its parent hub;
  /// - a room id listed in a hub's `rooms` → that room.
  /// The entry key is the name that, in the TARGET, leads back to the source
  /// (so geometry authors place the player just inside the right door).
  Transition? resolve(String sourceId, String exitName) {
    final source = node(sourceId);
    String? targetId = source.exits[exitName];
    if (targetId == null && exitName == 'back') targetId = source.parent;
    if (targetId == null && source.rooms.contains(exitName)) {
      targetId = exitName;
    }
    if (targetId == null || !nodes.containsKey(targetId)) return null;

    final target = node(targetId);
    String? entryKey;
    for (final e in target.exits.entries) {
      if (e.value == sourceId) {
        entryKey = e.key;
        break;
      }
    }
    entryKey ??= target.parent == sourceId
        ? 'back'
        : (target.rooms.contains(sourceId) ? sourceId : null);
    return Transition(targetId, entryKey);
  }
}

class Transition {
  Transition(this.targetId, this.entryKey);

  final String targetId;

  /// Key into the target's `entryPoints`; null → use the target's `start`.
  final String? entryKey;
}

class NodeData {
  NodeData({
    required this.id,
    required this.type,
    required this.file,
    this.exits = const {},
    this.entries = const [],
    this.rooms = const [],
    this.parent,
    this.unlock,
  });

  final String id;
  final NodeType type;
  final String file;
  final Map<String, String> exits;

  /// ROOM nodes: which of [exits] are the ENTRY side(s) — always-open ways
  /// in. Every other exit is the puzzle-locked side (opensOnSolve, both
  /// directions). THE source of truth for direction of travel, enforced by
  /// the direction validator.
  final List<String> entries;

  final List<String> rooms;
  final String? parent;
  final UnlockRule? unlock;

  factory NodeData.fromJson(Map<String, dynamic> json) => NodeData(
        id: json['id'] as String,
        type: NodeType.values.byName(json['type'] as String),
        file: json['file'] as String,
        exits: (json['exits'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as String)),
        entries: switch (json['entry']) {
          final String s => [s],
          final List l => l.cast<String>(),
          _ => const [],
        },
        rooms: (json['rooms'] as List? ?? []).cast<String>(),
        parent: json['parent'] as String?,
        unlock: json['unlock'] == null
            ? null
            : UnlockRule.fromJson(json['unlock'] as Map<String, dynamic>),
      );
}

/// When does a hub's onward door open? (GDD §4 — default: any 1 room solved.)
class UnlockRule {
  UnlockRule.anyOf(this.count) : rule = 'anyOf', rooms = const [];

  UnlockRule.specific(this.rooms) : rule = 'specific', count = rooms.length;

  final String rule;
  final int count;
  final List<String> rooms;

  factory UnlockRule.fromJson(Map<String, dynamic> json) {
    return switch (json['rule'] as String) {
      'anyOf' => UnlockRule.anyOf(json['count'] as int? ?? 1),
      'specific' => UnlockRule.specific(
          (json['rooms'] as List).cast<String>()),
      final other => throw FormatException('unknown unlock rule "$other"'),
    };
  }

  bool isSatisfied(Set<String> solved, List<String> hubRooms) =>
      switch (rule) {
        'anyOf' => hubRooms.where(solved.contains).length >= count,
        'specific' => rooms.every(solved.contains),
        _ => false,
      };
}

// --- Node files (rooms, corridors, hubs) --------------------------------------

class TilePoint {
  const TilePoint(this.x, this.y);

  final double x;
  final double y;

  factory TilePoint.fromJson(Map<String, dynamic> json) => TilePoint(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      );
}

class LevelData {
  LevelData({
    required this.version,
    required this.id,
    required this.code,
    required this.type,
    required this.name,
    required this.widthTiles,
    required this.heightTiles,
    required this.palette,
    required this.puzzle,
    required this.entryPoints,
    required this.start,
    required this.entities,
    this.assumePowerups = const [],
  });

  final int version;
  final String id;

  /// Short unique code (stored in JSON) shown by the debug overlay so the
  /// user can quote a room precisely. Falls back to [id] if absent.
  final String code;

  final NodeType type;
  final String name; // dev-facing only — never rendered (no-text rule)
  final double widthTiles;
  final double heightTiles;
  final String palette;
  final String? puzzle;
  final Map<String, TilePoint> entryPoints;
  final TilePoint start;
  final List<EntityData> entities;

  /// Powerup ids the player is ASSUMED to hold for path-checking this level
  /// (docs/POWERUPS.md §3) — a powerup-gated room declares its kit so the
  /// checker verifies reachability the way it's meant to be played.
  final List<String> assumePowerups;

  factory LevelData.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as Map<String, dynamic>;
    return LevelData(
      version: json['version'] as int,
      id: json['id'] as String,
      code: json['code'] as String? ?? json['id'] as String,
      type: NodeType.values.byName(json['type'] as String),
      name: json['name'] as String? ?? '',
      widthTiles: (size['w'] as num).toDouble(),
      heightTiles: (size['h'] as num).toDouble(),
      palette: json['palette'] as String? ?? 'amber',
      puzzle: json['puzzle'] as String?,
      entryPoints: (json['entryPoints'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, TilePoint.fromJson(v as Map<String, dynamic>)),
      ),
      start: TilePoint.fromJson(json['start'] as Map<String, dynamic>),
      assumePowerups: (json['assume'] as List? ?? []).cast<String>(),
      entities: [
        for (final e in json['entities'] as List)
          EntityData.fromJson(e as Map<String, dynamic>),
      ],
    );
  }
}

class EntityData {
  EntityData({
    this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.props = const {},
  });

  final String? id;
  final String type;
  final double x, y, w, h; // in tiles
  final Map<String, dynamic> props;

  factory EntityData.fromJson(Map<String, dynamic> json) => EntityData(
        id: json['id'] as String?,
        type: json['type'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        w: (json['w'] as num? ?? 1).toDouble(),
        h: (json['h'] as num? ?? 1).toDouble(),
        props: json['props'] as Map<String, dynamic>? ?? const {},
      );
}
