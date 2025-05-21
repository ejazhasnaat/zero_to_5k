import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/audio_settings_model.dart';

enum AudioCueType {
  warmup,
  run,
  walk,
  cooldown,
  halfway,
  complete,
  start,
  pause,
  resume,
  intervalChange,
}

class AudioPlaybackEngine {
  final FlutterTts _tts = FlutterTts();
  AudioSettingsModel _settings;
  bool _isSpeaking = false;

  AudioPlaybackEngine(this._settings) {
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    if (!_settings.enableTTS) return;

    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(1.0);
      await _tts.setPitch(1.0);
      await _tts.setVolume(_settings.cueVolume);

      if (_settings.voice.contains('UK')) {
        await _tts.setLanguage("en-GB");
      } else if (_settings.voice.contains('IN')) {
        await _tts.setLanguage("en-IN");
      }

      final voices = await _tts.getVoices;
      final matchedVoice = voices.firstWhere(
        (v) => v['name'].toString().toLowerCase().contains(_settings.voice.toLowerCase()),
        orElse: () => <String, dynamic>{},
      );

      if (matchedVoice.isNotEmpty) {
        await _tts.setVoice(matchedVoice);
      }

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
    } catch (e) {
      debugPrint("TTS initialization error: $e");
    }
  }

  Future<void> reloadSettings(AudioSettingsModel newSettings) async {
    _settings = newSettings;
    await stop();
    await _initializeTTS();
  }

  /// New method: Speak any arbitrary text
  Future<void> speak(String text) async {
    if (!_settings.enableTTS) return;

    try {
      await _tts.stop(); // stop any current speech to avoid overlapping
      await _tts.setVolume(_settings.cueVolume);
      _isSpeaking = true;
      await _tts.speak(text);
    } catch (e) {
      debugPrint("TTS speak error: $e");
    }
  }

  Future<void> speakCue(AudioCueType type) async {
    if (!_settings.enableTTS || !_shouldSpeak(type)) return;

    await _tts.stop(); // Prevent overlapping speech

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
        phrase = _styled("Halfway there!");
        break;
      case AudioCueType.complete:
        phrase = _styled("Workout complete. Great job!");
        break;
      case AudioCueType.start:
        phrase = _styled("Let's get started.");
        break;
      case AudioCueType.pause:
        phrase = _styled("Workout paused.");
        break;
      case AudioCueType.resume:
        phrase = _styled("Resuming workout.");
        break;
      case AudioCueType.intervalChange:
        phrase = _styled("Interval change.");
        break;
    }

    try {
      await _tts.setVolume(_settings.cueVolume);
      _isSpeaking = true;
      await _tts.speak(phrase);
    } catch (e) {
      debugPrint("TTS speak error: $e");
    }
  }

  Future<void> speakCountdown(int seconds) async {
    if (!_settings.enableCountdownCue || !_settings.enableTTS) return;
    if (seconds > 0 && seconds <= 5) {
      try {
        await _tts.setVolume(_settings.cueVolume);
        _isSpeaking = true;
        await _tts.speak(seconds.toString());
      } catch (e) {
        debugPrint("TTS countdown error: $e");
      }
    }
  }

  bool _shouldSpeak(AudioCueType type) {
    switch (type) {
      case AudioCueType.halfway:
        return _settings.enableHalfwayCue;
      case AudioCueType.start:
        return _settings.enableStartCue;
      case AudioCueType.pause:
        return _settings.enablePauseCue;
      case AudioCueType.resume:
        return _settings.enableResumeCue;
      case AudioCueType.intervalChange:
        return _settings.enableIntervalChangeCue;
      default:
        return true;
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
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint("TTS stop error: $e");
    }
  }

  Future<void> dispose() async {
    await stop();
  }

  bool get isSpeaking => _isSpeaking;
}

