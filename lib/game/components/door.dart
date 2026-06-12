import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';
import '../core/aabb.dart';
import '../core/interactable.dart';
import '../escape_game.dart';
import '../ui/symbols.dart';
import 'brickwork.dart';

/// A door: stand in front of it and press interact to walk through
/// (STYLE_GUIDE.md §6: rounded portal arch; goal-green when open, padlock
/// pictogram when locked).
class Door extends PositionComponent
    with HasGameReference<EscapeGame>
    implements Interactable {
  Door(Vector2 position, Vector2 size,
      {required this.exitName,
      this.lockedByRule = false,
      this.opensOnSolve = false,
      this.secret = false,
      this.glyph})
      : super(position: position, size: size);

  /// A hidden passage: renders as cracked brickwork, never prompts until
  /// discovered (the crack is the only tell). First use marks it discovered
  /// — it then shows a dark gap and appears on the map (M7).
  final bool secret;

  bool get discovered => !secret || game.isSecretDiscovered(exitName);

  /// Name resolved through the world graph (LEVEL_FORMAT.md §2).
  final String exitName;

  /// Discipline marker drawn directly on the door body (SYMBOLS §5) —
  /// what kind of puzzle lies through here.
  final SymbolId? glyph;

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

  /// Undiscovered secrets never advertise (STYLE_GUIDE: the crack is the
  /// only tell); the press still works — that's the discovery.
  @override
  bool get promptHidden => secret && !discovered;

  @override
  void onInteract() {
    if (!open) return;
    if (secret && !discovered) game.discoverSecret(exitName, this);
    game.goThrough(exitName);
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
    if (secret) {
      _renderSecret(canvas, p);
      return;
    }
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
    // Everything a door says is painted ON the door — glyphs are
    // architecture, not floating UI (STYLE_GUIDE §2 rule 9).
    // Upper body: the discipline glyph (what kind of puzzle lies through).
    final discipline = glyph;
    if (discipline != null) {
      final g = size.x * 0.55;
      canvas.save();
      canvas.translate((size.x - g) / 2, size.y * 0.14);
      drawSymbol(canvas, discipline, g, p.ink);
      canvas.restore();
    }
    // Lower body: the status glyph (standard signage — ISO no-entry when
    // closed, open padlock when solved). Only on sides that can be locked;
    // flips live on solve.
    if (_lockable) {
      final g = size.x * 0.5;
      canvas.save();
      canvas.translate((size.x - g) / 2, size.y * 0.55);
      drawSymbol(
        canvas,
        isOpen ? SymbolId.unlocked : SymbolId.noEntry,
        g,
        isOpen ? p.ink : p.accentDanger,
      );
      canvas.restore();
    }
  }

  /// Secret passage rendering: undiscovered = a wall panel whose only tell
  /// is cracked mortar; discovered = a dark gap in the brickwork.
  void _renderSecret(Canvas canvas, dynamic p) {
    final rect = size.toRect();
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(r, Paint()..color = p.surface);
    paintBrickCourses(canvas, r, p.ink);
    final crack = Paint()
      ..color = p.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    // The tell: a jagged crack down the panel + crumbs at the base.
    final path = Path()
      ..moveTo(size.x * 0.55, 2)
      ..lineTo(size.x * 0.40, size.y * 0.3)
      ..lineTo(size.x * 0.62, size.y * 0.55)
      ..lineTo(size.x * 0.45, size.y * 0.8)
      ..lineTo(size.x * 0.52, size.y - 2);
    canvas.drawPath(path, crack);
    canvas.drawCircle(Offset(size.x * 0.3, size.y - 3), 2, Paint()..color = p.ink);
    canvas.drawCircle(Offset(size.x * 0.7, size.y - 4), 2.5, Paint()..color = p.ink);
    if (discovered) {
      // Ajar: a dark slit where the panel has swung inward.
      canvas.drawRRect(
        RRect.fromLTRBR(size.x * 0.15, size.y * 0.12, size.x * 0.85, size.y,
            const Radius.circular(4)),
        Paint()..color = p.ink.withValues(alpha: 0.75),
      );
    }
  }
}
