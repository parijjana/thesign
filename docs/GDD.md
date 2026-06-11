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

## 4. Core loop & world structure
```
Corridor (cross hazards)  →  CUL-DE-SAC HUB (several room doors)
                                   │  pick a room
                                   ▼
                              Enter room → read it → solve?
                                   │                  │
                          yes ─────┘                  └───── stuck / don't like it
                           │                                        │
              way onward unlocks                      leave via the door you came in
                           │                                        │
                           ▼                                        ▼
                  next corridor  ◄───────────  back in the hub, try a DIFFERENT room
```
- A **cul-de-sac hub** sits at the end of each corridor and offers **N rooms** to choose from.
- **Unlock rule (default): solving any ONE room in a hub opens the onward corridor.** So a player
  who can't crack a given puzzle simply backs out and tries another — never hard-blocked (Pillar 3).
  Designers may override per hub (e.g. require a specific room, or solve 2 of 3) but the default is
  the kind one.
- **Variety rule: a hub's rooms span *different disciplines*** (e.g. one optics, one mechanics, one
  sports) — never easy/medium/hard versions of the same idea. Backing out of a room should always
  mean "try a different *kind of thinking*," not "try the same thing but easier." Each hub door
  carries its room's discipline glyph (SYMBOLS §5) and the room renders in its discipline palette,
  so the choice is legible before entering.
- Rooms are puzzle chambers off the hub: you **enter and exit through the same hub door**. Solving a
  room flags it solved and contributes to the hub's unlock; you then return to the hub to proceed.
- Some hub rooms can be **optional/reward** rooms (a collectible, a shortcut) rather than required.

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
- **Spike pits** — touch = reset to corridor start; the floor sign reads "careful."
- **Falling boulders** — drop on a track or roll; trigger by proximity/plate. Being caught = reset.
  (Forge2D-eligible.)
- **Moving platforms** — scripted paths over a pit; miss the platform = reset to corridor start.
- **Crushers / swinging blades** — scripted, rhythmic, telegraphed; contact = reset.
Every hazard must be **telegraphed** (a warning sign motif, a wind-up, or a visible track) so a reset
always feels fair — supports Pillars 2 & 3.

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

## 9b. The Field Kit & artifacts *(DRAFT — design-gate before build)*
> ⚠️ **Status: concept locked in spirit; details deliberately open.** Before any of this is built it
> gets a dedicated design pass (final tool list, per-discipline symbol economy, the artifact combo
> lattice, socket placement rules) — see ROADMAP §M5.5. Nothing in M0–M5 depends on it; M6+ places
> sockets/bonus doors only after that pass.

The symbol collection (§9) is not just a sticker book — it pays out.

**Every symbol is intentional.** A glyph only enters the collectible legend if collecting it
contributes to at least one reward — its discipline's tool, an artifact combo, or both. No filler
stamps.

**Tools — discipline rows award gear (the "Field Kit").** Completing a discipline's legend row
awards that discipline's **tool**: the lesson made portable. Illustrative set (final list in the
design pass):
- Mechanics → **portable pulley** — clip into a marked **anchor socket** on a wall/ceiling and
  hoist yourself or a heavy block up the rope (deliberate and slow — a thinking grapple, not a swing).
- Optics → **pocket mirror** — place on a marked stand to extend a beam where room mirrors can't reach.
- Magnetism → **magnet glove** — pull a metal block toward you across a gap.
- Chemistry → **grease vial** — coat a marked surface so a block slides with one push.
- Thermo → **ember / ice cube** — melt one small ice lock, or freeze one puddle.
- Sports → **bouncy ball** — throw it to press a plate you can't reach.

**Tool rules** (pillar-compatible constraints — these are *not* open questions):
1. **Permanent.** Never lost, never timed — no take-backs for a kid.
2. **World-acting, never player-buffing.** A tool visibly changes the world; no invisible stat
   modifiers (Pillar 1: clarity).
3. **Socket-constrained.** Tools apply only at marked **anchor sockets / stands** (a signage glyph,
   SYMBOLS §5b) — designers control exactly where they work; no sequence breaks, no aim skill
   (Pillar 2).
4. **Bonus path only.** The main path never requires a tool (never hard-blocked, Pillar 3). Tools
   open star-marked bonus doors, shortcuts, second solutions, and etching alcoves.
5. **Charges, not timers.** A limited tool carries per-room charges shown as pips; the claw's
   whirlwind refills them on reset.

**Artifacts — cross-discipline combos open cross paths.** Beyond per-row tools, **artifacts**
unlock from *combinations of symbols across disciplines* — illustrative: optics + mechanics stamps
assemble a **periscope**; thermo + fluids forge a **steam key** that opens one sealed
cross-discipline bonus room. The reward structure is a **lattice, not a line**: spreading across
disciplines is itself rewarded, so progression grows cross paths instead of grinding one row — and
it primes the late-game fusion rooms (PUZZLES §Difficulty) by getting the player to *think across
disciplines on their own initiative*.

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
small bobbing bubble with the **hand glyph** (SYMBOLS `interact`) above it. The same glyph labels
the touch interact button (and a controller's face button later), so "hand = act" is learned once
by association and the hint works identically on every input device. Locked things don't prompt —
their state glyph (padlock) already communicates.

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
- **In:** one corridor (spike pit, non-lethal reset) → one **cul-de-sac hub with 2–3 rooms
  spanning at least two disciplines** (mechanics picks from P1–P3 + the optics mirror room, per the
  §4 variety rule; solve any one to open the onward door) → a second corridor. Full aesthetic,
  forgiving movement, no-death reset model, hub room-selection + back-out, feedback popups,
  save/resume, keyboard + touch.
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
- **Field Kit design pass (§9b — must close before M6 builds on it):**
  - Final tool list and what each does; which (if any) carry charges.
  - **Symbol economy:** how many collectible symbols per discipline row, and where each is earned
    (first solve? per room? hidden?) — every one must feed a reward (the intentionality rule).
  - **The artifact lattice:** which cross-discipline combos exist, what each unlocks (bonus room,
    shortcut, cosmetic, lore), and how the player *discovers* a combo wordlessly.
  - Socket placement rules (density, telegraphing, how a socket shows *which* tool it accepts).
  - Does equipped gear show on the pictogram figure (tool belt) or stay HUD-only?
