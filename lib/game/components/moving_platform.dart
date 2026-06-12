import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../core/reset_controller.dart';
import '../escape_game.dart';

/// A solid platform riding a ping-pong path. Carries the player and settled
/// blocks standing on it. Resettable: the whirlwind snaps it to its start.
class MovingPlatform extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Resettable {
  MovingPlatform(Vector2 position, Vector2 size,
      {required this.path, required this.speed})
      : super(position: position, size: size);

  /// Waypoints in px (the authored position is the implicit first point).
  final List<Vector2> path;
  final double speed;

  late final List<Vector2> _points = [position.clone(), ...path];
  late final Aabb _solid = Aabb(position.x, position.y, size.x, size.y);
  int _target = 1;
  int _dir = 1;

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
    position.setFrom(_points.first);
    _solid
      ..x = position.x
      ..y = position.y;
    _target = 1;
    _dir = 1;
  }

  @override
  void update(double dt) {
    if (_points.length < 2) return;
    final goal = _points[_target];
    final delta = goal - position;
    final step = speed * dt;
    Vector2 moved;
    if (delta.length <= step) {
      moved = delta.clone();
      position.setFrom(goal);
      // Ping-pong.
      if (_target + _dir < 0 || _target + _dir >= _points.length) _dir = -_dir;
      _target += _dir;
    } else {
      moved = (delta.normalized())..scale(step);
      position.add(moved);
    }
    _solid
      ..x = position.x
      ..y = position.y;
    _carryRiders(moved);
  }

  void _carryRiders(Vector2 delta) {
    if (delta.length2 == 0) return;
    final top = _solid.y;
    bool riding(Aabb box) =>
        (box.bottom - top).abs() <= 3 &&
        box.x < _solid.right &&
        box.right > _solid.x;
    final player = game.player;
    if (!player.carried && riding(player.aabb)) player.position.add(delta);
    for (final b in game.blocks) {
      if (!b.held && !b.clawHeld && riding(b.aabb)) b.carryBy(delta);
    }
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final r = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(7));
    canvas.drawRRect(r, Paint()..color = p.surface);
    canvas.drawRRect(
      r,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    // Motion arrows (visible track rule: motion must be telegraphed).
    final ink = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final cy = size.y / 2;
    for (final cx in [size.x * 0.3, size.x * 0.5, size.x * 0.7]) {
      canvas.drawLine(Offset(cx - 4, cy), Offset(cx + 3, cy), ink);
      canvas.drawLine(Offset(cx, cy - 3), Offset(cx + 3, cy), ink);
      canvas.drawLine(Offset(cx, cy + 3), Offset(cx + 3, cy), ink);
    }
  }
}
