import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class GameProgressService {
  static const _xpKey    = 'eduverso_xp';
  static const _scoreKey = 'eduverso_best_score';
  static final _db = Supabase.instance.client;

  // ── Change this to your backend URL ──────────────────────────
  // For device/emulator use your machine's local IP, e.g. 192.168.x.x
  // For iOS simulator / Android emulator on same machine use localhost
  static const _baseUrl = 'http://localhost:5002';

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
    await _syncToBackend(totalXp: newXp, gameType: gameType);
  }

  static Future<void> saveBestScore(int score, {String gameType = 'guess_game'}) async {
    final prefs = await SharedPreferences.getInstance();
    final best  = prefs.getInt(_scoreKey) ?? 0;
    if (score > best) {
      await prefs.setInt(_scoreKey, score);
    }
    // Always sync so games_played increments
    await _syncToBackend(highScore: score, gameType: gameType);
  }

 static Future<void> _syncToBackend({
  int? totalXp,
  int? highScore,
  String gameType = 'guess_game',
}) async {
  try {
    final user  = _db.auth.currentUser;
    final token = await AuthService.getToken();
    
    print('🔵 syncToBackend called: gameType=$gameType, user=${user?.id}, tokenEmpty=${token.isEmpty}');
    
    if (user == null || token.isEmpty) {
      print('❌ No user or token');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final xp    = totalXp  ?? prefs.getInt(_xpKey)    ?? 0;
    final score = highScore ?? prefs.getInt(_scoreKey) ?? 0;

    print('📤 Posting to $_baseUrl/api/game-arena/sync-progress');
    
    final res = await http.post(
      Uri.parse('$_baseUrl/api/game-arena/sync-progress'),
      headers: {
        'Content-Type' : 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId'   : user.id,
        'gameType' : gameType,
        'totalXp'  : xp,
        'highScore': score,
      }),
    );
    
    print('✅ Response: ${res.statusCode} ${res.body}');
  } catch (e) {
    print('❌ Sync error: $e');
  }
}
  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final token = await AuthService.getToken();
      if (token.isEmpty) return [];

      final res = await http.get(
        Uri.parse('$_baseUrl/api/game-arena/leaderboard'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['leaderboard']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getMyStats() async {
    try {
      final user  = _db.auth.currentUser;
      final token = await AuthService.getToken();
      if (user == null || token.isEmpty) return null;

      final res = await http.get(
        Uri.parse('$_baseUrl/api/game-arena/my-stats/${user.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final stats = data['stats'] as List;
          if (stats.isEmpty) return null;
          // Aggregate all game types into one summary
          int totalXp    = 0;
          int highScore  = 0;
          for (final s in stats) {
            totalXp   += (s['total_xp']   ?? 0) as int;
            final hs   = (s['high_score'] ?? 0) as int;
            if (hs > highScore) highScore = hs;
          }
          return {'total_xp': totalXp, 'high_score': highScore};
        }
      }
      return null;
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