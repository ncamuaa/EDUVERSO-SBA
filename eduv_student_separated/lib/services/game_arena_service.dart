import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart'; // adjust to your actual config path

class GameArenaService {
  static const _base = '${ApiConfig.baseUrl}/api/game-arena';

  // ─── SHARED ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getLeaderboard({
    String? gameType,
    required String token,
  }) async {
    final query = gameType != null ? '?game_type=$gameType' : '';
    final res = await http.get(
      Uri.parse('$_base/leaderboard$query'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    if (data['success']) return List<Map<String, dynamic>>.from(data['leaderboard']);
    throw Exception(data['message']);
  }

  static Future<List<Map<String, dynamic>>> getMyStats({
    required int userId,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('$_base/my-stats/$userId'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    if (data['success']) return List<Map<String, dynamic>>.from(data['stats']);
    throw Exception(data['message']);
  }

  // ─── GUESS GAME ──────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getGuessGameQuestions({
    String? difficulty,
    int limit = 10,
    required String token,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (difficulty != null) params['difficulty'] = difficulty;

    final uri = Uri.parse('$_base/guess-game/questions').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers(token));
    final data = jsonDecode(res.body);
    if (data['success']) return List<Map<String, dynamic>>.from(data['questions']);
    throw Exception(data['message']);
  }

  /// [answers] = [{ 'questionId': 1, 'selected': 'a' }, ...]
  static Future<Map<String, dynamic>> submitGuessGame({
    required int userId,
    required List<Map<String, dynamic>> answers,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/guess-game/submit'),
      headers: _headers(token),
      body: jsonEncode({'userId': userId, 'answers': answers}),
    );
    final data = jsonDecode(res.body);
    if (data['success']) return Map<String, dynamic>.from(data);
    throw Exception(data['message']);
  }

  // ─── ESCAPE THE PROGRAM ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getEscapePuzzles({
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('$_base/escape/puzzles'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    if (data['success']) return List<Map<String, dynamic>>.from(data['puzzles']);
    throw Exception(data['message']);
  }

  static Future<Map<String, dynamic>> submitEscapePuzzle({
    required int userId,
    required int puzzleId,
    required String userOutput,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/escape/submit'),
      headers: _headers(token),
      body: jsonEncode({
        'userId': userId,
        'puzzleId': puzzleId,
        'userOutput': userOutput,
      }),
    );
    final data = jsonDecode(res.body);
    if (data['success']) return Map<String, dynamic>.from(data);
    throw Exception(data['message']);
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
}