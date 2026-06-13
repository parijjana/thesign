import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/aabb.dart';
import '../escape_game.dart';
import '../powerups.dart';
import '../ui/symbols.dart';

/// A powerup waiting on a pedestal (docs/POWERUPS.md). Walk up to collect —
/// discovery IS the verb, like an etching. Once owned, the pedestal stands
/// empty. The glyph bobs and shines so it reads as a prize.
class PowerupPickup extends PositionComponent with HasGameReference<EscapeGame> {
  PowerupPickup(Vector2 position, Vector2 size, {required this.powerup})
      : super(position: position, size: size);

  final Powerup powerup;
  double _bob = 0;

  bool get taken => game.hasPowerup(powerup);

  @override
  void update(double dt) {
    _bob += dt;
    if (taken) return;
    final zone = Aabb(position.x - 6, position.y - 8, size.x + 12, size.y + 12);
    if (!game.player.carried && zone.overlaps(game.player.aabb)) {
      game.collectPowerup(
        powerup,
        Vector2(position.x + size.x / 2, position.y - 16),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    // Pedestal.
    canvas.drawRRect(
      RRect.fromLTRBR(size.x * 0.2, size.y * 0.78, size.x * 0.8, size.y,
          const Radius.circular(3)),
      Paint()..color = p.ink,
    );
    if (taken) return;

    final lift = math.sin(_bob * 2.4) * 3;
    canvas.save();
    canvas.translate(0, lift);
    // A soft prize halo (the one sanctioned glow, like the hint halo).
    canvas.drawCircle(
      Offset(size.x / 2, size.y * 0.4),
      size.x * 0.5,
      Paint()..color = p.accentHint.withValues(alpha: 0.30),
    );
    canvas.save();
    canvas.translate(size.x * 0.15, size.y * 0.05);
    drawSymbol(canvas, powerup.glyph, size.x * 0.7, p.ink);
    canvas.restore();
    canvas.restore();
  }
}
