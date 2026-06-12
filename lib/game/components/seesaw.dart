import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../core/reset_controller.dart';
import '../escape_game.dart';

/// The fulcrum seesaw (Mechanics P3): two pans on a pivot. Weight (player=1,
/// each settled block=1) tilts the beam; the lighter pan rises ~0.75 tile.
/// Stand on one pan and load the other to ride up — balance, taught by foot.
class Seesaw extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Resettable {
  Seesaw(Vector2 pivot, {this.armHalf = 80, this.panWidth = 48})
      : super(position: pivot);

  final double armHalf;
  final double panWidth;
  static const _panH = 12.0;
  static const _swing = 24.0; // px each pan moves from level at full tilt

  double _tilt = 0; // -1 left-heavy .. +1 right-heavy

  late final Aabb _left = _panBox(-1, 0);
  late final Aabb _right = _panBox(1, 0);

  Aabb _panBox(int side, double tilt) => Aabb(
        position.x + side * armHalf - panWidth / 2,
        position.y + side * tilt * _swing - _panH,
        panWidth,
        _panH,
      );

  @override
  void onMount() {
    super.onMount();
    game.collisionWorld.solids.addAll([_left, _right]);
    game.resetController.register(this);
  }

  @override
  void onRemove() {
    game.collisionWorld.solids.removeWhere(
        (s) => identical(s, _left) || identical(s, _right));
    game.resetController.unregister(this);
    super.onRemove();
  }

  @override
  void resetToStart() => _tilt = 0;

  int _weightOn(Aabb pan) {
    var w = 0;
    final zone = Aabb(pan.x, pan.y - 6, pan.w, 8);
    final player = game.player;
    if (!player.carried &&
        player.grounded &&
        zone.overlaps(player.aabb)) {
      w += player.isCarrying ? 2 : 1; // a carried block counts on your side
    }
    for (final b in game.blocks) {
      if (!b.held && !b.clawHeld && zone.overlaps(b.aabb)) w++;
    }
    return w;
  }

  @override
  void update(double dt) {
    final target =
        (_weightOn(_right) - _weightOn(_left)).clamp(-1, 1).toDouble();
    final old = _tilt;
    final step = dt * 1.6;
    _tilt += (target - _tilt).clamp(-step, step);
    if (_tilt == old) return;

    // Reposition pans and carry their riders by the delta.
    for (final (side, pan) in [(-1, _left), (1, _right)]) {
      final fresh = _panBox(side, _tilt);
      final dy = fresh.y - pan.y;
      if (dy == 0) continue;
      final riders = Aabb(pan.x, pan.y - 8, pan.w, 10);
      pan.y = fresh.y;
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
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final ink = Paint()..color = p.ink;
    final stroke = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = Config.strokeHeavy
      ..strokeCap = StrokeCap.round;
    // Fulcrum triangle (we render at the pivot; pans are in world coords).
    final base = Offset.zero;
    final tri = Path()
      ..moveTo(base.dx, base.dy)
      ..lineTo(base.dx + 16, base.dy + 30)
      ..lineTo(base.dx - 16, base.dy + 30)
      ..close();
    canvas.drawPath(tri, ink);
    // The arm: pivot to each pan center-top.
    for (final pan in [_left, _right]) {
      canvas.drawLine(
        base,
        Offset(pan.x + pan.w / 2 - position.x, pan.y - position.y),
        stroke,
      );
    }
    // Pans.
    for (final pan in [_left, _right]) {
      final r = RRect.fromLTRBR(
        pan.x - position.x,
        pan.y - position.y,
        pan.right - position.x,
        pan.bottom - position.y,
        const Radius.circular(5),
      );
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
}
