import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_data.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_size.dart';
import '../utils/xp_history.dart';
import '../widgets/common_widgets.dart';
import '../widgets/student_page_base.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _profileImageBytes;
  bool _imageLoading = true;
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService.getProfile();
    // Reuse the same future result — no second network call
    _profileFuture.then((data) => _loadProfileImageFromData(data));
  }

  Future<void> _loadProfileImageFromData(Map<String, dynamic> data) async {
    try {
      final dbImage = data['user']?['profileImage'];

      if (dbImage != null && dbImage.toString().isNotEmpty) {
        final bytes = base64Decode(dbImage);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_base64', dbImage);

        if (!mounted) return;

        setState(() {
          _profileImageBytes = bytes;
          _imageLoading = false;
        });

        return;
      }

      // No DB image — fall back to local cache
      final prefs = await SharedPreferences.getInstance();
      final localImage = prefs.getString('profile_image_base64');

      if (!mounted) return;

      setState(() {
        if (localImage != null && localImage.isNotEmpty) {
          _profileImageBytes = base64Decode(localImage);
        }
        _imageLoading = false;
      });
    } catch (e) {
      debugPrint('Profile image load error: $e');

      // On any error, try local cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final localImage = prefs.getString('profile_image_base64');

        if (!mounted) return;

        setState(() {
          if (localImage != null && localImage.isNotEmpty) {
            _profileImageBytes = base64Decode(localImage);
          }
          _imageLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _imageLoading = false);
      }
    }
  }

  Future<void> _chooseImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) return;

      final imageBase64 = base64Encode(bytes);
      final token = await AuthService.getToken();

      final response = await http.put(
        Uri.parse('http://192.168.100.16:5002/api/auth/profile-image'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'profileImage': imageBase64,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_base64', imageBase64);

      if (!mounted) return;

      setState(() {
        _profileImageBytes = bytes;
        _profileFuture = AuthService.getProfile();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile image updated!'),
          backgroundColor: const Color(0xFFA56BFF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to choose image: ${e.toString()}'),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _removeImage() async {
    try {
      final token = await AuthService.getToken();

      await http.put(
        Uri.parse('http://192.168.100.16:5002/api/auth/profile-image'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'profileImage': null,
        }),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_base64');

      if (!mounted) return;

      setState(() {
        _profileImageBytes = null;
        _profileFuture = AuthService.getProfile();
      });
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_base64');

      if (!mounted) return;

      setState(() {
        _profileImageBytes = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = AppSize.w(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final user = snapshot.data?['user'];

        final name = user?['fullName'] ?? StudentData.name;
        final email = user?['email'] ?? StudentData.email;
        final section = user?['section'] ?? 'BSIT 3A';
        final course = user?['course'] ?? 'BSIT';
        final level = user?['level'] ?? 1;
        final streak = user?['streak'] ?? 0;
        final xp = user?['xp'] ?? 0;

        return StudentPageBase(
          title: 'Profile',
          child: ListView(
            padding: EdgeInsets.fromLTRB(w * 0.045, 12, w * 0.045, 18),
            children: [
              appCard(
                child: Column(
                  children: [
                    SizedBox(height: w * 0.03),
                    Container(
                      width: w * 0.42,
                      height: w * 0.42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white.withOpacity(.08),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _imageLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFA56BFF),
                                strokeWidth: 2,
                              ),
                            )
                          : _profileImageBytes != null
                              ? Image.memory(
                                  _profileImageBytes!,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.person,
                                  size: w * 0.2,
                                  color: Colors.white,
                                ),
                    ),
                    SizedBox(height: w * 0.04),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: w * 0.45,
                          height: w * 0.11,
                          child: ElevatedButton(
                            onPressed: _chooseImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white24,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Choose Image',
                              style: TextStyle(
                                fontSize: w * 0.038,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (_profileImageBytes != null) ...[
                          SizedBox(width: w * 0.025),
                          SizedBox(
                            width: w * 0.12,
                            height: w * 0.11,
                            child: ElevatedButton(
                              onPressed: _removeImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.red.withOpacity(.8),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: w * 0.05,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: w * 0.04),

              appCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: w * 0.055,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: w * 0.02),
                    Text(
                      'Email: $email',
                      style: TextStyle(
                        fontSize: w * 0.038,
                        color: AppTheme.textSoft,
                      ),
                    ),
                    SizedBox(height: w * 0.015),
                    Text(
                      'Section: $section',
                      style: TextStyle(
                        fontSize: w * 0.035,
                        color: AppTheme.textSoft,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: w * 0.04),

              Row(
                children: [
                  Expanded(
                    child: appCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏆 Achievements',
                            style: TextStyle(
                              fontSize: w * 0.04,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: w * 0.03),
                          Text(
                            'Level: $level',
                            style: TextStyle(
                              fontSize: w * 0.038,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Streak: $streak days',
                            style: TextStyle(
                              fontSize: w * 0.038,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: appCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 Stats',
                            style: TextStyle(
                              fontSize: w * 0.04,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: w * 0.03),
                          Text(
                            'XP: $xp',
                            style: TextStyle(
                              fontSize: w * 0.038,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Course: $course',
                            style: TextStyle(
                              fontSize: w * 0.038,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: w * 0.04),

              _XpHistoryCard(w: w),

              SizedBox(height: w * 0.05),

              SizedBox(
                height: w * 0.12,
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService.logout();

                    if (!context.mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: w * 0.04,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _XpHistoryCard extends StatefulWidget {
  final double w;

  const _XpHistoryCard({required this.w});

  @override
  State<_XpHistoryCard> createState() => _XpHistoryCardState();
}

class _XpHistoryCardState extends State<_XpHistoryCard> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = XpHistory.getEntries();
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');

      return '${months[dt.month]} ${dt.day}, ${dt.year}  $h:$min';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;

    return appCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '⚡ XP History',
                style: TextStyle(
                  fontSize: w * 0.042,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () {
                  XpHistory.clear().then((_) {
                    if (mounted) {
                      setState(() {
                        _future = XpHistory.getEntries();
                      });
                    }
                  });
                },
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: w * 0.032,
                    color: Colors.white38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: w * 0.03),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFA56BFF),
                    strokeWidth: 2,
                  ),
                );
              }

              final entries = snap.data ?? [];

              if (entries.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: w * 0.04),
                  child: Center(
                    child: Text(
                      'No XP earned yet.\nComplete modules or quizzes to get started!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: w * 0.035,
                        color: AppTheme.textSoft,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => Divider(
                  color: Colors.white12,
                  height: w * 0.04,
                ),
                itemBuilder: (context, i) {
                  final e = entries[i];
                  final xp = (e['xp'] as int?) ?? 0;
                  final reason = (e['reason'] as String?) ?? '';
                  final date = _formatDate((e['timestamp'] as String?) ?? '');

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: w * 0.14,
                        padding: EdgeInsets.symmetric(vertical: w * 0.015),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA56BFF).withOpacity(.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+$xp XP',
                          style: TextStyle(
                            fontSize: w * 0.033,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFA56BFF),
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reason,
                              style: TextStyle(
                                fontSize: w * 0.036,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: w * 0.008),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: w * 0.028,
                                color: AppTheme.textSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}