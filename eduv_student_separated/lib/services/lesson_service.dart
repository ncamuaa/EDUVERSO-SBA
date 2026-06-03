import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class ContentBlock {
  final int id;
  final String type;
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
  final bool isCorrect;
  final int orderIndex;

  const QuizOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    required this.orderIndex,
  });

  factory QuizOption.fromJson(Map<String, dynamic> j) => QuizOption(
        id: j['id'] as int,
        text: j['option_text'] as String,
        isCorrect: j['is_correct'] as bool? ?? false,
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
}

class CompletionResult {
  final int score;
  final int correct;
  final int total;
  final int xpGained;
  final Map<int, int>? correctOptionIds;

  const CompletionResult({
    required this.score,
    required this.correct,
    required this.total,
    required this.xpGained,
    this.correctOptionIds,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class LessonService {
  static final _supabase = Supabase.instance.client;

  static Future<LessonDetail> getLessonById(int lessonId) async {
    final lessonRow = await _supabase
        .from('lessons')
        .select('*, modules(title, subject, grade_level, course)')
        .eq('id', lessonId)
        .single();

    final contentRows = await _supabase
        .from('lesson_content')
        .select()
        .eq('lesson_id', lessonId)
        .order('order_index', ascending: true);

    final questionRows = await _supabase
        .from('quiz_questions')
        .select('*, quiz_options(*)')
        .eq('lesson_id', lessonId)
        .order('order_index', ascending: true);

    final userId = _supabase.auth.currentUser?.id;
    bool completed = false;
    int? quizScore;
    String? completedAt;

    if (userId != null) {
      try {
        final progressRow = await _supabase
            .from('user_progress')
            .select()
            .eq('user_id', userId)
            .eq('lesson_id', lessonId)
            .maybeSingle();

        if (progressRow != null) {
          completed   = progressRow['completed'] as bool? ?? false;
          quizScore   = progressRow['quiz_score'] as int?;
          completedAt = progressRow['completed_at'] as String?;
        }
      } catch (_) {}
    }

    final module = lessonRow['modules'] as Map<String, dynamic>;

    return LessonDetail(
      id:          lessonRow['id'] as int,
      moduleId:    lessonRow['module_id'] as int,
      title:       lessonRow['title'] as String,
      moduleTitle: module['title'] as String,
      subject:     module['subject'] as String,
      gradeLevel:  module['grade_level'] as String,
      course:      module['course'] as String,
      content: (contentRows as List)
          .map((c) => ContentBlock.fromJson(c as Map<String, dynamic>))
          .toList(),
      quiz: (questionRows as List).map((q) {
        final qMap = Map<String, dynamic>.from(q as Map);
        final opts = (qMap['quiz_options'] as List? ?? [])
            .map((o) => QuizOption.fromJson(o as Map<String, dynamic>))
            .toList();
        qMap['options'] = opts.map((o) => {
          'id': o.id,
          'option_text': o.text,
          'is_correct': o.isCorrect,
          'order_index': o.orderIndex,
        }).toList();
        return QuizQuestion.fromJson(qMap);
      }).toList(),
      progress: LessonProgress(
        completed:   completed,
        quizScore:   quizScore,
        completedAt: completedAt,
      ),
    );
  }

  static Future<List<Map<String, dynamic>>> getLessonsByModule(int moduleId) async {
    final userId = _supabase.auth.currentUser?.id;

    final lessons = await _supabase
        .from('lessons')
        .select()
        .eq('module_id', moduleId)
        .order('order_index', ascending: true);

    if (userId == null) return List<Map<String, dynamic>>.from(lessons as List);

    final progress = await _supabase
        .from('user_progress')
        .select()
        .eq('user_id', userId);

    final progressMap = <int, bool>{};
    for (final p in progress as List) {
      progressMap[p['lesson_id'] as int] = p['completed'] as bool? ?? false;
    }

    return (lessons as List).map((l) {
      final lesson = Map<String, dynamic>.from(l as Map);
      lesson['completed'] = progressMap[lesson['id'] as int] ?? false;
      return lesson;
    }).toList();
  }

  static Future<CompletionResult> completeLesson(
    int lessonId,
    Map<int, int> quizAnswers,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    // Get correct answers
    final questions = await _supabase
        .from('quiz_questions')
        .select('id, quiz_options(id, is_correct)')
        .eq('lesson_id', lessonId);

    int correct = 0;
    final total = (questions as List).length;
    final correctOptionIds = <int, int>{};

    for (final q in questions) {
      final qId = q['id'] as int;
      final opts = q['quiz_options'] as List;
      final correctOpt = opts.firstWhere(
        (o) => o['is_correct'] == true,
        orElse: () => null,
      );
      if (correctOpt != null) {
        correctOptionIds[qId] = correctOpt['id'] as int;
        if (quizAnswers[qId] == correctOpt['id']) correct++;
      }
    }

    final score    = total > 0 ? (correct / total * 100).round() : 0;
    final xpGained = correct * 10;

    // Save progress
    await _supabase.from('user_progress').upsert({
      'user_id':      userId,
      'lesson_id':    lessonId,
      'completed':    true,
      'quiz_score':   score,
      'completed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,lesson_id');

    // Update XP and level in users table
    if (xpGained > 0) {
      try {
        final userRow = await _supabase
            .from('users')
            .select('xp')
            .eq('id', userId)
            .single();
        final currentXp = (userRow['xp'] as int?) ?? 0;
        final newXp     = currentXp + xpGained;
        final newLevel  = (newXp / 100).floor() + 1;
        await _supabase.from('users').update({
          'xp':    newXp,
          'level': newLevel,
        }).eq('id', userId);
      } catch (e) {
        debugPrint('XP update error: $e');
      }
    }

    return CompletionResult(
      score:            score,
      correct:          correct,
      total:            total,
      xpGained:         xpGained,
      correctOptionIds: correctOptionIds,
    );
  }
}