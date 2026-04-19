import 'package:flutter/material.dart';

import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class GameArenaPage extends StatelessWidget {
  const GameArenaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final games = [
      ('Escape The Program', 'Solve coding puzzles in a neon maze.', const Color(0xFFB04CFF), true),
      ('Guess Game', 'Test your knowledge and earn XP!', const Color(0xFFFFCC29), true),
      ('Coming Soon', 'More games on the way!', const Color(0xFF3657C9), false),
    ];

    return StudentPageBase(
      title: 'Game Arena',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
        children: [
          const Text('🎮 Choose a Game', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 18),
          ...games.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Opacity(
                  opacity: g.$4 ? 1 : .45,
                  child: appCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle, size: 24, color: g.$3),
                            const SizedBox(width: 10),
                            Text(g.$1, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(g.$2, style: const TextStyle(fontSize: 18, color: Colors.white70)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: g.$4 ? () {} : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(.12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: Text(g.$4 ? '▶ Play' : 'Locked', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ))
        ],
      ),
    );
  }
}
