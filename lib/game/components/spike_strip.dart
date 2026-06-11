import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../escape_game.dart';

/// Spike hazard: a row of hard danger-red triangles (the deliberate exception
/// to rounded corners — hard points = danger semantics, STYLE_GUIDE.md §4/§6).
/// Touching it triggers the claw reset — never death (GDD.md §7).
class SpikeStrip extends PositionComponent with HasGameReference<EscapeGame> {
  SpikeStrip(Vector2 position, double width)
      : super(position: position, size: Vector2(width, Config.tileSize * 0.5));

  /// Trigger box, slightly forgiving: inset so grazing an edge doesn't count.
  Aabb get trigger =>
      Aabb(position.x + 4, position.y + 6, size.x - 8, size.y - 6);

  @override
  void update(double dt) {
    final player = game.player;
    if (!player.carried && trigger.overlaps(player.aabb)) {
      game.requestReset();
    }
    // Blocks are rejected home too — a block lost in a pit must never
    // soft-lock its puzzle.
    final zone = trigger;
    for (final b in List.of(game.blocks)) {
      if (!b.held && b.aabb.overlaps(zone)) b.rescueHome();
    }
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final fill = Paint()..color = p.accentDanger;
    final stroke = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.miter; // hard points, deliberately
    final spikeW = Config.tileSize / 2;
    final n = (size.x / spikeW).floor();
    final path = Path();
    for (var i = 0; i < n; i++) {
      final x = i * spikeW;
      path
        ..moveTo(x, size.y)
        ..lineTo(x + spikeW / 2, 0)
        ..lineTo(x + spikeW, size.y);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }
}
