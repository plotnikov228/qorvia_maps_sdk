import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import '../features/settings/settings_service.dart';
import 'theme/app_theme.dart';

/// Main application widget with Material 3 Blue theme.
class QorviaMapsExampleApp extends StatelessWidget {
  final SettingsService settingsService;

  const QorviaMapsExampleApp({
    super.key,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qorvia Map',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: HomeScreen(settingsService: settingsService),
    );
  }
}
