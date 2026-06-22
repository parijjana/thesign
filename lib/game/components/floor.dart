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
  Floor(Vector2 position, Vector2 size, {this.invisible = false})
      : super(position: position, size: size);

  /// Solid but unpainted — used where authored art (an SVG backdrop) already
  /// depicts the ground/branch, so we want the collision without a flat slab
  /// drawn over it (the meadow, M7).
  final bool invisible;

  @override
  void onMount() {
    super.onMount();
    game.collisionWorld.solids.add(Aabb(position.x, position.y, size.x, size.y));
  }

  @override
  void render(Canvas canvas) {
    if (invisible) return;
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
