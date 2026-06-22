import 'dart:ui';

import 'package:flame/components.dart';

import '../escape_game.dart';
import '../ui/symbols.dart';

/// A faint wordless breadcrumb: a glyph scuffed into the floor, leading the
/// eye toward a secret (GDD §9b discoverability — the fin-trail to the grotto
/// flippers in corridor_04). Drawn at low alpha in `ink` so it reads as a worn
/// mark on the stone, not a posted sign (STYLE_GUIDE rule 9). Non-solid,
/// purely decorative; never prompts, never collides.
class TrailMark extends PositionComponent with HasGameReference<EscapeGame> {
  TrailMark(Vector2 position, Vector2 size, {required this.glyph})
      : super(position: position, size: size, priority: 1);

  final SymbolId glyph;

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    drawSymbol(canvas, glyph, size.x, p.ink.withValues(alpha: 0.28));
  }
}
