# M6 Build Plan — the expansive castle *(living checklist — update as built)*

> THE resumability artifact: if a session dies mid-M6, read this + MAZE.md and continue from the
> first unchecked box. Mark boxes as phases land (one commit per phase).
> Mandate: depth, breadth, HIDDEN ROOMS. Foundation (M0–M5.7) is done and trusted.

## The castle v2 (supersedes MAZE.md §4 — 22 nodes, 3 acts)

```
ACT I (shipped)            ACT II                       ACT III
○ cor_01 ─ hub_01 ─┬ plates ┐                ┌ counter ┐ □ cor_03 ── far ── hub_03 ─┬ splitter ┐
   │(start)        ├ stack ─┤△ cor_02 ─ deep ─ fulcrum ─ hub_02 ─┤   │(boulders)      ├ sequence ┤ ☆ cor_05
   │               └ mirror ┘   │   └ plaza ──────────┘ │ soko ──┘   │                └ (secret: attic)  │mid
   └── stairs ═══════════════════════════════════════ stairs ────────┘                          capstone
                                 │(secret: arch)        │ vault, north ─ ◇ cor_04 ─ hub_03         │
                                 └ (stack has secret room)                                     EXIT_HALL
```

Doors per node (exits name→target; ALL must have matching entryPoints):
- `cor_01` ○: east→hub_01, **stairs→cor_03** *(edit shipped file)*
- `hub_01`: unchanged (west, plates, stack, east→room_mirror)
- `room_plates`: unchanged
- `room_stack`: west, east + **secret→secret_stack** *(secret door high right, reached from ledge)*
- `room_mirror`: unchanged
- `cor_02` △: west, east, mirror, **deep→room_fulcrum, plaza→hub_02, secret→secret_arch**
- `secret_arch` (hidden): door→cor_02. Contents: etching.
- `secret_stack` (hidden): door→room_stack. Contents: etching.
- `room_fulcrum` (Mech, SEESAW): west→cor_02, east→hub_02
- `hub_02`: west→cor_02, fulcrum→, counter→, soko→, vault→, **north→cor_04**
- `room_counter` (Gravity, COUNTERWEIGHT LIFT): west→hub_02, east→cor_03
- `room_sokoban` (Logic, plates×3 + blocks): west→hub_02, east→cor_03
- `room_vault` (reward leaf): door→hub_02. Contents: etching ×2.
- `cor_03` □ (BOULDERS): west→room_counter, east→room_sokoban, stairs→cor_01, far→hub_03
- `cor_04` ◇ (MOVING PLATFORMS over water): south→hub_02, north→hub_03
- `hub_03`: south→cor_04, west→cor_03, split→room_splitter, seq→room_sequence,
  **secret→secret_attic**, cap→cor_05? NO — see cor_05
- `room_splitter` (Optics, BEAM SPLITTER → 2 sensors): west→hub_03, east→cor_05
- `room_sequence` (Logic, ORDERED LEVERS w/ pip signs): west→hub_03, east→cor_05
- `secret_attic` (hidden): door→hub_03. Contents: etching ×2.
- `cor_05` ☆ (WATER GAUNTLET: pools + moving platforms): west→room_splitter, east→room_sequence,
  mid→room_capstone
- `room_capstone` (FUSION mech+optics: block-on-plate holds gate open; gate blocks beam; sensor
  opens exit side): west→cor_05, east→exit_hall — **the one allowed cut vertex**
- `exit_hall`: west→room_capstone. The "exit" = a big teleporter (spawn swirl glyph) — the twist.

Validator: `allowedGates: {'exit_hall'}`. Cut-vertex audit: every other room has a parallel route.

## Phases & checklist

**Phase 0 — plan + docs** ✅ *(this file; MAZE.md §4 superseded note)*

**Phase 1 — engine components** ✅
- [x] `moving_platform.dart`: path[], speed, loop|pingpong; solid mutates; carries riders
      (player + settled blocks get the delta); Resettable → whirlwind re-inits.
- [x] `boulder.dart`: ceiling slot; telegraph shake → fall (overlap player → requestReset) →
      land → poof → respawn. Resettable.
- [x] `seesaw.dart`: 2 pan solids on a pivot; tilt from weight (player=1, block=1 per side);
      pans animate ±0.75t; riders carried.
- [x] `counter_lift.dart`: basket zone + platform solid; height = base − 1.5t·(blocks in basket);
      riders carried.
- [x] optics: `splitter` obstacle in beam_tracer (pass-through + '/'-reflect branch) +
      `Splitter` component (mirror-like, frame + diagonal + dot).
- [x] `secret door`: Door(secret:true) renders as cracked brick panel (not arch); prompt hidden
      until discovered; first pass-through → progress.discoveredSecrets + fb_success; discovered →
      dark gap rendering.
- [x] `etching.dart`: wall plaque (framed glyph); auto-collect on overlap → foundEtchings +
      fb_success; found → goal-green frame.
- [x] `sign` pips prop (q_pips row, glyph optional) for the sequence room.
- [x] street badge glyphs in symbols.dart: streetCircle/Triangle/Square/Diamond/Star/Hex (+ map
      'street_*' in loader; door glyph slot doubles for badges).
- [x] save: Progress gains foundEtchings, discoveredSecrets, visitedNodes (defaults, back-compat);
      game tracks/persists.

**Phase 2 — puzzle scripts + tests** ✅
- [x] `p3_seesaw.dart`: solved = goal lever on (lever sits high beside LEFT pan top; rise by
      loading right pan with 2 blocks).
- [x] `p_counterweight.dart`: solved = high lever on (ride lifted platform).
- [x] `p_sokoban.dart`: solved = ALL pressure plates pressed simultaneously (latched).
- [x] `p_splitter.dart`: solved = both sensors lit at once (latched).
- [x] `p_sequence.dart`: levers in pip order; wrong flip → all off + fb_error; complete → solved.
- [x] `p_capstone.dart`: gate.open = plate.pressed; solved = sensor.lit (latched).
- [x] registry entries + headless tests (sequence wrong-order reset, sokoban all-plates,
      splitter both-sensors).

**Phase 3 — levels + world** ✅
- [x] world.json v2 (22 nodes per the table above).
- [x] edit: cor_01 (+stairs door), cor_02 (+deep/plaza/secret), room_stack (+secret door + ledge
      route), hub_02 (replace placeholder exits: +north).  *(hub_02 was new, built fresh)*
- [x] new JSONs: room_fulcrum, room_counter, room_sokoban, room_vault, cor_03, cor_04, hub_03,
      room_splitter, room_sequence, secret_arch, secret_stack, secret_attic, cor_05,
      room_capstone, exit_hall.
- [x] street badges: corridor-bound doors get street_* glyph; badge signs inside corridors.
- [x] water jeopardy in every new puzzle room (GDD §7); telegraphs everywhere.
- [x] `flutter test` green: path checker × all nodes + validator (allowedGates {exit_hall}).

**Phase 4 — verify + ship** ✅ *(code-verified: 65 tests green, release build OK, launched)*
- [x] analyze + full suite + windows build, launch for user.
- [ ] user playthrough; kid test when convenient.
- [x] docs sync: MAZE.md note → M6_PLAN as built source; ROADMAP M6 ✅; memory update.

## Component design notes (enough to rebuild from scratch)
- **MovingPlatform**: constructor(points<Vector2 px>, speed px/s, loop bool). Update: advance along
  segment; delta applied to own Aabb then to riders: player if player.aabb rests on top (|bottom−top|≤2
  & x-overlap) → player.position += delta; same for settled blocks. Render: rounded bar `surface`
  + ink + motion arrows. Registers solid + resetController.
- **Boulder**: slot at (x, ceilingBottom). States: armed (boulder peeks from slot) → triggered when
  player x within ±1.5t and below (telegraph: 0.35s shake) → falling (vy += g; player overlap →
  requestReset, boulder keeps falling) → landed (poof anim 0.4s, fades) → cooldown 2.5s → armed.
  Resettable → armed. Render: circle `accentDanger` heavy ink + slot notch in ceiling.
- **Seesaw**: pivot (x,y); arm half-length 2.5t; pans 1.5t wide solids hanging at arm ends. tilt
  target = clamp(rightWeight−leftWeight,−1,1); pan dy = ±0.75t·tilt animated 2t/s; weights:
  settled blocks & player whose aabb sits on pan top zone. Riders carried by delta.
- **CounterLift**: platform solid (1.5t wide) at column x; basket zone (static floor pen) nearby;
  height = baseY − 1.5t·min(blocksInBasket,2); animate 1.5t/s; carries riders.
- **Splitter in tracer**: BeamObstacle.splitter(box, state '/'): on hit → recurse BOTH continue-dir
  and reflect(state) from center (shared hops budget, segments, lit set).
- **SecretDoor render**: same rect as wall; brick courses; 3 crack strokes (ink 1.6) + tiny rubble;
  discovered: inner dark arch (ink fill 70%) + cracks. Prompt suppressed pre-discovery
  (Interactable gains `promptHidden`); interact always works.
- **Etching**: 1×1t plaque: double-frame board, glyph from props (any SymbolId), auto-collect on
  player overlap (no verb — walking close enough is the discovery).
- **Pip sign**: Sign(pips:n) draws n filled ink dots in a row (glyph optional, above dots if both).

## Room sketches (coords in tiles; all 24×14; entry west x2.5 unless noted)
- **fulcrum**: pivot at (12,11); pans at x9.5–11 (left) & x13–14.5 (right); 2 blocks at x5,x7;
  goal lever on high ledge x8,y6.75 (floor 7.5–9.5@y7.5) reachable only by riding LEFT pan up
  (load right pan); water pit x17.5–19; doors W/E.
- **counter**: basket pen x8–10 (low walls h0.5); platform column x14 (rides y11→y6.5 with 2
  blocks); high ledge x15.5–18@y6.5 with goal lever; blocks at x4,x6; water x19–20.5.
- **sokoban**: 3 plates (x8,x12,x16 @y11.65), 3 blocks (x5,x10,x14); low ceiling shelf y9 over
  plates row (carry under); water x19.5–21.
- **vault**: cozy leaf: 2 etchings (claw glyph + sun glyph) on back wall; bench floor.
- **cor_03** □: boulders at x8 & x15 (slots in deep tunnel ceiling y6); floor water x11–12.5;
  doors: W(x1.6)→counter, E(x21)→soko, stairs(x5)→cor_01, far(x18)→hub_03.
- **cor_04** ◇: water x6–18 (wide!); moving platform path (6.5,11)→(16.5,11) speed 60; second
  platform (10,8.5)→(14,8.5); doors S(x2)→hub_02, N(x21)→hub_03.
- **hub_03**: doors: south(x2)→cor_04, west(x5.5)→cor_03, split(x9.5), seq(x13.5),
  secret(x18, cracked wall)→secret_attic.
- **splitter**: src (1.5,5.5)E; splitter at (8,5.5) '/'; sensorA (21,1.5) via up-leg mirror m1
  (8,1.5)'/'→E… simpler: splitter splits E into E(pass)+N(reflect); pass → sensorB (21,5.5
  needs pillar gap) hmm — final: src(1.5,5.5)E → splitter(8,5.5,'/') → pass E to sensorB(16,5.5);
  reflect N to m1(8,1.5) start '\' (player cranks to '/') → E to sensorA(21,1.5). Crank x11.
  Water x18.5–20.
- **sequence**: 3 levers x6/x11/x16 with pip signs (1/2/3) SHUFFLED on wall: lever@6=pips2,
  @11=pips3, @16=pips1 → press order x16,x6,x11. Water x19.5–21.
- **secret rooms**: small furnished leaves; arch: etching(water glyph); stack-secret: etching
  (d_mechanics); attic: etchings(hint bulb + street_star).
- **cor_05** ☆: 3 pools (x5–7.5, x10–12.5, x15.5–17.5) with 2 moving platforms over them;
  doors W(x1.6)→splitter, E(x21)→sequence, mid(x13)→capstone.
- **capstone**: plate x5; blocks x8; gate x12 (y2–7!) blocking BEAM row y4 (src 1.5,3.5 E;
  sensor 21,3.5); block on plate → gate opens (slides UP out of beam) → beam crosses → solved;
  door E opensOnSolve; water x16–17.5. Beam above walk level; gate tall.
- **exit_hall**: teleporter: big swirl glyph (spawn) on pedestal center; walking into it = (M7+:
  ending) for now fb_success fireworks-ish popup + nothing (door back stays open).

## Risks / notes
- Boulder & platforms are the first whirlwind-reset CONSUMERS (register w/ resetController).
- Splitter recursion: cap total segments 64.
- Sequence room: lever.onInteract notifies script BEFORE script can untoggle: script may set
  lever.on=false (allowed — public field).
- visitedNodes grows save JSON; harmless.
- Path checker: capstone beam/gate don't affect it (gate ignored=open ✓). cor_04 crossing relies
  on moving platforms — checker treats gaps optimistically ✓ (humans verify rides).
