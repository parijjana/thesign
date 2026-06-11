import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'progress.dart';

/// Offline persistence via shared_preferences (ARCHITECTURE.md §5.8).
/// Autosaved on node transitions and solves; loaded on launch. Keys are
/// per-profile — avatar-select UI lands in M7, default profile until then.
class SaveService {
  SaveService({this.profile = 'p1'});

  final String profile;

  String get _key => 'thesign.$profile.progress';

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
