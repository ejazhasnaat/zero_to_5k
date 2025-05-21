import 'package:shared_preferences/shared_preferences.dart';

class SettingsHelper {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs => _prefs;

  // ----------- Boolean -----------
  static bool getBool(String key, {required bool defaultValue}) =>
      _prefs.getBool(key) ?? defaultValue;

  static Future<void> setBool(String key, bool value) =>
      _prefs.setBool(key, value);

  // ----------- String -----------
  static String getString(String key, {required String defaultValue}) =>
      _prefs.getString(key) ?? defaultValue;

  static Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  // ----------- Double (NEW) -----------
  static double getDouble(String key, {required double defaultValue}) =>
      _prefs.getDouble(key) ?? defaultValue;

  static Future<void> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
}

