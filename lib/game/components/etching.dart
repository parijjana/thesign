import 'dart:ui';

import 'package:flame/components.dart';

import '../core/aabb.dart';
import '../escape_game.dart';
import '../ui/symbols.dart';

/// A collectible lore etching (GDD §9): a framed wall pictogram. Walking up
/// to it collects it — discovery IS the verb. Persists per profile; renders
/// goal-green once found. The collection gallery arrives with M7's legend.
class Etching extends PositionComponent with HasGameReference<EscapeGame> {
  Etching(Vector2 position, Vector2 size,
      {required this.etchingId, required this.glyph})
      : super(position: position, size: size);

  final String etchingId;
  final SymbolId glyph;

  bool get found => game.foundEtchings.contains(etchingId);

  @override
  void update(double dt) {
    if (found) return;
    final zone =
        Aabb(position.x - 8, position.y - 8, size.x + 16, size.y + 16);
    if (!game.player.carried && zone.overlaps(game.player.aabb)) {
      game.collectEtching(
        etchingId,
        Vector2(position.x + size.x / 2, position.y - 12),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final frameColor = found ? p.accentGoal : p.ink;
    // Double frame — reads as "an exhibit", not a sign.
    for (final inset in [0.0, 4.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            size.toRect().deflate(inset), const Radius.circular(4)),
        Paint()
          ..color = frameColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.save();
    canvas.translate(size.x * 0.15, size.y * 0.15);
    drawSymbol(canvas, glyph, size.x * 0.7, p.ink);
    canvas.restore();
  }
}
