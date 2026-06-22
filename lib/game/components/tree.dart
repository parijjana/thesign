import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../escape_game.dart';

/// A framing tree for the night meadow (M7 hub). Rooted at its OUTER edge with
/// boughs reaching inward; place one normal (left) and one [mirror] (right) so
/// their canopies overlap and frame the scene. Non-solid silhouette — the
/// standable boughs are `floor` platforms placed along the limbs, with the
/// teleporters perched on them. Drawn in the meadow's dark `surface` with a
/// light ink edge so it reads against the night sky. Programmer-art for now;
/// the M7.5 art pass gives it the pixelart/signage-hybrid treatment.
class Tree extends PositionComponent with HasGameReference<EscapeGame> {
  Tree(Vector2 position, Vector2 size, {this.mirror = false})
      : super(position: position, size: size, priority: 1);

  final bool mirror;

  /// Bough anchor (on the trunk) → tip (reaching inward/up), in fractions.
  static const _boughs = [
    [Offset(0.16, 0.82), Offset(0.66, 0.74)],
    [Offset(0.16, 0.54), Offset(0.98, 0.46)],
    [Offset(0.16, 0.28), Offset(0.70, 0.20)],
  ];

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final w = size.x;
    final h = size.y;
    canvas.save();
    if (mirror) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }
    final fill = Paint()..color = p.surface;
    final edge = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = Config.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Trunk: a tapering column at the outer edge.
    final trunk = Path()
      ..moveTo(w * 0.02, h)
      ..lineTo(w * 0.10, h * 0.04)
      ..lineTo(w * 0.22, h * 0.04)
      ..lineTo(w * 0.18, h)
      ..close();
    canvas.drawPath(trunk, fill);
    canvas.drawPath(trunk, edge);

    // Boughs + leafy canopy clumps at each tip.
    for (final b in _boughs) {
      final a = Offset(b[0].dx * w, b[0].dy * h);
      final tip = Offset(b[1].dx * w, b[1].dy * h);
      canvas.drawLine(a, tip, edge);
      _clump(canvas, tip, w * 0.16, fill);
    }
    canvas.restore();
  }

  /// A soft canopy blob — overlapping ovals, filled only (a night silhouette).
  void _clump(Canvas canvas, Offset c, double r, Paint fill) {
    final path = Path();
    for (final o in const [
      Offset(0, 0),
      Offset(-0.6, 0.1),
      Offset(0.6, 0.1),
      Offset(0, -0.6),
      Offset(0.3, 0.4),
    ]) {
      path.addOval(Rect.fromCircle(
          center: c + Offset(o.dx * r, o.dy * r), radius: r * 0.7));
    }
    canvas.drawPath(path, fill);
  }
}
