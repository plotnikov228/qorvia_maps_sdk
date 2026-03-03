import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import 'theme/app_theme.dart';

/// Main application widget with Material 3 Blue theme.
class QorviaMapsExampleApp extends StatelessWidget {
  const QorviaMapsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qorvia Map',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
