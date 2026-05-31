import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class ContentBlock {
  final int id;
  final String type; // 'text' | 'code'
  final String body;
  final String? language;
  final int orderIndex;

  const ContentBlock({
    required this.id,
    required this.type,
    required this.body,
    this.language,
    required this.orderIndex,
  });

  factory ContentBlock.fromJson(Map<String, dynamic> j) => ContentBlock(
        id: j['id'] as int,
        type: j['type'] as String,
        body: j['body'] as String,
        language: j['language'] as String?,
        orderIndex: j['order_index'] as int,
      );
}

class QuizOption {
  final int id;
  final String text;
  final int orderIndex;

  const QuizOption(
      {required this.id, required this.text, required this.orderIndex});

  factory QuizOption.fromJson(Map<String, dynamic> j) => QuizOption(
        id: j['id'] as int,
        text: j['option_text'] as String,
        orderIndex: j['order_index'] as int,
      );
}

class QuizQuestion {
  final int id;
  final String question;
  final int orderIndex;
  final List<QuizOption> options;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.orderIndex,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id'] as int,
        question: j['question'] as String,
        orderIndex: j['order_index'] as int,
        // ✅ FIX: null-safe options list
        options: ((j['options'] as List?) ?? [])
            .map((o) => QuizOption.fromJson(o as Map<String, dynamic>))
            .toList(),
      );
}

class LessonProgress {
  final bool completed;
  final int? quizScore;
  final String? completedAt;

  const LessonProgress({
    required this.completed,
    this.quizScore,
    this.completedAt,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> j) => LessonProgress(
        // ✅ FIX: handle both bool and int (1/0) from server
        completed: j['completed'] == true || j['completed'] == 1,
        quizScore: j['quiz_score'] as int?,
        completedAt: j['completed_at'] as String?,
      );
}

class LessonDetail {
  final int id;
  final int moduleId;
  final String title;
  final String moduleTitle;
  final String subject;
  final String gradeLevel;
  final String course;
  final List<ContentBlock> content;
  final List<QuizQuestion> quiz;
  final LessonProgress progress;

  const LessonDetail({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.moduleTitle,
    required this.subject,
    required this.gradeLevel,
    required this.course,
    required this.content,
    required this.quiz,
    required this.progress,
  });

  factory LessonDetail.fromJson(Map<String, dynamic> j) {
    // ✅ DEBUG: print raw quiz data so you can see what the server returns
    // Remove these prints once confirmed working.
    final rawQuiz = j['quiz'];
    print('──────────────────────────────────');
    print('[LessonDetail] raw quiz field: $rawQuiz');
    print('[LessonDetail] quiz type: ${rawQuiz.runtimeType}');
    print('[LessonDetail] quiz length: ${(rawQuiz as List?)?.length ?? 0}');
    print('──────────────────────────────────');

    return LessonDetail(
      id: j['id'] as int,
      moduleId: j['module_id'] as int? ?? 0,
      title: j['title'] as String,
      moduleTitle: j['module_title'] as String,
      subject: j['subject'] as String,
      gradeLevel: j['grade_level'] as String,
      course: j['course'] as String,
      // ✅ FIX: null-safe content list
      content: ((j['content'] as List?) ?? [])
          .map((c) => ContentBlock.fromJson(c as Map<String, dynamic>))
          .toList(),
      // ✅ FIX: null-safe quiz list
      quiz: ((j['quiz'] as List?) ?? [])
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      // ✅ FIX: null-safe progress (fallback to not-completed if missing)
      progress: j['progress'] != null
          ? LessonProgress.fromJson(j['progress'] as Map<String, dynamic>)
          : const LessonProgress(completed: false),
    );
  }
}

class CompletionResult {
  final int score;
  final int correct;
  final int total;
  final int xpGained;

  /// questionId → correct optionId
  final Map<int, int>? correctOptionIds;

  const CompletionResult({
    required this.score,
    required this.correct,
    required this.total,
    required this.xpGained,
    this.correctOptionIds,
  });

  factory CompletionResult.fromJson(Map<String, dynamic> j) {
    Map<int, int>? correctOptionIds;
    final raw = j['correctAnswers'];
    if (raw is Map && raw.isNotEmpty) {
      correctOptionIds = {};
      raw.forEach((k, v) {
        final questionId = int.tryParse(k.toString());
        final optionId = v is int ? v : int.tryParse(v.toString());
        if (questionId != null && optionId != null) {
          correctOptionIds![questionId] = optionId;
        }
      });
    }

    return CompletionResult(
      score: j['score'] as int,
      correct: j['correct'] as int,
      total: j['total'] as int,
      xpGained: j['xpGained'] as int,
      correctOptionIds: correctOptionIds,
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class LessonService {
  static const String _base = '${ApiConfig.baseUrl}/api/lessons';

  static Future<Map<String, String>> get _headers async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await AuthService.getToken()}',
      };

  static Future<LessonDetail> getLessonById(int lessonId) async {
    final res = await http.get(
      Uri.parse('$_base/$lessonId'),
      headers: await _headers,
    );

    // ✅ DEBUG: print raw response so you can inspect it
    print('[LessonService] GET /lessons/$lessonId → ${res.statusCode}');
    print('[LessonService] body: ${res.body}');

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data['success'] == true) {
      return LessonDetail.fromJson(data['lesson'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Failed to load lesson');
  }

  /// quizAnswers: { questionId -> selectedOptionId }
  static Future<CompletionResult> completeLesson(
    int lessonId,
    Map<int, int> quizAnswers,
  ) async {
    final res = await http.post(
      Uri.parse('$_base/$lessonId/complete'),
      headers: await _headers,
      body: jsonEncode({
        'quizAnswers': quizAnswers.map((k, v) => MapEntry(k.toString(), v)),
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data['success'] == true) {
      return CompletionResult.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Failed to submit lesson');
  }
}