import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../core/interactable.dart';
import '../escape_game.dart';
import '../ui/symbols.dart';

/// A door: stand in front of it and press interact to walk through
/// (STYLE_GUIDE.md §6: rounded portal arch; goal-green when open, padlock
/// pictogram when locked).
class Door extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Interactable {
  Door(Vector2 position, Vector2 size, {required this.exitName, this.lockedByRule = false})
      : super(position: position, size: size);

  /// Name resolved through the world graph (LEVEL_FORMAT.md §2).
  final String exitName;

  /// True for a hub's onward door: stays shut until the hub's unlock rule is
  /// satisfied (GDD §4).
  final bool lockedByRule;

  bool get open => !lockedByRule || game.isUnlockSatisfied();

  @override
  Aabb get interactZone =>
      Aabb(position.x - 6, position.y, size.x + 12, size.y);

  @override
  void onInteract() {
    if (open) game.goThrough(exitName);
    // Locked: nothing happens for now — fb_error popup arrives in M4.
  }

  @override
  void onMount() {
    super.onMount();
    game.interactables.add(this);
  }

  @override
  void onRemove() {
    game.interactables.remove(this);
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final p = game.palette;
    final isOpen = open;
    // Portal arch: rounded top, flat bottom.
    final arch = RRect.fromRectAndCorners(
      size.toRect(),
      topLeft: Radius.circular(size.x / 2),
      topRight: Radius.circular(size.x / 2),
    );
    canvas.drawRRect(
        arch, Paint()..color = isOpen ? p.accentGoal : p.surface);
    canvas.drawRRect(
      arch,
      Paint()
        ..color = p.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Config.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    if (!isOpen) {
      // Padlock pictogram, centered.
      final glyph = size.x * 0.7;
      canvas.save();
      canvas.translate((size.x - glyph) / 2, size.y * 0.3);
      drawSymbol(canvas, SymbolId.locked, glyph, p.ink);
      canvas.restore();
    }
  }
}
