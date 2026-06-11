import 'dart:math' as math;
import 'dart:ui';

import '../config.dart';

/// THE brick motif — one painter so every brick surface in the game (walls,
/// corridor ceilings, corridor floors) is visually identical
/// (STYLE_GUIDE.md §6: masonry reads as masonry, consistently).
///
/// Draws thin bed joints every half tile and staggered head joints every
/// tile, clipped to [bounds]. Caller draws fill below and outline above.
void paintBrickCourses(Canvas canvas, RRect bounds, Color jointColor) {
  final joint = Paint()
    ..color = jointColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  const course = Config.tileSize / 2;
  const brickW = Config.tileSize;
  final r = bounds.outerRect;

  canvas.save();
  canvas.clipRRect(bounds);

  // Bed joints (horizontal).
  for (var y = r.top + course; y < r.bottom; y += course) {
    canvas.drawLine(Offset(r.left, y), Offset(r.right, y), joint);
  }
  // Head joints (vertical), staggered per course.
  var row = 0;
  for (var y = r.top; y < r.bottom; y += course, row++) {
    final offset = row.isOdd ? brickW / 2 : brickW;
    for (var x = r.left + offset; x < r.right; x += brickW) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + course, r.bottom)),
        joint,
      );
    }
  }
  canvas.restore();
}
