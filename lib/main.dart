// M0 SPIKE (docs/ROADMAP.md) — THROWAWAY CODE.
// Purpose: prove Flame's game loop, Canvas rendering, and keyboard input on
// web + Windows before committing to the real architecture. Delete after M0.

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Dungeon Amber tokens (docs/STYLE_GUIDE.md §3.1) — hard-coded here only
// because this file is throwaway; the real game uses palette.dart tokens.
const bg = Color(0xFFC9A227);
const ink = Color(0xFF101010);
const surface = Color(0xFFB8941F);
const accentInteract = Color(0xFF1E4E8C);

void main() {
  runApp(GameWidget(game: SpikeGame()));
}

class SpikeGame extends FlameGame with HasKeyboardHandlerComponents {
  @override
  Color backgroundColor() => bg;

  @override
  Future<void> onLoad() async {
    addAll([Floor(), InkCircle(), PlayerBox()]);
  }
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(double w) => Paint()
  ..color = ink
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round;

/// Rounded-rect floor spanning the bottom of the screen.
class Floor extends PositionComponent {
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(16, size.y - 80);
    this.size = Vector2(size.x - 32, 64);
  }

  @override
  void render(Canvas canvas) {
    final r = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(10));
    canvas.drawRRect(r, _fill(surface));
    canvas.drawRRect(r, _stroke(4));
  }
}

/// A solid ink circle resting on the floor — render() sanity check.
class InkCircle extends PositionComponent {
  static const radius = 28.0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x * 0.7, size.y - 80 - radius);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius, _fill(ink));
  }
}

/// Keyboard-movable box: arrows / WASD, clamped to the screen.
class PlayerBox extends PositionComponent
    with KeyboardHandler, HasGameReference<SpikeGame> {
  PlayerBox() : super(size: Vector2.all(48), anchor: Anchor.center);

  static const speed = 280.0;
  final Vector2 _dir = Vector2.zero();

  @override
  void onMount() {
    super.onMount();
    position = game.size / 2;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool down(LogicalKeyboardKey k) => keysPressed.contains(k);
    _dir.setValues(
      (down(LogicalKeyboardKey.arrowRight) || down(LogicalKeyboardKey.keyD)
              ? 1.0
              : 0.0) -
          (down(LogicalKeyboardKey.arrowLeft) || down(LogicalKeyboardKey.keyA)
              ? 1.0
              : 0.0),
      (down(LogicalKeyboardKey.arrowDown) || down(LogicalKeyboardKey.keyS)
              ? 1.0
              : 0.0) -
          (down(LogicalKeyboardKey.arrowUp) || down(LogicalKeyboardKey.keyW)
              ? 1.0
              : 0.0),
    );
    return true;
  }

  @override
  void update(double dt) {
    if (_dir.length2 > 0) {
      position += _dir.normalized() * speed * dt;
      position.clamp(
        Vector2.all(24),
        game.size - Vector2.all(24),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final r = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8));
    canvas.drawRRect(r, _fill(accentInteract));
    canvas.drawRRect(r, _stroke(3));
  }
}
