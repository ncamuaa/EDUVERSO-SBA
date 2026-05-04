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
    final token = await AuthService.getToken();

    // 🔍 TEMP DEBUG
    print('=== AI TUTOR DEBUG ===');
    print('TOKEN: "$token"');
    print('TOKEN EMPTY: ${token.isEmpty}');
    print('======================');

    if (token.isEmpty) {
      throw Exception('Not authenticated. Please login again.');
    }

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

    // 🔍 TEMP DEBUG
    print('STATUS: ${response.statusCode}');
    print('RESPONSE: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['reply'];
    } else {
      throw Exception(data['message'] ?? 'Failed to get response');
    }
  }
}