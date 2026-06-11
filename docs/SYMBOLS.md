# Symbol Legend

> The source-of-truth catalogue for every glyph in the game. Referenced by `lib/game/ui/symbols.dart`
> and surfaced in-game by `symbol_legend.dart`. Enforces the **no-text rule**
> ([STYLE_GUIDE.md §8b](STYLE_GUIDE.md)). Visual preview is rendered alongside this doc in chat.
>
> **The in-game legend is a collection (sticker book):** entries are *earned*, not pre-filled.
> A discipline glyph (§5) stamps in on the first solve in that discipline; an invented (`INV`)
> glyph stamps in when first taught; completing all of a discipline's rooms completes its row.
> Found **lore etchings** appear in a gallery on the same screen. Per-profile; see GDD §9.

## Rules (recap)
- **No words or numerals in the play space, in any language, ever.** Every glyph here replaces
  text. The application shell (splash/title/settings/credits) is text-permitted but symbol-first —
  boundary in [STYLE_GUIDE.md §8b](STYLE_GUIDE.md).
- **Prefer a recognized standard** (ISO 7010 safety, biohazard/radiation trefoils, IEC 60417 /
  ISO 7000 equipment symbols, universal media icons) — redrawn in our line style.
- **Invent only when no standard exists**, register it here, and **teach it on first use** by
  demonstration (never a text tooltip).
- Draw every glyph in `ink` (near-black) line on the active palette, base stroke weight, rounded
  joins/caps (spikes/hazard points excepted). Fill flat with a token only when meaning needs it.
- **Every collectible glyph is intentional:** it must contribute to at least one reward — its
  discipline's tool row, an artifact combo, or both ([GDD §9b](GDD.md)). No filler stamps.

**Source column key:** `STD` = recognized standard · `STD*` = standard, lightly stylized ·
`INV` = invented for this game (must be taught).

---

## 1. System / HUD
| id | Meaning | Glyph | Source | Teach-on-first-use |
|---|---|---|---|---|
| `pause` | Pause | two vertical bars | STD | n/a (universal) |
| `resume` | Resume / play | right-pointing triangle | STD | n/a |
| `restart` | Restart room | the **claw** (jaws + cable) | INV | shown when the claw first rescues you |
| `settings` | Settings | gear | STD | n/a |
| `sound_on` | Audio on | speaker + waves | STD | n/a |
| `sound_off` | Audio off | speaker + slash | STD | n/a |
| `hint` | Hint / idea (opt-in) | lightbulb | STD* | pressing it pulses a **halo glow** on the puzzle's current target (STYLE_GUIDE §8d) |
| `back` | Back / leave menu | U-turn arrow | STD | n/a |
| `collection` | Collection / legend book (the achievements screen) | open book + stamp | INV | first earned stamp flies into it |
| `inventory` | Inventory / Field Kit | satchel (toolbox once tools exist) | STD* | first carried object |
| `credits` | Attributions / credits (settings → the one text screen) | heart | STD* | n/a |
| `profile` | Profile / save slot | framed pictogram avatar | INV | avatar-select screen itself |

## 2. Navigation & world state
| id | Meaning | Glyph | Source | Teach |
|---|---|---|---|---|
| `exit` | The way out / level exit | running figure through a door | STD (fire-exit) | n/a (universal) |
| `door_back` | Door back to the hub | door + small return arrow | INV | first time you back out of a room |
| `locked` | Locked | closed padlock | STD | with the first locked door |
| `unlocked` | Unlocked / solved | open padlock | STD | flips from `locked` on solve |
| `goal` | Goal / objective point | bullseye target | STD | first puzzle's target glows |
| `spawn` | Teleport-in / start point | swirl-in-circle | INV | the opening teleport-in moment |
| `solved_tick` | Room solved marker (hub) | open padlock / filled ring | INV | when first room is solved |

## 3. Player verbs (controls)
| id | Meaning | Glyph | Source | Teach |
|---|---|---|---|---|
| `move` | Move left/right | d-pad / opposed arrows | STD | tutorial corridor |
| `jump` | Jump | up arrow over a baseline | STD* | first gap |
| `interact` | Use / actuate | arrow pressing a button cap (elevator "press" pictogram). *Rejected: open palm (= stop), drawn finger (illegible small)* | STD* | contextual bubble above any in-range interactable (GDD §10); same glyph labels the touch/controller button |
| `carry` | Pick up / carry | hand holding a box | INV | first carryable object |

## 4. Hazards (telegraphs — `accentDanger`)
| id | Meaning | Glyph | Source | Teach |
|---|---|---|---|---|
| `hazard` | General danger ahead | triangle + `!` | STD (ISO 7010 W001) | before the first hazard |
| `no_swimming` | Water pool ahead | prohibition ring over swimmer + signage waves | STD (ISO P049) | posted at the first pool |
| `spike` | Spikes (unused — water replaced spikes for kid-friendliness) | row of triangles | STD* | — |
| `boulder` | Falling/rolling boulder | circle + down chevrons | INV | wind-up before first boulder |
| `crusher` | Crusher / press | two converging blocks + arrows | INV | before the first crusher |
| `no_entry` | Blocked / not this way | circle with diagonal slash | STD (prohibition) | on a sealed door |

## 5. Discipline markers
Shown on a hub's room doors to hint each room's puzzle type (hubs mix disciplines — GDD §4 variety
rule). Color = the discipline's palette. Earned as legend stamps on first solve in that discipline.
| id | Discipline | Glyph | Source |
|---|---|---|---|
| `d_optics` | Optics & light | sun + a single ray | STD* |
| `d_mechanics` | Mechanics & forces | gear (or lever + fulcrum triangle) | STD* |
| `d_chemistry` | Chemistry | Erlenmeyer flask | STD* |
| `d_gravity` | Gravity & projectiles | apple/ball with down arrows | INV |
| `d_fluids` | Fluids & pressure | water droplet | STD* |
| `d_electric` | Electricity | lightning bolt | STD (IEC) |
| `d_magnet` | Magnetism | horseshoe magnet + field arcs | STD* |
| `d_thermo` | Thermodynamics | half-flame / half-snowflake | INV |
| `d_sound` | Sound & waves | tuning fork + arcs | STD* |
| `d_sports` | Sports | a ball | STD* |

## 5b. Tools, sockets & artifacts *(DRAFT — pending the GDD §9b design pass)*
The Field Kit ([GDD §9b](GDD.md)): discipline rows award tools; cross-discipline symbol combos
unlock artifacts. **Do not build or finalize these glyphs until the design pass closes** (ROADMAP
§M5.5) — rows below are placeholders to reserve the ids and the teaching obligations.
| id | Meaning | Glyph (sketch) | Source | Teach |
|---|---|---|---|---|
| `anchor_socket` | A tool attaches here | ring/eyelet bolted to wall, dashed outline until usable | INV | first socket seen with a matching tool owned |
| `bonus_door` | Bonus content (tool/artifact gated, never the main path) | door + star | INV | first encountered; the star never appears on required paths |
| `tool_pulley` | Portable pulley (Mechanics row) | pulley wheel + hook | STD* | awarded with the Mechanics row stamp |
| `tool_mirror` | Pocket mirror (Optics row) | hand mirror | STD* | awarded with the Optics row |
| `tool_*` | One per remaining tool | *(design pass)* | — | — |
| `artifact_*` | Cross-discipline artifacts (e.g. periscope, steam key) | *(design pass)* | INV | combo-completion moment on the legend screen |

## 6. Quantity & state representations *(never numerals)*
The grammar for showing amounts, forces, angles, counts, time — all visual.
| id | Represents | How it reads |
|---|---|---|
| `q_fill` | Amount / volume / ratio | a beaker or bar **filled to a level**; ratios = two fills compared |
| `q_balance` | Force / torque / weight | a **beam that tilts**; level = balanced |
| `q_pips` | Discrete count / order | a **row of dots** (dice-like); filled vs empty |
| `q_dial` | Angle / direction | a **needle/protractor arc** pointing |
| `q_charge` | Time / energy / progress | a **ring or bar that fills or drains** |
| `q_match` | Target vs current | two shapes/waves shown together; **align them** |

## 6b. Feedback popups *(event glyphs — pop over the widget concerned)*
Automatic, wordless cause-and-effect feedback (visual rules in [STYLE_GUIDE.md §8d](STYLE_GUIDE.md)):
quick scale-in, hold ~1 s, fade; one at a time per widget; events, not persistent states.
| id | Meaning | Glyph | Color | Source |
|---|---|---|---|---|
| `fb_error` | That didn't work / refused | bold `!` with a tiny shake | `accentDanger` | STD* (from ISO warning `!`) |
| `fb_idea` | Notice this / idea | lightbulb | `accentHint` | STD* |
| `fb_success` | Step succeeded / solved | open padlock / tick pop | `accentGoal` | STD |
| `hint_halo` | Hint target highlight | pulsing halo ring around the object | `accentHint` | INV — the one sanctioned glow; taught by the first lightbulb press |

---

## 7. Construction notes
- One consistent stroke weight per importance tier; glyphs sit on an invisible ~1×1 tile grid so they
  align in the HUD.
- Keep each glyph readable at small size (mobile HUD) — test at ~24 px.
- A glyph may take a token fill to carry meaning (e.g. `goal` glows `accentGoal` when active,
  `hazard` is `accentDanger`); otherwise it's plain `ink`.
- Animated states are posture/feature tweens (padlock shackle pops open; sensor target brightens).

## 8. Adding a new symbol
1. Check for a recognized standard first; if found, mark `STD`/`STD*` and redraw in our style.
2. If inventing (`INV`): add a row here, implement it in `symbols.dart`, register it in
   `symbol_legend.dart`, and design its **first-use teaching moment** (a demonstration in context,
   no text).
3. Never ship an `INV` glyph that isn't in this table — that's how inconsistency creeps in
   ([STYLE_GUIDE.md §10 Don'ts](STYLE_GUIDE.md)).
