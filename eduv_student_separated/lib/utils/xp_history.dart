import 'package:supabase_flutter/supabase_flutter.dart';

class XpHistory {
  static final _db = Supabase.instance.client;

  static String? get _userId => _db.auth.currentUser?.id;

  static Future<void> addEntry({
    required int xp,
    required String reason,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _db.from('xp_history').insert({
        'user_id': userId,
        'xp': xp,
        'reason': reason,
      });
    } catch (e) {
      // fail silently
    }
  }

  static Future<List<Map<String, dynamic>>> getEntries() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final rows = await _db
          .from('xp_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return (rows as List).map((r) => {
        'xp': r['xp'] as int,
        'reason': r['reason'] as String,
        'timestamp': r['created_at'] as String,
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _db.from('xp_history').delete().eq('user_id', userId);
    } catch (_) {}
  }
}