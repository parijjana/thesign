import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../escape_game.dart';

/// A portcullis: an iron lattice that raises into its stone header when [open]
/// (set by the room's puzzle script). The collision box shrinks from the
/// bottom up as it lifts; even fully raised, the header and the spiked bottom
/// stay in view (it tucks up, it doesn't vanish). Castle theme (STYLE_GUIDE §6).
class Gate extends PositionComponent with HasGameReference<EscapeGame> {
  Gate(Vector2 position, Vector2 size) : super(position: position, size: size);

  bool open = false;
  double _openT = 0; // 0 closed .. 1 fully raised

  static const double _spikeH = 7;
  static const double _headerH = 7;

  late final Aabb _solid = Aabb(position.x, position.y, size.x, size.y);

  @override
  void onMount() {
    super.onMount();
    game.collisionWorld.solids.add(_solid);
  }

  @override
  void onRemove() {
    game.collisionWorld.solids.remove(_solid);
    super.onRemove();
  }

  @override
  void update(double dt) {
    final target = open ? 1.0 : 0.0;
    _openT += (target - _openT).clamp(-dt * 2.5, dt * 2.5);
    // The grille rises: the solid shrinks from the bottom up (the passage
    // clears from the floor). Fully raised → no collision.
    _solid.h = size.y * (1 - _openT);
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final w = size.x;

    // How far the grille hangs below the header. Even fully raised it keeps a
    // short stub so the spikes peek out under the header — never disappears.
    final hang = math.max(Config.tileSize * 0.5, size.y * (1 - _openT));

    final iron = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = p.ink;

    final barsTop = _headerH - 1;
    final barsBottom = hang - _spikeH;
    final nBars = math.max(2, (w / 11).round());

    // Vertical bars, each ending in a downward spike.
    for (var i = 0; i < nBars; i++) {
      final x = w * (i + 0.5) / nBars;
      if (barsBottom > barsTop) {
        canvas.drawLine(Offset(x, barsTop), Offset(x, barsBottom), iron);
      }
      final tipY = math.max(barsTop, hang);
      final spike = Path()
        ..moveTo(x - 3.2, tipY - _spikeH)
        ..lineTo(x + 3.2, tipY - _spikeH)
        ..lineTo(x, tipY)
        ..close();
      canvas.drawPath(spike, fill);
    }
    // Horizontal cross-bars (the lattice).
    for (var y = barsTop + 14; y < barsBottom; y += Config.tileSize * 0.62) {
      canvas.drawLine(Offset(2, y), Offset(w - 3, y), iron);
    }

    // Stone header the grille retracts into — always visible, anchors the gate.
    final header = RRect.fromRectAndRadius(
      Rect.fromLTRB(-3, -3, w + 3, _headerH),
      const Radius.circular(3),
    );
    canvas.drawRRect(header, Paint()..color = p.surface);
    canvas.drawRRect(
      header,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
