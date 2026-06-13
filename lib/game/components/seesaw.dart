import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../core/reset_controller.dart';
import '../escape_game.dart';

/// The fulcrum seesaw (Mechanics): two thick pans on a pivot. Load **two
/// blocks** onto one pan and that side tips down while the other rises into
/// a high platform you can jump to. A clear, reliable threshold (2 blocks,
/// the player's own weight is ignored) — balance taught by doing.
class Seesaw extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Resettable {
  Seesaw(Vector2 pivot, {this.armHalf = 128, this.panWidth = 80})
      : super(position: pivot);

  final double armHalf;
  final double panWidth;
  static const _panH = 16.0; // thick enough to catch blocks reliably
  static const _swing = 48.0; // px each pan travels from level (1.5 tiles)

  double _tilt = 0; // -1 left-down .. +1 right-down

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
  void resetToStart() {
    _tilt = 0;
    _left.y = _panBox(-1, 0).y;
    _right.y = _panBox(1, 0).y;
  }

  /// Blocks (not the player) resting on a pan — the trigger weight.
  int _blocksOn(Aabb pan) {
    final zone = Aabb(pan.x, pan.y - 18, pan.w, 22);
    var n = 0;
    for (final b in game.blocks) {
      if (!b.held && !b.clawHeld && b.aabb.overlaps(zone)) n++;
    }
    return n;
  }

  @override
  void update(double dt) {
    final leftBlocks = _blocksOn(_left);
    final rightBlocks = _blocksOn(_right);
    final target = leftBlocks >= 2
        ? -1.0
        : rightBlocks >= 2
            ? 1.0
            : 0.0;
    final old = _tilt;
    _tilt += (target - _tilt).clamp(-dt * 1.4, dt * 1.4);
    if (_tilt == old) return;

    // Reposition each pan and carry whatever rides on it by the delta.
    for (final (side, pan) in [(-1, _left), (1, _right)]) {
      final fresh = _panBox(side, _tilt);
      final dy = fresh.y - pan.y;
      if (dy == 0) continue;
      final riders = Aabb(pan.x, pan.y - 10, pan.w, 12);
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
    final beam = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = Config.strokeHeavy
      ..strokeCap = StrokeCap.round;
    // Fulcrum triangle at the pivot.
    final tri = Path()
      ..moveTo(0, 0)
      ..lineTo(16, 34)
      ..lineTo(-16, 34)
      ..close();
    canvas.drawPath(tri, ink);
    // Beam from pivot to each pan centre-top.
    for (final pan in [_left, _right]) {
      canvas.drawLine(
        Offset.zero,
        Offset(pan.x + pan.w / 2 - position.x, pan.y - position.y),
        beam,
      );
    }
    // Pans (thick, with grip), drawn at their world positions.
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
