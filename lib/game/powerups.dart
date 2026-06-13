import 'ui/symbols.dart';

/// Permanent Metroidvania abilities (docs/POWERUPS.md). Found once in hidden
/// rooms, kept forever, shown on the figure, persisted per profile. Each
/// changes what an existing verb does — never adds a button.
enum Powerup {
  /// Swim instead of being reset by water (resolves the float icebox idea).
  flippers,

  /// One extra mid-air jump.
  springBoots,

  /// Pull across a wide gap at a marked anchor socket (later phase).
  grapple,

  /// Light a dark room (later phase).
  lantern;

  /// Stable string for save data.
  String get id => name;

  static Powerup? byId(String id) {
    for (final p in Powerup.values) {
      if (p.name == id) return p;
    }
    return null;
  }

  SymbolId get glyph => switch (this) {
        Powerup.flippers => SymbolId.powerFlippers,
        Powerup.springBoots => SymbolId.powerSpring,
        Powerup.grapple => SymbolId.powerGrapple,
        Powerup.lantern => SymbolId.powerLantern,
      };
}
