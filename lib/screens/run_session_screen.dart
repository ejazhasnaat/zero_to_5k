import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'dart:ui' as ui;

import '../data/z25k_data.dart';
import '../controllers/timer_controller.dart';
import '../audio/audio_playback_engine.dart';
import '../services/audio_settings_service.dart';
import '../services/local_storage_service.dart';
import '../models/run_data.dart';
import '../screens/run_summary_screen.dart';
import '../core/theme/app_colors.dart';

class RunSessionScreen extends StatefulWidget {
  final Workout workout;
  final VoidCallback? onComplete;

  const RunSessionScreen({
    super.key,
    required this.workout,
    this.onComplete,
  });

  @override
  State<RunSessionScreen> createState() => _RunSessionScreenState();
}

class _RunSessionScreenState extends State<RunSessionScreen> with TickerProviderStateMixin {
  late TimerController _timerController;
  late AudioPlaybackEngine _audioEngine;
  late ConfettiController _confettiController;

  final PageController _intervalPageController = PageController(viewportFraction: 0.42);
  final AudioPlayer _tickPlayer = AudioPlayer();

  bool _summaryShown = false;
  bool _isLocked = false;
  bool _isPaused = false;

  int _lastSegmentIndex = -1;
  Timer? _voiceDebounceTimer;
  Timer? _tickingTimer;

  late AnimationController _pauseResumeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    final audioSvc = Provider.of<AudioSettingsService>(context, listen: false);
    _audioEngine = AudioPlaybackEngine(audioSvc.settings);
    audioSvc.onSettingsChanged = (newSettings) => _audioEngine.reloadSettings(newSettings);

    _timerController = TimerController(
      workout: widget.workout,
      audioEngine: _audioEngine,
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _pauseResumeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _pauseResumeController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _timerController.start());

    _timerController.addListener(() {
      final currentIndex = _timerController.currentIndex;
      if (currentIndex != _lastSegmentIndex) {
        _onSegmentChange();
        _lastSegmentIndex = currentIndex;
      }

      final remaining = _timerController.remainingSeconds;
      if (remaining <= 5 && remaining > 0) {
        _playTickingSound();
      } else {
        _tickingTimer?.cancel();
      }

      if (_timerController.isCompleted && !_summaryShown) {
        _summaryShown = true;
        _confettiController.play();
        widget.onComplete?.call();
        _stopAndSaveRun(context, autoComplete: true);
      }

      setState(() {});
    });
  }

  void _onSegmentChange() {
    final segment = _timerController.currentSegment;
    final type = segment.type.name;
    final duration = _formatDuration(segment.duration);

    _voiceDebounceTimer?.cancel();
    _voiceDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _audioEngine.speak("Next: $type for $duration");
    });

    if (!_isPaused && !_isLocked) {
      Vibration.hasVibrator().then((hasVibrator) {
        if (hasVibrator ?? false) {
          Vibration.vibrate(duration: 100);
        } else {
          HapticFeedback.mediumImpact();
        }
      });
    }

    _intervalPageController.animateToPage(
      _timerController.currentIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _playTickingSound() {
    _tickingTimer?.cancel();
    int tickCount = 0;

    _tickingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (tickCount >= 5) {
        timer.cancel();
        return;
      }
      _tickPlayer.stop();
      _tickPlayer.play(AssetSource('assets/audio/tick.mp3'), volume: 0.5);
      tickCount++;
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    _audioEngine.dispose();
    _confettiController.dispose();
    _intervalPageController.dispose();
    _voiceDebounceTimer?.cancel();
    _tickingTimer?.cancel();
    _tickPlayer.dispose();
    _pauseResumeController.dispose();
    super.dispose();
  }

  Future<void> _stopAndSaveRun(BuildContext ctx, {bool autoComplete = false}) async {
    _timerController.stop();
    final runData = await _timerController.generateRunData();

    if (runData.durationSeconds >= 60) {
      runData.endTime = DateTime.now();
      await LocalStorageService.saveRun(runData);

      if (ctx.mounted) {
        Navigator.pushReplacement(
          ctx,
          MaterialPageRoute(builder: (_) => RunSummaryScreen(run: runData)),
        );
      }

      Vibration.hasVibrator().then((hasVibrator) {
        if (hasVibrator ?? false) {
          Vibration.vibrate(duration: 300);
        } else {
          HapticFeedback.heavyImpact();
        }
      });
    } else if (!autoComplete && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text("Run too short to save.")),
      );
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _onSwipeLeft() {
    if (_isLocked) return;
    _timerController.nextSegment();
  }

  void _onSwipeRight() {
    if (_isLocked) return;
    _timerController.previousSegment();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _timerController,
      child: Consumer<TimerController>(
        builder: (ctx, timer, __) {
          final current = timer.currentSegment;
          final totalDuration = timer.totalDuration;
          final elapsed = timer.elapsedSeconds;
          final remaining = timer.remainingSeconds;

          final progress = (elapsed / totalDuration).clamp(0.0, 1.0);
          final segmentProgress = current.duration == 0
              ? 0.0
              : ((current.duration - remaining) / current.duration).clamp(0.0, 1.0);

          return GestureDetector(
            onHorizontalDragEnd: (details) {
              if (_isLocked) return;
              const velocityThreshold = 300;
              if (details.primaryVelocity! < -velocityThreshold) {
                _onSwipeLeft();
              } else if (details.primaryVelocity! > velocityThreshold) {
                _onSwipeRight();
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Zero to 5K"),
                backgroundColor: AppColors.calmGreen,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(_isLocked ? Icons.lock : Icons.lock_open),
                    onPressed: () => setState(() => _isLocked = !_isLocked),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  Column(
                    children: [
                      // Task 1.1: Stretched Image
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                _getImageForSegment(current.type.name),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned.fill(
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                child: Container(color: Colors.black.withOpacity(0.15)),
                              ),
                            ),
                            Center(
                              child: Text(
                                current.type.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          color: AppColors.warmOrange,
                          backgroundColor: AppColors.calmGreen.withOpacity(0.3),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Task 1.2: Perfect rounded square interval cards
                      SizedBox(
                        height: 120,
                        child: PageView.builder(
                          controller: _intervalPageController,
                          itemCount: timer.intervals.length,
                          physics: _isLocked
                              ? const NeverScrollableScrollPhysics()
                              : const BouncingScrollPhysics(),
                          itemBuilder: (ctx, idx) {
                            final segment = timer.intervals[idx];
                            final isCurrent = idx == timer.currentIndex;
                            final isCompleted = idx < timer.currentIndex;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.grey.shade300
                                    : Colors.white,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isCurrent ? AppColors.warmOrange : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isCurrent
                                    ? [
                                        BoxShadow(
                                          color: AppColors.warmOrange.withOpacity(0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      segment.type.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent
                                            ? AppColors.warmOrange
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatDuration(segment.duration),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isCurrent
                                            ? AppColors.calmGreen
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Task 1.3: Smaller rounded timer showing current interval remaining
                      CircularPercentIndicator(
                        radius: 64,
                        lineWidth: 10,
                        percent: segmentProgress,
                        center: Text(
                          _formatDuration(remaining),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warmOrange,
                          ),
                        ),
                        progressColor: AppColors.warmOrange,
                        backgroundColor: Colors.grey.shade200,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),

                      const SizedBox(height: 12),

                      // Task 1.4: Enlarged elapsed/remaining time text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Elapsed: ${_formatDuration(elapsed)}",
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              "Remaining: ${_formatDuration(totalDuration - elapsed)}",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLocked
                                ? null
                                : () {
                                    setState(() {
                                      if (_isPaused) {
                                        _pauseResumeController.forward(from: 0);
                                        _timerController.resume();
                                      } else {
                                        _pauseResumeController.reverse(from: 1);
                                        _timerController.pause();
                                      }
                                      _isPaused = !_isPaused;
                                    });
                                  },
                            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                            label: Text(_isPaused ? "Resume" : "Pause"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.calmGreen,
                              minimumSize: const Size(130, 48),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLocked
                                ? null
                                : () async {
                                    await _stopAndSaveRun(context);
                                  },
                            icon: const Icon(Icons.stop),
                            label: const Text("Stop & Save"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warmOrange,
                              minimumSize: const Size(130, 48),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getImageForSegment(String type) {
    switch (type.toLowerCase()) {
      case "warmup":
        return 'assets/images/warmup.jpg';
      case "run":
        return 'assets/images/run.jpg';
      case "walk":
        return 'assets/images/walk.jpg';
      case "cooldown":
        return 'assets/images/cooldown.jpg';
      default:
        return 'assets/images/workout.jpg';
    }
  }
}