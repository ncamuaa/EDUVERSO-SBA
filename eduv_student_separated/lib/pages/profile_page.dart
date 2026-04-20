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
    final w = MediaQuery.of(context).size.width;

    return StudentPageBase(
      title: 'Profile',
      child: ListView(
        padding: EdgeInsets.fromLTRB(w * 0.045, 12, w * 0.045, 18),
        children: [
          /// PROFILE IMAGE
          appCard(
            child: Column(
              children: [
                SizedBox(height: w * 0.03),
                Container(
                  width: w * 0.5,
                  height: w * 0.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(.08),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Icon(
                    Icons.person,
                    size: w * 0.25,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: w * 0.04),
                SizedBox(
                  width: w * 0.5,
                  height: w * 0.12,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Choose Image',
                      style: TextStyle(
                        fontSize: w * 0.04,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: w * 0.04),

          /// USER INFO
          appCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StudentData.name,
                  style: TextStyle(
                    fontSize: w * 0.06,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: w * 0.02),
                Text(
                  'Email: ${StudentData.email}',
                  style: TextStyle(
                    fontSize: w * 0.04,
                    color: AppTheme.textSoft,
                  ),
                ),
                SizedBox(height: w * 0.015),
                Text(
                  'Section: BSIT 3A',
                  style: TextStyle(
                    fontSize: w * 0.038,
                    color: AppTheme.textSoft,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: w * 0.04),

          /// ACHIEVEMENTS + STATS
          Row(
            children: [
              Expanded(
                child: appCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏆 Achievements',
                        style: TextStyle(
                          fontSize: w * 0.045,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: w * 0.03),
                      Text(
                        'Level: 1',
                        style: TextStyle(fontSize: w * 0.04, color: Colors.white),
                      ),
                      Text(
                        'Streak: 0 days',
                        style: TextStyle(fontSize: w * 0.04, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: appCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Stats',
                        style: TextStyle(
                          fontSize: w * 0.045,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: w * 0.03),
                      Text(
                        'XP: 60',
                        style: TextStyle(fontSize: w * 0.04, color: Colors.white),
                      ),
                      Text(
                        'Course: BSIT',
                        style: TextStyle(fontSize: w * 0.04, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: w * 0.05),

          /// LOGOUT BUTTON
          SizedBox(
            height: w * 0.13,
            child: ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}