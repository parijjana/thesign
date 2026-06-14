import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/collision_world.dart';
import '../escape_game.dart';

/// A walkable incline (STYLE_GUIDE §6) — a ramp you walk UP, not stairs you
/// can't. Renders as a signage-style right triangle in masonry tones and
/// registers a [Ramp] support surface with the collision world.
///
/// The slope runs across the component's bounding box. [highSide] names the end
/// that meets the top platform; the other end drops to the box's bottom (author
/// it so that low end meets the floor — see [Ramp]).
class RampComponent extends PositionComponent with HasGameReference<EscapeGame> {
  RampComponent(Vector2 position, Vector2 size, {this.highSide = 'left'})
      : super(position: position, size: size);

  /// Which end is high: `"left"` or `"right"`.
  final String highSide;

  @override
  void onMount() {
    super.onMount();
    final x0 = position.x;
    final x1 = position.x + size.x;
    final top = position.y;
    final bottom = position.y + size.y;
    // High end's surface = top; low end's = bottom.
    final ramp = highSide == 'right'
        ? Ramp(x0, x1, bottom, top)
        : Ramp(x0, x1, top, bottom);
    game.collisionWorld.ramps.add(ramp);
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final w = size.x;
    final h = size.y;
    // Right triangle: the hypotenuse is the slope; the vertical leg is at the
    // high side, the horizontal leg along the bottom.
    final path = Path();
    if (highSide == 'right') {
      path
        ..moveTo(0, h) // low corner (bottom-left)
        ..lineTo(w, 0) // high corner (top-right)
        ..lineTo(w, h); // down the high side
    } else {
      path
        ..moveTo(0, 0) // high corner (top-left)
        ..lineTo(w, h) // low corner (bottom-right)
        ..lineTo(0, h); // down the high side
    }
    path.close();

    canvas.drawPath(path, Paint()..color = p.surface);
    canvas.drawPath(
      path,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
