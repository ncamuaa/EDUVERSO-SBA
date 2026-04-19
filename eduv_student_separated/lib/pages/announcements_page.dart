import 'package:flutter/material.dart';

import '../models/student_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final item = StudentData.announcements.first;

    return StudentPageBase(
      title: 'Announcements',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        children: [
          appCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: tag(item.tag, const Color(0xFF226BFF)),
                    ),
                    const Spacer(),
                    tag(item.badge, AppTheme.accent2),
                    const SizedBox(width: 8),
                    Text(
                      item.date,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.body,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _navBtn('◀ Prev'),
              const SizedBox(width: 10),
              _navBtn('1', small: true),
              const SizedBox(width: 10),
              _navBtn('Next ▶'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navBtn(String label, {bool small = false}) {
    return Container(
      width: small ? 42 : 90,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}