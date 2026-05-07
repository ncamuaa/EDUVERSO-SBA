import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/ai_tutor_service.dart';
import '../services/lesson_service.dart';
import '../utils/app_size.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class QuizPage extends StatefulWidget {
  final int lessonId;
  final String lessonTitle;
  final List<QuizQuestion> questions;
  final bool alreadyCompleted;
  final int? previousScore;

  const QuizPage({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.questions,
    this.alreadyCompleted = false,
    this.previousScore,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final Map<int, int> _answers = {};
  bool _submitted = false;
  bool _submitting = false;
  CompletionResult? _result;

  // correctAnswers: questionId → correct optionId (populated after submit)
  // Requires CompletionResult to expose correctOptionIds map.
  Map<int, int> _correctAnswers = {};

  // AI Tutor overlay
  bool _showTutor = false;
  final List<Map<String, dynamic>> _tutorMessages = [];
  bool _tutorLoading = false;
  final TextEditingController _tutorCtrl = TextEditingController();
  final ScrollController _tutorScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Do NOT lock the quiz even if already completed — let them retake it.
    // The _CompletedBanner informs them of their previous score.
  }

  @override
  void dispose() {
    _tutorCtrl.dispose();
    _tutorScroll.dispose();
    super.dispose();
  }

  // ── Quiz submit ───────────────────────────────────────────────────────────

  Future<void> _submitQuiz() async {
    if (_answers.length < widget.questions.length) {
      _toast('Please answer all ${widget.questions.length} questions first.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final result =
          await LessonService.completeLesson(widget.lessonId, _answers);
      if (!mounted) return;

      // Populate correct answers if the server returns them.
      // Add `Map<int,int>? correctOptionIds` to your CompletionResult model.
      final Map<int, int> correct = {};
      if (result.correctOptionIds != null) {
        correct.addAll(result.correctOptionIds!);
      }

      setState(() {
        _result = result;
        _correctAnswers = correct;
        _submitted = true;
        _submitting = false;
      });
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── AI Tutor ──────────────────────────────────────────────────────────────

  void _openTutor() {
    if (_tutorMessages.isEmpty) {
      final wrongQuestions = widget.questions.where((q) {
        final selected = _answers[q.id];
        final correct = _correctAnswers[q.id];
        return selected != null && correct != null && selected != correct;
      }).toList();

      String greeting;
      if (wrongQuestions.isEmpty) {
        greeting =
            'Great job on the quiz! 🎉 Do you have any questions about **${widget.lessonTitle}**?';
      } else {
        final topics =
            wrongQuestions.map((q) => '"${q.question}"').join(', ');
        greeting =
            "Let's review the questions you missed! 📚\n\nYou got these wrong: $topics\n\nWhich one would you like me to explain?";
      }

      setState(() {
        _tutorMessages.add({'role': 'assistant', 'content': greeting});
      });
    }
    setState(() => _showTutor = true);
  }

  Future<void> _sendTutorMessage() async {
    final text = _tutorCtrl.text.trim();
    if (text.isEmpty || _tutorLoading) return;
    _tutorCtrl.clear();

    setState(() {
      _tutorMessages.add({'role': 'user', 'content': text});
      _tutorLoading = true;
    });
    _scrollTutor();

    try {
      final wrongList = widget.questions.where((q) {
        final s = _answers[q.id];
        final c = _correctAnswers[q.id];
        return s != null && c != null && s != c;
      }).map((q) {
        final correctOpt = q.options
            .firstWhere((o) => o.id == _correctAnswers[q.id],
                orElse: () => q.options.first)
            .text;
        final selectedOpt = q.options
            .firstWhere((o) => o.id == _answers[q.id],
                orElse: () => q.options.first)
            .text;
        return '- "${q.question}" (answered: "$selectedOpt", correct: "$correctOpt")';
      }).join('\n');

      final systemContext =
          'You are an AI tutor helping a student review a quiz on "${widget.lessonTitle}". '
          'Score: ${_result?.correct ?? 0}/${_result?.total ?? widget.questions.length}. '
          '${wrongList.isNotEmpty ? "Questions they got wrong:\n$wrongList" : "They got all correct!"} '
          'Be encouraging, concise, and educational.';

      final apiMessages = [
        {'role': 'user', 'content': systemContext},
        ..._tutorMessages.map((m) =>
            {'role': m['role'] as String, 'content': m['content'] as String}),
      ];

      final reply = await AiTutorService.chat(
        messages: apiMessages,
        mode: 'Explain',
      );

      if (!mounted) return;
      setState(() {
        _tutorMessages.add({'role': 'assistant', 'content': reply});
        _tutorLoading = false;
      });
      _scrollTutor();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tutorMessages.add({
          'role': 'assistant',
          'content': 'Sorry, something went wrong. Please try again.',
        });
        _tutorLoading = false;
      });
      _scrollTutor();
    }
  }

  void _scrollTutor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tutorScroll.hasClients) {
        _tutorScroll.animateTo(
          _tutorScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);
    return StudentPageBase(
      title: '📝 Quiz',
      child: Stack(
        children: [
          _buildQuizBody(w),
          if (_showTutor) _buildTutorOverlay(w),
        ],
      ),
    );
  }

  Widget _buildQuizBody(double w) {
    return ListView(
      padding: EdgeInsets.fromLTRB(w * 0.045, 16, w * 0.045, 32),
      children: [
        if (widget.alreadyCompleted && _result == null) ...[
          _CompletedBanner(score: widget.previousScore ?? 100, w: w),
          SizedBox(height: w * 0.02),
        ],
        Text(
          widget.lessonTitle,
          style: TextStyle(
            fontSize: w * 0.033,
            color: Colors.white38,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: w * 0.015),
        Text(
          'Answer all questions below',
          style: TextStyle(
            fontSize: w * 0.042,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: w * 0.04),
        ...widget.questions.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(bottom: w * 0.04),
                child: _QuizCard(
                  index: entry.key,
                  question: entry.value,
                  selectedOptionId: _answers[entry.value.id],
                  correctOptionId: _correctAnswers[entry.value.id],
                  submitted: _submitted,
                  w: w,
                  onSelect: _submitted
                      ? null
                      : (optionId) =>
                          setState(() => _answers[entry.value.id] = optionId),
                ),
              ),
            ),
        if (!_submitted)
          _SubmitButton(
            onPressed: _submitQuiz,
            loading: _submitting,
            answered: _answers.length,
            total: widget.questions.length,
            w: w,
          ),
        if (_submitted && _result != null)
          _ResultCard(
            result: _result!,
            w: w,
            onAskTutor: _openTutor,
          ),
      ],
    );
  }

  // ── AI Tutor slide-up overlay ─────────────────────────────────────────────

  Widget _buildTutorOverlay(double w) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.88),
        child: Column(
          children: [
            // Header bar
            Container(
              padding: EdgeInsets.fromLTRB(w * 0.045, 14, w * 0.03, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1533),
                border: Border(
                  bottom: BorderSide(
                      color: Colors.white.withOpacity(0.08), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: w * 0.1,
                    height: w * 0.1,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9074FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.smart_toy,
                        color: Color(0xFF9074FF), size: 22),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Tutor',
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Text(
                          'Reviewing: ${widget.lessonTitle}',
                          style: TextStyle(
                            fontSize: w * 0.03,
                            color: Colors.white38,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showTutor = false),
                    child: Container(
                      width: w * 0.09,
                      height: w * 0.09,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white70, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _tutorScroll,
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.045, vertical: 12),
                itemCount:
                    _tutorMessages.length + (_tutorLoading ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _tutorMessages.length && _tutorLoading) {
                    return _TypingIndicator(w: w);
                  }
                  final msg = _tutorMessages[i];
                  return _TutorBubble(
                    isUser: msg['role'] == 'user',
                    content: msg['content'] as String,
                    w: w,
                  );
                },
              ),
            ),

            // Input bar
            Container(
              padding:
                  EdgeInsets.fromLTRB(w * 0.045, 10, w * 0.045, 16),
              color: const Color(0xFF1A1533),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: w * 0.13,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: w * 0.04),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: _tutorCtrl,
                        style: TextStyle(
                            color: Colors.white, fontSize: w * 0.038),
                        onSubmitted: (_) => _sendTutorMessage(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Ask about the quiz...',
                          hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: w * 0.038),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                  GestureDetector(
                    onTap: _sendTutorMessage,
                    child: Container(
                      width: w * 0.13,
                      height: w * 0.13,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8A63FF), Color(0xFFA77BFF)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _tutorLoading
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quiz card — green correct / red wrong after submit
// ─────────────────────────────────────────────────────────────────────────────

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.index,
    required this.question,
    required this.selectedOptionId,
    required this.correctOptionId,
    required this.submitted,
    required this.w,
    required this.onSelect,
  });

  final int index;
  final QuizQuestion question;
  final int? selectedOptionId;
  final int? correctOptionId;
  final bool submitted;
  final double w;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    return appCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Q${index + 1}.  ${question.question}',
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              if (submitted &&
                  selectedOptionId != null &&
                  correctOptionId != null) ...[
                SizedBox(width: w * 0.02),
                _StatusBadge(
                  correct: selectedOptionId == correctOptionId,
                  w: w,
                ),
              ],
            ],
          ),
          SizedBox(height: w * 0.03),
          ...question.options.map((opt) {
            final isSelected = selectedOptionId == opt.id;
            final isCorrect =
                correctOptionId != null && correctOptionId == opt.id;

            Color borderColor = Colors.white.withOpacity(0.1);
            Color bgColor = Colors.white.withOpacity(0.05);
            Color textColor = Colors.white70;
            Widget? trailing;

            if (submitted) {
              if (isCorrect) {
                borderColor = const Color(0xFF4ECA8D);
                bgColor = const Color(0xFF4ECA8D).withOpacity(0.12);
                textColor = const Color(0xFF4ECA8D);
                trailing = Icon(Icons.check_circle_rounded,
                    color: const Color(0xFF4ECA8D), size: w * 0.05);
              } else if (isSelected) {
                // Selected but wrong
                borderColor = const Color(0xFFFF6B6B);
                bgColor = const Color(0xFFFF6B6B).withOpacity(0.12);
                textColor = const Color(0xFFFF6B6B);
                trailing = Icon(Icons.cancel_rounded,
                    color: const Color(0xFFFF6B6B), size: w * 0.05);
              }
            } else if (isSelected) {
              borderColor = const Color(0xFFA56BFF);
              bgColor = const Color(0xFFA56BFF).withOpacity(0.12);
              textColor = Colors.white;
            }

            return GestureDetector(
              onTap: onSelect == null ? null : () => onSelect!(opt.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(bottom: w * 0.02),
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04, vertical: w * 0.03),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        opt.text,
                        style: TextStyle(
                          fontSize: w * 0.037,
                          color: textColor,
                          fontWeight: (submitted && isCorrect)
                              ? FontWeight.w600
                              : FontWeight.normal,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.correct, required this.w});
  final bool correct;
  final double w;

  @override
  Widget build(BuildContext context) {
    final color =
        correct ? const Color(0xFF4ECA8D) : const Color(0xFFFF6B6B);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: w * 0.025, vertical: w * 0.008),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        correct ? '✓ Correct' : '✗ Wrong',
        style: TextStyle(
          fontSize: w * 0.028,
          fontWeight: FontWeight.w700,
          color: color,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result card
// ─────────────────────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.w,
    required this.onAskTutor,
  });
  final CompletionResult result;
  final double w;
  final VoidCallback onAskTutor;

  @override
  Widget build(BuildContext context) {
    final isPerfect = result.score == 100;
    return Container(
      margin: EdgeInsets.only(top: w * 0.04),
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPerfect
              ? [
                  const Color(0xFF4ECA8D).withOpacity(0.2),
                  const Color(0xFF4ECA8D).withOpacity(0.05)
                ]
              : [
                  const Color(0xFFA56BFF).withOpacity(0.2),
                  const Color(0xFFA56BFF).withOpacity(0.05)
                ],
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
          Text(isPerfect ? '🎉' : '✅',
              style: TextStyle(
                  fontSize: w * 0.1, decoration: TextDecoration.none)),
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
          SizedBox(height: w * 0.04),

          // ── Ask AI Tutor ──
          GestureDetector(
            onTap: onAskTutor,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04, vertical: w * 0.04),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B3FD9), Color(0xFF9074FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9074FF).withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.smart_toy_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: w * 0.025),
                  Text(
                    isPerfect
                        ? 'Chat with AI Tutor'
                        : 'Review mistakes with AI Tutor',
                    style: TextStyle(
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: w * 0.025),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: w * 0.035),
              ),
              child: Text(
                'Back to Lesson',
                style: TextStyle(
                  fontSize: w * 0.038,
                  color: Colors.white70,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tutor chat bubble
// ─────────────────────────────────────────────────────────────────────────────

class _TutorBubble extends StatelessWidget {
  const _TutorBubble(
      {required this.isUser, required this.content, required this.w});
  final bool isUser;
  final String content;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.03),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: w * 0.045,
              backgroundColor: const Color(0xFF9074FF).withOpacity(0.2),
              child: const Icon(Icons.smart_toy,
                  color: Color(0xFF9074FF), size: 16),
            ),
            SizedBox(width: w * 0.025),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04, vertical: w * 0.03),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF9074FF)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
              ),
              child: isUser
                  ? Text(content,
                      style: TextStyle(
                          fontSize: w * 0.037,
                          color: Colors.white,
                          decoration: TextDecoration.none))
                  : MarkdownBody(
                      data: content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                            fontSize: w * 0.037, color: Colors.white),
                        strong: TextStyle(
                            fontSize: w * 0.037,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                        listBullet: TextStyle(
                            fontSize: w * 0.037, color: Colors.white),
                        code: TextStyle(
                            fontSize: w * 0.033,
                            color: const Color(0xFF74EEFF),
                            backgroundColor: Colors.black26),
                      ),
                    ),
            ),
          ),
          if (isUser) SizedBox(width: w * 0.025),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.w});
  final double w;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.03),
      child: Row(
        children: [
          CircleAvatar(
            radius: w * 0.045,
            backgroundColor: const Color(0xFF9074FF).withOpacity(0.2),
            child: const Icon(Icons.smart_toy,
                color: Color(0xFF9074FF), size: 16),
          ),
          SizedBox(width: w * 0.025),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.04, vertical: w * 0.03),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [_dot(w, 0), _dot(w, 150), _dot(w, 300)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(double w, int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      builder: (_, val, __) => Opacity(
        opacity: val,
        child: Container(
          width: w * 0.018,
          height: w * 0.018,
          margin: EdgeInsets.symmetric(horizontal: w * 0.008),
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reused widgets
// ─────────────────────────────────────────────────────────────────────────────

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
                  decoration: TextDecoration.none),
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
                          strokeWidth: 2, color: Colors.white))
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

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner({required this.score, required this.w});
  final int score;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFF4ECA8D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF4ECA8D).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('✅',
              style:
                  TextStyle(fontSize: 18, decoration: TextDecoration.none)),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(
              'You already completed this quiz with a score of $score%.',
              style: TextStyle(
                  fontSize: w * 0.035,
                  color: const Color(0xFF4ECA8D),
                  decoration: TextDecoration.none),
            ),
          ),
        ],
      ),
    );
  }
}