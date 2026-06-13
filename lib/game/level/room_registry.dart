import 'dart:convert';

import 'package:flame/cache.dart';

import 'level_model.dart';

/// Loads and caches the world graph + node files from `assets/levels/`
/// (ARCHITECTURE.md §5.5).
class RoomRegistry {
  RoomRegistry(this.world);

  final WorldData world;
  final Map<String, LevelData> _levelCache = {};

  static Future<RoomRegistry> load(AssetsCache assets) async {
    final raw = await assets.readFile('levels/world.json');
    return RoomRegistry(
      WorldData.fromJson(jsonDecode(raw) as Map<String, dynamic>),
    );
  }

  NodeData node(String id) => world.node(id);

  Transition? resolve(String sourceId, String exitName) =>
      world.resolve(sourceId, exitName);

  /// Does the door from [sourceId] via [exitName] open only on the adjoining
  /// room's solve? (Direction of travel — see WorldData.isSolveGated.)
  bool isSolveGated(String sourceId, String exitName) =>
      world.isSolveGated(sourceId, exitName);

  /// Which room's solve opens that door (null = always open).
  String? gatingRoomId(String sourceId, String exitName) =>
      world.gatingRoomId(sourceId, exitName);

  Future<LevelData> level(String nodeId, AssetsCache assets) async {
    final cached = _levelCache[nodeId];
    if (cached != null) return cached;
    final raw = await assets.readFile('levels/${node(nodeId).file}');
    final data = LevelData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (data.id != nodeId) {
      throw FormatException(
          'level file ${node(nodeId).file} declares id "${data.id}", '
          'expected "$nodeId"');
    }
    return _levelCache[nodeId] = data;
  }
}
