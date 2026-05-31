import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

class Module {
  final int id;
  final String title;
  final String description;
  final String subject;
  final String gradeLevel;
  final String course;
  final int orderIndex;

  const Module({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.gradeLevel,
    required this.course,
    required this.orderIndex,
  });

  factory Module.fromJson(Map<String, dynamic> json) => Module(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        subject: json['subject'] as String,
        gradeLevel: json['grade_level'] as String,
        course: json['course'] as String,
        orderIndex: json['order_index'] as int? ?? 0,
      );
}

class ModulesResponse {
  final List<Module> modules;
  final List<String> subjects;
  final List<String> grades;
  final List<String> courses;

  const ModulesResponse({
    required this.modules,
    required this.subjects,
    required this.grades,
    required this.courses,
  });
}

class ModulesService {
  static const String _base = '${ApiConfig.baseUrl}/api/modules';

  static Future<ModulesResponse> getModules({
    String? subject,
    String? grade,
    String? course,
  }) async {
    final token = await AuthService.getToken();

    final params = <String, String>{};
    if (subject != null) params['subject'] = subject;
    if (grade != null) params['grade'] = grade;
    if (course != null) params['course'] = course;

    final uri = Uri.parse(_base).replace(queryParameters: params.isEmpty ? null : params); // 👈 fixed

    print('[ModulesService] GET $uri'); // 👈 debug

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('[ModulesService] status: ${response.statusCode}'); // 👈 debug
    print('[ModulesService] body: ${response.body}');         // 👈 debug

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      final filters = data['filters'] as Map<String, dynamic>;
      return ModulesResponse(
        modules: (data['modules'] as List)
            .map((m) => Module.fromJson(m as Map<String, dynamic>))
            .toList(),
        subjects: List<String>.from(filters['subjects'] as List),
        grades: List<String>.from(filters['grades'] as List),
        courses: List<String>.from(filters['courses'] as List),
      );
    } else {
      throw Exception(data['message'] ?? 'Failed to load modules');
    }
  }
}