import 'package:supabase_flutter/supabase_flutter.dart';

class GameArenaService {
  static final _db = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getLeaderboard({
    String? gameType,
    required String token,
  }) async {
    var query = _db
        .from('game_scores')
        .select('user_id, game_type, high_score, total_xp, games_played, users(full_name)')
        .order('high_score', ascending: false)
        .limit(10);

    if (gameType != null) {
      query = query.eq('game_type', gameType);
    }

    final data = await query;
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<List<Map<String, dynamic>>> getMyStats({
    required int userId,
    required String token,
  }) async {
    final data = await _db
        .from('game_scores')
        .select()
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<List<Map<String, dynamic>>> getGuessGameQuestions({
    String? difficulty,
    int limit = 10,
    required String token,
  }) async {
    var query = _db
        .from('guess_game_questions')
        .select()
        .limit(limit);

    if (difficulty != null) {
      query = query.eq('difficulty', difficulty);
    }

    final data = await query;
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<Map<String, dynamic>> submitGuessGame({
    required int userId,
    required List<Map<String, dynamic>> answers,
    required String token,
  }) async {
    // scoring handled client-side or via game_progress_service
    return {'success': true};
  }

  static Future<List<Map<String, dynamic>>> getEscapePuzzles({
    required String token,
  }) async {
    final data = await _db
        .from('escape_puzzles')
        .select();
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<Map<String, dynamic>> submitEscapePuzzle({
    required int userId,
    required int puzzleId,
    required String userOutput,
    required String token,
  }) async {
    return {'success': true};
  }
}
