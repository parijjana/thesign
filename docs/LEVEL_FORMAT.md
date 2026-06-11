# Level Data Format

> Source of truth for how rooms, corridors, and the world graph are described in data.
> Decision: **JSON data + per-room Dart logic hooks**. Geometry & object placement are declarative
> JSON; bespoke puzzle behavior lives in a named Dart `PuzzleScript`.
> Loader: `lib/game/level/level_loader.dart`. Units: **tiles** (1 tile = 32 px). See [ARCHITECTURE.md](ARCHITECTURE.md) §3.

## 1. Files & locations
```
assets/levels/
  world.json            # the world graph: ordered nodes + connections
  room_p1.json          # a room
  corridor_01.json      # a corridor
  ...
```
Every level file is validated on load; a malformed file fails loudly in dev (assert), not silently.

## 2. World graph — `world.json`
Defines the nodes and how they connect. The graph is **hub-and-spoke**: `corridor` nodes link two
`hub` (cul-de-sac) nodes; each `hub` fans out to several `room` nodes plus one onward `corridor`.

```json
{
  "version": 1,
  "start": "corridor_01",
  "nodes": [
    {
      "id": "corridor_01",
      "type": "corridor",
      "file": "corridor_01.json",
      "exits": { "east": "hub_01" }
    },
    {
      "id": "hub_01",
      "type": "hub",
      "file": "hub_01.json",
      "rooms": ["room_p1", "room_p2", "room_p3"],
      "unlock": { "rule": "anyOf", "count": 1 },
      "exits": { "east": "corridor_02" }
    },
    {
      "id": "room_p1",
      "type": "room",
      "file": "room_p1.json",
      "parent": "hub_01"
    }
  ]
}
```
- `exits` maps a named door/side → target node id. Door entities reference the same exit name so the
  loader knows where each door leads and where to place the player on arrival.
- **`hub` nodes** declare `rooms` (the room nodes reachable from this cul-de-sac) and an `unlock`
  rule controlling when the onward `exits` door opens:
  - `{ "rule": "anyOf", "count": 1 }` — **default, kid-friendly**: solving any 1 listed room unlocks
    the way forward.
  - `{ "rule": "anyOf", "count": 2 }` — solve any 2 of the listed rooms.
  - `{ "rule": "specific", "rooms": ["room_p2"] }` — a particular room must be solved.
  - rooms not needed for the unlock are **optional/reward** rooms.
- **`room` nodes** declare a `parent` hub. A room's entry door always leads back to its parent hub;
  the loader records the parent so "back out" / "give up" returns the player to the hub.

## 3. Room / corridor / hub file schema
The same schema describes all three node kinds (`room`, `corridor`, `hub`). Hubs are just small
spaces whose `door` entities lead to rooms + the onward corridor.
```json
{
  "version": 1,
  "id": "room_p1",
  "type": "room",                  // "room" | "corridor" | "hub"
  "name": "Pressure",              // dev-facing label
  "size": { "w": 24, "h": 14 },    // in tiles; defines bounds & camera framing
  "palette": "amber",              // optional; defaults to active palette (see STYLE_GUIDE §3.2)
  "physics": "kinematic",          // "kinematic" (default) | "forge2d"
  "puzzle": "p1_pressure_plates",  // id of the Dart PuzzleScript to attach (rooms only)
  "entryPoints": {                 // where the player spawns when entering via a given exit name
    "west": { "x": 2,  "y": 11 },
    "east": { "x": 21, "y": 11 }
  },
  "start": { "x": 2, "y": 11 },    // NO-DEATH reset point: where the player returns to on reset
                                   // (hazard contact in a corridor, room restart, or puzzle reset)
  "entities": [
    { "type": "floor", "x": 0,  "y": 12, "w": 24, "h": 2 },
    { "type": "wall",  "x": 0,  "y": 0,  "w": 1,  "h": 12 },
    { "type": "wall",  "x": 23, "y": 0,  "w": 1,  "h": 12 },

    { "id": "plateA", "type": "pressure_plate", "x": 6,  "y": 11, "w": 2, "h": 1 },
    { "id": "blockA", "type": "pushable_block",  "x": 9,  "y": 10, "w": 1, "h": 1 },
    { "id": "goalSwitch", "type": "lever", "x": 18, "y": 11, "w": 1, "h": 1 },
    { "id": "gateA", "type": "gate", "x": 16, "y": 8, "w": 1, "h": 4, "props": { "openY": 4 } },

    { "id": "doorBack", "type": "door", "x": 2, "y": 10, "w": 1, "h": 2,
      "props": { "exit": "back", "locked": false } }
  ]
}
```
> Note: this is a `room`, so its single `doorBack` always returns to the parent hub (`"exit": "back"`).
> Solving the puzzle flips the script's `isSolved` to true, which marks the room **solved** and
> contributes to the parent hub's unlock — the player then walks back through `doorBack` to the hub
> and takes the now-open onward corridor.

### 3.1 Common fields
| Field | Meaning |
|---|---|
| `id` | Optional for static geometry; **required** for anything a puzzle script references. |
| `type` | Entity kind → maps to a component class in `lib/game/components/`. |
| `x, y` | Top-left position in tiles (fractional allowed). |
| `w, h` | Size in tiles. |
| `props` | Type-specific bag (see §4). |

## 4. Entity types & their `props`
| `type` | Component | Key props |
|---|---|---|
| `floor` | `FloorComponent` | — (solid) |
| `wall` | `WallComponent` | — (solid) |
| `player_start` | sets initial spawn if no entry used | — |
| `door` | `DoorComponent` | `exit` (exit name in world graph; for a room's entry door this is omitted/`"back"` → returns to parent hub), `locked` (bool), `keyId` (string, if locked) |
| `gate` | `GateComponent` | `openY`/`openX` (offset when open), `startsOpen` (bool) |
| `lever` | `LeverComponent` | `startsOn` (bool), `group` (string, for sequences) |
| `pressure_plate` | `PressurePlateComponent` | `requiresWeight` (number, optional) |
| `pushable_block` | `PushableBlockComponent` | `weight` (number) |
| `key` | `KeyComponent` | `keyId` (string) |
| `moving_platform` | `MovingPlatformComponent` | `path` (array of `{x,y}` tiles), `speed`, `loop` (bool) |
| `water` | `WaterPool` | — (reset trigger: fall in → the claw fishes the player out to node `start`, no death; sunk blocks snap home). The kid-friendly hazard, no-swimming-sign motifs. |
| `boulder` | `BoulderComponent` (scripted) | `track` (array of `{x,y}`), `trigger` (zone id / `"proximity"`); contact = reset, not death |
| `boulder_forge2d` | `BoulderForge2DComponent` | `radius`, `density` — **only in `physics: forge2d` rooms** |
| `trigger_zone` | invisible `TriggerZone` | `zoneId` (string) — fires enter/exit to the puzzle script |
| `warning_sign` | `WarningSignComponent` | `glyph` (a symbol id, e.g. `"hazard"`, `"spike"`, `"boulder"`) — telegraph only |
| `etching` | `EtchingComponent` | `etchingId` (string) — a findable lore etching; first touch records it in the profile's gallery (GDD §9). Non-solid, purely collectible. |
| `anchor_socket` *(DRAFT)* | `AnchorSocketComponent` | `accepts` (tool id, e.g. `"tool_pulley"`) — marked point where a Field Kit tool attaches (GDD §9b). **Do not author until the §9b design pass closes (ROADMAP M5.5);** schema may change. |

> *(DRAFT, same gate)*: `door` gains an optional `requiresTool`/`requiresArtifact` prop for
> star-marked **bonus doors** — never used on the main path (GDD §9b rule 4).

> Solid vs trigger is determined by type (floor/wall/gate/platform = solid; plate/spike/zone/door =
> trigger). The loader assigns this; JSON authors don't set it.
>
> **No reset/claw entity:** the excavator-claw reset is a global system, not an authored object — it
> activates on hazard contact / restart and uses the node's `start` (see ARCHITECTURE §5.6).

### 4.1 Discipline entity types (grow this as disciplines are built)
New puzzle disciplines from [PUZZLES.md](PUZZLES.md) add their own entity types + components. Add
each here when implemented. Representative (not yet all built):

| Discipline | `type` examples | Notable props |
|---|---|---|
| Optics | `light_source`, `mirror`, `crank`, `prism`, `lens`, `light_sensor`, `beam_splitter` | mirror: `start` (`"/"`/`"\\"`), `rotatable` (bool — false when crank-driven); crank: `target` (mirror id), `hideChain` (bool — hide the chain to make the mapping part of the puzzle); `color` (token); sensor: `wantsColor` |
| Mechanics | `fulcrum_lever`, `pulley`, `gear`, `seesaw`, `ramp` | `fulcrumMovable` (bool), `ratio` (visual), `teeth`, `pivot` |
| Gravity/Proj. | `launcher`, `counterweight`, `spring` | `angleDial` (bool), `powerCharge` (bool) |
| Fluids | `tank`, `pipe`, `valve`, `float`, `water_source` | `level`, `connectsTo`, `density` |
| Chemistry | `beaker`, `reagent_source`, `pour_target`, `mix_vessel` | `reagent` (token), `ratioGoal` (visual proportions), `productEffect` |
| Electricity/Mag. | `power_source`, `wire`, `switch_node`, `logic_node`, `magnet`, `electromagnet` | `op` (`and`/`or`/`not`), `polarity`, `powered` |
| Thermo | `heater`, `ice_block`, `steam_vent`, `metal_bar` | `temp_state` (`hot`/`cold`/`frozen`) |
| Sports | `ball_machine`, `ball`, `racket_zone`, `hoop`, `target_ring`, `pins` | `fireInterval`, `targetZone`, `bankable` |

> All puzzle-relevant **quantities are authored as visual goals** (proportions, levels, pip counts),
> never numerals exposed to the player — the UI renders them as fills/dials/dots (STYLE_GUIDE §8b).

## 5. Puzzle scripts (the logic hooks)
- Each room names one script via `"puzzle": "<id>"`. The loader looks the id up in a registry and
  attaches an instance.
- Base class (see `lib/game/puzzles/puzzle_script.dart`):

```dart
abstract class PuzzleScript {
  void onLoad(Room room);                 // grab entities by id, wire initial state
  void onUpdate(double dt) {}             // per-frame logic (timers, sequences)
  void onInteract(GameObject target) {}   // player pressed interact on `target`
  void onTrigger(String zoneId, GameObject body, bool entered) {} // zone enter/exit
  bool get isSolved;                      // when true -> room's exit unlocks
  void onReset() {}                       // optional: behavior on player respawn
  String? get hintTargetId => null;       // entity the hint halo pulses on (HUD lightbulb)

  // Provided by the base: emit feedback events rendered as popup glyphs over the
  // entity (red !, yellow lightbulb, green success — SYMBOLS §6b); audio attaches
  // to the same stream later.
  void emitError(String entityId) {...}
  void emitIdea(String entityId) {...}
  void emitSuccess(String entityId) {...}
}
```
- Scripts reference entities by their JSON `id` (e.g. `room.byId('plateA')`). This keeps geometry in
  data and behavior in code, cleanly separated.
- `isSolved` flipping true is the signal the loader uses to unlock/open the room's exit door.
- Scripts are **unit-testable headless**: load a room, simulate interacts/triggers, assert `isSolved`.

### Example mapping (P1 — pressure plates)
- JSON declares `plateA`, `blockA`, `gateA`, `goalSwitch`, `doorBack`.
- `p1_pressure_plates.dart`: push `blockA` onto `plateA` to open `gateA`, which guards `goalSwitch`;
  pulling `goalSwitch` sets `isSolved = true`. The room is now marked solved (it contributes to the
  parent hub's unlock). The player leaves via `doorBack` to the hub. No death anywhere — falling or
  mis-stepping just resets the player to the room `start`.

## 6. Authoring conventions
- Keep room files small and one-idea (mirrors GDD §6). Combine ideas only in later rooms.
- Always place a `start` (no-death reset point) and at least one `entryPoint`.
- Every room needs an **entry door back to its parent hub** so the player can always leave (no-death,
  never-blocked). Hubs need a door per listed room plus the onward `exit` door.
- Telegraph every hazard with a `warning_sign` or a visible `track`/`path` (style + fairness rule).
- **Reachability rule: every interactable must be operable from the ground or a platform.** An
  elevated mechanism (a mirror half-way up a wall) gets a ground-level **`crank`** + chain — the
  gear column stands on a floor/platform at a fixed kid height. The chain is visible by default;
  `hideChain` (routing it "behind the wall") is a deliberate later-game difficulty knob.
- **Every door must be PROVABLY reachable: the path checker enforces it.**
  `lib/game/level/path_checker.dart` flood-fills the level's playable space (walls, ceilings, and
  jump height respected; gates checked open, blocks treated as movable aids) and
  `test/path_checker_test.dart` runs it over **every node in world.json** — an unreachable door
  fails the test suite before the level can ship. The checker is deliberately optimistic about
  horizontal air control (it won't catch a too-wide gap — playtest for those); arc-accurate
  checking can come with the M5.7 pass.
- Prefer `kinematic` physics; set `physics: "forge2d"` **only** when a puzzle truly needs rolling/
  emergent physics, and keep such rooms rare and well-tested.
- Use stable, descriptive `id`s — they're the contract between JSON and the puzzle script.

## 7. Versioning
- Every file carries `"version"`. The loader checks it and can migrate or reject old formats.
- Breaking changes to this spec bump the version and update the loader + this document together.
