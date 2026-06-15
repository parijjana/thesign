import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../core/reset_controller.dart';
import '../escape_game.dart';

/// Falling boulder (corridor hazard, GDD §7): waits armed in a ceiling slot
/// (visibly peeking — the telegraph), shakes briefly when the player passes
/// beneath, then drops. Contact = the claw rescue. On impact it **bounces
/// once and shatters** into shards that scatter and fade (never just a poof),
/// then re-arms. Resettable: whirlwind re-arms it instantly.
class Boulder extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Resettable {
  Boulder(Vector2 slotPosition, {this.radius = 14})
      : super(position: slotPosition.clone(), size: Vector2.all(28));

  final double radius;

  late final Vector2 _slot = position.clone();
  final _rng = math.Random();
  _BoulderState _state = _BoulderState.armed;
  double _t = 0;
  double _vy = 0;
  bool _bounced = false;
  double _squash = 0; // 1 → 0 on impact, flattens the ball briefly
  final List<_Shard> _shards = [];

  static const double _bounceSpeed = 230; // min impact speed that bounces
  static const double _shatterDur = 0.7;

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
    _bounced = false;
    _squash = 0;
    _shards.clear();
  }

  @override
  void update(double dt) {
    final player = game.player;
    _t += dt;
    if (_squash > 0) _squash = math.max(0, _squash - dt * 5);
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
        final intended = _vy * dt;
        final dy = clipDy(_box, intended, game.collisionWorld.solids);
        position.y += dy;
        if (!player.carried && _box.overlaps(player.aabb)) {
          game.requestReset();
        }
        // Hit the ground (downward move was clipped short).
        if (_vy > 0 && dy < intended - 0.01) {
          if (!_bounced && _vy > _bounceSpeed) {
            _vy = -_vy * 0.42; // bounce, losing most of its speed
            _bounced = true;
            _squash = 1;
          } else {
            _shatter();
          }
        }
      case _BoulderState.shatter:
        _updateShards(dt);
        if (_t > _shatterDur) {
          _state = _BoulderState.cooldown;
          _t = 0;
        }
      case _BoulderState.cooldown:
        if (_t > 1.3) resetToStart();
    }
  }

  void _shatter() {
    _state = _BoulderState.shatter;
    _t = 0;
    _squash = 1;
    _shards.clear();
    // A handful of angular chips flung up-and-out, then gravity takes them.
    final n = 6 + _rng.nextInt(2);
    for (var i = 0; i < n; i++) {
      final ang = -math.pi + (_rng.nextDouble() - 0.5) * math.pi * 0.9 +
          (i / n) * math.pi; // spread across the upper arc
      final speed = 90 + _rng.nextDouble() * 160;
      _shards.add(_Shard(
        pos: Offset(
            (_rng.nextDouble() - 0.5) * radius, (_rng.nextDouble() - 0.5) * radius),
        vel: Offset(math.cos(ang) * speed, math.sin(ang) * speed - 40),
        size: radius * (0.3 + _rng.nextDouble() * 0.35),
        rot: _rng.nextDouble() * math.pi,
        rotVel: (_rng.nextDouble() - 0.5) * 14,
      ));
    }
  }

  void _updateShards(double dt) {
    for (final s in _shards) {
      s.vel = Offset(s.vel.dx * (1 - dt * 0.6), s.vel.dy + 1400 * dt);
      s.pos += s.vel * dt;
      s.rot += s.rotVel * dt;
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

    if (_state == _BoulderState.cooldown) return; // shards already gone

    if (_state == _BoulderState.shatter) {
      final fade = (1 - _t / _shatterDur).clamp(0.0, 1.0);
      final fill = Paint()..color = p.accentDanger.withValues(alpha: fade);
      final ink = Paint()
        ..color = p.ink.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final s in _shards) {
        canvas.save();
        canvas.translate(s.pos.dx, s.pos.dy);
        canvas.rotate(s.rot);
        // A small 3-sided chip.
        final path = Path()
          ..moveTo(0, -s.size)
          ..lineTo(s.size * 0.9, s.size * 0.7)
          ..lineTo(-s.size * 0.8, s.size * 0.6)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, ink);
        canvas.restore();
      }
      return;
    }

    final shake = _state == _BoulderState.telegraph
        ? math.sin(_t * 60) * 2.0
        : 0.0;
    final peek = _state == _BoulderState.armed ? -radius * 0.4 : 0.0;
    final center = Offset(shake, peek);
    // Impact squash: flatten vertically, widen horizontally, briefly.
    final sx = 1 + _squash * 0.35;
    final sy = 1 - _squash * 0.3;
    canvas.save();
    canvas.translate(center.dx, center.dy + radius * _squash * 0.3);
    canvas.scale(sx, sy);
    canvas.drawCircle(Offset.zero, radius, Paint()..color = p.accentDanger);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.strokeHeavy,
    );
    canvas.restore();
  }
}

/// A flung chip of a shattered boulder.
class _Shard {
  _Shard({
    required this.pos,
    required this.vel,
    required this.size,
    required this.rot,
    required this.rotVel,
  });

  Offset pos;
  Offset vel;
  final double size;
  double rot;
  final double rotVel;
}

enum _BoulderState { armed, telegraph, falling, shatter, cooldown }
