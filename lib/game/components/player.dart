import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../escape_game.dart';

/// The pictogram player (GDD.md §5, STYLE_GUIDE.md §5).
///
/// Kinematic AABB controller on a fixed 1/120s timestep: forgiving run,
/// single jump with coyote-time + jump-buffer + variable height, squash on
/// land. No momentum mastery required — think, don't twitch.
class Player extends PositionComponent with HasGameReference<EscapeGame> {
  Player() : super(size: Vector2(22, 50));

  static const _step = 1 / 120;
  static const _accel = 1900.0; // how fast vx approaches the target
  static const _maxFall = 720.0;
  static const _jumpCut = -130.0; // rise speed cap once jump is released

  final Vector2 velocity = Vector2.zero();
  bool grounded = false;

  /// While true (claw sequence), physics and input are suspended and the
  /// figure renders in the limp "carried" pose.
  bool carried = false;

  double _accumulator = 0;
  double _coyoteLeft = 0;
  double _bufferLeft = 0;
  double _squash = 0; // 1 → 0 land-squash envelope
  double _runPhase = 0;

  Aabb get aabb => Aabb(position.x, position.y, size.x, size.y);

  void teleport(Vector2 to) {
    position.setFrom(to);
    velocity.setZero();
    _coyoteLeft = 0;
    _bufferLeft = 0;
    _squash = 0;
  }

  @override
  void update(double dt) {
    if (carried) return; // the claw owns position and pose

    // Jump press is buffered here (the edge flag lasts one frame only).
    if (game.input.jumpPressed && !game.resetting) {
      _bufferLeft = Config.jumpBufferTime;
    }

    _accumulator += math.min(dt, 1 / 15); // clamp hitches, avoid the spiral
    while (_accumulator >= _step) {
      _physicsStep(_step);
      _accumulator -= _step;
    }

    // Visual envelopes run on frame time.
    _squash = math.max(0, _squash - dt * 6);
    if (grounded && velocity.x.abs() > 20) {
      _runPhase += dt * 11;
    } else {
      _runPhase = 0;
    }
  }

  void _physicsStep(double h) {
    final input = game.input;
    // Control locks during the claw sequence (physics keeps running).
    final axis = game.resetting ? 0.0 : input.moveAxis;

    // Horizontal: approach target speed (forgiving, no momentum mastery).
    final target = axis * Config.runSpeed;
    final dvx = target - velocity.x;
    final maxStep = _accel * h;
    velocity.x += dvx.clamp(-maxStep, maxStep);

    // Vertical: gravity, capped fall.
    velocity.y = math.min(velocity.y + Config.gravity * h, _maxFall);
    // Variable jump height: releasing jump caps the rise.
    if (!input.jumpHeld && velocity.y < _jumpCut) velocity.y = _jumpCut;

    // Grace timers.
    _coyoteLeft = grounded ? Config.coyoteTime : _coyoteLeft - h;
    _bufferLeft -= h;
    if (_bufferLeft > 0 && _coyoteLeft > 0) {
      velocity.y = Config.jumpVelocity;
      _bufferLeft = 0;
      _coyoteLeft = 0;
    }

    // Move & resolve.
    final box = aabb;
    final result = game.collisionWorld.move(box, velocity.x * h, velocity.y * h);
    position.setValues(box.x, box.y);

    if (result.hitX) velocity.x = 0;
    final wasAirborne = !grounded;
    if (result.hitY) {
      if (velocity.y > 0 && wasAirborne) _squash = 1; // landing thump
      velocity.y = 0;
    }
    grounded = game.collisionWorld.isGrounded(box);
  }

  // --- Rendering: posture-driven pictogram (no sprites) ---------------------

  @override
  void render(Canvas canvas) {
    final ink = game.palette.ink;
    final limb = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = ink;

    final w = size.x;
    final h = size.y;
    final cx = w / 2;

    canvas.save();
    // Squash about the feet; slight lean into the run.
    canvas.translate(cx, h);
    final sq = _squash * 0.16;
    canvas.scale(1 + sq * 0.8, 1 - sq);
    canvas.rotate(carried ? 0 : velocity.x / Config.runSpeed * 0.07);
    canvas.translate(-cx, -h);

    // Pose endpoints.
    final swing = math.sin(_runPhase * math.pi);
    Offset hip = Offset(cx, h * 0.60);
    Offset neck = Offset(cx, h * 0.28);
    Offset legL, legR, armL, armR;

    if (carried) {
      // Limp dangle, "kitten by the scruff": arms up, legs hanging.
      armL = Offset(cx - 6, h * 0.10);
      armR = Offset(cx + 6, h * 0.10);
      legL = Offset(cx - 4, h * 0.96);
      legR = Offset(cx + 5, h * 0.98);
    } else if (!grounded) {
      // Airborne tuck.
      armL = Offset(cx - 9, h * 0.36);
      armR = Offset(cx + 9, h * 0.36);
      legL = Offset(cx - 6, h * 0.82);
      legR = Offset(cx + 7, h * 0.86);
    } else if (velocity.x.abs() > 20) {
      // Run: scissoring limbs.
      legL = Offset(cx - 7 * swing, h * 0.97);
      legR = Offset(cx + 7 * swing, h * 0.97);
      armL = Offset(cx + 7 * swing, h * 0.52);
      armR = Offset(cx - 7 * swing, h * 0.52);
    } else {
      // Idle.
      legL = Offset(cx - 5, h * 0.97);
      legR = Offset(cx + 5, h * 0.97);
      armL = Offset(cx - 6, h * 0.54);
      armR = Offset(cx + 6, h * 0.54);
    }

    // Head, torso, limbs — a few thick ink strokes (silhouette first).
    canvas.drawCircle(Offset(cx, h * 0.13), w * 0.30, fill);
    canvas.drawLine(neck, hip, limb);
    canvas.drawLine(neck + const Offset(0, 3), armL, limb);
    canvas.drawLine(neck + const Offset(0, 3), armR, limb);
    canvas.drawLine(hip, legL, limb);
    canvas.drawLine(hip, legR, limb);

    canvas.restore();
  }
}
