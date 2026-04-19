import 'package:flutter/material.dart';

import '../models/student_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_widgets.dart';
import 'ai_tutor_page.dart';
import 'announcements_page.dart';
import 'feedback_page.dart';
import 'game_arena_page.dart';
import 'modules_page.dart';
import 'settings_page.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: Builder(
        builder: (context) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(.08),
                      minimumSize: const Size(58, 58),
                    ),
                    icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  const LogoText(),
                  const Spacer(),
                  const CircleAvatar(radius: 26, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 22),
              const Text('Welcome,', style: TextStyle(fontSize: 28, color: Colors.white70)),
              const Text(StudentData.name, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Shape your future, one lesson at a time.', style: TextStyle(fontSize: 18, color: AppTheme.textSoft)),
              const SizedBox(height: 18),
              appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daily Focus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white70)),
                    const SizedBox(height: 6),
                    const Text('Introduction to Programming', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: progressBar(0.5)),
                        const SizedBox(width: 10),
                        const Text('50%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(colors: [Color(0xFF071C66), Color(0xFF1558E1)]),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'INTRODUCTION TO PROGRAMMING',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, letterSpacing: 1, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              appCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Your Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white70)),
                          SizedBox(height: 4),
                          Text('Level 1', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                          SizedBox(height: 4),
                          Text('60/100 XP', style: TextStyle(fontSize: 20, color: Colors.white)),
                          SizedBox(height: 8),
                          Text('🔥 0-day streak', style: TextStyle(fontSize: 18, color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('60% to next level', style: TextStyle(fontSize: 18, color: Colors.white70)),
                          const SizedBox(height: 14),
                          progressBar(0.6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.25,
                children: [
                  _homeButton(context, 'Voice Tutor', AppTheme.blue, Icons.mic, const AITutorPage()),
                  _homeButton(context, 'Modules', AppTheme.green, Icons.menu_book_rounded, const ModulesPage()),
                  _homeButton(context, 'Peer Feedback', const Color(0xFFFF5F98), Icons.forum_outlined, const PeerFeedbackPage()),
                  _homeButton(context, 'Game Arena', AppTheme.yellow, Icons.psychology_alt, const GameArenaPage()),
                  _homeButton(context, 'Announcement', const Color(0xFF4AA0FF), Icons.campaign_outlined, const AnnouncementsPage()),
                  _homeButton(context, 'Settings', const Color(0xFFA175FF), Icons.settings, const SettingsPage()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeButton(BuildContext context, String title, Color color, IconData icon, Widget page) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Flexible(
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
