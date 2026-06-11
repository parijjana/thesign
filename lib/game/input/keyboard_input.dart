import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import 'game_input.dart';

/// Desktop/web keyboard binding (GDD.md §10): writes normalized intents into
/// [GameInput]. The game must mix in `HasKeyboardHandlerComponents`.
class KeyboardInput extends Component with KeyboardHandler {
  KeyboardInput(this.input);

  final GameInput input;

  static const _left = [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA];
  static const _right = [
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyD,
  ];
  static const _jump = [
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.arrowUp,
  ];
  static const _interact = [LogicalKeyboardKey.keyE, LogicalKeyboardKey.enter];

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool anyDown(List<LogicalKeyboardKey> keys) =>
        keys.any(keysPressed.contains);

    input.moveAxis = (anyDown(_right) ? 1 : 0) - (anyDown(_left) ? 1 : 0);
    input.jumpHeld = anyDown(_jump);

    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (_jump.contains(key)) input.jumpPressed = true;
      if (_interact.contains(key)) input.interactPressed = true;
      if (key == LogicalKeyboardKey.keyR) input.restartPressed = true;
      if (key == LogicalKeyboardKey.escape) input.pausePressed = true;
      if (key == LogicalKeyboardKey.f2) input.devResetPressed = true;
    }
    return true;
  }
}
