import '../../client/qorvia_maps_client.dart';
import '../../config/transport_mode.dart';
import '../../exceptions/qorvia_maps_exception.dart';
import '../../models/coordinates.dart';
import '../../models/geocode/geocode_response.dart';
import '../../models/reverse/reverse_response.dart';
import '../../models/route/route_response.dart';
import '../../models/smart_search/smart_search_response.dart';
import '../../navigation/navigation_logger.dart';
import '../config/offline_config.dart';
import '../connectivity/connectivity_service.dart';
import '../connectivity/network_status.dart';
import '../database/cache_database.dart';
import '../repository/geocode_cache_repository.dart';
import '../repository/reverse_cache_repository.dart';
import '../repository/route_cache_repository.dart';
import '../repository/smart_search_cache_repository.dart';

const _logTag = 'OfflineAwareClient';

/// Client wrapper that provides offline support with automatic cache fallback.
///
/// This client wraps [QorviaMapsClient] and adds:
/// - Automatic caching of API responses
/// - Fallback to cached data when offline
/// - Fallback to cached data when API calls fail
///
/// ## Behavior
///
/// **Online mode:**
/// 1. Make API request
/// 2. On success: cache result and return
/// 3. On network error: try to return cached data
///
/// **Offline mode:**
/// 1. Return cached data if available
/// 2. Throw [OfflineException] if no cached data
///
/// ## Usage
///
/// ```dart
/// final client = OfflineAwareClient(
///   apiClient: QorviaMapsClient(apiKey: 'xxx'),
///   database: CacheDatabase(),
///   config: OfflineConfig(),
/// );
///
/// // Works the same as QorviaMapsClient
/// final result = await client.geocode(query: 'Moscow');
///
/// // But automatically uses cache when offline
/// ```
class OfflineAwareClient {
  final QorviaMapsClient _apiClient;
  final CacheDatabase _database;
  final OfflineConfig _config;
  final ConnectivityService _connectivity;

  late final GeocodeCacheRepository _geocodeCache;
  late final ReverseCacheRepository _reverseCache;
  late final RouteCacheRepository _routeCache;
  late final SmartSearchCacheRepository _smartSearchCache;

  bool _isInitialized = false;

  OfflineAwareClient({
    required QorviaMapsClient apiClient,
    required CacheDatabase database,
    required OfflineConfig config,
    ConnectivityService? connectivity,
  })  : _apiClient = apiClient,
        _database = database,
        _config = config,
        _connectivity = connectivity ?? ConnectivityService.instance {
    _geocodeCache = GeocodeCacheRepository(_database, _config);
    _reverseCache = ReverseCacheRepository(_database, _config);
    _routeCache = RouteCacheRepository(_database, _config);
    _smartSearchCache = SmartSearchCacheRepository(_database, _config);
  }

  /// Initialize the offline client.
  ///
  /// This should be called once before using the client.
  /// It initializes the connectivity service and optionally cleans up
  /// expired cache entries.
  Future<void> initialize() async {
    if (_isInitialized) return;

    NavigationLogger.info(_logTag, 'Initializing offline client');

    // Initialize connectivity service
    if (!_connectivity.isInitialized) {
      await _connectivity.initialize();
    }

    // Cleanup expired entries on startup if configured
    if (_config.cleanupOnStartup) {
      await cleanupExpiredEntries();
    }

    _isInitialized = true;
    NavigationLogger.info(_logTag, 'Initialization complete', {
      'networkStatus': _connectivity.currentStatus.name,
    });
  }

  /// Current network status.
  NetworkStatus get networkStatus => _connectivity.currentStatus;

  /// Whether the device is currently online.
  bool get isOnline => _connectivity.currentStatus.isConnected;

  // ==================== GEOCODING ====================

  /// Geocode an address with offline fallback.
  Future<GeocodeResponse> geocode({
    required String query,
    int limit = 5,
    String language = 'en',
    List<String>? countryCodes,
    double? userLat,
    double? userLon,
    double? radiusKm,
    bool? biasLocation,
  }) async {
    final cacheParams = {
      'query': query,
      'language': language,
      'biasLat': userLat,
      'biasLon': userLon,
    };

    // Try cache first if offline
    if (!isOnline) {
      NavigationLogger.debug(_logTag, 'Offline mode, checking cache', cacheParams);
      final cached = await _geocodeCache.getByQuery(
        query: query,
        language: language,
        biasLat: userLat,
        biasLon: userLon,
      );

      if (cached != null) {
        NavigationLogger.info(_logTag, 'Returning cached geocode result');
        return cached;
      }

      throw OfflineException(
        message: 'No cached geocoding results available for "$query"',
        dataType: 'geocode',
        searchParams: cacheParams,
      );
    }

    // Online mode: try API, fallback to cache on error
    try {
      NavigationLogger.debug(_logTag, 'Online mode, making API request', cacheParams);

      final response = await _apiClient.geocode(
        query: query,
        limit: limit,
        language: language,
        countryCodes: countryCodes,
        userLat: userLat,
        userLon: userLon,
        radiusKm: radiusKm,
        biasLocation: biasLocation,
      );

      // Cache the result
      await _geocodeCache.putByQuery(
        query: query,
        response: response,
        language: language,
        biasLat: userLat,
        biasLon: userLon,
      );

      return response;
    } on NetworkException catch (e) {
      NavigationLogger.debug(_logTag, 'API failed, trying cache', {'error': e.message});

      final cached = await _geocodeCache.getByQuery(
        query: query,
        language: language,
        biasLat: userLat,
        biasLon: userLon,
      );

      if (cached != null) {
        NavigationLogger.info(_logTag, 'Returning cached result after API failure');
        return cached;
      }

      rethrow;
    }
  }

  // ==================== REVERSE GEOCODING ====================

  /// Reverse geocode coordinates with offline fallback.
  Future<ReverseResponse> reverse({
    required Coordinates coordinates,
    String language = 'en',
  }) async {
    return reverseLatLon(
      lat: coordinates.lat,
      lon: coordinates.lon,
      language: language,
    );
  }

  /// Reverse geocode lat/lon with offline fallback.
  Future<ReverseResponse> reverseLatLon({
    required double lat,
    required double lon,
    String language = 'en',
  }) async {
    final cacheParams = {'lat': lat, 'lon': lon, 'language': language};

    // Try cache first if offline
    if (!isOnline) {
      NavigationLogger.debug(_logTag, 'Offline mode, checking cache', cacheParams);

      final cached = await _reverseCache.getByCoordinates(
        lat: lat,
        lon: lon,
        language: language,
      );

      if (cached != null) {
        NavigationLogger.info(_logTag, 'Returning cached reverse result');
        return cached;
      }

      throw OfflineException(
        message: 'No cached reverse geocoding results for ($lat, $lon)',
        dataType: 'reverse',
        searchParams: cacheParams,
      );
    }

    // Online mode: try API, fallback to cache on error
    try {
      NavigationLogger.debug(_logTag, 'Online mode, making API request', cacheParams);

      final response = await _apiClient.reverseLatLon(
        lat: lat,
        lon: lon,
        language: language,
      );

      // Cache the result
      await _reverseCache.putByCoordinates(
        lat: lat,
        lon: lon,
        response: response,
        language: language,
      );

      return response;
    } on NetworkException catch (e) {
      NavigationLogger.debug(_logTag, 'API failed, trying cache', {'error': e.message});

      final cached = await _reverseCache.getByCoordinates(
        lat: lat,
        lon: lon,
        language: language,
      );

      if (cached != null) {
        NavigationLogger.info(_logTag, 'Returning cached result after API failure');
        return cached;
      }

      rethrow;
    }
  }

  // ==================== ROUTING ====================

  /// Calculate route with offline fallback.
  Future<RouteResponse> route({
    required Coordinates from,
    required Coordinates to,
    List<Coordinates>? waypoints,
    TransportMode mode = TransportMode.car,
    bool alternatives = false,
    bool steps = true,
    String language = 'en',
  }) async {
    final cacheParams = {
      'from': '${from.lat},${from.lon}',
      'to': '${to.lat},${to.lon}',
      'mode': mode.name,
    };

    // Try cache first if offline
    if (!isOnline) {
      NavigationLogger.debug(_logTag, 'Offline mode, checking cache', cacheParams);

      final cached = await _routeCache.getByRoute(
        from: from,
        to: to,
        transportMode: mode.name,
        waypoints: waypoints,
      );

      if (cached != null) {
        NavigationLogger.info(_logTag, 'Returning cached route');
        return cached;
      }

      throw OfflineException(
        message: 'No cached route available for this origin/destination',
        dataType: 'route',
        searchParams: cacheParams,
      );
    }

    // Online mode: try API, fallback to cache on error
    try {
      NavigationLogger.debug(_logTag, 'Online mode, making API request', cacheParams);

      final response = await _apiClient.route(
        from: from,
        to: to,
        waypoints: waypoints,
        mode: mode,
        alternatives: alternatives,
        steps: steps,
        language: language,
      );

      // Cache the result
      await _routeCache.putByRoute(
        from: from,
        to: to,
        transportMode: mode.name,
        response: response,
        waypoints: waypoints,
      );

      return response;
    } on NetworkException catch (e) {
      NavigationLogger.debug(_logTag, 'API failed, trying cache', {'error': e.message});

      final cached = await _routeCache.getByRoute(
        from: from,
        to: to,
        transportMode: mode.name,
        waypoints: waypoints,
      );

      if (cached != null) {
        NavigationLogger.info(_logTag, 'Returning cached result after API failure');
        return cached;
      }

      rethrow;
    }
  }

  // ==================== SMART SEARCH ====================

  /// Smart search with offline fallback.
  Future<SmartSearchResponse> smartSearch({
    required String query,
    required double lat,
    required double lon,
    int? radiusKm,
    int? limit,
    String? language,
  }) async {
    final effectiveRadiusKm = radiusKm?.toDouble() ?? 10.0;
    final cacheParams = {
      'query': query,
      'lat': lat,
      'lon': lon,
      'radiusKm': effectiveRadiusKm,
    };

    // Try cache first if offline
    if (!isOnline) {
      NavigationLogger.debug(_logTag, 'Offline mode, checking cache', cacheParams);

      final cached = await _smartSearchCache.getByQuery(
        query: query,
        lat: lat,
        lon: lon,
        radiusKm: effectiveRadiusKm,
        language: language,
      );

      if (cached != null) {
        NavigationLogger.info(_logTag, 'Returning cached smart search result');
        return cached;
      }

      throw OfflineException(
        message: 'No cached smart search results for "$query"',
        dataType: 'smartSearch',
        searchParams: cacheParams,
      );
    }

    // Online mode: try API, fallback to cache on error
    try {
      NavigationLogger.debug(_logTag, 'Online mode, making API request', cacheParams);

      final response = await _apiClient.smartSearch(
        query: query,
        lat: lat,
        lon: lon,
        radiusKm: radiusKm,
        limit: limit,
        language: language,
      );

      // Cache the result
      await _smartSearchCache.putByQuery(
        query: query,
        lat: lat,
        lon: lon,
        radiusKm: effectiveRadiusKm,
        response: response,
        language: language,
      );

      return response;
    } on NetworkException catch (e) {
      NavigationLogger.debug(_logTag, 'API failed, trying cache', {'error': e.message});

      final cached = await _smartSearchCache.getByQuery(
        query: query,
        lat: lat,
        lon: lon,
        radiusKm: effectiveRadiusKm,
        language: language,
      );

      if (cached != null) {
        NavigationLogger.info(_logTag, 'Returning cached result after API failure');
        return cached;
      }

      rethrow;
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clean up expired cache entries.
  Future<Map<String, int>> cleanupExpiredEntries() async {
    NavigationLogger.info(_logTag, 'Cleaning up expired entries');
    return _database.cleanupExpiredEntries();
  }

  /// Get cache statistics.
  Future<Map<String, int>> getCacheStats() async {
    return _database.getCacheStats();
  }

  /// Clear all cached data.
  Future<void> clearAllCaches() async {
    NavigationLogger.info(_logTag, 'Clearing all caches');
    await _database.clearAllCaches();
  }

  /// Clear geocoding cache.
  Future<void> clearGeocodeCache() async {
    await _geocodeCache.clear();
  }

  /// Clear reverse geocoding cache.
  Future<void> clearReverseCache() async {
    await _reverseCache.clear();
  }

  /// Clear route cache.
  Future<void> clearRouteCache() async {
    await _routeCache.clear();
  }

  /// Clear smart search cache.
  Future<void> clearSmartSearchCache() async {
    await _smartSearchCache.clear();
  }

  /// Get database size in bytes.
  Future<int> getDatabaseSize() async {
    return _database.getDatabaseSize();
  }

  // ==================== PASS-THROUGH METHODS ====================

  /// These methods don't need offline support as they are
  /// administrative or require real-time data.

  /// Get quota information (requires online).
  Future<dynamic> quota() => _apiClient.quota();

  /// Get usage statistics (requires online).
  Future<dynamic> usage() => _apiClient.usage();

  /// Get tile URL (requires online, but cached by SDK).
  Future<String> tileUrl() => _apiClient.tileUrl();

  // ==================== LIFECYCLE ====================

  /// Dispose the client and release resources.
  void dispose() {
    _apiClient.dispose();
  }
}
