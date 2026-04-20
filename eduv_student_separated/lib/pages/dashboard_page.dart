import 'package:flutter/material.dart';

import '../models/student_data.dart';
import '../theme/app_theme.dart';
import '../utils/app_size.dart';
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
    final w = AppSize.w(context); // ✅ FIXED

    return AppShell(
      child: Builder(
        builder: (context) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(w * 0.045, 14, w * 0.045, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(.08),
                      minimumSize: Size(w * 0.13, w * 0.13),
                    ),
                    icon: Icon(Icons.menu_rounded,
                        color: Colors.white, size: w * 0.06),
                  ),
                  const Spacer(),
                  const LogoText(),
                  const Spacer(),
                  CircleAvatar(
                    radius: w * 0.06,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person,
                        color: Colors.white, size: w * 0.05),
                  ),
                ],
              ),

              SizedBox(height: w * 0.05),

              /// WELCOME TEXT
              Text(
                'Welcome,',
                style: TextStyle(fontSize: w * 0.055, color: Colors.white70),
              ),
              Text(
                StudentData.name,
                style: TextStyle(
                  fontSize: w * 0.07,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Shape your future, one lesson at a time.',
                style: TextStyle(
                  fontSize: w * 0.038,
                  color: AppTheme.textSoft,
                ),
              ),

              SizedBox(height: w * 0.05),

              /// DAILY FOCUS
              appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Focus',
                      style: TextStyle(
                        fontSize: w * 0.042,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Introduction to Programming',
                      style: TextStyle(
                        fontSize: w * 0.05,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: w * 0.03),
                    Row(
                      children: [
                        Expanded(child: progressBar(0.5)),
                        const SizedBox(width: 8),
                        Text(
                          '50%',
                          style: TextStyle(
                            fontSize: w * 0.038,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: w * 0.04),
                    Container(
                      height: w * 0.28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF071C66), Color(0xFF1558E1)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'INTRODUCTION TO PROGRAMMING',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: w * 0.04,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              SizedBox(height: w * 0.04),

              /// PROGRESS
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
                              fontSize: w * 0.042,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Level 1',
                            style: TextStyle(
                              fontSize: w * 0.055,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '60/100 XP',
                            style: TextStyle(
                              fontSize: w * 0.04,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '🔥 0-day streak',
                            style: TextStyle(
                              fontSize: w * 0.038,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: w * 0.04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '60% to next level',
                            style: TextStyle(
                              fontSize: w * 0.038,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: w * 0.03),
                          progressBar(0.6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: w * 0.05),

              /// GRID
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: w * 0.04,
                mainAxisSpacing: w * 0.04,
                childAspectRatio: 2.5, // slightly tighter
                children: [
                  _homeButton(context, 'Voice Tutor', AppTheme.blue, Icons.mic, const AITutorPage(), w),
                  _homeButton(context, 'Modules', AppTheme.green, Icons.menu_book_rounded, const ModulesPage(), w),
                  _homeButton(context, 'Peer Feedback', const Color(0xFFFF5F98), Icons.forum_outlined, const PeerFeedbackPage(), w),
                  _homeButton(context, 'Game Arena', AppTheme.yellow, Icons.psychology_alt, const GameArenaPage(), w),
                  _homeButton(context, 'Announcement', const Color(0xFF4AA0FF), Icons.campaign_outlined, const AnnouncementsPage(), w),
                  _homeButton(context, 'Settings', const Color(0xFFA175FF), Icons.settings, const SettingsPage(), w),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeButton(BuildContext context, String title, Color color, IconData icon, Widget page, double w) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.03),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: w * 0.045),
                SizedBox(width: w * 0.02),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.032,
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