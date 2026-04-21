import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'student_drawer.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, this.showDrawer = false});
  final Widget child;
  final bool showDrawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: showDrawer ? const StudentDrawer() : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.bgTop, AppTheme.bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: DefaultTextStyle(
            style: const TextStyle(decoration: TextDecoration.none),
            child: child,
          ),
        ),
      ),
    );
  }
}