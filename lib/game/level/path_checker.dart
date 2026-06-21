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

  /// Labels (id or exit name) of doors/goal-levers the player can never stand
  /// in front of.
  final List<String> unreachableDoors;

  bool get ok => unreachableDoors.isEmpty;
}

/// Portal soft-lock report (the exit_hall trap): every teleporter portal must
/// be both ACTIVATABLE on arrival and reachable from EVERY way the player can
/// enter the room — otherwise a player who walks in (e.g. via a high one-way
/// door) is stranded with no usable way out. Empty = safe.
class PortalSafetyResult {
  PortalSafetyResult(this.violations);

  final List<String> violations;

  bool get ok => violations.isEmpty;
}

const _res = 2; // grid cells per tile (half-tile resolution)
const _playerW = 2; // cells (1 tile — a touch wider than the real 0.7t)
const _playerH = 4; // cells (2 tiles — a touch taller than the real 1.6t)
const _jumpBudget = 6; // up-steps per jump (3 tiles ≈ the real 3.25t rise)

/// A built navigation grid for one level: solids + swim cells + jump budget,
/// independent of where the player starts. Flood it from any spawn point.
class _Nav {
  _Nav(this.w, this.h, this.solid, this.swimmable, this.jumpBudget);

  final int w;
  final int h;
  final List<List<bool>> solid;
  final List<List<bool>> swimmable;
  final int jumpBudget;

  bool _cellClear(int x, int y) =>
      x >= 0 && y >= 0 && x < w && y < h && !solid[y][x];

  /// Player fits with feet at (x, feetY) — x is the left of its 2 columns.
  bool _fits(int x, int feetY) {
    for (var dx = 0; dx < _playerW; dx++) {
      for (var dy = 0; dy < _playerH; dy++) {
        if (!_cellClear(x + dx, feetY - dy)) return false;
      }
    }
    return true;
  }

  bool _supported(int x, int feetY) {
    if (feetY + 1 >= h) return true; // resting on the level's bottom edge
    // Standing on solid, OR treading water (with flippers) at this cell.
    if (solid[feetY + 1][x] || solid[feetY + 1][x + 1]) return true;
    return swimmable[feetY][x] || swimmable[feetY][x + 1];
  }

  /// Flood from one spawn tile; returns the grid of cells the player can STAND
  /// on (feet position), the basis for "can reach a door/portal".
  List<List<bool>> standingFrom(TilePoint from) {
    // BFS over (x, feetY, jumpBudget): budget spends on upward steps and
    // refills when standing; falling and lateral movement are free.
    final visited = List.generate(
        h, (_) => List.generate(w, (_) => List.filled(jumpBudget + 1, false)));
    final standing = List.generate(w, (_) => List.filled(h, false));

    final queue = <(int, int, int)>[];
    void push(int x, int feetY, int budget) {
      if (!_fits(x, feetY)) return;
      if (_supported(x, feetY)) {
        budget = jumpBudget; // landing refills the jump
        standing[x][feetY] = true;
      }
      if (visited[feetY][x][budget]) return;
      visited[feetY][x][budget] = true;
      queue.add((x, feetY, budget));
    }

    final sx = (from.x * _res).round();
    final sy = ((from.y + 1) * _res - 1).round();
    push(sx, sy, jumpBudget);
    while (queue.isNotEmpty) {
      final (x, y, b) = queue.removeLast();
      final grounded = _supported(x, y);
      push(x - 1, y, b); // lateral
      push(x + 1, y, b);
      if (b > 0 || grounded) push(x, y - 1, grounded ? jumpBudget - 1 : b - 1);
      push(x, y + 1, b); // fall (budget held until landing)
    }
    return standing;
  }

  /// Can the player STAND overlapping a target's frame? (Used for doors,
  /// goal levers, and portals — gates are excluded from `solid`, so a lever
  /// behind its mechanism gate counts as reachable in this optimistic model.)
  bool canStandAt(EntityData e, List<List<bool>> standing) {
    final x0 = (e.x * _res).floor() - _playerW;
    final x1 = ((e.x + e.w) * _res).ceil();
    final feet = ((e.y + e.h) * _res).round() - 1;
    for (var x = x0; x <= x1; x++) {
      for (var y = feet - 2; y <= feet + 1; y++) {
        if (x >= 0 && x < w && y >= 0 && y < h && standing[x][y]) return true;
      }
    }
    return false;
  }
}

_Nav _buildNav(LevelData level) {
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
    // A ramp is a non-rectangular solid: rasterize the triangle column by
    // column (fill from the slope surface down to the base) so the flood-fill
    // can stand on the incline.
    if (e.type == 'ramp') {
      final highLeft = (e.props['highSide'] as String? ?? 'left') == 'left';
      final base = e.y + e.h;
      final cols = (e.w * _res).ceil();
      for (var i = 0; i < cols; i++) {
        final frac = (i + 0.5) / cols; // 0..1 across the ramp
        final surf = highLeft ? e.y + e.h * frac : base - e.h * frac;
        fillRect(e.x + i / _res, surf, 1 / _res, base - surf);
      }
    }
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

  return _Nav(w, h, solid, swimmable, jumpBudget);
}

PathCheckResult checkDoorReachability(LevelData level) {
  final nav = _buildNav(level);
  final standing = nav.standingFrom(level.start);

  // Every door must be reachable, and every lever (the goal switch each room's
  // exit now hangs on) too — an unreachable lever is a soft-lock.
  final unreachable = <String>[];
  for (final e in level.entities) {
    if (e.type == 'door') {
      if (!nav.canStandAt(e, standing)) {
        unreachable.add(e.id ?? (e.props['exit'] as String? ?? 'door'));
      }
    } else if (e.type == 'lever') {
      if (!nav.canStandAt(e, standing)) unreachable.add(e.id ?? 'lever');
    }
  }
  return PathCheckResult(unreachable);
}

/// PORTAL SOFT-LOCK GUARD (the exit_hall trap, GDD §4 kindness law): if the
/// player can reach a room, they must always be able to LEAVE it through its
/// portal. For every teleporter portal (a teleporter with an `exit`, i.e. not
/// the decorative `isExit` pad) this checks two things:
///   1. It is activatable on arrival — `availableFromStart`, so reaching the
///      room is enough to open the iris (no hidden prerequisite can strand a
///      player standing right next to their only way out).
///   2. It is physically reachable from EVERY entry point of the room (`start`
///      plus every named `entryPoints`), not just the authored start — so a
///      one-way high door can't drop the player somewhere the portal can't be
///      walked to.
/// The meadow is exempt: it's open-sky overworld whose portals are a
/// deliberate progress meter, and it is never a dead-end (GDD §3 twist).
PortalSafetyResult checkPortalSafety(LevelData level) {
  final violations = <String>[];
  if (level.type == NodeType.meadow) return PortalSafetyResult(violations);

  final portals = level.entities
      .where((e) =>
          e.type == 'teleporter' &&
          e.props['exit'] != null &&
          (e.props['isExit'] as bool? ?? false) == false)
      .toList();
  if (portals.isEmpty) return PortalSafetyResult(violations);

  final nav = _buildNav(level);
  // Every distinct spawn point the player can arrive at.
  final spawns = <TilePoint>[level.start, ...level.entryPoints.values];
  final standingBySpawn = [for (final s in spawns) nav.standingFrom(s)];

  for (final portal in portals) {
    final label = portal.props['exit'] as String;
    if ((portal.props['availableFromStart'] as bool? ?? false) == false) {
      violations.add('portal "$label" is not availableFromStart — reaching '
          'the room would not guarantee a way out');
    }
    for (var i = 0; i < spawns.length; i++) {
      if (!nav.canStandAt(portal, standingBySpawn[i])) {
        violations.add('portal "$label" is unreachable from entry '
            '(${spawns[i].x}, ${spawns[i].y}) — a player arriving there is '
            'stranded');
      }
    }
  }
  return PortalSafetyResult(violations);
}
