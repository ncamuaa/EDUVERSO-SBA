import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

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
        tag: j['tag'] as String,
        badge: j['badge'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        createdAt: j['created_at'] as String,
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
  static const String _base =
      'https://eduverso-sba-production.up.railway.app/api/announcements';

  static Future<Map<String, String>> get _headers async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await AuthService.getToken()}',
      };

  static Future<AnnouncementResult> getAnnouncements({int page = 1}) async {
    final uri = Uri.parse('$_base?page=$page&limit=1');
    final res = await http.get(uri, headers: await _headers);
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200 && data['success'] == true) {
      final list = (data['data'] as List)
          .map((a) => Announcement.fromJson(a as Map<String, dynamic>))
          .toList();
      final pagination = data['pagination'] as Map<String, dynamic>;
      return AnnouncementResult(
        data: list,
        total: pagination['total'] as int,
        page: pagination['page'] as int,
        totalPages: pagination['totalPages'] as int,
      );
    }
    throw Exception(data['message'] ?? 'Failed to load announcements');
  }
}