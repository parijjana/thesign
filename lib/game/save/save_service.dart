import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'progress.dart';

/// Offline persistence via shared_preferences (ARCHITECTURE.md §5.8).
/// Autosaved on node transitions and solves; loaded on launch. Keys are
/// per-profile — avatar-select UI lands in M7, default profile until then.
class SaveService {
  SaveService({this.profile = 'p1'});

  final String profile;

  /// The fixed profile/avatar slots (M7 profile select). Each id IS one avatar
  /// identity — the player picks an avatar, never types a name (symbol-first,
  /// no text in the shell where it can be avoided). Saves live per slot.
  static const profileIds = ['p1', 'p2', 'p3'];
  static const _lastKey = 'thesign.lastProfile';

  String get _key => 'thesign.$profile.progress';

  /// Does this slot already hold a run? Drives the select screen's resume
  /// indicator and lets the game decide fresh-start vs resume.
  Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  /// Remember this as the most recently played slot (pre-selected next launch).
  Future<void> markActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKey, profile);
  }

  /// The slot played last, if any.
  static Future<String?> lastProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastKey);
  }

  /// Which slots currently hold a saved run — for the select screen's dots.
  static Future<Set<String>> profilesWithSaves() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final id in profileIds)
        if (prefs.containsKey('thesign.$id.progress')) id,
    };
  }

  Future<void> save(Progress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(progress.toJson()));
  }

  Future<Progress?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Progress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null; // corrupt save: start fresh rather than crash (kindness)
    }
  }

  Future<void> wipe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
