import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../escape_game.dart';

/// Solid wall column with the brick-coursing motif (STYLE_GUIDE.md §6):
/// thin ink bed joints + staggered head joints so masonry reads as masonry.
class Wall extends PositionComponent with HasGameReference<EscapeGame> {
  Wall(Vector2 position, Vector2 size) : super(position: position, size: size);

  @override
  void onMount() {
    super.onMount();
    game.collisionWorld.solids.add(Aabb(position.x, position.y, size.x, size.y));
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final rect = size.toRect();
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(r, Paint()..color = p.surface);

    final joint = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.save();
    canvas.clipRRect(r);
    const course = Config.tileSize / 2;
    var row = 0;
    for (var y = 0.0; y < size.y; y += course, row++) {
      canvas.drawLine(
          Offset(0, y + course), Offset(size.x, y + course), joint);
      if (row.isOdd) {
        canvas.drawLine(
          Offset(size.x / 2, y),
          Offset(size.x / 2, math.min(y + course, size.y)),
          joint,
        );
      }
    }
    canvas.restore();

    canvas.drawRRect(
      r,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
