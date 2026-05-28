import 'package:shared_preferences/shared_preferences.dart';

class GameProgressService {
  static const _xpKey = 'eduverso_xp';
  static const _scoreKey = 'eduverso_best_score';

  static Future<int> getXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_xpKey) ?? 0;
  }

  static Future<int> getBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_scoreKey) ?? 0;
  }

  static Future<void> addXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final currentXp = prefs.getInt(_xpKey) ?? 0;
    await prefs.setInt(_xpKey, currentXp + amount);
  }

  static Future<void> saveBestScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_scoreKey) ?? 0;

    if (score > best) {
      await prefs.setInt(_scoreKey, score);
    }
  }

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_xpKey);
    await prefs.remove(_scoreKey);
  }
}