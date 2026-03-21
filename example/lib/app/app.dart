import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/localization/app_localizations.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_service.dart';
import 'theme/app_theme.dart';

/// Main application widget with Material 3 Blue theme.
class QorviaMapsExampleApp extends StatefulWidget {
  final SettingsService settingsService;

  const QorviaMapsExampleApp({
    super.key,
    required this.settingsService,
  });

  @override
  State<QorviaMapsExampleApp> createState() => _QorviaMapsExampleAppState();
}

class _QorviaMapsExampleAppState extends State<QorviaMapsExampleApp> {
  late Locale _locale;
  StreamSubscription<AppLanguage>? _languageSubscription;

  @override
  void initState() {
    super.initState();
    _locale = widget.settingsService.effectiveLocale;

    // Listen to language changes
    _languageSubscription = widget.settingsService.languageStream.listen((_) {
      setState(() {
        _locale = widget.settingsService.effectiveLocale;
      });
    });
  }

  @override
  void dispose() {
    _languageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qorvia Map',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      // Localization support
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Use selected locale
      locale: _locale,
      home: HomeScreen(settingsService: widget.settingsService),
    );
  }
}
