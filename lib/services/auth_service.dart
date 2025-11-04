import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  /// Signup with backend + local save
  static Future<bool> signup(String name, String email, String password) async {
    try {
      final success = await ApiService.signup(name, email, password);

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);
        await prefs.setString('user_email', email);
        await prefs.setString('user_password', password);
        return true;
      }
    } catch (e) {
      debugPrint('Signup error: $e');
    }
    return false;
  }

  /// Login with backend
  static Future<bool> login(String email, String password) async {
    try {
      final success = await ApiService.login(email, password);
      return success;
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return false;
  }
}
