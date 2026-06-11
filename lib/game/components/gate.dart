import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../escape_game.dart';

/// A solid gate that slides up into the ceiling when [open] (set by the
/// room's puzzle script). The collision box shrinks with the visual.
class Gate extends PositionComponent with HasGameReference<EscapeGame> {
  Gate(Vector2 position, Vector2 size) : super(position: position, size: size);

  bool open = false;
  double _openT = 0; // 0 closed .. 1 fully raised

  late final Aabb _solid = Aabb(position.x, position.y, size.x, size.y);

  @override
  void onMount() {
    super.onMount();
    game.collisionWorld.solids.add(_solid);
  }

  @override
  void onRemove() {
    game.collisionWorld.solids.remove(_solid);
    super.onRemove();
  }

  @override
  void update(double dt) {
    final target = open ? 1.0 : 0.0;
    _openT += (target - _openT).clamp(-dt * 2.5, dt * 2.5);
    // The gate rises: solid shrinks from the bottom up.
    _solid.h = size.y * (1 - _openT);
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final visibleH = size.y * (1 - _openT);
    if (visibleH < 2) return;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, visibleH),
      const Radius.circular(5),
    );
    canvas.drawRRect(r, Paint()..color = p.surface);
    canvas.drawRRect(
      r,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    // Slat lines so it reads as a portcullis, not a wall.
    final slat = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    for (var y = 10.0; y < visibleH - 4; y += 12) {
      canvas.drawLine(Offset(3, y), Offset(size.x - 3, y), slat);
    }
  }
}
