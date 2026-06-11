import 'package:flutter_test/flutter_test.dart';
import 'package:thesign/game/core/aabb.dart';
import 'package:thesign/game/core/beam_tracer.dart';

void main() {
  group('reflect (45° mirrors)', () {
    test('"/" turns east→north and north→east', () {
      expect(reflect('/', 1, 0), (0, -1));
      expect(reflect('/', 0, -1), (1, 0));
    });

    test(r'"\" turns east→south and north→west', () {
      expect(reflect(r'\', 1, 0), (0, 1));
      expect(reflect(r'\', 0, -1), (-1, 0));
    });
  });

  group('traceBeam', () {
    test('stops at a wall', () {
      final r = traceBeam(
        ox: 10, oy: 50, dx: 1, dy: 0,
        obstacles: [BeamObstacle.solid(Aabb(100, 0, 20, 100))],
        boundsW: 400, boundsH: 100,
      );
      expect(r.segments.length, 1);
      expect(r.segments.single.x2, 100);
      expect(r.litSensors, isEmpty);
    });

    test('exits the bounds when nothing is hit', () {
      final r = traceBeam(
        ox: 10, oy: 50, dx: 1, dy: 0,
        obstacles: [],
        boundsW: 400, boundsH: 100,
      );
      expect(r.segments.single.x2, 400);
    });

    test('one mirror bends the beam onto a sensor (the worked example)', () {
      // east → '/' at (100,50) → north → sensor above the mirror.
      final r = traceBeam(
        ox: 10, oy: 50, dx: 1, dy: 0,
        obstacles: [
          BeamObstacle.mirror(Aabb(90, 40, 20, 20), '/'),
          BeamObstacle.sensor(Aabb(90, 0, 20, 10), 'sensorA'),
        ],
        boundsW: 400, boundsH: 100,
      );
      expect(r.litSensors, {'sensorA'});
      expect(r.segments.length, 2);
      // Bend happens at the mirror's center.
      expect(r.segments.first.x2, 100);
      expect(r.segments.first.y2, 50);
    });

    test('a wrongly-set mirror misses the sensor', () {
      final r = traceBeam(
        ox: 10, oy: 50, dx: 1, dy: 0,
        obstacles: [
          BeamObstacle.mirror(Aabb(90, 40, 20, 20), r'\'), // east→south
          BeamObstacle.sensor(Aabb(90, 0, 20, 10), 'sensorA'),
        ],
        boundsW: 400, boundsH: 100,
      );
      expect(r.litSensors, isEmpty);
    });

    test('two mirrors route around a pillar (room_mirror layout)', () {
      // east → '/' up → '/' east again → sensor, with a pillar between
      // source row and sensor row that the high path clears.
      final r = traceBeam(
        ox: 64, oy: 192, dx: 1, dy: 0,
        obstacles: [
          BeamObstacle.solid(Aabb(448, 128, 64, 256)), // pillar y128..384
          BeamObstacle.mirror(Aabb(256, 176, 32, 32), '/'),
          BeamObstacle.mirror(Aabb(256, 48, 32, 32), '/'),
          BeamObstacle.sensor(Aabb(672, 48, 32, 32), 'sensorA'),
        ],
        boundsW: 768, boundsH: 448,
      );
      expect(r.litSensors, {'sensorA'});
      expect(r.segments.length, 3);
    });

    test('mirror loops terminate at maxHops', () {
      // Four mirrors in a square cycle — the beam orbits forever.
      // (Origin sits inside the cycle so the first hit enters it.)
      final r = traceBeam(
        ox: 70, oy: 50, dx: 1, dy: 0,
        obstacles: [
          BeamObstacle.mirror(Aabb(90, 40, 20, 20), '/'), // E→N
          BeamObstacle.mirror(Aabb(90, 0, 20, 20), r'\'), // N→W
          BeamObstacle.mirror(Aabb(40, 0, 20, 20), '/'), // W→S
          BeamObstacle.mirror(Aabb(40, 40, 20, 20), r'\'), // S→E
        ],
        boundsW: 400, boundsH: 100,
        maxHops: 8,
      );
      expect(r.segments.length, 8); // bounded, no infinite loop
    });
  });
}
