import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/aabb.dart';
import '../core/interactable.dart';
import '../escape_game.dart';

/// A lever: clear up/down states, interact toggles it
/// (STYLE_GUIDE.md §6 — "looks pullable", accentInteract).
class Lever extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Interactable {
  Lever(Vector2 position, Vector2 size,
      {required this.entityId, bool startsOn = false})
      : on = startsOn,
        super(position: position, size: size);

  final String entityId;
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
}
