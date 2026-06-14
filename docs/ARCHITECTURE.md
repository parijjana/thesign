# Technical Architecture

> Source of truth for engineering. Game design lives in [GDD.md](GDD.md);
> visual rules in [STYLE_GUIDE.md](STYLE_GUIDE.md); level data spec in [LEVEL_FORMAT.md](LEVEL_FORMAT.md).

## 1. Stack decision
| Concern | Choice | Why |
|---|---|---|
| Language / app framework | **Flutter (Dart)** | Already known; one codebase for all 5 targets. |
| Game engine | **Flame** | De-facto 2D engine on Flutter: game loop, component tree, camera, collision; inherits Flutter's platform reach. |
| Targets now | **Web + Windows desktop** | Flutter web + Windows desktop builds. |
| Targets later | **Android, then iOS** | Same codebase; add stores when ready. |
| Physics | **Custom kinematic AABB** for player + scripted hazards; **`flame_forge2d`** reserved per-room | "Hybrid" decision — deterministic by default, real physics only where a puzzle needs it. |
| Rendering | **Procedural vector** via Canvas in component `render()` | Matches signage aesthetic; no art pipeline; tiny binary; theming is trivial. |
| Levels | **JSON data + per-room Dart logic hooks** | Authoring decision — data describes geometry, Dart handles bespoke puzzle logic. |
| Persistence | **`shared_preferences`** (or JSON file) | Offline, tiny, cross-platform save. |

### Rejected alternatives (recorded so we don't relitigate)
- **Pygame** — no viable web/mobile path. Disqualified by platform requirements.
- **Raw Flutter, no Flame** — would force us to hand-roll loop/collision/entities. Not worth it here.
- **Unity / Godot** — explicitly out; overkill for a vector puzzle game and adds an engine to learn.

## 2. Design decisions locked
- **Movement:** *Minimal & simple* — forgiving run + jump, coyote-time + jump-buffer, no momentum mastery.
- **Hazards:** *Hybrid* — scripted/deterministic by default; Forge2D only for rooms flagged `physics: forge2d`.
- **Authoring:** *JSON data + logic hooks* — see [LEVEL_FORMAT.md](LEVEL_FORMAT.md).
- **No death (kid-friendly):** there is no death/lives/game-over. Failure = **reset to the start of the
  current node** (corridor or room). Hazard contact resets to corridor start; failing/leaving a puzzle
  resets to (or exits) the room. The player can always restart a room or walk back out the entry door.
- **World graph is a maze of passages (GDD §4):** puzzle rooms have an entry side (always open)
  and an exit side that **opens on solve**; corridors (auto low-ceiling tunnels) and junction
  plazas connect arbitrarily with cycles. Kindness law: no puzzle room may be a cut vertex —
  enforced by a graph validator test (lands with M6).

## 3. Coordinate system & units
- **Logical unit = 1 tile = 32 px** (the "design pixel"; rendering scales to device).
- Level coordinates are expressed in **tiles** (can be fractional) in JSON; converted to pixels on load.
- World origin top-left, +x right, +y down (Flame convention).
- The camera fits a target **logical viewport** (e.g. 24×14 tiles) and letterboxes as needed so the
  game looks identical on a phone and a desktop window.

## 4. Project layout
```
lib/
  main.dart                     # Flutter entry; mounts GameWidget
  app/
    app.dart                    # MaterialApp shell, routes (splash → title → profile → game)
    theme.dart                  # Flutter-side UI theme (menus), references Palette tokens
    screens/
      splash.dart               # logo beat; doubles as load screen (web first-load may show a ring)
      title.dart                # play / settings / collection glyphs
      profile_select.dart       # 2–3 pictogram-avatar save slots
      settings.dart             # sound/music toggles + bars; entry to credits (heart glyph)
      credits.dart              # attributions — THE one text-allowed screen (STYLE_GUIDE §8b)
  game/
    escape_game.dart            # FlameGame subclass: world, camera, lifecycle, room loading
    palette.dart                # COLOR TOKENS (single source — see STYLE_GUIDE)
    config.dart                 # tile size, viewport, physics constants, tuning knobs
    input/
      game_input.dart           # platform-agnostic intent stream (move/jump/interact)
      keyboard_input.dart       # desktop/web binding
      touch_controls.dart       # on-screen d-pad + buttons (mobile/web-touch)
    core/
      game_loop_systems.dart    # fixed-step update helpers if needed
      aabb.dart                 # AABB collision + kinematic resolver (player & scripted bodies)
      collision_world.dart      # broadphase over static geometry + triggers
      reset_controller.dart     # no-death reset: teleport to node start + re-init bodies
    components/
      player.dart               # PlayerComponent (kinematic controller, carry logic)
      wall.dart, floor.dart     # static geometry (rendered as ink shapes)
      door.dart                 # exit/locked door
      lever.dart, plate.dart    # interactables
      pushable_block.dart
      moving_platform.dart
      spike_pit.dart
      boulder.dart              # scripted variant
      boulder_forge2d.dart      # Forge2D variant (only loaded in forge2d rooms)
      claw_reset.dart           # excavator-claw reset animation (the no-death set-piece)
      # ...discipline objects grow here as built: mirror, prism, lens, light_source,
      #    light_sensor, fulcrum_lever, pulley, gear, magnet, pipe, valve, beaker, ball_machine...
    level/
      level_loader.dart         # JSON -> components; instantiates the room's logic hook
      level_model.dart          # parsed data classes (RoomData, EntityData, DoorData...)
      room_registry.dart        # id -> asset path; world graph (room/corridor connections)
    puzzles/
      puzzle_script.dart        # abstract base: onLoad/onUpdate/onInteract/isSolved
      p1_pressure_plates.dart   # one file per room logic hook
      p2_lever_sequence.dart
      ...
    save/
      save_service.dart         # read/write progress (shared_preferences)
      progress.dart             # data model: currentNode, solvedRooms, items
    ui/
      hud.dart                  # minimal in-game overlay (symbol glyphs only — no text)
      pause_overlay.dart
      symbols.dart              # the icon library: draws every HUD/menu/puzzle glyph in ink style
      symbol_legend.dart        # in-game visual legend screen for invented symbols
assets/
  levels/                       # *.json room & corridor files
  levels/world.json             # the world graph (hub-and-spoke nodes + connections)
  svg/                          # authored vector art (claw parts, wordmark — see §5.2b)
  audio/                        # CC0 music & SFX (post-MVP; every file registered in credits.json)
  credits.json                  # attribution registry — rendered by app/screens/credits.dart
docs/                           # these documents
test/
  ...                           # unit tests for loader, aabb, puzzle scripts
```

## 5. Core systems

### 5.1 Game loop
Flame drives `update(dt)` / `render(canvas)`. Player movement and scripted hazards run on a
**fixed timestep accumulator** (e.g. 1/120 s) for deterministic collision; rendering interpolates.
Forge2D rooms let the physics engine own its step.

### 5.2 Rendering (procedural vector)
- Every visible component overrides `render(Canvas c)` and draws `Path`s with two `Paint`s:
  a **fill** (flat color token) and a **stroke** (black ink, fixed logical line weight).
- No raster images, no shaders for MVP. See [STYLE_GUIDE.md](STYLE_GUIDE.md) for line weights &
  construction.
- All colors come from `palette.dart` tokens — never hard-coded hex in components. This is what makes
  "swap background color later / multiple palettes" a one-line change.

### 5.2b Authored vector assets (the SVG pipeline)
Procedural drawing stays the default, but **complex/characterful art may be authored as SVG** in a
vector editor (Inkscape etc.) instead of hand-coding paths — first candidates: the **claw
set-piece**, the title **wordmark**, possibly intricate glyphs. Rules (authoring side in
[STYLE_GUIDE.md §11](STYLE_GUIDE.md)):
- Files live in `assets/svg/`; rendered via `flame_svg` (dependency added when the first asset lands).
- **Palette mapping:** SVGs are authored using the exact amber-palette hex values as placeholder
  colors; the loader remaps hex → token at load, so authored art re-themes with the active palette
  exactly like procedural art. An SVG containing a hex not in the palette fails loudly in dev.
- **Animated set-pieces are authored as one SVG per moving part** (e.g. `claw_cable.svg`,
  `claw_hinge.svg`, `claw_jaw_l.svg`, `claw_jaw_r.svg`), composed and transformed by the component —
  the art is the *look*, code remains the *motion*.
- `ui/symbols.dart` remains the **single access point** for glyphs: whether a symbol is drawn
  procedurally or loads an SVG is an implementation detail behind the same API.
- Third-party SVGs go through the attribution pipeline (§5.10) like any other asset; self-made art
  doesn't need it but may be credited anyway.

### 5.3 Physics & collision
- **Player:** custom kinematic AABB. Per fixed step: apply input → integrate velocity → resolve X
  then Y against static geometry → set grounded flag → apply coyote/buffer timers.
- **Scripted hazards & moving platforms:** kinematic bodies on authored paths/triggers; player
  resolves against them as moving AABBs.
- **Ramps (walkable slopes):** the collision world holds `ramps` alongside the AABB `solids`. After
  the X-then-Y AABB pass, `move()` settles the body onto any ramp surface beneath it — lifting it up
  a rise (so you *walk* up, no auto-step lip) and snapping it down a descent, but only while not
  moving upward so jumps launch cleanly. One-way support (pass through from below); works in swim
  mode too, which is how a swimmer climbs out of water. See `collision_world.dart` (`Ramp`).
- **Forge2D rooms:** room JSON sets `"physics": "forge2d"`; loader spins up a Forge2D world for that
  room only; eligible objects (e.g. rolling boulders) become Forge2D bodies. The player can remain a
  kinematic body bridged into that world. Keep these rooms few and well-tested.
- **Triggers** (plates, door zones, hazard zones) are non-solid AABBs that fire enter/exit events to
  the active puzzle script.
- **Weight system** (`components/weight.dart`): one shared `weightOn(surface)` that sums the weight
  resting on a surface **including whole stacks** (it recurses up each support chain — a block on a
  block on a plate weighs 2). Every weight sensor uses it — pressure plates, seesaw pans, the
  counterweight lift — so stacking and side-by-side loading behave identically everywhere (no
  per-room hacks). Blocks weigh 1; the player weighs 1 (excluded where a rider shouldn't load the
  sensor, e.g. a seesaw you ride up).

### 5.4 Input abstraction
`GameInput` exposes a normalized intent each frame: `{moveAxis: -1..1, jumpPressed, jumpHeld,
interactPressed}`. `keyboard_input.dart` and `touch_controls.dart` both feed it. Game logic never
reads raw key/touch events — keeps the five platforms uniform and makes rebinding trivial.

### 5.5 Level loading & world graph
- `world.json` lists nodes — `corridor`, `hub` (cul-de-sac), and `room` — with their connections and
  entry points. The graph is **hub-and-spoke**: a corridor links two hubs; a hub fans out to several
  rooms plus one onward corridor whose door is gated by the hub's `unlock` rule (default: any 1 room
  solved). See [LEVEL_FORMAT.md](LEVEL_FORMAT.md) §2.
- `level_loader.dart` reads a node's JSON → builds components → attaches the named `PuzzleScript`
  (rooms only).
- **Transitions:** door/exit trigger → save progress → load target node → place player at the entry
  matching the door used. A **room** door always leads back to its parent **hub**; entering a room
  records the parent hub so "back out" returns there.

### 5.6 No-death reset model (the excavator claw)
- Each node has a `start` point. A `ResetController` runs the reset on:
  (a) hazard contact in a corridor, (b) explicit room restart (R / claw button),
  (c) optional puzzle-driven reset.
- The reset is presented as the **excavator-claw animation** (`claw_reset.dart`), a UI/animation
  layer over the controller. Beats: descend → scoop player (limp "carried" pose) → carry to `start`
  → place → **whirlwind** → retract. Visual spec in [STYLE_GUIDE.md §8c](STYLE_GUIDE.md).
- **Input is locked** for the duration (~1–1.5 s; abbreviated/sped up on rapid repeats).
- The **actual state mutation happens on the whirlwind beat** so visuals and logic align: re-init
  moving hazards/platforms to their authored start and call active `PuzzleScript.onReset()`.
  **Solved sub-state is preserved unless the script opts to clear it.**
- No respawn/lives bookkeeping — logically it's "teleport player to node `start` + re-init kinematic
  bodies," dressed up by the claw. The claw is purely presentational and can be force-skipped (e.g.
  in headless tests) without changing the resulting state.
- Hub `room solved` flags persist for the session and are saved.

### 5.7 Puzzle scripts (the "logic hooks")
Abstract `PuzzleScript` with lifecycle: `onLoad(room)`, `onUpdate(dt)`, `onInteract(target)`,
`onTrigger(zone, body)`, `isSolved`. Each room references one script by id in its JSON. This is where
bespoke logic lives so the JSON stays declarative. See [LEVEL_FORMAT.md](LEVEL_FORMAT.md) §Puzzle scripts.

Two further script responsibilities (specs: STYLE_GUIDE §8d, SYMBOLS §6b):
- **Semantic feedback events:** scripts emit `error(entityId)` / `idea(entityId)` /
  `success(entityId)` through a small event bus. The feedback-popup layer renders them as glyphs
  over the entity (red `!`, yellow lightbulb, green success pop). The **same event stream** is the
  attachment point for the post-MVP audio pass — no rewiring later.
- **Hint target:** scripts expose `String? get hintTargetId` — the entity the hint halo pulses on
  when the player presses the HUD lightbulb. v1 returns the current goal/next actionable object;
  the API leaves room to return a chain later.

### 5.8 Save / progression
`SaveService` persists **per-profile** `Progress{ currentNode, parentHub, solvedRooms:Set<String>,
unlockedHubs:Set<String>, items:Map, earnedGlyphs:Set<String>, foundEtchings:Set<String> }` via
`shared_preferences`. Autosave on node transition and on puzzle solve. Offline, no account.
- **Profiles:** 2–3 slots, each identified by a **pictogram avatar** (no names — no text). A simple
  avatar-select screen at launch; siblings/parents on a shared device never overwrite each other.
- `earnedGlyphs` backs the **legend-as-collection** (a discipline glyph stamps on first solve in
  that discipline; `INV` glyphs stamp when first taught). `foundEtchings` backs the etchings
  gallery. Both render on the `symbol_legend.dart` screen (GDD §9, SYMBOLS intro).
- **Field Kit tools & artifacts (GDD §9b, design-gated at M5.5) add no save state:** both are
  *derived* — a tool from its discipline row being complete, an artifact from its combo being
  present in `earnedGlyphs`. Keeps the save model stable while the §9b design evolves.

### 5.9 Symbols & a text-free play space
**Hard constraint: no text/numerals anywhere in the play space, in any language** (style decision;
also makes play inherently localization-free). The **application shell** (`app/screens/` — splash,
title, profile select, settings, credits) is text-permitted but symbol-first; the boundary is
defined in STYLE_GUIDE §8b. Implications for engineering:
- All HUD/menu/puzzle indicators are drawn glyphs from `ui/symbols.dart` — never `TextComponent`/
  `Text` widgets with words. **`lib/game/**` must contain no user-facing strings**; a lint/CI check
  guards this (grep for `Text(`/`TextSpan` in `lib/game/` render paths). `lib/app/` is outside the
  guard. The title **wordmark** is a drawn asset, not rendered text, so even the shell stays
  font-free except settings small print and the credits screen.
- **Quantities are visual** (fill levels, balance tilt, dials, pip counts) — see
  [STYLE_GUIDE.md §8b](STYLE_GUIDE.md). No number rendering in gameplay.
- Prefer recognized standards (ISO 7010, biohazard/radiation trefoils, IEC symbols) redrawn in our
  line style; invented symbols are centralized in `symbols.dart` and surfaced via `symbol_legend.dart`.
- **Discipline-coordinated palettes:** the `Palette` token system (§5.2) already supports this;
  each **room** sets its palette id (per its discipline — map in PUZZLES.md) while hubs/corridors
  keep the castle palette, so a hub can mix disciplines (GDD §4 variety rule) and entering a room
  signals the kind of puzzle.
- **Hints & feedback popups** are glyph systems too (STYLE_GUIDE §8d, SYMBOLS §6b): the popup layer
  listens to script events (§5.7); the hint halo pulses the active script's `hintTargetId`.

### 5.10 Attributions pipeline (CC0 / openly licensed assets)
Music — and possibly some artwork — will be CC0 or similarly licensed. Rule: **an asset enters the
repo together with its attribution record**, never separately (a missing credit is a bug).
- `assets/credits.json` is the registry: one entry per asset —
  `{ "asset": "...", "title": "...", "artist": "...", "source": "https://…", "license": "CC0-1.0" }`.
- `app/screens/credits.dart` renders the registry grouped by artist, with **tappable links**
  (via `url_launcher`) to each artist's page. CC0 doesn't legally require credit — we credit anyway.
- Credits is a shell screen, so it sits outside the play-space lint guard (§5.9) like the rest of
  `lib/app/` — it's simply the most text-heavy of the shell screens.

## 6. Determinism & testing
- AABB resolver, level loader, and each puzzle script's `isSolved` are **pure-ish and unit-tested**
  (no rendering needed). Aim: a headless test can load a room, feed scripted inputs/triggers, and
  assert the puzzle solves.
- Forge2D rooms are integration-tested manually (non-deterministic by nature) — keep them rare.

## 7. Build & run targets
| Target | Command (planned) | Notes |
|---|---|---|
| Web | `flutter run -d chrome` / `flutter build web` | CanvasKit renderer recommended for crisp vector + perf. |
| Windows | `flutter run -d windows` / `flutter build windows` | Desktop window sized to viewport aspect. |
| Android | `flutter build apk` / Play Store later | Enable touch controls; test mid-range device. |
| iOS | `flutter build ios` later | Requires macOS + Apple dev account. |

## 8. Dependencies (initial)
- `flame` — engine.
- `flame_forge2d` — physics for forge2d rooms only.
- `shared_preferences` — save.
- `url_launcher` — clickable artist links on the credits screen (M7).
- `flame_svg` — authored vector assets (§5.2b); added when the first SVG asset lands.
- (later, audio pass) an audio plugin, e.g. `flame_audio` — pick at M7.
- (dev) `flutter_test`, `flame_test`.
Keep the dependency surface small; prefer engine primitives over plugins.

## 9. Performance & quality budgets
- 60 fps on a mid-range phone for a single room (vector draw is cheap; watch overdraw and path
  rebuilds — cache static room geometry into a single layer/picture).
- Cold room load < 100 ms. Respawn < 1 frame of perceptible delay.
- Binary stays small (no texture atlases) — a selling point for web load time.

## 10. Risks & mitigations
| Risk | Mitigation |
|---|---|
| Flame learning curve | Start with a throwaway spike: render a tile, move an AABB, before real code. |
| Forge2D ↔ kinematic player bridging is fiddly | Keep forge2d rooms minimal; design most "physics" puzzles as scripted. |
| Web touch + keyboard coexistence | Input abstraction handles both; detect pointer type at runtime. |
| Scope creep in puzzle types | The GDD table is the backlog; nothing ships that isn't on it. |
