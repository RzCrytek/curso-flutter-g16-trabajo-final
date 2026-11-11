import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keyToken = "auth_token";
  static const _keyIsDarkMode = "is_dark_mode";

  Future<void> setToken(String token) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(_keyToken, token);
  }

  Future<String?> getToken() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString(_keyToken);
  }

  Future<void> removeToken() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove(_keyToken);
  }

  Future<void> setIsDarkMode(bool isDarkMode) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setBool(_keyIsDarkMode, isDarkMode);
  }

  Future<bool> getIsDarkMode() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(_keyIsDarkMode) ?? false;
  }
}
