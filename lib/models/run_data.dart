import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

part 'run_data.g.dart'; // Needed for Hive codegen

@HiveType(typeId: 3)
class RunData extends HiveObject {
  @HiveField(0)
  final DateTime startTime;

  @HiveField(1)
  DateTime endTime;

  @HiveField(2)
  final int durationSeconds;

  @HiveField(3)
  final double distanceMeters;

  @HiveField(4)
  final double paceSecondsPerKm;

  @HiveField(5)
  final double caloriesBurned;

  @HiveField(6)
  final List<RoutePoint> route;

  @HiveField(7)
  final double? averageSpeedKmh;

  @HiveField(8)
  final double? maxSpeedKmh;

  @HiveField(9)
  final double? elevationGainMeters;

  @HiveField(10)
  final double? elevationLossMeters;

  RunData({
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.paceSecondsPerKm,
    required this.caloriesBurned,
    required this.route,
    this.averageSpeedKmh,
    this.maxSpeedKmh,
    this.elevationGainMeters,
    this.elevationLossMeters,
  });

  double get paceMinPerKm => paceSecondsPerKm / 60;
  double get calories => caloriesBurned;

  factory RunData.mock({required double userWeightKg}) {
    return RunData(
      startTime: DateTime.now().subtract(const Duration(minutes: 7)),
      endTime: DateTime.now(),
      durationSeconds: 420,
      distanceMeters: 1500,
      paceSecondsPerKm: 280,
      caloriesBurned: userWeightKg * 1.05,
      route: [
        RoutePoint(lat: 31.5204, lng: 74.3587),
        RoutePoint(lat: 31.5210, lng: 74.3595),
      ],
      averageSpeedKmh: 12.8,
      maxSpeedKmh: 15.5,
      elevationGainMeters: 12.0,
      elevationLossMeters: 8.0,
    );
  }

  factory RunData.fromJson(Map<String, dynamic> json) => RunData(
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        durationSeconds: json['durationSeconds'],
        distanceMeters: json['distanceMeters'],
        paceSecondsPerKm: json['paceSecondsPerKm'],
        caloriesBurned: json['caloriesBurned'],
        route: (json['route'] as List<dynamic>)
            .map((p) => RoutePoint(lat: p['lat'], lng: p['lng']))
            .toList(),
        averageSpeedKmh: json['averageSpeedKmh']?.toDouble(),
        maxSpeedKmh: json['maxSpeedKmh']?.toDouble(),
        elevationGainMeters: json['elevationGainMeters']?.toDouble(),
        elevationLossMeters: json['elevationLossMeters']?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationSeconds': durationSeconds,
        'distanceMeters': distanceMeters,
        'paceSecondsPerKm': paceSecondsPerKm,
        'caloriesBurned': caloriesBurned,
        'route': route.map((p) => {'lat': p.lat, 'lng': p.lng}).toList(),
        'averageSpeedKmh': averageSpeedKmh,
        'maxSpeedKmh': maxSpeedKmh,
        'elevationGainMeters': elevationGainMeters,
        'elevationLossMeters': elevationLossMeters,
      };

  String get formattedPace {
    final minutes = (paceSecondsPerKm ~/ 60).toString().padLeft(2, '0');
    final seconds = (paceSecondsPerKm % 60).toStringAsFixed(0).padLeft(2, '0');
    return "$minutes:$seconds /km";
  }

  String get formattedDistance =>
      (distanceMeters / 1000).toStringAsFixed(2) + " km";

  String get formattedCalories =>
      caloriesBurned.toStringAsFixed(0) + " kcal";

  String get formattedDuration {
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  String? get formattedAverageSpeed =>
      averageSpeedKmh == null ? null : "${averageSpeedKmh!.toStringAsFixed(1)} km/h";

  String? get formattedMaxSpeed =>
      maxSpeedKmh == null ? null : "${maxSpeedKmh!.toStringAsFixed(1)} km/h";

  String? get formattedElevationGain =>
      elevationGainMeters == null ? null : "${elevationGainMeters!.toStringAsFixed(0)} m";

  String? get formattedElevationLoss =>
      elevationLossMeters == null ? null : "${elevationLossMeters!.toStringAsFixed(0)} m";

  List<Position> get positions =>
      route.map((p) => p.toPosition()).toList();
}

@HiveType(typeId: 4)
class RoutePoint {
  @HiveField(0)
  final double lat;

  @HiveField(1)
  final double lng;

  RoutePoint({required this.lat, required this.lng});

  double get latitude => lat;
  double get longitude => lng;

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
        headingAccuracy: 0.0,
      );

  static RoutePoint fromPosition(Position p) =>
      RoutePoint(lat: p.latitude, lng: p.longitude);
}

