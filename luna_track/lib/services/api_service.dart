import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  // 10.0.2.2 = Android emulator localhost
  // Change to your PC IP (e.g. 192.168.1.x) for real device

  // ── Token storage ─────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // ── Headers ───────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static const Map<String, String> _plainHeaders = {
    'Content-Type': 'application/json',
  };

  // ── Auth ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _plainHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await saveToken(data['token']);
      await saveUserInfo(data['name'] ?? '', data['email'] ?? ''); // ← add
    }
    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _plainHeaders,
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await saveToken(data['token']);
      await saveUserInfo(data['name'] ?? name, data['email'] ?? email); // ← add
    }
    return data;
  }

  // ── Cycle Entries ─────────────────────────────────────────
  static Future<bool> saveEntry(Map<String, dynamic> entry) async {
    final res = await http.post(
      Uri.parse('$baseUrl/entries'),
      headers: await _authHeaders(),
      body: jsonEncode(entry),
    );
    return res.statusCode == 200;
  }

  static Future<List<dynamic>> getAllEntries() async {
    final res = await http.get(
      Uri.parse('$baseUrl/entries'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getEntryByDate(String date) async {
    final res = await http.get(
      Uri.parse('$baseUrl/entries/$date'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  static Future<List<dynamic>> getEntriesInRange(
      String start, String end) async {
    final res = await http.get(
      Uri.parse('$baseUrl/entries/range?start=$start&end=$end'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  static Future<bool> deleteEntry(String date) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/entries/$date'),
      headers: await _authHeaders(),
    );
    return res.statusCode == 204;
  }

  // ── AI Chat ───────────────────────────────────────────────
  static Future<String?> sendChatMessage({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'message': message,
          'history': history,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['message'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save user profile to SharedPreferences
  static Future<void> saveUserInfo(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? '';
  }

  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? '';
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }
}