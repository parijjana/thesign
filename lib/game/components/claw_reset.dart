import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../escape_game.dart';
import 'player.dart';

/// The excavator-claw reset — the no-death promise made literal
/// (GDD.md §8, STYLE_GUIDE.md §8c). Presentation ONLY: the actual state
/// mutation happens when this calls `onWhirlwind` (the whirlwind beat);
/// headless tests skip the claw and call the ResetController directly.
///
/// Crane-like beats: descend (chasing the live player, grab detected by AABB
/// overlap) → scoop → lift straight up → carry along the ceiling → lower →
/// place → whirlwind → retract. Brief, sped up on rapid repeats. Cute,
/// mechanical, never violent.
class ClawReset extends PositionComponent with HasGameReference<EscapeGame> {
  ClawReset() : super(priority: 100); // draws over room geometry

  static const _ceilingY = Config.tileSize * 0.75; // hinge's "home" height
  static const _descendSpeed = 560.0; // px/s while chasing the player
  static const _grabTimeout = 1.4; // s — failsafe snap if the chase drags

  _Phase _phase = _Phase.idle;
  double _t = 0; // 0..1 within tweened phases
  double _phaseTime = 0;
  double _speed = 1;
  double _spin = 0;
  double _jaws = 0; // 0 open .. 1 closed

  Player? _player;
  Vector2 _start = Vector2.zero();
  final Vector2 _from = Vector2.zero();
  final Vector2 _to = Vector2.zero();
  void Function()? _onWhirlwind;
  void Function()? _onDone;

  bool get busy => _phase != _Phase.idle;

  /// The grab region hanging below the hinge — the claw has caught the player
  /// when this overlaps the player's collision box.
  Aabb get _jawZone => Aabb(position.x - 11, position.y + 2, 22, 36);

  /// Starts the sequence: scoop [player] and carry it to [start].
  /// [abbreviated] speeds everything up on rapid repeats.
  void play({
    required Player player,
    required Vector2 start,
    required void Function() onWhirlwind,
    required void Function() onDone,
    bool abbreviated = false,
  }) {
    if (busy) return;
    _player = player;
    _start = start.clone();
    _onWhirlwind = onWhirlwind;
    _onDone = onDone;
    _speed = abbreviated ? 1.7 : 1.0;
    _jaws = 0;
    // Emerges from the ceiling directly above the player.
    position.setValues(player.position.x + player.size.x / 2, _ceilingY);
    _enter(_Phase.descend);
  }

  void _enter(_Phase next) {
    _phase = next;
    _t = 0;
    _phaseTime = 0;
    _from.setFrom(position);
    final p = _player;
    switch (next) {
      case _Phase.scoop:
        // Jaws are around the player: freeze & take ownership of the figure.
        p!.carried = true;
      case _Phase.lift:
        _to.setValues(position.x, _ceilingY + 20);
      case _Phase.carry:
        _to.setValues(_start.x + p!.size.x / 2, _ceilingY + 20);
      case _Phase.lower:
        _to.setValues(_start.x + p!.size.x / 2, _start.y - 6);
      case _Phase.whirlwind:
        _to.setValues(Config.viewportWidth / 2, Config.viewportHeight / 2);
      case _Phase.retract:
        _to.setValues(position.x, -Config.tileSize);
      case _Phase.idle || _Phase.descend || _Phase.place:
        _to.setFrom(position);
    }
  }

  double _duration(_Phase p) => switch (p) {
        _Phase.scoop => 0.14,
        _Phase.lift => 0.45, // an unhurried hoist — it's a crane, not a yo-yo
        _Phase.carry => 0.42,
        _Phase.lower => 0.22,
        _Phase.place => 0.14,
        _Phase.whirlwind => 0.40,
        _Phase.retract => 0.22,
        _Phase.idle || _Phase.descend => 1,
      };

  static double _ease(double t) => t * t * (3 - 2 * t); // smoothstep

  @override
  void update(double dt) {
    if (_phase == _Phase.idle) return;
    final p = _player!;
    _phaseTime += dt * _speed;
    _spin += dt * (_phase == _Phase.whirlwind ? 26 : 0);

    if (_phase == _Phase.descend) {
      // CHASE the live player (it may still be falling); the grab is decided
      // by collision, not by a timer.
      final target = Vector2(
        p.position.x + p.size.x / 2,
        p.position.y - 6,
      );
      final delta = target - position;
      final step = _descendSpeed * _speed * dt;
      if (delta.length <= step) {
        position.setFrom(target);
      } else {
        position.add(delta.normalized()..scale(step));
      }
      if (_jawZone.overlaps(p.aabb) || _phaseTime > _grabTimeout) {
        if (_phaseTime > _grabTimeout) position.setFrom(target); // failsafe
        _enter(_Phase.scoop);
      }
    } else {
      // Tweened phases.
      _t = math.min(1, _t + dt * _speed / _duration(_phase));
      final k = _ease(_t);
      position.setValues(
        _from.x + (_to.x - _from.x) * k,
        _from.y + (_to.y - _from.y) * k,
      );
      if (_t >= 1) _advance();
    }

    // Jaw motion.
    _jaws = switch (_phase) {
      _Phase.scoop => _t,
      _Phase.place => 1 - _t,
      _Phase.lift || _Phase.carry || _Phase.lower => 1,
      _ => _jaws,
    };

    // The scooped player dangles from the jaws, gripped at the shoulders —
    // the jaw tips reach the neck line, kitten-by-the-scruff.
    if (p.carried) {
      p.position.setValues(position.x - p.size.x / 2, position.y + 12);
    }
  }

  void _advance() {
    final p = _player!;
    switch (_phase) {
      case _Phase.scoop:
        _enter(_Phase.lift);
      case _Phase.lift:
        _enter(_Phase.carry);
      case _Phase.carry:
        _enter(_Phase.lower);
      case _Phase.lower:
        _enter(_Phase.place);
      case _Phase.place:
        p.carried = false;
        p.teleport(_start); // grounded exactly at the node start
        _enter(_Phase.whirlwind);
        _onWhirlwind?.call(); // THE reset beat: bodies snap to start state
      case _Phase.whirlwind:
        _enter(_Phase.retract);
      case _Phase.retract:
        _phase = _Phase.idle;
        _onDone?.call();
      case _Phase.idle || _Phase.descend:
        break;
    }
  }

  // --- Rendering (local coordinates: origin = the hinge) ---------------------

  @override
  void render(Canvas canvas) {
    if (_phase == _Phase.idle) return;
    final ink = game.palette.ink;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = ink;

    if (_phase == _Phase.whirlwind) {
      // The tidy-up tornado: nested spinning arcs.
      for (var i = 0; i < 3; i++) {
        final r = 14.0 + i * 9;
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r),
          _spin * (i.isEven ? 1 : -1) + i,
          math.pi * 1.3,
          false,
          stroke,
        );
      }
      return;
    }

    // Cable: from the room ceiling straight down to the hinge.
    if (position.y > 6) {
      canvas.drawLine(Offset(0, 4 - position.y), Offset.zero, stroke);
      // Trolley block at the ceiling the cable hangs from.
      canvas.drawRRect(
        RRect.fromLTRBR(-9, 2 - position.y, 9, 12 - position.y,
            const Radius.circular(3)),
        fill,
      );
    }
    // Hinge.
    canvas.drawCircle(Offset.zero, 7, fill);

    // Jaws: open spread ±55°, closed ±18° (around straight-down).
    // Note the negated rotation: with y-down canvas coords, +θ would swing
    // the right-side jaw left and turn the claw inside out.
    final spread = (55 - 37 * _jaws) * math.pi / 180;
    for (final side in const [-1, 1]) {
      canvas.save();
      canvas.rotate(-side * spread);
      final jaw = Path()
        ..moveTo(0, 4)
        ..quadraticBezierTo(side * 6.0, 16, side * 2.0, 30)
        ..quadraticBezierTo(side * 1.0, 33, -side * 3.0, 31);
      canvas.drawPath(jaw, stroke);
      canvas.restore();
    }
  }
}

enum _Phase { idle, descend, scoop, lift, carry, lower, place, whirlwind, retract }
