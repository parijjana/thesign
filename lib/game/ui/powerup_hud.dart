import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../escape_game.dart';
import '../powerups.dart';
import 'symbols.dart';

/// Bottom-left row of owned powerup glyphs on neutral chips (matches the top
/// HUD treatment so it reads on every palette). Wordless inventory.
class PowerupHud extends PositionComponent with HasGameReference<EscapeGame> {
  PowerupHud() : super(priority: 50);

  static const double glyphSize = 24;
  static const double gap = 8;

  @override
  void onLoad() {
    position = Vector2(14, Config.viewportHeight - glyphSize - 18);
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final owned = [
      for (final pw in Powerup.values)
        if (game.hasPowerup(pw)) pw,
    ];
    for (var i = 0; i < owned.length; i++) {
      canvas.save();
      canvas.translate(i * (glyphSize + gap), 0);
      final chip = RRect.fromRectAndRadius(
        Rect.fromLTWH(-4, -4, glyphSize + 8, glyphSize + 8),
        const Radius.circular(6),
      );
      canvas.drawRRect(
          chip, Paint()..color = p.accentNeutral.withValues(alpha: 0.85));
      canvas.drawRRect(
        chip,
        Paint()
          ..color = p.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      drawSymbol(canvas, owned[i].glyph, glyphSize, p.ink);
      canvas.restore();
    }
  }
}
