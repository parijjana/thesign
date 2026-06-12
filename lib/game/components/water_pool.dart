import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/aabb.dart';
import '../escape_game.dart';

/// Water hazard — the kid-friendly jeopardy (GDD §7): fall in and the claw
/// fishes you out, back to the node start. No death, barely even a splash.
///
/// Drawn with no-swimming-sign motifs: a flat water fill with the wavy
/// signage surface line, gently undulating. Renders BENEATH the floor slabs
/// (negative priority) and is authored slightly overlapping them, so the
/// pool reads as set INTO the ground — seamless, not taped on.
///
/// Blocks dropped in SINK with buoyant drag, and once fully submerged are
/// fished home to their start (anti-soft-lock).
class WaterPool extends PositionComponent with HasGameReference<EscapeGame> {
  WaterPool(Vector2 position, Vector2 size)
      : super(position: position, size: size, priority: -2);

  double _t = 0;

  /// Player trigger: starts a little below the surface, so brushing the
  /// waterline is forgiven.
  Aabb get trigger =>
      Aabb(position.x + 2, position.y + 6, size.x - 4, size.y - 6);

  @override
  void update(double dt) {
    _t += dt;
    final player = game.player;
    if (!player.carried && trigger.overlaps(player.aabb)) {
      game.requestReset(); // the claw fishes the player out
    }
    // Blocks sink slowly (buoyant drag); once well under, they're fished
    // home — a block lost in a pool must never soft-lock its puzzle.
    // (Generous box: the whole pool, not the inset player zone.)
    final pool = Aabb(position.x, position.y, size.x, size.y);
    for (final b in List.of(game.blocks)) {
      if (b.held || !b.aabb.overlaps(pool)) continue;
      b.applyWaterDrag();
      final centerY = b.aabb.y + b.aabb.h / 2;
      if (centerY > position.y + 12) b.rescueHome(); // submerged past center
    }
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    // Flat fill, square edges — the floor slabs draw over our rim.
    canvas.drawRect(
      Rect.fromLTRB(0, 3, size.x, size.y),
      Paint()..color = p.water,
    );
    // The signage wave surface: an undulating polyline, like the waves on a
    // no-swimming sign.
    final wave = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(0, 4);
    for (var x = 0.0; x <= size.x; x += 6) {
      path.lineTo(x, 4 + math.sin(x / 9 + _t * 2.2) * 2.2);
    }
    canvas.drawPath(path, wave);
  }
}
