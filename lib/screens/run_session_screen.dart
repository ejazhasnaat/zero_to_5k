import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import '../models/audio_settings_model.dart';
import '../services/audio_settings_service.dart';
import '../controllers/timer_controller.dart';
import '../audio/audio_playback_engine.dart';
import '../data/z25k_data.dart';
import '../features/tracking/tracking_service.dart';
import '../services/local_storage_service.dart';
import '../models/run_data.dart';

class RunSessionScreen extends StatefulWidget {
  final Workout workout;

  const RunSessionScreen({super.key, required this.workout});

  @override
  State<RunSessionScreen> createState() => _RunSessionScreenState();
}

class _RunSessionScreenState extends State<RunSessionScreen> {
  late TimerController _timerController;
  late AudioPlaybackEngine _audioEngine;
  late TrackingService _trackingService;
  final double userWeightKg = 65.0;
  final double userHeightCm = 175.0;

  @override
  void initState() {
    super.initState();
    final audioSettingsService =
        Provider.of<AudioSettingsService>(context, listen: false);

    _audioEngine = AudioPlaybackEngine(audioSettingsService.settings);

    audioSettingsService.onSettingsChanged = (newSettings) {
      _audioEngine.reloadSettings(newSettings);
    };

    _timerController = TimerController(
      workout: widget.workout,
      audioEngine: _audioEngine,
    );

    _trackingService = TrackingService(userWeightKg: userWeightKg,
                                       userHeightCm: userHeightCm);
  }

  @override
  void dispose() {
    _timerController.dispose();
    _audioEngine.dispose();
    _trackingService.stopTracking();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Color _intervalColor(IntervalType type) {
    switch (type) {
      case IntervalType.run:
        return Colors.green;
      case IntervalType.walk:
        return Colors.blue;
      case IntervalType.warmup:
        return Colors.orange;
      case IntervalType.cooldown:
        return Colors.purple;
    }
  }

  IconData _intervalIcon(IntervalType type) {
    switch (type) {
      case IntervalType.run:
        return Icons.directions_run;
      case IntervalType.walk:
        return Icons.directions_walk;
      case IntervalType.warmup:
        return Icons.wb_sunny;
      case IntervalType.cooldown:
        return Icons.self_improvement;
    }
  }

  Widget _buildRunStats() {
    return ValueListenableBuilder<RunData?>(
      valueListenable: _trackingService.runData,
      builder: (context, data, child) {
        if (data == null) {
          return const Text("Waiting for GPS...", style: TextStyle(fontSize: 16));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Distance: ${data.formattedDistance}"),
            Text("Pace: ${data.formattedPace}"),
            Text("Duration: ${data.formattedDuration}"),
            Text("Calories: ${data.formattedCalories}"),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _timerController,
      child: Consumer<TimerController>(
        builder: (context, timer, _) {
          final upcoming = timer.intervals
              .skip(timer.currentIndex + 1)
              .take(5)
              .toList();

          return Scaffold(
            appBar: AppBar(title: const Text('Run Session')),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    timer.currentSegment.type.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  LinearProgressIndicator(
                    value: timer.progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade300,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _formatDuration(timer.currentSegmentRemaining),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Elapsed: ${_formatDuration(timer.totalElapsedSeconds)}"),
                      Text("Remaining: ${_formatDuration(timer.totalDuration - timer.totalElapsedSeconds)}"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildRunStats(),
                  const SizedBox(height: 20),
                  if (upcoming.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Next Intervals",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: upcoming.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final interval = upcoming[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _intervalColor(interval.type).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _intervalColor(interval.type),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_intervalIcon(interval.type),
                                        color: _intervalColor(interval.type)),
                                    const SizedBox(width: 8),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          interval.type.name.toUpperCase(),
                                          style: TextStyle(
                                            color: _intervalColor(interval.type),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(interval.duration),
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!timer.isRunning)
                        ElevatedButton.icon(
                          onPressed: () {
                            _trackingService.startTracking();
                            timer.start();
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Start"),
                        ),
                      if (timer.isRunning && !timer.isPaused)
                        ElevatedButton.icon(
                          onPressed: timer.pause,
                          icon: const Icon(Icons.pause),
                          label: const Text("Pause"),
                        ),
                      if (timer.isRunning && timer.isPaused)
                        ElevatedButton.icon(
                          onPressed: timer.resume,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Resume"),
                        ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          timer.stop();
                          _trackingService.stopTracking();
                          final runData = _trackingService.runData.value;
                          if (runData != null) {
                            await LocalStorageService.saveRun(runData);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Run saved successfully!")),
                            );
                          }
                        },
                        icon: const Icon(Icons.stop),
                        label: const Text("Stop"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

