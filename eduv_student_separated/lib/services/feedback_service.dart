import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

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
        title: j['title'] as String,
        body: j['body'] as String,
        rating: j['rating'] as int,
        createdAt: j['created_at'] as String,
        giverName: j['giver_name'] as String? ?? '',
      );
}

class FeedbackService {
  // Flutter Web uses localhost directly
  static const String _base = '${ApiConfig.baseUrl}/api/feedback';
  
  static Future<Map<String, String>> get _headers async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await AuthService.getToken()}',
      };

  static Future<List<FeedbackItem>> getFeedback({
    required int userId,
    String? search,
  }) async {
    final uri = Uri.parse(
      '$_base/$userId${search != null && search.isNotEmpty ? '?search=$search' : ''}',
    );

    print('[FeedbackService] GET $uri'); // 👈 debug

    final res = await http.get(uri, headers: await _headers);

    print('[FeedbackService] status: ${res.statusCode}'); // 👈 debug
    print('[FeedbackService] body: ${res.body}');         // 👈 debug

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List)
          .map((f) => FeedbackItem.fromJson(f as Map<String, dynamic>))
          .toList();
    }
    throw Exception(data['message'] ?? 'Failed to load feedback');
  }
}