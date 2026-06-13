import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';

import '../escape_game.dart';

/// DEV-ONLY overlay (toggle with F3): shows the current node's short code +
/// id in the top-left so the user can quote a room precisely in feedback.
/// Text is allowed here — it's developer tooling, never shipped player UI.
class DebugHud extends PositionComponent with HasGameReference<EscapeGame> {
  DebugHud() : super(priority: 200);

  final TextPaint _text = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );

  @override
  void render(Canvas canvas) {
    if (!game.showDebug) return;
    final label = '${game.currentNodeCode}  ·  ${game.currentNodeId}';
    final metrics = _text.getLineMetrics(label);
    final w = metrics.width + 16;
    canvas.drawRRect(
      RRect.fromLTRBR(6, 6, 6 + w, 30, const Radius.circular(4)),
      Paint()..color = const Color(0xDD101010),
    );
    _text.render(canvas, label, Vector2(14, 11));
  }
}
