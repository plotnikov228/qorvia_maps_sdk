import 'dart:async';

import 'package:flutter/foundation.dart';

import 'client/qorvia_maps_client.dart';
import 'map/map_options.dart';

/// Global SDK initializer for Base Maps SDK.
///
/// Provides a centralized way to initialize the SDK and automatically
/// resolve tile URLs for all map widgets.
///
/// Example:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   await QorviaMapsSDK.init(
///     apiKey: 'geoapi_live_xxx',
///     baseUrl: 'https://api.basemaps.com',
///   );
///
///   runApp(MyApp());
/// }
/// ```
///
/// After initialization, [QorviaMapView] and [NavigationView] will
/// automatically use the tile URL from the server.
class QorviaMapsSDK {
  QorviaMapsSDK._();

  static QorviaMapsSDK? _instance;
  static bool _enableLogging = false;

  /// Returns the singleton instance of [QorviaMapsSDK].
  ///
  /// Throws [StateError] if SDK is not initialized.
  static QorviaMapsSDK get instance {
    if (_instance == null) {
      throw StateError(
        'QorviaMapsSDK is not initialized. Call QorviaMapsSDK.init() first.',
      );
    }
    return _instance!;
  }

  /// Returns the singleton instance if initialized, null otherwise.
  static QorviaMapsSDK? get instanceOrNull => _instance;

  /// Whether the SDK has been initialized.
  static bool get isInitialized => _instance != null;

  QorviaMapsClient? _client;
  String? _cachedTileUrl;
  bool _tileUrlLoading = false;
  List<void Function(String?)>? _tileUrlWaiters;

  /// The internal API client.
  QorviaMapsClient get client {
    if (_client == null) {
      throw StateError('QorviaMapsSDK client is not available.');
    }
    return _client!;
  }

  /// Whether the tile URL has been loaded.
  bool get hasTileUrl => _cachedTileUrl != null;

  /// The cached tile URL, or null if not yet loaded.
  String? get tileUrlOrNull => _cachedTileUrl;

  /// Initializes the SDK with the given configuration.
  ///
  /// This should be called once at app startup, typically in `main()`.
  ///
  /// [apiKey] - Your API key for authentication.
  /// [baseUrl] - Optional custom API base URL.
  /// [enableLogging] - Enable debug logging (default: false).
  /// [prefetchTileUrl] - Whether to fetch tile URL immediately (default: true).
  ///
  /// Example:
  /// ```dart
  /// await QorviaMapsSDK.init(
  ///   apiKey: 'geoapi_live_xxx',
  ///   baseUrl: 'https://api.basemaps.com',
  ///   enableLogging: true,
  /// );
  /// ```
  static Future<void> init({
    required String apiKey,
    String? baseUrl,
    bool enableLogging = false,
    bool prefetchTileUrl = true,
  }) async {
    _enableLogging = enableLogging;

    _log('init() called', {
      'baseUrl': baseUrl ?? 'default',
      'enableLogging': enableLogging,
      'prefetchTileUrl': prefetchTileUrl,
    });

    // Create or update instance
    _instance ??= QorviaMapsSDK._();

    // Dispose old client if re-initializing
    _instance!._client?.dispose();
    _instance!._cachedTileUrl = null;

    // Create new client
    _instance!._client = QorviaMapsClient(
      apiKey: apiKey,
      baseUrl: baseUrl,
      enableLogging: enableLogging,
    );

    _log('SDK initialized successfully');

    // Prefetch tile URL in background
    if (prefetchTileUrl) {
      _instance!._fetchTileUrl();
    }
  }

  /// Returns the tile URL, fetching it from server if necessary.
  ///
  /// Returns the cached URL if available, otherwise fetches from server.
  /// Returns fallback URL if fetch fails.
  Future<String> getTileUrl() async {
    if (_cachedTileUrl != null) {
      _log('getTileUrl() returning cached URL', {'url': _cachedTileUrl});
      return _cachedTileUrl!;
    }

    // If already loading, wait for result
    if (_tileUrlLoading) {
      _log('getTileUrl() waiting for in-flight request');
      return _waitForTileUrl();
    }

    return _fetchTileUrl();
  }

  Future<String> _fetchTileUrl() async {
    _tileUrlLoading = true;
    _log('Fetching tile URL from server...');

    try {
      final url = await _client!.tileUrl();
      _cachedTileUrl = url;
      _tileUrlLoading = false;

      _log('Tile URL fetched successfully', {'url': url});

      // Notify waiters
      _notifyWaiters(url);

      return url;
    } catch (e) {
      _tileUrlLoading = false;
      _log('Failed to fetch tile URL', {'error': e.toString()}, true);

      // Use fallback
      const fallback = MapStyles.openFreeMapLiberty;
      _notifyWaiters(fallback);

      return fallback;
    }
  }

  Future<String> _waitForTileUrl() {
    final completer = Completer<String>();

    _tileUrlWaiters ??= [];
    _tileUrlWaiters!.add((url) {
      completer.complete(url ?? MapStyles.openFreeMapLiberty);
    });

    return completer.future;
  }

  void _notifyWaiters(String? url) {
    final waiters = _tileUrlWaiters;
    _tileUrlWaiters = null;

    if (waiters != null) {
      for (final waiter in waiters) {
        waiter(url);
      }
    }
  }

  /// Clears the cached tile URL, forcing a re-fetch on next request.
  void clearTileUrlCache() {
    _log('Clearing tile URL cache');
    _cachedTileUrl = null;
  }

  /// Disposes the SDK and releases resources.
  ///
  /// After calling this, [init] must be called again before using the SDK.
  static void dispose() {
    _log('dispose() called');

    _instance?._client?.dispose();
    _instance?._client = null;
    _instance?._cachedTileUrl = null;
    _instance = null;
  }

  static void _log(String message, [Map<String, dynamic>? data, bool isError = false]) {
    if (!_enableLogging) return;

    final prefix = '[QorviaMapsSDK]';
    final dataStr = data != null ? ' $data' : '';

    if (isError) {
      debugPrint('$prefix ERROR: $message$dataStr');
    } else {
      debugPrint('$prefix $message$dataStr');
    }
  }
}
