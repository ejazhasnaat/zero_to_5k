import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import '../audio/audio_playback_engine.dart';
import '../data/z25k_data.dart';
import '../models/audio_settings_model.dart';
import '../models/run_data.dart';
import '../features/tracking/tracking_service.dart';
import 'package:vibration/vibration.dart';

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
  bool _isCompleted = false;
  bool _isDisposed = false;

  final DateTime _startTime = DateTime.now();

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
    _isCompleted = false;
    _speakCurrentInterval();
  }

  WorkoutInterval get currentSegment => intervals[currentIndex];

  int get totalDuration => intervals.fold(0, (sum, i) => sum + i.duration);

  double get progress {
    final p = totalElapsedSeconds / totalDuration;
    return p.clamp(0.0, 1.0);
  }

  double get currentSegmentProgress {
    final total = currentSegment.duration;
    if (total == 0) return 0.0;
    final elapsed = currentSegment.duration - currentSegmentRemaining;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  bool get isCompleted => _isCompleted;

  int get elapsedSeconds => totalElapsedSeconds;

  int get remainingSeconds => totalDuration - totalElapsedSeconds;

  List<WorkoutInterval> get segments => intervals;

  void start() {
    if (isRunning && !isPaused) return;

    isRunning = true;
    isPaused = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    audioEngine.speakCue(AudioCueType.warmup);
    _safeNotify();
  }

  void pause() {
    if (!isRunning || isPaused) return;

    _timer?.cancel();
    isPaused = true;
    _safeNotify();
  }

  void resume() {
    if (isRunning && isPaused) {
      isPaused = false;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      _safeNotify();
    }
  }

  void stop() async {
    _timer?.cancel();
    _timer = null;
    isRunning = false;
    isPaused = false;

    if (_isCompleted) {
      final runData = await generateRunData();
      final box = await Hive.openBox<RunData>('run_data');
      await box.add(runData);
    }

    audioEngine.stop();
    _initializeWorkout();
    _safeNotify();
  }

  void _tick() {
    if (!isRunning || isPaused) return;

    if (currentSegmentRemaining <= 5 && currentSegmentRemaining > 0) {
      audioEngine.speakCountdown(currentSegmentRemaining);
    }

    final segmentDuration = currentSegment.duration;
    final halfwayPoint = (segmentDuration / 2).floor();
    if (!halfwaySpoken &&
        currentSegmentRemaining == halfwayPoint &&
        segmentDuration >= 10) {
      audioEngine.speakCue(AudioCueType.halfway);
      halfwaySpoken = true;
    }

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
        _isCompleted = true;
        stop();
        return;
      }
    }

    _safeNotify();
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

  Future<RunData> generateRunData() async {
    final endTime = DateTime.now();
    final durationSeconds = totalElapsedSeconds;
    final routePoints = await TrackingService.instance.getRoute();
    final distanceMeters =
        TrackingService.instance.calculateDistance(routePoints);
    final pace = distanceMeters > 0
        ? durationSeconds / (distanceMeters / 1000)
        : 0;
    final calories = 65.0 * (durationSeconds / 60.0) * 0.1;
    final speeds =
        TrackingService.instance.estimateSpeeds(routePoints, durationSeconds);
    final elevation =
        TrackingService.instance.estimateElevation(routePoints);

    return RunData(
      startTime: _startTime,
      endTime: endTime,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      paceSecondsPerKm: pace.toDouble(),
      caloriesBurned: calories,
      route: routePoints,
      averageSpeedKmh: speeds['avg'],
      maxSpeedKmh: speeds['max'],
      elevationGainMeters: elevation['gain'],
      elevationLossMeters: elevation['loss'],
    );
  }

  void previousSegment() {
    if (currentIndex > 0) {
      currentIndex--;
      currentSegmentRemaining = intervals[currentIndex].duration;
      totalElapsedSeconds = intervals
          .sublist(0, currentIndex)
          .fold(0, (sum, i) => sum + i.duration);
      halfwaySpoken = false;
      _speakCurrentInterval();
      _safeNotify();
    }
  }

  void nextSegment() {
    if (currentIndex < intervals.length - 1) {
      totalElapsedSeconds += currentSegmentRemaining;
      currentIndex++;
      currentSegmentRemaining = intervals[currentIndex].duration;
      halfwaySpoken = false;
      _speakCurrentInterval();
      _safeNotify();
    }
  }

  Future<void> jumpToSegment(int index) async {
    if (index < 0 || index >= intervals.length) return;

    pause();

    currentIndex = index;
    currentSegmentRemaining = intervals[index].duration;
    totalElapsedSeconds =
        intervals.sublist(0, index).fold(0, (sum, i) => sum + i.duration);
    halfwaySpoken = false;

    _speakCurrentInterval();
    await audioEngine.speakCue(AudioCueType.intervalChange);

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 150);
    }

    _safeNotify();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

