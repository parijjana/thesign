import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../escape_game.dart';
import 'symbols.dart';

/// Feedback popup glyphs (SYMBOLS §6b / STYLE_GUIDE §8d): instant, wordless
/// cause-and-effect. Quick scale-in, hold ~1 s, fade. Events, not states.
enum FeedbackKind { error, success, idea }

class FeedbackPopups extends PositionComponent
    with HasGameReference<EscapeGame> {
  FeedbackPopups() : super(position: Vector2.zero(), priority: 60);

  final List<_Popup> _active = [];

  void emit(FeedbackKind kind, Vector2 worldPos) {
    _active.add(_Popup(kind, worldPos.clone()));
  }

  @override
  void update(double dt) {
    for (final p in _active) {
      p.age += dt;
    }
    _active.removeWhere((p) => p.age > _Popup.life);
  }

  @override
  void render(Canvas canvas) {
    final palette = game.palette;
    for (final p in _active) {
      // Scale-in (0–0.12s), hold, fade-out (last 0.25s).
      final scale = math.min(1.0, p.age / 0.12);
      final fade = math.min(1.0, (_Popup.life - p.age) / 0.25);
      // The error glyph gives a tiny indignant shake.
      final shake = p.kind == FeedbackKind.error && p.age < 0.4
          ? math.sin(p.age * 50) * 2
          : 0.0;

      final color = switch (p.kind) {
        FeedbackKind.error => palette.accentDanger,
        FeedbackKind.success => palette.accentGoal,
        FeedbackKind.idea => palette.accentHint,
      };
      final glyph = switch (p.kind) {
        FeedbackKind.error => SymbolId.error,
        FeedbackKind.success => SymbolId.unlocked,
        FeedbackKind.idea => SymbolId.hint,
      };

      const half = 14.0;
      final cx = p.pos.x + shake;
      final cy = p.pos.y - p.age * 8; // drifts gently upward
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(scale * 1.0);
      final chip = RRect.fromLTRBR(
          -half, -half, half, half, const Radius.circular(7));
      canvas.drawRRect(
          chip,
          Paint()
            ..color = palette.accentNeutral.withValues(alpha: 0.9 * fade));
      canvas.drawRRect(
        chip,
        Paint()
          ..color = palette.ink.withValues(alpha: fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
      canvas.translate(-11, -11);
      drawSymbol(canvas, glyph, 22, color.withValues(alpha: fade));
      canvas.restore();
    }
  }
}

class _Popup {
  _Popup(this.kind, this.pos);

  static const life = 1.0; // seconds

  final FeedbackKind kind;
  final Vector2 pos;
  double age = 0;
}
