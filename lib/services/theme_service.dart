import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  ThemeData get currentTheme => _isDarkMode
      ? ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(),
          useMaterial3: true,
        )
      : ThemeData(
          brightness: Brightness.light,
          colorScheme: const ColorScheme.light(),
          useMaterial3: true,
        );
}
