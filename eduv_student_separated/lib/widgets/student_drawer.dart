import 'package:flutter/material.dart';

import '../pages/ai_tutor_page.dart';
import '../pages/announcements_page.dart';
import '../pages/feedback_page.dart';
import '../pages/game_arena_page.dart';
import '../pages/login_page.dart';
import '../pages/modules_page.dart';
import '../pages/profile_page.dart';
import '../pages/settings_page.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class StudentDrawer extends StatelessWidget {
  const StudentDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _DrawerLink('Voice Tutor', Icons.mic, const AITutorPage()),
      _DrawerLink('Modules', Icons.menu_book_rounded, const ModulesPage()),
      _DrawerLink('Peer Feedback', Icons.forum_outlined, const PeerFeedbackPage()),
      _DrawerLink('AI Quiz Arena', Icons.psychology_alt, const GameArenaPage()),
      _DrawerLink('Announcement', Icons.campaign_outlined, const AnnouncementsPage()),
      _DrawerLink('Settings', Icons.settings, const SettingsPage()),
      _DrawerLink('Profile', Icons.person_outline, const ProfilePage()),
    ];

    return Drawer(
      width: MediaQuery.of(context).size.width * .82,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.bgTop, Color(0xFF18045E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: AuthService.getProfile(),
                        builder: (context, snapshot) {
                          final user = snapshot.data?['user'];
                          final name = user?['fullName'] ?? 'Loading...';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Level 1',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.textSoft,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                      ),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...items.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _drawerButton(
                              context,
                              e.label,
                              e.icon,
                              e.page,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _drawerButton(
                  context,
                  'Logout',
                  Icons.logout,
                  const LoginPage(),
                  logout: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerButton(
    BuildContext context,
    String label,
    IconData icon,
    Widget page, {
    bool logout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (logout) {
            await AuthService.logout();

            if (!context.mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => page),
              (_) => false,
            );
          } else {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: logout
                ? const Color(0xFF6F1E4A)
                : Colors.white.withOpacity(.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerLink {
  final String label;
  final IconData icon;
  final Widget page;

  _DrawerLink(this.label, this.icon, this.page);
}