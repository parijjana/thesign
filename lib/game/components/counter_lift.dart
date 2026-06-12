import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../core/reset_controller.dart';
import '../escape_game.dart';

/// Counterweight lift (Gravity): a platform rises as blocks are loaded into
/// its basket — 1.5 tiles per block (max 2). Real pulley logic: the heavier
/// the counterweight, the higher you ride.
class CounterLift extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Resettable {
  CounterLift(Vector2 position, Vector2 size, {required this.basket})
      : super(position: position, size: size);

  /// Basket floor zone (px): blocks resting here are the counterweight.
  final Aabb basket;

  late final double _baseY = position.y;
  late final Aabb _solid = Aabb(position.x, position.y, size.x, size.y);

  @override
  void onMount() {
    super.onMount();
    game.collisionWorld.solids.add(_solid);
    game.resetController.register(this);
  }

  @override
  void onRemove() {
    game.collisionWorld.solids.remove(_solid);
    game.resetController.unregister(this);
    super.onRemove();
  }

  @override
  void resetToStart() {
    position.y = _baseY;
    _solid.y = _baseY;
  }

  int get _load {
    var n = 0;
    for (final b in game.blocks) {
      if (!b.held && !b.clawHeld && b.aabb.overlaps(basket)) n++;
    }
    return n > 2 ? 2 : n;
  }

  @override
  void update(double dt) {
    final targetY = _baseY - _load * Config.tileSize * 1.5;
    final old = position.y;
    final step = dt * Config.tileSize * 1.5;
    position.y += (targetY - position.y).clamp(-step, step);
    final dy = position.y - old;
    if (dy == 0) return;
    _solid.y = position.y;
    // Carry riders.
    final riders = Aabb(_solid.x, _solid.y - dy - 8, _solid.w, 10);
    final player = game.player;
    if (!player.carried && riders.overlaps(player.aabb)) {
      player.position.y += dy;
    }
    for (final b in game.blocks) {
      if (!b.held && !b.clawHeld && riders.overlaps(b.aabb)) {
        b.carryBy(Vector2(0, dy));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final stroke = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    // Rope: platform → pulley at the ceiling → down to the basket.
    final pulley = Offset(size.x / 2, game.ceilingY - position.y + 6);
    final basketTop = Offset(
        basket.x + basket.w / 2 - position.x, basket.y - position.y);
    canvas.drawLine(Offset(size.x / 2, 0), pulley, stroke);
    canvas.drawLine(pulley, basketTop, stroke);
    canvas.drawCircle(pulley, 6, stroke);
    // Platform.
    final r = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6));
    canvas.drawRRect(r, Paint()..color = p.accentInteract);
    canvas.drawRRect(
      r,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.stroke,
    );
  }
}
