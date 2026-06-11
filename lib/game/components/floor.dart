import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../escape_game.dart';
import 'brickwork.dart';

/// Solid floor/platform slab in signage style (STYLE_GUIDE.md §6).
/// Registers itself as collision geometry on mount. Corridor floors render
/// with the shared brick motif (GDD §4 corridor identity); room floors stay
/// plain slabs — one more cue that can't be confused.
class Floor extends PositionComponent with HasGameReference<EscapeGame> {
  Floor(Vector2 position, Vector2 size, {this.brick = false})
      : super(position: position, size: size);

  final bool brick;

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
    if (brick) paintBrickCourses(canvas, r, p.ink);
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
