import '../data/z25k_data.dart';

String formatTimeForDisplay(int seconds) {
  if (seconds <= 90) return '$seconds seconds';
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (remainingSeconds > 0) {
    return '$minutes minute${minutes != 1 ? 's' : ''} and $remainingSeconds second${remainingSeconds != 1 ? 's' : ''}';
  }
  return '$minutes minute${minutes != 1 ? 's' : ''}';
}

String formatWorkoutDescription(Workout workout) {
  String description = 'Brisk five-minute warmup walk. Then alternate';

  final hasAlt = workout.alternateIntervals != null && workout.alternateIntervals! > 0;

  if (hasAlt) {
    description +=
        ' ${formatTimeForDisplay(workout.runDuration)} of jogging and ${formatTimeForDisplay(workout.walkDuration)} of walking for ${workout.intervals} intervals, then ${formatTimeForDisplay(workout.alternateRunDuration ?? 0)} of jogging and ${formatTimeForDisplay(workout.alternateWalkDuration ?? 0)} of walking for ${workout.alternateIntervals} intervals.';
  } else {
    description +=
        ' ${formatTimeForDisplay(workout.runDuration)} of jogging and ${formatTimeForDisplay(workout.walkDuration)} of walking for a total of ${workout.intervals} intervals.';
  }

  return description;
}

int getTotalWorkoutTime(Workout workout) {
  int totalSeconds = workout.warmup + workout.cooldown;

  totalSeconds += workout.intervals * (workout.runDuration + workout.walkDuration);

  if (workout.alternateIntervals != null && workout.alternateIntervals! > 0) {
    totalSeconds += workout.alternateIntervals! *
        ((workout.alternateRunDuration ?? 0) + (workout.alternateWalkDuration ?? 0));
  }

  return (totalSeconds / 60).ceil(); // return total in minutes
}

