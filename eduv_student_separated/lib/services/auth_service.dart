import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;
  static Map<String, dynamic>? _cachedUser;
  static Map<String, dynamic>? get cachedUser => _cachedUser;

  static const _baseUrl = 'http://localhost:5002';

  // ── Register ──────────────────────────────────────────────────
  static Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String department,
    required String course,
    required String year,
    required String section,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'department': department,
        'course': course,
        'year': year,
        'section': section,
      },
    );

    if (response.user == null) {
      throw Exception('Registration failed. Please try again.');
    }

    await _supabase.from('users').upsert({
      'id': response.user!.id,
      'full_name': fullName,
      'email': email,
      'department': department,
      'course': course,
      'year': year,
      'section': section,
    });
  }

  // ── Login ─────────────────────────────────────────────────────
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Invalid email or password.');
    }

    final profile = await _supabase
        .from('users')
        .select()
        .eq('id', response.user!.id)
        .single();

    _cachedUser = Map<String, dynamic>.from(profile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.setString('user', jsonEncode(_cachedUser));

    // ✅ Update last_login in Express backend (no auth needed)
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/students/update-last-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': response.user!.id}),
      );
    } catch (_) {}
  }

  // ── Logout ────────────────────────────────────────────────────
  static Future<void> logout() async {
    await _supabase.auth.signOut();
    _cachedUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('profile_image_base64');
  }

  // ── Auth check ────────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    return _supabase.auth.currentSession != null;
  }

  // ── Get token ─────────────────────────────────────────────────
  static Future<String> getToken() async {
    return _supabase.auth.currentSession?.accessToken ?? '';
  }

  // ── Get profile ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final profile = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    _cachedUser = Map<String, dynamic>.from(profile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.setString('user', jsonEncode(_cachedUser));
    return _cachedUser!;
  }

  // ── Cached user ───────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getCachedUser() async {
    if (_cachedUser != null) return _cachedUser;

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return null;

    _cachedUser = Map<String, dynamic>.from(jsonDecode(userJson));
    return _cachedUser;
  }

  // ── Update profile ────────────────────────────────────────────
  static Future<void> updateProfile({
    required String fullName,
    String? username,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final updates = {
      'full_name': fullName,
      if (username != null && username.isNotEmpty) 'username': username,
    };

    await _supabase.from('users').update(updates).eq('id', user.id);

    _cachedUser ??= {};
    _cachedUser!.addAll(updates);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.setString('user', jsonEncode(_cachedUser));
  }

  // ── Update phone ──────────────────────────────────────────────
  static Future<void> updatePhone({required String phone}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _supabase.from('users').update({'phone': phone}).eq('id', user.id);

    _cachedUser ??= {};
    _cachedUser!['phone'] = phone;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.setString('user', jsonEncode(_cachedUser));
  }

  // ── Update password ───────────────────────────────────────────
  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ── Update email ──────────────────────────────────────────────
  static Future<void> updateEmail({required String email}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _supabase.auth.updateUser(UserAttributes(email: email));

    _cachedUser ??= {};
    _cachedUser!['email'] = email;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.setString('user', jsonEncode(_cachedUser));
  }
}