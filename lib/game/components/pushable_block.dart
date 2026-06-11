import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../core/interactable.dart';
import '../escape_game.dart';

/// A carryable block (the Carry verb, GDD §5): interact to pick up, interact
/// again to set down. Solid when placed (stand on it, stack it); falls and
/// settles under gravity when set down. M4 scope is carry-only — push
/// physics can come later if a puzzle needs it.
class PushableBlock extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Interactable {
  PushableBlock(Vector2 position, Vector2 size)
      : super(position: position, size: size);

  late final Aabb _solid = Aabb(position.x, position.y, size.x, size.y);
  bool held = false;
  bool _settled = true;
  double _vy = 0;

  Aabb get aabb => _solid;

  @override
  void onMount() {
    super.onMount();
    game.collisionWorld.solids.add(_solid);
    game.blocks.add(this);
    game.interactables.add(this);
  }

  @override
  void onRemove() {
    game.collisionWorld.solids.remove(_solid);
    game.blocks.remove(this);
    game.interactables.remove(this);
    super.onRemove();
  }

  @override
  Aabb get interactZone =>
      Aabb(position.x - 8, position.y - 6, size.x + 16, size.y + 12);

  /// Grabbable only when free-standing: not while something rests on it, and
  /// not while the player already has their hands full.
  @override
  bool get canInteract =>
      !held && _settled && !game.player.isCarrying && !_hasBlockOnTop;

  bool get _hasBlockOnTop {
    final probe = Aabb(_solid.x + 3, _solid.y - 4, _solid.w - 6, 4);
    return game.blocks
        .any((b) => b != this && !b.held && b.aabb.overlaps(probe));
  }

  @override
  void onInteract() => game.player.pickUp(this);

  void pickUp() {
    held = true;
    _settled = true;
    game.collisionWorld.solids.remove(_solid);
  }

  /// Sets the block down occupying [target]; it then falls until it rests.
  void placeAt(Aabb target) {
    held = false;
    _solid
      ..x = target.x
      ..y = target.y;
    position.setValues(target.x, target.y);
    game.collisionWorld.solids.add(_solid);
    _settled = false;
    _vy = 0;
  }

  @override
  void update(double dt) {
    if (held) {
      // Ride along above the carrier's head.
      final p = game.player;
      position.setValues(
        p.position.x + p.size.x / 2 - size.x / 2,
        p.position.y - size.y - 3,
      );
      return;
    }
    if (_settled) return;
    // Settle under gravity, colliding with everything but ourselves.
    _vy = (_vy + Config.gravity * dt).clamp(-900, 900);
    final others =
        game.collisionWorld.solids.where((s) => !identical(s, _solid));
    final dy = clipDy(_solid, _vy * dt, others);
    _solid.y += dy;
    position.setValues(_solid.x, _solid.y);
    if (dy != _vy * dt) {
      _vy = 0;
      _settled = true;
    }
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final r = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6));
    canvas.drawRRect(r, Paint()..color = p.accentInteract);
    canvas.drawRRect(
      r,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    // Grip marks.
    final grip = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final cx = size.x / 2;
    canvas.drawLine(Offset(cx - 6, size.y * 0.35), Offset(cx - 6, size.y * 0.65), grip);
    canvas.drawLine(Offset(cx + 6, size.y * 0.35), Offset(cx + 6, size.y * 0.65), grip);
  }
}
