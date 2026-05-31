import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class XpHistory {
  static const _key = 'xp_history';

  static Future<void> addEntry({
    required int xp,
    required String reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final entry = jsonEncode({
      'xp': xp,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });
    raw.insert(0, entry); // newest first
    await prefs.setStringList(_key, raw.take(50).toList()); // keep last 50
  }

  static Future<List<Map<String, dynamic>>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}