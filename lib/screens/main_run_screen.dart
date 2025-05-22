
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

import 'package:zero_to_5k/core/theme/app_colors.dart';
import 'package:zero_to_5k/data/z25k_data.dart';
import 'package:zero_to_5k/utils/workout_formatter.dart';
import '../core/theme/app_colors.dart';
import 'run_session_screen.dart';
import 'settings_screen.dart';
import 'leaderboard_history_screen.dart';

class MainRunScreen extends StatefulWidget {
  const MainRunScreen({super.key});

  @override
  State<MainRunScreen> createState() => _MainRunScreenState();
}

final GlobalKey _menuKey = GlobalKey();

class _MainRunScreenState extends State<MainRunScreen> {
  late Workout selectedWorkout;
  late int selectedWeekIndex;
  late int selectedDayIndex;
  late ConfettiController _confettiController;
  late ScrollController _scrollController;

  final double cardWidth = 90.0;
  final double cardHeight = 90.0;
  int lastCompletedDayIndex = -1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _scrollController = ScrollController();
    _loadProgress();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      lastCompletedDayIndex = prefs.getInt('lastCompletedDayIndex') ?? -1;
      selectedWeekIndex = prefs.getInt('selectedWeekIndex') ?? 0;
      selectedDayIndex = prefs.getInt('selectedDayIndex') ?? 0;
      selectedWorkout = Z25KProgram.weeks[selectedWeekIndex][selectedDayIndex];
      isLoading = false;
    });
  }

  void _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastCompletedDayIndex', lastCompletedDayIndex);
    await prefs.setInt('selectedWeekIndex', selectedWeekIndex);
    await prefs.setInt('selectedDayIndex', selectedDayIndex);
  }

  void _onWorkoutCompleted() {
    setState(() {
      final currentIndex = selectedWeekIndex * 3 + selectedDayIndex;
      if (currentIndex > lastCompletedDayIndex) {
        lastCompletedDayIndex = currentIndex;
        _confettiController.play();
        _saveProgress();
      }
    });
  }

  void _onDayCardTap(int index) {
    setState(() {
      selectedWeekIndex = index ~/ 3;
      selectedDayIndex = index % 3;
      selectedWorkout = Z25KProgram.weeks[selectedWeekIndex][selectedDayIndex];
    });

    _scrollController.animateTo(
      (index - 1).clamp(0, 999) * cardWidth,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateDay(int direction) {
    final newIndex = selectedWeekIndex * 3 + selectedDayIndex + direction;
    final totalDays = Z25KProgram.weeks.length * 3;

    if (newIndex >= 0 && newIndex < totalDays) {
      setState(() {
        selectedWeekIndex = newIndex ~/ 3;
        selectedDayIndex = newIndex % 3;
        selectedWorkout = Z25KProgram.weeks[selectedWeekIndex][selectedDayIndex];
      });

      _scrollController.animateTo(
        (newIndex - 1).clamp(0, 999) * cardWidth,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }



  void _showOptionsMenu() {
    final RenderBox button = _menuKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: const [
              Icon(Icons.settings, color: AppColors.calmGreen),
              SizedBox(width: 8),
              Text("Settings"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'leaderboard',
          child: Row(
            children: const [
              Icon(Icons.leaderboard, color: AppColors.calmGreen),
              SizedBox(width: 8),
              Text("View Leaderboard"),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'settings') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      } else if (value == 'leaderboard') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardHistoryScreen()));
      }
    });
  }
  void _onStartRunning() {
    final currentIndex = selectedWeekIndex * 3 + selectedDayIndex;
    if (currentIndex > lastCompletedDayIndex + 1) {
      _showSkipStartDialog();
    } else {
      _navigateToRunSession();
    }
  }

  void _navigateToRunSession() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RunSessionScreen(
          workout: selectedWorkout,
          onComplete: _onWorkoutCompleted,
        ),
      ),
    );
  }

  void _showSkipStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Start Skipped Workout?"),
          content: const Text(
            "You are skipping scheduled days. Do you still want to start this session?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text("Cancel", style: TextStyle(color: AppColors.calmGreen)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  _navigateToRunSession();
                }
              },
              child: Text("Start Anyway", style: TextStyle(color: AppColors.warmOrange)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundGray,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final dayLabels = <String>[];
    final workouts = <Workout>[];

    for (int week = 0; week < Z25KProgram.weeks.length; week++) {
      for (int day = 0; day < Z25KProgram.weeks[week].length; day++) {
        dayLabels.add('WEEK ${week + 1}\nDAY ${day + 1}');
        workouts.add(Z25KProgram.weeks[week][day]);
      }
    }

    final totalDays = workouts.length;
    final completedDays = (lastCompletedDayIndex + 1).clamp(0, totalDays);
    final progress = completedDays / totalDays;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: const Text("Zero to 5K"),
        centerTitle: true,
        backgroundColor: AppColors.calmGreen,
        elevation: 0,
        actions: [
          IconButton(
            key: _menuKey, // Required for positioning
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Workout Summary Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Card(
                  color: AppColors.cardBackground,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.timer, color: AppColors.calmGreen),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                "Duration: ${getTotalWorkoutTime(selectedWorkout)} min",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.directions_run, color: AppColors.warmOrange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                formatWorkoutDescription(selectedWorkout),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Big Stretched Image Banner
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/start.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),

              // Progress Bar & Start Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.progressBackground,
                      color: AppColors.progressForeground,
                      minHeight: 10,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _onStartRunning,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warmOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Start Workout",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Day Selector with Navigation Arrows
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: AppColors.calmGreen),
                      onPressed: () => _navigateDay(-1),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: cardHeight,
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: dayLabels.length,
                          itemBuilder: (context, index) {
                            final isSelected = (index == selectedWeekIndex * 3 + selectedDayIndex);
                            final isCompleted = (index <= lastCompletedDayIndex);

                            return GestureDetector(
                              onTap: () => _onDayCardTap(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: cardWidth,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.calmGreen
                                      : isCompleted
                                          ? AppColors.progressForeground
                                          : AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.calmGreen.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : [],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Center(
                                  child: Text(
                                    dayLabels[index],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected || isCompleted
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: AppColors.calmGreen),
                      onPressed: () => _navigateDay(1),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Confetti Animation
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [AppColors.warmOrange, AppColors.calmGreen, Colors.white],
              numberOfParticles: 30,
              maxBlastForce: 30,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              gravity: 0.1,
              particleDrag: 0.05,
            ),
          ),
        ],
      ),
    );
  }
}

