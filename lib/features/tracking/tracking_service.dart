import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/run_data.dart';

class TrackingService {
  final ValueNotifier<RunData?> _runData = ValueNotifier<RunData?>(null);
  ValueNotifier<RunData?> get runData => _runData;

  final List<Position> _positions = [];
  Timer? _timer;
  DateTime? _startTime;
  double _totalDistance = 0.0; // in meters

  final double userWeightKg;
  final double userHeightCm;

  TrackingService({
    required this.userWeightKg,
    required this.userHeightCm,
  });

  Future<void> startTracking() async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) return;

    _startTime = DateTime.now();
    _positions.clear();
    _totalDistance = 0.0;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (_positions.isNotEmpty) {
        final last = _positions.last;
        _totalDistance += Geolocator.distanceBetween(
          last.latitude,
          last.longitude,
          position.latitude,
          position.longitude,
        );
      }

      _positions.add(position);

      final durationSeconds = DateTime.now().difference(_startTime!).inSeconds;
      final pace = durationSeconds > 0
          ? durationSeconds / (_totalDistance / 1000) // sec per km
          : 0.0;

      final speedKmh = _totalDistance / 1000 / (durationSeconds / 3600);
      final calories = _estimateCalories(speedKmh, userWeightKg, durationSeconds);

      _runData.value = RunData(
        startTime: _startTime!,
        durationSeconds: durationSeconds,
        distanceMeters: _totalDistance,
        paceSecondsPerKm: pace,
        caloriesBurned: calories,
        route: _positions.map((p) => RoutePoint.fromPosition(p)).toList(), // ✅ Convert to RoutePoint
      );
    });
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _startTime = null;
  }

  void dispose() {
    _timer?.cancel();
    _runData.dispose();
  }

  double _estimateCalories(double speedKmh, double weightKg, int durationSec) {
    final met = speedKmh < 6
        ? 3.5
        : speedKmh < 8
            ? 6.0
            : speedKmh < 10
                ? 8.3
                : 9.8;
    return (met * 3.5 * weightKg / 200) * (durationSec / 60);
  }

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}

