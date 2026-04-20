import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/app_size.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class AITutorPage extends StatefulWidget {
  const AITutorPage({super.key});

  @override
  State<AITutorPage> createState() => _AITutorPageState();
}

class _AITutorPageState extends State<AITutorPage> {
  final TextEditingController controller = TextEditingController();
  int selected = 0;
  final labels = ['Study', 'Explain', 'Exam', 'Quiz'];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);

    final horizontalPadding = w * 0.045;
    final smallGap = w * 0.02;
    final mediumGap = w * 0.03;

    final xpFont = w * 0.11;
    final levelFont = w * 0.045;
    final tabFont = w * 0.035;
    final bubbleFont = w * 0.04;
    final timeFont = w * 0.03;
    final inputFont = w * 0.04;
    final sendFont = w * 0.04;

    final tabHeight = w * 0.12;
    final avatarRadius = w * 0.06;
    final actionSize = w * 0.12;
    final iconSize = w * 0.06;
    final inputHeight = w * 0.13;
    final sendWidth = w * 0.2;

    return StudentPageBase(
      title: 'AI Tutor',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                12,
              ),
              children: [
                appCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: xpFont,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: smallGap),
                      Text(
                        'XP • Level 1',
                        style: TextStyle(
                          fontSize: levelFont,
                          color: AppTheme.textSoft,
                        ),
                      ),
                      SizedBox(height: mediumGap),
                      progressBar(0.0),
                    ],
                  ),
                ),
                SizedBox(height: mediumGap),
                Row(
                  children: List.generate(labels.length, (i) {
                    final active = i == selected;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i == labels.length - 1 ? 0 : 8,
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => selected = i),
                          child: Container(
                            height: tabHeight,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF74EEFF)
                                  : Colors.white.withOpacity(.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              labels[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: tabFont,
                                fontWeight: FontWeight.w800,
                                color: active ? Colors.black87 : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: w * 0.06),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: w * 0.04,
                              vertical: w * 0.03,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Hi Student! Ready to learn?',
                              style: TextStyle(
                                fontSize: bubbleFont,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: smallGap),
                          Text(
                            '8:13 PM',
                            style: TextStyle(
                              fontSize: timeFont,
                              color: AppTheme.textSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: Colors.black12,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              10,
              horizontalPadding,
              14,
            ),
            child: Row(
              children: [
                _circleAction(Icons.attach_file, actionSize, iconSize),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: inputHeight,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: controller,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: inputFont,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Speak or type...',
                        hintStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: sendWidth,
                  height: inputHeight,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9074FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Send',
                      style: TextStyle(
                        fontSize: sendFont,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _circleAction(Icons.mic, actionSize, iconSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleAction(IconData icon, double size, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}