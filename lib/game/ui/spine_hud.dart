import 'dart:ui';

import 'package:flame/components.dart';

import '../escape_game.dart';
import 'symbols.dart';

/// PROTOTYPE — the "street spine" progress ribbon (design idea A1).
/// Top-centre row of the corridor street-badge family in castle order
/// (○ △ □ ◇ ☆), capped by the exit swirl. Each badge is a faint outline
/// until you've set foot on that street, then it fills with ink — so the
/// player reads "how lit is the spine" as distance toward the exit, wordless
/// and numeral-free (reuses the existing badges + SYMBOLS grammar). The
/// street you're currently on rides a goal-green chip.
class SpineHud extends PositionComponent with HasGameReference<EscapeGame> {
  SpineHud() : super(priority: 50);

  static const double glyphSize = 22;
  static const double gap = 8;

  /// Castle order: corridor → its street glyph (assets/levels/corridor_0N).
  static const _streets = <(SymbolId, String)>[
    (SymbolId.streetCircle, 'corridor_01'),
    (SymbolId.streetTriangle, 'corridor_02'),
    (SymbolId.streetSquare, 'corridor_03'),
    (SymbolId.streetDiamond, 'corridor_04'),
    (SymbolId.streetStar, 'corridor_05'),
  ];

  int get _count => _streets.length + 1; // + the exit cap

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final width = _count * (glyphSize + gap) - gap;
    this.size = Vector2(width, glyphSize);
    position = Vector2((size.x - width) / 2, 16);
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    for (var i = 0; i < _count; i++) {
      final isExit = i == _streets.length;
      final glyph = isExit ? SymbolId.spawn : _streets[i].$1;
      final reached = isExit
          ? game.visitedNodes.contains('exit_hall')
          : game.visitedNodes.contains(_streets[i].$2);
      final current = !isExit && game.currentNodeId == _streets[i].$2;

      canvas.save();
      canvas.translate(i * (glyphSize + gap), 0);
      final chip = RRect.fromRectAndRadius(
        Rect.fromLTWH(-4, -4, glyphSize + 8, glyphSize + 8),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        chip,
        Paint()
          ..color = (current ? p.accentGoal : p.accentNeutral)
              .withValues(alpha: 0.85),
      );
      canvas.drawRRect(
        chip,
        Paint()
          ..color = p.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      drawSymbol(
        canvas,
        glyph,
        glyphSize,
        p.ink.withValues(alpha: reached || current ? 1.0 : 0.26),
      );
      canvas.restore();
    }
  }
}
