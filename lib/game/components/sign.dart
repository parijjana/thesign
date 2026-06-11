import 'dart:ui';

import 'package:flame/components.dart';

import '../escape_game.dart';
import '../ui/symbols.dart';

/// A neutral wall sign with an ink glyph — e.g. the discipline markers above
/// a hub's room doors (SYMBOLS §5: variety made legible before entering).
class Sign extends PositionComponent with HasGameReference<EscapeGame> {
  Sign(Vector2 position, Vector2 size, {required this.glyph})
      : super(position: position, size: size);

  final SymbolId glyph;

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
    drawSymbol(canvas, glyph, size.x, p.ink);
  }
}
