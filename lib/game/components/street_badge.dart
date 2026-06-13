import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../escape_game.dart';
import '../ui/symbols.dart';

/// A corridor's "street name" badge (MAZE.md §2), carved as **bas-relief**
/// into the castle stone — architecture, not a posted sign (STYLE_GUIDE
/// rule 9). Rendered in the masonry colours (surface + ink + bg), with a
/// minimal two-tone to read as a raised carving: an ink recess-shadow under
/// a bright stone face. One per corridor.
class StreetBadge extends PositionComponent with HasGameReference<EscapeGame> {
  StreetBadge(Vector2 position, Vector2 size, {required this.glyph})
      : super(position: position, size: size, priority: 2);

  final SymbolId glyph;

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final rect = size.toRect();

    // A stone cartouche, same stone as the walls — set INTO the masonry.
    final panel = RRect.fromRectAndRadius(rect, const Radius.circular(7));
    canvas.drawRRect(panel, Paint()..color = p.surface);
    // Carved rim: a bright inner edge (top-left, catching light) over an ink
    // outer groove — the two-tone that says "recessed into the wall".
    canvas.drawRRect(
      panel.deflate(2),
      Paint()
        ..color = p.bg
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      panel,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.strokeHeavy
        ..strokeJoin = StrokeJoin.round,
    );

    // The glyph as raised relief: an ink shadow offset down-right, then the
    // bright stone face on top — chiselled, no gradients (flat two-tone).
    final g = size.x * 0.62;
    final ox = (size.x - g) / 2;
    final oy = (size.y - g) / 2;
    canvas.save();
    canvas.translate(ox + 1.6, oy + 1.6);
    drawSymbol(canvas, glyph, g, p.ink);
    canvas.restore();
    canvas.save();
    canvas.translate(ox, oy);
    drawSymbol(canvas, glyph, g, p.bg);
    canvas.restore();
  }
}
