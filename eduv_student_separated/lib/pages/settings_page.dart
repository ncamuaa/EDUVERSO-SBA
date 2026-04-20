import 'package:flutter/material.dart';

import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifications = true;
  bool sound = true;
  bool reducedMotion = false;
  bool darkMode = true;
  int accentIndex = 1;

  final accents = const [
    Color(0xFF6B8FFF),
    Color(0xFFA56BFF),
    Color(0xFFD0A06A),
    Color(0xFF7FC7C9),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return StudentPageBase(
      title: 'Settings',
      child: ListView(
        padding: EdgeInsets.fromLTRB(w * 0.045, 10, w * 0.045, 16),
        children: [
          _switchCard('Notifications', 'Enable reminders', notifications,
              (v) => setState(() => notifications = v), w),
          _switchCard(
              'Sound', 'UI click sounds', sound, (v) => setState(() => sound = v), w),
          _switchCard('Reduced Motion', 'Less animations', reducedMotion,
              (v) => setState(() => reducedMotion = v), w),
          _switchCard('Dark Mode', 'Switch theme', darkMode,
              (v) => setState(() => darkMode = v), w),

          SizedBox(height: w * 0.03),

          /// ACCENT COLORS
          appCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accent Color',
                  style: TextStyle(
                    fontSize: w * 0.045,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: w * 0.03),
                Wrap(
                  spacing: w * 0.03,
                  runSpacing: w * 0.03,
                  children: List.generate(accents.length, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => accentIndex = i),
                      child: Container(
                        width: w * 0.09,
                        height: w * 0.09,
                        decoration: BoxDecoration(
                          color: accents[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i == accentIndex
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          SizedBox(height: w * 0.03),

          /// CHANGE EMAIL
          appCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Email',
                  style: TextStyle(
                    fontSize: w * 0.045,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: w * 0.03),
                Container(
                  height: w * 0.12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: w * 0.03),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w * 0.04,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'New email',
                      hintStyle: TextStyle(
                        color: Colors.white70,
                        fontSize: w * 0.04,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: w * 0.03),
                SizedBox(
                  width: double.infinity,
                  height: w * 0.11,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9E7AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Update Email',
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
        ],
      ),
    );
  }

  Widget _switchCard(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    double w,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.03),
      child: appCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: w * 0.045,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: w * 0.01),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: w * 0.035,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFFD8C3FF),
            ),
          ],
        ),
      ),
    );
  }
}