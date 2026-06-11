import 'aabb.dart';

/// Deterministic light-beam raycaster (docs/examples/room-optics-mirror.md).
/// Pure Dart, headless-testable. Beams are axis-aligned: sources emit along
/// an axis and 45° mirrors turn them 90°, so a "raycast" is just a nearest-
/// edge search.
enum BeamObstacleKind { solid, mirror, sensor }

class BeamObstacle {
  BeamObstacle.solid(this.box)
      : kind = BeamObstacleKind.solid,
        mirrorState = '',
        sensorId = '';

  /// [state] is `'/'` or `'\'`.
  BeamObstacle.mirror(this.box, String state)
      : kind = BeamObstacleKind.mirror,
        mirrorState = state,
        sensorId = '';

  BeamObstacle.sensor(this.box, this.sensorId)
      : kind = BeamObstacleKind.sensor,
        mirrorState = '';

  final Aabb box;
  final BeamObstacleKind kind;
  final String mirrorState;
  final String sensorId;
}

class BeamSegment {
  BeamSegment(this.x1, this.y1, this.x2, this.y2);

  final double x1, y1, x2, y2;
}

class BeamResult {
  BeamResult(this.segments, this.litSensors);

  final List<BeamSegment> segments;
  final Set<String> litSensors;
}

/// Reflection of 45° mirrors (worked example §5):
/// `/` maps (dx,dy) → (-dy,-dx);  `\` maps (dx,dy) → (dy,dx).
(int, int) reflect(String state, int dx, int dy) =>
    state == '/' ? (-dy, -dx) : (dy, dx);

BeamResult traceBeam({
  required double ox,
  required double oy,
  required int dx,
  required int dy,
  required List<BeamObstacle> obstacles,
  required double boundsW,
  required double boundsH,
  int maxHops = 16,
}) {
  assert((dx.abs() == 1) ^ (dy.abs() == 1), 'beam must be axis-aligned');
  final segments = <BeamSegment>[];
  final lit = <String>{};
  var x = ox, y = oy;
  var dirX = dx, dirY = dy;

  for (var hop = 0; hop < maxHops; hop++) {
    // Nearest obstacle ahead, else the room bounds.
    var bestT = _boundsExit(x, y, dirX, dirY, boundsW, boundsH);
    BeamObstacle? best;
    for (final o in obstacles) {
      final t = _entryT(x, y, dirX, dirY, o.box);
      if (t != null && t < bestT) {
        bestT = t;
        best = o;
      }
    }

    // Mirrors/sensors bend or terminate the beam at their CENTER (visual
    // niceness); solids stop it at the entry edge.
    var endT = bestT;
    if (best != null && best.kind != BeamObstacleKind.solid) {
      endT = dirX != 0 ? (best.box.x + best.box.w / 2 - x) * dirX
                       : (best.box.y + best.box.h / 2 - y) * dirY;
    }
    final ex = x + dirX * endT;
    final ey = y + dirY * endT;
    segments.add(BeamSegment(x, y, ex, ey));

    if (best == null || best.kind == BeamObstacleKind.solid) break;
    if (best.kind == BeamObstacleKind.sensor) {
      lit.add(best.sensorId);
      break;
    }
    // Mirror: turn and continue from just past the center.
    final (ndx, ndy) = reflect(best.mirrorState, dirX, dirY);
    dirX = ndx;
    dirY = ndy;
    x = ex + dirX * 0.5;
    y = ey + dirY * 0.5;
  }
  return BeamResult(segments, lit);
}

/// Distance along the ray to the entry edge of [box], or null if the box
/// isn't ahead or doesn't span the ray's line. Boxes containing the origin
/// are ignored (a beam starts inside its source's cell).
double? _entryT(double x, double y, int dirX, int dirY, Aabb box) {
  if (dirX != 0) {
    if (y <= box.y || y >= box.bottom) return null;
    final t = dirX > 0 ? box.x - x : x - box.right;
    return t > 0 ? t : null;
  } else {
    if (x <= box.x || x >= box.right) return null;
    final t = dirY > 0 ? box.y - y : y - box.bottom;
    return t > 0 ? t : null;
  }
}

double _boundsExit(
    double x, double y, int dirX, int dirY, double w, double h) {
  if (dirX > 0) return w - x;
  if (dirX < 0) return x;
  if (dirY > 0) return h - y;
  return y;
}
