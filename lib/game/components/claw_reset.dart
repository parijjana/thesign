import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../escape_game.dart';
import 'player.dart';
import 'pushable_block.dart';

/// The excavator claw — the no-death promise made literal (GDD §8,
/// STYLE_GUIDE §8c), and the castle's general-purpose rescuer: it resets the
/// player AND fishes sunken blocks home. Nothing in this game teleports;
/// the claw carries it.
///
/// Player reset: descend (chasing, grab by AABB overlap) → scoop → lift →
/// carry → lower → place → WHIRLWIND (the actual state-reset beat) → retract.
/// Input locked, ~1.5s, abbreviated on rapid repeats.
///
/// Block rescue: same crane choreography, no whirlwind, and the player
/// KEEPS CONTROL — the claw is just doing its job in the background.
/// A player rescue always preempts a block job.
class ClawReset extends PositionComponent with HasGameReference<EscapeGame> {
  ClawReset() : super(priority: 100); // draws over room geometry

  static const _descendSpeed = 560.0; // px/s while chasing the target
  static const _grabTimeout = 1.4; // s — failsafe snap if the chase drags

  /// The claw hangs from the CURRENT node's ceiling (thin room roof or deep
  /// corridor mass) — never from the window edge.
  double get _ceilingY => game.ceilingY;

  _Phase _phase = _Phase.idle;
  _Mode _mode = _Mode.player;
  double _t = 0; // 0..1 within tweened phases
  double _phaseTime = 0;
  double _speed = 1;
  double _spin = 0;
  double _jaws = 0; // 0 open .. 1 closed

  Player? _player;
  PushableBlock? _block;
  Vector2 _start = Vector2.zero();
  final Vector2 _from = Vector2.zero();
  final Vector2 _to = Vector2.zero();
  void Function()? _onWhirlwind;
  void Function()? _onDone;

  bool get busy => _phase != _Phase.idle;

  /// The grab region hanging below the hinge — the target is caught when
  /// this overlaps its collision box.
  Aabb get _jawZone => Aabb(position.x - 11, position.y + 2, 22, 36);

  Aabb get _targetBox =>
      _mode == _Mode.player ? _player!.aabb : _block!.aabb;

  /// Where the cargo gets delivered (top-left).
  Vector2 get _dropPoint => _mode == _Mode.player
      ? _start
      : Vector2(_block!.homeTarget.x, _block!.homeTarget.y);

  double get _cargoWidth =>
      _mode == _Mode.player ? _player!.size.x : _block!.size.x;

  /// Starts a PLAYER reset: scoop [player] and carry it to [start].
  /// [abbreviated] speeds everything up on rapid repeats.
  void play({
    required Player player,
    required Vector2 start,
    required void Function() onWhirlwind,
    required void Function() onDone,
    bool abbreviated = false,
  }) {
    if (busy) return;
    _mode = _Mode.player;
    _player = player;
    _block = null;
    _start = start.clone();
    _onWhirlwind = onWhirlwind;
    _onDone = onDone;
    _speed = abbreviated ? 1.7 : 1.0;
    _begin(player.position.x + player.size.x / 2);
  }

  /// Starts a BLOCK rescue: fish [block] out (it waits waterlogged) and
  /// carry it home. No whirlwind, no input lock.
  void playBlockRescue({
    required PushableBlock block,
    required void Function() onDone,
  }) {
    if (busy) return;
    _mode = _Mode.block;
    _block = block;
    _player = null;
    _onWhirlwind = null;
    _onDone = onDone;
    _speed = 1.0;
    _begin(block.position.x + block.size.x / 2);
  }

  /// A player rescue preempts a block job: finish the block's trip
  /// instantly (fallback snap) and free the machine.
  void abortBlockJob() {
    if (!busy || _mode != _Mode.block) return;
    final b = _block;
    if (b != null) {
      if (b.clawHeld) {
        b.clawRelease(b.homeTarget);
      } else {
        b.waterlogged = false;
        b.rescueHome();
      }
    }
    _block = null;
    _phase = _Phase.idle;
    _onDone?.call();
  }

  void _begin(double targetCenterX) {
    _jaws = 0;
    position.setValues(targetCenterX, _ceilingY);
    _enter(_Phase.descend);
  }

  void _enter(_Phase next) {
    _phase = next;
    _t = 0;
    _phaseTime = 0;
    _from.setFrom(position);
    switch (next) {
      case _Phase.scoop:
        // Jaws are around the cargo: take ownership.
        if (_mode == _Mode.player) {
          _player!.carried = true; // kitten by the scruff
        } else {
          _block!.clawGrab();
        }
      case _Phase.lift:
        _to.setValues(position.x, _ceilingY + 20);
      case _Phase.carry:
        _to.setValues(_dropPoint.x + _cargoWidth / 2, _ceilingY + 20);
      case _Phase.lower:
        _to.setValues(_dropPoint.x + _cargoWidth / 2, _dropPoint.y - 6);
      case _Phase.whirlwind:
        _to.setValues(Config.viewportWidth / 2, Config.viewportHeight / 2);
      case _Phase.retract:
        _to.setValues(position.x, _ceilingY - 44); // up into the brickwork
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
    _phaseTime += dt * _speed;
    _spin += dt * (_phase == _Phase.whirlwind ? 26 : 0);

    if (_phase == _Phase.descend) {
      // CHASE the live target; the grab is decided by collision, not timer.
      final box = _targetBox;
      final target = Vector2(box.x + box.w / 2, box.y - 6);
      final delta = target - position;
      final step = _descendSpeed * _speed * dt;
      if (delta.length <= step) {
        position.setFrom(target);
      } else {
        position.add(delta.normalized()..scale(step));
      }
      if (_jawZone.overlaps(box) || _phaseTime > _grabTimeout) {
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

    // Cargo dangles from the jaws.
    final p = _player;
    if (p != null && p.carried) {
      // Gripped at the shoulders — kitten-by-the-scruff.
      p.position.setValues(position.x - p.size.x / 2, position.y + 12);
    }
    final b = _block;
    if (b != null && b.clawHeld) {
      b.position.setValues(position.x - b.size.x / 2, position.y + 10);
    }
  }

  void _advance() {
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
        if (_mode == _Mode.player) {
          final p = _player!;
          p.carried = false;
          p.teleport(_start); // grounded exactly at the node start
          _enter(_Phase.whirlwind);
          _onWhirlwind?.call(); // THE reset beat: bodies snap to start state
        } else {
          _block!.clawRelease(_block!.homeTarget);
          _enter(_Phase.retract); // no whirlwind for cargo runs
        }
      case _Phase.whirlwind:
        _enter(_Phase.retract);
      case _Phase.retract:
        _phase = _Phase.idle;
        _block = null;
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

    // Cable: from the node's ceiling underside straight down to the hinge,
    // with the trolley block embedded at the ceiling line.
    final ceilDy = _ceilingY - position.y; // negative while hanging below
    if (ceilDy < -4) {
      canvas.drawLine(Offset(0, ceilDy), Offset.zero, stroke);
      canvas.drawRRect(
        RRect.fromLTRBR(-9, ceilDy - 8, 9, ceilDy + 4,
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

enum _Mode { player, block }
