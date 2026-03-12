import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'save_manager.dart';

/// Persistent save manager backed by SharedPreferences.
/// Stores game state as a JSON string so progress survives app restarts.
class SharedPrefsSaveManager implements SaveManager {
  static const _key = 'ai_evolution_save';

  @override
  Future<Map<String, dynamic>?> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return json.decode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> saveGameState(Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(state));
  }

  @override
  Future<void> deleteSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
