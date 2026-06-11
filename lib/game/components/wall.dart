import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../escape_game.dart';
import 'brickwork.dart';

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

    paintBrickCourses(canvas, r, p.ink);

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
