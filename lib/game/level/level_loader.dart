import 'dart:ui';

import 'package:flame/components.dart';

import '../components/door.dart';
import '../components/floor.dart';
import '../components/gate.dart';
import '../components/lever.dart';
import '../components/optics.dart';
import '../components/pressure_plate.dart';
import '../components/pushable_block.dart';
import '../components/sign.dart';
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
    final sources = <LightSource>[];
    final mirrors = <Mirror>[];
    final sensors = <LightSensor>[];

    for (final e in data.entities) {
      final pos = Vector2(e.x * t, e.y * t);
      final size = Vector2(e.w * t, e.h * t);
      final component = switch (e.type) {
        'floor' => Floor(pos, size),
        'wall' => Wall(pos, size),
        'spike_pit' => SpikeStrip(pos, size.x),
        'warning_sign' => WarningSign(pos, glyph: _glyph(e.props['glyph'])),
        'sign' => Sign(pos, size, glyph: _glyph(e.props['glyph'])),
        'door' => Door(
            pos,
            size,
            exitName: e.props['exit'] as String? ?? 'back',
            lockedByRule: e.props['locked'] as bool? ?? false,
            opensOnSolve: e.props['opensOnSolve'] as bool? ?? false,
            glyph:
                e.props['glyph'] != null ? _glyph(e.props['glyph']) : null,
          ),
        'lever' => Lever(
            pos,
            size,
            entityId: e.id ?? 'lever',
            startsOn: e.props['startsOn'] as bool? ?? false,
          ),
        'pushable_block' => PushableBlock(pos, size),
        'pressure_plate' => PressurePlate(pos, size),
        'gate' => Gate(pos, size),
        'light_source' => LightSource(pos, size,
            dir: e.props['dir'] as String? ?? 'east'),
        'mirror' => Mirror(
            pos,
            size,
            entityId: e.id ?? 'mirror',
            state: e.props['start'] as String? ?? '/',
            rotatable: e.props['rotatable'] as bool? ?? true,
          ),
        'crank' => Crank(
            pos,
            size,
            targetId: e.props['target'] as String? ??
                (throw FormatException('${data.id}: crank needs a target')),
            hideChain: e.props['hideChain'] as bool? ?? false,
          ),
        'light_sensor' => LightSensor(pos, size, entityId: e.id ?? 'sensor'),
        _ => throw FormatException(
            '${data.id}: unknown entity type "${e.type}"'),
      };
      if (e.id != null) _byId[e.id!] = component;
      switch (component) {
        case LightSource():
          sources.add(component);
        case Mirror():
          mirrors.add(component);
        case LightSensor():
          sensors.add(component);
        default:
      }
      add(component);
    }

    if (sources.isNotEmpty) {
      add(OpticsSystem(
        sources: sources,
        mirrors: mirrors,
        sensors: sensors,
        roomSize: size,
      ));
    }

    // Every node gets a brick ceiling — THIN in rooms (a hall with a roof),
    // MASSIVE in corridors (a tunnel at half room height) — so the two can
    // never be confused (GDD §4 corridor identity) while all masonry stays
    // consistent. Thickness rule shared with the path checker.
    add(Wall(
      Vector2(t * 0.5, t * 0.5),
      Vector2(size.x - t, t * synthesizedCeilingTiles(data.type)),
    ));

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
        'd_mechanics' => SymbolId.dMechanics,
        'd_optics' => SymbolId.dOptics,
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
