import 'dart:math' as math;
import 'dart:ui';

/// The icon library (SYMBOLS.md): every HUD/menu glyph is DRAWN, never text.
///
/// Each glyph renders inside a unit square scaled to `size`, anchored at the
/// canvas origin. Construction rules per SYMBOLS.md §7 / STYLE_GUIDE.md §4:
/// consistent stroke weight, rounded joins/caps, legible at ~24 px.
enum SymbolId {
  /// Two vertical bars (STD).
  pause,

  /// Right-pointing triangle (STD).
  resume,

  /// The excavator claw — jaws + cable (INV; doubles as the reset motif).
  restartClaw,

  /// Gear (STD).
  settings,

  /// ISO 7010 W001 warning triangle with the standardized `!` mark (STD —
  /// the one universal mark the no-text rule explicitly allows).
  hazard,

  /// Closed padlock (STD) — locked door/state.
  locked,

  /// Press-the-button pictogram (STD* — arrow pressing a button cap, like an
  /// elevator call sign) — the interact verb. Labels the contextual prompt
  /// above in-range interactables AND the touch/controller interact button,
  /// so the association is learned once. (History: an open palm reads as
  /// "stop"; a drawn finger doesn't survive 20 px. Geometry wins.)
  interact,
}

void drawSymbol(Canvas canvas, SymbolId id, double size, Color ink) {
  // Work in unit-square coordinates; stroke widths are relative so a glyph
  // keeps the same visual weight at any size (≈3 px at 32 px glyph size).
  final stroke = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.10
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final fill = Paint()..color = ink;

  canvas.save();
  canvas.scale(size);

  switch (id) {
    case SymbolId.pause:
      const r = Radius.circular(0.06);
      canvas.drawRRect(
        RRect.fromLTRBR(0.24, 0.18, 0.42, 0.82, r),
        fill,
      );
      canvas.drawRRect(
        RRect.fromLTRBR(0.58, 0.18, 0.76, 0.82, r),
        fill,
      );

    case SymbolId.resume:
      final triangle = Path()
        ..moveTo(0.28, 0.16)
        ..lineTo(0.84, 0.5)
        ..lineTo(0.28, 0.84)
        ..close();
      canvas.drawPath(triangle, fill);

    case SymbolId.restartClaw:
      // Cable from above.
      canvas.drawLine(const Offset(0.5, 0.06), const Offset(0.5, 0.34), stroke);
      // Hinge.
      canvas.drawCircle(const Offset(0.5, 0.40), 0.07, fill);
      // Two open jaws, curving down and out.
      final leftJaw = Path()
        ..moveTo(0.46, 0.44)
        ..quadraticBezierTo(0.16, 0.52, 0.26, 0.86)
        ..quadraticBezierTo(0.33, 0.74, 0.40, 0.70);
      final rightJaw = Path()
        ..moveTo(0.54, 0.44)
        ..quadraticBezierTo(0.84, 0.52, 0.74, 0.86)
        ..quadraticBezierTo(0.67, 0.74, 0.60, 0.70);
      canvas.drawPath(leftJaw, stroke);
      canvas.drawPath(rightJaw, stroke);

    case SymbolId.hazard:
      final triangle = Path()
        ..moveTo(0.5, 0.10)
        ..lineTo(0.94, 0.88)
        ..lineTo(0.06, 0.88)
        ..close();
      canvas.drawPath(triangle, stroke);
      // The standardized exclamation: stem + dot.
      canvas.drawLine(const Offset(0.5, 0.36), const Offset(0.5, 0.62), stroke);
      canvas.drawCircle(const Offset(0.5, 0.76), 0.045, fill);

    case SymbolId.locked:
      // Body.
      canvas.drawRRect(
        RRect.fromLTRBR(0.22, 0.46, 0.78, 0.88, const Radius.circular(0.07)),
        fill,
      );
      // Shackle.
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(0.5, 0.46), radius: 0.19),
        math.pi,
        math.pi,
        false,
        stroke,
      );

    case SymbolId.interact:
      // Press-the-button: bold arrow pressing down onto a button cap.
      // Button cap on its housing.
      canvas.drawRRect(
        RRect.fromLTRBR(0.26, 0.64, 0.74, 0.80, const Radius.circular(0.07)),
        fill,
      );
      canvas.drawLine(const Offset(0.14, 0.88), const Offset(0.86, 0.88), stroke);
      // Arrow: shaft + solid head, pressing down.
      canvas.drawLine(const Offset(0.5, 0.10), const Offset(0.5, 0.34), stroke);
      final head = Path()
        ..moveTo(0.32, 0.32)
        ..lineTo(0.68, 0.32)
        ..lineTo(0.5, 0.56)
        ..close();
      canvas.drawPath(head, fill);

    case SymbolId.settings:
      const center = Offset(0.5, 0.5);
      canvas.drawCircle(center, 0.26, stroke);
      canvas.drawCircle(center, 0.10, stroke);
      // Eight teeth as radial ticks.
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(center + dir * 0.30, center + dir * 0.42, stroke);
      }
  }

  canvas.restore();
}
