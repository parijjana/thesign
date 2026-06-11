/// Logical units, viewport, and tuning knobs (ARCHITECTURE.md §3).
///
/// 1 logical unit = 1 tile = 32 design px; level JSON is authored in tiles.
/// The camera letterboxes a fixed logical viewport so the game renders
/// identically on every device and window size.
abstract final class Config {
  // --- Units & viewport -----------------------------------------------------
  static const double tileSize = 32;
  static const int viewportTilesW = 24;
  static const int viewportTilesH = 14;
  static const double viewportWidth = tileSize * viewportTilesW; // 768
  static const double viewportHeight = tileSize * viewportTilesH; // 448

  // --- Signage line weights (STYLE_GUIDE.md §4), in logical px ---------------
  static const double stroke = 3;
  static const double strokeHeavy = 4.5;

  // --- Movement tuning knobs (felt out in M2) --------------------------------
  static const double runSpeed = 140; // logical px/s
  static const double gravity = 1200; // logical px/s²
  static const double jumpVelocity = -500; // logical px/s (up is -y); ≈3.2-tile rise
  static const double coyoteTime = 0.12; // s of grace after leaving a ledge
  static const double jumpBufferTime = 0.12; // s a jump press is remembered
  static const double carryJumpFactor = 0.82; // carrying limits jump (GDD §5)
}
