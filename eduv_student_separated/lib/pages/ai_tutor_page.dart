import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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
  Widget build(BuildContext context) {
    return StudentPageBase(
      title: 'AI Tutor',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              children: [
                appCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('0', style: TextStyle(fontSize: 54, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('XP • Level 1', style: TextStyle(fontSize: 22, color: AppTheme.textSoft)),
                      const SizedBox(height: 16),
                      progressBar(0.0),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: List.generate(labels.length, (i) {
                    final active = i == selected;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 10),
                        child: GestureDetector(
                          onTap: () => setState(() => selected = i),
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFF74EEFF) : Colors.white.withOpacity(.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              labels[i],
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: active ? Colors.black87 : Colors.white),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.smart_toy, color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(18)),
                            child: const Text('Hi Student! Ready to learn?', style: TextStyle(fontSize: 18, color: Colors.white)),
                          ),
                          const SizedBox(height: 8),
                          const Text('8:13 PM', style: TextStyle(fontSize: 14, color: AppTheme.textSoft)),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          Container(
            color: Colors.black12,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            child: Row(
              children: [
                _circleAction(Icons.attach_file),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Speak or type...',
                        hintStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9074FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Send', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                _circleAction(Icons.mic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleAction(IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(18)),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
