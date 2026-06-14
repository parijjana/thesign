import 'dart:math' as math;

import 'aabb.dart';

/// Result of a kinematic move: how far the box actually travelled and which
/// axes made contact.
class MoveResult {
  MoveResult(this.dx, this.dy, {required this.hitX, required this.hitY});

  final double dx;
  final double dy;

  /// True when movement on that axis was clipped by a solid.
  final bool hitX;
  final bool hitY;
}

/// A walkable slope (STYLE_GUIDE §6 — an incline you walk up, not stairs you
/// can't). Modelled as a **one-way support surface from above**: you rest on
/// the top edge and may pass through from below/the sides. Authoring rule: the
/// low end must meet the floor, so a body arriving along the bottom is already
/// on the surface and climbs from there (never yanked up from deep below).
class Ramp {
  Ramp(this.x0, this.x1, this.yAtX0, this.yAtX1);

  /// Left/right extent and the surface height at each (top edge of the slope).
  final double x0, x1, yAtX0, yAtX1;

  /// Slope-surface y at world [x] (clamped to the ramp's extent).
  double surfaceY(double x) {
    final t = ((x - x0) / (x1 - x0)).clamp(0.0, 1.0);
    return yAtX0 + (yAtX1 - yAtX0) * t;
  }

  /// The highest (smallest y) surface point under a footprint — so a body sits
  /// on the slope without its leading edge sinking in.
  double supportY(double lx, double rx) =>
      math.min(surfaceY(lx.clamp(x0, x1)), surfaceY(rx.clamp(x0, x1)));

  bool overlapsX(double lx, double rx) => lx < x1 && rx > x0;
}

/// Broadphase-less collision world over static solid geometry — rooms are a
/// few dozen boxes, so a linear scan is plenty (ARCHITECTURE.md §5.3).
/// Pure Dart for headless tests. Holds axis-aligned [solids] plus walkable
/// [ramps] (slopes).
class CollisionWorld {
  final List<Aabb> solids = [];
  final List<Ramp> ramps = [];

  /// How far above a ramp surface a descending/grounded body snaps down to it,
  /// so walking *down* a slope sticks instead of stair-stepping off the edge.
  static const double _rampSnap = 8;

  /// Moves [box] by ([dx], [dy]) resolving X first, then Y (the classic
  /// kinematic order: walking into a wall doesn't kill your fall, landing
  /// doesn't stop your run), then settling onto any ramp surface beneath it.
  /// MUTATES [box] to the resolved position.
  MoveResult move(Aabb box, double dx, double dy) {
    final startY = box.y;
    final allowedX = clipDx(box, dx, solids);
    box.x += allowedX;
    final allowedY = clipDy(box, dy, solids);
    box.y += allowedY;

    var hitY = allowedY != dy;
    // Ramp pass: a slope lifts a body walking up a rise (or catches a fall),
    // and snaps a descending body down so it hugs the incline. Only while NOT
    // moving upward (dy >= 0), so a jump still launches cleanly off the slope.
    if (dy >= 0) {
      for (final r in ramps) {
        if (!r.overlapsX(box.left, box.right)) continue;
        final support = r.supportY(box.left, box.right);
        final penetration = box.bottom - support; // >0 = below the surface
        if (penetration > 0) {
          box.y -= penetration; // lift onto the slope
          hitY = true;
        } else if (-penetration <= _rampSnap) {
          box.y -= penetration; // snap down (penetration<0 → moves down)
          hitY = true;
        }
      }
    }

    return MoveResult(
      allowedX,
      box.y - startY, // actual vertical travel, including any ramp settle
      hitX: allowedX != dx,
      hitY: hitY,
    );
  }

  /// True if [box] is resting on a solid (a 1px probe downward is blocked) or
  /// on a ramp surface.
  bool isGrounded(Aabb box) {
    if (clipDy(box, 1, solids) < 1) return true;
    for (final r in ramps) {
      if (!r.overlapsX(box.left, box.right)) continue;
      if ((box.bottom - r.supportY(box.left, box.right)).abs() <= 1.0) {
        return true;
      }
    }
    return false;
  }
}
