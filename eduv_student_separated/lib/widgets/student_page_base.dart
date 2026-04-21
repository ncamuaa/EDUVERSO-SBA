import 'package:flutter/material.dart';

import 'app_shell.dart';

class StudentPageBase extends StatelessWidget {
  const StudentPageBase({super.key, required this.title, required this.child, this.showBack = true});
  final String title;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
              child: Row(
                children: [
                  if (showBack)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('← Back', style: TextStyle(fontSize: 22, color: Colors.white, decoration: TextDecoration.none)),
                    )
                  else
                    const SizedBox(width: 76),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, decoration: TextDecoration.none),
                    ),
                  ),
                  const SizedBox(width: 76),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}