import 'dart:ui';

import 'package:flame/components.dart';

import '../escape_game.dart';
import '../ui/symbols.dart';

/// A neutral wall sign with an ink glyph — e.g. the discipline markers above
/// a hub's room doors (SYMBOLS §5: variety made legible before entering).
class Sign extends PositionComponent with HasGameReference<EscapeGame> {
  Sign(Vector2 position, Vector2 size, {this.glyph, this.pips = 0})
      : assert(glyph != null || pips > 0),
        super(position: position, size: size);

  final SymbolId? glyph;

  /// Wordless count (q_pips quantity grammar): a row of filled dots —
  /// e.g. order numbers in the sequence room.
  final int pips;

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final board = RRect.fromRectAndRadius(
      size.toRect().inflate(4),
      const Radius.circular(6),
    );
    canvas.drawRRect(board, Paint()..color = p.accentNeutral);
    canvas.drawRRect(
      board,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
    final g = glyph;
    if (g != null) drawSymbol(canvas, g, size.x, p.ink);
    if (pips > 0) {
      final dot = Paint()..color = p.ink;
      final totalW = (pips - 1) * 10.0;
      final y = g == null ? size.y / 2 : size.y + 1;
      for (var i = 0; i < pips; i++) {
        canvas.drawCircle(
            Offset(size.x / 2 - totalW / 2 + i * 10, y), 3.2, dot);
      }
    }
  }
}
