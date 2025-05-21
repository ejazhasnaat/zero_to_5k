import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/run_data.dart';

class TrackingService {
  static final TrackingService instance = TrackingService._internal();

  factory TrackingService({
    double? userWeightKg,
    double? userHeightCm,
  }) {
    if (userWeightKg != null) instance.userWeightKg = userWeightKg;
    if (userHeightCm != null) instance.userHeightCm = userHeightCm;
    return instance;
  }

  TrackingService._internal();

  final ValueNotifier<RunData?> _runData = ValueNotifier<RunData?>(null);
  ValueNotifier<RunData?> get runData => _runData;

  final List<Position> _positions = [];
  Timer? _timer;
  DateTime? _startTime;

  double _totalDistance = 0.0;
  double userWeightKg = 65.0;
  double userHeightCm = 170.0;

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

      final now = DateTime.now();
      final durationSeconds = now.difference(_startTime!).inSeconds;
      final pace = durationSeconds > 0
          ? durationSeconds / (_totalDistance / 1000)
          : 0.0;

      final speedKmh = _totalDistance / 1000 / (durationSeconds / 3600);
      final calories = _estimateCalories(speedKmh, userWeightKg, durationSeconds);

      _runData.value = RunData(
        startTime: _startTime!,
        endTime: now,
        durationSeconds: durationSeconds,
        distanceMeters: _totalDistance,
        paceSecondsPerKm: pace,
        caloriesBurned: calories,
        route: _positions.map((p) => RoutePoint.fromPosition(p)).toList(),
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

  /// ✅ Get full route as RoutePoint list
  Future<List<RoutePoint>> getRoute() async {
    return _positions.map((p) => RoutePoint.fromPosition(p)).toList();
  }

  /// ✅ Calculate total distance from route (if needed independently)
  double calculateDistance(List<RoutePoint> route) {
    if (route.length < 2) return 0.0;

    double distance = 0.0;
    for (int i = 1; i < route.length; i++) {
      final p1 = route[i - 1];
      final p2 = route[i];
      distance += Geolocator.distanceBetween(
        p1.latitude,
        p1.longitude,
        p2.latitude,
        p2.longitude,
      );
    }
    return distance;
  }

  /// ✅ Estimate average and max speed
  Map<String, double> estimateSpeeds(List<RoutePoint> route, int durationSeconds) {
    final totalDistance = calculateDistance(route);
    final average = totalDistance / 1000 / (durationSeconds / 3600);
    double max = 0.0;

    for (int i = 1; i < route.length; i++) {
      final d = Geolocator.distanceBetween(
        route[i - 1].lat, route[i - 1].lng,
        route[i].lat, route[i].lng,
      );
      final speed = d / 1 / 1000 * 3600; // Assuming 1 sec interval
      if (speed > max) max = speed;
    }

    return {'avg': average, 'max': max};
  }

  /// ✅ Stubbed elevation logic (customize if elevation data available)
  Map<String, double> estimateElevation(List<RoutePoint> route) {
    // Elevation data not available via Position by default
    return {'gain': 0.0, 'loss': 0.0};
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

