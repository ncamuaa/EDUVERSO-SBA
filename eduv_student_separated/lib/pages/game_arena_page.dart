import 'package:flutter/material.dart';

import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class GameArenaPage extends StatelessWidget {
  const GameArenaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    final games = [
      (
        'Escape The Program',
        'Solve coding puzzles in a neon maze.',
        const Color(0xFFB04CFF),
        true
      ),
      (
        'Guess Game',
        'Test your knowledge and earn XP!',
        const Color(0xFFFFCC29),
        true
      ),
      (
        'Coming Soon',
        'More games on the way!',
        const Color(0xFF3657C9),
        false
      ),
    ];

    return StudentPageBase(
      title: 'Game Arena',
      child: ListView(
        padding: EdgeInsets.fromLTRB(w * 0.045, 12, w * 0.045, 22),
        children: [
          Text(
            '🎮 Choose a Game',
            style: TextStyle(
              fontSize: w * 0.055,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: w * 0.04),
          ...games.map(
            (g) => Padding(
              padding: EdgeInsets.only(bottom: w * 0.04),
              child: Opacity(
                opacity: g.$4 ? 1 : .45,
                child: appCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: w * 0.045,
                            color: g.$3,
                          ),
                          SizedBox(width: w * 0.025),
                          Expanded(
                            child: Text(
                              g.$1,
                              style: TextStyle(
                                fontSize: w * 0.05,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: w * 0.03),
                      Text(
                        g.$2,
                        style: TextStyle(
                          fontSize: w * 0.04,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: w * 0.045),
                      SizedBox(
                        width: double.infinity,
                        height: w * 0.12,
                        child: ElevatedButton(
                          onPressed: g.$4 ? () {} : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(.12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            g.$4 ? '▶ Play' : 'Locked',
                            style: TextStyle(
                              fontSize: w * 0.045,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}