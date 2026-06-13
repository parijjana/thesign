import 'dart:ui';

import 'package:flame/components.dart';

import '../core/aabb.dart';
import '../escape_game.dart';
import 'weight.dart';

/// A floor plate that is [pressed] while weighed down (STYLE_GUIDE §6: "step
/// / weigh down"). Uses the shared weight system, so a stack of blocks loads
/// it by its full weight. Puzzle scripts read [pressed]; the plate depresses.
class PressurePlate extends PositionComponent
    with HasGameReference<EscapeGame> {
  PressurePlate(Vector2 position, Vector2 size, {this.requiresWeight = 1})
      : super(position: position, size: size);

  /// Minimum weight (block-units) needed to count as pressed.
  final double requiresWeight;

  bool pressed = false;

  /// The rest level objects sit at over the plate (its base = the floor top).
  Aabb get _surface =>
      Aabb(position.x, position.y + size.y, size.x, 1);

  @override
  void update(double dt) {
    pressed = weightOn(game, _surface) >= requiresWeight - 0.01;
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
