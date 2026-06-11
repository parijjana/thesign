import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/aabb.dart';
import '../escape_game.dart';
import 'symbols.dart';

/// The contextual verb prompt (GDD §10): a bubble with the press glyph above
/// whatever the player can currently act on. EPHEMERA, not architecture
/// (STYLE_GUIDE §2 rule 9): it floats, bobs, wiggles, and fades in and out —
/// nothing in the world is ever permanently decorated by it.
class InteractPrompt extends PositionComponent
    with HasGameReference<EscapeGame> {
  InteractPrompt() : super(position: Vector2.zero(), priority: 50);

  double _bob = 0;
  double _alpha = 0;
  Aabb? _zone; // last focused zone — lingers so the fade-out has a home

  @override
  void update(double dt) {
    _bob += dt;
    final target = game.resetting ? null : game.focusedInteractable;
    if (target != null) {
      _zone = target.interactZone;
      _alpha = math.min(1, _alpha + dt * 7);
    } else {
      _alpha = math.max(0, _alpha - dt * 7);
    }
  }

  @override
  void render(Canvas canvas) {
    final zone = _zone;
    if (zone == null || _alpha <= 0.01) return;
    final p = game.palette;

    final cx = zone.x + zone.w / 2;
    final cy = zone.y - 24 + math.sin(_bob * 3.2) * 2.5;
    final scale = 0.85 + 0.15 * _alpha; // grows in as it fades in

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(math.sin(_bob * 2.1) * 0.06); // gentle wiggle
    canvas.scale(scale);

    const half = 13.0;
    final bubble = RRect.fromLTRBR(
        -half, -half, half, half, const Radius.circular(6));
    canvas.drawRRect(
        bubble,
        Paint()..color = p.accentNeutral.withValues(alpha: 0.92 * _alpha));
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = p.ink.withValues(alpha: _alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.translate(-10, -10);
    drawSymbol(canvas, SymbolId.interact, 20, p.ink.withValues(alpha: _alpha));
    canvas.restore();
  }
}
