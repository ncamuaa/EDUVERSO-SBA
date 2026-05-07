import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/lesson_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_size.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';
import 'quiz_page.dart'; // 👈 import the new quiz page

class LessonPage extends StatefulWidget {
  final int lessonId;
  final String lessonTitle;

  const LessonPage({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  bool _loading = true;
  String? _error;
  LessonDetail? _lesson;

  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lesson = await LessonService.getLessonById(widget.lessonId);
      if (!mounted) return;
      setState(() {
        _lesson = lesson;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);

    return StudentPageBase(
      title: widget.lessonTitle,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA56BFF)))
          : _error != null
              ? _buildError(w)
              : _buildLesson(w),
    );
  }

  Widget _buildError(double w) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⚠️',
                style: TextStyle(
                    fontSize: w * 0.12, decoration: TextDecoration.none)),
            SizedBox(height: w * 0.04),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: w * 0.038,
                  color: Colors.white70,
                  decoration: TextDecoration.none),
            ),
            SizedBox(height: w * 0.04),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA56BFF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLesson(double w) {
    final lesson = _lesson!;

    return ListView(
      controller: _scrollCtrl,
      padding: EdgeInsets.fromLTRB(w * 0.045, 12, w * 0.045, 32),
      children: [
        // ── Header meta ───────────────────────────────────────
        _MetaBar(lesson: lesson, w: w),
        SizedBox(height: w * 0.04),

        // ── Completion banner (if already done) ───────────────
        if (lesson.progress.completed)
          _CompletedBanner(
              score: lesson.progress.quizScore ?? 100, w: w),

        // ── Content blocks ────────────────────────────────────
        ...lesson.content.map((block) => Padding(
              padding: EdgeInsets.only(bottom: w * 0.04),
              child: block.type == 'code'
                  ? _CodeBlock(
                      code: block.body,
                      language: block.language ?? 'dart',
                      w: w,
                    )
                  : _TextBlock(body: block.body, w: w),
            )),

        // ── Quiz button ───────────────────────────────────────
        if (lesson.quiz.isNotEmpty) ...[
          SizedBox(height: w * 0.02),
          _QuizButton(
            w: w,
            completed: lesson.progress.completed,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizPage(
                    lessonId: widget.lessonId,
                    lessonTitle: widget.lessonTitle,
                    questions: lesson.quiz,
                    alreadyCompleted: lesson.progress.completed,
                    previousScore: lesson.progress.quizScore,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: w * 0.02),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quiz button
// ─────────────────────────────────────────────────────────────────────────────

class _QuizButton extends StatelessWidget {
  const _QuizButton({
    required this.w,
    required this.completed,
    required this.onTap,
  });

  final double w;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            horizontal: w * 0.05, vertical: w * 0.045),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8A63FF), Color(0xFFA77BFF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA56BFF).withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.025),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                completed ? '🔁' : '📝',
                style: TextStyle(
                    fontSize: w * 0.05, decoration: TextDecoration.none),
              ),
            ),
            SizedBox(width: w * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completed ? 'Retake Quiz' : 'Take Quiz',
                    style: TextStyle(
                      fontSize: w * 0.042,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  SizedBox(height: w * 0.005),
                  Text(
                    completed
                        ? 'Try again to improve your score'
                        : 'Test your knowledge on this lesson',
                    style: TextStyle(
                      fontSize: w * 0.031,
                      color: Colors.white.withOpacity(0.75),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: w * 0.04),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _MetaBar extends StatelessWidget {
  const _MetaBar({required this.lesson, required this.w});
  final LessonDetail lesson;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: w * 0.02,
      runSpacing: w * 0.015,
      children: [
        _chip(lesson.gradeLevel, const Color(0xFF6B8FFF)),
        _chip(lesson.course, const Color(0xFF4ECA8D)),
        _chip(lesson.subject, const Color(0xFFA56BFF)),
      ],
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: w * 0.025, vertical: w * 0.01),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35), width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: w * 0.029,
            color: color,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      );
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.body, required this.w});
  final String body;
  final double w;

  @override
  Widget build(BuildContext context) {
    return appCard(
      child: _MarkdownText(text: body, w: w),
    );
  }
}

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.text, required this.w});
  final String text;
  final double w;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('## ')) {
          return Padding(
            padding: EdgeInsets.only(bottom: w * 0.015, top: w * 0.01),
            child: Text(
              line.substring(3),
              style: TextStyle(
                fontSize: w * 0.046,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          );
        }
        if (line.startsWith('- ')) {
          return Padding(
            padding: EdgeInsets.only(bottom: w * 0.01, left: w * 0.02),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ',
                    style: TextStyle(
                        color: const Color(0xFFA56BFF),
                        fontSize: w * 0.038,
                        decoration: TextDecoration.none)),
                Expanded(child: _inlineText(line.substring(2), w)),
              ],
            ),
          );
        }
        if (line.isEmpty) return SizedBox(height: w * 0.01);
        return Padding(
          padding: EdgeInsets.only(bottom: w * 0.01),
          child: _inlineText(line, w),
        );
      }).toList(),
    );
  }

  Widget _inlineText(String line, double w) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int last = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > last) {
        spans.add(TextSpan(text: line.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      last = match.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last)));
    }
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: w * 0.038,
          color: Colors.white.withOpacity(0.85),
          height: 1.5,
          decoration: TextDecoration.none,
        ),
        children: spans,
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock(
      {required this.code, required this.language, required this.w});
  final String code;
  final String language;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0B2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                EdgeInsets.fromLTRB(w * 0.04, w * 0.025, w * 0.025, 0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.025, vertical: w * 0.008),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA56BFF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    language,
                    style: TextStyle(
                      fontSize: w * 0.028,
                      color: const Color(0xFFA56BFF),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(w * 0.02),
                    child: Icon(Icons.copy_rounded,
                        color: Colors.white38, size: w * 0.045),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(
                w * 0.04, w * 0.02, w * 0.04, w * 0.035),
            child: Text(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: w * 0.035,
                color: const Color(0xFFD8C3FF),
                height: 1.6,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner({required this.score, required this.w});
  final int score;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: w * 0.04),
      padding: EdgeInsets.symmetric(
          horizontal: w * 0.04, vertical: w * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFF4ECA8D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF4ECA8D).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('✅',
              style: TextStyle(
                  fontSize: 18, decoration: TextDecoration.none)),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(
              'You completed this lesson with a score of $score%.',
              style: TextStyle(
                fontSize: w * 0.035,
                color: const Color(0xFF4ECA8D),
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}