import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../escape_game.dart';
import '../ui/symbols.dart';

/// A real, posted safety sign telegraphing a hazard (GDD.md §7). Unlike the
/// carved [Sign] labels, safety signs are MEANT to stand out — so they're
/// drawn as a standardised mounted sign: a standard-shape plate (round for a
/// prohibition like no-swimming, triangular for a warning) on a planted
/// **post**, in high-contrast colours. A placed object, not floating UI.
class WarningSign extends PositionComponent with HasGameReference<EscapeGame> {
  WarningSign(Vector2 position, {this.glyph = SymbolId.hazard})
      : super(position: position, size: Vector2.all(40));

  final SymbolId glyph;

  bool get _isProhibition =>
      glyph == SymbolId.noSwimming || glyph == SymbolId.noEntry;

  /// Floor top beneath the sign centre, in local coords — so the post foot
  /// lands exactly on the ground.
  double _floorBelowLocal() {
    final cx = position.x + size.x / 2;
    var best = position.y + size.y + Config.tileSize * 1.5; // fallback
    for (final s in game.collisionWorld.solids) {
      if (cx >= s.x && cx <= s.right && s.y >= position.y + size.y * 0.5) {
        best = math.min(best, s.y);
      }
    }
    return best - position.y;
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final cx = size.x / 2;
    final faceR = size.x * 0.5;
    final faceCy = faceR; // face sits at the top, post below

    final ink = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Post planted in the ground: drawn down to the actual floor top (found
    // in the collision world) so the base sits ON the floor, never through it.
    final postTop = faceCy + faceR - 2;
    final postBottom = _floorBelowLocal();
    canvas.drawLine(Offset(cx, postTop), Offset(cx, postBottom), ink);
    canvas.drawLine(Offset(cx - 7, postBottom), Offset(cx + 7, postBottom), ink);

    // The sign plate: standard shape + pale face, then the pictogram.
    final fill = Paint()..color = p.accentNeutral;
    if (_isProhibition) {
      canvas.drawCircle(Offset(cx, faceCy), faceR, fill);
      canvas.drawCircle(Offset(cx, faceCy), faceR, ink);
    } else {
      // Warning triangle (rounded corners, the ISO look).
      final t = Path()
        ..moveTo(cx, faceCy - faceR)
        ..lineTo(cx + faceR * 0.92, faceCy + faceR * 0.72)
        ..lineTo(cx - faceR * 0.92, faceCy + faceR * 0.72)
        ..close();
      canvas.drawPath(t, fill);
      canvas.drawPath(t, ink);
    }

    // Pictogram centred on the face (its own ring/figure on top).
    final gs = size.x * 0.78;
    canvas.save();
    canvas.translate((size.x - gs) / 2, faceCy - gs / 2);
    drawSymbol(canvas, glyph, gs, p.accentDanger);
    canvas.restore();
  }
}
