import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../escape_game.dart';

/// Water hazard — the kid-friendly jeopardy (GDD §7): fall in and the claw
/// fishes you out, back to the node start. No death, barely even a splash.
/// Drawn with no-swimming-sign motifs: flat water fill with the wavy
/// signage surface line, gently undulating (motion doubles as telegraph).
class WaterPool extends PositionComponent with HasGameReference<EscapeGame> {
  WaterPool(Vector2 position, double width)
      : super(position: position, size: Vector2(width, Config.tileSize * 0.5));

  double _t = 0;

  /// Trigger box: slightly submerged, so brushing the surface is forgiven.
  Aabb get trigger =>
      Aabb(position.x + 2, position.y + 4, size.x - 4, size.y - 2);

  @override
  void update(double dt) {
    _t += dt;
    final player = game.player;
    if (!player.carried && trigger.overlaps(player.aabb)) {
      game.requestReset();
    }
    // Blocks are fished out too — a block sunk in a pool must never
    // soft-lock its puzzle (same kindness the player gets).
    final zone = trigger;
    for (final b in List.of(game.blocks)) {
      if (!b.held && b.aabb.overlaps(zone)) b.rescueHome();
    }
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    // The pool.
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(0, 3, size.x, size.y),
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      ),
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
