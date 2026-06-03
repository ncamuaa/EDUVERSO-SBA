import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'onboarding_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/game_progress_service.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_size.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_widgets.dart';
import 'ai_tutor_page.dart';
import 'announcements_page.dart';
import 'feedback_page.dart';
import 'game_arena_page.dart';
import 'lesson_page.dart';
import 'modules_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  late Future<Map<String, dynamic>> _profileFuture;

  Uint8List? _profileImageBytes;

  String _lastModuleTitle = 'No module opened yet';
  String _lastModuleSubject = '';
  bool _hasLastModule = false;
  double _lastModuleProgress = 0.0;
  int? _lastModuleId;
  int? _lastLessonId;
  String _lastLessonTitle = '';

  @override
  void initState() {
    super.initState();

    _profileFuture = _loadProfile();
    AuthService.getToken().then((t) => print('🔑 TOKEN: $t'));
    _profileFuture.then((data) => _loadProfileImageFromData(data));

    _loadLastModule();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    try {
      final freshProfile = await AuthService.getProfile();
      return freshProfile;
    } catch (_) {
      final cached = await AuthService.getCachedUser();
      if (cached != null) return {'user': cached};
      rethrow;
    }
  }

  Future<void> _loadProfileImageFromData(Map<String, dynamic> data) async {
    try {
      final dbImage = data['profileImage'];

      if (dbImage != null && dbImage.toString().isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_base64', dbImage);

        if (!mounted) return;

        setState(() {
          _profileImageBytes = base64Decode(dbImage);
        });

        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final imageBase64 = prefs.getString('profile_image_base64');

      if (!mounted) return;

      setState(() {
        _profileImageBytes = imageBase64 != null && imageBase64.isNotEmpty
            ? base64Decode(imageBase64)
            : null;
      });
    } catch (e) {
      debugPrint('Profile image load error: $e');

      try {
        final prefs = await SharedPreferences.getInstance();
        final imageBase64 = prefs.getString('profile_image_base64');

        if (!mounted) return;

        setState(() {
          _profileImageBytes = imageBase64 != null && imageBase64.isNotEmpty
              ? base64Decode(imageBase64)
              : null;
        });
      } catch (_) {}
    }
  }

  Future<void> _loadLastModule() async {
    final prefs = await SharedPreferences.getInstance();

    print('=== LAST MODULE DEBUG ===');
    print('title: ${prefs.getString('last_module_title')}');
    print('lesson_id: ${prefs.getInt('last_lesson_id')}');
    print('module_id: ${prefs.getInt('last_module_id')}');
    print('=========================');

    final title = prefs.getString('last_module_title');
    final subject = prefs.getString('last_module_subject') ?? '';
    final progress = prefs.getDouble('last_module_progress') ?? 0.0;
    final moduleId = prefs.getInt('last_module_id');
    final lessonId = prefs.getInt('last_lesson_id');
    final lessonTitle = prefs.getString('last_lesson_title') ?? '';

    if (title != null && mounted) {
      setState(() {
        _lastModuleTitle = title;
        _lastModuleSubject = subject;
        _lastModuleProgress = progress;
        _lastModuleId = moduleId;
        _lastLessonId = lessonId;
        _lastLessonTitle = lessonTitle;
        _hasLastModule = true;
      });
    }
  }

  Future<void> _refreshLastModuleProgress() async {
    final moduleId = _lastModuleId;
    if (moduleId == null) return;

    try {
      final token = await AuthService.getToken();
      final res = await http.get(
        Uri.parse('DISABLED'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        final lessons = data['lessons'] as List;
        final total = lessons.length;

        if (total > 0) {
          final completed = lessons.where((l) {
            final lesson = l as Map<String, dynamic>;
            return lesson['completed'] == true || lesson['completed'] == 1;
          }).length;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('last_module_progress', completed / total);
        }
      }
    } catch (_) {}
  }

  Future<void> _goToModules(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ModulesPage()),
    );

    await _loadLastModule();

    if (mounted) {
      try {
        final data = await AuthService.getProfile();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data));

        setState(() {
          _profileFuture = Future.value(data);
        });

        await _loadProfileImageFromData(data);
      } catch (_) {}
    }
  }

  Future<void> _continueLastModule(BuildContext context) async {
    if (_lastLessonId == null) {
      _goToModules(context);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonPage(
          lessonId: _lastLessonId!,
          lessonTitle: _lastLessonTitle,
        ),
      ),
    );

    if (context.mounted) {
      await _loadLastModule();
    }
  }

  Future<void> _refreshProgress() async => _loadLastModule();

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);

    return OnboardingOverlay(
      child: AppShell(
        showDrawer: true,
        child: Builder(
          builder: (context) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(w * 0.04, 12, w * 0.04, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(.08),
                        minimumSize: Size(w * 0.11, w * 0.11),
                        padding: EdgeInsets.zero,
                      ),
                      icon: Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: w * 0.05,
                      ),
                    ),
                    SizedBox(width: w * 0.02),
                    const Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: LogoText(),
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.02),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(),
                            ),
                          );

                          try {
                            final data = await AuthService.getProfile();
                            if (mounted) {
                              setState(() {
                                _profileFuture = Future.value(data);
                              });
                              await _loadProfileImageFromData(data);
                            }
                          } catch (_) {}
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: CircleAvatar(
                          radius: w * 0.055,
                          backgroundColor: Colors.white24,
                          backgroundImage: _profileImageBytes != null
                              ? MemoryImage(_profileImageBytes!)
                              : null,
                          child: _profileImageBytes == null
                              ? Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: w * 0.045,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: w * 0.04),
                FutureBuilder<Map<String, dynamic>>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    final user = snapshot.data;

                    final name = user?['full_name'] ?? 'Student';
                    final xp = (user?['xp'] ?? 0) as int;
                    final level = (user?['level'] ?? 1) as int;
                    final streak = (user?['streak'] ?? 0) as int;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome,',
                          style: TextStyle(
                            fontSize: w * 0.038,
                            color: Colors.white60,
                          ),
                        ),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: w * 0.055,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Shape your future, one lesson at a time.',
                          style: TextStyle(
                            fontSize: w * 0.032,
                            color: AppTheme.textSoft,
                          ),
                        ),
                        SizedBox(height: w * 0.04),
                        appCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Daily Focus',
                                    style: TextStyle(
                                      fontSize: w * 0.035,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white60,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_hasLastModule)
                                    GestureDetector(
                                      onTap: () => _goToModules(context),
                                      child: Text(
                                        'Change',
                                        style: TextStyle(
                                          fontSize: w * 0.03,
                                          color: const Color(0xFFA56BFF),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _lastModuleTitle,
                                style: TextStyle(
                                  fontSize: w * 0.042,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              if (_lastModuleSubject.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _lastModuleSubject,
                                  style: TextStyle(
                                    fontSize: w * 0.03,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                              SizedBox(height: w * 0.025),
                              Row(
                                children: [
                                  Expanded(
                                    child: progressBar(_lastModuleProgress),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(_lastModuleProgress * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: w * 0.032,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: w * 0.03),
                              GestureDetector(
                                onTap: () => _hasLastModule
                                    ? _continueLastModule(context)
                                    : _goToModules(context),
                                child: Container(
                                  height: w * 0.2,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF071C66),
                                        Color(0xFF1558E1),
                                      ],
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: _hasLastModule
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.play_circle_fill,
                                              color: Colors.white70,
                                              size: w * 0.055,
                                            ),
                                            SizedBox(width: w * 0.02),
                                            Flexible(
                                              child: Text(
                                                _lastModuleTitle.toUpperCase(),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: w * 0.033,
                                                  letterSpacing: 0.8,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: w * 0.02),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: w * 0.03,
                                                vertical: w * 0.01,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'Continue →',
                                                style: TextStyle(
                                                  fontSize: w * 0.028,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.menu_book_rounded,
                                              color: Colors.white38,
                                              size: w * 0.07,
                                            ),
                                            SizedBox(height: w * 0.015),
                                            Text(
                                              'Tap to browse modules',
                                              style: TextStyle(
                                                fontSize: w * 0.032,
                                                color: Colors.white38,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: w * 0.03),
                        appCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Progress',
                                      style: TextStyle(
                                        fontSize: w * 0.033,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white60,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Level $level',
                                      style: TextStyle(
                                        fontSize: w * 0.046,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    FutureBuilder<int>(
                                      future: GameProgressService.getXp(),
                                      builder: (_, snap) {
                                        final totalXp = xp + (snap.data ?? 0);
                                        return Text(
                                          '$totalXp XP',
                                          style: TextStyle(
                                            fontSize: w * 0.032,
                                            color: Colors.white70,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '🔥 $streak-day streak',
                                      style: TextStyle(
                                        fontSize: w * 0.032,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: w * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder<int>(
                                      future: GameProgressService.getXp(),
                                      builder: (_, snap) {
                                        final gameXp = snap.data ?? 0;
                                        final totalXp = xp + gameXp;
                                        final pct = (totalXp % 100) / 100;
                                        final pctInt = (pct * 100).toInt();

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$pctInt% to next level',
                                              style: TextStyle(
                                                fontSize: w * 0.03,
                                                color: Colors.white54,
                                              ),
                                            ),
                                            SizedBox(height: w * 0.02),
                                            progressBar(pct),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: w * 0.04),
                        Text(
                          'Quick Access',
                          style: TextStyle(
                            fontSize: w * 0.038,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: w * 0.025),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: w * 0.03,
                          mainAxisSpacing: w * 0.03,
                          childAspectRatio: 2.8,
                          children: [
                            _homeButton(
                              context,
                              'Voice Tutor',
                              AppTheme.blue,
                              Icons.mic,
                              const AITutorPage(),
                              w,
                            ),
                            _homeButtonCallback(
                              context,
                              'Modules',
                              AppTheme.green,
                              Icons.menu_book_rounded,
                              () => _goToModules(context),
                              w,
                            ),
                            _homeButton(
                              context,
                              'Peer Feedback',
                              const Color(0xFFFF5F98),
                              Icons.forum_outlined,
                              const _FeedbackPageWrapper(),
                              w,
                            ),
                            _homeButton(
                              context,
                              'Game Arena',
                              AppTheme.yellow,
                              Icons.psychology_alt,
                              const GameArenaPage(),
                              w,
                            ),
                            _homeButton(
                              context,
                              'Announcement',
                              const Color(0xFF4AA0FF),
                              Icons.campaign_outlined,
                              const AnnouncementsPage(),
                              w,
                            ),
                            _homeButton(
                              context,
                              'Settings',
                              const Color(0xFFA175FF),
                              Icons.settings,
                              const SettingsPage(),
                              w,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _homeButton(
    BuildContext context,
    String title,
    Color color,
    IconData icon,
    Widget page,
    double w,
  ) {
    return _homeButtonCallback(
      context,
      title,
      color,
      icon,
      () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
      w,
    );
  }

  Widget _homeButtonCallback(
    BuildContext context,
    String title,
    Color color,
    IconData icon,
    VoidCallback onTap,
    double w,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: w * 0.04),
                SizedBox(width: w * 0.015),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.03,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackPageWrapper extends StatefulWidget {
  const _FeedbackPageWrapper();

  @override
  State<_FeedbackPageWrapper> createState() => _FeedbackPageWrapperState();
}

class _FeedbackPageWrapperState extends State<_FeedbackPageWrapper> {
  String? _userId;

  @override
  void initState() {
    super.initState();

    AuthService.getCachedUser().then((u) {
      if (mounted) {
        setState(() => _userId = u?['id']?.toString() ?? '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFA56BFF)),
        ),
      );
    }

    return PeerFeedbackPage(userId: _userId!);
  }
}