import 'package:shared_preferences/shared_preferences.dart';

class SettingsHelper {
  static SharedPreferences? _prefsInstance;

  static Future<void> init() async {
    _prefsInstance = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _prefs {
    if (_prefsInstance == null) {
      throw Exception('SettingsHelper not initialized. Call SettingsHelper.init() first.');
    }
    return _prefsInstance!;
  }

  // General-purpose getters/setters
  static bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  static String getString(String key, {String defaultValue = ''}) =>
      _prefs.getString(key) ?? defaultValue;

  static Future<void> setBool(String key, bool value) async =>
      await _prefs.setBool(key, value);

  static Future<void> setString(String key, String value) async =>
      await _prefs.setString(key, value);

  // Specific keys
  static const _keyBeeps = 'beepsEnabled';
  static const _keyVibrate = 'vibrateEnabled';
  static const _keyReminders = 'remindersEnabled';
  static const _keyIsMetric = 'isMetric';
  static const _keyDisableSleep = 'disableSleep';

  static bool get beepsEnabled => getBool(_keyBeeps, defaultValue: true);
  static bool get vibrateEnabled => getBool(_keyVibrate, defaultValue: true);
  static bool get remindersEnabled => getBool(_keyReminders, defaultValue: true);
  static bool get isMetric => getBool(_keyIsMetric, defaultValue: true);
  static bool get disableSleep => getBool(_keyDisableSleep, defaultValue: false);

  static Future<void> setBeepsEnabled(bool val) async => await setBool(_keyBeeps, val);
  static Future<void> setVibrateEnabled(bool val) async => await setBool(_keyVibrate, val);
  static Future<void> setRemindersEnabled(bool val) async => await setBool(_keyReminders, val);
  static Future<void> setIsMetric(bool val) async => await setBool(_keyIsMetric, val);
  static Future<void> setDisableSleep(bool val) async => await setBool(_keyDisableSleep, val);
}

