import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../features/workouts/workout_model.dart';
import '../models/run_data.dart';

class LocalStorageService {
  static const String workoutBoxName = 'workouts';
  static const String runDataBoxName = 'run_sessions';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(WorkoutAdapter());
    Hive.registerAdapter(IntervalAdapter());
    Hive.registerAdapter(RunDataAdapter());
    Hive.registerAdapter(RoutePointAdapter());

    await Hive.openBox<Workout>(workoutBoxName);
    await Hive.openBox<RunData>(runDataBoxName);
  }

  // ---- Workout Persistence ----
  static Future<void> saveWorkout(Workout workout) async {
    final box = Hive.box<Workout>(workoutBoxName);
    await box.add(workout);
  }

  static List<Workout> getWorkouts() {
    final box = Hive.box<Workout>(workoutBoxName);
    return box.values.toList();
  }

  // ---- Run Session Persistence ----
  static Future<void> saveRun(RunData run) async {
    final box = Hive.box<RunData>(runDataBoxName);
    await box.add(run);
  }

  static List<RunData> getRunHistory() {
    final box = Hive.box<RunData>(runDataBoxName);
    return box.values.toList().reversed.toList(); // Most recent first
  }
}

