# Powerups & the Expansive Castle *(living build plan — the resume artifact)*

> The Metroidvania expansion: hidden-room **powerups** that are also **gates** — they open routes
> you saw earlier but couldn't pass. This single mechanic delivers everything the mandate asked:
> multiple paths to the exit, replayability, reasons to return to old corridors, and Mario-style
> hidden-room payoffs. It also REALIZES the design-gated Field Kit (GDD §9b) — powerups ARE the kit.
>
> If a session dies mid-build: read this + MAZE.md + M6_PLAN.md, continue from the first `[ ]`.

## 1. The core loop (why this creates depth)
1. While exploring, you hit a **barrier** you can't pass (deep water, a too-high ledge, a wide
   chasm, a dark room). It's visibly there, clearly impassable — a promise.
2. Somewhere else, often in a **hidden room**, you find the **powerup** that beats that barrier.
3. You **return** to the barrier — now passable — opening a wing of harder puzzles, more etchings,
   another powerup, and an **alternate route toward the exit**.
4. The exit is reachable **multiple ways**: the base puzzle route (kind, always-available) AND
   powerup shortcuts/wings. Completionists chase every powerup + etching; a kid can still finish.

Kindness preserved: powerups NEVER gate the only path to the exit (the base capstone route always
works). Powerups gate BONUS wings and SHORTCUTS. Enforced by the validators (§6).

## 2. The powerups (permanent, visible, kid-legible)
Each is found once, kept forever, **shown on the pictogram figure** (no invisible stat buffs —
STYLE_GUIDE rule 9), and persists per profile. They reuse the fixed verb budget (move/jump/interact)
— a powerup changes what a verb DOES, it never adds a button.

| Powerup | Glyph | What it does | Gates (barriers it beats) | Figure tell |
|---|---|---|---|---|
| **Flippers** | swim-fin | Water stops resetting you — you **float & swim** (4-dir, slow). Resolves the icebox float idea. | deep water pools, underwater tunnels | fins on feet |
| **Spring boots** | coiled spring | **Double jump** (one extra mid-air jump). | high ledges, tall shafts | spring under feet |
| **Grapple claw** | hook | At marked **anchor sockets**, pull across a wide gap (socket-constrained, GDD §9b — no free aim). | wide chasms | small claw in hand |
| **Lantern** | lamp | Lights a **dark room** (dark rooms render near-black until lit). | dark passages | glow around figure |

Build order by impact: **Flippers → Spring boots** (this session), then Grapple → Lantern (later
phases). Flippers first because water is *everywhere* — it instantly turns the whole castle's
hazards into a second map.

## 3. Engine design (enough to rebuild from scratch)
- **`Powerup` enum** (`lib/game/powerups.dart`): flippers, springBoots, grapple, lantern.
- **Ownership**: `EscapeGame.powerups: Set<Powerup>`; `player.has(Powerup)`. Persisted in
  `Progress.powerups` (back-compat default empty). F2 clears.
- **Pickup**: `PowerupPickup` component (like Etching) — a pedestal holding the glyph; walk up to
  collect → `game.collectPowerup(p)` → add to set, `fb_success`, autosave, brief teaching pulse.
- **HUD**: a small row of owned-powerup glyphs (bottom-left, on neutral chips like the top HUD).
- **Flippers / swim** (`player.dart` + `water_pool.dart`):
  - WaterPool: if `player.has(flippers)` → NO reset; else current reset behavior.
  - Player gains `_inWater` (set by WaterPool each frame it overlaps). With flippers + in water:
    buoyancy (gentle rise toward surface), `moveAxis` drives slow horizontal, jump = swim up,
    no-input = slow sink; gravity damped; swim pose. Without flippers, in water → reset (unchanged).
  - Blocks unaffected (still sink → claw fetches them) — only the PLAYER swims.
- **Spring boots / double jump** (`player.dart`):
  - `_jumpsUsed`; on jump: grounded/coyote → jump, `_jumpsUsed=1`. Airborne + has(springBoots) +
    `_jumpsUsed<2` + buffered press → second jump, `_jumpsUsed=2`, small "spring" squash. Reset on land.
- **Gated passage** (`gated_door`/`gate_block`): a solid that's absent (passable) when the player
  owns its `requires` powerup — for non-water/non-jump gates (grapple/lantern later). For now,
  water depth + ledge height ARE the gates (no new entity needed for flippers/boots).
- **Path checker** (`path_checker.dart`): per-level `"assume": ["flippers","springBoots"]` top-level
  prop. flippers → water cells count as standing floor (swim routes connect). springBoots →
  jumpBudget ×2. So powerup-gated rooms verify reachability under their assumed kit, and base rooms
  stay strict. A door behind a barrier must live in a level that `assume`s the needed powerup.

## 4. World expansion (the "hours of gameplay")
Layer onto the existing 22-node castle (don't rebuild it). New content hangs off powerup gates.

### Phase A — Flippers wing *(this session)*
- `secret_grotto` (hidden, off corridor_04 the water corridor — a cracked wall): contains the
  **Flippers** pickup. The room is a short dry approach so it's findable without flippers.
- `room_dive` (Fluids puzzle, flipper-gated): reached by swimming DOWN through corridor_04's wide
  pool (without flippers you'd reset; with them you dive to a sunken door). Buoyancy puzzle:
  raise a float to ride up to the exit ledge. Exit → a NEW corridor `corridor_06` (Pearl street ◌).
- `corridor_06`: connects room_dive ↔ hub_03 (a flipper SHORTCUT skipping corridor_03's boulders).

### Phase B — Spring boots wing *(this session)*
- `secret_belfry` (hidden, off hub_03 high up — reach via the existing attic? or a cracked ceiling):
  contains **Spring boots**.
- `room_ascent` (Mechanics/Gravity, double-jump-gated): a vertical shaft of ledges only climbable
  with the double jump; goal lever at top opens a door to...
- a SECOND entrance to `exit_hall` (the multiple-paths-to-exit requirement): exit_hall gains a
  `high` door from room_ascent, so you can reach the exit via the spring-boots route OR the capstone.

### Phase C+ — later sessions (documented, not built yet)
- Grapple wing (wide-chasm corridor + bonus vault), Lantern wing (dark catacombs).
- An **Act IV** behind 2+ powerups: the hardest fusion puzzles, the "true" collectibles.
- Difficulty ramp: tag rooms easy/med/hard; later wings are harder; capstone-tier fusion in Act IV.
- A **third exit route** so the exit has 3 entrances (capstone / spring / grapple).

## 5. Replayability payload (reasons to return — mostly M7 screens, data now)
- **Castle map** (M7): shows powerup gates as locked icons → "I can reach that now!"
- **Etching gallery + powerup shelf** (M7 legend): visible completion %, empty slots tease content.
- **Powerups stamped into the legend** when found (the collection meta-game, GDD §9).
- Data we persist NOW so M7 can show it: `powerups`, `foundEtchings`, `discoveredSecrets`,
  `visitedNodes` (all already in Progress; add `powerups`).

## 6. Validators (extend the guards)
- Path checker: honor `assume` (above) so gated rooms are checked under their kit.
- Kindness validator: the EXIT must stay reachable WITHOUT any powerup (base route). Add a check:
  reachability from start, treating powerup-gated edges as absent, must still include `exit_hall`.
  (For now flipper/boot gates are GEOMETRY not graph edges, so the graph validator already sees the
  base route; the path checker per-level `assume` keeps geometry honest. When `gated_door` graph
  edges arrive, mark them `requires` and exclude from the kindness base-route check.)

## 7. Build checklist
**Phase 0 — design** [x] this doc.

**Phase 1 — powerup framework** [x]
- [x] `powerups.dart` enum; `Progress.powerups`; `EscapeGame.powerups` + collect/has + persistence + F2 clear.
- [x] `PowerupPickup` component (pedestal + glyph + auto-collect + fb_success).
- [x] powerup glyphs in symbols.dart (flippers, springBoots, grapple, lantern).
- [x] HUD owned-powerup row (PowerupHud, bottom-left).
- [x] loader: `powerup_pickup` entity type.

**Phase 2 — flippers/swim + spring boots/double-jump** [x]
- [x] water_pool: skip reset when player has flippers; registers in game.waterPools.
- [x] player: `inWater` (queried from waterPools) + swim physics + swim pose; double-jump with springBoots.
- [x] path_checker: `assume` prop (flippers→water-as-standable, springBoots→2× jump).

**Phase 3 — content (Flippers wing + Spring boots wing)** [x]
- [x] secret_grotto + Flippers pickup (off corridor_04); room_dive (underwater reward, assume flippers).
- [x] secret_belfry + Spring boots pickup (off hub_03); room_ascent (assume springBoots);
      exit_hall `high` door → SECOND path to the exit (capstone route + spring route).
- [x] world.json v3: 4 new rooms + entries; room↔room gating generalized (gatingRoomId) for
      capstone/ascent → exit_hall.
- [x] all guards green: path checker (w/ assume), direction, liveness, kindness. 82 tests.

**Phase 4 — verify + ship** [~]
- [x] analyze + tests + windows build + launch.
- [ ] USER PLAYTEST (swim feel, double-jump feel, wing pacing) — pending.
- [ ] docs: GDD §9b note (Field Kit realized as powerups); ROADMAP; memory — partial.

**Phase 5+ — NEXT SESSIONS (documented, not built):** grapple wing (wide-chasm corridor +
`gated_door` entity + anchor sockets), lantern wing (dark catacombs + dark-room render), Act IV
behind 2 powerups (hardest fusion puzzles), difficulty tags, a 3rd exit route. M7 map/legend
screens surface the powerup shelf + completion %.

## 8. Notes / risks
- Swim feel needs tuning (buoyancy, swim speed) — expect a pass after playtest.
- Double-jump makes some base rooms trivially easier; acceptable (it's a late find; base rooms
  stay solvable without it — path checker still passes base-budget).
- Keep the exit's BASE route (capstone) untouched so kindness holds no matter what.
- Powerup pickups are leaves → no cut-vertex risk.
