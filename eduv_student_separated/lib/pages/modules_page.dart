import 'package:flutter/material.dart';

import '../models/student_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class ModulesPage extends StatelessWidget {
  const ModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return StudentPageBase(
      title: 'Available Modules',
      child: ListView(
        padding: EdgeInsets.fromLTRB(w * 0.045, 14, w * 0.045, 18),
        children: [
          Text(
            '📘 Categorized Topics',
            style: TextStyle(
              fontSize: w * 0.04,
              color: AppTheme.textSoft,
            ),
          ),
          SizedBox(height: w * 0.04),
          ...StudentData.modules.map(
            (module) => Padding(
              padding: EdgeInsets.only(bottom: w * 0.04),
              child: appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: TextStyle(
                        fontSize: w * 0.055,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: w * 0.025),
                    Text(
                      module.description,
                      style: TextStyle(
                        fontSize: w * 0.04,
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: w * 0.025),
                    Text(
                      module.category,
                      style: TextStyle(
                        fontSize: w * 0.038,
                        color: AppTheme.accent2,
                      ),
                    ),
                    SizedBox(height: w * 0.04),
                    SizedBox(
                      width: double.infinity,
                      height: w * 0.12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8A63FF), Color(0xFFA77BFF)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Open',
                            style: TextStyle(
                              fontSize: w * 0.045,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
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