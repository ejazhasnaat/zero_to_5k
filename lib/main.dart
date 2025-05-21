import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'services/audio_settings_service.dart';
import 'app.dart';
import 'services/local_storage_service.dart';
import 'services/feedback_settings_service.dart';
import 'services/settings_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  await SettingsHelper.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AudioSettingsService()),
        ChangeNotifierProvider(create: (_) => FeedbackSettingsService()),
      ],
      //child: const ZeroTo5KApp(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            title: 'Zero to 5K',
            theme: themeService.currentTheme,
            home: const ZeroTo5KApp(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    ),
  );
}

