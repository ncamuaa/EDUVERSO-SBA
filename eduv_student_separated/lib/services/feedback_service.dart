import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackItem {
  final int id;
  final String category;
  final String title;
  final String body;
  final int rating;
  final String createdAt;
  final String giverName;

  const FeedbackItem({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.rating,
    required this.createdAt,
    required this.giverName,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> j) => FeedbackItem(
        id: j['id'] as int,
        category: j['category'] as String? ?? 'General',
        title: j['title'] as String? ?? '',
        body: j['content'] as String? ?? '',
        rating: j['rating'] as int? ?? 0,
        createdAt: j['created_at'] as String? ?? '',
        giverName: j['giver_name'] as String? ?? '',
      );
}

class FeedbackService {
  static final _db = Supabase.instance.client;

  static Future<List<FeedbackItem>> getFeedback({
    required String userId,
    String? search,
  }) async {
    var query = _db
        .from('feedback')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final List data = await query;

    var items = data.map((f) => FeedbackItem.fromJson(f as Map<String, dynamic>)).toList();

    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      items = items.where((f) =>
        f.body.toLowerCase().contains(q) ||
        f.title.toLowerCase().contains(q) ||
        f.giverName.toLowerCase().contains(q)
      ).toList();
    }

    return items;
  }

  static Future<void> createFeedback({
    required String userId,
    required String content,
    required int rating,
  }) async {
    await _db.from('feedback').insert({
      'user_id': userId,
      'content': content,
      'rating': rating,
    });
  }

  static Future<void> deleteFeedback({required int feedbackId}) async {
    await _db.from('feedback').delete().eq('id', feedbackId);
  }
}
