import 'package:hive_flutter/hive_flutter.dart';
import '../features/workouts/workout_model.dart';

class LocalStorageService {
  static const String workoutBoxName = 'workouts';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(WorkoutAdapter());
    Hive.registerAdapter(IntervalAdapter());
    await Hive.openBox<Workout>(workoutBoxName);
  }

  static Future<void> saveWorkout(Workout workout) async {
    final box = Hive.box<Workout>(workoutBoxName);
    await box.add(workout);
  }

  static List<Workout> getWorkouts() {
    final box = Hive.box<Workout>(workoutBoxName);
    return box.values.toList();
  }
}
