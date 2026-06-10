import 'dart:ui';

import 'package:flame/components.dart';

import '../escape_game.dart';
import '../ui/symbols.dart';

/// Hazard telegraph: a wall-mounted sign with a glyph (every hazard must be
/// telegraphed — GDD.md §7, STYLE_GUIDE.md §9). Purely visual.
class WarningSign extends PositionComponent with HasGameReference<EscapeGame> {
  WarningSign(Vector2 position, {this.glyph = SymbolId.hazard})
      : super(position: position, size: Vector2.all(36));

  final SymbolId glyph;

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    // Sign board.
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
    drawSymbol(canvas, glyph, size.x, p.accentDanger);
  }
}
