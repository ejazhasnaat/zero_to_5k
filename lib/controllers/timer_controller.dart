import 'dart:async';
import 'package:flutter/material.dart';
import '../audio/audio_playback_engine.dart';
import '../data/z25k_data.dart';
import '../models/audio_settings_model.dart';

class TimerController extends ChangeNotifier {
  final Workout workout;
  final AudioPlaybackEngine audioEngine;

  late final List<WorkoutInterval> intervals;
  int currentIndex = 0;
  int currentSegmentRemaining = 0;
  int totalElapsedSeconds = 0;
  Timer? _timer;

  bool isRunning = false;
  bool isPaused = false;
  bool halfwaySpoken = false;

  TimerController({
    required this.workout,
    required this.audioEngine,
  }) {
    _initializeWorkout();
  }

  void _initializeWorkout() {
    intervals = workout.getIntervals();
    currentIndex = 0;
    totalElapsedSeconds = 0;
    currentSegmentRemaining = intervals.first.duration;
    halfwaySpoken = false;
    _speakCurrentInterval();
  }

  WorkoutInterval get currentSegment => intervals[currentIndex];

  int get totalDuration => intervals.fold(0, (sum, i) => sum + i.duration);

  double get progress => totalElapsedSeconds / totalDuration;

  void start() {
    if (isRunning && !isPaused) return;

    isRunning = true;
    isPaused = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pause() {
    if (!isRunning || isPaused) return;

    _timer?.cancel();
    isPaused = true;
    notifyListeners();
  }

  void resume() {
    if (isRunning && isPaused) {
      isPaused = false;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      notifyListeners();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    isRunning = false;
    isPaused = false;

    audioEngine.stop();
    _initializeWorkout();
    notifyListeners();
  }

  void _tick() {
    if (!isRunning || isPaused) return;

    // Countdown cue: 5...4...3...2...1
    if (currentSegmentRemaining <= 5 && currentSegmentRemaining > 0) {
      audioEngine.speakCountdown(currentSegmentRemaining);
    }

    // Halfway cue (only once per segment)
    final segmentDuration = currentSegment.duration;
    final halfwayPoint = (segmentDuration / 2).floor();
    if (!halfwaySpoken &&
        currentSegmentRemaining == halfwayPoint &&
        segmentDuration >= 10) {
      audioEngine.speakCue(AudioCueType.halfway);
      halfwaySpoken = true;
    }

    // Countdown logic
    if (currentSegmentRemaining > 0) {
      currentSegmentRemaining--;
      totalElapsedSeconds++;
    } else {
      if (currentIndex < intervals.length - 1) {
        currentIndex++;
        currentSegmentRemaining = intervals[currentIndex].duration;
        halfwaySpoken = false;
        _speakCurrentInterval();
      } else {
        audioEngine.speakCue(AudioCueType.complete);
        stop(); // Ends workout and resets
      }
    }

    notifyListeners();
  }

  void _speakCurrentInterval() {
    switch (currentSegment.type) {
      case IntervalType.warmup:
        audioEngine.speakCue(AudioCueType.warmup);
        break;
      case IntervalType.run:
        audioEngine.speakCue(AudioCueType.run);
        break;
      case IntervalType.walk:
        audioEngine.speakCue(AudioCueType.walk);
        break;
      case IntervalType.cooldown:
        audioEngine.speakCue(AudioCueType.cooldown);
        break;
    }
  }
}

