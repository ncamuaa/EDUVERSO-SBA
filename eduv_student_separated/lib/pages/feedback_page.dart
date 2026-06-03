import 'package:flutter/material.dart';
import '../services/feedback_service.dart';
import '../utils/app_size.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class PeerFeedbackPage extends StatefulWidget {
  final String userId;
  const PeerFeedbackPage({super.key, required this.userId});
  @override
  State<PeerFeedbackPage> createState() => _PeerFeedbackPageState();
}

class _PeerFeedbackPageState extends State<PeerFeedbackPage> {
  List<FeedbackItem> _feedbackList = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  int _currentPage = 0;

  static const int _perPage = 3;

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
      setState(() {
        _feedbackList = data;
        // Reset to last valid page if items shrank
        final maxPage = _totalPages(data.length) - 1;
        if (_currentPage > maxPage) _currentPage = maxPage < 0 ? 0 : maxPage;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  int _totalPages(int count) => (count / _perPage).ceil().clamp(1, 9999);

  List<FeedbackItem> get _pageItems {
    final start = _currentPage * _perPage;
    final end = (start + _perPage).clamp(0, _feedbackList.length);
    if (start >= _feedbackList.length) return [];
    return _feedbackList.sublist(start, end);
  }

  Future<void> _deleteFeedback(FeedbackItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Feedback',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text(
          'Are you sure you want to delete this feedback? This cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5F57),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FeedbackService.deleteFeedback(feedbackId: item.id);
      _loadFeedback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
        );
      }
    }
  }

  void _showAddFeedbackDialog() {
    final contentCtrl = TextEditingController();
    int rating = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Give Feedback',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Content',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Write your feedback...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Rating',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setDlg(() => rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        i < rating ? '⭐' : '☆',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA56BFF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (contentCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await FeedbackService.createFeedback(
                    userId: widget.userId,
                    content: contentCtrl.text.trim(),
                    rating: rating,
                  );
                  _loadFeedback();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feedback submitted!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);
    final totalPages = _totalPages(_feedbackList.length);

    return StudentPageBase(
      title: 'Peer Feedback',
      actions: [
        IconButton(
          onPressed: _showAddFeedbackDialog,
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        ),
      ],
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA56BFF)))
          : _error != null
              ? Center(
                  child: Text('Error: $_error',
                      style: TextStyle(
                          color: Colors.redAccent, fontSize: w * 0.032),
                      textAlign: TextAlign.center))
              : Column(
                  children: [
                    // ── Search bar ──────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          w * 0.04, 10, w * 0.04, 0),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: w * 0.03),
                        child: Row(
                          children: [
                            const Icon(Icons.search,
                                color: Colors.white54, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Search feedback...',
                                  hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white54),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  _search = val;
                                  _currentPage = 0;
                                  _loadFeedback();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Feedback list (3 per page) ──────────────────────
                    Expanded(
                      child: _feedbackList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('No feedback yet.',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white38)),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _showAddFeedbackDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFA56BFF),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.add,
                                        color: Colors.white, size: 16),
                                    label: const Text('Give Feedback',
                                        style:
                                            TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              padding: EdgeInsets.fromLTRB(
                                  w * 0.04, 0, w * 0.04, 16),
                              children: _pageItems
                                  .map((item) => Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 10),
                                        child: appCard(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: const Text(
                                                        'General',
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                Colors.white)),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                      _formatDate(
                                                          item.createdAt),
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Colors.white54)),
                                                  const SizedBox(width: 8),
                                                  // ── Delete button ──
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _deleteFeedback(item),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                                0xFFFF5F57)
                                                            .withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        border: Border.all(
                                                          color: const Color(
                                                                  0xFFFF5F57)
                                                              .withOpacity(0.4),
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                          Icons.delete_outline,
                                                          color:
                                                              Color(0xFFFF5F57),
                                                          size: 15),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(item.body,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      height: 1.4,
                                                      color: Colors.white70)),
                                              const SizedBox(height: 10),
                                              Text('⭐' * item.rating,
                                                  style: const TextStyle(
                                                      fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                    ),

                    // ── Pagination controls ─────────────────────────────
                    if (_feedbackList.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            w * 0.04, 4, w * 0.04, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Prev button
                            _PageButton(
                              icon: Icons.chevron_left,
                              enabled: _currentPage > 0,
                              onTap: () =>
                                  setState(() => _currentPage--),
                            ),
                            const SizedBox(width: 12),
                            // Page indicator dots
                            ...List.generate(totalPages, (i) {
                              final active = i == _currentPage;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _currentPage = i),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  width: active ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? const Color(0xFFA56BFF)
                                        : Colors.white.withOpacity(0.25),
                                    borderRadius:
                                        BorderRadius.circular(99),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(width: 12),
                            // Next button
                            _PageButton(
                              icon: Icons.chevron_right,
                              enabled: _currentPage < totalPages - 1,
                              onTap: () =>
                                  setState(() => _currentPage++),
                            ),
                          ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Pagination arrow button
// ─────────────────────────────────────────────────────────────────────────────

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFFA56BFF).withOpacity(0.18)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? const Color(0xFFA56BFF).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFFA56BFF) : Colors.white24,
          size: 20,
        ),
      ),
    );
  }
}