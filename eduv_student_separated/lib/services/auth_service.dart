import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl =
      'https://eduverso-sba-production.up.railway.app/api/auth';

  // ✅ In-memory fallback for web
  static String? _cachedToken;
  static Map<String, dynamic>? _cachedUser;

  // =========================
  // LOGIN
  // =========================
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

      // Save to SharedPreferences
      await prefs.setString('token', data['token']);
      await prefs.setString('user', jsonEncode(data['user']));

      // ✅ Also save in memory (works on web)
      _cachedToken = data['token'];
      _cachedUser = Map<String, dynamic>.from(data['user']);

      return data;
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  // =========================
  // GET TOKEN
  // =========================
  static Future<String> getToken() async {
    // Try memory first (web-safe)
    if (_cachedToken != null) return _cachedToken!;

    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    _cachedToken = token;
    return token;
  }

  // =========================
  // GET PROFILE (network)
  // =========================
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
      // Update both caches
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(data['user']));
      _cachedUser = Map<String, dynamic>.from(data['user']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to load profile');
    }
  }

  // =========================
  // GET CACHED USER (instant, no network)
  // =========================
  static Future<Map<String, dynamic>?> getCachedUser() async {
    // Try memory first
    if (_cachedUser != null) return _cachedUser;

    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return null;
    _cachedUser = jsonDecode(userJson);
    return _cachedUser;
  }

  // =========================
  // IS LOGGED IN
  // =========================
  static Future<bool> isLoggedIn() async {
    if (_cachedToken != null) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  // =========================
  // LOGOUT
  // =========================
  static Future<void> logout() async {
    // Clear memory
    _cachedToken = null;
    _cachedUser = null;

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}