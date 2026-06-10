# Visual Style Guide — Signage Aesthetic

> Source of truth for the look & feel. Referenced by `lib/game/palette.dart` and every
> component's `render()`. Design lives in [GDD.md](GDD.md); engineering in [ARCHITECTURE.md](ARCHITECTURE.md).

## 1. The idea in one sentence
Render the entire game like international public-safety **signage** — a wet-floor sign, a
no-swimming sign, a fire-exit pictogram: hard black ink outlines, flat solid fills, no gradients,
no texture, no shadows, instantly legible silhouettes.

## 2. Rules (non-negotiable for visual coherence)
1. **Ink is black, lines are hard.** Every object, wall, floor, and the character has a solid black
   outline of a consistent weight. No anti-aliased "soft" edges as a style choice (rendering AA is
   fine; the *design* reads as crisp).
2. **Fills are flat.** One solid color per shape. No gradients, no lighting, no bevels.
3. **No texture, no noise, no detail-for-detail's-sake.** If a detail doesn't help you read the
   object's function, cut it. Signage communicates with the minimum marks.
4. **Silhouette first.** An object must be identifiable from its outline alone. Interactive things
   read as interactive (a lever looks pullable, a plate looks steppable).
5. **High contrast, limited palette.** Background + ink + a small set of accent colors. Accents
   carry *meaning* (danger, goal, interactive), not decoration.
6. **Geometric construction.** Shapes are built from circles, rounded rectangles, straight runs, and
   simple arcs — the vocabulary of pictograms.
7. **No text in the play space. In any language.** This is a hard rule — everything communicable
   while playing is a symbol or a visual; words and numerals never appear in play. The
   **application shell** (splash, title, settings, credits) is text-permitted but symbol-first —
   the precise boundary is defined in §8b.
8. **Color is never the *only* carrier of meaning** (colorblind-safe rule). Every color-coded element
   pairs its color with a redundant **shape, pattern, or position** cue — exactly like real signage.
   Concretely: light beams of different colors get distinct **line patterns** (solid / dashed /
   dotted) and their sensors show the matching pattern; chemistry reagents get distinct container
   silhouettes or fill patterns; acid/base bars carry a centered tick mark, not just a color shift.
   ~1 in 12 boys is red-green colorblind — for a kids' game this is a hard rule, not a nice-to-have.

## 3. Color tokens
Colors live **only** in `lib/game/palette.dart` as named tokens. Components reference tokens, never
raw hex. This is what makes "different background colors later / multiple palettes" trivial.

### 3.1 Current palette — "Dungeon Amber" (the default)
| Token | Role | Value | Notes |
|---|---|---|---|
| `bg` | Room/corridor background | `#C9A227` (darkish yellow / amber) | The current chosen background. Swappable per theme. |
| `ink` | All outlines & the figure | `#101010` (near-black) | The universal stroke color. |
| `surface` | Walls / solid floor fill | `#B8941F` (a touch darker than bg) | Reads as "solid" against bg without breaking palette. |
| `accentDanger` | Hazards (spikes, boulders, warning) | `#B5341F` (sign red) | "Avoid" — touching resets you (no death). Never decorative. |
| `accentGoal` | Exit door, goal markers | `#1F6F4E` (sign green) | "Go / safe / exit" semantics. |
| `accentInteract` | Levers, plates, keys, pushables | `#1E4E8C` (sign blue) | Signals "you can act on this." |
| `accentNeutral` | Inactive/secondary fills | `#E6D38A` (pale amber) | Light fill for highlights/panels. |
| `beam` | Light beams (optics) | `#F2E27A` (bright pale yellow) | Flat bright line, no glow; spark mark at reflections. Used by optics puzzles. |
| `accentHint` | Hints & feedback (lightbulb, hint halo, `fb_idea` popup) | `#F2C94C` (warm yellow) | Assistance/feedback moments only — never decorative. Tune per palette for contrast (must pop on every bg). |

> These hex values are the *starting point* to encode in `palette.dart`; tune on-screen.
> The **roles** (semantics) are the contract — future palettes must keep the same roles.

### 3.2 Theming model (later palettes) — coordinated with puzzle discipline
A `Palette` is a struct of the tokens above. The game holds an active `Palette`; rooms may
declare `"palette": "amber"` (or another id). Adding a new theme = define a new token set with the
**same role names**. Never introduce a new semantic color without adding it to every palette.

**Background color is coordinated with the room's puzzle discipline** — optics rooms go deep
indigo so beams pop, chemistry goes muted teal, fluids go ocean blue, etc. Hubs and corridors keep
the castle palette (Dungeon Amber), so since a hub's rooms span different disciplines (GDD §4),
*entering a room* is the bg shift — a soft cue that the *kind of thinking* changed. The full
discipline→palette map lives in [PUZZLES.md §Theme ↔ color](PUZZLES.md). Roles stay constant across
palettes; only values shift to preserve contrast.

## 4. Line weight & geometry
- **Base stroke weight:** `3` logical px (at tile = 32 px). Scales with the camera, so it stays a
  consistent visual weight on every device.
- **Heavy outline (room boundary / important objects):** `4–5` logical px.
- **Corners:** prefer slightly rounded joins (`StrokeJoin.round`) — pictograms are friendly, not
  sharp. Spikes are the deliberate exception (hard points = danger semantics).
- **Caps:** `StrokeCap.round` for limbs/poles; `butt` for structural lines.
- Draw order per object: **fill first, stroke on top**, so the ink edge is always crisp.

## 5. The player character — the pictogram figure
Constructed like a restroom/exit-sign person, but our protagonist:
- **Head:** a solid `ink` circle.
- **Body/limbs:** thick rounded `ink` strokes (or filled capsules) — readable as a person at a glance.
- **No face, no clothing detail.** Identity comes from posture, not features.
- **Animation = posture interpolation.** Because the figure is a few paths/points, animate by
  tweening point positions: idle (neutral), run (leg/arm swing, 2–4 key poses), jump (tucked),
  land (compress), carry (arms forward). No sprite sheets — pose data in code.
- **Carry state:** when holding an object, arms extend forward and the carried object renders as its
  own pictogram in front of the figure.
- Optional single accent: the figure may use pure `ink` only (truest to signage) — keep it ink for
  MVP; reserve color for interactables and hazards so the player reads the *world's* color cues.

## 6. Object construction vocabulary
| Object | Construction | Fill token | Read |
|---|---|---|---|
| Floor / wall | rounded-rect blocks, heavy outline | `surface` | solid, immovable |
| Door / exit | rounded portal arch + frame | `accentGoal` | "way out" |
| Locked door | same + a keyhole pictogram | `surface` + `ink` keyhole | "needs a key" |
| Lever | post + handle (clear up/down states) | `accentInteract` | "pull me" |
| Pressure plate | flat tab on the floor, depresses | `accentInteract` | "step / weigh down" |
| Pushable block | rounded square with grip marks | `accentInteract` | "push me" |
| Key | classic key pictogram | `accentInteract` | "carry to lock" |
| Spike pit | row of hard triangles | `accentDanger` | "avoid — sends you back to the start" |
| Boulder | solid circle, heavy outline | `accentDanger` | "dodge it — it'll bump you back" |
| Moving platform | rounded bar, maybe motion arrows | `surface` + `ink` arrows | "rides a path" |
| Warning sign | triangle/!, on the wall before a hazard | `accentDanger` | telegraph (Pillar 2) |

## 7. Backgrounds & space
- Background is a **flat field** of `bg` — no parallax, no scenery clutter for MVP.
- Depth/place is implied by sparse signage motifs on walls (etchings in `ink`), used rarely.
- Corridors may use a subtly different framing (narrower viewport feel) but the **same palette**.
- Keep negative space generous — legibility over density. The emptiness is the aesthetic.

## 8. UI / HUD
- HUD is part of the sign language: thin `ink` lines, flat token fills, **pictogram icons only**
  (pause = two bars, resume = triangle). No skeuomorphism, no rounded-glass buttons.
- Touch controls: a left d-pad and right action buttons drawn as flat pictogram controls with `ink`
  outline and a translucent `accentNeutral` fill so they don't fight the world.

## 8b. Iconography & the no-text rule *(core constraint — and its precise boundary)*
The no-text rule applies to **the game, not the whole shipped application**. Two layers:

**The play space — hard rule, no exceptions.** The game world, HUD, pause overlay, puzzle UI,
prompts, tutorials, the inventory/Field Kit screen, and the collection/legend screen: **no text, no
letters, no words, no numerals — in any language.** Everything is communicated by symbol and
visual; quantities are always visual (see below). This is the deliberate artistic choice that keeps
play in the signage aesthetic and language-free for any player, including a young child.

**The application shell — text-permitted, symbol-first.** Splash, title, profile select, settings,
credits/attributions, store listings, the window/app title. Rules of taste:
- The game's **name appears as a wordmark** on splash/title — a drawn logo that happens to be
  letters (and since the game is *The Sign*, the wordmark is itself drawn **as a sign**: ink on a
  signage panel). The wordmark is an asset, not rendered text.
- **Symbols first**: if a glyph communicates it (play ▶, gear, speaker), don't add a word. Settings
  should remain fully navigable by a non-reader.
- Text where it's necessary or honest: the **credits screen** (artist names, license labels,
  clickable links — see ARCHITECTURE §5.10), legal/version small print, store metadata.
- Shell typography is plain ink-on-bg, consistent with signage — think the small print at the
  bottom of a real safety sign. No decorative fonts.

**Source hierarchy for any symbol we need:**
1. **Use an internationally recognized standard if one exists** — and redraw it in our line style:
   - ISO 7010 safety signs (warning triangle with `!`, "no" prohibition circle-slash, mandatory blue circles).
   - The **biohazard** trefoil (ISO 21482), **radiation** trefoil, **high-voltage** arrow, recycling loop.
   - IEC 60417 / ISO 7000 equipment symbols (power, sound on/off, etc.).
   - Universal pictograms: play ▶, pause ⏸, directional arrows, target/bullseye, gear, lightbulb (idea/hint).
2. **If no standard exists, invent one** — and register it in the project **Symbol Legend**
   ([SYMBOLS.md](SYMBOLS.md), mirrored by an in-game visual screen) so the same idea always uses the
   same glyph. Teach each invented symbol the first time it appears, in context, by demonstration.

> 📖 The full glyph catalogue (system, navigation, verbs, hazards, discipline markers, and the
> quantity-without-numerals grammar) lives in **[SYMBOLS.md](SYMBOLS.md)**.

**Standardized glyphs that aren't "language" are allowed:** the `!` inside an ISO warning triangle,
the `?`-as-idea is *avoided* in favor of a lightbulb, mathematical/physical marks only where they're
truly universal. When in doubt, prefer a *picture of the thing* over an abstract mark.

**Quantities without numerals** (critical for the science puzzles):
- Amounts/ratios → **beaker fill levels, proportional bars, or pip dots** (like dice faces).
- Forces/torque/balance → the **physical tilt** of a beam or a needle on a dial.
- Angles → a **protractor arc / rotating pointer**, never degrees.
- Counts/sequence → **rows of dots or repeated icons**, never digits.
- Time/charge → a **filling/draining bar or shrinking ring**.

**Common HUD/menu glyphs (draw all in `ink` line style):**
| Meaning | Glyph |
|---|---|
| Pause / resume | two bars / triangle |
| Restart room | the **excavator-claw icon** (see §8c) or a circular-arrow ↻ |
| Settings | gear |
| Sound on / off | speaker / speaker-with-slash |
| Hint / idea | lightbulb |
| Goal / target | bullseye |
| Hazard | ISO warning triangle (with the standard `!`) |
| Locked / unlocked | closed / open padlock |
| Carry / pick up | hand or grabber |
| Exit | running-figure-through-door (the universal fire-exit pictogram) |

## 8c. The excavator-claw reset *(signature animation, replaces any "death")*
There is no death animation. When the player is reset (hazard contact, room restart, or puzzle
reset), a friendly **excavator/grabber claw** handles it — making the no-death promise *diegetic*:
the room itself scoops you up and tidies up. Tone: **cute, mechanical, gentle — "kitten by the
scruff," never violent.** Drawn entirely in our line style (segmented arm + cable + claw jaws).

**Animation beats:**
1. **Descend** — the claw drops from the ceiling on a cable/segmented arm, jaws open. A small wind-up.
2. **Scoop** — jaws close gently around the player, who goes into a limp, dangling "carried" pose
   (kitten-by-the-scruff). No impact, no distress — playful.
3. **Carry** — the claw retracts and travels along the ceiling to the room/corridor **start point**.
4. **Place** — it sets the player down at the start and releases; player drops into the idle pose.
5. **Whirlwind reset** — the claw then spins into a quick **whirlwind/tornado sweep** across the room;
   as it passes, all **moving hazards and platforms** snap back to their authored start state.
   **Puzzle progress is preserved** (a pulled lever stays pulled) unless the room's script opts to
   clear it via `onReset()` — matching [GDD.md §8](GDD.md) and ARCHITECTURE §5.6. The reset is
   *shown*, not silent — the whirlwind is the visual metaphor for "room reset."
6. **Retract** — the claw zips back into the ceiling; player control returns.

**Feel & rules:**
- Keep it **brief (~1–1.5 s)** so it never annoys on repeats; **abbreviate/speed up on rapid repeats**.
- **Player input is locked** during the animation; it ends with the player grounded at `start`.
- The actual state reset (re-init kinematic bodies, `PuzzleScript.onReset()`) happens on the
  **whirlwind beat** so visuals and logic line up (see [ARCHITECTURE.md §5.6](ARCHITECTURE.md)).
- The claw is the same motif used for the **Restart room** button glyph (§8b) — one consistent idea.

## 8d. Hints & feedback popups *(wordless assistance)*
With no text, "what should I do?" and "did that work?" get their own visual systems
(design intent in [GDD.md §8b](GDD.md); glyph registry in [SYMBOLS.md §6b](SYMBOLS.md)).

**The hint halo (opt-in):**
- Pressing the HUD **lightbulb** makes the puzzle's **current target pulse with a halo glow** — a
  soft pulsing ring in `accentHint` around the goal sensor or the next actionable object (the
  active puzzle script nominates it via `hintTargetId`).
- The halo is the **single sanctioned "glow" in the game** (deliberate exception to §10) — its
  rarity is what makes it read as "look here."
- Pulse is gentle (~1 Hz scale/opacity), sits *behind* the object's ink outline, and fades after a
  few seconds. **v1: target only.** Designed to extend later to haloing other artifacts in the
  causal chain (subsequent presses walk the chain: source → mirror → sensor).

**Feedback popups (automatic):**
Small glyphs that pop briefly **over the widget concerned** — instant, wordless cause-and-effect:
| Event | Glyph | Color | Example |
|---|---|---|---|
| That didn't work / refused | bold `!` with a tiny shake | `accentDanger` | wrong key in a lock; pushing an immovable block |
| Notice this / idea | lightbulb | `accentHint` | a mechanism armed elsewhere; first-use nudge |
| Step succeeded | open padlock / tick pop | `accentGoal` | plate engaged, sensor satisfied, room solved |

Rules: pop with a quick scale-in, hold ~1 s, fade out; one popup at a time per widget; drawn in the
standard line style at HUD glyph size. These are **events, not states** — persistent state stays on
the widget itself (a lit sensor, a depressed plate). Puzzle scripts emit the events
(ARCHITECTURE §5.7); the same event stream drives the audio pass later.

## 9. Motion & feel (visual)
- Movement reads as light and forgiving (matches the "minimal & simple" design): small squash on
  land, a slight lean when running. Nothing flashy.
- Hazards are **always telegraphed visually** before they can reset you (warning sign, wind-up
  frame, or visible track) — this is a style rule *and* a fairness/kindness rule. Nothing kills;
  the worst outcome is a friendly "back to the start."

## 10. Don'ts
- ❌ **Any text, letters, words, or numerals — in any language — anywhere in the play space.**
  *(The application shell — splash, title, settings, credits — is text-permitted but symbol-first;
  boundary in §8b.)*
- ❌ A "death" animation. Resets are always the friendly claw. (§8c)
- ❌ Gradients, drop shadows, glows, bevels, textures, photographic anything.
  *(One sanctioned exception: the pulsing **hint halo**, §8d — kept rare so it reads as "look here.")*
- ❌ Color as the sole carrier of meaning — always pair with shape/pattern (§2 rule 8).
- ❌ Hard-coded colors in components (always tokens).
- ❌ New accent colors without a defined semantic role across all palettes.
- ❌ An invented symbol that isn't registered in the Symbol Legend (causes inconsistency).
- ❌ Detail that doesn't aid recognition.
- ❌ Inconsistent line weights between objects of the same importance tier.
