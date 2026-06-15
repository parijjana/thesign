import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../core/reset_controller.dart';
import '../escape_game.dart';
import 'weight.dart';

/// Counterweight lift (Gravity): a **sunk pressure plate**, held up from
/// below by a spring, is linked over a pulley to a blue platform. The platform
/// rises by the **net** weight — what's on the plate MINUS what's on the
/// platform — 1 tile per unit (max 2). So your own weight (and any block) on
/// the platform pushes back, exactly like a real counterweight: there's no
/// free ride up. Uses the shared weight system (stacks count fully). To lift
/// yourself to the top you must out-weigh yourself on the plate (e.g. 3 blocks
/// beat you + the platform).
class CounterLift extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Resettable {
  CounterLift(Vector2 position, Vector2 size, {required this.plate})
      : super(position: position, size: size);

  /// The sunk plate zone (px) — blocks/the player here are the counterweight.
  final Aabb plate;

  late final double _baseY = position.y;
  late final Aabb _solid = Aabb(position.x, position.y, size.x, size.y);
  double _load = 0; // net lift in tiles (0..2), drives height + spring sink

  /// Objects rest on the plate at its top edge (the floor line).
  Aabb get _plateSurface => Aabb(plate.x, plate.y, plate.w, 1);

  /// Objects rest on the platform at ITS top edge — the counter side.
  Aabb get _liftSurface => Aabb(_solid.x, _solid.y, _solid.w, 1);

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
    _load = 0;
  }

  @override
  void update(double dt) {
    // Net counterweight: plate side minus platform side (both stack-aware).
    // Whatever stands on the rising platform pushes back — no free ride.
    final onPlate = weightOn(game, _plateSurface);
    final onPlatform = weightOn(game, _liftSurface);
    _load = (onPlate - onPlatform).clamp(0.0, 2.0);
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
    // The plate tab stays FLUSH with the floor — that's where blocks/the player
    // actually rest, so they sit ON it (no floating gap). Load is told by the
    // spring squashing beneath and by the far platform rising.
    final recessBottom = plTop + Config.tileSize * 0.7;
    final plateY = plTop;

    // Recess housing walls + floor (the spring lives below the flush plate).
    canvas.drawLine(Offset(plL, plTop), Offset(plL, recessBottom), ink);
    canvas.drawLine(Offset(plR, plTop), Offset(plR, recessBottom), ink);
    canvas.drawLine(Offset(plL, recessBottom), Offset(plR, recessBottom), ink);
    // Spring under the plate — squashes tighter as the load grows.
    final springTop = plateY + 5;
    final coilH = recessBottom - springTop;
    final coils = 3 + (_load * 2).round(); // more coils = more compressed
    final spring = Path()..moveTo(plL + 4, recessBottom);
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
