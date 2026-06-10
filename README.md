# *(working title)* The Sign

A minimalist 2D **puzzle-platformer** rendered like public-safety signage. You're a pictogram
figure teleported into a castle/dungeon and must escape — crossing hazard-filled corridors to
**cul-de-sac hubs**, where you choose which puzzle room to try next. **No death, no punishment:** a
gentle thinking game built so an 8-year-old can play and enjoy it.

- **Stack:** Flutter + Flame (one codebase → web, Windows, later Android & iOS).
- **Look:** hard black ink lines, flat fills, no texture — like a wet-floor or no-swimming sign.
  Current background: darkish amber (themeable).
- **Feel:** forgiving, puzzle-first movement. Think deliberately, not twitch-perfectly.
- **Kind by design:** failure only ever means "reset to the start of this bit," performed by a
  friendly **excavator claw** that scoops you up and whirlwind-resets the room. Stuck? Back out and
  pick another room — you're never hard-blocked.
- **No words in play:** everything in the game itself is symbols (standard signage where it exists,
  invented where it doesn't) — language-free by design. The **application shell** (title screen
  with the wordmark, settings, credits) is text-permitted but symbol-first.
- **Puzzles teach real ideas:** optics, levers, chemistry ratios, gravity, fluids… plus sports
  (return the tennis machine's serve into the target). Later rooms braid disciplines together, and
  each hub's rooms span **different disciplines** so backing out always offers a different kind of
  thinking.
- **Wordless help & feedback:** an opt-in lightbulb hint pulses a halo on the puzzle's target;
  popup glyphs (red `!` on the thing that didn't work, green pop on success) give instant
  cause-and-effect feedback. The in-game **symbol legend is an earnable collection** (stamps +
  found lore etchings) — the wordless sticker book.
- **The collection pays out *(design-gated draft)*:** completing a discipline's row awards its
  **tool** (e.g. a portable pulley that clips into marked wall sockets); **cross-discipline symbol
  combos** unlock artifacts that open bonus paths — a reward lattice, not a line. Spec'd in GDD
  §9b; gets a dedicated design pass (M5.5) before any of it is built.

## Documentation (source of truth)
Read in this order:
1. **[docs/GDD.md](docs/GDD.md)** — game design: story, loop, hazards, scope.
2. **[docs/PUZZLES.md](docs/PUZZLES.md)** — the living puzzle backlog: science & sports disciplines,
   theme→color map, difficulty/fusion ramp.
3. **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — stack, project layout, core systems, decisions.
4. **[docs/STYLE_GUIDE.md](docs/STYLE_GUIDE.md)** — signage visual language, color tokens, the
   no-text iconography rule, and the excavator-claw reset.
5. **[docs/SYMBOLS.md](docs/SYMBOLS.md)** — the Symbol Legend: every glyph, its meaning & source.
6. **[docs/LEVEL_FORMAT.md](docs/LEVEL_FORMAT.md)** — JSON level data + puzzle-script hooks spec.
7. **[docs/ROADMAP.md](docs/ROADMAP.md)** — milestones; build top-to-bottom.
8. **[docs/examples/room-optics-mirror.md](docs/examples/room-optics-mirror.md)** — a full worked
   room (level JSON + puzzle script + beam system).

## Locked decisions
| Decision | Choice |
|---|---|
| Engine | Flutter + Flame |
| Movement | Minimal & simple (forgiving run + jump) |
| Failure | **No death** — an excavator claw scoops you to the start & whirlwind-resets; never hard-blocked |
| UI | **Play space: symbols only, no text** in any language (standards where they exist, else invented). Application shell (title/settings/credits): text-permitted, symbol-first |
| Puzzles | Real-world disciplines (optics, mechanics, chemistry, gravity…) + sports; later rooms fuse them |
| World shape | Corridors → cul-de-sac hubs → pick a room; solve any one to go onward; hub rooms span different disciplines |
| Accessibility | Color never the sole carrier of meaning (colorblind-safe patterns/shapes) |
| Saves | 2–3 profile slots picked by pictogram avatar; offline |
| Level authoring | JSON data + per-room Dart logic hooks |
| Hazards | Hybrid — scripted by default, Forge2D only where needed; non-lethal |
| Default palette | "Dungeon Amber" (darkish yellow bg, black ink) |
| Audience | Built to be playable & enjoyable for an 8-year-old |

## Status
Planning complete. No game code yet — next step is **M0 (Flame spike)** per the roadmap.
