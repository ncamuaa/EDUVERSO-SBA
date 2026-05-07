import 'package:flutter/material.dart';
import '../services/feedback_service.dart';
import '../utils/app_size.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class PeerFeedbackPage extends StatefulWidget {
  final int userId;

  const PeerFeedbackPage({
    super.key,
    required this.userId,
  });

  @override
  State<PeerFeedbackPage> createState() => _PeerFeedbackPageState();
}

class _PeerFeedbackPageState extends State<PeerFeedbackPage> {
  List<FeedbackItem> _feedbackList = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() => _loading = true);
    try {
      final data = await FeedbackService.getFeedback(
        userId: widget.userId,
        search: _search.isEmpty ? null : _search,
      );
      setState(() => _feedbackList = data);
    } catch (e) {
      debugPrint('Error loading feedback: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);

    return StudentPageBase(
      title: 'Peer Feedback',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA56BFF)),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(w * 0.045, 12, w * 0.045, 18),
              children: [
                Row(
                  children: [
                    const Spacer(),
                    SizedBox(
                      width: w * 0.52,
                      height: w * 0.12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: w * 0.035),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                style: TextStyle(
                                  fontSize: w * 0.04,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search',
                                  hintStyle: TextStyle(
                                    fontSize: w * 0.04,
                                    color: Colors.white70,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onChanged: (val) {
                                  _search = val;
                                  _loadFeedback();
                                },
                              ),
                            ),
                            Icon(
                              Icons.search,
                              color: Colors.white70,
                              size: w * 0.05,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: w * 0.035),
                if (_feedbackList.isEmpty && !_loading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: w * 0.2),
                      child: Text(
                        'No feedback yet.',
                        style: TextStyle(
                          fontSize: w * 0.04,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  )
                else
                  ..._feedbackList.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: w * 0.04),
                      child: appCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(child: pill(item.category)),
                                const Spacer(),
                                Text(
                                  _formatDate(item.createdAt),
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
                              '⭐' * item.rating,
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

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}