import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../escape_game.dart';
import 'brickwork.dart';

/// Solid floor/platform slab in signage style (STYLE_GUIDE.md §6).
/// Registers itself as collision geometry on mount. All masonry — floors,
/// walls, ceilings — carries the same shared brick motif, consistently.
class Floor extends PositionComponent with HasGameReference<EscapeGame> {
  Floor(Vector2 position, Vector2 size) : super(position: position, size: size);

  @override
  void onMount() {
    super.onMount();
    game.collisionWorld.solids.add(Aabb(position.x, position.y, size.x, size.y));
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final r = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8));
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
