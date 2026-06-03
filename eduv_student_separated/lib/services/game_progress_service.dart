import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class GameProgressService {
  static const _xpKey    = 'eduverso_xp';
  static const _scoreKey = 'eduverso_best_score';
  static final _db = Supabase.instance.client;

  static Future<int> getXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_xpKey) ?? 0;
  }

  static Future<int> getBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_scoreKey) ?? 0;
  }

  static Future<void> addXp(int amount, {String gameType = 'guess_game'}) async {
    final prefs = await SharedPreferences.getInstance();
    final newXp = (prefs.getInt(_xpKey) ?? 0) + amount;
    await prefs.setInt(_xpKey, newXp);
    await _syncToSupabase(totalXp: newXp, gameType: gameType);
  }

  static Future<void> saveBestScore(int score, {String gameType = 'guess_game'}) async {
    final prefs = await SharedPreferences.getInstance();
    final best  = prefs.getInt(_scoreKey) ?? 0;
    if (score > best) {
      await prefs.setInt(_scoreKey, score);
      await _syncToSupabase(highScore: score, gameType: gameType);
    }
  }

  static Future<void> _syncToSupabase({int? totalXp, int? highScore, String gameType = 'guess_game'}) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final xp    = totalXp  ?? prefs.getInt(_xpKey)    ?? 0;
      final score = highScore ?? prefs.getInt(_scoreKey) ?? 0;

      await _db.from('game_scores').upsert({
        'user_id'     : user.id,
        'game_type'   : gameType,
        'total_xp'    : xp,
        'high_score'  : score,
        'games_played': 1,
      }, onConflict: 'user_id,game_type');
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final data = await _db
          .from('game_scores')
          .select('user_id, game_type, high_score, total_xp, games_played, users(full_name)')
          .order('high_score', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getMyStats() async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return null;

      final data = await _db
          .from('game_scores')
          .select()
          .eq('user_id', user.id)
          .limit(1);

      final list = data as List;
      if (list.isEmpty) return null;
      return Map<String, dynamic>.from(list.first);
    } catch (_) {
      return null;
    }
  }

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_xpKey);
    await prefs.remove(_scoreKey);
  }
}
