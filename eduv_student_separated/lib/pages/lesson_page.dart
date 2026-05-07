import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/lesson_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_size.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

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
  // ── State ─────────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  LessonDetail? _lesson;

  // ── Quiz state ────────────────────────────────────────────────────────────
  // questionId → selected optionId
  final Map<int, int> _answers = {};
  bool _quizSubmitted = false;
  CompletionResult? _result;

  // ── Scroll ────────────────────────────────────────────────────────────────
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

  // ── Data ──────────────────────────────────────────────────────────────────

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
        // Pre-fill if already completed
        if (lesson.progress.completed) {
          _quizSubmitted = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _submitQuiz() async {
    final lesson = _lesson!;
    // Validate all questions answered
    if (_answers.length < lesson.quiz.length) {
      _toast('Please answer all ${lesson.quiz.length} questions first.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await LessonService.completeLesson(
          widget.lessonId, _answers);
      if (!mounted) return;
      setState(() {
        _result = result;
        _quizSubmitted = true;
        _submitting = false;
      });
      // Scroll to results
      await Future.delayed(const Duration(milliseconds: 300));
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFA56BFF),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
                    fontSize: w * 0.12,
                    decoration: TextDecoration.none)),
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
        if (lesson.progress.completed && _result == null)
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

        // ── Quiz section ──────────────────────────────────────
        if (lesson.quiz.isNotEmpty) ...[
          _SectionDivider(label: '📝 Quiz', w: w),
          SizedBox(height: w * 0.03),
          ...lesson.quiz.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(bottom: w * 0.04),
                  child: _QuizCard(
                    index: entry.key,
                    question: entry.value,
                    selectedOptionId: _answers[entry.value.id],
                    submitted: _quizSubmitted,
                    w: w,
                    onSelect: _quizSubmitted
                        ? null
                        : (optionId) {
                            setState(() =>
                                _answers[entry.value.id] = optionId);
                          },
                  ),
                ),
              ),

          // Submit button
          if (!_quizSubmitted)
            _SubmitButton(
              onPressed: _submitQuiz,
              loading: _submitting,
              answered: _answers.length,
              total: lesson.quiz.length,
              w: w,
            ),

          // Results card
          if (_quizSubmitted && _result != null)
            _ResultCard(result: _result!, w: w),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
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
    // Simple markdown-ish rendering: parse ## headings and **bold**
    return appCard(
      child: _MarkdownText(text: body, w: w),
    );
  }
}

/// Very lightweight markdown renderer (headings + bold + bullets).
/// For full markdown, swap this out with the `flutter_markdown` package.
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
                Expanded(
                    child: _inlineText(line.substring(2), w)),
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
    // Handle **bold** inline
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
          // Language tag + copy button
          Padding(
            padding: EdgeInsets.fromLTRB(
                w * 0.04, w * 0.025, w * 0.025, 0),
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
          // Code content
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

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label, required this.w});
  final String label;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Container(
                height: 0.5,
                color: Colors.white.withOpacity(0.1))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.03),
          child: Text(
            label,
            style: TextStyle(
              fontSize: w * 0.038,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        Expanded(
            child: Container(
                height: 0.5,
                color: Colors.white.withOpacity(0.1))),
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.index,
    required this.question,
    required this.selectedOptionId,
    required this.submitted,
    required this.w,
    required this.onSelect,
  });

  final int index;
  final QuizQuestion question;
  final int? selectedOptionId;
  final bool submitted;
  final double w;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    return appCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${index + 1}.  ${question.question}',
            style: TextStyle(
              fontSize: w * 0.04,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: w * 0.03),
          ...question.options.map((opt) {
            final isSelected = selectedOptionId == opt.id;
            // Determine colors after submit
            Color borderColor = Colors.white.withOpacity(0.1);
            Color bgColor = Colors.white.withOpacity(0.05);
            Color textColor = Colors.white70;
            Widget? trailingIcon;

            if (submitted) {
              // For the quiz we don't reveal correct answer client-side
              // (correct answer data is NOT sent from server for security)
              // We just show which was selected
              if (isSelected) {
                borderColor = const Color(0xFFA56BFF);
                bgColor = const Color(0xFFA56BFF).withOpacity(0.15);
                textColor = Colors.white;
                trailingIcon = Icon(Icons.check_circle_rounded,
                    color: const Color(0xFFA56BFF), size: w * 0.05);
              }
            } else if (isSelected) {
              borderColor = const Color(0xFFA56BFF);
              bgColor = const Color(0xFFA56BFF).withOpacity(0.12);
              textColor = Colors.white;
            }

            return GestureDetector(
              onTap: onSelect == null ? null : () => onSelect!(opt.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: EdgeInsets.only(bottom: w * 0.02),
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04, vertical: w * 0.03),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        opt.text,
                        style: TextStyle(
                          fontSize: w * 0.037,
                          color: textColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) trailingIcon,
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.onPressed,
    required this.loading,
    required this.answered,
    required this.total,
    required this.w,
  });

  final VoidCallback onPressed;
  final bool loading;
  final int answered;
  final int total;
  final double w;

  @override
  Widget build(BuildContext context) {
    final ready = answered == total;
    return Column(
      children: [
        if (!ready)
          Padding(
            padding: EdgeInsets.only(bottom: w * 0.02),
            child: Text(
              '$answered / $total answered',
              style: TextStyle(
                fontSize: w * 0.033,
                color: Colors.white54,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: w * 0.13,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: ready
                    ? [const Color(0xFF8A63FF), const Color(0xFFA77BFF)]
                    : [Colors.white12, Colors.white12],
              ),
            ),
            child: ElevatedButton(
              onPressed: (ready && !loading) ? onPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Submit Quiz',
                      style: TextStyle(
                        fontSize: w * 0.042,
                        fontWeight: FontWeight.w800,
                        color: ready ? Colors.white : Colors.white38,
                        decoration: TextDecoration.none,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.w});
  final CompletionResult result;
  final double w;

  @override
  Widget build(BuildContext context) {
    final isPerfect = result.score == 100;
    return Container(
      margin: EdgeInsets.only(top: w * 0.04),
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPerfect
              ? [const Color(0xFF4ECA8D).withOpacity(0.2),
                 const Color(0xFF4ECA8D).withOpacity(0.05)]
              : [const Color(0xFFA56BFF).withOpacity(0.2),
                 const Color(0xFFA56BFF).withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPerfect
              ? const Color(0xFF4ECA8D).withOpacity(0.4)
              : const Color(0xFFA56BFF).withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Text(
            isPerfect ? '🎉' : '✅',
            style: TextStyle(
                fontSize: w * 0.1, decoration: TextDecoration.none),
          ),
          SizedBox(height: w * 0.02),
          Text(
            isPerfect ? 'Perfect Score!' : 'Lesson Complete!',
            style: TextStyle(
              fontSize: w * 0.055,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            '${result.correct} / ${result.total} correct  ·  ${result.score}%',
            style: TextStyle(
              fontSize: w * 0.038,
              color: Colors.white70,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: w * 0.025),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.04, vertical: w * 0.015),
            decoration: BoxDecoration(
              color: const Color(0xFFD0A06A).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFD0A06A).withOpacity(0.4)),
            ),
            child: Text(
              '+${result.xpGained} XP earned',
              style: TextStyle(
                fontSize: w * 0.035,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFD0A06A),
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