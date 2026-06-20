import 'dart:ui';

/// Color tokens — the single source of color in the game (STYLE_GUIDE.md §3).
///
/// Components reference tokens, never raw hex. Adding a discipline palette
/// (PUZZLES.md §Theme↔color) = one more [Palette] const with the same roles.
class Palette {
  const Palette({
    required this.bg,
    required this.ink,
    required this.surface,
    required this.accentDanger,
    required this.accentGoal,
    required this.accentInteract,
    required this.accentNeutral,
    required this.beam,
    required this.accentHint,
    required this.water,
  });

  /// Room/corridor background.
  final Color bg;

  /// All outlines & the player figure.
  final Color ink;

  /// Walls / solid floor fill — a touch darker than [bg].
  final Color surface;

  /// Hazards & warnings. Never decorative.
  final Color accentDanger;

  /// Exit doors, goal markers. "Go / safe."
  final Color accentGoal;

  /// Levers, plates, keys, pushables. "You can act on this."
  final Color accentInteract;

  /// Inactive/secondary fills, panels.
  final Color accentNeutral;

  /// Light beams (optics).
  final Color beam;

  /// Hints & feedback (lightbulb, hint halo, fb_idea popups).
  final Color accentHint;

  /// Water pools (the kid-friendly hazard): reads as WATER — the hazard
  /// semantics are carried by the no-swimming sign, not by danger-red.
  final Color water;
}

/// Palette registry. Rooms declare `"palette": "<id>"` (LEVEL_FORMAT.md §3);
/// hubs/corridors use the castle palette (`amber`).
abstract final class Palettes {
  /// "Dungeon Amber" — the castle/default palette (bg tuned on-screen in M0).
  static const Palette amber = Palette(
    bg: Color(0xFFE6E619),
    ink: Color(0xFF101010),
    surface: Color(0xFFD2D215),
    accentDanger: Color(0xFFB5341F),
    accentGoal: Color(0xFF1F6F4E),
    accentInteract: Color(0xFF1E4E8C),
    accentNeutral: Color(0xFFE6D38A),
    beam: Color(0xFFF2E27A),
    accentHint: Color(0xFFF2C94C),
    water: Color(0xFF2F6DA4),
  );

  /// Optics discipline palette — deep indigo so beams pop
  /// (PUZZLES.md §Theme↔color). Values are first-pass; tuned in M7.5.
  static const Palette optics = Palette(
    bg: Color(0xFF241F4A),
    ink: Color(0xFF101010),
    surface: Color(0xFF332D63),
    accentDanger: Color(0xFFC4452E),
    accentGoal: Color(0xFF2E9468),
    accentInteract: Color(0xFF5B7FD4),
    accentNeutral: Color(0xFF8B84C2),
    beam: Color(0xFFF2E27A),
    accentHint: Color(0xFFF2C94C),
    water: Color(0xFF3D77B5),
  );

  /// The meadow — the start/hub/ending overworld (GDD §3 twist). A **dark
  /// night forest**: a deep-blue sky so the teleporter glows read as the only
  /// light, the figure and tree in ink. Deliberately the opposite of the lit
  /// dungeon so "you got out" lands. Values first-pass; tuned in M7.5.
  static const Palette meadow = Palette(
    bg: Color(0xFF12182B), // night sky
    ink: Color(0xFFE8E8EC), // light ink — outlines read on the dark bg
    surface: Color(0xFF1C2A22), // dark grass/earth
    accentDanger: Color(0xFFC4452E),
    accentGoal: Color(0xFF55C98A), // teleporter "lit" glow
    accentInteract: Color(0xFF5B7FD4),
    accentNeutral: Color(0xFF3A4358), // dormant teleporter / dim
    beam: Color(0xFFF2E27A),
    accentHint: Color(0xFFF2C94C),
    water: Color(0xFF2F6DA4),
  );

  static const Map<String, Palette> byId = {
    'amber': amber,
    'optics': optics,
    'meadow': meadow,
  };
}
