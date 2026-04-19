import 'package:flutter/material.dart';

import '../models/student_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentPageBase(
      title: 'Profile',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          appCard(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: Colors.white.withOpacity(.08),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: const Icon(Icons.person, size: 100, color: Colors.white),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, minimumSize: const Size(180, 54)),
                  child: const Text('Choose Image', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                )
              ],
            ),
          ),
          const SizedBox(height: 18),
          appCard(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(StudentData.name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(height: 8),
                Text('Email: ${StudentData.email}', style: TextStyle(fontSize: 20, color: AppTheme.textSoft)),
                SizedBox(height: 6),
                Text('Section: BSIT 3A', style: TextStyle(fontSize: 18, color: AppTheme.textSoft)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: appCard(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🏆 Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                      SizedBox(height: 14),
                      Text('Level: 1', style: TextStyle(fontSize: 18, color: Colors.white)),
                      Text('Streak: 0 days', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: appCard(
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📊 Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                      SizedBox(height: 14),
                      Text('XP: 60', style: TextStyle(fontSize: 18, color: Colors.white)),
                      Text('Course: BSIT', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
              child: const Text('Logout', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
