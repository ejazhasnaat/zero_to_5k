import 'package:flutter_tts/flutter_tts.dart';
import '../models/audio_settings_model.dart';

enum AudioCueType {
  warmup,
  run,
  walk,
  cooldown,
  halfway,
  complete,
}

class AudioPlaybackEngine {
  final FlutterTts _tts = FlutterTts();
  AudioSettingsModel _settings;

  AudioPlaybackEngine(this._settings) {
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    if (!_settings.enableTTS) return;

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    if (_settings.voice.contains('UK')) {
      await _tts.setLanguage("en-GB");
    } else if (_settings.voice.contains('IN')) {
      await _tts.setLanguage("en-IN");
    }

    final voices = await _tts.getVoices;
    final matchedVoice = voices.firstWhere(
      (v) => v['name'].toString().toLowerCase().contains(_settings.voice.toLowerCase()),
      orElse: () => null,
    );

    if (matchedVoice != null) {
      await _tts.setVoice(matchedVoice);
    }
  }

  Future<void> reloadSettings(AudioSettingsModel newSettings) async {
    _settings = newSettings;
    await stop();
    await _initializeTTS();
  }

  Future<void> speakCue(AudioCueType type) async {
    if (!_settings.enableTTS) return;

    String phrase;
    switch (type) {
      case AudioCueType.warmup:
        phrase = _styled("Start warm-up. Easy pace.");
        break;
      case AudioCueType.run:
        phrase = _styled("Run now!");
        break;
      case AudioCueType.walk:
        phrase = _styled("Walk now!");
        break;
      case AudioCueType.cooldown:
        phrase = _styled("Cooldown. You made it!");
        break;
      case AudioCueType.halfway:
        if (_settings.enableHalfwayCue) {
          phrase = _styled("Halfway there!");
        } else {
          return;
        }
        break;
      case AudioCueType.complete:
        phrase = _styled("Workout complete. Great job!");
        break;
    }

    await _tts.speak(phrase);
  }

  Future<void> speakCountdown(int seconds) async {
    if (!_settings.enableCountdownCue || !_settings.enableTTS) return;
    if (seconds > 0 && seconds <= 5) {
      await _tts.speak(seconds.toString());
    }
  }

  String _styled(String base) {
    switch (_settings.style.toLowerCase()) {
      case 'energetic':
        return "$base Let's crush it!";
      case 'calm':
        return "$base Stay relaxed.";
      default:
        return base;
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  void dispose() {
    _tts.stop();
  }
}

