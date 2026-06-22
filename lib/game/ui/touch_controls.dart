import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../escape_game.dart';
import 'symbols.dart';

/// On-screen touch controls (GDD §10, ROADMAP M5): a left move-pad and right
/// action buttons that WRITE into the same [GameInput] the keyboard does — so
/// game logic stays input-agnostic (ARCHITECTURE §5.4). Symbols only, on the
/// neutral chips the rest of the HUD uses. Mounted only on touch platforms
/// (see EscapeGame.useTouchControls).
///
/// Buttons set intents directly on press/release rather than in update(), so
/// the value is already current when the player component reads it the same
/// frame (component update order is otherwise unspecified).
class TouchControls extends PositionComponent with HasGameReference<EscapeGame> {
  TouchControls() : super(priority: 60);

  bool _leftHeld = false;
  bool _rightHeld = false;
  final _buttons = <_TouchButton>[];

  // A tap is too brief for the keyboard-style variable-jump hold, so the rise
  // would get cut to a hop. Latch jumpHeld for at least one full rise (-500 →
  // -130 cut threshold over ~0.31 s) so a tap always gives a full jump
  // (kinder than a precision hold — GDD §2). A longer press still extends it.
  static const double _jumpMinHold = 0.33;
  bool _jumpFinger = false;
  double _jumpHold = 0;

  /// One uniform button size for every control (px). Player-adjustable in the
  /// M7 settings shell (wire this to a saved setting) — ROADMAP M7.
  static const double btn = 68;
  static const double _edge = 26; // gap from the screen edge
  static const double _gap = 16; // gap between paired buttons

  @override
  Future<void> onLoad() async {
    // Buttons glue to the real screen corners (offX/offY = gap from that edge
    // to the button), so they stay reachable on any device aspect.
    const near = _edge;
    const far = _edge + btn + _gap;
    _buttons.addAll([
      // Left thumb: move pad (bottom-left).
      _TouchButton(_Btn.left, this, btn, _Corner.bottomLeft, near, _edge),
      _TouchButton(_Btn.right, this, btn, _Corner.bottomLeft, far, _edge),
      // Right thumb: jump nearest the corner, interact inboard (bottom-right).
      _TouchButton(_Btn.jump, this, btn, _Corner.bottomRight, near, _edge),
      _TouchButton(_Btn.interact, this, btn, _Corner.bottomRight, far, _edge),
      // Meta: claw/restart top-right, pause top-left (the HUD row is hidden on
      // touch, so the overlay owns these).
      _TouchButton(_Btn.restart, this, btn, _Corner.topRight, near, _edge),
      _TouchButton(_Btn.pause, this, btn, _Corner.topLeft, near, _edge),
    ]);
    addAll(_buttons);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size; // buttons self-place via their own onGameResize
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_jumpHold > 0) _jumpHold -= dt;
    // Hold the jump while the finger is down OR the min-hold is still running.
    game.input.jumpHeld = _jumpFinger || _jumpHold > 0;
  }

  /// A button reports its press/release; we translate to input intents.
  void _press(_Btn b, bool down) {
    final input = game.input;
    switch (b) {
      case _Btn.left:
        _leftHeld = down;
        input.moveAxis = _axis();
      case _Btn.right:
        _rightHeld = down;
        input.moveAxis = _axis();
      case _Btn.jump:
        _jumpFinger = down;
        if (down) {
          _jumpHold = _jumpMinHold;
          input.jumpHeld = true;
          input.jumpPressed = true;
        }
      case _Btn.interact:
        if (down) input.interactPressed = true;
      case _Btn.restart:
        if (down) input.restartPressed = true;
      case _Btn.pause:
        if (down) input.pausePressed = true;
    }
  }

  double _axis() => (_rightHeld ? 1.0 : 0.0) - (_leftHeld ? 1.0 : 0.0);
}

enum _Btn { left, right, jump, interact, restart, pause }

enum _Corner { bottomLeft, bottomRight, topRight, topLeft }

class _TouchButton extends PositionComponent
    with TapCallbacks, HasGameReference<EscapeGame> {
  _TouchButton(
      this.kind, this.owner, double side, this.corner, this.offX, this.offY)
      : super(size: Vector2.all(side), priority: 60);

  final _Btn kind;
  final TouchControls owner;
  final _Corner corner;

  /// Gap from the anchored screen edge to this button (px).
  final double offX;
  final double offY;
  bool _down = false;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final isRight =
        corner == _Corner.bottomRight || corner == _Corner.topRight;
    final isTop = corner == _Corner.topRight || corner == _Corner.topLeft;
    final x = isRight ? size.x - offX - this.size.x : offX;
    final y = isTop ? offY : size.y - offY - this.size.y;
    position = Vector2(x, y);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _down = true;
    owner._press(kind, true);
  }

  @override
  void onTapUp(TapUpEvent event) => _release();

  @override
  void onTapCancel(TapCancelEvent event) => _release();

  void _release() {
    _down = false;
    owner._press(kind, false);
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final r = size.x / 2;
    final c = Offset(r, r);
    // Thumb-friendly round chip; brightens while held.
    canvas.drawCircle(
      c,
      r,
      Paint()..color = p.accentNeutral.withValues(alpha: _down ? 0.95 : 0.6),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = p.ink.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final ink = p.ink.withValues(alpha: 0.9);
    final g = size.x * 0.5;
    switch (kind) {
      case _Btn.left:
        _arrow(canvas, c, g * 0.5, _Dir.left, ink);
      case _Btn.right:
        _arrow(canvas, c, g * 0.5, _Dir.right, ink);
      case _Btn.jump:
        _arrow(canvas, c, g * 0.5, _Dir.up, ink);
      case _Btn.interact:
        _glyph(canvas, SymbolId.interact, g, ink);
      case _Btn.restart:
        _glyph(canvas, SymbolId.restartClaw, g, ink);
      case _Btn.pause:
        _glyph(canvas, SymbolId.pause, g, ink);
    }
  }

  void _glyph(Canvas canvas, SymbolId id, double side, Color color) {
    canvas.save();
    canvas.translate((size.x - side) / 2, (size.y - side) / 2);
    drawSymbol(canvas, id, side, color);
    canvas.restore();
  }

  void _arrow(Canvas canvas, Offset c, double s, _Dir dir, Color color) {
    final path = Path();
    switch (dir) {
      case _Dir.left:
        path
          ..moveTo(c.dx - s, c.dy)
          ..lineTo(c.dx + s * 0.7, c.dy - s)
          ..lineTo(c.dx + s * 0.7, c.dy + s);
      case _Dir.right:
        path
          ..moveTo(c.dx + s, c.dy)
          ..lineTo(c.dx - s * 0.7, c.dy - s)
          ..lineTo(c.dx - s * 0.7, c.dy + s);
      case _Dir.up:
        path
          ..moveTo(c.dx, c.dy - s)
          ..lineTo(c.dx - s, c.dy + s * 0.7)
          ..lineTo(c.dx + s, c.dy + s * 0.7);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..strokeJoin = StrokeJoin.round,
    );
  }
}

enum _Dir { left, right, up }
