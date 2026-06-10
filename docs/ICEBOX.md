# Icebox — parked ideas

> Ideas worth keeping that are **not** on the roadmap. One entry each, enough detail to pick up
> cold. Nothing here is a commitment; promoting an entry means giving it a design pass and a
> milestone. (Keeping them here protects M0–M4 from scope creep — ROADMAP §Sequencing.)

## Level editor (player UGC + our own authoring tool)
- An in-game **level-editor UI**: players build their own levels from the shipped object/entity
  catalogue (LEVEL_FORMAT §4).
- **Dual-purpose:** the same editor is *our* dev tool for authoring/editing the levels we ship —
  one tool, two audiences.
- Players may use **unlocked levels as templates** or start from scratch.
- **Playthrough gate:** the editor must include a play-test mode proving the level is *achievable
  with the given tools* before it can be saved/shared (author-must-beat-it). All design rules
  still apply inside the editor: no-death, telegraphed hazards, the no-text rule.
- Why it's feasible later: levels are already declarative JSON — the editor is a UI over the
  existing schema. Biggest open questions: puzzle logic for custom levels (custom rooms can't
  have bespoke Dart scripts → needs a library of parameterizable stock behaviors), sharing
  mechanism, and kid-safe UGC moderation if sharing is ever online.

## Other parked ideas (from the replayability review)
- **Castle map / completion view** — post-game map showing solved vs unexplored rooms.
- **Second solutions** — hidden bonus objective in select rooms (bullseye-with-star glyph).
- **Remix mode** — parameterized room variants (`seed` prop re-rolls mirror angles, ratios, weights).
- **NG+ twist** — the "exit" is another teleporter; second lap re-presents rooms in fusion form.
