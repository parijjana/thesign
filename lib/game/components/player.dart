import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../escape_game.dart';
import '../powerups.dart';
import '../ui/feedback_popups.dart';
import 'pushable_block.dart';

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

  /// The block in our arms, if any (the Carry verb — GDD §5, one object max).
  PushableBlock? carrying;
  bool get isCarrying => carrying != null;

  /// Which way the figure faces (placement direction); +1 right, -1 left.
  int facing = 1;

  /// Set TRUE each frame by a WaterPool the player overlaps (and only when
  /// the player owns Flippers — otherwise water resets, it doesn't submerge).
  /// Drives swim physics + the paddling pose. Self-clears each step.
  bool inWater = false;

  double _accumulator = 0;
  double _coyoteLeft = 0;
  double _bufferLeft = 0;
  int _jumpsUsed = 0; // for double jump (spring boots)
  double _squash = 0; // 1 → 0 land-squash envelope
  double _runPhase = 0;
  double _swimPhase = 0;

  // Climb-out (mantle): clamber from water onto an adjacent ledge instead of
  // needing a ramp. A short scripted move from the water to standing on top.
  bool _climbing = false;
  double _climbT = 0;
  final Vector2 _climbFrom = Vector2.zero();
  final Vector2 _climbTo = Vector2.zero();
  static const double _climbDur = 0.4;

  // Carried-pose pendulum: the claw grips the scruff; the body swings
  // beneath, driven by the claw's own acceleration.
  double _dangle = 0; // rad
  double _dangleVel = 0;
  double _prevX = 0;
  double _prevVx = 0;
  bool _wasCarried = false;

  Aabb get aabb => Aabb(position.x, position.y, size.x, size.y);

  void teleport(Vector2 to) {
    position.setFrom(to);
    velocity.setZero();
    _coyoteLeft = 0;
    _bufferLeft = 0;
    _squash = 0;
    _climbing = false;
  }

  /// Pick up a block (called by the block's onInteract).
  void pickUp(PushableBlock block) {
    if (isCarrying || carried) return;
    carrying = block;
    block.pickUp();
  }

  /// Set the carried block down in front of us; tries ground level first,
  /// then one and two block-heights up (which is how stacking works).
  void tryPlace() {
    final block = carrying;
    if (block == null) return;
    final bw = block.size.x;
    final bh = block.size.y;
    final baseX =
        facing > 0 ? position.x + size.x + 3 : position.x - bw - 3;
    final baseY = position.y + size.y - bh;
    for (final lift in [0.0, bh, bh * 2]) {
      final target = Aabb(baseX, baseY - lift, bw, bh);
      final blocked = game.collisionWorld.solids.any(target.overlaps) ||
          target.overlaps(aabb);
      if (!blocked) {
        carrying = null;
        block.placeAt(target);
        return;
      }
    }
    // Nowhere to put it — say so, wordlessly.
    game.feedback.emit(
      FeedbackKind.error,
      Vector2(position.x + size.x / 2, position.y - 16),
    );
  }

  /// Drop the carried block where we stand (used when the claw grabs us).
  void _dropCarried() {
    final block = carrying;
    if (block == null) return;
    carrying = null;
    block.placeAt(Aabb(
        position.x + size.x / 2 - block.size.x / 2, position.y, block.size.x,
        block.size.y));
  }

  @override
  void update(double dt) {
    if (carried) {
      // The claw owns position; we own the limp sway.
      if (!_wasCarried) {
        _dropCarried(); // hands open when the claw grabs us
        // Just grabbed: inherit a bit of swing from our momentum.
        _dangle = 0;
        _dangleVel = (velocity.x / 250).clamp(-0.5, 0.5);
        _prevX = position.x;
        _prevVx = 0;
        _wasCarried = true;
      }
      _updateDangle(dt);
      return;
    }
    _wasCarried = false;
    _dangle = 0;
    _dangleVel = 0;

    // Jump press is buffered here (the edge flag lasts one frame only).
    if (game.input.jumpPressed && !game.resetting) {
      _bufferLeft = Config.jumpBufferTime;
    }

    // Submerged? (Only with Flippers — otherwise water resets, see WaterPool.)
    inWater = game.hasPowerup(Powerup.flippers) &&
        game.waterPools.any((w) => w.surface.overlaps(aabb));

    // Climb-out: clamber from water onto a bank (a scripted move that owns the
    // body while it plays — so no ramp is needed to exit a pool).
    if (_climbing) {
      _advanceClimb(dt);
      return;
    }
    if (inWater && !game.resetting && !isCarrying) {
      final to = _climbTarget();
      if (to != null) {
        _climbing = true;
        _climbT = 0;
        _climbFrom.setFrom(position);
        _climbTo.setFrom(to);
        velocity.setZero();
        _advanceClimb(dt);
        return;
      }
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
    if (inWater) _swimPhase += dt * 5;
  }

  /// Damped pendulum about the grip point, driven by the pivot's horizontal
  /// acceleration — the body trails the claw's motion and settles when still.
  void _updateDangle(double dt) {
    if (dt <= 0) return;
    final vx = (position.x - _prevX) / dt;
    final ax = (vx - _prevVx) / dt;
    _prevX = position.x;
    _prevVx = vx;
    const omega2 = 30.0; // g/L stiffness
    const damping = 4.5;
    const drive = 1 / 130.0; // how strongly pivot accel swings the body
    _dangleVel += (-omega2 * _dangle - damping * _dangleVel - ax * drive) * dt;
    _dangle = (_dangle + _dangleVel * dt).clamp(-0.7, 0.7);
  }

  void _physicsStep(double h) {
    final input = game.input;
    // Control locks during the claw sequence (physics keeps running).
    final axis = game.resetting ? 0.0 : input.moveAxis;
    if (axis > 0) facing = 1;
    if (axis < 0) facing = -1;

    if (inWater) {
      _swimStep(h, axis);
      return;
    }

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
    final canGround = _bufferLeft > 0 && _coyoteLeft > 0;
    final canDouble = _bufferLeft > 0 &&
        !grounded &&
        _jumpsUsed >= 1 &&
        _jumpsUsed < 2 &&
        game.hasPowerup(Powerup.springBoots);
    if (canGround || canDouble) {
      // Carrying a block limits jump height (GDD §5 — a puzzle lever).
      velocity.y =
          Config.jumpVelocity * (isCarrying ? Config.carryJumpFactor : 1);
      _jumpsUsed = canGround ? 1 : _jumpsUsed + 1;
      if (canDouble) _squash = 0.6; // a little spring flourish
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
    if (grounded) _jumpsUsed = 0;
  }

  /// Swimming (Flippers powerup): 4-directional, slow, gently buoyant — the
  /// figure floats rather than sinks (no drowning, ever). Jump = stroke up.
  void _swimStep(double h, double axis) {
    final input = game.input;
    grounded = false;
    _jumpsUsed = 0;

    // Horizontal: slower than running, with drag.
    final target = axis * Config.swimSpeed;
    velocity.x += (target - velocity.x).clamp(-_accel * h, _accel * h);

    // Vertical: buoyancy pulls gently up; holding jump strokes up harder;
    // otherwise a slow sink. Always damped so it feels like water.
    final up = (input.jumpHeld && !game.resetting) ? -Config.swimStroke : 0.0;
    velocity.y += (Config.swimBuoyancy + up - velocity.y * 3.0) * h;
    velocity.y = velocity.y.clamp(-Config.swimSpeed, Config.swimSpeed * 0.8);

    final box = aabb;
    final result = game.collisionWorld.move(box, velocity.x * h, velocity.y * h);
    position.setValues(box.x, box.y);
    if (result.hitX) velocity.x = 0;
    if (result.hitY) velocity.y = 0;
    grounded = game.collisionWorld.isGrounded(box);
    if (grounded) _jumpsUsed = 0;
  }

  /// Eased clamber from the water to standing on the ledge: y leads (pull up),
  /// x lags (swing over), so it reads as a climb, not a slide.
  void _advanceClimb(double dt) {
    _climbT += dt;
    final t = (_climbT / _climbDur).clamp(0.0, 1.0);
    final xt = t * t; // x lags — swing over last
    final yt = 1 - (1 - t) * (1 - t); // y leads — pull up first
    position.x = _climbFrom.x + (_climbTo.x - _climbFrom.x) * xt;
    position.y = _climbFrom.y + (_climbTo.y - _climbFrom.y) * yt;
    if (t >= 1) {
      _climbing = false;
      position.setFrom(_climbTo);
      velocity.setZero();
      grounded = true;
      _jumpsUsed = 0;
      _coyoteLeft = Config.coyoteTime;
      inWater = false;
    }
  }

  /// While swimming and pressing toward an adjacent ledge whose top is within
  /// reach (and which has clear standing room), returns where to clamber to —
  /// the climb-out that replaces "add a ramp" for getting out of water.
  Vector2? _climbTarget() {
    final axis = game.input.moveAxis;
    if (axis == 0) return null;
    final dir = axis > 0 ? 1 : -1;
    final box = aabb;
    final feetY = box.bottom;
    const maxClimb = Config.tileSize * 2.0; // up to ~2 tiles above the feet
    const reach = Config.tileSize * 0.55; // how far ahead to look
    for (final s in game.collisionWorld.solids) {
      final ahead = dir > 0
          ? (s.left >= box.right - 2 && s.left <= box.right + reach)
          : (s.right <= box.left + 2 && s.right >= box.left - reach);
      if (!ahead) continue;
      if (s.top > feetY + 8 || s.top < feetY - maxClimb) continue; // out of band
      final landX = dir > 0 ? s.left + 2 : s.right - size.x - 2;
      final landY = s.top - size.y;
      final landing = Aabb(landX, landY, size.x, size.y);
      final blocked = game.collisionWorld.solids
          .any((o) => !identical(o, s) && o.overlaps(landing));
      if (blocked) continue; // no headroom / something in the way
      return Vector2(landX, landY);
    }
    return null;
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
    if (carried) {
      // Hang from the scruff: the figure pendulums about the shoulder-line
      // grip point, so the body sways below and the head tips gently above.
      final px = cx;
      final py = h * 0.26;
      canvas.translate(px, py);
      canvas.rotate(_dangle);
      canvas.translate(-px, -py);
    } else {
      // Squash about the feet; slight lean into the run.
      canvas.translate(cx, h);
      final sq = _squash * 0.16;
      canvas.scale(1 + sq * 0.8, 1 - sq);
      canvas.rotate(velocity.x / Config.runSpeed * 0.07);
      canvas.translate(-cx, -h);
    }

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
    } else if (isCarrying) {
      // Arms up, holding the block overhead; legs keep working.
      armL = Offset(cx - 7, h * 0.02);
      armR = Offset(cx + 7, h * 0.02);
      if (grounded && velocity.x.abs() > 20) {
        legL = Offset(cx - 7 * swing, h * 0.97);
        legR = Offset(cx + 7 * swing, h * 0.97);
      } else if (!grounded) {
        legL = Offset(cx - 6, h * 0.84);
        legR = Offset(cx + 7, h * 0.88);
      } else {
        legL = Offset(cx - 5, h * 0.97);
        legR = Offset(cx + 5, h * 0.97);
      }
    } else if (_climbing) {
      // Clamber: lean forward, both arms reach up onto the ledge, legs trail.
      // M7.5: this currently "supermans" (flat, arms out) — redo as a weighty
      // grab-lip / plant-knee / push-up clamber (ROADMAP M7.5 motion polish).
      final f = facing.toDouble();
      hip = Offset(cx + f * 3, h * 0.55);
      neck = Offset(cx + f * 6, h * 0.30);
      armL = Offset(cx + f * 12, h * 0.10);
      armR = Offset(cx + f * 9, h * 0.22);
      legL = Offset(cx - f * 6, h * 0.92);
      legR = Offset(cx - f * 10, h * 0.84);
    } else if (inWater) {
      // Treading water: arms scull, legs flutter — floating, never sinking.
      final paddle = math.sin(_swimPhase);
      armL = Offset(cx - 9 - 3 * paddle, h * 0.46);
      armR = Offset(cx + 9 + 3 * paddle, h * 0.46);
      legL = Offset(cx - 6 + 4 * paddle, h * 0.9);
      legR = Offset(cx + 6 - 4 * paddle, h * 0.9);
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
