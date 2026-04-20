import 'package:flutter/material.dart';

import '../models/student_data.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class PeerFeedbackPage extends StatelessWidget {
  const PeerFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return StudentPageBase(
      title: 'Peer Feedback',
      child: ListView(
        padding: EdgeInsets.fromLTRB(w * 0.045, 12, w * 0.045, 18),
        children: [
          Row(
            children: [
              const Spacer(),
              Container(
                width: w * 0.42,
                height: w * 0.12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: EdgeInsets.symmetric(horizontal: w * 0.035),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Search',
                        style: TextStyle(
                          fontSize: w * 0.04,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.search,
                      color: Colors.white70,
                      size: w * 0.05,
                    ),
                  ],
                ),
              )
            ],
          ),
          SizedBox(height: w * 0.035),
          ...StudentData.peerFeedback.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: w * 0.04),
              child: appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: pill(
                            item.date == '12/10/2025' ? 'General' : 'Feedback',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.date,
                          style: TextStyle(
                            fontSize: w * 0.035,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: w * 0.04),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: w * 0.055,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: w * 0.03),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: w * 0.04,
                        height: 1.45,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: w * 0.035),
                    Text(
                      '⭐⭐⭐⭐⭐',
                      style: TextStyle(fontSize: w * 0.065),
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