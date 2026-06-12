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

  /// ISO prohibition sign (STD) — circle with diagonal slash: "no entry".
  /// The closed-door status sign (GDD §4 passage doors).
  noEntry,

  /// ISO P049 no-swimming (STD) — prohibition ring over a swimmer in waves.
  /// Telegraphs water pools (the kid-friendly hazard).
  noSwimming,

  /// Press-the-button pictogram (STD* — arrow pressing a button cap, like an
  /// elevator call sign) — the interact verb. Labels the contextual prompt
  /// above in-range interactables AND the touch/controller interact button,
  /// so the association is learned once. (History: an open palm reads as
  /// "stop"; a drawn finger doesn't survive 20 px. Geometry wins.)
  interact,

  /// Open padlock (STD) — unlocked/solved; the fb_success popup glyph.
  unlocked,

  /// Bold exclamation (STD*, from the ISO warning mark) — the fb_error
  /// popup: "that didn't work".
  error,

  /// Lightbulb (STD*) — hint/idea; the fb_idea popup glyph and the future
  /// HUD hint button.
  hint,

  /// Corridor street-name badges (INV, MAZE.md §2): a geometric family —
  /// one per corridor, painted on doors leading into it and on its walls.
  streetCircle,
  streetTriangle,
  streetSquare,
  streetDiamond,
  streetStar,
  streetHex,

  /// Teleporter / spawn point (INV): swirl-in-circle. The way in — and the
  /// "exit" (the twist).
  spawn,

  /// Discipline marker: Mechanics — lever on a fulcrum triangle (SYMBOLS §5).
  dMechanics,

  /// Discipline marker: Optics — sun with a single long ray (SYMBOLS §5).
  dOptics,

  /// Discipline marker: Gravity — falling ball with down arrows (SYMBOLS §5).
  dGravity,

  /// Discipline marker: Logic/Pattern — three linked nodes (INV).
  dLogic,
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

    case SymbolId.noEntry:
      final ring = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.13
        ..strokeCap = StrokeCap.butt;
      canvas.drawCircle(const Offset(0.5, 0.5), 0.34, ring);
      // The 45° slash, top-left → bottom-right (ISO prohibition).
      canvas.drawLine(
          const Offset(0.26, 0.26), const Offset(0.74, 0.74), ring);

    case SymbolId.noSwimming:
      final thin = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.07
        ..strokeCap = StrokeCap.round;
      // Swimmer: head + a reaching arm-stroke above the water line.
      canvas.drawCircle(const Offset(0.40, 0.38), 0.065, fill);
      canvas.drawLine(const Offset(0.48, 0.44), const Offset(0.66, 0.40), thin);
      // Two signage wave lines.
      for (final yy in const [0.56, 0.70]) {
        final wavePath = Path()..moveTo(0.20, yy);
        for (var i = 0; i < 3; i++) {
          final x0 = 0.20 + i * 0.20;
          wavePath.quadraticBezierTo(x0 + 0.05, yy - 0.08, x0 + 0.10, yy);
          wavePath.quadraticBezierTo(x0 + 0.15, yy + 0.08, x0 + 0.20, yy);
        }
        canvas.drawPath(wavePath, thin);
      }
      // Prohibition ring + slash, over everything.
      final ring = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.11
        ..strokeCap = StrokeCap.butt;
      canvas.drawCircle(const Offset(0.5, 0.5), 0.40, ring);
      canvas.drawLine(
          const Offset(0.22, 0.22), const Offset(0.78, 0.78), ring);

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

    case SymbolId.unlocked:
      // Body + shackle swung open to the side.
      canvas.drawRRect(
        RRect.fromLTRBR(0.22, 0.46, 0.78, 0.88, const Radius.circular(0.07)),
        fill,
      );
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(0.30, 0.42), radius: 0.19),
        math.pi * 0.95,
        math.pi * 0.85,
        false,
        stroke,
      );

    case SymbolId.error:
      final bold = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.16
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(0.5, 0.12), const Offset(0.5, 0.58), bold);
      canvas.drawCircle(const Offset(0.5, 0.82), 0.08, fill);

    case SymbolId.streetCircle:
      canvas.drawCircle(const Offset(0.5, 0.5), 0.3, stroke);

    case SymbolId.streetTriangle:
      final t = Path()
        ..moveTo(0.5, 0.18)
        ..lineTo(0.82, 0.78)
        ..lineTo(0.18, 0.78)
        ..close();
      canvas.drawPath(t, stroke);

    case SymbolId.streetSquare:
      canvas.drawRect(const Rect.fromLTRB(0.22, 0.22, 0.78, 0.78), stroke);

    case SymbolId.streetDiamond:
      final d = Path()
        ..moveTo(0.5, 0.14)
        ..lineTo(0.86, 0.5)
        ..lineTo(0.5, 0.86)
        ..lineTo(0.14, 0.5)
        ..close();
      canvas.drawPath(d, stroke);

    case SymbolId.streetStar:
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final r = i.isEven ? 0.34 : 0.15;
        final a = -math.pi / 2 + i * math.pi / 5;
        final pt = Offset(0.5 + math.cos(a) * r, 0.5 + math.sin(a) * r);
        i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(star..close(), stroke);

    case SymbolId.streetHex:
      final hex = Path();
      for (var i = 0; i < 6; i++) {
        final a = -math.pi / 2 + i * math.pi / 3;
        final pt = Offset(0.5 + math.cos(a) * 0.32, 0.5 + math.sin(a) * 0.32);
        i == 0 ? hex.moveTo(pt.dx, pt.dy) : hex.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(hex..close(), stroke);

    case SymbolId.spawn:
      canvas.drawCircle(const Offset(0.5, 0.5), 0.38, stroke);
      // Inward spiral: three shrinking arcs.
      for (var i = 0; i < 3; i++) {
        canvas.drawArc(
          Rect.fromCircle(
              center: const Offset(0.5, 0.5), radius: 0.28 - i * 0.08),
          i * 2.1,
          math.pi * 1.2,
          false,
          stroke,
        );
      }

    case SymbolId.hint:
      // Bulb + base + two light ticks.
      canvas.drawCircle(const Offset(0.5, 0.42), 0.22, stroke);
      canvas.drawLine(const Offset(0.42, 0.66), const Offset(0.42, 0.78), stroke);
      canvas.drawLine(const Offset(0.58, 0.66), const Offset(0.58, 0.78), stroke);
      canvas.drawLine(const Offset(0.44, 0.84), const Offset(0.56, 0.84), stroke);
      canvas.drawLine(const Offset(0.16, 0.20), const Offset(0.24, 0.28), stroke);
      canvas.drawLine(const Offset(0.84, 0.20), const Offset(0.76, 0.28), stroke);

    case SymbolId.dMechanics:
      // Fulcrum triangle + tilted lever bar with a load dot.
      final fulcrum = Path()
        ..moveTo(0.5, 0.52)
        ..lineTo(0.66, 0.80)
        ..lineTo(0.34, 0.80)
        ..close();
      canvas.drawPath(fulcrum, fill);
      canvas.drawLine(const Offset(0.12, 0.40), const Offset(0.88, 0.56), stroke);
      canvas.drawCircle(const Offset(0.16, 0.32), 0.08, fill);

    case SymbolId.dOptics:
      // Sun + one long ray.
      canvas.drawCircle(const Offset(0.38, 0.38), 0.15, stroke);
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(
          Offset(0.38 + dir.dx * 0.21, 0.38 + dir.dy * 0.21),
          Offset(0.38 + dir.dx * 0.30, 0.38 + dir.dy * 0.30),
          stroke,
        );
      }
      canvas.drawLine(const Offset(0.52, 0.52), const Offset(0.86, 0.86), stroke);

    case SymbolId.dGravity:
      canvas.drawCircle(const Offset(0.5, 0.30), 0.14, fill);
      for (final x in const [0.32, 0.5, 0.68]) {
        canvas.drawLine(Offset(x, 0.52), Offset(x, 0.74), stroke);
        final head = Path()
          ..moveTo(x - 0.07, 0.68)
          ..lineTo(x, 0.80)
          ..lineTo(x + 0.07, 0.68);
        canvas.drawPath(head, stroke);
      }

    case SymbolId.dLogic:
      const a = Offset(0.28, 0.70);
      const b = Offset(0.5, 0.26);
      const c = Offset(0.72, 0.70);
      canvas.drawLine(a, b, stroke);
      canvas.drawLine(b, c, stroke);
      canvas.drawLine(a, c, stroke);
      for (final pt in const [a, b, c]) {
        canvas.drawCircle(pt, 0.09, fill);
      }

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
