import 'package:flutter/foundation.dart'; // For ChangeNotifier
import '../models/audio_settings_model.dart'; // Adjust if your path differs
import '../helpers/settings_helper.dart'; // Ensure this exists

class AudioSettingsService extends ChangeNotifier {
  static const _keyEnableTTS = 'enableTTS';
  static const _keyVoice = 'voice';
  static const _keyStyle = 'style';
  static const _keyHalfwayCue = 'halfwayCue';
  static const _keyCountdownCue = 'countdownCue';

  late AudioSettingsModel _settings;
  AudioSettingsModel get settings => _settings;

  /// New: Assign this externally to let engine react to changes
  void Function(AudioSettingsModel)? onSettingsChanged;

  AudioSettingsService() {
    _settings = const AudioSettingsModel();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = AudioSettingsModel(
      enableTTS: SettingsHelper.getBool(_keyEnableTTS, defaultValue: true),
      voice: SettingsHelper.getString(_keyVoice, defaultValue: 'US Female'),
      style: SettingsHelper.getString(_keyStyle, defaultValue: 'Calm'),
      enableHalfwayCue: SettingsHelper.getBool(_keyHalfwayCue, defaultValue: true),
      enableCountdownCue: SettingsHelper.getBool(_keyCountdownCue, defaultValue: true),
    );
    notifyListeners();
  }

  Future<void> update({
    bool? enableTTS,
    String? voice,
    String? style,
    bool? enableHalfwayCue,
    bool? enableCountdownCue,
  }) async {
    final newSettings = _settings.copyWith(
      enableTTS: enableTTS,
      voice: voice,
      style: style,
      enableHalfwayCue: enableHalfwayCue,
      enableCountdownCue: enableCountdownCue,
    );

    _settings = newSettings;

    await SettingsHelper.setBool(_keyEnableTTS, _settings.enableTTS);
    await SettingsHelper.setString(_keyVoice, _settings.voice);
    await SettingsHelper.setString(_keyStyle, _settings.style);
    await SettingsHelper.setBool(_keyHalfwayCue, _settings.enableHalfwayCue);
    await SettingsHelper.setBool(_keyCountdownCue, _settings.enableCountdownCue);

    onSettingsChanged?.call(_settings); // this is the key line

    notifyListeners();
  }
}

