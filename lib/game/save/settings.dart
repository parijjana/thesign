import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings (M7 shell). **Global, not per-profile** — sound prefs and
/// touch-control sizing belong to the device/player, not a single save slot.
/// Persisted via shared_preferences alongside the save data (ARCHITECTURE §5.8).
///
/// The sound/music toggles are stored now but inert until the M7 audio pass
/// lands (no audio engine yet, user's call); the touch-size preset is live and
/// scales [TouchControls] on touch platforms.
class AppSettings {
  AppSettings({
    this.soundOn = true,
    this.musicOn = true,
    this.touchScale = TouchScale.medium,
  });

  bool soundOn;
  bool musicOn;
  TouchScale touchScale;

  static const _key = 'thesign.settings';

  Map<String, dynamic> toJson() => {
        'version': 1,
        'soundOn': soundOn,
        'musicOn': musicOn,
        'touchScale': touchScale.name,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        soundOn: json['soundOn'] as bool? ?? true,
        musicOn: json['musicOn'] as bool? ?? true,
        touchScale: TouchScale.values.firstWhere(
          (s) => s.name == json['touchScale'],
          orElse: () => TouchScale.medium,
        ),
      );

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return AppSettings(); // corrupt prefs: sensible defaults (kindness)
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toJson()));
  }
}

/// Touch-button size presets (kid-hand sizing) — a wordless small/medium/large
/// shown as pips. Multiplies the base button px in [TouchControls].
enum TouchScale { small, medium, large }

extension TouchScaleFactor on TouchScale {
  double get factor => switch (this) {
        TouchScale.small => 0.8,
        TouchScale.medium => 1.0,
        TouchScale.large => 1.25,
      };

  /// Cycle to the next preset (wraps) — the settings confirm action.
  TouchScale get next =>
      TouchScale.values[(index + 1) % TouchScale.values.length];

  /// Pip count for the wordless size indicator (1..3).
  int get pips => index + 1;
}
