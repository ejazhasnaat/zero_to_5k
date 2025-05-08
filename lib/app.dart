import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
//import 'features/home/home_screen.dart';
import 'screens/main_run.dart';

class ZeroTo5KApp extends StatelessWidget {
  const ZeroTo5KApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zero to 5K',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.oceanicTeal),
        useMaterial3: true,
      ),
      //home: const HomeScreen(),
      home: const MainRunScreen(),
    );
  }
}
