import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

import 'client/qorvia_maps_client.dart';
import 'map/map_options.dart';
import 'offline/config/offline_config.dart';
import 'offline/client/offline_aware_client.dart';
import 'offline/connectivity/connectivity_service.dart';
import 'offline/connectivity/network_status.dart';
import 'offline/database/cache_database.dart';
import 'offline/tiles/offline_region.dart';
import 'offline/tiles/offline_tile_manager.dart';

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
  static OfflineConfig? _offlineConfig;

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
  CacheDatabase? _cacheDatabase;
  OfflineAwareClient? _offlineClient;
  OfflineTileManager? _offlineTileManager;
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

  /// The offline-aware client, if offline mode is enabled.
  OfflineAwareClient? get offlineClient => _offlineClient;

  /// Whether offline mode is enabled.
  static bool get isOfflineEnabled => _offlineConfig?.enabled ?? false;

  /// Current network status.
  static NetworkStatus get networkStatus =>
      ConnectivityService.instance.currentStatus;

  /// Whether the device is currently online.
  static bool get isOnline =>
      ConnectivityService.instance.currentStatus.isConnected;

  /// The connectivity service instance.
  static ConnectivityService get connectivity => ConnectivityService.instance;

  /// The offline tile manager for downloading map regions.
  ///
  /// Returns null if offline mode is not enabled or not initialized.
  static OfflineTileManager? get offlineManager => _instance?._offlineTileManager;

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
  /// [offlineConfig] - Optional configuration for offline mode.
  ///
  /// Example:
  /// ```dart
  /// await QorviaMapsSDK.init(
  ///   apiKey: 'geoapi_live_xxx',
  ///   baseUrl: 'https://api.basemaps.com',
  ///   enableLogging: true,
  ///   offlineConfig: OfflineConfig(
  ///     enabled: true,
  ///     geocodeTtl: Duration(hours: 48),
  ///   ),
  /// );
  /// ```
  static Future<void> init({
    required String apiKey,
    String? baseUrl,
    bool enableLogging = false,
    bool prefetchTileUrl = true,
    OfflineConfig? offlineConfig,
  }) async {
    _enableLogging = enableLogging;
    _offlineConfig = offlineConfig;

    _log('init() called', {
      'baseUrl': baseUrl ?? 'default',
      'enableLogging': enableLogging,
      'prefetchTileUrl': prefetchTileUrl,
      'offlineEnabled': offlineConfig?.enabled ?? false,
    });

    // Create or update instance
    _instance ??= QorviaMapsSDK._();

    // Dispose old resources if re-initializing
    _instance!._client?.dispose();
    _instance!._offlineClient?.dispose();
    _instance!._cachedTileUrl = null;

    // Create new client
    _instance!._client = QorviaMapsClient(
      apiKey: apiKey,
      baseUrl: baseUrl,
      enableLogging: enableLogging,
    );

    // Initialize offline support if enabled
    if (offlineConfig?.enabled ?? false) {
      await _instance!._initializeOfflineSupport(offlineConfig!);
    }

    _log('SDK initialized successfully');

    // Prefetch tile URL in background
    if (prefetchTileUrl) {
      _instance!._fetchTileUrl();
    }
  }

  /// Initialize offline support with cache database and offline client.
  Future<void> _initializeOfflineSupport(OfflineConfig config) async {
    _log('Initializing offline support', {
      'geocodeTtl': config.geocodeTtl.inHours,
      'routeTtl': config.routeTtl.inMinutes,
      'cleanupOnStartup': config.cleanupOnStartup,
    });

    try {
      // Create cache database
      _cacheDatabase = CacheDatabase();

      // Create offline-aware client
      _offlineClient = OfflineAwareClient(
        apiClient: _client!,
        database: _cacheDatabase!,
        config: config,
      );

      // Initialize offline client (starts connectivity monitoring)
      await _offlineClient!.initialize();

      // Create and initialize offline tile manager
      _offlineTileManager = OfflineTileManager(
        database: _cacheDatabase!,
        downloadService: _client!.tileDownload,
        defaultStyleUrl: '', // Will be set when tile URL is fetched
      );
      await _offlineTileManager!.initialize();

      _log('Offline support initialized', {
        'networkStatus': ConnectivityService.instance.currentStatus.name,
      });
    } catch (e) {
      _log('Failed to initialize offline support', {'error': e.toString()}, true);
      // Don't fail SDK initialization if offline setup fails
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

  /// Whether we're currently using offline mode.
  bool _isOfflineMode = false;

  /// Whether we're currently using offline mode.
  bool get isOfflineMode => _isOfflineMode;

  /// Path to cached style file.
  String? _cachedStyleFilePath;

  Future<String> _fetchTileUrl() async {
    _tileUrlLoading = true;
    _log('Fetching tile URL from server...');

    try {
      final url = await _client!.tileUrl();
      _cachedTileUrl = url;
      _tileUrlLoading = false;
      _isOfflineMode = false;

      _log('Tile URL fetched successfully', {'url': url});

      // Cache the style JSON for offline use (do not await - background operation)
      _cacheStyleJson(url);

      // Notify waiters
      _notifyWaiters(url);

      return url;
    } catch (e) {
      _tileUrlLoading = false;
      _log('Failed to fetch tile URL', {'error': e.toString()}, true);

      // Check if we have cached style
      final cachedPath = await _getCachedStylePath();
      _log('Cached style check', {
        'hasCachedStyle': cachedPath != null,
        'path': cachedPath,
      });

      // Fallback chain: Cached style → OSM
      final fallback = await _getFallbackStyleUrl();
      _log('Using fallback', {
        'isOfflineMode': _isOfflineMode,
        'fallbackLength': fallback.length,
        'isJson': fallback.startsWith('{'),
      });
      _notifyWaiters(fallback);

      return fallback;
    }
  }

  /// Caches the style JSON locally for offline use.
  /// Also resolves and inlines TileJSON sources for full offline support.
  Future<void> _cacheStyleJson(String styleUrl) async {
    try {
      _log('Caching style JSON', {'url': styleUrl});

      // Download style JSON using Dio
      final dio = Dio();
      final response = await dio.get<String>(styleUrl);
      if (response.statusCode != 200 || response.data == null) {
        _log('Failed to download style JSON', {
          'statusCode': response.statusCode,
        }, true);
        return;
      }

      // Parse style JSON
      final styleJson = jsonDecode(response.data!) as Map<String, dynamic>;

      // Process sources - resolve TileJSON URLs and inline them
      final sources = styleJson['sources'] as Map<String, dynamic>?;
      if (sources != null) {
        for (final entry in sources.entries) {
          final sourceConfig = entry.value as Map<String, dynamic>;
          final sourceUrl = sourceConfig['url'] as String?;

          // If source has a URL (TileJSON reference), resolve it
          if (sourceUrl != null && sourceUrl.startsWith('http')) {
            _log('Resolving TileJSON', {'source': entry.key, 'url': sourceUrl});

            try {
              final tileJsonResponse = await dio.get<String>(sourceUrl);
              if (tileJsonResponse.statusCode == 200 && tileJsonResponse.data != null) {
                final tileJson = jsonDecode(tileJsonResponse.data!) as Map<String, dynamic>;

                // Extract tiles array and other properties from TileJSON
                final tiles = tileJson['tiles'] as List<dynamic>?;
                final minZoom = tileJson['minzoom'];
                final maxZoom = tileJson['maxzoom'];
                final bounds = tileJson['bounds'];

                if (tiles != null) {
                  // Replace URL with inline tiles array
                  sourceConfig.remove('url');
                  sourceConfig['tiles'] = tiles;
                  if (minZoom != null) sourceConfig['minzoom'] = minZoom;
                  if (maxZoom != null) sourceConfig['maxzoom'] = maxZoom;
                  if (bounds != null) sourceConfig['bounds'] = bounds;

                  _log('TileJSON inlined', {
                    'source': entry.key,
                    'tiles': tiles.length,
                  });
                }
              }
            } catch (e) {
              _log('Failed to resolve TileJSON', {
                'source': entry.key,
                'error': e.toString(),
              }, true);
            }
          }
        }
      }

      // Save modified style to local file
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(path.join(appDir.path, 'offline_tiles'));
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final modifiedStyleJson = jsonEncode(styleJson);
      final styleFile = File(path.join(cacheDir.path, 'cached_style.json'));
      await styleFile.writeAsString(modifiedStyleJson);

      _cachedStyleFilePath = styleFile.path;
      _log('Style JSON cached', {
        'path': _cachedStyleFilePath,
        'size': modifiedStyleJson.length,
      });
    } catch (e) {
      _log('Failed to cache style JSON', {'error': e.toString()}, true);
    }
  }

  /// Gets fallback style URL when server is unavailable.
  ///
  /// Tries to create offline style with mbtiles, then cached style, then OSM.
  Future<String> _getFallbackStyleUrl() async {
    _log('Attempting offline fallback...');

    try {
      // First, try to create style with mbtiles sources
      final offlineStyle = await _createOfflineMbtilesStyle();
      if (offlineStyle != null) {
        _log('Using offline mbtiles style', {'size': offlineStyle.length});
        _isOfflineMode = true;
        _cachedTileUrl = offlineStyle;
        return offlineStyle;
      }

      // Fallback to cached style (tiles from MapLibre cache)
      final cachedStylePath = await _getCachedStylePath();
      if (cachedStylePath != null) {
        final file = File(cachedStylePath);
        if (await file.exists()) {
          final styleContent = await file.readAsString();
          _log('Using cached style', {
            'path': cachedStylePath,
            'size': styleContent.length,
          });
          _isOfflineMode = true;
          _cachedTileUrl = styleContent;
          return styleContent;
        }
      }
    } catch (e) {
      _log('Failed to get offline style', {'error': e.toString()}, true);
    }

    // Final fallback: OSM
    _log('Using OSM fallback style');
    _isOfflineMode = false;
    return MapStyles.openFreeMapLiberty;
  }

  /// Creates offline style JSON using mbtiles sources.
  Future<String?> _createOfflineMbtilesStyle() async {
    final tileManager = _offlineTileManager;
    if (tileManager == null || !tileManager.hasOfflineRegions) {
      _log('No offline regions available');
      return null;
    }

    // Get cached style as base
    final cachedStylePath = await _getCachedStylePath();
    if (cachedStylePath == null) {
      _log('No cached style to modify');
      return null;
    }

    final file = File(cachedStylePath);
    if (!await file.exists()) {
      return null;
    }

    try {
      final styleContent = await file.readAsString();
      final styleJson = jsonDecode(styleContent) as Map<String, dynamic>;

      // Get completed regions with mbtiles files
      final regions = tileManager.completedRegions;
      if (regions.isEmpty) {
        _log('No completed regions with files');
        return null;
      }

      // Get the first region's mbtiles path (for now, use single region)
      final region = regions.first;
      if (region.filePath == null) {
        return null;
      }

      final mbtilesFile = File(region.filePath!);
      if (!await mbtilesFile.exists()) {
        _log('Mbtiles file not found', {'path': region.filePath});
        return null;
      }

      _log('Creating offline style with mbtiles', {
        'region': region.name,
        'filePath': region.filePath,
      });

      // Modify sources to use mbtiles://
      final sources = styleJson['sources'] as Map<String, dynamic>?;
      if (sources != null) {
        for (final entry in sources.entries) {
          final sourceConfig = entry.value as Map<String, dynamic>;
          final sourceType = sourceConfig['type'] as String?;

          // Replace tiles URL with mbtiles path
          if (sourceType == 'vector' || sourceType == 'raster') {
            // Remove url and tiles, use mbtiles:// URL
            sourceConfig.remove('url');
            sourceConfig.remove('tiles');
            // mbtiles:// protocol points directly to the file
            sourceConfig['url'] = 'mbtiles://${region.filePath}';

            _log('Modified source for offline', {
              'source': entry.key,
              'type': sourceType,
              'mbtilesUrl': sourceConfig['url'],
            });
          }
        }
      }

      final modifiedStyle = jsonEncode(styleJson);
      _log('Offline mbtiles style created', {'size': modifiedStyle.length});

      return modifiedStyle;
    } catch (e) {
      _log('Failed to create offline mbtiles style', {'error': e.toString()}, true);
      return null;
    }
  }

  /// Gets the path to cached style file if it exists.
  Future<String?> _getCachedStylePath() async {
    if (_cachedStyleFilePath != null) {
      return _cachedStyleFilePath;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final stylePath = path.join(appDir.path, 'offline_tiles', 'cached_style.json');
      final file = File(stylePath);
      if (await file.exists()) {
        _cachedStyleFilePath = stylePath;
        return stylePath;
      }
    } catch (e) {
      _log('Error checking cached style', {'error': e.toString()}, true);
    }

    return null;
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
  static Future<void> dispose() async {
    _log('dispose() called');

    await _instance?._offlineTileManager?.dispose();
    _instance?._offlineTileManager = null;
    _instance?._offlineClient?.dispose();
    _instance?._offlineClient = null;
    await _instance?._cacheDatabase?.close();
    _instance?._cacheDatabase = null;
    _instance?._client?.dispose();
    _instance?._client = null;
    _instance?._cachedTileUrl = null;
    _offlineConfig = null;
    ConnectivityService.resetInstance();
    _instance = null;
  }

  // ==================== OFFLINE CACHE METHODS ====================

  /// Clean up expired cache entries.
  ///
  /// Returns a map of cache types to number of entries removed.
  static Future<Map<String, int>> cleanupCache() async {
    if (_instance?._offlineClient == null) {
      return {};
    }
    return _instance!._offlineClient!.cleanupExpiredEntries();
  }

  /// Get cache statistics.
  ///
  /// Returns a map of cache types to number of entries.
  static Future<Map<String, int>> getCacheStats() async {
    if (_instance?._offlineClient == null) {
      return {};
    }
    return _instance!._offlineClient!.getCacheStats();
  }

  /// Clear all cached data.
  static Future<void> clearAllCaches() async {
    if (_instance?._offlineClient == null) {
      return;
    }
    await _instance!._offlineClient!.clearAllCaches();
  }

  /// Get total cache database size in bytes.
  static Future<int> getCacheSize() async {
    if (_instance?._offlineClient == null) {
      return 0;
    }
    return _instance!._offlineClient!.getDatabaseSize();
  }

  // ==================== OFFLINE TILE METHODS ====================

  /// Get all downloaded offline regions.
  ///
  /// Returns an empty list if offline mode is not enabled.
  static Future<List<OfflineRegion>> getOfflineRegions() async {
    if (_instance?._offlineTileManager == null) {
      return [];
    }
    return _instance!._offlineTileManager!.getAllRegions();
  }

  /// Get an offline region by ID.
  ///
  /// Returns null if not found or offline mode is not enabled.
  static Future<OfflineRegion?> getOfflineRegion(String regionId) async {
    return _instance?._offlineTileManager?.getRegion(regionId);
  }

  /// Delete an offline region and its downloaded tiles.
  ///
  /// Does nothing if offline mode is not enabled or region not found.
  static Future<void> deleteOfflineRegion(String regionId) async {
    await _instance?._offlineTileManager?.deleteRegion(regionId);
  }

  /// Get total size of all downloaded offline regions in bytes.
  static Future<int> getOfflineRegionsSize() async {
    if (_instance?._offlineTileManager == null) {
      return 0;
    }
    return _instance!._offlineTileManager!.getTotalDownloadedSize();
  }

  /// Get count of fully downloaded regions.
  static int get completedOfflineRegionsCount {
    return _instance?._offlineTileManager?.completedRegionsCount ?? 0;
  }

  /// Whether the SDK is currently using offline mode.
  static bool get isUsingOfflineMode => _instance?._isOfflineMode ?? false;

  /// Checks if offline tiles are available.
  ///
  /// Returns true if there are completed offline regions.
  static bool get hasOfflineTiles =>
      _instance?._offlineTileManager?.hasOfflineRegions ?? false;

  /// Checks if cached style is available for offline use.
  ///
  /// Returns true if we have a cached style JSON file.
  static Future<bool> get hasCachedStyle async {
    final path = await _instance?._getCachedStylePath();
    return path != null;
  }

  /// Gets the cached style path if available.
  ///
  /// Returns null if no cached style exists.
  static Future<String?> getCachedStylePath() async {
    return _instance?._getCachedStylePath();
  }

  /// Forces the SDK to re-fetch the tile URL.
  ///
  /// This will try the server first, then fall back to offline or OSM.
  static Future<String> refreshTileUrl() async {
    if (_instance == null) {
      throw StateError('QorviaMapsSDK is not initialized');
    }
    _instance!._cachedTileUrl = null;
    return _instance!._fetchTileUrl();
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
