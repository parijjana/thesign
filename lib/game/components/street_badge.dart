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
    // A flat engraved wall marker — no frame, no shadow. The glyph is drawn
    // in the stone's own `surface` tone so it reads as carved into the wall
    // rather than posted on it.
    drawSymbol(canvas, glyph, size.x, p.surface);
  }
}
