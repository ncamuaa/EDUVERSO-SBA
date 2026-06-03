import 'package:supabase_flutter/supabase_flutter.dart';

// ── Models ────────────────────────────────────────────────────────────────────

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

  factory Module.fromJson(Map<String, dynamic> j) => Module(
        id: j['id'] as int,
        title: j['title'] as String,
        description: j['description'] as String,
        subject: j['subject'] as String,
        gradeLevel: j['grade_level'] as String,
        course: j['course'] as String,
        orderIndex: j['order_index'] as int? ?? 0,
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
  static final _supabase = Supabase.instance.client;

  static Future<ModulesResponse> getModules({
    String? subject,
    String? grade,
    String? course,
  }) async {
    var query = _supabase
        .from('modules')
        .select()
        .order('order_index', ascending: true);

    final response = await query;
    final all = (response as List)
        .map((m) => Module.fromJson(m as Map<String, dynamic>))
        .toList();

    // Filter client-side
    final filtered = all.where((m) {
      if (subject != null && m.subject != subject) return false;
      if (grade != null && m.gradeLevel != grade) return false;
      if (course != null && m.course != course) return false;
      return true;
    }).toList();

    final subjects = all.map((m) => m.subject).toSet().toList()..sort();
    final grades   = all.map((m) => m.gradeLevel).toSet().toList()..sort();
    final courses  = all.map((m) => m.course).toSet().toList()..sort();

    return ModulesResponse(
      modules: filtered,
      subjects: subjects,
      grades: grades,
      courses: courses,
    );
  }
}
