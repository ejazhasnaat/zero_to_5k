import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class FeedbackSettingsService extends ChangeNotifier {
  static const _keyBeeps = 'beepsEnabled';
  static const _keyVibrate = 'vibrateEnabled';
  static const _keyReminders = 'remindersEnabled';
  static const _keyUnits = 'isMetric';
  static const _keyDisableSleep = 'disableSleep';
  static const _keyHeight = 'height';
  static const _keyWeight = 'weight';

  bool _beepsEnabled = true;
  bool _vibrateEnabled = true;
  bool _remindersEnabled = true;
  bool _isMetric = true;
  bool _disableSleep = false;
  double _height = 170.0; // cm by default
  double _weight = 70.0;  // kg by default

  bool get beepsEnabled => _beepsEnabled;
  bool get vibrateEnabled => _vibrateEnabled;
  bool get remindersEnabled => _remindersEnabled;
  bool get isMetric => _isMetric;
  bool get disableSleep => _disableSleep;
  double get height => _height;
  double get weight => _weight;

  late SharedPreferences _prefs;

  FeedbackSettingsService() {
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    _beepsEnabled = _prefs.getBool(_keyBeeps) ?? true;
    _vibrateEnabled = _prefs.getBool(_keyVibrate) ?? true;
    _remindersEnabled = _prefs.getBool(_keyReminders) ?? true;
    _isMetric = _prefs.getBool(_keyUnits) ?? true;
    _disableSleep = _prefs.getBool(_keyDisableSleep) ?? false;
    _height = _prefs.getDouble(_keyHeight) ?? 170.0;
    _weight = _prefs.getDouble(_keyWeight) ?? 70.0;

    // Apply wakelock state
    WakelockPlus.toggle(enable: _disableSleep);

    notifyListeners();
  }

  Future<void> setBeepsEnabled(bool value) async {
    _beepsEnabled = value;
    await _prefs.setBool(_keyBeeps, value);
    notifyListeners();
  }

  Future<void> setVibrateEnabled(bool value) async {
    _vibrateEnabled = value;
    await _prefs.setBool(_keyVibrate, value);
    notifyListeners();
  }

  Future<void> setRemindersEnabled(bool value) async {
    _remindersEnabled = value;
    await _prefs.setBool(_keyReminders, value);
    notifyListeners();
  }

  Future<void> toggleUnits() async {
    _isMetric = !_isMetric;
    await _prefs.setBool(_keyUnits, _isMetric);
    notifyListeners();
  }

  Future<void> setDisableSleep(bool value) async {
    _disableSleep = value;
    await _prefs.setBool(_keyDisableSleep, value);
    await WakelockPlus.toggle(enable: value);
    notifyListeners();
  }

  Future<void> setHeight(double value) async {
    _height = value;
    await _prefs.setDouble(_keyHeight, value);
    notifyListeners();
  }

  Future<void> setWeight(double value) async {
    _weight = value;
    await _prefs.setDouble(_keyWeight, value);
    notifyListeners();
  }
}

