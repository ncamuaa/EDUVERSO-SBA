import 'package:flutter/material.dart';
import '../services/announcement_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_size.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  AnnouncementResult? _result;
  bool _loading = true;
  String? _error;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AnnouncementService.getAnnouncements(page: page);
      setState(() {
        _result = result;
        _page = page;
      });
    } catch (e) {
      debugPrint('Error loading announcements: $e');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // Tag color based on type
  Color _tagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'feature':     return const Color(0xFF6C3CE1);
      case 'achievement': return const Color(0xFFF59E0B);
      case 'system':      return const Color(0xFFEF4444);
      case 'tips':        return const Color(0xFF10B981);
      default:            return const Color(0xFF6C3CE1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);
    final pagePadding = w * 0.04;
    final totalPages = _result?.totalPages ?? 1;
    final items = _result?.data ?? [];

    return StudentPageBase(
      title: 'Announcements',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA56BFF)),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load announcements',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.redAccent, fontSize: w * 0.032),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => _load(page: _page),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C3CE1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Retry',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: w * 0.038,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📭', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'No announcements yet',
                            style: TextStyle(
                              fontSize: w * 0.04,
                              color: Colors.white38,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFA56BFF),
                      backgroundColor: const Color(0xFF1E1B4B),
                      onRefresh: () => _load(page: _page),
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(pagePadding, 12, pagePadding, 24),
                        itemCount: items.length + 1, // +1 for pagination row
                        separatorBuilder: (_, __) => SizedBox(height: w * 0.03),
                        itemBuilder: (context, index) {
                          // Last item = pagination
                          if (index == items.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: w * 0.03),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _navBtn('◀ Prev',
                                    width: w * 0.22, height: w * 0.11,
                                    fontSize: w * 0.035,
                                    enabled: _page > 1,
                                    onTap: () => _load(page: _page - 1),
                                  ),
                                  SizedBox(width: w * 0.025),
                                  _navBtn('$_page / $totalPages',
                                    width: w * 0.24, height: w * 0.11,
                                    fontSize: w * 0.032,
                                    enabled: false,
                                  ),
                                  SizedBox(width: w * 0.025),
                                  _navBtn('Next ▶',
                                    width: w * 0.22, height: w * 0.11,
                                    fontSize: w * 0.035,
                                    enabled: _page < totalPages,
                                    onTap: () => _load(page: _page + 1),
                                  ),
                                ],
                              ),
                            );
                          }

                          final item = items[index];
                          final tagColor = _tagColor(item.tag);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border(
                                left: BorderSide(color: tagColor, width: 4),
                              ),
                            ),
                            padding: EdgeInsets.all(w * 0.04),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tags + Date row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          // Type tag
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: tagColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.tag,
                                              style: TextStyle(
                                                color: tagColor,
                                                fontSize: w * 0.03,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          // Badge (audience / pinned)
                                          if (item.badge.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6C3CE1).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    item.badge == 'Pinned'
                                                        ? Icons.push_pin_rounded
                                                        : Icons.people_rounded,
                                                    size: w * 0.03,
                                                    color: const Color(0xFFA56BFF),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    item.badge,
                                                    style: TextStyle(
                                                      color: const Color(0xFFA56BFF),
                                                      fontSize: w * 0.03,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(item.createdAt),
                                      style: TextStyle(
                                        fontSize: w * 0.028,
                                        color: Colors.white38,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: w * 0.03),

                                // Title
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: w * 0.045,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),

                                SizedBox(height: w * 0.02),

                                // Body
                                Text(
                                  item.body,
                                  style: TextStyle(
                                    fontSize: w * 0.036,
                                    height: 1.5,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _navBtn(
    String label, {
    required double width,
    required double height,
    required double fontSize,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF6C3CE1).withOpacity(0.3)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? const Color(0xFF6C3CE1).withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: enabled ? Colors.white : Colors.white30,
          ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}