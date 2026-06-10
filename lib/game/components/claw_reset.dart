import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../escape_game.dart';
import 'player.dart';

/// The excavator-claw reset — the no-death promise made literal
/// (GDD.md §8, STYLE_GUIDE.md §8c). Presentation ONLY: the actual state
/// mutation happens when this calls `onWhirlwind` (the whirlwind beat);
/// headless tests skip the claw and call the ResetController directly.
///
/// Beats: descend → scoop → lift/carry/lower → place → whirlwind → retract.
/// Brief (~1.5 s), sped up on rapid repeats. Cute, mechanical, never violent.
class ClawReset extends PositionComponent with HasGameReference<EscapeGame> {
  ClawReset() : super(priority: 100); // draws over room geometry

  static const _ceilingY = Config.tileSize * 0.5;

  _Phase _phase = _Phase.idle;
  double _t = 0; // 0..1 within the current phase
  double _speed = 1;
  double _spin = 0;

  Player? _player;
  Vector2 _start = Vector2.zero(); // node start (player top-left)
  final Vector2 _from = Vector2.zero();
  final Vector2 _to = Vector2.zero();
  double _jaws = 0; // 0 open .. 1 closed
  void Function()? _onWhirlwind;
  void Function()? _onDone;

  bool get busy => _phase != _Phase.idle;

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
    // Hinge starts at the ceiling above the player, jaws open.
    position.setValues(player.position.x + player.size.x / 2, _ceilingY);
    _enter(_Phase.descend);
  }

  void _enter(_Phase next) {
    _phase = next;
    _t = 0;
    _from.setFrom(position);
    switch (next) {
      case _Phase.descend:
        final p = _player!;
        _to.setValues(p.position.x + p.size.x / 2, p.position.y - 6);
      case _Phase.carry:
        _to.setValues(_start.x + _player!.size.x / 2, _ceilingY + 24);
      case _Phase.lower:
        _to.setValues(_start.x + _player!.size.x / 2, _start.y - 6);
      case _Phase.whirlwind:
        _to.setValues(Config.viewportWidth / 2, Config.viewportHeight / 2);
      case _Phase.retract:
        _to.setValues(position.x, -Config.tileSize);
      case _Phase.idle || _Phase.scoop || _Phase.place:
        _to.setFrom(position);
    }
  }

  double _duration(_Phase p) => switch (p) {
        _Phase.descend => 0.30,
        _Phase.scoop => 0.14,
        _Phase.carry => 0.45,
        _Phase.lower => 0.22,
        _Phase.place => 0.14,
        _Phase.whirlwind => 0.40,
        _Phase.retract => 0.22,
        _Phase.idle => 1,
      };

  static double _ease(double t) => t * t * (3 - 2 * t); // smoothstep

  @override
  void update(double dt) {
    if (_phase == _Phase.idle) return;
    _t = math.min(1, _t + dt * _speed / _duration(_phase));
    _spin += dt * (_phase == _Phase.whirlwind ? 26 : 0);

    // Hinge motion.
    final k = _ease(_t);
    position.setValues(
      _from.x + (_to.x - _from.x) * k,
      _from.y + (_to.y - _from.y) * k,
    );

    // Jaw motion.
    _jaws = switch (_phase) {
      _Phase.scoop => _t,
      _Phase.place => 1 - _t,
      _Phase.carry || _Phase.lower => 1,
      _ => _jaws,
    };

    // The scooped player dangles from the jaws.
    final p = _player;
    if (p != null && p.carried) {
      p.position.setValues(position.x - p.size.x / 2, position.y + 8);
    }

    if (_t >= 1) _advance();
  }

  void _advance() {
    final p = _player!;
    switch (_phase) {
      case _Phase.descend:
        _enter(_Phase.scoop);
      case _Phase.scoop:
        p.carried = true; // gotcha — kitten by the scruff
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
      case _Phase.idle:
        break;
    }
  }

  // --- Rendering -------------------------------------------------------------

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

    canvas.save();
    canvas.translate(position.x, position.y);

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
      canvas.restore();
      return;
    }

    // Cable up to the ceiling, hinge, two jaws.
    canvas.drawLine(Offset(0, _ceilingY - position.y), Offset.zero, stroke);
    canvas.drawCircle(Offset.zero, 7, fill);

    // Jaws: open spread ±55°, closed ±18° (around straight-down).
    final spread = (55 - 37 * _jaws) * math.pi / 180;
    for (final side in const [-1, 1]) {
      canvas.save();
      canvas.rotate(side * spread);
      final jaw = Path()
        ..moveTo(0, 4)
        ..quadraticBezierTo(side * 6.0, 16, side * 2.0, 30)
        ..quadraticBezierTo(side * 1.0, 33, -side * 3.0, 31);
      canvas.drawPath(jaw, stroke);
      canvas.restore();
    }
    canvas.restore();
  }
}

enum _Phase { idle, descend, scoop, carry, lower, place, whirlwind, retract }
