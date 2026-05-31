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
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await FeedbackService.getFeedback(
        userId: widget.userId,
        search: _search.isEmpty ? null : _search,
      );
      setState(() => _feedbackList = data);
    } catch (e) {
      debugPrint('Error loading feedback: $e');
      setState(() => _error = e.toString());
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
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: $_error',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: w * 0.032,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(w * 0.04, 10, w * 0.04, 16),
                  children: [
                    // Search bar — full width
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: w * 0.03),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: Colors.white54,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search feedback...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white54,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) {
                                _search = val;
                                _loadFeedback();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_feedbackList.isEmpty && !_loading)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: w * 0.2),
                          child: const Text(
                            'No feedback yet.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._feedbackList.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: appCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category pill + date
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDate(item.createdAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Title
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Body
                                Text(
                                  item.body,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: Colors.white70,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Stars
                                Text(
                                  '⭐' * item.rating,
                                  style: const TextStyle(fontSize: 14),
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