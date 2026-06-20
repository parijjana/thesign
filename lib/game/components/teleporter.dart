import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../core/interactable.dart';
import '../escape_game.dart';

/// How lit a meadow teleporter is (M7 hub/ending, GDD §3 twist):
/// - [dark]  — the iris is shut; not yet available (area unreached).
/// - [half]  — the iris is ajar with a sliver of light; available to enter.
/// - [full]  — the iris is wide open, light blazing through: every puzzle of
///             its area is solved (the collectible payoff + a progress meter).
enum TeleLevel { dark, half, full }

/// A mechanical **iris portal**. Aperture blades open as the area's state
/// advances, with light pouring from behind. The lone ground-left [isExit] pad
/// is the shut "you came out here" marker. One-way by design (you leave the
/// castle by re-escaping), so meadow edges are exempt from the symmetry guard.
class Teleporter extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Interactable {
  Teleporter(
    Vector2 position,
    Vector2 size, {
    this.exitName,
    this.requiresVisited,
    this.completesRooms = const [],
    this.availableFromStart = false,
    this.isExit = false,
  }) : super(position: position, size: size, priority: 3);

  final String? exitName;
  final String? requiresVisited;
  final List<String> completesRooms;
  final bool availableFromStart;
  final bool isExit;

  static const _blades = 7;
  double _t = 0;

  TeleLevel get level {
    if (isExit) return TeleLevel.dark;
    if (completesRooms.isNotEmpty &&
        completesRooms.every(game.solvedRooms.contains)) {
      return TeleLevel.full;
    }
    final available = availableFromStart ||
        (requiresVisited != null &&
            game.visitedNodes.contains(requiresVisited));
    return available ? TeleLevel.half : TeleLevel.dark;
  }

  @override
  Aabb get interactZone => Aabb(position.x - 6, position.y, size.x + 12, size.y);

  @override
  bool get canInteract =>
      !isExit && exitName != null && level != TeleLevel.dark;

  @override
  bool get promptHidden => isExit || level == TeleLevel.dark;

  @override
  void onInteract() {
    if (canInteract) game.goThrough(exitName!);
  }

  @override
  void onMount() {
    super.onMount();
    game.interactables.add(this);
  }

  @override
  void onRemove() {
    game.interactables.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final lvl = level;
    final cx = size.x / 2;
    final cy = size.y / 2;
    final rOuter = size.x * 0.48; // metal housing
    final rRing = size.x * 0.42; // blade root ring

    // openness 0 = shut, 1 = wide; spin speed grows with state.
    final (double openness, double spin) = switch (isExit ? null : lvl) {
      null => (0.0, 0.0),
      TeleLevel.dark => (0.0, 0.0),
      TeleLevel.half => (0.42, 0.5),
      TeleLevel.full => (0.86, 1.1),
    };
    final aperture = openness * rRing;

    canvas.save();
    canvas.translate(cx, cy);

    // Soft halo bleeding out around the housing (only when lit).
    if (aperture > 0.5) {
      canvas.drawCircle(Offset.zero, rRing * (1.0 + openness * 0.9),
          Paint()..color = p.accentHint.withValues(alpha: 0.22 * openness));
    }

    // The housing: a metal disc backing the blades.
    canvas.drawCircle(Offset.zero, rOuter, Paint()..color = p.accentNeutral);

    // Light from behind, seen through the open aperture.
    if (aperture > 0.5) {
      canvas.drawCircle(Offset.zero, aperture * 1.15,
          Paint()..color = p.accentHint.withValues(alpha: 0.9));
      canvas.drawCircle(Offset.zero, aperture * 0.7,
          Paint()..color = const Color(0xFFFFF6D8));
    }

    // Iris blades: an overlapping pinwheel from the ring inward to the aperture.
    final blade = Paint()..color = p.accentNeutral;
    final bladeEdge = Paint()
      ..color = p.ink.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;
    const span = 2 * math.pi / _blades * 1.7;
    const twist = 0.95;
    final rot = _t * spin;
    for (var i = 0; i < _blades; i++) {
      final a = rot + i * 2 * math.pi / _blades;
      final path = Path()
        ..moveTo(math.cos(a) * rRing, math.sin(a) * rRing)
        ..lineTo(math.cos(a + span) * rRing, math.sin(a + span) * rRing)
        ..lineTo(math.cos(a + span + twist) * aperture,
            math.sin(a + span + twist) * aperture)
        ..lineTo(
            math.cos(a + twist) * aperture, math.sin(a + twist) * aperture)
        ..close();
      canvas.drawPath(path, blade);
      canvas.drawPath(path, bladeEdge);
    }

    // Housing rim, drawn last so it crisply frames the aperture.
    canvas.drawCircle(
      Offset.zero,
      rOuter,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    // Bolt studs around the housing for the mechanical read.
    for (var i = 0; i < _blades; i++) {
      final a = i * 2 * math.pi / _blades + math.pi / _blades;
      canvas.drawCircle(
          Offset(math.cos(a) * rOuter * 0.86, math.sin(a) * rOuter * 0.86),
          1.6,
          Paint()..color = p.ink.withValues(alpha: 0.7));
    }

    // Fully open: shafts of light spilling out past the housing.
    if (lvl == TeleLevel.full && !isExit) {
      final ray = Paint()
        ..color = p.accentHint.withValues(alpha: 0.45)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = _t * 0.6 + i * math.pi / 4;
        canvas.drawLine(
          Offset(math.cos(a) * aperture, math.sin(a) * aperture),
          Offset(math.cos(a) * rOuter * 1.6, math.sin(a) * rOuter * 1.6),
          ray,
        );
      }
    }
    canvas.restore();
  }
}
