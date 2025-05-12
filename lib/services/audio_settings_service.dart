import 'package:flutter/foundation.dart';
import '../helpers/settings_helper.dart';
import '../models/audio_settings_model.dart';

class AudioSettingsService extends ChangeNotifier {
  static const _keyEnableTTS = 'enableTTS';
  static const _keyVoice = 'voice';
  static const _keyStyle = 'style';

  late AudioSettingsModel _settings;

  AudioSettingsModel get settings => _settings;

  AudioSettingsService() {
    _settings = const AudioSettingsModel(); // Default
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = AudioSettingsModel(
      enableTTS: SettingsHelper.getBool(_keyEnableTTS, defaultValue: true),
      voice: SettingsHelper.getString(_keyVoice, defaultValue: 'US Female'),
      style: SettingsHelper.getString(_keyStyle, defaultValue: 'Calm'),
    );
    notifyListeners();
  }

  Future<void> update({bool? enableTTS, String? voice, String? style}) async {
    final newSettings = _settings.copyWith(
      enableTTS: enableTTS ?? _settings.enableTTS,
      voice: voice ?? _settings.voice,
      style: style ?? _settings.style,
    );
    _settings = newSettings;

    await SettingsHelper.setBool(_keyEnableTTS, _settings.enableTTS);
    await SettingsHelper.setString(_keyVoice, _settings.voice);
    await SettingsHelper.setString(_keyStyle, _settings.style);

    notifyListeners();
  }
}

