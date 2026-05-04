import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class AiTutorService {
  static const String baseUrl =
      'https://eduverso-sba-production.up.railway.app/api/ai-tutor';

  static Future<String> chat({
    required List<Map<String, String>> messages,
    required String mode,
  }) async {
    // ✅ Use AuthService.getToken() — works on web + mobile
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'mode': mode,
        'messages': messages,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['reply'];
    } else {
      throw Exception(data['message'] ?? 'Failed to get response');
    }
  }
}