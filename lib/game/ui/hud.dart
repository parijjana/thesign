import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../escape_game.dart';
import 'symbols.dart';

/// Minimal HUD overlay: the core glyph row, top-right (symbols only — no
/// text). Lives in the camera viewport, so it's fixed to the screen in
/// logical coordinates regardless of window size.
class Hud extends PositionComponent with HasGameReference<EscapeGame> {
  static const double glyphSize = 28;
  static const double gap = 10;
  static const _glyphs = [
    SymbolId.restartClaw,
    SymbolId.settings,
    SymbolId.pause,
  ];

  @override
  void onLoad() {
    final width = _glyphs.length * (glyphSize + gap) - gap;
    position = Vector2(Config.viewportWidth - width - 14, 14);
    size = Vector2(width, glyphSize);
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    for (var i = 0; i < _glyphs.length; i++) {
      canvas.save();
      canvas.translate(i * (glyphSize + gap), 0);
      // Neutral chip behind each glyph keeps the HUD readable on every
      // discipline palette (ink on indigo would vanish).
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
      drawSymbol(canvas, _glyphs[i], glyphSize, p.ink);
      canvas.restore();
    }
  }
}
