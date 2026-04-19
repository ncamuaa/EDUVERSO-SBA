import 'package:flutter/material.dart';

import '../models/student_data.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class PeerFeedbackPage extends StatelessWidget {
  const PeerFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentPageBase(
      title: 'Peer Feedback',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        children: [
          Row(
            children: [
              const Spacer(),
              Container(
                width: 170,
                height: 52,
                decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: const Row(
                  children: [
                    Expanded(child: Text('Search', style: TextStyle(fontSize: 18, color: Colors.white70))),
                    Icon(Icons.search, color: Colors.white70)
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 14),
          ...StudentData.peerFeedback.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        pill(item.date == '12/10/2025' ? 'General' : 'Feedback'),
                        const Spacer(),
                        Text(item.date, style: const TextStyle(fontSize: 18, color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 14),
                    Text(item.body, style: const TextStyle(fontSize: 18, height: 1.45, color: Colors.white70)),
                    const SizedBox(height: 16),
                    const Text('⭐⭐⭐⭐⭐', style: TextStyle(fontSize: 30)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
