import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color calmGreen = Color(0xFF4CAF50);      // Minty calm green
  static const Color warmOrange = Color(0xFFFF5733);    // Soft warm orange

  // Background colors
  static const Color backgroundGray = Color(0xFFF7F9F9); // Very light gray for backgrounds
  static const Color lightGray = Color(0xFFD3D3D3); // Light gray
  static const Color mediumGray = Color(0xFF808080); // Medium gray

  // Text colors
  static const Color textPrimary = Color(0xFF263238);   // Dark slate gray for primary text
  static const Color textSecondary = Color(0xFF546E7A); // Medium gray for secondary text

  // Card backgrounds
  static const Color cardBackground = Colors.white;

  // Borders and shadows
  static const Color borderColor = Color(0xFFE0E0E0);   // Light gray border color

  // Progress and indicators
  static final Color progressBackground = Color(0x4D4CAF50); //calmGreen at 30% opacity
  static const Color progressForeground = calmGreen;

  // Additional accent colors (optional)
  static const Color accentLightGreen = Color(0xFF81C784);
  static const Color accentLightOrange = Color(0xFFFFB74D);

  // Error / warning colors (if needed)
  static const Color errorRed = Color(0xFFD32F2F);

  // Add missing oceanicTeal color
  static const Color oceanicTeal = Color(0xFF008080);
}
