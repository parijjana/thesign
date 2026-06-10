import 'dart:math' as math;

/// Axis-aligned bounding box, the unit of all collision (ARCHITECTURE.md §5.3).
/// Pure Dart — no Flame/Flutter imports — so it's trivially unit-testable.
class Aabb {
  Aabb(this.x, this.y, this.w, this.h)
      : assert(w >= 0),
        assert(h >= 0);

  double x, y, w, h;

  double get left => x;
  double get top => y;
  double get right => x + w;
  double get bottom => y + h;

  bool overlaps(Aabb o) =>
      x < o.right && right > o.x && y < o.bottom && bottom > o.y;

  Aabb copy() => Aabb(x, y, w, h);

  @override
  String toString() => 'Aabb($x, $y, $w, $h)';
}

/// Clips a horizontal movement [dx] of [box] against [solids]: returns the
/// largest portion of [dx] that doesn't penetrate any solid. Flush contact
/// (touching edges) is allowed.
double clipDx(Aabb box, double dx, Iterable<Aabb> solids) {
  var clipped = dx;
  for (final s in solids) {
    final verticalOverlap = box.y < s.bottom && box.bottom > s.y;
    if (!verticalOverlap) continue;
    if (dx > 0 && box.right <= s.x) {
      clipped = math.min(clipped, s.x - box.right);
    } else if (dx < 0 && box.x >= s.right) {
      clipped = math.max(clipped, s.right - box.x);
    }
  }
  return clipped;
}

/// Vertical counterpart of [clipDx].
double clipDy(Aabb box, double dy, Iterable<Aabb> solids) {
  var clipped = dy;
  for (final s in solids) {
    final horizontalOverlap = box.x < s.right && box.right > s.x;
    if (!horizontalOverlap) continue;
    if (dy > 0 && box.bottom <= s.y) {
      clipped = math.min(clipped, s.y - box.bottom);
    } else if (dy < 0 && box.y >= s.bottom) {
      clipped = math.max(clipped, s.bottom - box.y);
    }
  }
  return clipped;
}
