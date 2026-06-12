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

/// A rotatable 45° mirror: toggling cycles `/` ↔ `\`.
///
/// Mirrors at player height may be `rotatable` (direct interact); elevated
/// mirrors are driven remotely by a [Crank] + chain — every control must be
/// operable from the ground or a platform (the player is not Superman).
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
  bool get promptHidden => false;

  @override
  bool get canInteract => rotatable && !game.player.isCarrying;

  @override
  void onInteract() => toggle();

  /// Flips the mirror (direct interact or a crank).
  void toggle() {
    state = state == '/' ? r'\' : '/';
    game.roomPuzzle?.onInteract(entityId);
  }

  @override
  void onMount() {
    super.onMount();
    game.interactables.add(this);
  }

  @override
  void onRemove() {
    game.interactables.remove(this);
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    // Mirror frame.
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

/// A fixed half-mirror: the beam passes through AND reflects — one source,
/// two outputs (the "two birds" room).
class Splitter extends PositionComponent with HasGameReference<EscapeGame> {
  Splitter(Vector2 position, Vector2 size, {this.state = '/'})
      : super(position: position, size: size);

  final String state;

  Aabb get aabb => Aabb(position.x, position.y, size.x, size.y);

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(5)),
      Paint()..color = p.accentNeutral.withValues(alpha: 0.35),
    );
    // Half-silvered: a dashed diagonal instead of the mirror's solid one.
    final face = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final inset = size.x * 0.18;
    final a = state == '/'
        ? Offset(inset, size.y - inset)
        : Offset(inset, inset);
    final b = state == '/'
        ? Offset(size.x - inset, inset)
        : Offset(size.x - inset, size.y - inset);
    final dir = (b - a) / (b - a).distance;
    for (var d = 0.0; d < (b - a).distance; d += 9) {
      canvas.drawLine(a + dir * d, a + dir * (d + 4.5), face);
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

/// A ground-level steering column that drives an elevated [Mirror] through a
/// chain: gear on a post at a fixed, kid-reachable height, authored standing
/// on a floor or platform. Interact = the target mirror rotates. The chain
/// is drawn by default; `hideChain` (later rooms) makes "which crank drives
/// which mirror" part of the puzzle.
class Crank extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Interactable {
  Crank(Vector2 position, Vector2 size,
      {required this.targetId, this.hideChain = false})
      : super(position: position, size: size);

  final String targetId;
  final bool hideChain;

  double _spin = 0;
  double _spinVel = 0;

  Mirror? get _target => game.roomEntity<Mirror>(targetId);

  @override
  Aabb get interactZone =>
      Aabb(position.x - 10, position.y - 10, size.x + 20, size.y + 20);

  @override
  bool get promptHidden => false;

  @override
  bool get canInteract => !game.player.isCarrying && _target != null;

  @override
  void onInteract() {
    _target?.toggle();
    _spinVel = 14; // satisfying gear whirl on use
  }

  @override
  void onMount() {
    super.onMount();
    game.interactables.add(this);
  }

  @override
  void onRemove() {
    game.interactables.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    _spin += _spinVel * dt;
    _spinVel *= math.pow(0.05, dt).toDouble(); // quick decay
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final stroke = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final cx = size.x / 2;
    final gearC = Offset(cx, size.x * 0.45); // gear near the top of the post
    final gearR = size.x * 0.34;

    // Chain LOOP up to the mirror: two parallel runs (drive + return),
    // like a real chain-and-sprocket drive — physics shown honestly.
    final target = _target;
    if (target != null && !hideChain) {
      final chain = Paint()
        ..color = p.ink.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      final from = gearC;
      final to = Offset(
        target.position.x + target.size.x / 2 - position.x,
        target.position.y + target.size.y / 2 - position.y,
      );
      final delta = to - from;
      final len = delta.distance;
      final dir = delta / len;
      final perp = Offset(-dir.dy, dir.dx) * 3.5;
      for (final side in const [-1.0, 1.0]) {
        // Dashed links: 5px dash, 5px gap, offset to either side of the axis.
        for (var d = gearR + 4; d < len - 8; d += 10) {
          canvas.drawLine(
            from + dir * d + perp * side,
            from + dir * (d + 5) + perp * side,
            chain,
          );
        }
      }
      // Sprocket at the mirror end, closing the loop.
      canvas.drawCircle(
        to,
        6,
        Paint()
          ..color = p.ink.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }

    // Post + base plate.
    canvas.drawLine(Offset(cx, gearC.dy), Offset(cx, size.y), stroke);
    canvas.drawRRect(
      RRect.fromLTRBR(cx - 11, size.y - 5, cx + 11, size.y,
          const Radius.circular(2.5)),
      Paint()..color = p.ink,
    );

    // Gear: rim, spinning teeth, interact-blue hub.
    canvas.drawCircle(gearC, gearR, stroke);
    final teeth = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = _spin + i * math.pi / 3;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
          gearC + dir * gearR, gearC + dir * (gearR + 5), teeth);
    }
    canvas.drawCircle(gearC, 5, Paint()..color = p.accentInteract);
  }
}

/// Traces every source's beam each frame against the room's solids, mirrors,
/// and sensors; renders the beam; sets sensors lit.
class OpticsSystem extends PositionComponent with HasGameReference<EscapeGame> {
  OpticsSystem({
    required this.sources,
    required this.mirrors,
    required this.sensors,
    this.splitters = const [],
    required this.roomSize,
  }) : super(priority: 5); // beams draw over geometry, under the player

  final List<LightSource> sources;
  final List<Mirror> mirrors;
  final List<LightSensor> sensors;
  final List<Splitter> splitters;
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
      for (final sp in splitters) BeamObstacle.splitter(sp.aabb, sp.state),
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
