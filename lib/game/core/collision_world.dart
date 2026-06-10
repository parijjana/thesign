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

/// Broadphase-less collision world over static solid geometry — rooms are a
/// few dozen boxes, so a linear scan is plenty (ARCHITECTURE.md §5.3).
/// Pure Dart for headless tests.
class CollisionWorld {
  final List<Aabb> solids = [];

  /// Moves [box] by ([dx], [dy]) resolving X first, then Y (the classic
  /// kinematic order: walking into a wall doesn't kill your fall, landing
  /// doesn't stop your run). MUTATES [box] to the resolved position.
  MoveResult move(Aabb box, double dx, double dy) {
    final allowedX = clipDx(box, dx, solids);
    box.x += allowedX;
    final allowedY = clipDy(box, dy, solids);
    box.y += allowedY;
    return MoveResult(
      allowedX,
      allowedY,
      hitX: allowedX != dx,
      hitY: allowedY != dy,
    );
  }

  /// True if [box] is resting on a solid (a 1px probe downward is blocked).
  bool isGrounded(Aabb box) => clipDy(box, 1, solids) < 1;
}
