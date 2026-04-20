import 'package:flutter/material.dart';

import '../models/student_data.dart';
import '../theme/app_theme.dart';
import '../utils/app_size.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final item = StudentData.announcements.first;
    final w = AppSize.w(context);

    final pagePadding = w * 0.04;
    final titleFont = w * 0.05;
    final bodyFont = w * 0.036;
    final dateFont = w * 0.032;
    final buttonFont = w * 0.035;

    return StudentPageBase(
      title: 'Announcements',
      child: ListView(
        padding: EdgeInsets.fromLTRB(pagePadding, 12, pagePadding, 18),
        children: [
          appCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          tag(item.tag, const Color(0xFF226BFF)),
                          tag(item.badge, AppTheme.accent2),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.date,
                        style: TextStyle(
                          fontSize: dateFont,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: w * 0.03),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: titleFont,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: w * 0.03),
                Text(
                  item.body,
                  style: TextStyle(
                    fontSize: bodyFont,
                    height: 1.45,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: w * 0.05),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _navBtn(
                '◀ Prev',
                width: w * 0.22,
                height: w * 0.11,
                fontSize: buttonFont,
              ),
              SizedBox(width: w * 0.025),
              _navBtn(
                '1',
                width: w * 0.11,
                height: w * 0.11,
                fontSize: buttonFont,
              ),
              SizedBox(width: w * 0.025),
              _navBtn(
                'Next ▶',
                width: w * 0.22,
                height: w * 0.11,
                fontSize: buttonFont,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navBtn(
    String label, {
    required double width,
    required double height,
    required double fontSize,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}