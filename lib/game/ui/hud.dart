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
    for (var i = 0; i < _glyphs.length; i++) {
      canvas.save();
      canvas.translate(i * (glyphSize + gap), 0);
      drawSymbol(canvas, _glyphs[i], glyphSize, game.palette.ink);
      canvas.restore();
    }
  }
}
