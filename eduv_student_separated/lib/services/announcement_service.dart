import 'package:supabase_flutter/supabase_flutter.dart';

class Announcement {
  final int id;
  final String tag;
  final String badge;
  final String title;
  final String body;
  final String createdAt;

  const Announcement({
    required this.id,
    required this.tag,
    required this.badge,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'] as int,
        tag: j['tag'] as String? ?? '',
        badge: j['badge'] as String? ?? '',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        createdAt: j['created_at'] as String? ?? '',
      );
}

class AnnouncementResult {
  final List<Announcement> data;
  final int total;
  final int page;
  final int totalPages;

  const AnnouncementResult({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}

class AnnouncementService {
  static final _db = Supabase.instance.client;
  static const int _perPage = 1;

  static Future<AnnouncementResult> getAnnouncements({int page = 1}) async {
    final from = (page - 1) * _perPage;
    final to = from + _perPage - 1;

    final countRes = await _db
        .from('announcements')
        .select('id');
    final total = (countRes as List).length;

    final response = await _db
        .from('announcements')
        .select()
        .order('created_at', ascending: false)
        .range(from, to);

    final list = (response as List)
        .map((a) => Announcement.fromJson(a as Map<String, dynamic>))
        .toList();

    return AnnouncementResult(
      data: list,
      total: total,
      page: page,
      totalPages: (total / _perPage).ceil().clamp(1, 9999),
    );
  }
}
