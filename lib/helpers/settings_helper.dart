import 'package:shared_preferences/shared_preferences.dart';

class SettingsHelper {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs => _prefs;

  // Example typed getters and setters for reuse

  static bool getBool(String key, {required bool defaultValue}) =>
      _prefs.getBool(key) ?? defaultValue;

  static Future<void> setBool(String key, bool value) =>
      _prefs.setBool(key, value);

  static String getString(String key, {required String defaultValue}) =>
      _prefs.getString(key) ?? defaultValue;

  static Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
}
