import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../core/reset_controller.dart';
import '../escape_game.dart';

/// Falling boulder (corridor hazard, GDD §7): waits armed in a ceiling slot
/// (visibly peeking — the telegraph), shakes briefly when the player passes
/// beneath, then drops. Contact = the claw rescue. Lands with a poof and
/// re-arms. Resettable: whirlwind re-arms it instantly.
class Boulder extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Resettable {
  Boulder(Vector2 slotPosition, {this.radius = 14})
      : super(position: slotPosition.clone(), size: Vector2.all(28));

  final double radius;

  late final Vector2 _slot = position.clone();
  _BoulderState _state = _BoulderState.armed;
  double _t = 0;
  double _vy = 0;

  Aabb get _box =>
      Aabb(position.x - radius, position.y - radius, radius * 2, radius * 2);

  @override
  void onMount() {
    super.onMount();
    game.resetController.register(this);
  }

  @override
  void onRemove() {
    game.resetController.unregister(this);
    super.onRemove();
  }

  @override
  void resetToStart() {
    _state = _BoulderState.armed;
    position.setFrom(_slot);
    _vy = 0;
    _t = 0;
  }

  @override
  void update(double dt) {
    final player = game.player;
    _t += dt;
    switch (_state) {
      case _BoulderState.armed:
        final px = player.position.x + player.size.x / 2;
        if ((px - position.x).abs() < Config.tileSize * 1.5 &&
            player.position.y > position.y) {
          _state = _BoulderState.telegraph;
          _t = 0;
        }
      case _BoulderState.telegraph:
        if (_t > 0.35) {
          _state = _BoulderState.falling;
          _vy = 0;
        }
      case _BoulderState.falling:
        _vy = math.min(_vy + Config.gravity * dt, 800);
        final dy = clipDy(_box, _vy * dt, game.collisionWorld.solids);
        position.y += dy;
        if (!player.carried && _box.overlaps(player.aabb)) {
          game.requestReset();
        }
        if (dy < _vy * dt) {
          _state = _BoulderState.landed;
          _t = 0;
        }
      case _BoulderState.landed:
        if (_t > 0.4) {
          _state = _BoulderState.cooldown;
          _t = 0;
        }
      case _BoulderState.cooldown:
        if (_t > 2.2) resetToStart();
    }
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    // Ceiling slot notch (always visible — the promise of danger).
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(0, _slot.y - position.y - radius + 2),
          width: radius * 2 + 8,
          height: 8),
      Paint()..color = p.ink,
    );
    if (_state == _BoulderState.cooldown) return; // poofed away

    final shake = _state == _BoulderState.telegraph
        ? math.sin(_t * 60) * 2.0
        : 0.0;
    final fade = _state == _BoulderState.landed
        ? (1 - _t / 0.4).clamp(0.0, 1.0)
        : 1.0;
    final peek = _state == _BoulderState.armed ? -radius * 0.4 : 0.0;
    final center = Offset(shake, peek);
    canvas.drawCircle(
        center, radius, Paint()..color = p.accentDanger.withValues(alpha: fade));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = p.ink.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.strokeHeavy,
    );
  }
}

enum _BoulderState { armed, telegraph, falling, landed, cooldown }
