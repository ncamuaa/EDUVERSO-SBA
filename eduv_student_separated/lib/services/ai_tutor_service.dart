import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';

class AiTutorService {
  static const String _apiKey = Secrets.groqApiKey;
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _textModel = 'llama-3.3-70b-versatile';
  static const String _visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  static const Map<String, String> _systemPrompts = {
    'Study': '''You are a friendly, encouraging AI tutor helping a student learn.
- Answer questions clearly and accurately
- Break down complex topics into digestible parts
- Use examples and analogies to aid understanding
- Use markdown formatting to organize responses
- Keep responses concise but complete
- End with a follow-up question to keep learning momentum''',

    'Explain': '''You are an expert at making complex concepts simple.
- Explain any concept as clearly as possible
- Use analogies, real-world examples, and step-by-step breakdowns
- Use markdown for structure (headers, bullet points, bold key terms)
- Highlight the most important takeaways
- Explain the core first, then go deeper''',

    'Exam': '''You are a focused exam preparation coach.
- Help the student review and master topics for exams
- Ask practice questions to test understanding
- Give clear explanations for correct and incorrect answers
- Focus on common exam patterns and key concepts
- Provide memory tips and mnemonics when helpful''',
  };

  static Future<String> chat({
    required List<Map<String, dynamic>> messages,
    required String mode,
  }) async {
    bool hasImage = false;

    final chatMessages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': _systemPrompts[mode] ?? _systemPrompts['Study'],
      },
    ];

    for (final m in messages) {
      final role = m['role'] as String;
      if (role != 'user' && role != 'assistant') continue;

      if (m['type'] == 'image' && m['imageBytes'] != null) {
        hasImage = true;
        final bytes = m['imageBytes'] is Uint8List
            ? m['imageBytes'] as Uint8List
            : Uint8List.fromList(m['imageBytes'] as List<int>);
        final base64Image = base64Encode(bytes);
        final fileName = (m['fileName'] as String? ?? 'image.jpg').toLowerCase();
        final mimeType = fileName.endsWith('.png')
            ? 'image/png'
            : fileName.endsWith('.gif')
                ? 'image/gif'
                : fileName.endsWith('.webp')
                    ? 'image/webp'
                    : 'image/jpeg';

        chatMessages.add({
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mimeType;base64,$base64Image',
              },
            },
            {
              'type': 'text',
              'text': 'Please analyze this image and help me understand it as a tutor.',
            },
          ],
        });
      } else {
        chatMessages.add({
          'role': role,
          'content': m['content'] as String,
        });
      }
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': hasImage ? _visionModel : _textModel,
        'messages': chatMessages,
        'max_tokens': 1024,
        'temperature': 0.7,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception(data['error']?['message'] ?? 'Failed to get response');
    }
  }
}
