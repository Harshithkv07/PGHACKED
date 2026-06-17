import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/credentials.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';

  // Login with hardcoded credentials
  Future<bool> login(String username, String password) async {
    if (username == Credentials.username && password == Credentials.password) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      return true;
    }
    return false;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }
}
