import 'dart:async';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

/// Search mode options.
enum SearchMode {
  /// Smart geosearch - uses AI-enhanced search with better results.
  smartGeosearch,

  /// Regular geocoding - standard address lookup.
  regularGeocoding,
}

/// Settings service for managing app preferences.
///
/// Uses SharedPreferences for persistent storage.
/// Provides a stream for reactive updates.
class SettingsService {
  static const String _searchModeKey = 'search_mode';

  final StreamController<SearchMode> _searchModeController =
      StreamController<SearchMode>.broadcast();

  SearchMode _currentSearchMode = SearchMode.regularGeocoding;
  bool _initialized = false;

  /// Stream of search mode changes.
  Stream<SearchMode> get searchModeStream => _searchModeController.stream;

  /// Current search mode.
  SearchMode get searchMode => _currentSearchMode;

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

    _initialized = true;
    _log('Initialized', {'searchMode': _currentSearchMode.name});
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

  /// Disposes resources.
  void dispose() {
    _searchModeController.close();
    _log('Disposed');
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[SettingsService] $message$dataStr');
  }
}
