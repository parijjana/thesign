import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/aabb.dart';
import '../core/beam_tracer.dart';
import '../core/interactable.dart';
import '../escape_game.dart';

/// Optics entities + the beam system (docs/examples/room-optics-mirror.md).

/// Emits a beam along [dir] ('east'/'west'/'north'/'south').
class LightSource extends PositionComponent with HasGameReference<EscapeGame> {
  LightSource(Vector2 position, Vector2 size, {required this.dir})
      : super(position: position, size: size);

  final String dir;

  (int, int) get dirVec => switch (dir) {
        'east' => (1, 0),
        'west' => (-1, 0),
        'north' => (0, -1),
        'south' => (0, 1),
        final d => throw FormatException('bad light_source dir "$d"'),
      };

  Vector2 get emitPoint => Vector2(
        position.x + size.x / 2,
        position.y + size.y / 2,
      );

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final c = Offset(size.x / 2, size.y / 2);
    // Housing.
    final r = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6));
    canvas.drawRRect(r, Paint()..color = p.surface);
    canvas.drawRRect(
      r,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    // Sun: bright disc + rays.
    canvas.drawCircle(c, size.x * 0.2, Paint()..color = p.beam);
    final ray = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * size.x * 0.26, c + d * size.x * 0.36, ray);
    }
  }
}

/// A rotatable 45° mirror: interact cycles `/` ↔ `\`.
class Mirror extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Interactable {
  Mirror(Vector2 position, Vector2 size,
      {required this.entityId, required this.state, this.rotatable = true})
      : super(position: position, size: size);

  final String entityId;
  final bool rotatable;
  String state; // '/' or '\'

  Aabb get aabb => Aabb(position.x, position.y, size.x, size.y);

  @override
  Aabb get interactZone =>
      Aabb(position.x - 10, position.y - 10, size.x + 20, size.y + 20);

  @override
  bool get canInteract => rotatable && !game.player.isCarrying;

  @override
  void onInteract() {
    state = state == '/' ? r'\' : '/';
    game.roomPuzzle?.onInteract(entityId);
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    // Stand frame.
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(5)),
      Paint()
        ..color = p.accentNeutral.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
    // The mirror face: a heavy diagonal.
    final face = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final inset = size.x * 0.18;
    if (state == '/') {
      canvas.drawLine(Offset(inset, size.y - inset),
          Offset(size.x - inset, inset), face);
    } else {
      canvas.drawLine(
          Offset(inset, inset), Offset(size.x - inset, size.y - inset), face);
    }
  }
}

/// Lights up when a beam lands on it; the room's win condition reads [lit].
class LightSensor extends PositionComponent with HasGameReference<EscapeGame> {
  LightSensor(Vector2 position, Vector2 size, {required this.entityId})
      : super(position: position, size: size);

  final String entityId;
  bool lit = false;

  Aabb get aabb => Aabb(position.x, position.y, size.x, size.y);

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final c = Offset(size.x / 2, size.y / 2);
    // Bullseye: outer ring always; core bright when lit.
    canvas.drawCircle(
      c,
      size.x * 0.42,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      c,
      size.x * 0.24,
      Paint()..color = lit ? p.accentGoal : p.surface,
    );
    if (lit) {
      canvas.drawCircle(
        c,
        size.x * 0.32,
        Paint()
          ..color = p.beam
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }
  }
}

/// Traces every source's beam each frame against the room's solids, mirrors,
/// and sensors; renders the beam; sets sensors lit.
class OpticsSystem extends PositionComponent with HasGameReference<EscapeGame> {
  OpticsSystem({
    required this.sources,
    required this.mirrors,
    required this.sensors,
    required this.roomSize,
  }) : super(priority: 5); // beams draw over geometry, under the player

  final List<LightSource> sources;
  final List<Mirror> mirrors;
  final List<LightSensor> sensors;
  final Vector2 roomSize;

  final List<BeamSegment> _segments = [];

  @override
  void update(double dt) {
    _segments.clear();
    for (final s in sensors) {
      s.lit = false;
    }
    final obstacles = <BeamObstacle>[
      for (final s in game.collisionWorld.solids) BeamObstacle.solid(s),
      for (final m in mirrors) BeamObstacle.mirror(m.aabb, m.state),
      for (final s in sensors) BeamObstacle.sensor(s.aabb, s.entityId),
    ];
    for (final source in sources) {
      final (dx, dy) = source.dirVec;
      final origin = source.emitPoint;
      final result = traceBeam(
        ox: origin.x,
        oy: origin.y,
        dx: dx,
        dy: dy,
        obstacles: obstacles,
        boundsW: roomSize.x,
        boundsH: roomSize.y,
      );
      _segments.addAll(result.segments);
      for (final s in sensors) {
        if (result.litSensors.contains(s.entityId)) s.lit = true;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final beam = Paint()
      ..color = p.beam
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final spark = Paint()..color = p.beam;
    for (var i = 0; i < _segments.length; i++) {
      final s = _segments[i];
      canvas.drawLine(Offset(s.x1, s.y1), Offset(s.x2, s.y2), beam);
      // Spark mark at each bend (every segment start after the first).
      if (i > 0) canvas.drawCircle(Offset(s.x1, s.y1), 5, spark);
    }
  }
}
