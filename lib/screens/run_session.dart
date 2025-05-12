import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../data/z25k_data.dart';
import '../controllers/timer_controller.dart';

class RunSessionScreen extends StatelessWidget {
  final Workout workout;
  const RunSessionScreen({super.key, required this.workout});

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String intervalLabel(IntervalType type) {
    switch (type) {
      case IntervalType.warmup:
        return 'WARMUP';
      case IntervalType.run:
        return 'RUN';
      case IntervalType.walk:
        return 'WALK';
      case IntervalType.cooldown:
        return 'COOLDOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TimerController(workout)..start(),
      child: Consumer<TimerController>(
        builder: (context, timer, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(workout.name),
              centerTitle: true,
            ),
            body: Column(
              children: [
                // Image & Label
                Expanded(
                  child: Stack(
                    children: [
                      Image.asset(
                        "assets/images/running.jpg",
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Center(
                        child: Text(
                          intervalLabel(timer.currentSegment.type),
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress Bar
                LinearPercentIndicator(
                  percent: timer.progress.clamp(0, 1),
                  lineHeight: 8.0,
                  backgroundColor: Colors.grey[300],
                  progressColor: Colors.blue,
                  padding: const EdgeInsets.all(16),
                ),

                // Current Interval Countdown
                Text(
                  "Interval Remaining: ${formatTime(timer.currentSegmentRemaining)}",
                  style: const TextStyle(fontSize: 20),
                ),

                // Elapsed / Remaining Total Time
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(children: [
                        const Text("Elapsed", style: TextStyle(color: Colors.grey)),
                        Text(formatTime(timer.totalElapsedSeconds), style: const TextStyle(fontSize: 20))
                      ]),
                      Column(children: [
                        const Text("Remaining", style: TextStyle(color: Colors.grey)),
                        Text(
                          formatTime(timer.totalDuration - timer.totalElapsedSeconds),
                          style: const TextStyle(fontSize: 20),
                        )
                      ]),
                    ],
                  ),
                ),

                // Controls
                if (timer.isRunning && !timer.isPaused)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Icon(Icons.fast_rewind, size: 36), // Optional: skip back
                      ElevatedButton(
                        onPressed: timer.pause,
                        child: const Text("PAUSE"),
                      ),
                      const Icon(Icons.fast_forward, size: 36), // Optional: skip ahead
                    ],
                  )
                else if (timer.isRunning && timer.isPaused)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: timer.resume,
                        child: const Text("RESUME"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          timer.stop();
                          Navigator.pop(context);
                        },
                        child: const Text("STOP"),
                      ),
                    ],
                  ),

                // Lock Button (optional for UI lock state)
                IconButton(
                  icon: const Icon(Icons.lock),
                  onPressed: () {}, // implement lock toggle if needed
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

