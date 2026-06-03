import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingOverlay extends StatefulWidget {
  final Widget child;
  const OnboardingOverlay({super.key, required this.child});

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  bool _showOverlay = false;
  int _step = 0;

  final List<_TutorialStep> _steps = [
    _TutorialStep(
      title: 'Welcome to EduVerso! 🌟',
      desc: 'Your all-in-one learning platform. Let me show you around!',
      alignment: Alignment.center,
    ),
    _TutorialStep(
      title: 'Modules 📚',
      desc: 'Tap to explore lessons by subject. Complete them to earn XP!',
      alignment: Alignment.bottomCenter,
      offsetY: -160,
      arrowDir: ArrowDir.down,
    ),
    _TutorialStep(
      title: 'Voice Tutor 🤖',
      desc: 'Ask your AI tutor anything by voice or text. Try it now!',
      alignment: Alignment.bottomCenter,
      offsetY: -160,
      arrowDir: ArrowDir.down,
    ),
    _TutorialStep(
      title: 'Game Arena 🎮',
      desc: 'Play games, earn XP, and climb the leaderboard!',
      alignment: Alignment.bottomCenter,
      offsetY: -100,
      arrowDir: ArrowDir.down,
    ),
    _TutorialStep(
      title: 'Peer Feedback 💬',
      desc: 'View AI-generated feedback from your quizzes here.',
      alignment: Alignment.bottomCenter,
      offsetY: -100,
      arrowDir: ArrowDir.down,
    ),
    _TutorialStep(
      title: 'Your Profile 👤',
      desc: 'Track your level, XP, streak and achievements.',
      alignment: Alignment.topRight,
      offsetY: 80,
      offsetX: -20,
      arrowDir: ArrowDir.up,
    ),
    _TutorialStep(
      title: "You're all set! 🚀",
      desc: 'Start learning, earn XP, and become the top student!',
      alignment: Alignment.center,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  String get _prefKey => 'onboarding_done_$_userId';

  Future<void> _checkFirstTime() async {
  final prefs = await SharedPreferences.getInstance();
  final done = prefs.getBool(_prefKey) ?? false;
  if (done) return;

  // Skip onboarding for existing users (created before today)
  final user = Supabase.instance.client.auth.currentUser;
  if (user != null) {
    final createdAt = DateTime.tryParse(user.createdAt);
    if (createdAt != null) {
      final now = DateTime.now();
      final isNewUser = now.difference(createdAt).inMinutes < 5;
      if (!isNewUser) {
        // Mark as done silently for old users
        await prefs.setBool(_prefKey, true);
        return;
      }
    }
  }

  if (mounted) {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _showOverlay = true);
  }
}

  Future<void> _next() async {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
      setState(() => _showOverlay = false);
    }
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    setState(() => _showOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_showOverlay) return widget.child;
    final step = _steps[_step];
    final size = MediaQuery.of(context).size;
    final isLast = _step == _steps.length - 1;

    return Stack(
      children: [
        widget.child,
        GestureDetector(
          onTap: _next,
          child: Container(
            width: size.width,
            height: size.height,
            color: Colors.black.withOpacity(0.72),
          ),
        ),
        Align(
          alignment: step.alignment,
          child: Transform.translate(
            offset: Offset(step.offsetX, step.offsetY),
            child: GestureDetector(
              onTap: _next,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B4B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFA56BFF).withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA56BFF).withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (step.arrowDir == ArrowDir.up)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('↑',
                            style: TextStyle(
                                color: Color(0xFFA56BFF),
                                fontSize: 24,
                                decoration: TextDecoration.none)),
                      ),
                    Text(step.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.none)),
                    const SizedBox(height: 8),
                    Text(step.desc,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                            decoration: TextDecoration.none)),
                    if (step.arrowDir == ArrowDir.down)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('↓',
                            style: TextStyle(
                                color: Color(0xFFA56BFF),
                                fontSize: 24,
                                decoration: TextDecoration.none)),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(_steps.length, (i) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 4),
                              width: i == _step ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _step
                                    ? const Color(0xFFA56BFF)
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            );
                          }),
                        ),
                        Row(
                          children: [
                            if (!isLast)
                              GestureDetector(
                                onTap: _skip,
                                child: const Text('Skip',
                                    style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 13,
                                        decoration: TextDecoration.none)),
                              ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: _next,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFA56BFF),
                                    Color(0xFF6B8FFF)
                                  ]),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isLast ? '🚀 Start' : 'Next →',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      decoration: TextDecoration.none),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum ArrowDir { up, down }

class _TutorialStep {
  final String title;
  final String desc;
  final Alignment alignment;
  final double offsetX;
  final double offsetY;
  final ArrowDir? arrowDir;

  const _TutorialStep({
    required this.title,
    required this.desc,
    required this.alignment,
    this.offsetX = 0,
    this.offsetY = 0,
    this.arrowDir,
  });
}