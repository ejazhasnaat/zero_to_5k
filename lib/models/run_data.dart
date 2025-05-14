import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

part 'run_data.g.dart'; // Needed for Hive codegen

@HiveType(typeId: 3)
class RunData extends HiveObject {
  @HiveField(0)
  final DateTime startTime;

  @HiveField(1)
  final int durationSeconds;

  @HiveField(2)
  final double distanceMeters;

  @HiveField(3)
  final double paceSecondsPerKm;

  @HiveField(4)
  final double caloriesBurned;

  @HiveField(5)
  final List<RoutePoint> route;

  RunData({
    required this.startTime,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.paceSecondsPerKm,
    required this.caloriesBurned,
    required this.route,
  });

  /// ✅ Add this factory for development/testing UI stubbing
  factory RunData.mock({required double userWeightKg}) {
    return RunData(
      startTime: DateTime.now(),
      durationSeconds: 420, // 7 minutes
      distanceMeters: 1500,
      paceSecondsPerKm: 280,
      caloriesBurned: userWeightKg * 1.05, // arbitrary formula
      route: [
        RoutePoint(31.5204, 74.3587),
        RoutePoint(31.5210, 74.3595),
      ],
    );
  }

  factory RunData.fromJson(Map<String, dynamic> json) => RunData(
        startTime: DateTime.parse(json['startTime']),
        durationSeconds: json['durationSeconds'],
        distanceMeters: json['distanceMeters'],
        paceSecondsPerKm: json['paceSecondsPerKm'],
        caloriesBurned: json['caloriesBurned'],
        route: (json['route'] as List<dynamic>)
            .map((p) => RoutePoint(
                  p['lat'],
                  p['lng'],
                ))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'durationSeconds': durationSeconds,
        'distanceMeters': distanceMeters,
        'paceSecondsPerKm': paceSecondsPerKm,
        'caloriesBurned': caloriesBurned,
        'route': route.map((p) => {'lat': p.lat, 'lng': p.lng}).toList(),
      };

  String get formattedPace {
    final minutes = (paceSecondsPerKm ~/ 60).toString().padLeft(2, '0');
    final seconds = (paceSecondsPerKm % 60).toStringAsFixed(0).padLeft(2, '0');
    return "$minutes:$seconds /km";
  }

  String get formattedDistance {
    return (distanceMeters / 1000).toStringAsFixed(2) + " km";
  }

  String get formattedCalories {
    return caloriesBurned.toStringAsFixed(0) + " kcal";
  }

  String get formattedDuration {
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  List<Position> get positions => route.map((p) => p.toPosition()).toList();
}

@HiveType(typeId: 4)
class RoutePoint {
  @HiveField(0)
  final double lat;

  @HiveField(1)
  final double lng;

  RoutePoint(this.lat, this.lng);

  Position toPosition() => Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        altitude: 0,
        accuracy: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0, // Required by newer geolocator versions
      );

  static RoutePoint fromPosition(Position p) => RoutePoint(p.latitude, p.longitude);
}

