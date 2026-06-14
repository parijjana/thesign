import 'package:flutter_test/flutter_test.dart';
import 'package:thesign/game/core/aabb.dart';
import 'package:thesign/game/core/collision_world.dart';

void main() {
  group('Aabb.overlaps', () {
    test('detects overlap and separation', () {
      expect(Aabb(0, 0, 10, 10).overlaps(Aabb(5, 5, 10, 10)), isTrue);
      expect(Aabb(0, 0, 10, 10).overlaps(Aabb(20, 0, 10, 10)), isFalse);
    });

    test('flush edges do not count as overlap', () {
      expect(Aabb(0, 0, 10, 10).overlaps(Aabb(10, 0, 10, 10)), isFalse);
      expect(Aabb(0, 0, 10, 10).overlaps(Aabb(0, 10, 10, 10)), isFalse);
    });
  });

  group('clip', () {
    final wall = Aabb(20, 0, 10, 30);
    final floor = Aabb(0, 20, 100, 10);

    test('rightward movement clips at a wall', () {
      expect(clipDx(Aabb(0, 0, 10, 10), 25, [wall]), 10);
    });

    test('leftward movement clips at a wall', () {
      expect(clipDx(Aabb(40, 0, 10, 10), -25, [wall]), -10);
    });

    test('no clipping without vertical overlap', () {
      expect(clipDx(Aabb(0, 50, 10, 10), 25, [wall]), 25);
    });

    test('falling clips onto a floor', () {
      expect(clipDy(Aabb(0, 0, 10, 10), 50, [floor]), 10);
    });

    test('rising clips at a ceiling', () {
      final ceiling = Aabb(0, 0, 100, 10);
      expect(clipDy(Aabb(0, 30, 10, 10), -50, [ceiling]), -20);
    });

    test('resting flush on a floor still slides horizontally', () {
      // bottom == floor.top: no vertical overlap, so no horizontal clip.
      expect(clipDx(Aabb(0, 10, 10, 10), 5, [floor]), 5);
    });
  });

  group('CollisionWorld.move', () {
    test('diagonal into a corner resolves X then Y', () {
      final w = CollisionWorld()
        ..solids.addAll([Aabb(20, 0, 10, 40), Aabb(0, 20, 40, 10)]);
      final box = Aabb(0, 0, 10, 10);
      final r = w.move(box, 25, 25);
      expect(box.x, 10); // stopped at the wall
      expect(box.y, 10); // stopped on the floor
      expect(r.hitX, isTrue);
      expect(r.hitY, isTrue);
    });

    test('free movement is unclipped', () {
      final w = CollisionWorld();
      final box = Aabb(0, 0, 10, 10);
      final r = w.move(box, 7, -3);
      expect(box.x, 7);
      expect(box.y, -3);
      expect(r.hitX, isFalse);
      expect(r.hitY, isFalse);
    });

    test('isGrounded: resting yes, airborne no', () {
      final w = CollisionWorld()..solids.add(Aabb(0, 20, 100, 10));
      expect(w.isGrounded(Aabb(0, 10, 10, 10)), isTrue); // flush on top
      expect(w.isGrounded(Aabb(0, 5, 10, 10)), isFalse); // 5px in the air
    });
  });

  group('Ramp (walkable slope)', () {
    // Rises to the LEFT: high (y=0) at x0, low (y=100) at x1.
    final ramp = Ramp(0, 100, 0, 100);

    test('surface/support height along the slope', () {
      expect(ramp.surfaceY(50), 50);
      // Support is the highest (leftmost) point under the footprint.
      expect(ramp.supportY(40, 50), 40);
      // Footprint clamps to the ramp extent.
      expect(ramp.supportY(-20, 10), 0);
    });

    test('walking up a rise lifts the body onto the slope', () {
      final w = CollisionWorld()..ramps.add(ramp);
      final box = Aabb(40, 35, 10, 10); // bottom 45, below support (40)
      w.move(box, 0, 1);
      expect(box.bottom, 40); // sat on the surface
    });

    test('walking down the slope snaps onto it (no stair-step off)', () {
      final w = CollisionWorld()..ramps.add(ramp);
      final box = Aabb(40, 30, 10, 10); // resting: bottom 40 == support
      w.move(box, 5, 1); // step toward the low side
      expect(box.bottom, 45); // hugged the slope down to the new support
    });

    test('a jump (upward move) launches cleanly off the slope', () {
      final w = CollisionWorld()..ramps.add(ramp);
      final box = Aabb(40, 60, 10, 10); // below the surface
      w.move(box, 0, -5); // rising
      expect(box.y, 55); // not yanked up onto the slope
    });

    test('isGrounded true when resting on a ramp', () {
      final w = CollisionWorld()..ramps.add(ramp);
      expect(w.isGrounded(Aabb(40, 30, 10, 10)), isTrue); // bottom 40 == support
      expect(w.isGrounded(Aabb(40, 25, 10, 10)), isFalse); // 5px above
    });
  });
}
