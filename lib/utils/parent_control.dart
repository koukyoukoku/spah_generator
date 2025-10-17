import 'package:shared_preferences/shared_preferences.dart';

class ParentControlService {
  static const String _passwordKey = 'parent_password';
  static const String _defaultPassword = '1234'; 

  static Future<bool> isPasswordSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_passwordKey);
  }

  static Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey, password);
  }

  static Future<bool> verifyPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString(_passwordKey) ?? _defaultPassword;
    return password == savedPassword;
  }

  static Future<void> clearPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordKey);
  }
}