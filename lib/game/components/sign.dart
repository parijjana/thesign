import 'dart:ui';

import 'package:flame/components.dart';

import '../escape_game.dart';
import '../ui/symbols.dart';

/// A permanent world label carved as **bas-relief** into the castle stone —
/// pip-order plaques (sequence room), hint markers, the spawn seal. NOT a
/// posted UI board: masonry colours (surface plaque, ink recess-shadow,
/// bright bg face) so it reads as engraved architecture (STYLE_GUIDE rule 9,
/// the §6 bas-relief sanction). Safety signs use [WarningSign] instead.
class Sign extends PositionComponent with HasGameReference<EscapeGame> {
  Sign(Vector2 position, Vector2 size, {this.glyph, this.pips = 0})
      : assert(glyph != null || pips > 0),
        super(position: position, size: size);

  final SymbolId? glyph;

  /// Wordless count (q_pips quantity grammar): a row of dots — e.g. order
  /// numbers in the sequence room.
  final int pips;

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    // Carved stone plaque.
    final panel = RRect.fromRectAndRadius(
        size.toRect(), Radius.circular(size.x * 0.22));
    canvas.drawRRect(panel, Paint()..color = p.surface);
    canvas.drawRRect(
      panel,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );

    final g = glyph;
    if (g != null) {
      final gs = size.x * 0.7;
      final ox = (size.x - gs) / 2;
      final oy = (size.y - gs) / 2 - (pips > 0 ? size.y * 0.12 : 0);
      // Carved relief: ink recess-shadow, then bright stone face.
      canvas.save();
      canvas.translate(ox + 1.1, oy + 1.1);
      drawSymbol(canvas, g, gs, p.ink);
      canvas.restore();
      canvas.save();
      canvas.translate(ox, oy);
      drawSymbol(canvas, g, gs, p.bg);
      canvas.restore();
    }
    if (pips > 0) {
      final totalW = (pips - 1) * 11.0;
      final y = g == null ? size.y / 2 : size.y * 0.78;
      void dots(Color color, double dx, double dy) {
        final paint = Paint()..color = color;
        for (var i = 0; i < pips; i++) {
          canvas.drawCircle(
              Offset(size.x / 2 - totalW / 2 + i * 11 + dx, y + dy), 3.6,
              paint);
        }
      }
      // Carved dots: ink recess-shadow, then bright stone face.
      dots(p.ink, 1.1, 1.1);
      dots(p.bg, 0, 0);
    }
  }
}
