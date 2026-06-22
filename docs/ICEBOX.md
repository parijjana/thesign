# Icebox — parked ideas

> Ideas worth keeping that are **not** on the roadmap. One entry each, enough detail to pick up
> cold. Nothing here is a commitment; promoting an entry means giving it a design pass and a
> milestone. (Keeping them here protects M0–M4 from scope creep — ROADMAP §Sequencing.)

## Level editor (player UGC + our own authoring tool)
- An in-game **level-editor UI**: players build their own levels from the shipped object/entity
  catalogue (LEVEL_FORMAT §4).
- **Dual-purpose:** the same editor is *our* dev tool for authoring/editing the levels we ship —
  one tool, two audiences.
- Players may use **unlocked levels as templates** or start from scratch.
- **Playthrough gate:** the editor must include a play-test mode proving the level is *achievable
  with the given tools* before it can be saved/shared (author-must-beat-it). All design rules
  still apply inside the editor: no-death, telegraphed hazards, the no-text rule.
- Why it's feasible later: levels are already declarative JSON — the editor is a UI over the
  existing schema. Biggest open questions: puzzle logic for custom levels (custom rooms can't
  have bespoke Dart scripts → needs a library of parameterizable stock behaviors), sharing
  mechanism, and kid-safe UGC moderation if sharing is ever online.

## Player floats & treads water (swimming pose)
- When the player lands in a water pool they should **float at the surface with a paddling/
  treading-water pose** (head up, arms sculling) until the claw fishes them out — never sink.
  Sinking below the surface implies drowning/death, which this game must never even hint at
  (GDD §0). The waterlogged-block "neutral buoyancy" suspension already exists; the player
  version needs the swim posture in the posture-interpolation set (player.dart) plus a float-at-
  surface behavior while awaiting rescue. Pairs naturally with the M7.5 animation pass.

## Fulcrum seesaw mechanic *(retired from M6 — physics too finicky)*
- A two-pan **balance seesaw** (load weight on one pan → the other rises into a platform you reach).
  We built it two ways: first a hard "2-block threshold, player weight ignored" (a bandaid that
  didn't read as real gravity), then a true weight balance on the shared `weightOn` system (tips to
  the heavier side, counts the player + single blocks). The *physics concept* was right, but the
  **rider-on-a-tilting-pan handling** never settled — blocks and the player jittered/flapped off the
  pans, and getting the fulcrum to sit cleanly in the floor (pans must be at floor level for
  block-loading, which buries the pivot) fought the layout. After several playtest passes it stayed
  unreliable, so `room_fulcrum` was rebuilt on the **counterweight lift** (`counter_lift`, which
  already works) and the `Seesaw` component + `seesaw` entity type were removed (recover from git
  history: last present at the "real weight balance" commit).
- **To revive:** treat riders properly — move the platform through the collision sweep so it *pushes*
  riders (don't hand-roll a carry), or rotate the beam as a real angled surface (needs slope support,
  which the ramp work now provides). Pairs with the M7.5 motion pass. The `weightOn` balance logic is
  sound and worth reusing.

## Exit, escape & re-entry — a replayability milestone *(needs its own design pass)*
> Promote to a milestone once designed. Surfaced during the M6 playthrough at `exit_hall`.
- **Principle (non-negotiable, already true): you may leave whenever you reach the exit** — no
  exploration/collection gate on escaping (GDD §0 kindness; the validator keeps `exit_hall`
  reachable with an empty kit). Completion is a *reward to chase*, never a *requirement to leave*.
- **Current state:** the exit is a stub — `exit_hall`'s swirl is a decorative `spawn` sign; there's
  no win/escape trigger yet. So the real "you escaped" moment is unbuilt, and that's where this
  milestone lives.
- **The idea:** make escaping a satisfying beat that *opens* replay rather than ending the game —
  **re-entry rooms**: after escaping, the player can re-enter the castle from new access points to
  chase the things they skipped (unexplored wings, powerup secrets, etchings, second solutions).
  Turns "the end" into "lap two, but on your terms."
- **Why it needs design (open questions):** where re-entry points sit and how they telegraph; what
  persists vs. re-presents on re-entry; how it relates to the **NG+ twist** (exit-is-a-teleporter,
  fusion-form rooms) below and the **castle map / completion view**; whether re-entry is free-roam
  or curated "unfinished business" hops. Touches save data, the map screen (M7), and the exit
  trigger — so it's a real design gate, not a quick add.
- **Connects to:** the NG+ twist + castle map + second-solutions entries just below (this milestone
  likely subsumes or sequences them).

## Progress & objective display — spine ribbon + objective lenses *(prototype landed)*
> Surfaced during the M6 playthrough ("hard to tell if I'm progressing toward the exit; also want
> goals like explore-all-swimming-rooms"). Reuses existing grammar — no new HUD language.
- **A1 — street-spine ribbon (PROTOTYPE in code, `lib/game/ui/spine_hud.dart`):** the corridor
  street-badge family (○ △ □ ◇ ☆) in castle order, capped by the exit swirl, top-centre. Faint
  outline until you set foot on a street, then fills ink; current street rides a goal-green chip.
  Wordless "how lit is the spine" = sense of progress + scale. Reads end-to-end as of this
  playtest. **Open:** full-spine-upfront (shows scale, mild spoiler) vs. reveal-as-discovered
  (preserves mystery) — a 1–2 line toggle. Verdict pending.
- **B1 — objective pip-ribbon:** a row of discipline glyphs (droplet, gear, sun…), each trailing a
  `q_pips` row (●●●○○ = 3 of 5 rooms) for "explore all X" goals. Active objective enlarges.
- **B2/C — objectives as lenses (M7 map territory):** pick a goal glyph → the castle map recolours
  to that lens (solved = filled, unsolved = outline) + a "you are here" wayfinding directory. The
  exit objective uses the fire-exit running figure (ISO standard).
- **Boundary flag:** progress meters sit near the no-numerals / play-space-vs-shell line
  (STYLE_GUIDE §8b) and overlap M7's map/collection scope — settle the boundary in docs before
  promoting beyond the prototype. Avoid an explicit arrow/compass *to* the exit (kills the maze's
  "wait, I've been here" — GDD §4); ambient "lit spine" is the kinder cue.

## Avatars as the player sprite, each with a signature ability
> Surfaced while building the M7 profile/avatar-select screen — promote the avatar from a save-slot
> badge into the actual in-world figure *and* a playstyle choice.
- **The idea:** the chosen avatar IS the player sprite, and each carries a signature movement trait —
  e.g. **bunny = higher jump**, **cat = wall-climb/cling**, **bird = glide/short flight** (or hover,
  double-flap, etc.). Pick your creature, play the whole castle in its style. Adds replay (run it
  again as a different animal) and personality.
- **Hard constraint it must respect — kindness / no-soft-lock (GDD §0):** abilities may **never gate
  required progress.** Every route to every door must stay completable by *every* avatar, or the
  path-checker/kindness validators break and a kid picks the "wrong" animal and gets stuck. So traits
  have to be **conveniences or alternate routes**, not keys — the cat's wall-climb is a *shortcut* up
  a shaft that also has a normal way up; the bird's glide *eases* a gap that's still jumpable. The
  validators would need to prove reachability under the **weakest** traversal kit (likely: assume no
  avatar ability at all), exactly as `path_checker` already does for powerups.
- **Big open tension — avatars vs. the Metroidvania powerups (POWERUPS.md):** the found-powerup kit
  (flippers/spring-boots/grapple/lantern) already *is* the ability-gating system, and it's built to
  gate *bonus* routes fairly because everyone can eventually find every powerup. Per-avatar permanent
  traits collide with that: do avatar traits overlap powerups (bunny ≈ spring-boots)? Stack with
  them? Does picking the cat mean you never need the climb powerup? Resolve before promoting —
  otherwise two ability systems fight over the same routes.
- **Other open questions:** how each trait reads wordlessly; balancing so no avatar is strictly best;
  sprite/animation cost (each avatar needs the full posture set — pairs with the M7.5 art pass);
  whether traits are fixed or a light unlock. Touches player.dart movement, the validators, the
  powerup design, and save data, so it's a real design gate, not a quick add.
- **Connects to:** the profile-select screen (M7, already built), POWERUPS.md (overlap to resolve),
  and the NG+/remix replay ideas below (different-avatar runs are a replay axis).

## Wordless hint halo *(built a v1, scrapped on looks — revisit)*
> Was an M7 deliverable; built a working v1 during the shell pass, but the visual didn't land, so it
> was reverted (working tree back to the collection-board commit) and parked here. The *mechanism* was
> sound; the *look* needs a real design pass (pairs with the M7.5 art stage).
- **The idea (STYLE_GUIDE §8d):** an **opt-in** hint. The player toggles it (H key / a touch
  lightbulb / the HUD lightbulb glyph lit while active); a wordless glow appears around the thing to
  focus on — "look here," never "do this." v1 is a single target; chain-walking later.
- **What the v1 did (all reverted, recoverable from git history at the collection-board commit):**
  - Added `PuzzleScript.hintTargetId` (a getter scripts override, returning the entity id to glow
    around). Could reflect **live state** for a *progressive* hint — e.g. P1 pressure-plate returned
    `plateA` until the plate was pressed, then `goalSwitch` ("weigh this, now go pull that"). Wired in
    `P1PressurePlates` + `StubSwitchPuzzle` (goal lever) as the two demo types.
  - `EscapeGame.hintActive` + `hintTargetCenter()` (resolve id → `byId<PositionComponent>` → centre);
    a `HintHalo` world component (priority −5, under the player) drawing a pulsing breathing disc +
    ring in `accentHint`; toggle on H (keyboard) and a new touch lightbulb `_Btn.hint`; HUD gained a
    lightbulb glyph that lit (`accentHint` chip) while active.
- **Why parked:** the glow itself **looked bad** (the pulsing amber disc/ring read as cheap/unclear,
  not the crisp signage language). Needs an art-led treatment — maybe a drawn signage "look-here"
  mark (a framed arrow/target glyph that pops over the entity) rather than a soft glow, or an
  animated bracket. Decide the visual in the **M7.5 art pass**, then rebuild on the same mechanism.
- **Open questions for the revisit:** the visual treatment (glow vs. drawn mark vs. bracket); whether
  it nudges toward a *target* or a *direction* (avoid an explicit compass to the exit — GDD §4); how
  it advances for multi-step puzzles (the progressive-`hintTargetId` hook is there); and authoring
  cost — only P1 + stub-switch had targets, every bespoke M6 script would need one.
- **Connects to:** STYLE_GUIDE §8d, the M7.5 art stage, and the symbol/feedback language (the
  lightbulb is already `SymbolId.hint`, the `fb_idea` glyph).

## Other parked ideas (from the replayability review)
- **Castle map / completion view** — post-game map showing solved vs unexplored rooms.
- **Second solutions** — hidden bonus objective in select rooms (bullseye-with-star glyph).
- **Remix mode** — parameterized room variants (`seed` prop re-rolls mirror angles, ratios, weights).
- **NG+ twist** — the "exit" is another teleporter; second lap re-presents rooms in fusion form.
