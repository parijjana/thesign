import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/collision_world.dart';
import '../escape_game.dart';
import 'brickwork.dart';

/// A walkable incline (STYLE_GUIDE §6) — a ramp you walk UP, not stairs you
/// can't. Rendered as a **brick slab** following the slope (constant thickness,
/// masonry motif, matching the floors and walls) and registered as a [Ramp]
/// support surface with the collision world.
///
/// The slope runs along the bbox diagonal: [highSide] is the end that meets the
/// top platform (its surface = the bbox top there); the other end is the low end
/// (surface = the bbox bottom there). Author the low end to sit in the water,
/// short of the room floor — the slab is a plank, not a filled wedge. The player
/// walks up it in walk *and* swim mode, no jump.
class RampComponent extends PositionComponent with HasGameReference<EscapeGame> {
  RampComponent(Vector2 position, Vector2 size, {this.highSide = 'left'})
      : super(position: position, size: size);

  /// Which end is high: `"left"` or `"right"`.
  final String highSide;

  /// Visual plank thickness (the slope itself is the bbox diagonal).
  static const double _thickness = Config.tileSize * 0.55;

  bool get _highRight => highSide == 'right';

  @override
  void onMount() {
    super.onMount();
    final x0 = position.x;
    final x1 = position.x + size.x;
    final top = position.y;
    final bottom = position.y + size.y;
    // High end's surface = top; low end's = bottom.
    final ramp = _highRight
        ? Ramp(x0, x1, bottom, top)
        : Ramp(x0, x1, top, bottom);
    game.collisionWorld.ramps.add(ramp);
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final w = size.x;
    final h = size.y;

    // The slope goes from the high corner to the low corner along the diagonal.
    final high = _highRight ? Offset(w, 0) : const Offset(0, 0);
    final low = _highRight ? Offset(0, h) : Offset(w, h);
    final len = (low - high).distance;
    final dir = (low - high) / len; // unit vector down the slope
    final t = _thickness;

    // The plank: a parallelogram of vertical thickness [t] under the slope.
    // Vertical (not perpendicular) so its high end sits flush against the flat
    // ledge — no leftward jut, no overlap.
    final down = Offset(0, t);
    final corners = <Offset>[
      high,
      low,
      low + down,
      high + down,
    ];
    final slab = Path()..addPolygon(corners, true);

    canvas.save();
    canvas.clipPath(slab);
    canvas.drawPath(slab, Paint()..color = p.surface);
    // Brick courses laid ALONG the slope: rotate so the slope is horizontal,
    // then reuse the shared masonry painter.
    canvas.save();
    canvas.translate(high.dx, high.dy);
    canvas.rotate(math.atan2(dir.dy, dir.dx));
    paintBrickCourses(
      canvas,
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, len, t), Radius.zero),
      p.ink,
    );
    canvas.restore();
    canvas.restore();

    canvas.drawPath(
      slab,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
