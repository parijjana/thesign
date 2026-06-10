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
}
