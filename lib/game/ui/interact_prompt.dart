import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../escape_game.dart';
import 'symbols.dart';

/// The contextual verb prompt (GDD §10): a small bobbing bubble with the
/// hand glyph above whatever the player can currently act on. Wordless —
/// the same glyph labels the touch/controller interact button, so the verb
/// is taught once by association.
class InteractPrompt extends PositionComponent
    with HasGameReference<EscapeGame> {
  InteractPrompt() : super(position: Vector2.zero(), priority: 50);

  double _bob = 0;

  @override
  void update(double dt) => _bob += dt;

  @override
  void render(Canvas canvas) {
    final target = game.focusedInteractable;
    if (target == null || game.resetting) return;
    final p = game.palette;

    final zone = target.interactZone;
    final cx = zone.x + zone.w / 2;
    final cy = zone.y - 24 + math.sin(_bob * 3.2) * 2.5;

    const half = 13.0;
    final bubble = RRect.fromLTRBR(
        cx - half, cy - half, cx + half, cy + half, const Radius.circular(6));
    canvas.drawRRect(bubble, Paint()..color = p.accentNeutral);
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.save();
    canvas.translate(cx - 10, cy - 10);
    drawSymbol(canvas, SymbolId.interact, 20, p.ink);
    canvas.restore();
  }
}
