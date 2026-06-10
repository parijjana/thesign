// M2 TEST ROOM — hand-built level proving movement, collision, and the claw
// reset. Replaced by data-loaded rooms in M3 (LEVEL_FORMAT.md).

import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../escape_game.dart';
import '../ui/symbols.dart';
import 'floor.dart';
import 'spike_strip.dart';
import 'wall.dart';
import 'warning_sign.dart';

/// Layout (24×14 tiles): ground with a 3-tile spike pit, two jump platforms,
/// brick wall columns, and a warning sign telegraphing the pit (GDD §7).
class TestRoom extends PositionComponent with HasGameReference<EscapeGame> {
  TestRoom()
      : super(
          position: Vector2.zero(),
          size: Vector2(Config.viewportWidth, Config.viewportHeight),
        );

  @override
  void onLoad() {
    const t = Config.tileSize;
    addAll([
      // Side wall columns.
      Wall(Vector2(t * 0.5, t * 0.5), Vector2(t * 0.75, t * 11.5)),
      Wall(Vector2(t * 22.75, t * 0.5), Vector2(t * 0.75, t * 11.5)),
      // Ground, split by the spike pit (tiles 10–13).
      Floor(Vector2(t * 0.5, t * 12), Vector2(t * 9.5, t * 1.5)),
      Floor(Vector2(t * 13, t * 12), Vector2(t * 10.5, t * 1.5)),
      // Jump platforms.
      Floor(Vector2(t * 5, t * 9), Vector2(t * 3, t * 0.75)),
      Floor(Vector2(t * 15, t * 7.5), Vector2(t * 3, t * 0.75)),
      // The pit hazard + its telegraph.
      SpikeStrip(Vector2(t * 10, t * 13.3), t * 3),
      WarningSign(Vector2(t * 8.5, t * 10.4), glyph: SymbolId.hazard),
    ]);
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    // Background field.
    canvas.drawRect(size.toRect(), Paint()..color = p.bg);
    // Heavy room boundary.
    canvas.drawRect(
      size.toRect().deflate(Config.strokeHeavy / 2),
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.strokeHeavy
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
