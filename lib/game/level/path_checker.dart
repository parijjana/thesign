import 'level_model.dart';

/// THE PATH CHECKER — proves a player can physically reach every door in a
/// level (LEVEL_FORMAT.md §6 authoring conventions). Runs over level JSON in
/// the test suite, so an unreachable door fails CI before it can ship.
///
/// Model: a coarse flood-fill platformer solver on a half-tile grid.
/// - Solids: `floor` + `wall` entities plus the synthesized ceiling.
///   Gates are EXCLUDED (checked in their solved/open state) and blocks are
///   EXCLUDED (they're movable aids, not obstacles).
/// - The player is 1×2 tiles (slightly generous), can rise ~3 tiles per
///   jump, and falls freely.
/// - Deliberately OPTIMISTIC about horizontal air control (it will not
///   catch a too-wide gap), but exact about walls, ceilings, and jump
///   height — i.e. it catches dead ends like a full-height pillar between
///   the player and a door. Tighter arcs can come with the M5.7 pass.
class PathCheckResult {
  PathCheckResult(this.unreachableDoors);

  /// Door labels (id or exit name) the player can never stand in front of.
  final List<String> unreachableDoors;

  bool get ok => unreachableDoors.isEmpty;
}

const _res = 2; // grid cells per tile (half-tile resolution)
const _playerW = 2; // cells (1 tile — a touch wider than the real 0.7t)
const _playerH = 4; // cells (2 tiles — a touch taller than the real 1.6t)
const _jumpBudget = 6; // up-steps per jump (3 tiles ≈ the real 3.25t rise)

PathCheckResult checkDoorReachability(LevelData level) {
  final w = (level.widthTiles * _res).round();
  final h = (level.heightTiles * _res).round();
  final solid = List.generate(h, (_) => List.filled(w, false));

  // Blocks extend the player's reach: each carryable block in the room can
  // add ~1 tile of standing height to a stack (that's the stacking puzzle).
  final blockBonus =
      2 * level.entities.where((e) => e.type == 'pushable_block').length;
  // Assumed powerups (docs/POWERUPS.md §3): spring boots double the jump;
  // flippers make water a standable surface (swim routes connect).
  final hasSpring = level.assumePowerups.contains('springBoots');
  final hasFlippers = level.assumePowerups.contains('flippers');
  final jumpBudget = (hasSpring ? 2 * _jumpBudget : _jumpBudget) + blockBonus;

  void fillRect(double x, double y, double rw, double rh) {
    final x0 = (x * _res).floor().clamp(0, w);
    final x1 = ((x + rw) * _res).ceil().clamp(0, w);
    final y0 = (y * _res).floor().clamp(0, h);
    final y1 = ((y + rh) * _res).ceil().clamp(0, h);
    for (var yy = y0; yy < y1; yy++) {
      for (var xx = x0; xx < x1; xx++) {
        solid[yy][xx] = true;
      }
    }
  }

  for (final e in level.entities) {
    if (e.type == 'floor' || e.type == 'wall') fillRect(e.x, e.y, e.w, e.h);
  }
  fillRect(0, 0, level.widthTiles, synthesizedCeilingTiles(level.type));

  // With flippers the player swims, so water cells act as standable surface
  // — the checker can route through them.
  final swimmable = List.generate(h, (_) => List.filled(w, false));
  if (hasFlippers) {
    for (final e in level.entities) {
      if (e.type != 'water') continue;
      final x0 = (e.x * _res).floor().clamp(0, w);
      final x1 = ((e.x + e.w) * _res).ceil().clamp(0, w);
      final y0 = (e.y * _res).floor().clamp(0, h);
      final y1 = ((e.y + e.h) * _res).ceil().clamp(0, h);
      for (var yy = y0; yy < y1; yy++) {
        for (var xx = x0; xx < x1; xx++) {
          if (!solid[yy][xx]) swimmable[yy][xx] = true;
        }
      }
    }
  }

  bool cellClear(int x, int y) =>
      x >= 0 && y >= 0 && x < w && y < h && !solid[y][x];

  /// Player fits with feet at (x, feetY) — x is the left of its 2 columns.
  bool fits(int x, int feetY) {
    for (var dx = 0; dx < _playerW; dx++) {
      for (var dy = 0; dy < _playerH; dy++) {
        if (!cellClear(x + dx, feetY - dy)) return false;
      }
    }
    return true;
  }

  bool supported(int x, int feetY) {
    if (feetY + 1 >= h) return true; // resting on the level's bottom edge
    // Standing on solid, OR treading water (with flippers) at this cell.
    if (solid[feetY + 1][x] || solid[feetY + 1][x + 1]) return true;
    return swimmable[feetY][x] || swimmable[feetY][x + 1];
  }

  // BFS over (x, feetY, jumpBudget): budget spends on upward steps and
  // refills when standing; falling and lateral movement are free.
  final visited = List.generate(
      h, (_) => List.generate(w, (_) => List.filled(jumpBudget + 1, false)));
  final standingReached = List.generate(w, (_) => List.filled(h, false));

  final startX = (level.start.x * _res).round();
  final startY = ((level.start.y + 1) * _res - 1).round();
  final queue = <(int, int, int)>[];

  void push(int x, int feetY, int budget) {
    if (!fits(x, feetY)) return;
    if (supported(x, feetY)) {
      budget = jumpBudget; // landing refills the jump
      standingReached[x][feetY] = true;
    }
    if (visited[feetY][x][budget]) return;
    visited[feetY][x][budget] = true;
    queue.add((x, feetY, budget));
  }

  push(startX, startY, jumpBudget);
  while (queue.isNotEmpty) {
    final (x, y, b) = queue.removeLast();
    final grounded = supported(x, y);
    push(x - 1, y, b); // lateral
    push(x + 1, y, b);
    if (b > 0 || grounded) push(x, y - 1, grounded ? jumpBudget - 1 : b - 1);
    push(x, y + 1, b); // fall (budget held until landing)
  }

  // A door is reachable if the player can STAND overlapping its frame.
  final unreachable = <String>[];
  for (final e in level.entities) {
    if (e.type != 'door') continue;
    final x0 = (e.x * _res).floor() - _playerW;
    final x1 = ((e.x + e.w) * _res).ceil();
    final feet = ((e.y + e.h) * _res).round() - 1;
    var found = false;
    for (var x = x0; x <= x1 && !found; x++) {
      for (var y = feet - 2; y <= feet + 1 && !found; y++) {
        if (x >= 0 && x < w && y >= 0 && y < h && standingReached[x][y]) {
          found = true;
        }
      }
    }
    if (!found) {
      unreachable.add(e.id ?? (e.props['exit'] as String? ?? 'door'));
    }
  }
  return PathCheckResult(unreachable);
}
