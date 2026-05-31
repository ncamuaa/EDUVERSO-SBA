import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/lesson_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_size.dart';
import '../services/last_lesson_store.dart';
import '../utils/xp_history.dart';

// ═════════════════════════════════════════════════════════════════════════════
// LESSON PAGE
// ═════════════════════════════════════════════════════════════════════════════

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

class _LessonPageState extends State<LessonPage> with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  LessonDetail? _lesson;
  int _currentSlide = 0;
  bool _showQuiz = false;

  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnim =
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut);

    _load();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSlideProgress() async {
    if (_lesson == null || _lesson!.content.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
 await prefs.setString('last_module_title', _lesson!.moduleTitle); // ← add
  await prefs.setString('last_module_subject', _lesson!.subject);   // ← add
  await prefs.setInt('last_module_id', _lesson!.moduleId);          

    // Save dashboard progress percentage.
    await prefs.setDouble(
      'last_module_progress',
      (_currentSlide + 1) / _lesson!.content.length,
    );

    // Save the exact slide position for this specific lesson.
    // This prevents another lesson, like "Introduction to Microsoft",
    // from reusing the same slide position.
    await prefs.setInt(
      'last_slide_index_${widget.lessonId}',
      _currentSlide,
    );

    // Save the exact lesson to continue later.
    await prefs.setInt('last_lesson_id', widget.lessonId);
    await prefs.setString('last_lesson_title', widget.lessonTitle);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final lesson = await LessonService.getLessonById(widget.lessonId);
      final prefs = await SharedPreferences.getInstance();

      // Load the saved slide only for this specific lesson.
      // Example: Purposive Communication will not open the slide saved
      // for Introduction to Microsoft.
      final savedSlide = prefs.getInt('last_slide_index_${widget.lessonId}') ?? 0;
      final safeSlide = lesson.content.isEmpty
          ? 0
          : savedSlide.clamp(0, lesson.content.length - 1);

      if (!mounted) return;

      LastLessonStore.instance.set(lesson);

      setState(() {
        _lesson = lesson;
        _currentSlide = safeSlide;
        _loading = false;
      });

      await _saveSlideProgress();
      _slideCtrl.forward();
      _animateProgress(_currentSlide);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _animateProgress(int slideIndex) {
    final total = _lesson!.content.length;
    final target = (slideIndex + 1) / total;
    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: target,
    ).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut));
    _progressCtrl
      ..reset()
      ..forward();
  }

  Future<void> _nextSlide() async {
    final lesson = _lesson!;
    final total = lesson.content.length;
    final isLast = _currentSlide == total - 1;

    if (isLast) {
      await _saveSlideProgress();

      if (lesson.quiz.isNotEmpty) {
        await _slideCtrl.reverse();
        setState(() => _showQuiz = true);
        _slideCtrl.forward();
      } else {
        if (mounted) Navigator.pop(context);
      }
      return;
    }

    await _slideCtrl.reverse();
    setState(() => _currentSlide++);
    await _saveSlideProgress();
    _animateProgress(_currentSlide);
    _slideCtrl.forward();
  }

  Future<void> _prevSlide() async {
    if (_currentSlide > 0) {
      await _slideCtrl.reverse();
      setState(() => _currentSlide--);
      await _saveSlideProgress();
      _animateProgress(_currentSlide);
      _slideCtrl.forward();
    }
  }

  Future<void> _backToSlides() async {
    await _slideCtrl.reverse();
    setState(() {
      _showQuiz = false;
      _currentSlide = _lesson!.content.length - 1;
    });
    await _saveSlideProgress();
    _animateProgress(_currentSlide);
    _slideCtrl.forward();
  }

  Future<void> _exitLesson() async {
    await _saveSlideProgress();
    if (mounted) Navigator.pop(context);
  }

  bool get _isLastSlide =>
      _lesson != null && _currentSlide == _lesson!.content.length - 1;

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);

    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0C2E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFA56BFF)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0C2E),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '⚠️',
                style: TextStyle(
                  fontSize: w * 0.12,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: w * 0.04),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: w * 0.038,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: w * 0.04),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA56BFF),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lesson = _lesson!;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0C2E),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: _showQuiz
                ? _QuizSection(
                    w: w,
                    lessonId: widget.lessonId,
                    lessonTitle: widget.lessonTitle,
                    questions: lesson.quiz,
                    alreadyCompleted: lesson.progress.completed,
                    previousScore: lesson.progress.quizScore,
                    onBack: _exitLesson,
                    onBackToSlides: _backToSlides,
                  )
                : Column(
                    children: [
                      _TopBar(
                        w: w,
                        currentSlide: _currentSlide,
                        total: lesson.content.length,
                        progressAnim: _progressAnim,
                        progressCtrl: _progressCtrl,
                        lessonTitle: widget.lessonTitle,
                        onBack: _exitLesson,
                      ),
                      Expanded(
                        child: _SlideCard(
                          block: lesson.content[_currentSlide],
                          slideIndex: _currentSlide,
                          total: lesson.content.length,
                          w: w,
                          lesson: lesson,
                        ),
                      ),
                      _BottomNav(
                        w: w,
                        currentSlide: _currentSlide,
                        total: lesson.content.length,
                        isLastSlide: _isLastSlide,
                        hasQuiz: lesson.quiz.isNotEmpty,
                        alreadyCompleted: lesson.progress.completed,
                        onPrev: _currentSlide > 0 ? _prevSlide : null,
                        onNext: _nextSlide,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.w,
    required this.currentSlide,
    required this.total,
    required this.progressAnim,
    required this.progressCtrl,
    required this.lessonTitle,
    required this.onBack,
  });

  final double w;
  final int currentSlide, total;
  final Animation<double> progressAnim;
  final AnimationController progressCtrl;
  final String lessonTitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.03, w * 0.04, w * 0.02),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: EdgeInsets.all(w * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white60, size: w * 0.05),
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lessonTitle,
                        style: TextStyle(
                          fontSize: w * 0.034,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: w * 0.005),
                    Text('Slide ${currentSlide + 1} of $total',
                        style: TextStyle(
                          fontSize: w * 0.028,
                          color: Colors.white38,
                          decoration: TextDecoration.none,
                        )),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.03, vertical: w * 0.012),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('⚡',
                        style: TextStyle(
                            fontSize: w * 0.032,
                            decoration: TextDecoration.none)),
                    SizedBox(width: w * 0.01),
                    Text('+20 XP',
                        style: TextStyle(
                            fontSize: w * 0.028,
                            color: const Color(0xFFFFD700),
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.03),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: w * 0.022,
              color: Colors.white.withOpacity(0.08),
              child: AnimatedBuilder(
                animation: progressAnim,
                builder: (_, __) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressAnim.value,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF8A63FF), Color(0xFF4ECA8D)]),
                    ),
                  ),
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
// Slide card
// ─────────────────────────────────────────────────────────────────────────────

class _SlideCard extends StatelessWidget {
  const _SlideCard({
    required this.block,
    required this.slideIndex,
    required this.total,
    required this.w,
    required this.lesson,
  });

  final ContentBlock block;
  final int slideIndex, total;
  final double w;
  final LessonDetail lesson;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.045),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: w * 0.02),
          Wrap(
            spacing: w * 0.02,
            runSpacing: w * 0.015,
            children: [
              _chip(lesson.gradeLevel, const Color(0xFF6B8FFF), w),
              _chip(lesson.course, const Color(0xFF4ECA8D), w),
              _chip(lesson.subject, const Color(0xFFA56BFF), w),
            ],
          ),
          SizedBox(height: w * 0.04),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.03, vertical: w * 0.01),
            decoration: BoxDecoration(
              color: const Color(0xFFA56BFF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: const Color(0xFFA56BFF).withOpacity(0.3)),
            ),
            child: Text('SLIDE ${slideIndex + 1}',
                style: TextStyle(
                  fontSize: w * 0.026,
                  color: const Color(0xFFA56BFF),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  decoration: TextDecoration.none,
                )),
          ),
          SizedBox(height: w * 0.03),
          Expanded(
            child: block.type == 'code'
                ? _CodeSlide(
                    code: block.body,
                    language: block.language ?? 'code',
                    w: w)
                : _TextSlide(body: block.body, w: w),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, double w) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: w * 0.025, vertical: w * 0.008),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35), width: 0.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: w * 0.028,
                color: color,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Text slide
// ─────────────────────────────────────────────────────────────────────────────

class _TextSlide extends StatelessWidget {
  const _TextSlide({required this.body, required this.w});
  final String body;
  final double w;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(w * 0.055),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA56BFF).withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _MarkdownContent(text: body, w: w),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Code slide
// ─────────────────────────────────────────────────────────────────────────────

class _CodeSlide extends StatelessWidget {
  const _CodeSlide(
      {required this.code, required this.language, required this.w});
  final String code, language;
  final double w;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF080618),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: const Color(0xFFA56BFF).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA56BFF).withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04, vertical: w * 0.03),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Row(children: [
                    _dot(const Color(0xFFFF5F57)),
                    SizedBox(width: w * 0.015),
                    _dot(const Color(0xFFFFBD2E)),
                    SizedBox(width: w * 0.015),
                    _dot(const Color(0xFF28CA41)),
                  ]),
                  SizedBox(width: w * 0.03),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: w * 0.025, vertical: w * 0.006),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA56BFF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(language,
                        style: TextStyle(
                            fontSize: w * 0.028,
                            color: const Color(0xFFA56BFF),
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Copied!'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                    },
                    child: Icon(Icons.copy_rounded,
                        color: Colors.white38, size: w * 0.042),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.all(w * 0.045),
              child: Text(
                code,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: w * 0.036,
                  color: const Color(0xFFD8C3FF),
                  height: 1.7,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Markdown renderer
// ─────────────────────────────────────────────────────────────────────────────

class _MarkdownContent extends StatelessWidget {
  const _MarkdownContent({required this.text, required this.w});
  final String text;
  final double w;

  @override
  Widget build(BuildContext context) {
    final lines = text.replaceAll('\\n', '\n').split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('## ')) {
          return Padding(
            padding: EdgeInsets.only(bottom: w * 0.025, top: w * 0.005),
            child: Text(line.substring(3),
                style: TextStyle(
                  fontSize: w * 0.052,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                  decoration: TextDecoration.none,
                )),
          );
        }
        if (line.startsWith('- ')) {
          return Padding(
            padding: EdgeInsets.only(bottom: w * 0.018, left: w * 0.01),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: w * 0.008),
                  child: Container(
                    width: w * 0.018,
                    height: w * 0.018,
                    decoration: const BoxDecoration(
                        color: Color(0xFFA56BFF), shape: BoxShape.circle),
                  ),
                ),
                SizedBox(width: w * 0.025),
                Expanded(child: _inlineText(line.substring(2), w)),
              ],
            ),
          );
        }
        if (RegExp(r'^\d\.').hasMatch(line)) {
          final dot = line.indexOf('.');
          final num = line.substring(0, dot + 1);
          final content = line.substring(dot + 1).trim();
          return Padding(
            padding: EdgeInsets.only(bottom: w * 0.018, left: w * 0.01),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(num,
                    style: TextStyle(
                        fontSize: w * 0.036,
                        color: const Color(0xFFA56BFF),
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.none)),
                SizedBox(width: w * 0.02),
                Expanded(child: _inlineText(content, w)),
              ],
            ),
          );
        }
        if (line.isEmpty) return SizedBox(height: w * 0.015);
        return Padding(
          padding: EdgeInsets.only(bottom: w * 0.012),
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
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.white,
          decoration: TextDecoration.none,
        ),
      ));
      last = match.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last)));
    }
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: w * 0.04,
          color: Colors.white.withOpacity(0.85),
          height: 1.55,
          decoration: TextDecoration.none,
        ),
        children: spans,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom nav (slides)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.w,
    required this.currentSlide,
    required this.total,
    required this.isLastSlide,
    required this.hasQuiz,
    required this.alreadyCompleted,
    required this.onPrev,
    required this.onNext,
  });

  final double w;
  final int currentSlide, total;
  final bool isLastSlide, hasQuiz, alreadyCompleted;
  final VoidCallback? onPrev;
  final VoidCallback onNext;

  String get _label {
    if (isLastSlide && hasQuiz) {
      return alreadyCompleted ? '🔁  Retake Quiz' : '🎯  Take Quiz';
    }
    return 'Continue';
  }

  bool get _isQuizButton => isLastSlide && hasQuiz;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.fromLTRB(w * 0.045, w * 0.03, w * 0.045, w * 0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final active = i == currentSlide;
              final done = i < currentSlide;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: w * 0.008),
                width: active ? w * 0.06 : w * 0.02,
                height: w * 0.02,
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFF4ECA8D)
                      : active
                          ? const Color(0xFFA56BFF)
                          : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
          SizedBox(height: w * 0.04),
          Row(
            children: [
              if (onPrev != null)
                GestureDetector(
                  onTap: onPrev,
                  child: Container(
                    width: w * 0.14,
                    height: w * 0.14,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Icon(Icons.arrow_back_rounded,
                        color: Colors.white60, size: w * 0.05),
                  ),
                )
              else
                SizedBox(width: w * 0.14),
              SizedBox(width: w * 0.03),
              Expanded(
                child: GestureDetector(
                  onTap: onNext,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: w * 0.14,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isQuizButton
                            ? const [Color(0xFF8A63FF), Color(0xFF4ECA8D)]
                            : const [Color(0xFF8A63FF), Color(0xFFA77BFF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA56BFF)
                              .withOpacity(_isQuizButton ? 0.45 : 0.35),
                          blurRadius: _isQuizButton ? 24 : 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _label,
                          key: ValueKey(_label),
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// QUIZ SECTION
// ═════════════════════════════════════════════════════════════════════════════

class _QuizSection extends StatefulWidget {
  const _QuizSection({
    required this.w,
    required this.lessonId,
    required this.lessonTitle,
    required this.questions,
    required this.alreadyCompleted,
    required this.previousScore,
    required this.onBack,
    required this.onBackToSlides,
  });

  final double w;
  final int lessonId;
  final String lessonTitle;
  final List<QuizQuestion> questions;
  final bool alreadyCompleted;
  final int? previousScore;
  final VoidCallback onBack;
  final VoidCallback onBackToSlides;

  @override
  State<_QuizSection> createState() => _QuizSectionState();
}

class _QuizSectionState extends State<_QuizSection>
    with TickerProviderStateMixin {
  int _current = 0;
  final Map<int, int> _selectedOptionIds = {};
  CompletionResult? _result;
  bool _submitting = false;
  String? _submitError;

  late AnimationController _cardCtrl;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  late AnimationController _feedbackCtrl;
  late Animation<double> _feedbackScale;

  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();

    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));

    _feedbackCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _feedbackScale =
        CurvedAnimation(parent: _feedbackCtrl, curve: Curves.elasticOut);

    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut));

    _cardCtrl.forward();
    _animateProgress(0);
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _feedbackCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  void _animateProgress(int index) {
    final total = widget.questions.length;
    final target = (index + 1) / total;
    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: target,
    ).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut));
    _progressCtrl
      ..reset()
      ..forward();
  }

  QuizQuestion get _currentQ => widget.questions[_current];
  bool get _answered => _selectedOptionIds.containsKey(_currentQ.id);
  int? get _selectedId => _selectedOptionIds[_currentQ.id];
  bool get _isLast => _current == widget.questions.length - 1;

  void _selectOption(int optionId) {
    if (_answered) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedOptionIds[_currentQ.id] = optionId);
    _feedbackCtrl.forward(from: 0);
  }

  Future<void> _next() async {
    if (!_isLast) {
      await _cardCtrl.reverse();
      setState(() => _current++);
      _animateProgress(_current);
      _cardCtrl.forward();
    } else {
      await _submit();
    }
  }

 Future<void> _submit() async {
  setState(() {
    _submitting = true;
    _submitError = null;
  });
  try {
    final result = await LessonService.completeLesson(
        widget.lessonId, _selectedOptionIds);
    if (!mounted) return;

    if (result.xpGained > 0) {
      await XpHistory.addEntry(
        xp: result.xpGained,
        reason: 'Quiz: ${widget.lessonTitle} (${result.correct}/${result.total} correct)',
      );
    }

    setState(() {
      _result = result;
      _submitting = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _submitError = e.toString().replaceFirst('Exception: ', '');
      _submitting = false;
    });
  }
}

  Future<void> _retake() async {
    await _cardCtrl.reverse();
    setState(() {
      _current = 0;
      _selectedOptionIds.clear();
      _result = null;
      _submitError = null;
    });
    _animateProgress(0);
    _cardCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;

    if (_result != null) {
      return _QuizResultsView(
        w: w,
        result: _result!,
        questions: widget.questions,
        selectedOptionIds: _selectedOptionIds,
        onRetake: _retake,
        onBack: widget.onBack,
      );
    }

    return Column(
      children: [
        // ── Quiz top bar ──────────────────────────────────────────
        _QuizTopBar(
          w: w,
          current: _current,
          total: widget.questions.length,
          progressAnim: _progressAnim,
          progressCtrl: _progressCtrl,
          lessonTitle: widget.lessonTitle,
          onBack: widget.onBack,
        ),

        // ── Submit error banner ───────────────────────────────────
        if (_submitError != null)
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: w * 0.045, vertical: w * 0.02),
            padding: EdgeInsets.all(w * 0.035),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5F57).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFF5F57).withOpacity(0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFFF5F57), size: 18),
                SizedBox(width: w * 0.02),
                Expanded(
                  child: Text(_submitError!,
                      style: TextStyle(
                          fontSize: w * 0.032,
                          color: Colors.white70,
                          decoration: TextDecoration.none)),
                ),
                GestureDetector(
                  onTap: _submit,
                  child: Text('Retry',
                      style: TextStyle(
                          fontSize: w * 0.032,
                          color: const Color(0xFFFF5F57),
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none)),
                ),
              ],
            ),
          ),

        // ── Question card ─────────────────────────────────────────
        Expanded(
          child: FadeTransition(
            opacity: _cardFade,
            child: SlideTransition(
              position: _cardSlide,
              child: _QuestionCard(
                w: w,
                question: _currentQ,
                questionNumber: _current + 1,
                total: widget.questions.length,
                selectedOptionId: _selectedId,
                answered: _answered,
                onSelect: _selectOption,
                feedbackScale: _feedbackScale,
              ),
            ),
          ),
        ),

        // ── Quiz bottom nav ───────────────────────────────────────
        _QuizBottomNav(
          w: w,
          answered: _answered,
          isLast: _isLast,
          submitting: _submitting,
          onNext: _answered && !_submitting ? _next : null,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quiz top bar — matches slide _TopBar exactly, green accent swapped to purple
// ─────────────────────────────────────────────────────────────────────────────

class _QuizTopBar extends StatelessWidget {
  const _QuizTopBar({
    required this.w,
    required this.current,
    required this.total,
    required this.progressAnim,
    required this.progressCtrl,
    required this.lessonTitle,
    required this.onBack,
  });

  final double w;
  final int current, total;
  final Animation<double> progressAnim;
  final AnimationController progressCtrl;
  final String lessonTitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.03, w * 0.04, w * 0.02),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: EdgeInsets.all(w * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white60, size: w * 0.05),
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lessonTitle,
                        style: TextStyle(
                          fontSize: w * 0.034,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: w * 0.005),
                    Text('Question ${current + 1} of $total',
                        style: TextStyle(
                          fontSize: w * 0.028,
                          color: Colors.white38,
                          decoration: TextDecoration.none,
                        )),
                  ],
                ),
              ),
              // ✅ Matches the XP badge style from _TopBar
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.03, vertical: w * 0.012),
                decoration: BoxDecoration(
                  color: const Color(0xFFA56BFF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFA56BFF).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🎯',
                        style: TextStyle(
                            fontSize: w * 0.032,
                            decoration: TextDecoration.none)),
                    SizedBox(width: w * 0.01),
                    Text('Quiz',
                        style: TextStyle(
                            fontSize: w * 0.028,
                            color: const Color(0xFFA56BFF),
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.03),
          // ✅ Same progress bar style as slides — purple→green gradient
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: w * 0.022,
              color: Colors.white.withOpacity(0.08),
              child: AnimatedBuilder(
                animation: progressAnim,
                builder: (_, __) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressAnim.value,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF8A63FF), Color(0xFF4ECA8D)]),
                    ),
                  ),
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
// Question card — frosted glass card matching _TextSlide style
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.w,
    required this.question,
    required this.questionNumber,
    required this.total,
    required this.selectedOptionId,
    required this.answered,
    required this.onSelect,
    required this.feedbackScale,
  });

  final double w;
  final QuizQuestion question;
  final int questionNumber, total;
  final int? selectedOptionId;
  final bool answered;
  final void Function(int) onSelect;
  final Animation<double> feedbackScale;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding:
          EdgeInsets.symmetric(horizontal: w * 0.045, vertical: w * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Badge pill — matches SLIDE X badge from _SlideCard
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.03, vertical: w * 0.01),
            decoration: BoxDecoration(
              color: const Color(0xFFA56BFF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: const Color(0xFFA56BFF).withOpacity(0.3)),
            ),
            child: Text('QUESTION $questionNumber OF $total',
                style: TextStyle(
                  fontSize: w * 0.026,
                  color: const Color(0xFFA56BFF),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  decoration: TextDecoration.none,
                )),
          ),
          SizedBox(height: w * 0.04),

          // ✅ Question text card — same frosted glass as _TextSlide
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(w * 0.055),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA56BFF).withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(question.question,
                style: TextStyle(
                  fontSize: w * 0.044,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.45,
                  decoration: TextDecoration.none,
                )),
          ),
          SizedBox(height: w * 0.04),

          // ✅ Answer saved feedback — purple glow matching slide accent
          if (answered)
            ScaleTransition(
              scale: feedbackScale,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04, vertical: w * 0.03),
                margin: EdgeInsets.only(bottom: w * 0.03),
                decoration: BoxDecoration(
                  color: const Color(0xFFA56BFF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFA56BFF).withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA56BFF).withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text('✅',
                        style: TextStyle(
                            fontSize: w * 0.04,
                            decoration: TextDecoration.none)),
                    SizedBox(width: w * 0.025),
                    Text('Answer saved!',
                        style: TextStyle(
                          fontSize: w * 0.036,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB89FFF),
                          decoration: TextDecoration.none,
                        )),
                  ],
                ),
              ),
            ),

          // Options
          ...question.options.map((opt) => _OptionTile(
                w: w,
                option: opt,
                selectedOptionId: selectedOptionId,
                answered: answered,
                onTap: () => onSelect(opt.id),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Option tile — purple selection matching slide accent colors
// ─────────────────────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.w,
    required this.option,
    required this.selectedOptionId,
    required this.answered,
    required this.onTap,
  });

  final double w;
  final QuizOption option;
  final int? selectedOptionId;
  final bool answered;
  final VoidCallback onTap;

  bool get _isSelected => selectedOptionId == option.id;

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + option.orderIndex);
    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(bottom: w * 0.028),
        padding: EdgeInsets.symmetric(
            horizontal: w * 0.04, vertical: w * 0.038),
        decoration: BoxDecoration(
          // ✅ Selected: purple glow card matching slide selection style
          color: _isSelected
              ? const Color(0xFFA56BFF).withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isSelected
                ? const Color(0xFFA56BFF)
                : Colors.white.withOpacity(0.1),
            width: _isSelected ? 1.5 : 1.0,
          ),
          boxShadow: _isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFA56BFF).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // ✅ Letter circle — same style as slide chips
            Container(
              width: w * 0.09,
              height: w * 0.09,
              decoration: BoxDecoration(
                gradient: _isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF8A63FF), Color(0xFFA77BFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _isSelected
                    ? null
                    : Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(letter,
                    style: TextStyle(
                      fontSize: w * 0.036,
                      fontWeight: FontWeight.w800,
                      color: _isSelected ? Colors.white : Colors.white60,
                      decoration: TextDecoration.none,
                    )),
              ),
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Text(option.text,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight:
                        _isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: _isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.78),
                    height: 1.4,
                    decoration: TextDecoration.none,
                  )),
            ),
            if (_isSelected)
              Container(
                padding: EdgeInsets.all(w * 0.005),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8A63FF), Color(0xFF4ECA8D)],
                  ),
                ),
                child: Icon(Icons.check_rounded,
                    color: Colors.white, size: w * 0.042),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quiz bottom nav — full gradient button always visible, dims when inactive
// ─────────────────────────────────────────────────────────────────────────────

class _QuizBottomNav extends StatelessWidget {
  const _QuizBottomNav({
    required this.w,
    required this.answered,
    required this.isLast,
    required this.submitting,
    required this.onNext,
  });

  final double w;
  final bool answered, isLast, submitting;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final active = onNext != null;
    return Container(
      padding:
          EdgeInsets.fromLTRB(w * 0.045, w * 0.02, w * 0.045, w * 0.05),
      child: GestureDetector(
        onTap: onNext,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: w * 0.14,
          decoration: BoxDecoration(
            // ✅ Matches _BottomNav gradient button exactly
            gradient: LinearGradient(
              colors: active
                  ? (isLast
                      ? const [Color(0xFF8A63FF), Color(0xFF4ECA8D)]
                      : const [Color(0xFF8A63FF), Color(0xFFA77BFF)])
                  : [
                      Colors.white.withOpacity(0.06),
                      Colors.white.withOpacity(0.06),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFFA56BFF)
                          .withOpacity(isLast ? 0.45 : 0.35),
                      blurRadius: isLast ? 24 : 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: submitting
                ? SizedBox(
                    width: w * 0.05,
                    height: w * 0.05,
                    child: const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      isLast ? '🏁  See Results' : 'Next Question',
                      key: ValueKey('$isLast$active'),
                      style: TextStyle(
                        fontSize: w * 0.042,
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : Colors.white24,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// QUIZ RESULTS VIEW
// ═════════════════════════════════════════════════════════════════════════════

class _QuizResultsView extends StatelessWidget {
  const _QuizResultsView({
    required this.w,
    required this.result,
    required this.questions,
    required this.selectedOptionIds,
    required this.onRetake,
    required this.onBack,
  });

  final double w;
  final CompletionResult result;
  final List<QuizQuestion> questions;
  final Map<int, int> selectedOptionIds;
  final VoidCallback onRetake;
  final VoidCallback onBack;

  double get _pct => result.total > 0 ? result.correct / result.total : 0;

  String get _grade {
    if (_pct >= 0.9) return 'S';
    if (_pct >= 0.75) return 'A';
    if (_pct >= 0.6) return 'B';
    if (_pct >= 0.4) return 'C';
    return 'D';
  }

  Color get _gradeColor {
    if (_pct >= 0.9) return const Color(0xFFFFD700);
    if (_pct >= 0.75) return const Color(0xFF4ECA8D);
    if (_pct >= 0.6) return const Color(0xFF8A63FF);
    if (_pct >= 0.4) return const Color(0xFF6B8FFF);
    return const Color(0xFFFF5F57);
  }

  String get _message {
    if (_pct >= 0.9) return 'Outstanding! 🏆';
    if (_pct >= 0.75) return 'Great job! 🎉';
    if (_pct >= 0.6) return 'Good work! 👍';
    if (_pct >= 0.4) return 'Keep going! 💪';
    return 'Review and retry 📚';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ Header matches quiz top bar style
        Container(
          padding:
              EdgeInsets.fromLTRB(w * 0.04, w * 0.03, w * 0.04, w * 0.02),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: EdgeInsets.all(w * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white60, size: w * 0.05),
                ),
              ),
              SizedBox(width: w * 0.03),
              Text('Quiz Results',
                  style: TextStyle(
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  )),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.045, vertical: w * 0.02),
            child: Column(
              children: [
                // ✅ Score card — frosted glass matching TextSlide
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(w * 0.06),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: _gradeColor.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Grade circle with gradient border
                      Container(
                        width: w * 0.28,
                        height: w * 0.28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _gradeColor.withOpacity(0.12),
                          border: Border.all(
                              color: _gradeColor.withOpacity(0.5), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: _gradeColor.withOpacity(0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(_grade,
                              style: TextStyle(
                                fontSize: w * 0.12,
                                fontWeight: FontWeight.w900,
                                color: _gradeColor,
                                decoration: TextDecoration.none,
                              )),
                        ),
                      ),
                      SizedBox(height: w * 0.04),
                      Text(_message,
                          style: TextStyle(
                            fontSize: w * 0.046,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          )),
                      SizedBox(height: w * 0.015),
                      Text('${result.correct} / ${result.total} correct',
                          style: TextStyle(
                            fontSize: w * 0.038,
                            color: Colors.white54,
                            decoration: TextDecoration.none,
                          )),
                      SizedBox(height: w * 0.04),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          height: w * 0.025,
                          color: Colors.white.withOpacity(0.08),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _pct,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  _gradeColor.withOpacity(0.7),
                                  _gradeColor,
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: w * 0.015),
                      Text('${(_pct * 100).round()}%',
                          style: TextStyle(
                            fontSize: w * 0.032,
                            fontWeight: FontWeight.w700,
                            color: _gradeColor,
                            decoration: TextDecoration.none,
                          )),
                    ],
                  ),
                ),
                SizedBox(height: w * 0.04),

                // Stats row
                Row(
                  children: [
                    _StatBox(
                        w: w,
                        label: 'Correct',
                        value: '${result.correct}',
                        color: const Color(0xFF4ECA8D),
                        icon: '✅'),
                    SizedBox(width: w * 0.03),
                    _StatBox(
                        w: w,
                        label: 'Wrong',
                        value: '${result.total - result.correct}',
                        color: const Color(0xFFFF5F57),
                        icon: '❌'),
                    SizedBox(width: w * 0.03),
                    _StatBox(
                        w: w,
                        label: 'XP Earned',
                        value: '+${result.xpGained}',
                        color: const Color(0xFFFFD700),
                        icon: '⚡'),
                  ],
                ),
                SizedBox(height: w * 0.04),

                // Review section header — matches slide badge style
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: w * 0.03, vertical: w * 0.01),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA56BFF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                const Color(0xFFA56BFF).withOpacity(0.3)),
                      ),
                      child: Text('REVIEW',
                          style: TextStyle(
                            fontSize: w * 0.026,
                            color: const Color(0xFFA56BFF),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            decoration: TextDecoration.none,
                          )),
                    ),
                  ],
                ),
                SizedBox(height: w * 0.025),

                // Review items
                ...questions.map((q) {
                  final pickedId = selectedOptionIds[q.id];
                  final correctId = result.correctOptionIds?[q.id];
                  final isCorrect =
                      pickedId != null && pickedId == correctId;
                  final pickedOption = pickedId != null
                      ? q.options
                          .where((o) => o.id == pickedId)
                          .firstOrNull
                      : null;
                  final correctOption = correctId != null
                      ? q.options
                          .where((o) => o.id == correctId)
                          .firstOrNull
                      : null;

                  return Container(
                    margin: EdgeInsets.only(bottom: w * 0.025),
                    padding: EdgeInsets.all(w * 0.04),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? const Color(0xFF4ECA8D).withOpacity(0.07)
                          : const Color(0xFFFF5F57).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCorrect
                            ? const Color(0xFF4ECA8D).withOpacity(0.25)
                            : const Color(0xFFFF5F57).withOpacity(0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isCorrect
                              ? const Color(0xFF4ECA8D).withOpacity(0.06)
                              : const Color(0xFFFF5F57).withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isCorrect ? '✅' : '❌',
                            style: TextStyle(
                                fontSize: w * 0.04,
                                decoration: TextDecoration.none)),
                        SizedBox(width: w * 0.025),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(q.question,
                                  style: TextStyle(
                                    fontSize: w * 0.034,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.4,
                                    decoration: TextDecoration.none,
                                  )),
                              SizedBox(height: w * 0.01),
                              if (isCorrect)
                                Text(
                                  'Correct: ${correctOption?.text ?? "—"}',
                                  style: TextStyle(
                                    fontSize: w * 0.03,
                                    color: const Color(0xFF4ECA8D),
                                    height: 1.4,
                                    decoration: TextDecoration.none,
                                  ),
                                )
                              else ...[
                                Text(
                                  'Your answer: ${pickedOption?.text ?? "—"}',
                                  style: TextStyle(
                                    fontSize: w * 0.03,
                                    color: const Color(0xFFFF5F57)
                                        .withOpacity(0.8),
                                    height: 1.4,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                Text(
                                  'Correct: ${correctOption?.text ?? "—"}',
                                  style: TextStyle(
                                    fontSize: w * 0.03,
                                    color: const Color(0xFF4ECA8D),
                                    height: 1.4,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: w * 0.02),
              ],
            ),
          ),
        ),

        // ✅ Bottom buttons — match _BottomNav style exactly
        Container(
          padding: EdgeInsets.fromLTRB(
              w * 0.045, w * 0.02, w * 0.045, w * 0.05),
          child: Row(
            children: [
              GestureDetector(
                onTap: onRetake,
                child: Container(
                  width: w * 0.14,
                  height: w * 0.14,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Text('🔁',
                        style: TextStyle(
                            fontSize: w * 0.05,
                            decoration: TextDecoration.none)),
                  ),
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: GestureDetector(
                  onTap: onBack,
                  child: Container(
                    height: w * 0.14,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8A63FF), Color(0xFF4ECA8D)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFA56BFF).withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text('Back to Lessons',
                          style: TextStyle(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          )),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat box
// ─────────────────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.w,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final double w;
  final String label, value, icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: w * 0.035, horizontal: w * 0.02),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(icon,
                style: TextStyle(
                    fontSize: w * 0.042, decoration: TextDecoration.none)),
            SizedBox(height: w * 0.012),
            Text(value,
                style: TextStyle(
                  fontSize: w * 0.044,
                  fontWeight: FontWeight.w900,
                  color: color,
                  decoration: TextDecoration.none,
                )),
            SizedBox(height: w * 0.005),
            Text(label,
                style: TextStyle(
                  fontSize: w * 0.026,
                  color: Colors.white38,
                  decoration: TextDecoration.none,
                )),
          ],
        ),
      ),
    );
  }
}