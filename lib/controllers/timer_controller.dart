import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/z25k_data.dart';

class TimerController extends ChangeNotifier {
  final Workout workout;
  final FlutterTts tts = FlutterTts();

  List<WorkoutInterval> intervals = [];
  int currentIndex = 0;
  int currentSegmentRemaining = 0;
  int totalElapsedSeconds = 0;
  Timer? _timer;

  bool isRunning = false;
  bool isPaused = false;

  TimerController(this.workout) {
    intervals = workout.getIntervals();
    currentSegmentRemaining = intervals.first.duration;
    _initTTS();
  }

  Future<void> _initTTS() async {
    await tts.setLanguage("en-US"); // Try "en-GB", "en-IN", etc.
    await tts.setPitch(1.0); // 0.5 to 2.0
    await tts.setSpeechRate(0.5); // 0.0 to 1.0
    await tts.setVoice({
      "name": "en-us-x-sfg#male_1-local",
      "locale": "en-US"
    });
    await tts.setVolume(1.0); // 0.0 to 1.0
    await _speakCurrentInterval();
    final voices = await tts.getVoices;
    print(voices);
  }

  WorkoutInterval get currentSegment => intervals[currentIndex];

  int get totalDuration => intervals.fold(0, (sum, i) => sum + i.duration);

  double get progress => totalElapsedSeconds / totalDuration;

  void start() {
    isRunning = true;
    isPaused = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    isPaused = true;
    notifyListeners();
  }

  void resume() {
    start(); // restart the timer
  }

  void stop() {
    _timer?.cancel();
    isRunning = false;
    isPaused = false;
    totalElapsedSeconds = 0;
    currentIndex = 0;
    currentSegmentRemaining = intervals.first.duration;
    notifyListeners();
  }

  Future<void> _speakCurrentInterval() async {
    final type = currentSegment.type;
    String text;

    switch (type) {
      case IntervalType.warmup:
        text = "Start warmup. Easy pace.";
        break;
      case IntervalType.run:
        text = "Run now!";//"Start running";
        break;
      case IntervalType.walk:
        text = "Walk now!";//"Start walking";
        break;
      case IntervalType.cooldown:
        text = "Cooldown. You made it!";
        break;
    }

    await tts.speak(text);
  }

  void _tick() {
    if (!isRunning || isPaused) return;

    if (currentSegmentRemaining > 0) {
      currentSegmentRemaining--;
      totalElapsedSeconds++;
    } else {
      if (currentIndex < intervals.length - 1) {
        currentIndex++;
        currentSegmentRemaining = intervals[currentIndex].duration;
        _speakCurrentInterval();
      } else {
        stop(); // workout complete
      }
    }

    notifyListeners();
  }
}

