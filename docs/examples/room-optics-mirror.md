# Worked Example — Optics: Mirror Routing room

> A concrete, end-to-end design for one room: the **first Optics room** (the first "wow" discipline,
> per [ROADMAP.md](../ROADMAP.md) M4). Shows how a [PUZZLES.md](../PUZZLES.md) concept becomes a
> level JSON + a `PuzzleScript` + the supporting system, all under the no-text rule. A visual layout
> is rendered alongside this doc in chat.

## 1. The idea (one sentence)
A fixed light source shoots a beam; the player **rotates mirrors** to bend the beam onto a sensor,
which unlocks the door back to the hub. Teaches "a 45° mirror turns light 90°" by doing.

## 2. Discipline & palette
- Discipline: **Optics**, so this **room** uses the **indigo palette** (`bg #241F4A`) — dark so the
  beam and sensor read clearly ([PUZZLES.md §Theme↔color](../PUZZLES.md), [STYLE_GUIDE §3.2](../STYLE_GUIDE.md)).
  The hub outside stays castle amber; its door to this room carries the `d_optics` glyph — stepping
  in *is* the color shift.
- New color token needed: **`beam`** — a bright pale-yellow `#F2E27A` light line (flat, no glow;
  reflection points get a small spark mark). Add to every palette like other role tokens.

## 3. Layout (24×14 tiles, floor at y=12)
```
   x→  0    4    8    12   16   20  23
 y0  ┌────────────────────────────────┐
     │                                 │
 y2  │        M2�ً  ····E····► (◎)sensor│   ← beam top run, above the pillar
     │         ▲                       │
 y4  │         │              ███      │
     │         │              ███pillar│
 y6  │ (☀)src ─E─► M1         ███      │   ← source beam, blocked by pillar if straight
     │                        ███      │
 y8  │                        ███      │
     │                                 │
y10  │  [door⟲back]                    │
y12  ├─────────────────────────────────┤   ← floor
     └─────────────────────────────────┘
```
Beam solution path: `src (E) → M1 set "/" (turns E→N) → up → M2 set "\" (turns N→E) → (E) → sensor`.
The pillar (x≈14, y4–12) blocks the straight shot, motivating the climb over the top at y≈2.

## 4. The level JSON (`assets/levels/room_optics_mirror.json`)
Follows [LEVEL_FORMAT.md](../LEVEL_FORMAT.md). Positions in tiles.
```json
{
  "version": 1,
  "id": "room_optics_mirror",
  "type": "room",
  "name": "First Light",
  "size": { "w": 24, "h": 14 },
  "palette": "optics",
  "physics": "kinematic",
  "puzzle": "optics_mirror",
  "parent": "hub_01",
  "entryPoints": { "back": { "x": 3, "y": 11 } },
  "start": { "x": 3, "y": 11 },
  "entities": [
    { "type": "floor", "x": 0, "y": 12, "w": 24, "h": 2 },
    { "type": "wall",  "x": 0, "y": 0,  "w": 1,  "h": 12 },
    { "type": "wall",  "x": 23,"y": 0,  "w": 1,  "h": 12 },
    { "type": "wall",  "x": 14,"y": 4,  "w": 2,  "h": 8, "id": "pillar" },

    { "id": "src", "type": "light_source", "x": 1, "y": 6, "w": 1, "h": 1,
      "props": { "dir": "east", "color": "beam" } },

    { "id": "m1", "type": "mirror", "x": 8, "y": 6, "w": 1, "h": 1,
      "props": { "rotatable": true, "states": ["/","\\"], "start": "\\" } },
    { "id": "m2", "type": "mirror", "x": 8, "y": 2, "w": 1, "h": 1,
      "props": { "rotatable": true, "states": ["/","\\"], "start": "/" } },

    { "id": "sensorA", "type": "light_sensor", "x": 21, "y": 2, "w": 1, "h": 1,
      "props": { "face": "west", "wantsColor": "any" } },

    { "id": "doorBack", "type": "door", "x": 2, "y": 10, "w": 1, "h": 2,
      "props": { "exit": "back", "locked": true, "opensOnSolve": true } }
  ]
}
```
> Both mirrors **start in the wrong orientation** (`m1:"\"`, `m2:"/"`) so the beam initially
> dead-ends — the player must fix both. *Difficulty knob:* for the very first teaching room, set
> `m2.start` to `"\\"` (already correct) so only **one** rotation is needed; the sibling room in the
> hub can require both.

## 5. Supporting system — the beam tracer
A small, deterministic raycaster (`lib/game/core/beam_tracer.dart`), retraced whenever a mirror
changes (or each fixed step — it's cheap):

```
trace(source):
  pos  = source.center
  dir  = unit(source.dir)              # east = (1,0)
  for hops in 0..MAX_HOPS:             # MAX_HOPS ~16, guards infinite loops
    hit = raycast(pos, dir, opticsBodies)   # walls, mirrors, sensors
    drawSegment(pos, hit.point)        # render later in `beam` color
    switch hit.kind:
      WALL    -> stop
      SENSOR  -> hit.sensor.lit = true; stop
      MIRROR  -> dir = reflect(dir, hit.mirror.orientation)
                 pos = hit.point + dir*epsilon   # step off the surface
      NONE    -> stop                  # left the room
```
Reflection math (45° mirrors):
- `"/"` maps `(dx,dy) → (-dy,-dx)`  → east→north, north→east, …
- `"\"` maps `(dx,dy) → ( dy, dx)`  → east→south, north→west, …

Sensors are cleared at the start of each trace, so `lit` is true only while the beam currently
lands on them. Rendering: solid `beam`-colored polyline + a small spark glyph at each reflection.

## 6. The puzzle script (`lib/game/puzzles/optics_mirror.dart`, sketch)
```dart
class OpticsMirrorPuzzle extends PuzzleScript {
  late final LightSource source;
  late final List<Mirror> mirrors;
  late final LightSensor sensor;

  @override
  void onLoad(Room room) {
    source  = room.byId('src');
    mirrors = room.byType<Mirror>();
    sensor  = room.byId('sensorA');
    room.beam.attach(source); // tracer follows this source
  }

  @override
  void onInteract(GameObject target) {
    if (target is Mirror && target.rotatable) {
      target.cycleState();    // "/" <-> "\" ; tracer re-runs, beam visibly bends
    }
  }

  @override
  bool get isSolved => sensor.lit;   // loader opens `opensOnSolve` doors when true

  @override
  String? get hintTargetId =>        // HUD lightbulb pulses the hint halo here
      sensor.lit ? null : 'sensorA'; // v1: the waiting sensor; later: walk the chain

  @override
  void onReset() {
    // Puzzle progress is preserved by default (GDD §8); this script *opts in*
    // to returning mirrors to their authored start on a claw reset.
    for (final m in mirrors) m.setState(m.startState);
  }
}
```
- The loader watches `isSolved`; when true it flips `doorBack` `locked → unlocked` (padlock glyph
  animates open) and marks the room solved → contributes to `hub_01`'s `anyOf 1` unlock.
- No hazards here, so the claw only appears if the player taps **Restart** (which calls `onReset`).

## 7. How it teaches — with zero words
1. The source already emits a visible beam that **dead-ends on a wall** → the player sees "light, and
   it's stuck."
2. The sensor shows the dim **`goal` bullseye**, visibly *waiting* for light.
3. Standing by a mirror shows the **`interact` hand** hint; pressing it **rotates the mirror and the
   beam bends in real time** — instant cause→effect teaches the rule with no instruction.
4. When the beam lands on the sensor it **brightens to `accentGoal`** and the door **padlock pops
   open** — the win state is purely visual.

Every signal is a symbol or a visible physical change — consistent with [SYMBOLS.md](../SYMBOLS.md)
and [STYLE_GUIDE §8b](../STYLE_GUIDE.md).

## 8. New pieces this room introduces (add to the catalogues as built)
- **Entities:** `light_source`, `mirror`, `light_sensor` → register in [LEVEL_FORMAT §4.1](../LEVEL_FORMAT.md).
- **System:** `beam_tracer.dart` (reusable by every optics concept — prisms, lenses, splitters).
- **Token:** `beam` color → add to all palettes ([STYLE_GUIDE §3](../STYLE_GUIDE.md)).
- **Components:** `mirror.dart`, `light_source.dart`, `light_sensor.dart` → `lib/game/components/`.

## 9. Natural progressions (sibling / later rooms)
- Add a **third mirror** and a wall maze (intra-discipline depth).
- Add a **prism** that splits the beam; route the correct color to a color-matched sensor — each
  split color also gets a distinct **line pattern** (solid/dashed/dotted) echoed on its sensor, so
  the match never relies on hue alone (colorblind-safe, STYLE_GUIDE §2 rule 8).
- **Cross-discipline:** mount a mirror on a **fulcrum lever** (Mechanics) so aiming it is itself a
  force puzzle; or float a mirror up on a **chemistry-gas float** to reach the beam.
