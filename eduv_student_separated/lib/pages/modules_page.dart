import 'package:flutter/material.dart';

import '../models/student_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class ModulesPage extends StatelessWidget {
  const ModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentPageBase(
      title: 'Available Modules',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
        children: [
          const Text('📘 Categorized Topics', style: TextStyle(fontSize: 18, color: AppTheme.textSoft)),
          const SizedBox(height: 16),
          ...StudentData.modules.map(
            (module) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 10),
                    Text(module.description, style: const TextStyle(fontSize: 18, color: Colors.white70, height: 1.35)),
                    const SizedBox(height: 10),
                    Text(module.category, style: const TextStyle(fontSize: 16, color: AppTheme.accent2)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(colors: [Color(0xFF8A63FF), Color(0xFFA77BFF)]),
                        ),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                          child: const Text('Open', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
