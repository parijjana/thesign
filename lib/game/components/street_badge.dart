import 'dart:ui';

import 'package:flame/components.dart';

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
    // A small carved stone plaque, same stone as the walls — a wall marker
    // at head height, not a posted sign. Round-ish like a worn cartouche.
    final panel = RRect.fromRectAndRadius(size.toRect(), Radius.circular(size.x * 0.28));
    canvas.drawRRect(panel, Paint()..color = p.surface);
    canvas.drawRRect(
      panel,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );

    // The glyph as raised relief: an ink shadow offset down-right, then the
    // bright stone face on top — chiselled, flat two-tone (no gradients).
    final g = size.x * 0.62;
    final ox = (size.x - g) / 2;
    final oy = (size.y - g) / 2;
    canvas.save();
    canvas.translate(ox + 1.1, oy + 1.1);
    drawSymbol(canvas, glyph, g, p.ink);
    canvas.restore();
    canvas.save();
    canvas.translate(ox, oy);
    drawSymbol(canvas, glyph, g, p.bg);
    canvas.restore();
  }
}
