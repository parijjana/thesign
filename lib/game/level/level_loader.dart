import 'dart:ui';

import 'package:flame/components.dart';

import '../components/boulder.dart';
import '../components/counter_lift.dart';
import '../components/door.dart';
import '../components/etching.dart';
import '../components/floor.dart';
import '../components/gate.dart';
import '../components/lever.dart';
import '../components/moving_platform.dart';
import '../components/optics.dart';
import '../components/pressure_plate.dart';
import '../components/pushable_block.dart';
import '../components/seesaw.dart';
import '../components/sign.dart';
import '../components/wall.dart';
import '../components/water_pool.dart';
import '../components/warning_sign.dart';
import '../config.dart';
import '../core/aabb.dart';
import '../escape_game.dart';
import '../puzzles/puzzle_registry.dart';
import '../puzzles/puzzle_script.dart';
import '../ui/feedback_popups.dart';
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
  List<T> allOf<T>() => children.whereType<T>().toList();

  void _emitAt(String entityId, FeedbackKind kind) {
    final c = _byId[entityId];
    if (c is! PositionComponent) return;
    game.feedback.emit(
        kind, Vector2(c.position.x + c.size.x / 2, c.position.y - 14));
  }

  @override
  void emitError(String entityId) => _emitAt(entityId, FeedbackKind.error);

  @override
  void emitSuccess(String entityId) => _emitAt(entityId, FeedbackKind.success);

  @override
  void onLoad() {
    const t = Config.tileSize;
    final sources = <LightSource>[];
    final mirrors = <Mirror>[];
    final sensors = <LightSensor>[];
    final splitters = <Splitter>[];

    for (final e in data.entities) {
      final pos = Vector2(e.x * t, e.y * t);
      final size = Vector2(e.w * t, e.h * t);
      final component = switch (e.type) {
        'floor' => Floor(pos, size),
        'wall' => Wall(pos, size),
        'water' => WaterPool(pos, size),
        'warning_sign' => WarningSign(pos, glyph: _glyph(e.props['glyph'])),
        'sign' => Sign(
            pos,
            size,
            glyph:
                e.props['glyph'] != null ? _glyph(e.props['glyph']) : null,
            pips: (e.props['pips'] as num?)?.toInt() ?? 0,
          ),
        'door' => Door(
            pos,
            size,
            exitName: e.props['exit'] as String? ?? 'back',
            lockedByRule: e.props['locked'] as bool? ?? false,
            opensOnSolve: e.props['opensOnSolve'] as bool? ?? false,
            secret: e.props['secret'] as bool? ?? false,
            glyph:
                e.props['glyph'] != null ? _glyph(e.props['glyph']) : null,
          ),
        'moving_platform' => MovingPlatform(
            pos,
            size,
            path: [
              for (final p in e.props['path'] as List)
                Vector2(((p as Map)['x'] as num).toDouble() * t,
                    (p['y'] as num).toDouble() * t),
            ],
            speed: ((e.props['speed'] as num?) ?? 60).toDouble(),
          ),
        'boulder' => Boulder(
            Vector2(pos.x + size.x / 2, pos.y + size.y / 2),
            radius: size.x / 2,
          ),
        'seesaw' => Seesaw(
            Vector2(pos.x + size.x / 2, pos.y),
            armHalf: ((e.props['armHalf'] as num?) ?? 2.5).toDouble() * t,
            panWidth: ((e.props['panW'] as num?) ?? 1.5).toDouble() * t,
          ),
        'counter_lift' => CounterLift(
            pos,
            size,
            basket: Aabb(
              ((e.props['basketX'] as num).toDouble()) * t,
              ((e.props['basketY'] as num).toDouble()) * t,
              ((e.props['basketW'] as num?) ?? 2).toDouble() * t,
              ((e.props['basketH'] as num?) ?? 1).toDouble() * t,
            ),
          ),
        'beam_splitter' => Splitter(
            pos,
            size,
            state: e.props['state'] as String? ?? '/',
          ),
        'etching' => Etching(
            pos,
            size,
            etchingId: e.id ?? 'etching',
            glyph: _glyph(e.props['glyph']),
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
        case Splitter():
          splitters.add(component);
        default:
      }
      add(component);
    }

    if (sources.isNotEmpty) {
      add(OpticsSystem(
        sources: sources,
        mirrors: mirrors,
        sensors: sensors,
        splitters: splitters,
        roomSize: size,
      ));
    }

    // Every node gets a brick ceiling flush to the top edge — THIN in rooms
    // (a hall with a roof), MASSIVE in corridors (a tunnel at half room
    // height) — so the two can never be confused (GDD §4 corridor identity)
    // while all masonry stays consistent. No wasted margin: the shell
    // masonry meets the room border. Thickness shared with the path checker.
    add(Wall(
      Vector2.zero(),
      Vector2(size.x, t * synthesizedCeilingTiles(data.type)),
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
        'no_swimming' => SymbolId.noSwimming,
        'd_mechanics' => SymbolId.dMechanics,
        'd_optics' => SymbolId.dOptics,
        'd_gravity' => SymbolId.dGravity,
        'd_logic' => SymbolId.dLogic,
        'street_circle' => SymbolId.streetCircle,
        'street_triangle' => SymbolId.streetTriangle,
        'street_square' => SymbolId.streetSquare,
        'street_diamond' => SymbolId.streetDiamond,
        'street_star' => SymbolId.streetStar,
        'street_hex' => SymbolId.streetHex,
        'spawn' => SymbolId.spawn,
        'claw' => SymbolId.restartClaw,
        'hint' => SymbolId.hint,
        'unlocked' => SymbolId.unlocked,
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
