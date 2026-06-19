# Game Design Document — *(working title)* The Sign

> Source of truth for game design. Engineering details live in [ARCHITECTURE.md](ARCHITECTURE.md);
> visual rules in [STYLE_GUIDE.md](STYLE_GUIDE.md); level data spec in [LEVEL_FORMAT.md](LEVEL_FORMAT.md).

## 1. One-line pitch
A minimalist puzzle-platformer rendered like public-safety signage: you are a featureless
pictogram person teleported into a castle/dungeon and you must escape, solving one puzzle per
room while crossing the hazards in the corridors between them. **No death, no punishment** —
a gentle thinking game, built so an 8-year-old can play and enjoy it.

## 0. Audience & tone
The intended player is a curious child (~8) as well as adults. This sets hard constraints:
- **No death, no game-over, no lives, no timers that punish.** Failure only ever means "try again."
- **Never hard-blocked.** If a puzzle is too tough, there's always another room to try (see §4).
- Friendly, calm, encouraging. Mistakes are cheap and reversible. The game waits for the player.

## 2. Pillars (the things every decision serves)
1. **Clarity over decoration.** The signage aesthetic is not just a look — it is the design
   language. If a thing is interactive, the silhouette should read instantly, like a real sign.
2. **Think, don't twitch.** Platforming is *minimal and forgiving*; the challenge is the puzzle,
   not execution. There is **no death** — a mistake just resets the current segment.
3. **Kind by design.** Built for an 8-year-old: no failure states, never hard-blocked, always a way
   forward. The game is patient; the player sets the pace.
4. **One room, one idea.** Each room introduces or combines a single, legible puzzle concept.
5. **Calm tension.** Corridors provide gentle hazard-based pressure between the cerebral rooms,
   giving the pacing a heartbeat: solve (calm) → traverse (a little tense) → choose → solve.

## 3. Story & framing
Minimal, environmental, no dialogue trees.
- **Setup:** A flash. The pictogram figure appears inside a stone castle/dungeon. No explanation.
- **Goal:** Find the exit. The only verb the story gives you is *escape*.
- **Structure of the search:** the castle is a chain of **corridors** ending in **cul-de-sac hubs**.
  Each hub offers several rooms (each a different puzzle). Solving a room opens the way deeper into
  the castle; the player keeps choosing rooms and crossing corridors until they reach the exit.
- **Telling:** Story is conveyed through space and signage motifs, not text. Optional sparse
  wall-etchings (still in the sign language) can hint at lore. No cutscenes for the MVP.
- **Ending:** Reaching the final exit door. (Stretch: a twist — the "exit" is another teleporter.)

## 4. Core loop & world structure — a castle maze of passages
The castle is a **maze graph**, all in side view: low-ceilinged **corridors** (tunnels) connect
**junction plazas** and **puzzle rooms**. The defining rule:

```
explore corridor → junction: pick a door → enter a puzzle room (entry side)
        ▲                                        │ read it → solve?
        │                              yes ──────┤
        │                               │        └── stuck / don't like it
        │                EXIT SIDE OPENS — a new                │
        │                corridor of the castle        walk back out the entry,
        └──────────────────── … ◄───────┘             take another route ────┐
                                                                             ▼
                                                              (the maze always offers one)
```

- **Every puzzle room is a PASSAGE, not a dead end: one entry side, one exit side.** The entry
  door is always open (retreat is always free — Pillar 3). The **exit door opens when the room is
  solved**: solving a puzzle literally unlocks a way through the castle. Solved rooms stay open
  from both sides forever — they become free passages.
- **Corridors and junctions connect arbitrarily.** Cycles are encouraged; the same corridor may be
  entered from different doors. "Wait — I've been here!" is a designed moment of mastery, and the
  maze is what gives the game depth and replay value (different runs solve different routes).
- **Corridor ≠ room, visually, always:** corridors are **tunnels** — a low brick ceiling is
  synthesized on every corridor automatically — while rooms keep their open, full-height halls.
  Each corridor additionally gets its own identity badge (a wordless "street name" from a
  geometric glyph family) plus recognizable motifs, so recognition never becomes confusion.
  **The full maze spec — castle graph, street badges, validator, map screen — lives in
  [MAZE.md](MAZE.md).**
- **Kindness law (replaces the hub unlock rule):** the maze must never soft-lock a player who
  can't crack one particular puzzle. **No single puzzle room may be a cut vertex of the reachable
  world** (a deliberate final gate may be the one exception). The world is data, so a
  graph-reachability **validator in the test suite enforces this** on every world change.
- **Hubs survive as junction plazas** — door-rich, puzzle-free breathing spaces. The old "solve
  any 1 of N" hub unlock is retired as the default; the `unlock` rule remains available as an
  optional special gate.
- **Variety rule (unchanged in spirit):** rooms reachable from one junction span *different
  disciplines* — never difficulty variants of the same idea. Door signs carry the discipline glyph
  (SYMBOLS §5); the room renders in its discipline palette.
- Some rooms can be **optional/reward** passages (a collectible, a shortcut) rather than on any
  main route.

## 5. Player character & verbs
The figure is a minimalist pictogram (see STYLE_GUIDE). Deliberately limited verb set:
- **Move** left/right (forgiving acceleration, no momentum mastery required).
- **Jump** (single jump; generous coyote-time and jump-buffer so timing is never the wall).
- **Interact** (one context button: pull lever, push block, pick up/place key or object).
- **Drop/Carry** (carry a single object at a time; carrying may limit jump height — a puzzle lever).

No combat. No double-jump/dash in MVP (could be a late unlock if a puzzle theme needs it).

## 6. Puzzles — science, sports & themed disciplines
Puzzles are organized by **real-world discipline** — optics, mechanics, chemistry, gravity, fluids,
electricity/magnetism, thermodynamics, plus **sports** (e.g. a tennis ball-machine rally you return
into a target) and grab-bag themes (music, astronomy, chain-reactions…). Each room teaches **one
idea**; later rooms **combine disciplines** into multi-step chains, and **each room is
palette-coded by its discipline** (optics = indigo, chemistry = teal, …). Hubs and corridors keep
the castle palette; entering a room shifts the color — a soft cue that the *kind of thinking*
changed. (Per the §4 variety rule, a hub's sibling rooms span different disciplines.)

> 📓 The full, growing concept backlog lives in **[PUZZLES.md](PUZZLES.md)** — disciplines, sports,
> more themes, the discipline→palette map, and the difficulty/fusion ramp. Each built room becomes a room
> JSON + a Dart logic hook (see [LEVEL_FORMAT.md §Puzzle scripts](LEVEL_FORMAT.md)).

**MVP seed set** (smallest tech, taught first):
| Concept | Discipline | Mechanic |
|---|---|---|
| Pressure plates | Mechanics | Weigh down a plate (block/player) to open a gate |
| Box stacking | Mechanics/Gravity | Build height to reach a ledge |
| Fulcrum lever | Mechanics | Reposition the fulcrum to lift a heavy gate |
| Mirror routing | Optics | Aim mirrors to bounce a beam onto a sensor *(first "wow" room)* |

> All puzzle goals/states/quantities are shown **as symbols and visuals, never text or numerals**
> (ratios = beaker levels, forces = balance tilt, etc.) — see [STYLE_GUIDE.md §8b](STYLE_GUIDE.md).

## 7. Hazards (corridors)
Corridors are short, side-scrolling, puzzle-light, hazard-heavy connective tissue.
**Hazards never kill.** Touching one simply **resets the player to the start of the corridor** (the
hub they entered from) — a "whoops, try again," not a death. This keeps the no-death promise while
still giving corridors a bit of tension and timing.
- **Water pools** — the signature kid-friendly hazard: fall in and the claw *fishes you out*,
  back to the node start. Drawn with no-swimming-sign motifs (wavy signage surface); telegraphed
  by the ISO **no-swimming** sign. Blocks that sink are fished home too (anti-soft-lock).
- **Falling boulders** — drop on a track or roll; trigger by proximity/plate. Being caught = reset.
  (Forge2D-eligible.)
- **Moving platforms** — scripted paths over a pit; miss the platform = reset to corridor start.
- **Crushers / swinging blades** — scripted, rhythmic, telegraphed; contact = reset.
Every hazard must be **telegraphed** (a warning sign motif, a wind-up, or a visible track) so a reset
always feels fair — supports Pillars 2 & 3.

**Rooms carry light jeopardies too** (a telegraphed water pool or similar): forgiving but not
trivial — the room's challenge stays the puzzle, but a careless step still earns a friendly claw
ride back to the room start (puzzle progress preserved). This keeps the claw present everywhere
and the player attentive.

## 8. Failure model (no death) — the excavator claw
There is **no death, no lives, no game-over**, and **no death animation**. "Failure" only ever means
*reset to a start point*, and the reset is performed by a friendly **excavator/grabber claw** that
drops from the ceiling, scoops the player up "kitten-by-the-scruff," carries them back to the start,
sets them down, then spins into a **whirlwind** that visibly resets the room. Cute, mechanical,
never violent — the no-death promise made literal. (Full beats in [STYLE_GUIDE.md §8c](STYLE_GUIDE.md).)

The claw triggers on:
- **Hazard contact (corridor):** claw carries the player back to the **start of the current corridor**
  (the hub side they entered from). Quick (~1–1.5 s; abbreviated on rapid repeats), no other penalty.
- **Failing / giving up on a puzzle (room):** claw returns the player to the **start of the room**.
  The player may instead simply **walk out the door they entered** to return to the hub at any time.
- **Voluntary restart:** the player can always trigger the claw to reset the current room (a gentle
  "try again" — its button uses the claw glyph).
- **State on reset:** the whirlwind re-initializes moving hazards/platforms to their start. **Puzzle
  progress is preserved by default** (a lever you pulled stays pulled) unless a puzzle script clears
  it (`onReset`). Hub-level "room solved" flags are permanent for the session.

## 8b. Hints & feedback (wordless)
Because there is no text, assistance and feedback are their own symbol systems
(visual spec in [STYLE_GUIDE.md §8d](STYLE_GUIDE.md), glyphs in [SYMBOLS.md §6b](SYMBOLS.md)):
- **Hint (opt-in, lightbulb):** pressing the HUD lightbulb makes the puzzle's **current target pulse
  with a halo glow** — the goal sensor, or the next thing worth acting on (the active script decides,
  via its `hintTargetId`). v1 is just the target halo; the system is designed to **extend later** to
  haloing other artifacts in the causal chain (e.g. the mirror that feeds the sensor).
- **Feedback popups:** small glyphs that pop briefly over the widget concerned —
  a **red exclamation** on the thing that refused or went wrong (wrong key, lever that won't move),
  a **yellow lightbulb** for "notice this" events, a **green success pop** when a step works.
  Instant, wordless cause-and-effect feedback — critical for a young player.

## 9. Progression, save & collection
- World = ordered list of rooms and corridors.
- **Profiles:** 2–3 save slots, each chosen by a **pictogram avatar** (no names — no text), so
  siblings/parents on a shared device never overwrite each other.
- Save records (per profile): current node, set of solved rooms, collected key items, **earned
  symbol-legend stamps**, and **found etchings**.
- **The Symbol Legend is the collection meta-game:** legend entries are *earned*, not pre-filled —
  a discipline glyph stamps in on the first solve in that discipline; an invented symbol stamps in
  when first taught; completing all of a discipline's rooms completes its row. The legend screen
  doubles as a wordless progress/sticker book.
- **Lore etchings are findables:** sparse wall etchings (§3) are collectible — touching one records
  it in an etchings gallery on the legend screen. Some hide in optional/reward rooms.
- **The collection pays out** — tools and artifacts; see §9b.
- Lightweight persistence (see ARCHITECTURE §Save). No accounts, fully offline.

## 9b. The Field Kit — Metroidvania powerups *(design pass closed; build status in [POWERUPS.md](POWERUPS.md))*
> **Decision (M5.5):** the Field Kit **is** the powerup set. The original sketch of charge-based,
> discipline-row-awarded tools used at sockets is **retired** in favour of a single, simpler model:
> permanent **powerups** found in hidden rooms that **gate routes** (Metroidvania). One reward
> system for a kid to learn — *find a thing → you can do a new thing forever.*

The symbol collection (§9) is not just a sticker book — it pays out, and the Field Kit is how.

### The kit = powerups (the whole reward system)
Each powerup is **found once, kept forever**, shown on the pictogram figure (no invisible stat
buffs — STYLE_GUIDE rule 9), and persists per profile. A powerup **changes what an existing verb
does** (swim, double-jump, cross, see) — it never adds a button (the fixed verb budget, §10). The
canonical set (flippers, spring boots, grapple, lantern) and engine design live in
**[POWERUPS.md](POWERUPS.md)**; this section is the *design law* they obey.

**Powerup rules** (pillar-compatible constraints — not open questions):
1. **Permanent.** Never lost, never timed, no charges — no take-backs for a kid. *(This retires the
   old "charges, not timers" rule: charges are gone.)*
2. **World-acting / world-traversing, never invisible.** A powerup visibly changes what the figure
   can do, shown on the figure (Pillar 1: clarity). No hidden stat modifiers.
3. **Found by exploration, not by completion.** A powerup is earned by *discovering its hidden room*
   — not by completing a discipline's legend row. *(This retires the old discipline-row→tool award.)*
4. **Bonus & shortcut only — never the sole path.** A powerup gates bonus wings, shortcuts, second
   solutions, and etching alcoves; the base capstone route to the exit always works without any
   powerup (Pillar 3, kindness law §4). **Enforced in `flutter test`** — the kindness validator
   keeps the exit reachable with an empty kit, and the path checker's per-level `assume` prop checks
   gated rooms under their required powerup (POWERUPS §6).
5. **Socket-constrained where it needs aim.** Powerups that could otherwise become a skill/aim toy
   (the grapple) apply only at marked **anchor sockets** (SYMBOLS §5b) — designers control exactly
   where they work; no sequence breaks (Pillar 2). Traversal powerups (flippers, spring boots) are
   gated by *geometry* (water depth, ledge height), needing no socket.

**Where the old "world-acting tools" went.** Ideas like grease-a-surface, freeze-a-puddle, or
throw-a-ball-at-a-plate aren't lost — they live as **per-room puzzle elements** (PUZZLES.md),
authored into the room that needs them, rather than as portable gear carried between rooms. Cleaner:
the puzzle owns its mechanics; the kit owns traversal.

### Every symbol is intentional (the economy rule)
A glyph only enters the collectible legend if collecting it **feeds at least one reward** — a
discipline row's completion payoff, a powerup, or a found-etching gallery slot. No filler stamps.
Concretely:
- **Discipline glyphs** stamp in on first solve in that discipline; completing all of a discipline's
  rooms **completes its row** (a collection/achievement payoff — the legend screen, M7). Under the
  Metroidvania model a completed row no longer *grants gear*; its payoff is the completion itself
  plus whatever cosmetic/lore the legend screen presents.
- **Powerup glyphs** stamp in when the powerup is found.
- **Etchings** record into the gallery when touched.

> **Deferred (not cut): per-room symbol counts.** Exactly how many collectibles each discipline
> carries and the precise earn-point of each is **left to land as rooms are built** — freezing
> numbers before the content is kid-tested is the expensive mistake. The *rule* above is the gate
> M5.5 closes; the *tally* fills in during M6+/M7.

### Artifacts — deferred to a later phase (documented, not built)
Cross-discipline **artifact combos** (e.g. optics + mechanics → periscope; thermo + fluids → steam
key) that open sealed cross-discipline bonus rooms remain an attractive late layer, but are **out of
MVP scope** and explicitly **not part of this design pass**. They hang off the same future shelf as
POWERUPS.md Phase C+/Act IV (the multi-powerup wing). The hook is preserved here so the idea isn't
lost; when revived, artifacts must obey the same five powerup rules above (permanent, visible,
bonus-only, validator-guarded).

## 10. Controls (abstracted across platforms)
| Action | Desktop/Web | Mobile |
|--------|-------------|--------|
| Move | A/D or ←/→ | on-screen d-pad (left side) |
| Jump | Space / W / ↑ | A button (right side) |
| Interact | E / Enter | B button (right side) |
| Restart room | R | claw glyph (corner) |
| Pause | Esc | pause glyph (corner) |
All input flows through one abstraction layer so game code is input-agnostic. **On-screen controls
and all play-space UI use symbols/pictograms only — no text or numerals**; the application shell is
text-permitted but symbol-first (boundary in [STYLE_GUIDE.md §8b](STYLE_GUIDE.md)).
The labels in this table are dev-facing only.

**Contextual verb prompt (wordless key hint):** any interactable the player is in range of shows a
small bobbing bubble with the **press glyph** (SYMBOLS `interact` — an arrow pressing a button)
above it. The same glyph labels the touch interact button (and a controller's face button later),
so "press = act" is learned once by association and the hint works identically on every input
device. Locked things don't prompt — their state glyph (padlock) already communicates.

**The verb/button budget is FIXED:** move + jump + interact, with restart and pause as meta
actions. That's one stick/d-pad + two face buttons + two meta — sized for keyboard, touch, and a
future controller. **A new mechanic must reuse the existing verbs; adding a button is a design
failure** (Pillar 2: think, don't twitch).

## 10b. Screens & flow (the game shell)
The product must flow like a finished game, not a tech demo. Built in M7 (ROADMAP); listed here so
nothing is forgotten. **The no-text rule applies to the play space, not the shell** (boundary in
[STYLE_GUIDE.md §8b](STYLE_GUIDE.md)): shell screens are text-permitted but **symbol-first** — a
non-reader must still be able to navigate them; play-space screens stay strictly wordless.

```
splash → title ──► profile select (pictogram avatars) ──► game (HUD)
           │              (resume jumps straight to the saved node)
           └─► settings ──► attributions/credits
in game:  pause overlay · inventory/Field Kit · collection (the achievements screen)
```

- **Splash:** the pictogram figure + claw motif, a brief beat; doubles as the load screen. The
  performance budget (cold room load < 100 ms) means no progress bar is normally needed; the **web
  first load** (CanvasKit + assets) may show a filling-ring `q_charge` loader.
- **Title:** the **wordmark** (the game's name drawn as a signage panel — an asset, not rendered
  text), play glyph, settings gear, collection-book glyph. Nothing else.
- **Profile select:** 2–3 pictogram avatars (§9).
- **Pause overlay:** resume, restart-claw, settings, exit-to-title glyphs.
- **Settings:** sound/music toggles + volume bars, palette/contrast options (later), credits entry
  (heart glyph).
- **Inventory / Field Kit screen:** the carried item, earned tools with charge pips, artifacts
  (§9b).
- **Collection screen = the achievements screen:** the symbol legend (§9) — stamps, completed rows,
  tools, artifact assembly, etchings gallery. Unlock moments also pop wordlessly in-game
  (a stamp glyph pops, then flies to the book).
- **Attributions / credits:** CC0 music & art credited properly — artist names, work, license, and
  **clickable links to each artist's page** (registry & pipeline in ARCHITECTURE §5.10). A shell
  screen reached via settings (heart glyph); the most text-heavy screen in the product, kept in
  plain ink-on-bg typography.

## 11. Scope guardrails (MVP)
- **In:** a **mini maze-loop** proving the §4 passage model: a water-pool corridor → junction plaza → three
  passage rooms spanning two disciplines (pressure plates + box stacking [mechanics], mirror
  routing [optics]) whose exit doors open on solve → a loop corridor reachable from multiple
  doors, closing one honest cycle. Full aesthetic, forgiving movement, no-death reset model,
  retreat-anytime, feedback popups, save/resume, keyboard + touch.
- **Out (later):** sound design, the full game shell (§10b — splash, title, settings, inventory,
  collection, attributions), level select, additional palettes, extra puzzle types, lore etchings,
  the **visual style overhaul** (functional MVP art is fine until ROADMAP M7.5), app-store polish.
- The first build target is a **vertical slice** (see [ROADMAP.md](ROADMAP.md)).

## 12. Audio (placeholder — post-MVP)
Minimalist, diegetic-ish: a soft thunk on landing, click on lever, low rumble for boulders.
Deferred until the vertical slice plays well silently. Music & SFX will be **CC0 / openly licensed**
— every asset adopted is recorded in the attribution registry the moment it enters the repo
(ARCHITECTURE §5.10) so the credits screen (§10b) is always complete.

## 13. Open questions (to revisit, not blocking)
- Is the player one continuous figure or does it "snap" to ledges (climb anim)? (MVP: continuous.)
- Carry limit: exactly one object? (Assumed yes.)
- Does the twist ending make the cut for v1? (Assumed stretch.)
- ~~**Field Kit design pass (§9b):**~~ **CLOSED (M5.5).** The Field Kit is the Metroidvania
  powerup set ([POWERUPS.md](POWERUPS.md)); charge/socket/discipline-row tools retired; the symbol
  economy *rule* is locked (per-room counts land with the content); artifacts deferred to a later
  phase. Equipped powerups **show on the pictogram figure** (not HUD-only). See §9b.
