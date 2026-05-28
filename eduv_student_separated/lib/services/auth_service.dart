import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
 static const String baseUrl = 'http://127.0.0.1:5002/api/auth';

  static String? _cachedToken;
  static Map<String, dynamic>? _cachedUser;

  // ── Register ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

  // ── Login ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _cachedToken = data['token'];
      await prefs.setString('token', _cachedToken!);

      final profileData = await getProfile();
      _cachedUser = Map<String, dynamic>.from(profileData['user']);
      await prefs.setString('user', jsonEncode(_cachedUser));

      return profileData;
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  // ── Token ─────────────────────────────────────────────────────
  static Future<String> getToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken!;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    _cachedToken = token;
    return token;
  }

  // ── Profile (read) ────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      _cachedUser = Map<String, dynamic>.from(data['user']);
      await prefs.setString('user', jsonEncode(_cachedUser));
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load profile');
    }
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

  // ── Auth check ────────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token.isNotEmpty;
  }

  // ── Logout ────────────────────────────────────────────────────
  static Future<void> logout() async {
    _cachedToken = null;
    _cachedUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Update profile ────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? username,
  }) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fullName': fullName,
        if (username != null && username.isNotEmpty) 'username': username,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      _cachedUser ??= {};
      _cachedUser!['fullName'] = fullName;
      if (username != null && username.isNotEmpty) {
        _cachedUser!['username'] = username;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_cachedUser));

      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update profile');
    }
  }

  // ── Update email ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateEmail({
    required String email,
  }) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/email'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      if (data['token'] != null) {
        _cachedToken = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _cachedToken!);
      }

      _cachedUser ??= {};
      _cachedUser!['email'] = email;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_cachedUser));

      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update email');
    }
  }

  // ── Update password ───────────────────────────────────────────
  static Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update password');
    }
  }

  // ── Update phone ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> updatePhone({
    required String phone,
  }) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/phone'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'phone': phone}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      _cachedUser ??= {};
      _cachedUser!['phone'] = phone;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_cachedUser));

      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update phone');
    }
  }
}