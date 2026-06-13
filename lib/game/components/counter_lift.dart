import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../core/reset_controller.dart';
import '../escape_game.dart';
import 'weight.dart';

/// Counterweight lift (Gravity): a **sunk pressure plate**, held up from
/// below by a spring, is linked over a pulley to a blue platform. Pile weight
/// on the plate — it sinks (compressing the spring) and the platform rises,
/// 1 tile per unit of weight (max 2). Uses the shared weight system, so a
/// STACK of blocks counts by its full weight (real gravity), not just the
/// block touching the plate. Load 2, then ride the raised platform to the goal.
class CounterLift extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Resettable {
  CounterLift(Vector2 position, Vector2 size, {required this.plate})
      : super(position: position, size: size);

  /// The sunk plate zone (px) — blocks/the player here are the counterweight.
  final Aabb plate;

  late final double _baseY = position.y;
  late final Aabb _solid = Aabb(position.x, position.y, size.x, size.y);
  double _weight = 0;

  /// Objects rest on the plate at its top edge (the floor line).
  Aabb get _plateSurface => Aabb(plate.x, plate.y, plate.w, 1);

  @override
  void onMount() {
    super.onMount();
    game.collisionWorld.solids.add(_solid);
    game.resetController.register(this);
  }

  @override
  void onRemove() {
    game.collisionWorld.solids.remove(_solid);
    game.resetController.unregister(this);
    super.onRemove();
  }

  @override
  void resetToStart() {
    position.y = _baseY;
    _solid.y = _baseY;
    _weight = 0;
  }

  double get _load => math.min(_weight, 2);

  @override
  void update(double dt) {
    _weight = weightOn(game, _plateSurface); // stack-aware, counts everything
    final targetY = _baseY - _load * Config.tileSize;
    final old = position.y;
    final step = dt * Config.tileSize * 1.5;
    position.y += (targetY - position.y).clamp(-step, step);
    final dy = position.y - old;
    if (dy == 0) return;
    _solid.y = position.y;
    // Carry whatever rides the platform.
    final riders = Aabb(_solid.x, _solid.y - dy - 8, _solid.w, 10);
    final player = game.player;
    if (!player.carried && riders.overlaps(player.aabb)) {
      player.position.y += dy;
    }
    for (final b in game.blocks) {
      if (!b.held && !b.clawHeld && riders.overlaps(b.aabb)) {
        b.carryBy(Vector2(0, dy));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final ink = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // --- The sunk spring-plate (drawn relative to this component) ----------
    final plL = plate.x - position.x;
    final plR = plate.right - position.x;
    final plTop = plate.y - position.y;
    final recessBottom = plTop + Config.tileSize * 0.7;
    final sink = _load / 2 * Config.tileSize * 0.5; // plate dips as it loads

    // Recess housing walls + floor.
    canvas.drawLine(Offset(plL, plTop), Offset(plL, recessBottom), ink);
    canvas.drawLine(Offset(plR, plTop), Offset(plR, recessBottom), ink);
    canvas.drawLine(Offset(plL, recessBottom), Offset(plR, recessBottom), ink);
    // Spring under the plate (a compressing zig-zag).
    final plateY = plTop + sink;
    final springTop = plateY + 5;
    final coilH = recessBottom - springTop;
    final spring = Path()..moveTo(plL + 4, recessBottom);
    const coils = 4;
    for (var i = 0; i <= coils; i++) {
      final y = recessBottom - coilH * i / coils;
      spring.lineTo(i.isEven ? plL + 4 : plR - 4, y);
    }
    canvas.drawPath(spring, ink);
    // The plate tab itself.
    final tab = RRect.fromRectAndRadius(
      Rect.fromLTRB(plL - 2, plateY, plR + 2, plateY + 6),
      const Radius.circular(3),
    );
    canvas.drawRRect(tab, Paint()..color = p.accentInteract);
    canvas.drawRRect(tab, ink);

    // --- Pulley + rope: the pulley sits BETWEEN the platform and the plate
    // so both ropes hang almost straight down (a real counterweight rig).
    final platformCx = size.x / 2;
    final plateCx = (plL + plR) / 2;
    // A fixed, sensible height above both (world y≈4 tiles).
    final pulley =
        Offset((platformCx + plateCx) / 2, 4 * Config.tileSize - position.y);
    canvas.drawCircle(pulley, 6, ink);
    canvas.drawLine(Offset(platformCx, 0), pulley, ink); // platform → pulley
    canvas.drawLine(pulley, Offset(plateCx, plateY), ink); // pulley → plate

    // --- The rising platform ----------------------------------------------
    final r = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6));
    canvas.drawRRect(r, Paint()..color = p.accentInteract);
    canvas.drawRRect(
      r,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.stroke,
    );
  }
}
