# Puzzle Concepts — the living backlog

> Brainstorm + backlog of puzzle ideas, organized by discipline. Not a commitment — we pull from
> here as we build (GDD §6 points here). Each concept is "one idea"; later rooms **combine
> disciplines** (see §Difficulty). Visual rules: [STYLE_GUIDE.md](STYLE_GUIDE.md); data/entity
> shapes: [LEVEL_FORMAT.md](LEVEL_FORMAT.md).

## Puzzle design rules (apply to every concept here)
1. **No text, ever.** Goals, states, and quantities are shown with symbols and visuals, never words
   or numerals. See [STYLE_GUIDE.md §Iconography](STYLE_GUIDE.md). Ratios/forces/angles are shown as
   **fill levels, balance tilt, pip counts, dials, and proportional bars — not digits.**
2. **Self-teaching.** The first room of a discipline teaches its rule with a trivial, safe example
   before any real challenge. The player learns by doing, not by reading.
3. **Never hard-blocked.** Every puzzle room is a passage with an always-open entry door; a player
   who can't crack it walks back out and takes another route — the maze guarantees one exists
   (no puzzle room is a cut vertex, GDD §4 kindness law).
4. **Telegraphed & reversible.** Nothing is lost by experimenting; mistakes reset cheaply (the claw).
5. **One idea, then combine.** Introduce a mechanic alone; only mix disciplines once each is taught.
6. **Variety within a hub.** Sibling rooms in a cul-de-sac span **different disciplines** (one
   optics, one mechanics, one sports…) — never the same idea at different difficulties. Backing out
   always offers a different *kind of thinking* (GDD §4 variety rule).
7. **Color never stands alone.** Color-matching puzzles (prism split, beam mixing, reagents) must
   pair every color with a redundant pattern/shape cue — colorblind-safe by construction
   (STYLE_GUIDE §2 rule 8).

---

## Discipline catalogue

### ☀ Optics & Light
- **Mirror routing** — rotate/place mirrors to bounce a beam from a source onto a sensor that opens
  the door. *(The flagship example.)*
- **Prism split** — split a white beam into colors; route the *correct* color to a color-matched sensor.
- **Lens focus** — position a lens to converge a beam to a point (burn a rope, ignite a torch, hit a tiny sensor).
- **Additive color mixing** — overlap red/green/blue beams on a panel to make a target color.
- **Beam splitter networks** — one source must satisfy *two* sensors at once via a half-mirror.
- **Shadow casting** — block light so a shadow of the right *shape* falls on a shaped sensor.
- **Periscope climb** — chain mirrors vertically to carry light (and sightline) up a shaft.

### ⚙ Mechanics & Forces
- **Fulcrum levers** — reposition the fulcrum to trade distance for force and lift a heavy gate. *(Flagship.)*
- **Pulley advantage** — thread rope through more pulleys to multiply force and raise a load you couldn't alone.
- **Gear trains** — mesh gears of the right sizes to change speed/torque/direction and drive a mechanism.
- **Seesaw balance** — distribute weights (blocks, the player) to tip a platform to the needed angle.
- **Inclined planes** — set a ramp's angle so a ball rolls into a cup / reaches a ledge.
- **Pendulum timing** — set a pendulum's length so its swing carries a key across a gap on beat.
- **Flywheel/momentum** — spin up a wheel, then release stored rotational energy to power a one-shot lift.

### 🌍 Gravity & Projectiles
- **Trajectory launch** — choose angle + power (shown as a dial + a charging bar) to lob a ball into a target.
- **Counterweights** — drop/raise a counterweight to balance an elevator to the player's floor.
- **Slingshot / orbit** — use a gravity well to curve a projectile around an obstacle to a sensor.
- **Stacking under gravity** — build a stable tower of blocks to reach height (topples if unbalanced).
- **Controlled fall** — break a fall with platforms/springs so an egg-object lands intact on a plate.

### 💧 Fluids & Pressure
- **Buoyancy (Archimedes)** — raise the water level to float a key or a platform up to reach it.
- **Density sort** — make objects sink/float by changing fluid density (salt/oil layers) to clear a path.
- **Pipe routing** — connect pipe segments to deliver flow to a water-wheel that opens the gate.
- **Communicating vessels / siphon** — balance levels across connected tanks to release a lock.
- **Pneumatic piston** — build pressure to push a piston that shoves a block onto a plate.

### 🧪 Chemistry
- **Exact-ratio mixing** — pour reagents in a precise proportion (shown as beaker fill levels) to make a
  reactant that, poured on a surface, dissolves/etches the lock. *(Flagship.)*
- **Acid/base neutralize** — mix to hit "neutral" (a color-bar centers) so a corroded gate becomes safe to pass.
- **Catalyst & heat** — add a catalyst or apply a flame to trigger a reaction that produces gas/precipitate.
- **Crystallize a bridge** — grow crystals across a gap by feeding a saturated solution.
- **Effervescence lift** — a reaction makes bubbles/gas that inflate a float or push a piston (chem→fluids).

### ⚡ Electricity & Magnetism
- **Circuit completion** — route conductive blocks/wires to close a circuit and power the door.
- **Conductor vs insulator** — choose the right materials so current reaches the lock but not the player.
- **Logic connectors** — arrange AND/OR/NOT junctions (drawn as symbol nodes) so the output is "on."
- **Magnet polarity** — attract/repel a steel block across a gap by flipping poles.
- **Electromagnet hold/release** — power a magnet to grab a metal platform; cut power to drop it on cue.
- **Capacitor timing** — charge up, then dump a burst to trigger a brief, timed gate.

### 🔥 Thermodynamics & States of Matter
- **Freeze / melt** — freeze water into an ice platform or bridge; melt ice to lower a level or free an object.
- **Steam drive** — boil water to spin a turbine or build pressure that lifts a platform (thermo→fluids).
- **Expansion** — heat a metal bar so it lengthens and bridges a contact / cools to retract.
- **Heat routing** — guide heat (via conductors) to exactly one of several ice locks.

### 🔊 Sound & Waves
- **Resonance match** — tune an emitter to a target frequency (match two waveform shapes) to shatter a brittle barrier.
- **Standing waves** — set string/pipe length so a node lands on a sensor.
- **Echo timing** — trigger a pulse so its reflection returns exactly when a moving gate is open.

### 🧩 Logic & Pattern
- **Sequence/order** — actuate elements in the correct order (shown by symbol cues, not numbers).
- **Sokoban push** — push blocks onto plates without trapping them.
- **Symbol matching** — match the right signage pictograms (deeply on-theme) to a lock — a mini "language" of our own icons.
- **Weight/shape coding** — only the correctly shaped/weighted key fits the lock.
- **Mazes** — beam mazes, magnet mazes, pipe mazes.

---

## 🏅 Sports-based puzzles
Skill-flavored but still forgiving (aim/charge assists; infinite retries via the claw).
- **Tennis rally** — a ball machine fires balls; return them into a marked zone to trigger the door. *(Flagship.)*
- **Basketball** — arc a shot (trajectory) through a hoop to drop a key.
- **Mini-golf / putting** — putt a ball through banked obstacles into a hole-sensor (angles = optics-like banking).
- **Bowling** — roll to knock pins arranged so the right ones press plates.
- **Archery** — aim accounting for gravity drop to hit a bullseye sensor.
- **Penalty kick** — kick past a sweeping keeper-block into the goal.
- **Curling** — slide a stone, fighting friction, to stop precisely on a target ring.
- **Billiards / pool** — bank shots off cushions (angles + momentum) to pot a ball into a pocket-sensor.
- **Baseball batting** — time a swing to send a pitch into a target zone.
- **Pinball** — flippers keep a ball hitting a set of targets to charge the lock.
- **Soccer juggling / keepie-uppie** — keep a ball aloft on a plate for a held duration.

---

## More themes (grab-bag to mine later)
- **🎵 Music** — step on note-plates to replay a melody (Simon-style), pitches shown as bar heights.
- **🪐 Astronomy / orbits** — place planets/wells to slingshot a probe to a target; gravity assist.
- **🌬 Aerodynamics** — use fans/wind currents to float the player or carry a light object across.
- **🁢 Chain reaction (Rube Goldberg)** — arrange dominoes/ramps/levers so one push cascades to the final plate.
- **🧲 Magnetism mazes** — already above; rich enough to be its own zone.
- **🕰 Clockwork / timing** — synchronize rotating cogs and moving platforms to thread a path.
- **🌱 Growth / biology** — route a climbing vine or guide water to grow a ladder of plants.
- **🍳 Cooking ratios** — kid-friendly chemistry reskin: combine ingredients in proportion (visual cups).
- **🧭 Navigation / cartography** — follow a compass/map symbol trail to orient a rotating room.
- **🪞 Optical illusion / perspective** — align foreground shapes so they "complete" a target picture.
- **♟ Board-game logic** — knight's-move / lights-out style grids actuating plates.

---

## 🎨 Theme ↔ background-color coordination
Each **discipline** gets its own **palette** (same role tokens, different values — see
[STYLE_GUIDE.md §3.2](STYLE_GUIDE.md)). Palettes apply **per room**: a room declares the palette of
its discipline, while **hubs and corridors keep the castle palette** — so a hub can offer rooms from
several disciplines (rule 6 above) and *entering a room* is the color shift that cues the kind of
thinking. Each hub door also carries its room's discipline glyph (SYMBOLS §5), so the player can
read the choice before stepping in. Starting suggestions (tune on-screen):

| Discipline | Background feel | Why |
|---|---|---|
| Mechanics (default castle) | **Dungeon Amber** `#C9A227` | The home palette — also used by all hubs & corridors. |
| Optics & Light | Deep indigo `#241F4A` | Dark so beams and colors pop. |
| Chemistry | Muted teal `#235650` | "Lab" coolness; distinct from goal-green. |
| Electricity & Magnetism | Slate blue `#26303F` | Dark for sparks/glow to read. |
| Fluids & Pressure | Ocean blue `#1E4A66` | Water association. |
| Gravity / Space | Near-black violet `#15122A` | Void/space. |
| Thermodynamics | Ember warm-grey `#523321` | Heat. |
| Sound & Waves | Plum `#3A2440` | Distinct, "vibey." |
| Sports | Clay `#A8512C` or court-green `#3F6E3A` | Per sport. |
| Logic / Pattern | Neutral slate `#363640` | Calm, abstract. |

> Roles stay constant across palettes (ink/danger/goal/interact/hint); only values shift to keep
> contrast. Entering a room = a visible color shift = a soft signal of "this kind of puzzle."
> The first row doubles as the castle palette used by all hubs and corridors.

---

## 📈 Difficulty & cross-discipline combination
The ramp is **breadth → depth → fusion**:
1. **Early (single discipline, taught):** one mechanic, gently. E.g., one mirror; one lever.
2. **Mid (intra-discipline depth):** more pieces of the same idea. E.g., 3 mirrors + a beam splitter;
   a lever *on a moving platform*.
3. **Late (cross-discipline fusion):** combine 2–3 disciplines so the output of one is the input of the
   next. Examples to aim for:
   - **Thermo → Chemistry → Fluids:** heat a beaker to react two reagents, producing a gas that inflates
     a float, which rises to lift a mirror into a beam (→ Optics) that finally opens the door.
   - **Mechanics → Optics:** reposition a fulcrum to *aim* a mirror mounted on the lever arm.
   - **Electricity → Magnetism → Gravity:** complete a circuit to power an electromagnet that drops a
     steel ball onto a launch ramp at the right moment.
   - **Sports → Optics:** bank a billiards shot (angles) so the ball's path *is* the "beam" hitting targets.
4. **Capstone rooms** near the exit deliberately braid three disciplines into one chain.

---

## Status / how we use this
- Treat this as a **backlog**, not a spec. When a room is built, its concrete design lives in its
  level JSON + puzzle script ([LEVEL_FORMAT.md](LEVEL_FORMAT.md)); link back here by concept name.
- Flagship/MVP picks (per [ROADMAP.md](ROADMAP.md) M4): start with **Mechanics** (fulcrum lever,
  pressure plates, box stacking) since they need the least new tech, then add **Optics (mirror
  routing)** as the first "wow" discipline.
- New disciplines introduce new entity types + components — add them to LEVEL_FORMAT §4 as built.
