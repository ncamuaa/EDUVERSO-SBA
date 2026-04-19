import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Widget appCard({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.card.withOpacity(.92),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(.14), blurRadius: 12, offset: const Offset(0, 8)),
      ],
    ),
    child: child,
  );
}

Widget progressBar(double value) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: LinearProgressIndicator(
      value: value,
      minHeight: 14,
      backgroundColor: Colors.white.withOpacity(.14),
      valueColor: const AlwaysStoppedAnimation(AppTheme.accent2),
    ),
  );
}

Widget pill(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
  );
}

Widget tag(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
  );
}

class LogoText extends StatelessWidget {
  const LogoText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.school, color: Color(0xFFFFD15C), size: 32),
        SizedBox(width: 8),
        Text('EduVerso', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
      ],
    );
  }
}
