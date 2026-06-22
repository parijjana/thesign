# Roadmap

> Source of truth for build sequencing. What/why lives in [GDD.md](GDD.md);
> how in [ARCHITECTURE.md](ARCHITECTURE.md). Build top-to-bottom; don't pull later work forward.

## Guiding principle
Get a **vertical slice** playable as early as possible, then widen. Every milestone ends in
something runnable on **web + Windows**. Mobile is validated early but polished late.

## M0 — Project & spike *(de-risk Flame before committing)*
**Goal:** prove the stack, throwaway-quality.
- Init Flutter project; add `flame`. Confirm `flutter run -d chrome` and `-d windows` both work.
- Spike: render one `bg`-colored screen, draw a rounded-rect floor and a circle in `ink` via
  `render(Canvas)`. Move a box with the keyboard. Throw it away after.
- **Exit criteria:** confident in Flame's loop, render, and input on both targets.

## M1 — Foundations
**Goal:** the skeleton every later milestone builds on.
- `palette.dart` with the **Dungeon Amber** tokens (STYLE_GUIDE §3.1) + the `Palette` struct so
  discipline-coordinated palettes drop in later.
- `config.dart` (tile size, viewport, physics constants).
- Camera/viewport that letterboxes a fixed logical viewport identically on desktop & mobile aspect.
- `GameInput` abstraction + `keyboard_input.dart`.
- `symbols.dart` seeded with the core HUD glyphs (pause/resume/restart-claw/settings) — **no text**,
  establishing the symbols-only discipline from day one.
- **Exit criteria:** a themed empty room renders correctly and identically across window sizes.

## M2 — Movement, collision & reset (the "feel")
**Goal:** the minimal, forgiving controller + the no-death reset.
- Custom kinematic AABB resolver (`aabb.dart`, `collision_world.dart`).
- `PlayerComponent`: run + jump with coyote-time + jump-buffer; squash-on-land.
- `reset_controller.dart`: teleport-to-`start` + re-init kinematic bodies (the whole no-death model),
  with logic skippable for headless tests.
- `claw_reset.dart`: the excavator-claw animation (descend → scoop → carry → place → whirlwind →
  retract); state mutation fires on the whirlwind beat; input locked during play. Procedural
  placeholder visuals are fine — the claw gets its authored multi-part SVG sprite in M7.5.
- Static `floor`/`wall` components rendered in signage style.
- Tune until "minimal & simple" feels right (forgiving, no momentum mastery).
- Unit tests for the AABB resolver and reset.
- **Exit criteria:** run/jump around a hand-built test room, hit a test hazard, and watch the claw
  gently carry you back and whirlwind-reset the room — no death.

## M3 — Level pipeline & world graph
**Goal:** stop hard-coding; load from data; prove the hub-and-spoke graph.
- `level_model.dart`, `level_loader.dart`, `room_registry.dart`.
- `world.json` with a `corridor → hub → room` chain; load geometry from data per
  [LEVEL_FORMAT.md](LEVEL_FORMAT.md).
- Node transitions with correct entry placement; **hub room-selection** (enter a room, walk back out
  the entry door to the hub) and the hub `unlock` rule opening the onward door.
- `PuzzleScript` base + registry wiring (stub puzzle that marks solved on a switch).
- Loader + unlock-rule unit tests.
- **Exit criteria:** from a corridor, reach a hub, enter a room, back out, enter another, "solve"
  the stub, see the onward corridor unlock — all loaded from JSON.

## M4 — Vertical slice *(the milestone that matters)*
**Goal:** one complete, representative experience — the full loop, kid-tested.
- **Corridor with a spike pit:** non-lethal reset-to-corridor-start + warning sign telegraph.
- **Cul-de-sac hub with 2–3 rooms**, `unlock: anyOf 1` → onward door opens when any room is solved.
  Hub rooms **span disciplines** (GDD §4 variety rule): mechanics picks + the optics room below;
  each door carries its discipline glyph.
- **Mechanics rooms** (pressure plates, box stacking, **fulcrum lever**) with their scripts —
  Mechanics first since it needs the least new tech (per PUZZLES.md). Entering and backing out of
  rooms via the hub works smoothly.
- **One Optics room (mirror routing)** as the first "wow" discipline + its **indigo palette** (a
  per-room palette, proving the discipline-palette and beam systems early).
- All puzzle goals/quantities rendered as **symbols/visuals, no text** (the no-text rule in practice).
- **Feedback popups** (`fb_error` / `fb_idea` / `fb_success`, SYMBOLS §6b) wired to puzzle-script
  events — instant wordless cause-and-effect, in from the first playtest.
- **Carry/interact** verb (pick up/push) and **restart room** (claw) working.
- Save: autosave on transition/solve; resume on launch (`save_service.dart`). **Per-profile data
  model from day one** (avatar-select UI lands in M7) so profiles never need a retrofit.
- Player character animated via posture interpolation (idle/run/jump/land/carry).
- **Exit criteria:** launch → cross hazard corridor → reach hub → try a room, back out, try another,
  solve one → onward door opens → quit → relaunch resumes. Plays well *silently*, and **your 8-year-old
  can complete the loop unaided.** This is the slice we show people.

## M5 — Mobile & touch validation *(in progress)*
**Goal:** prove cross-platform early, before content piles up.
- ✅ `touch_controls.dart` (left move pad, right jump/interact, top-right claw) feeding the same
  `GameInput`. Uniform 62 px buttons glued to real screen corners. Tap-jump latches `jumpHeld`
  ~0.33 s so a tap = full jump (the keyboard's variable-height hop is too brief for touch; kinder
  per GDD §2). On touch the desktop HUD meta-row is hidden (it owns the lone claw — no glyph dupe).
- ✅ **Fill-screen camera:** the fixed 24×14 room now **cover-fits** the device (no pillarbox bars),
  centred, cropping only decorative top/bottom margins — a small phone screen can't afford letterbox
  waste. HUD/overlays re-anchor to the real screen via `onGameResize` (replaces M1's letterbox).
- ✅ Android build env: scaffold `android/` (`flutter create --platforms=android .`) + disable Kotlin
  incremental compilation (`kotlin.incremental=false`) — the pub cache (C:) and project (D:) on
  different drive roots break Kotlin's relocatable cache. *(Capture in a run-skill.)*
- ✅ Built & playtested on a real **moto g57** (Android 16) — plays well; jump/move/interact verified.
- [ ] Runtime pointer-type detection (web touch vs mouse/keyboard) — still platform-gated for now.
- [ ] **Hide touch controls when a gamepad is connected** (GDD §10 future controller) — same
  input-source-detection hook as the web-touch detection above.
- [ ] 60 fps check + kid ergonomics pass.
- **Exit criteria:** the vertical slice is comfortably playable on a phone.

## M5.5 — Field Kit design pass ✅ *(closed — docs only; the design-gate for GDD §9b)*
**Goal:** turn the Field Kit/artifact concept from DRAFT into a buildable spec. **No code.**
**Decision:** the Field Kit **is** the Metroidvania **powerup set** ([POWERUPS.md](POWERUPS.md)) —
permanent, found-by-exploration abilities that gate bonus routes. The original charge/socket/
discipline-row tool model is **retired**; cross-discipline **artifacts** are **deferred** to a later
phase (POWERUPS Phase C+/Act IV); the **symbol-economy rule** is locked while per-room counts land
with the content.
- ✅ Kit finalized as powerups (flippers, spring boots, grapple, lantern) — charges dropped.
- ✅ Symbol-economy *rule* defined (intentionality preserved); per-room tallies deferred to M6+/M7.
- ✅ Artifact lattice deferred (hook preserved in GDD §9b), not built.
- ✅ Socket rule: only aim-prone powerups (grapple) are socket-constrained; traversal powerups are
  geometry-gated.
- ✅ GDD §9b de-DRAFTed; SYMBOLS §5b carries the real powerup glyphs; GDD §13 open question closed.
- **Exit criteria met:** GDD §9b is no longer DRAFT; M6 places powerup pickups/bonus doors with
  confidence (already done — POWERUPS Phases 1–3).

## M5.7 — Maze topology design pass ✅ *(closed — spec in [MAZE.md](MAZE.md))*
**Goal:** turn the GDD §4 passage/maze model from a proven mini-loop into a full castle spec.
- ✅ The complete M6 castle graph (3 streets, 2 plazas, 6 puzzle rooms + reward vault, exit hall,
  grand loop) — MAZE.md §4, cut-vertex audited.
- ✅ Corridor identity: geometric street-badge family (○ △ □ ◇ ☆ ⬡) on doors + corridor walls.
- ✅ The no-soft-lock validator — landed EARLY as code: `world_validator.dart` +
  `world_validator_test.dart` run over the real world.json in `flutter test`.
- ✅ Castle map screen spec (discovered-graph, builds in M7) — MAZE.md §5.
- **Exit criteria met:** M6 builds the real maze from MAZE.md.

## M6 — Content expansion
**Status: BUILT ✅** *(per [M6_PLAN.md](M6_PLAN.md) — 22 nodes, 6 new puzzle types, 3 secret
rooms, etchings, boulders, moving platforms, the capstone, the grand loop; 73 tests green.
Remaining: user playthrough + kid test.)*

**Goal:** turn the slice into a short game — build the castle maze per the M5.7 spec.
- Add more passage rooms (P4–P6) + their scripts, junctions mixing disciplines per the variety rule.
- A **falling boulder** corridor; introduce one `forge2d` room *only if* a puzzle needs real
  physics (otherwise scripted) — validate the hybrid path here.
- Place the first **lore etchings** (`etching` entities) — a few in corridors, a couple hidden in
  optional/reward passages; found ones persist per profile.
- Place the first **anchor sockets and star bonus doors** per the M5.5 spec (bonus path only —
  never required for progress), and implement the first one or two **tools** end-to-end.
- Build the full maze `world.json` (cycles, multi-door corridors, the final exit gate) and land
  the **no-soft-lock validator** in the test suite.
- **Exit criteria:** a complete short playable loop from teleport-in to escape.

## M7 — Polish, systems & the game shell
**Goal:** make it feel finished — a complete screen flow, not a tech demo (GDD §10b).
- **Full screen flow:** splash (logo beat, doubles as load screen) → title (**wordmark** — the
  name drawn as a signage panel — + play/settings/collection glyphs) → **profile avatar-select**
  (2–3 pictogram avatars; per-profile saves from M4's data model) → game. Pause overlay
  (resume/restart-claw/settings/exit-to-title). HUD final pass. Play-space screens strictly
  wordless; shell screens symbol-first (STYLE_GUIDE §8b boundary).
- **Settings screen:** sound/music toggles + volume bars (symbol-only), credits entry (heart glyph).
  **Touch-control size** adjustment (symbol-only slider; `TouchControls.btn` is already a single
  knob — wire it to a saved setting so a player can scale the buttons to their hands).
- **Inventory / Field Kit screen:** carried item, earned tools with charge pips, artifacts (GDD §9b).
- **Attributions/credits screen:** renders `assets/credits.json` with **clickable artist links**
  (`url_launcher`) — the most text-heavy shell screen (plain ink-on-bg typography). The registry
  itself starts the moment the first CC0 asset lands (asset + credit enter the repo together,
  ARCHITECTURE §5.10).
- **Hint halo**: HUD lightbulb pulses a halo glow on the active script's `hintTargetId`
  (STYLE_GUIDE §8d); v1 targets only, chain-walking later.
- `symbol_legend.dart` as the **collection screen — this is the achievements screen**: glyphs stamp
  in when earned (discipline glyphs on first solve, `INV` glyphs when taught), discipline rows
  complete, plus the **etchings gallery**. First-use teaching for each invented symbol. Completed
  rows present their **tool**; artifact combos assemble visually here (per M5.5 spec). Unlock
  moments also pop wordlessly in-game (stamp pops, flies to the book).
- Audio pass — **CC0/openly-licensed** music & SFX (landing thunk, lever click, boulder rumble, the
  claw's whir + whirlwind); every adopted file registered in `credits.json` as it lands.
- Claw-reset feel/timing polish (abbreviate on repeats), transition polish, telegraph review.
- Discipline palettes filled in beyond amber + indigo (chemistry teal, fluids blue, …) per PUZZLES.md.
- CI/lint guard: **no user-facing strings / number rendering** in gameplay paths.
- **Exit criteria:** no rough edges in the core loop; a stranger (or a child) can play unaided.

## M7.3 — Grand Castle Expansion *(the "many hours" content build)*
**Goal:** turn the short complete loop into a **large, deep game** — many hours of play. M6 proved
the castle pattern (22 nodes, ~10 rooms); this milestone **multiplies it massively** in both size
and complexity, keeping every law intact (no-death, no-text, kindness/no-soft-lock validator green,
direction-of-travel as data, per-room discipline palettes). Build on the M6/M5.7 machinery — this is
*content scale*, not new engine work, so it can largely be authored in JSON + per-room scripts.
Reuse the existing pipeline before adding tech; only reach for `forge2d` when a puzzle truly needs it.

**Shape — grow the castle into multiple ACTS (wings), gated by powerups (true Metroidvania depth):**
- **Many more streets, plazas & rooms.** Target a step-change in node count (M6 was 22; aim for a
  multiple of that across the new wings). Each plaza keeps the variety rule — sibling rooms span
  *different* disciplines.
- **Fill out the disciplines.** M6 leaned mechanics/optics. Expand into the full PUZZLES.md set:
  **chemistry ratios, fluids, gravity, electricity/magnetism, thermo, sound**, plus the **sports**
  grab-bag (tennis rally, basketball, mini-golf, billiards). Each new discipline brings its palette.
- **Difficulty ramp + fusion rooms.** Later wings escalate; capstone rooms **FUSE disciplines** (GDD)
  — e.g. optics+mechanics, fluids+thermo — as gate-guardians between acts.
- **Deepen the powerup gating (POWERUPS §7 Phase 5):** land the remaining kit — **grapple wing**,
  **lantern / dark rooms** — and put **Act IV (or the deepest wing) behind 2 powerups**, so routes
  genuinely open up as the kid earns abilities. More secret rooms behind cracked walls.
- **More traversal & hazard variety:** more moving-platform choreography, boulder runs, conveyor /
  timing rooms — non-lethal throughout.
- **Collectibles that pay off:** many more **lore etchings** + the symbol-economy rewards (per-room
  tallies, deferred since M5.5, finally land here) so exploration is always rewarded. The teleporter
  3-state irises and spine/map HUD already give wordless progress feedback across a big world.
- **Author at scale:** the path-checker + kindness/direction/corridor-liveness validators run over the
  whole expanded `world.json` in `flutter test` — never ship a wing without them. Watch memory
  footprint as node count grows (cold room loads stay budgeted; profile data scales per-profile).
- **Exit criteria:** a single playthrough is **many hours**; the castle feels vast and layered;
  multiple powerup-gated acts; every discipline represented; all validators green; an 8-year-old can
  keep discovering new wings over many sessions (save/resume across a big world holds up).

## M7.5 — Visual style overhaul *(the dedicated art stage, pre-release)*
**Goal:** MVP ships with functional programmer-drawn signage art; this stage makes it *beautiful*
in one deliberate pass, with the whole game playable as the test bed.
- **ART DIRECTION (locked):** **signage foreground + pixelart environment.** Anything interactive
  or gameplay-critical (the figure, doors, hazards, levers, glyphs, teleporter irises) stays crisp
  **signage** so it's always legible (Pillar 1). The **backdrop/atmosphere** (skies, trees, stone,
  scenery) becomes textured **pixelart**. Boundary rule: *if you can act on it, it's a sign; if it's
  scenery, it's pixels.* First realization landed in M7: the night-meadow SVG backdrop
  (`assets/art/meadow_bg.svg`, rendered via `flutter_svg` → a `Backdrop` component) with signage iris
  portals on top. M7.5 authors true pixelart sprites/tiles for the environments; the meadow SVG is
  the bridge/placeholder.
- **Style-guide audit** of every component: silhouettes, line weights, construction consistency,
  the §2 rules (incl. the color-redundancy rule 8) — fix every deviation.
- **Authored SVG art** (pipeline: ARCHITECTURE §5.2b, rules: STYLE_GUIDE §11) replacing
  programmer art where it pays: the **claw multi-part sprite** first (cable/hinge/jaws), the title
  **wordmark**, intricate glyphs. Hand-drawn or CC0-sourced (→ credits.json).
- **Palette tuning pass on real screens**: all discipline palettes side by side; fix the flagged
  contrast debts (`accentNeutral` and `accentHint` vs the bright bg).
- **Motion polish:** player posture curves, squash/lean feel, claw beat timing, room-transition
  choreography, telegraph animations.
  - **Water climb-out (mantle) pose:** the climb-out works mechanically (`player.dart` `_advanceClimb`
    / the `_climbing` render branch) but the figure currently "supermans" up — arms out, body flat.
    Redo the pose as a believable clamber: grab the lip, plant a knee, push up — weighty, not flying.
- Readability playtest (kid + a fresh adult) and a colorblind-simulation check.
- **Exit criteria:** the game looks intentionally designed, not functional; every visible element
  passes the style-guide audit; the claw is a character, not a placeholder.

## M8 — Release prep
**Goal:** ship to the chosen storefronts.
- **Web:** `flutter build web` (CanvasKit), host it. *(Earliest public release.)* First-load
  experience: a filling-ring loader (`q_charge`) while CanvasKit/assets warm — the only place a
  load indicator should be needed (cold room loads are budgeted < 100 ms).
- **Windows:** packaged build.
- **Android / Play Store:** signing, store listing, icons, device matrix testing.
- **iOS / App Store (latest):** needs macOS + Apple dev account; do last.
- **Exit criteria:** published on web + Windows; mobile store submissions staged.

## Sequencing notes
- M0–M4 are the spine; protect them from scope creep. Anything not on the GDD §6 backlog waits.
- Revisit the GDD "Open questions" (§13) at the end of M4, with a real game in hand.
- M5.5 is **docs-only** and can overlap M5; but **no Field Kit code or content before it closes** —
  the system touches save data, level schema, and symbol design, so building it half-specified is
  the expensive mistake.
- Keep `forge2d` usage minimal until M6 proves the hybrid bridge.
