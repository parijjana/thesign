import 'dart:ui';

import 'package:flame/components.dart';

import '../components/door.dart';
import '../components/floor.dart';
import '../components/lever.dart';
import '../components/spike_strip.dart';
import '../components/wall.dart';
import '../components/warning_sign.dart';
import '../config.dart';
import '../escape_game.dart';
import '../puzzles/puzzle_registry.dart';
import '../puzzles/puzzle_script.dart';
import '../ui/symbols.dart';
import 'level_model.dart';

/// Builds a node (room/corridor/hub) from its [LevelData]: background +
/// border + one component per entity, and attaches the named PuzzleScript
/// (ARCHITECTURE.md §5.5).
class RoomComponent extends PositionComponent
    with HasGameReference<EscapeGame>
    implements PuzzleRoom {
  RoomComponent(this.data)
      : super(
          position: Vector2.zero(),
          size: Vector2(data.widthTiles * Config.tileSize,
              data.heightTiles * Config.tileSize),
          priority: -10, // the room subtree always draws under player & claw
        );

  final LevelData data;
  final Map<String, Component> _byId = {};
  PuzzleScript? puzzle;

  @override
  T? byId<T>(String id) {
    final c = _byId[id];
    return c is T ? c as T : null;
  }

  @override
  void onLoad() {
    const t = Config.tileSize;
    for (final e in data.entities) {
      final pos = Vector2(e.x * t, e.y * t);
      final size = Vector2(e.w * t, e.h * t);
      final component = switch (e.type) {
        'floor' => Floor(pos, size),
        'wall' => Wall(pos, size),
        'spike_pit' => SpikeStrip(pos, size.x),
        'warning_sign' => WarningSign(pos, glyph: _glyph(e.props['glyph'])),
        'door' => Door(
            pos,
            size,
            exitName: e.props['exit'] as String? ?? 'back',
            lockedByRule: e.props['locked'] as bool? ?? false,
          ),
        'lever' => Lever(
            pos,
            size,
            entityId: e.id ?? 'lever',
            startsOn: e.props['startsOn'] as bool? ?? false,
          ),
        _ => throw FormatException(
            '${data.id}: unknown entity type "${e.type}"'),
      };
      if (e.id != null) _byId[e.id!] = component;
      add(component);
    }

    final puzzleId = data.puzzle;
    if (puzzleId != null) {
      final factory = puzzleRegistry[puzzleId] ??
          (throw FormatException('${data.id}: unknown puzzle "$puzzleId"'));
      puzzle = factory();
    }
  }

  @override
  void onMount() {
    super.onMount();
    // Children are mounted now — scripts can resolve entities by id.
    puzzle?.onLoad(this);
  }

  @override
  void update(double dt) => puzzle?.onUpdate(dt);

  static SymbolId _glyph(Object? id) => switch (id) {
        'hazard' || null => SymbolId.hazard,
        final other => throw FormatException('unknown sign glyph "$other"'),
      };

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    canvas.drawRect(size.toRect(), Paint()..color = p.bg);
    canvas.drawRect(
      size.toRect().deflate(Config.strokeHeavy / 2),
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.strokeHeavy
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
