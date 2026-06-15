import '../core/aabb.dart';
import '../escape_game.dart';

/// THE weight system (shared by every weight sensor: pressure plates, the
/// counterweight lift). Returns the total weight, in block-units,
/// resting on [surface]'s top edge — **counting whole stacks**, because a
/// block on a block on a plate weighs 2, not 1 (real gravity). This replaces
/// the old "count objects overlapping a zone" hack, which silently dropped
/// stacked weight.
///
/// Each block weighs 1; the player weighs 1 — **plus the block in their arms**,
/// since a carried block's weight rides on the player (pick a block up while
/// standing on a plate and the total doesn't change — real gravity). Set
/// [countPlayer] false where a rider's own weight shouldn't load the sensor.
double weightOn(EscapeGame game, Aabb surface, {bool countPlayer = true}) {
  var total = 0.0;
  for (final b in game.blocks) {
    if (b.held || b.clawHeld) continue; // a held block weighs on the player below
    if (_restsOn(b.aabb, surface)) {
      // The block, plus everything stacked on top of it (recurse on its top).
      total += 1 + weightOn(game, b.aabb, countPlayer: countPlayer);
    }
  }
  if (countPlayer) {
    final p = game.player;
    if (!p.carried && _restsOn(p.aabb, surface)) {
      total += 1 + (p.isCarrying ? 1 : 0); // the player, plus any carried block
    }
  }
  return total;
}

/// True when [obj] is resting on [on]'s top edge (bottom touching, with real
/// horizontal overlap). The epsilon absorbs settle jitter.
bool _restsOn(Aabb obj, Aabb on) =>
    (obj.bottom - on.y).abs() <= 5 &&
    obj.x < on.right - 1 &&
    obj.right > on.x + 1;
