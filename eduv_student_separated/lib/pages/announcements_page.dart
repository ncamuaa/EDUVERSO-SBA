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
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1}) async {
    setState(() => _loading = true);
    try {
      final result = await AnnouncementService.getAnnouncements(page: page);
      setState(() {
        _result = result;
        _page = page;
      });
    } catch (e) {
      debugPrint('Error loading announcements: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);

    final pagePadding = w * 0.04;
    final titleFont = w * 0.05;
    final bodyFont = w * 0.036;
    final dateFont = w * 0.032;
    final buttonFont = w * 0.035;

    final totalPages = _result?.totalPages ?? 1;
    final item = _result?.data.isNotEmpty == true ? _result!.data.first : null;

    return StudentPageBase(
      title: 'Announcements',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA56BFF)),
            )
          : item == null
              ? Center(
                  child: Text(
                    'No announcements yet.',
                    style: TextStyle(
                      fontSize: w * 0.04,
                      color: Colors.white38,
                    ),
                  ),
                )
              : ListView(
                  padding:
                      EdgeInsets.fromLTRB(pagePadding, 12, pagePadding, 18),
                  children: [
                    appCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    tag(item.tag, const Color(0xFF226BFF)),
                                    tag(item.badge, AppTheme.accent2),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _formatDate(item.createdAt),
                                  style: TextStyle(
                                    fontSize: dateFont,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: w * 0.03),
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: titleFont,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: w * 0.03),
                          Text(
                            item.body,
                            style: TextStyle(
                              fontSize: bodyFont,
                              height: 1.45,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: w * 0.05),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _navBtn(
                          '◀ Prev',
                          width: w * 0.22,
                          height: w * 0.11,
                          fontSize: buttonFont,
                          enabled: _page > 1,
                          onTap: () => _load(page: _page - 1),
                        ),
                        SizedBox(width: w * 0.025),
                        _navBtn(
                          '$_page',
                          width: w * 0.11,
                          height: w * 0.11,
                          fontSize: buttonFont,
                          enabled: false,
                        ),
                        SizedBox(width: w * 0.025),
                        _navBtn(
                          'Next ▶',
                          width: w * 0.22,
                          height: w * 0.11,
                          fontSize: buttonFont,
                          enabled: _page < totalPages,
                          onTap: () => _load(page: _page + 1),
                        ),
                      ],
                    ),
                  ],
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
              ? Colors.white.withOpacity(.12)
              : Colors.white.withOpacity(.04),
          borderRadius: BorderRadius.circular(12),
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
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}