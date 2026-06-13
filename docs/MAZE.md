# The Castle Maze — topology spec *(M5.7 design pass)*

> Source of truth for the maze: graph rules, the M6 castle layout, corridor identity, the
> kindness validator, and the map screen. Design intent lives in [GDD.md §4](GDD.md); data format
> in [LEVEL_FORMAT.md](LEVEL_FORMAT.md). M6 builds what this document describes.

## 0. Direction of travel — the data structure *(authoritative)*
Each **room** node in `world.json` declares **`entry`** — the exit name(s) that are its always-open
way(s) in. This is the single source of truth for "which way into a room"; **the engine derives
every door's lock from it** (`WorldData.isSolveGated`), so a room's two sides can never disagree
(the bug where you entered via the *closed* side and got stuck behind the puzzle).

```json
{ "id": "room_plates", "type": "room", "entry": "west",
  "exits": { "west": "hub_01", "east": "corridor_02" } }
```
- `entry` side(s): **always open** — you may enter (and later re-leave) freely.
- every other side: **opens on solve**, enforced identically from *both* endpoints (the room's own
  door AND the neighbour's door into that side) because both compute from the same `entry`.
- A corridor may therefore have doors you can't use yet (the room beyond is entered from elsewhere);
  that's fine — another corridor holds that room's entry. Authors **never** hand-set `opensOnSolve`.

**Two guards run over `world.json` in `flutter test`** (`world_validator.dart`):
- `findDirectionViolations`: every room declares a valid `entry`; the graph is symmetric (no
  one-way doors); each entry neighbour is reachable without solving that room.
- `findCorridorLivenessViolations`: every corridor/plaza has **≥2 non-secret doors and ≥1
  always-open door** — so however you arrive, there's always an open way onward (your entry door +
  that one ≥ 2). Secret doors don't count.

## 1. Principles (recap + formalization)
- **Rooms are passages**: entry side always open, exit side `opensOnSolve`. Solved rooms stay open
  both ways forever.
- **Cycles are the point.** The maze must contain loops so exploration produces recognition
  ("I've been here — from the other side!") and backtracking is never a chore.
- **Optional/reward rooms** may be single-door dead ends (the one sanctioned exception to
  two-door rooms) — they hold collectibles, never progress.
- **THE KINDNESS LAW (formal):** for every puzzle room R, a player who can *never* solve R must
  still be able to reach every other node of the castle. Graph-theoretically: **no puzzle room may
  be a cut vertex** of the world graph. Deliberate exceptions (the final gate region) must be
  declared explicitly. Enforced by the validator (§3) on every world change.
- **Junction variety** (GDD §4): rooms reachable from one junction span different disciplines.

## 2. Corridor identity — "street names" without words
Every corridor gets a **badge**: a simple geometric glyph from a reserved family —
**circle ○, triangle △, square □, diamond ◇, star ☆, hexagon ⬡** (extend only when exhausted).
- The badge is posted **on every door that leads INTO that corridor** (drawn on the door body,
  below the discipline/status glyphs — architecture, not ephemera, STYLE_GUIDE §2 rule 9), and
  **once inside the corridor** as a **bas-relief carving** in the stone (centred, high in the
  tunnel ceiling) — rendered in the masonry colours (surface + ink + bg two-tone), NOT a posted
  sign-board. One carving per corridor.
- So a door tells you: *what kind of puzzle* (discipline glyph) or *which street* (corridor badge)
  lies behind it — and standing in a corridor, the wall badge answers "which street am I on?"
- Badges are taught passively, by repetition; registered in [SYMBOLS.md §2](SYMBOLS.md) as the
  `street_*` family (INV).
- Corridors additionally vary a **motif knob** for texture-level recognition (M6+: wave pattern in
  the ceiling courses, hanging chains, drip stains — one per corridor, subtle, ink-only).

## 3. The no-soft-lock validator
`lib/game/level/world_validator.dart` — pure Dart, runs in `flutter test` over the real
`world.json` (alongside the per-level door-reachability path checker):
1. Build the undirected node graph from every `exits` entry (locks are ignored: a lock is a
   solve-state, not topology).
2. Assert the graph is **fully connected** from `start`.
3. For every `room` node R: delete R and recompute reachability from `start`. Every other node
   must remain reachable. Nodes listed in the world's declared **`finalGated`** set are exempt
   (M6 adds the field when the exit is built).
4. Any violation fails CI with the room named and the stranded nodes listed.

## 4. The M6 castle graph
Nine new/changed nodes on top of the shipped mini-loop. Three streets, two plazas, six puzzle
rooms (+1 reward vault), one exit. Disciplines marked; all rules above hold (validated mentally
here, mechanically by the validator when built).

```
                 ○ corridor_01 ════════ stairs ════════╗
                /        ║                             ║
        (start)          ║ east                        ║
                         ▼                             ▼
                      PLAZA hub_01                □ corridor_03  (boulders)
                     /    |     \                /      |       \
              plates(M)  stack(M/G)  mirror(O)  counter(G)  sokoban(L)   exit→ EXIT_HALL
                     \    |     /               /       |                      (final gate)
                      ▼   ▼    ▼               /        ▼
                  △ corridor_02 ═══ plaza ═══ PLAZA hub_02 ──→ vault (reward, dead end)
                         ║ deep                 ▲
                         ▼                      │ east
                      fulcrum(M) ───────────────┘
```

| Node | Type | Street/discipline | Doors (exit name → target) | Notes |
|---|---|---|---|---|
| `corridor_01` | corridor ○ | start | east→hub_01, stairs→corridor_03 | the grand loop closes here |
| `hub_01` | plaza | — | west→corridor_01, plates→, stack→, east→room_mirror | shipped |
| `room_plates` | room | Mechanics | west→hub_01, east→corridor_02 | shipped |
| `room_stack` | room | Mech/Gravity | west→hub_01, east→corridor_02 | shipped |
| `room_mirror` | room | Optics | west→corridor_02, east→hub_01 | shipped |
| `corridor_02` | corridor △ | — | west→plates, east→stack, mirror→, deep→room_fulcrum, plaza→hub_02 | 5 doors — the maze's spine |
| `room_fulcrum` | room | Mechanics (P3) | west→corridor_02, east→hub_02 | parallel to the plain plaza door (puzzle = shortcut + exit credit) |
| `hub_02` | plaza | — | west→corridor_02, fulcrum→, counter→, soko→, vault→ | |
| `room_counter` | room | Gravity (counterweight) | west→hub_02, east→corridor_03 | |
| `room_sokoban` | room | Logic (carry-onto-plates) | west→hub_02, east→corridor_03 | |
| `room_vault` | room | Reward (optional) | door→hub_02 | dead end: first lore etching + future star door |
| `corridor_03` | corridor □ | boulder hazard | west→counter, east→sokoban, stairs→corridor_01, exit→exit_hall | M6's new hazard lives here |
| `exit_hall` | room | THE EXIT | west→corridor_03 | exit door gated `anyOf 4` of the 6 puzzle rooms (kind: slack of 2); the door itself is the only sanctioned gate |

**Cycles delivered:** hub_01↔rooms↔corridor_02 (two small), hub_02↔rooms↔corridor_03 (one),
and the **grand loop** corridor_01→…→corridor_03→stairs→corridor_01 — the castle wraps onto
itself, so "the long way home" always exists and the stairs door is the "aha, it all connects"
moment.

**Cut-vertex audit:** every room has a parallel route (plates‖stack; mirror optional;
fulcrum‖plaza door; counter‖sokoban; vault is a leaf). Removing any single room strands nothing.
`exit_hall` is a leaf behind the declared final gate — exempt by design.

## 5. The castle map screen *(builds in M7 with the shell)*
Top-down **discovered-graph** map — play stays side-view; the map is how the maze stays legible
(and the replayability mirror: "how many doors did I never open?").
- **Nodes**: corridors drawn as their street badge (○ △ □…), plazas as larger rounded squares,
  rooms as small squares bearing their discipline glyph. Visited nodes solid; **seen-but-unentered
  doors as dashed stubs** poking out of visited nodes.
- **Edges**: lines following the door connections (the world graph, not geometry).
- **State marks**: current position = the player pictogram pip; solved rooms = small open padlock;
  the exit (once seen) = the fire-exit glyph.
- Discovery data = `visitedNodes` + `seenDoors` sets on the save Progress (small schema addition,
  M7).
- Access: pause overlay (map glyph — register `map` in SYMBOLS when built). No text anywhere.

## 6. Authoring workflow (every new level/world change)
1. Sketch on the graph first; check junction variety + at least one parallel route per room.
2. Author level JSON per LEVEL_FORMAT conventions (water pools, crank reachability, badges).
3. `flutter test` must pass:
   - **path checker** (every door physically reachable) + **world validator** (no cut-vertex
     rooms, world connected);
   - **level-wiring test** (`test/level_wiring_test.dart`) — loads every shipped level that
     declares a puzzle, builds its puzzle entities through the one shared builder the game uses
     (`lib/game/level/puzzle_entity_builder.dart`), and asserts the script (a) resolves the
     entities it needs in `onLoad` and (b) can be driven from unsolved → solved. This is the guard
     that catches the *id/type wiring* a logic unit-test can't: a lever named `goalSwitch` while
     the script looks up `switch`, a renamed/mis-typed entity, or a script that can never report
     solved. **Extending it:** a new puzzle solved by "satisfy every entity" needs no change; a
     puzzle needing a specific interaction order gets a `case` in `_driveToSolved`; a puzzle that
     queries a brand-new entity *type* needs that type added to the shared `buildPuzzleEntity`
     (see its doc comment). Authoring a puzzle entity outside that builder will silently skip this
     guard — always go through it.
4. **Regenerate the castle map:** `dart run tool/castle_map.dart` — prints an ASCII map +
   validation summary to the console and writes `build/castle_map.html` (a standalone SVG graph
   you open in a browser: nodes coloured by type, edges coloured open / opens-on-solve / secret).
   It reuses the real `WorldData` + validators, so it can't drift from the game. Use it to eyeball
   the maze and to navigate during playtests. (Generated output is local/gitignored; the tool is
   committed.)
5. Walk it in-game; the path checker is optimistic about wide gaps — jump tests stay human.
