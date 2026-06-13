import 'dart:ui';

import 'package:flame/components.dart';

import '../escape_game.dart';
import '../ui/symbols.dart';

/// A permanent world label: a flat mark on the wall — pip-order dots
/// (sequence room), a hint glyph, the spawn seal. No frame, no board, no
/// shadow (people don't hang labelled boards over their light switches):
/// just the marks themselves, in ink, like stencilled/engraved signage.
class Sign extends PositionComponent with HasGameReference<EscapeGame> {
  Sign(Vector2 position, Vector2 size, {this.glyph, this.pips = 0})
      : assert(glyph != null || pips > 0),
        super(position: position, size: size);

  final SymbolId? glyph;

  /// Wordless count (q_pips quantity grammar): a row of small solid dots.
  final int pips;

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final g = glyph;
    if (g != null) {
      final gs = size.x;
      canvas.save();
      canvas.translate(0, (size.y - gs) / 2);
      drawSymbol(canvas, g, gs, p.ink);
      canvas.restore();
    }
    if (pips > 0) {
      final dot = Paint()..color = p.ink;
      const r = 2.6;
      const spacing = 8.0;
      final totalW = (pips - 1) * spacing;
      final y = g == null ? size.y / 2 : size.y * 0.86;
      for (var i = 0; i < pips; i++) {
        canvas.drawCircle(
            Offset(size.x / 2 - totalW / 2 + i * spacing, y), r, dot);
      }
    }
  }
}
