import 'package:flutter/material.dart';
import 'package:zero_to_5k/data/z25k_data.dart';
import 'package:zero_to_5k/utils/workout_formatter.dart';
import 'run_session_screen.dart';
import 'package:zero_to_5k/screens/settings_screen.dart';

class MainRunScreen extends StatefulWidget {
  const MainRunScreen({super.key});

  @override
  State<MainRunScreen> createState() => _MainRunScreenState();
}

class _MainRunScreenState extends State<MainRunScreen> {
  late Workout selectedWorkout;
  late int selectedWeekIndex;
  late int selectedDayIndex;

  @override
  void initState() {
    super.initState();
    selectedWeekIndex = 0;
    selectedDayIndex = 0;
    selectedWorkout = Z25KProgram.weeks[0][0];
  }

  @override
  Widget build(BuildContext context) {
    final List<String> dayLabels = [];
    final List<Workout> workouts = [];

    for (int week = 0; week < Z25KProgram.weeks.length; week++) {
      for (int day = 0; day < Z25KProgram.weeks[week].length; day++) {
        dayLabels.add('WEEK ${week + 1}\nDAY ${day + 1}');
        workouts.add(Z25KProgram.weeks[week][day]);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Zero to 5K"),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Text('Settings'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Workout Description
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DURATION: ${getTotalWorkoutTime(selectedWorkout)} MINUTES",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  formatWorkoutDescription(selectedWorkout),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          // Image
          Expanded(
            child: Image.asset(
              'assets/images/start.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.white,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RunSessionScreen(workout: selectedWorkout),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("START", style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dayLabels.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final isSelected = index == (selectedWeekIndex * 3 + selectedDayIndex);
                      return GestureDetector(
                        onTap: () {
                          final newWeekIndex = index ~/ 3;
                          final newDayIndex = index % 3;
                          setState(() {
                            selectedWeekIndex = newWeekIndex;
                            selectedDayIndex = newDayIndex;
                            selectedWorkout = Z25KProgram.weeks[newWeekIndex][newDayIndex];
                          });
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayLabels[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                                color: isSelected ? Colors.black : Colors.grey,
                              ),
                            ),
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                height: 4,
                                width: 40,
                                color: Colors.redAccent,
                              )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

