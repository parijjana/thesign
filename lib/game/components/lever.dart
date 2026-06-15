import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/aabb.dart';
import '../core/interactable.dart';
import '../escape_game.dart';

/// How a lever reads at a glance:
/// - [goal]: the castle's one door lever — thin angled handle, teal knob. Every
///   exit door is opened by one of these (PUZZLES.md), so the look is reserved.
/// - [fireman]: a puzzle-input lever — a chunky knife-switch silhouette, so it
///   reads as "part of the puzzle", not "the lever that opens the door".
enum LeverStyle {
  goal,
  fireman;

  static LeverStyle fromId(String? id) => switch (id) {
        'fireman' => LeverStyle.fireman,
        _ => LeverStyle.goal,
      };
}

/// A lever: clear up/down states, interact toggles it
/// (STYLE_GUIDE.md §6 — "looks pullable", accentInteract).
class Lever extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Interactable {
  Lever(Vector2 position, Vector2 size,
      {required this.entityId,
      bool startsOn = false,
      this.style = LeverStyle.goal})
      : on = startsOn,
        super(position: position, size: size);

  final String entityId;
  final LeverStyle style;
  bool on;

  /// Visual sweep: eased toward [on] so the handle throws, not snaps.
  double _throw = 0;

  @override
  Aabb get interactZone =>
      Aabb(position.x - 8, position.y - 8, size.x + 16, size.y + 16);

  @override
  bool get promptHidden => false;

  @override
  bool get canInteract => true;

  @override
  void onInteract() {
    // The goal lever is a ONE-WAY commit: once thrown to open the exit it can't
    // be thrown back. The room stays solved for good, so the player can never
    // un-solve it and can always retrace their steps (kindness, GDD §8).
    if (style == LeverStyle.goal && on) return;
    on = !on;
    game.roomPuzzle?.onInteract(entityId);
  }

  @override
  void onMount() {
    super.onMount();
    _throw = on ? 1 : 0;
    game.interactables.add(this);
  }

  @override
  void onRemove() {
    game.interactables.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    final target = on ? 1.0 : 0.0;
    final d = (target - _throw).clamp(-dt * 7, dt * 7);
    _throw += d;
  }

  @override
  void render(Canvas canvas) {
    switch (style) {
      case LeverStyle.goal:
        _renderGoal(canvas);
      case LeverStyle.fireman:
        _renderFireman(canvas);
    }
  }

  /// The door lever: a base plate and a thin handle that sweeps about its pivot,
  /// tipped with the teal "act on me" knob.
  void _renderGoal(Canvas canvas) {
    final p = game.palette;
    final stroke = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final baseY = size.y;
    final cx = size.x / 2;
    // Base plate.
    canvas.drawRRect(
      RRect.fromLTRBR(0, baseY - 6, size.x, baseY, const Radius.circular(3)),
      Paint()..color = p.ink,
    );
    // Handle: sweeps -50° (off) → +50° (on) about the base pivot.
    final angle = (-50 + 100 * _throw) * math.pi / 180;
    final tip = Offset(
      cx + math.sin(angle) * size.y * 0.75,
      baseY - 8 - math.cos(angle) * size.y * 0.75,
    );
    canvas.drawLine(Offset(cx, baseY - 6), tip, stroke);
    // Knob signals "you can act on this".
    canvas.drawCircle(tip, 5.5, Paint()..color = p.accentInteract);
    canvas.drawCircle(
      tip,
      5.5,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  /// The puzzle lever: a chunky knife-switch — a slotted base block and a thick
  /// bar that throws down into it, tipped with a ball grip. Reads as "input",
  /// distinct from the slender door lever.
  void _renderFireman(Canvas canvas) {
    final p = game.palette;
    final baseY = size.y;
    final cx = size.x / 2;

    // Slotted base block (the switch housing).
    final blockTop = baseY - size.y * 0.34;
    canvas.drawRRect(
      RRect.fromLTRBR(
          size.x * 0.18, blockTop, size.x * 0.82, baseY, const Radius.circular(3)),
      Paint()..color = p.ink,
    );
    // The slot the bar throws through (bg-coloured notch).
    canvas.drawRRect(
      RRect.fromLTRBR(cx - 2.4, blockTop + 2, cx + 2.4, baseY - 2,
          const Radius.circular(1.5)),
      Paint()..color = p.bg,
    );

    // Pivot sits at the top of the housing; the thick bar throws from upright
    // (off, -55°) down toward the slot (on, +8°).
    final pivot = Offset(cx, blockTop + 1);
    final angle = (-55 + 63 * _throw) * math.pi / 180;
    final len = size.y * 0.82;
    final tip = Offset(
      pivot.dx + math.sin(angle) * len,
      pivot.dy - math.cos(angle) * len,
    );
    canvas.drawLine(
      pivot,
      tip,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    // Ball grip — the interact accent so it still reads as actionable.
    canvas.drawCircle(tip, 6.5, Paint()..color = p.accentInteract);
    canvas.drawCircle(
      tip,
      6.5,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }
}
