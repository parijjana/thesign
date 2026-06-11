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
  Door(Vector2 position, Vector2 size,
      {required this.exitName,
      this.lockedByRule = false,
      this.opensOnSolve = false})
      : super(position: position, size: size);

  /// Name resolved through the world graph (LEVEL_FORMAT.md §2).
  final String exitName;

  /// Optional special gate: shut until the node's `unlock` rule is satisfied.
  final bool lockedByRule;

  /// A passage room's EXIT side (GDD §4): shut until the room is solved —
  /// true on the room's own exit door AND on the neighbor's door leading
  /// into that side, so the lock reads identically from both directions.
  final bool opensOnSolve;

  bool get open {
    if (lockedByRule && !game.isUnlockSatisfied()) return false;
    if (opensOnSolve && !game.isSolvedSide(exitName)) return false;
    return true;
  }

  @override
  Aabb get interactZone =>
      Aabb(position.x - 6, position.y, size.x + 12, size.y);

  /// Locked doors don't prompt — the padlock already says it all.
  @override
  bool get canInteract => open;

  @override
  void onInteract() {
    if (open) game.goThrough(exitName);
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

  /// Does this door have a lock condition on THIS side? Only such doors
  /// carry a status sign — always-open doors say nothing.
  bool get _lockable => lockedByRule || opensOnSolve;

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
      // Padlock pictogram on the door body.
      final glyph = size.x * 0.7;
      canvas.save();
      canvas.translate((size.x - glyph) / 2, size.y * 0.3);
      drawSymbol(canvas, SymbolId.locked, glyph, p.ink);
      canvas.restore();
    }

    // Status sign above the door (standard signage — ISO no-entry when
    // closed, open padlock in goal-green when open). Only on the side that
    // can be locked; flips live when the room is solved.
    if (_lockable) {
      const glyphSize = 22.0;
      final cx = size.x / 2;
      const top = -36.0;
      final board = RRect.fromLTRBR(
        cx - glyphSize / 2 - 4,
        top - 4,
        cx + glyphSize / 2 + 4,
        top + glyphSize + 4,
        const Radius.circular(5),
      );
      canvas.drawRRect(board, Paint()..color = p.accentNeutral);
      canvas.drawRRect(
        board,
        Paint()
          ..color = p.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.save();
      canvas.translate(cx - glyphSize / 2, top);
      drawSymbol(
        canvas,
        isOpen ? SymbolId.unlocked : SymbolId.noEntry,
        glyphSize,
        isOpen ? p.accentGoal : p.accentDanger,
      );
      canvas.restore();
    }
  }
}
