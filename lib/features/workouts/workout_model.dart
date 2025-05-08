import 'package:hive/hive.dart';

part 'workout_model.g.dart';

@HiveType(typeId: 0)
class Workout extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<Interval> intervals;

  Workout({required this.name, required this.intervals});
}

@HiveType(typeId: 1)
class Interval {
  @HiveField(0)
  int runDuration; // seconds

  @HiveField(1)
  int walkDuration; // seconds

  Interval({required this.runDuration, required this.walkDuration});
}
