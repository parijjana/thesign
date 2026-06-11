import 'dart:ui';

import 'package:flame/components.dart';

import '../core/aabb.dart';
import '../escape_game.dart';

/// A floor plate that is [pressed] while weighed down by the player or a
/// placed block (STYLE_GUIDE §6: "step / weigh down"). Puzzle scripts read
/// [pressed]; the plate visually depresses.
class PressurePlate extends PositionComponent
    with HasGameReference<EscapeGame> {
  PressurePlate(Vector2 position, Vector2 size)
      : super(position: position, size: size);

  bool pressed = false;

  Aabb get _zone =>
      Aabb(position.x + 2, position.y - 6, size.x - 4, size.y + 6);

  @override
  void update(double dt) {
    final zone = _zone;
    pressed = (!game.player.carried && zone.overlaps(game.player.aabb)) ||
        game.blocks.any((b) => !b.held && b.aabb.overlaps(zone));
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final depress = pressed ? size.y * 0.45 : 0.0;
    final tab = RRect.fromRectAndCorners(
      Rect.fromLTRB(0, depress, size.x, size.y),
      topLeft: const Radius.circular(5),
      topRight: const Radius.circular(5),
    );
    canvas.drawRRect(tab, Paint()..color = p.accentInteract);
    canvas.drawRRect(
      tab,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
