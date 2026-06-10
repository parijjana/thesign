// M1 TEST ROOM — temporary content proving the foundations (palette,
// letterboxed viewport, input chain). Replaced by data-loaded rooms in M3;
// the probe puck is replaced by the real PlayerComponent in M2.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../escape_game.dart';

/// A themed empty room drawn in signage style: bg field, heavy room border,
/// floor slab and side walls (STYLE_GUIDE.md §6–7).
class TestRoom extends PositionComponent with HasGameReference<EscapeGame> {
  TestRoom()
      : super(
          position: Vector2.zero(),
          size: Vector2(Config.viewportWidth, Config.viewportHeight),
        );

  @override
  void onLoad() {
    add(ProbePuck());
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final fillBg = Paint()..color = p.bg;
    final fillSurface = Paint()..color = p.surface;
    final strokeInk = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = Config.stroke
      ..strokeJoin = StrokeJoin.round;
    final strokeHeavy = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = Config.strokeHeavy
      ..strokeJoin = StrokeJoin.round;

    // Background field.
    canvas.drawRect(size.toRect(), fillBg);

    // Floor slab.
    const t = Config.tileSize;
    final floor = RRect.fromLTRBR(
      t * 0.5,
      size.y - t * 2,
      size.x - t * 0.5,
      size.y - t * 0.5,
      const Radius.circular(10),
    );
    canvas.drawRRect(floor, fillSurface);
    canvas.drawRRect(floor, strokeInk);

    // Side wall columns with a brick-coursing motif (thin ink joints).
    final wallW = t * 0.75;
    final joint = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final x in [t * 0.5, size.x - t * 0.5 - wallW]) {
      const top = t * 0.5;
      final bottom = size.y - t * 2;
      final wall = RRect.fromLTRBR(
        x,
        top,
        x + wallW,
        bottom,
        const Radius.circular(6),
      );
      canvas.drawRRect(wall, fillSurface);

      canvas.save();
      canvas.clipRRect(wall);
      const course = Config.tileSize / 2; // brick course height
      var row = 0;
      for (var y = top; y < bottom; y += course, row++) {
        // Horizontal bed joint under each course.
        canvas.drawLine(Offset(x, y + course), Offset(x + wallW, y + course),
            joint);
        // Staggered vertical head joint on alternate courses.
        if (row.isOdd) {
          canvas.drawLine(
            Offset(x + wallW / 2, y),
            Offset(x + wallW / 2, math.min(y + course, bottom)),
            joint,
          );
        }
      }
      canvas.restore();

      canvas.drawRRect(wall, strokeInk);
    }

    // Heavy room boundary, drawn last so the ink edge stays crisp.
    canvas.drawRect(size.toRect().deflate(Config.strokeHeavy / 2), strokeHeavy);
  }
}

/// Temporary input probe: an ink puck sliding on the floor via
/// [GameInput.moveAxis] — proves keyboard → GameInput → component end-to-end.
class ProbePuck extends PositionComponent with HasGameReference<EscapeGame> {
  static const radius = 12.0;

  @override
  void onLoad() {
    position = Vector2(
      Config.viewportWidth / 2,
      Config.viewportHeight - Config.tileSize * 2 - radius,
    );
  }

  @override
  void update(double dt) {
    position.x += game.input.moveAxis * Config.runSpeed * dt;
    position.x = position.x.clamp(
      Config.tileSize * 2 + radius,
      Config.viewportWidth - Config.tileSize * 2 - radius,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius, Paint()..color = game.palette.ink);
  }
}
