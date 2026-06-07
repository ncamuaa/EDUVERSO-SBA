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
    if (amount <= 0) return;
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
    }
    await _syncToSupabase(highScore: score, gameType: gameType);
  }

  static Future<void> _syncToSupabase({
    int? totalXp,
    int? highScore,
    String gameType = 'guess_game',
  }) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final xp    = totalXp  ?? prefs.getInt(_xpKey)    ?? 0;
      final score = highScore ?? prefs.getInt(_scoreKey) ?? 0;

      // Fetch existing row for this user + game type
      final existing = await _db
          .from('game_scores')
          .select()
          .eq('user_id', user.id)
          .eq('game_type', gameType)
          .maybeSingle();

      if (existing == null) {
        // Insert new row
        await _db.from('game_scores').insert({
          'user_id'     : user.id,
          'game_type'   : gameType,
          'total_xp'    : xp,
          'high_score'  : score,
          'games_played': 1,
          'updated_at'  : DateTime.now().toIso8601String(),
        });
        print('✅ Inserted new game_scores row for $gameType');
      } else {
        // Update existing row
        final newHighScore = score > (existing['high_score'] ?? 0) ? score : (existing['high_score'] ?? 0);
        final newXp        = xp > (existing['total_xp']   ?? 0) ? xp : (existing['total_xp']   ?? 0);
        final newPlayed    = ((existing['games_played'] ?? 0) as int) + 1;

        await _db.from('game_scores').update({
          'total_xp'    : newXp,
          'high_score'  : newHighScore,
          'games_played': newPlayed,
          'updated_at'  : DateTime.now().toIso8601String(),
        })
        .eq('user_id', user.id)
        .eq('game_type', gameType);
        print('✅ Updated game_scores row for $gameType');
      }
    } catch (e) {
      print('❌ Supabase sync error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final scores = await _db
          .from('game_scores')
          .select('*, users(full_name)')
          .order('total_xp', ascending: false);

      return scores.map<Map<String, dynamic>>((s) => {
        ...s,
        'player_name': (s['users'] as Map?)?['full_name'] ?? 'Unknown',
      }).toList();
    } catch (e) {
      print('❌ Leaderboard error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getMyStats() async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return null;

      final stats = await _db
          .from('game_scores')
          .select()
          .eq('user_id', user.id);

      if (stats.isEmpty) return null;

      int totalXp   = 0;
      int highScore = 0;
      for (final s in stats) {
        totalXp  += (s['total_xp']  ?? 0) as int;
        final hs  = (s['high_score'] ?? 0) as int;
        if (hs > highScore) highScore = hs;
      }
      return {'total_xp': totalXp, 'high_score': highScore};
    } catch (e) {
      print('❌ getMyStats error: $e');
      return null;
    }
  }

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_xpKey);
    await prefs.remove(_scoreKey);
  }
}