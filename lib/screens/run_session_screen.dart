import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

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
  bool _isAnimatingPage = false;
  bool _hasSpokenInitialSegment = false;


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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timerController.start();

      // Delay initial onSegmentChange after everything has settled
      Future.delayed(const Duration(milliseconds: 200), () {
        _onSegmentChange();
        _lastSegmentIndex = _timerController.currentIndex;
      });
    });

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

    debugPrint("🗣️ Segment changed to: $type ($duration)");

    // Prevent duplicate speech on first segment
    if (!_hasSpokenInitialSegment) {
      _hasSpokenInitialSegment = true;
      debugPrint("✅ First segment speech trigger");
    } else {
      _voiceDebounceTimer?.cancel();
      _audioEngine.stop();

      _voiceDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        final _duration = _audioEngine.formatDurationReadable(Duration(seconds: segment.duration));
        _audioEngine.speak("${segment.type.name} for $_duration");
      });
    }

    if (!_isPaused && !_isLocked) {
      Vibration.hasVibrator().then((hasVibrator) {
        if (hasVibrator ?? false) {
          Vibration.vibrate(duration: 100);
        } else {
          HapticFeedback.mediumImpact();
        }
      });
    }

    final int index = _timerController.currentIndex;
    final int maxIndex = _timerController.intervals.length - 1;

    if (_intervalPageController.hasClients &&
        !_isAnimatingPage &&
        index >= 0 &&
        index <= maxIndex &&
        _intervalPageController.page?.round() != index) {
      _isAnimatingPage = true;
      _intervalPageController
          .animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          )
          .whenComplete(() => _isAnimatingPage = false)
          .catchError((e) {
            debugPrint("⚠️ animateToPage error: $e");
            _isAnimatingPage = false;
          });
    } else {
      debugPrint('⚠️ Skipping animateToPage: controller not ready or invalid index: $index');
    }
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

  String _getImageForSegment(String name) {
    switch (name.toLowerCase()) {
      case 'walk':
        return 'assets/images/walk.jpg';
      case 'run':
        return 'assets/images/run.jpg';
      case 'warmup':
        return 'assets/images/warmup.jpg';
      case 'cooldown':
        return 'assets/images/cooldown.jpg';
      default:
        return 'assets/images/running.jpg';
    }
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
          final progress = (elapsed / totalDuration).clamp(0.0, 1.0);

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
                      // Background image
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
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
                                filter: ui.ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                                child: Container(color: Colors.black.withOpacity(0.15)),
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
                      const SizedBox(height: 12), // slightly less vertical spacing
                      // Interval Cards
                      SizedBox(
                        height: 96, // reduced from 120
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _isLocked ? null : _onSwipeRight,
                              icon: const Icon(Icons.skip_previous_rounded),
                              iconSize: 32,
                              tooltip: "Previous Interval",
                              color: _isLocked ? Colors.grey.shade400 : AppColors.calmGreen,
                            ),
                            const SizedBox(width: 2), // reduced spacing

                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: ListView.separated(
                                  key: ValueKey<int>(timer.currentIndex),
                                  scrollDirection: Axis.horizontal,
                                  physics: _isLocked
                                      ? const NeverScrollableScrollPhysics()
                                      : const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 8), // reduced outer padding
                                  itemCount: timer.intervals.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8), // reduced spacing between cards
                                  itemBuilder: (context, idx) {
                                    final segment = timer.intervals[idx];
                                    final isCurrent = idx == timer.currentIndex;
                                    final isCompleted = idx < timer.currentIndex;
                                    return AspectRatio(
                                      aspectRatio: 1,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        decoration: BoxDecoration(
                                          color: isCompleted ? Colors.grey.shade200 : Colors.white,
                                          borderRadius: BorderRadius.circular(12), // slightly tighter radius
                                          border: Border.all(
                                            color: isCurrent ? AppColors.warmOrange : Colors.transparent,
                                            width: 2,
                                          ),
                                          boxShadow: isCurrent
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.warmOrange.withOpacity(0.3),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6), // reduced inner padding
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  segment.type.name.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: isCurrent
                                                        ? AppColors.warmOrange
                                                        : Colors.grey.shade800,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDuration(segment.duration),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isCurrent
                                                      ? AppColors.calmGreen
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(width: 2),
                            IconButton(
                              onPressed: _isLocked ? null : _onSwipeLeft,
                              icon: const Icon(Icons.skip_next_rounded),
                              iconSize: 32,
                              tooltip: "Next Interval",
                              color: _isLocked ? Colors.grey.shade400 : AppColors.calmGreen,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      CircularPercentIndicator(
                        radius: 54,
                        lineWidth: 10,
                        percent: (1.0 -
                            (timer.currentSegmentRemaining / timer.currentSegment.duration))
                            .clamp(0.0, 1.0),
                        center: Text(
                          _formatDuration(timer.currentSegmentRemaining),
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
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundGray,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Elapsed
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 24, color: AppColors.calmGreen),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Elapsed: ",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.calmGreen,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(elapsed),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),

                              // Remaining
                              Row(
                                children: [
                                  const Icon(Icons.hourglass_bottom, size: 24, color: AppColors.warmOrange),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Remaining: ",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.errorRed,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration((totalDuration - elapsed).clamp(0, totalDuration)),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                            icon: Icon(
                              _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              size: 24,
                            ),
                            label: Text(
                              _isPaused ? "Resume" : "Pause",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.calmGreen,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(140, 52),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                            ),
                          ),
                          
                          ElevatedButton.icon(
                            onPressed: _isLocked
                                ? null
                                : () async {
                                    await _stopAndSaveRun(context);
                                  },
                            icon: const Icon(Icons.stop_rounded, size: 24),
                            label: const Text(
                              "Stop & Save",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(140, 52),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      numberOfParticles: 30,
                      gravity: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
