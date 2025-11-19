import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ Replace this IP address with your Mac’s local IP
  // Run `ipconfig getifaddr en0` (or en1) to get it.
  static const String baseUrl = "http://10.45.13.172:8000";


  /// Signup API
  static Future<bool> signup(String name, String email, String password) async {
    try {
      final url = Uri.parse("$baseUrl/auth/signup");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Signup success: ${response.body}");
        return true;
      } else {
        print("❌ Signup failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Signup error: $e");
      return false;
    }
  }

  /// Login API
  static Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse("$baseUrl/auth/login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Login success: ${response.body}");
        return true;
      } else {
        print("❌ Login failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Login error: $e");
      return false;
    }
  }
}
