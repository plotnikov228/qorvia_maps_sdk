import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Search mode options.
enum SearchMode {
  /// Smart geosearch - uses AI-enhanced search with better results.
  smartGeosearch,

  /// Regular geocoding - standard address lookup.
  regularGeocoding,
}

/// App language options.
enum AppLanguage {
  /// Use system language.
  system,

  /// English.
  english,

  /// Russian.
  russian,
}

extension AppLanguageExtension on AppLanguage {
  /// Returns the locale for this language, or null for system.
  Locale? get locale {
    switch (this) {
      case AppLanguage.system:
        return null;
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.russian:
        return const Locale('ru');
    }
  }

  /// Returns display name for UI.
  String displayName(BuildContext context) {
    switch (this) {
      case AppLanguage.system:
        return _getSystemLanguageName();
      case AppLanguage.english:
        return 'English';
      case AppLanguage.russian:
        return 'Русский';
    }
  }

  static String _getSystemLanguageName() {
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    if (systemLocale.languageCode == 'ru') {
      return 'Системный (Русский)';
    }
    return 'System (English)';
  }
}

/// Settings service for managing app preferences.
///
/// Uses SharedPreferences for persistent storage.
/// Provides a stream for reactive updates.
class SettingsService {
  static const String _searchModeKey = 'search_mode';
  static const String _languageKey = 'app_language';

  final StreamController<SearchMode> _searchModeController =
      StreamController<SearchMode>.broadcast();
  final StreamController<AppLanguage> _languageController =
      StreamController<AppLanguage>.broadcast();

  SearchMode _currentSearchMode = SearchMode.regularGeocoding;
  AppLanguage _currentLanguage = AppLanguage.system;
  bool _initialized = false;

  /// Stream of search mode changes.
  Stream<SearchMode> get searchModeStream => _searchModeController.stream;

  /// Stream of language changes.
  Stream<AppLanguage> get languageStream => _languageController.stream;

  /// Current search mode.
  SearchMode get searchMode => _currentSearchMode;

  /// Current language setting.
  AppLanguage get language => _currentLanguage;

  /// Returns the effective locale (resolves system to actual locale).
  Locale get effectiveLocale {
    if (_currentLanguage == AppLanguage.system) {
      final systemLocale = ui.PlatformDispatcher.instance.locale;
      // Check if system language is supported, otherwise default to English
      if (systemLocale.languageCode == 'ru') {
        return const Locale('ru');
      }
      return const Locale('en');
    }
    return _currentLanguage.locale ?? const Locale('en');
  }

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  /// Initializes the settings service by loading stored values.
  Future<void> init() async {
    if (_initialized) {
      _log('Already initialized');
      return;
    }

    _log('Initializing...');
    final prefs = await SharedPreferences.getInstance();

    // Load search mode
    final searchModeIndex = prefs.getInt(_searchModeKey);
    if (searchModeIndex != null &&
        searchModeIndex >= 0 &&
        searchModeIndex < SearchMode.values.length) {
      _currentSearchMode = SearchMode.values[searchModeIndex];
    }

    // Load language
    final languageIndex = prefs.getInt(_languageKey);
    if (languageIndex != null &&
        languageIndex >= 0 &&
        languageIndex < AppLanguage.values.length) {
      _currentLanguage = AppLanguage.values[languageIndex];
    }

    _initialized = true;
    _log('Initialized', {
      'searchMode': _currentSearchMode.name,
      'language': _currentLanguage.name,
    });
  }

  /// Sets the search mode.
  Future<void> setSearchMode(SearchMode mode) async {
    if (mode == _currentSearchMode) return;

    _log('Setting search mode', {'from': _currentSearchMode.name, 'to': mode.name});

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_searchModeKey, mode.index);

    _currentSearchMode = mode;
    _searchModeController.add(mode);

    _log('Search mode updated', {'mode': mode.name});
  }

  /// Sets the app language.
  Future<void> setLanguage(AppLanguage language) async {
    if (language == _currentLanguage) return;

    _log('Setting language', {'from': _currentLanguage.name, 'to': language.name});

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_languageKey, language.index);

    _currentLanguage = language;
    _languageController.add(language);

    _log('Language updated', {'language': language.name});
  }

  /// Disposes resources.
  void dispose() {
    _searchModeController.close();
    _languageController.close();
    _log('Disposed');
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[SettingsService] $message$dataStr');
  }
}
