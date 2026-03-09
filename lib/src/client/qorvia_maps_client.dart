import '../config/sdk_config.dart';
import '../config/transport_mode.dart';
import '../models/coordinates.dart';
import '../models/route/route_response.dart';
import '../models/geocode/geocode_response.dart';
import '../models/geocode/geocode_result.dart';
import '../models/reverse/reverse_response.dart';
import '../models/quota/quota_response.dart';
import '../models/usage/usage_response.dart';
import '../services/routing_service.dart';
import '../services/geocoding_service.dart';
import '../services/reverse_service.dart';
import '../services/quota_service.dart';
import '../services/tile_service.dart';
import '../services/smart_search_service.dart';
import '../services/tile_download_service.dart';
import '../models/tile/tile_url_response.dart';
import '../models/smart_search/smart_search_response.dart';
import '../models/smart_search/smart_search_result.dart';
import 'http_client.dart';

/// Main client for Qorvia Maps SDK.
///
/// Provides access to all geo services: routing, geocoding, and reverse geocoding.
///
/// Example:
/// ```dart
/// final client = QorviaMapsClient(apiKey: 'your_api_key');
///
/// // Calculate route
/// final route = await client.route(
///   from: Coordinates(lat: 55.7539, lon: 37.6208),
///   to: Coordinates(lat: 55.7614, lon: 37.6500),
/// );
///
/// // Geocode address
/// final results = await client.geocode(query: 'Красная площадь');
///
/// // Don't forget to dispose when done
/// client.dispose();
/// ```
class QorviaMapsClient {
  final SdkConfig _config;
  late final QorviaMapsHttpClient _httpClient;

  // Lazy-initialized services
  RoutingService? _routingService;
  GeocodingService? _geocodingService;
  ReverseService? _reverseService;
  QuotaService? _quotaService;
  TileService? _tileService;
  SmartSearchService? _smartSearchService;
  TileDownloadService? _tileDownloadService;

  /// Creates a new QorviaMapsClient.
  ///
  /// [apiKey] - Your API key from the admin panel.
  /// [baseUrl] - Optional custom API base URL.
  /// [timeoutMs] - Request timeout in milliseconds (default: 30000).
  /// [enableLogging] - Enable debug logging (default: false).
  ///
  /// The bundle ID is automatically resolved from the app's package info.
  QorviaMapsClient({
    required String apiKey,
    String? baseUrl,
    int timeoutMs = 30000,
    bool enableLogging = false,
  }) : _config = SdkConfig(
          apiKey: apiKey,
          baseUrl: baseUrl ?? 'https://qorviamapkit.ru',
          timeoutMs: timeoutMs,
          enableLogging: enableLogging,
        ) {
    _httpClient = QorviaMapsHttpClient(_config);
  }

  /// Creates a client from a configuration object.
  QorviaMapsClient.fromConfig(this._config) {
    _httpClient = QorviaMapsHttpClient(_config);
  }

  // Service getters with lazy initialization
  RoutingService get _routing =>
      _routingService ??= RoutingService(_httpClient, _config);
  GeocodingService get _geocoding => _geocodingService ??= GeocodingService(_httpClient);
  ReverseService get _reverse => _reverseService ??= ReverseService(_httpClient);
  QuotaService get _quota => _quotaService ??= QuotaService(_httpClient);
  TileService get _tile => _tileService ??= TileService(_httpClient);
  SmartSearchService get _smartSearch =>
      _smartSearchService ??= SmartSearchService(_httpClient);

  /// Service for downloading offline map tiles.
  ///
  /// Provides access to server-side tile extraction and download functionality.
  TileDownloadService get tileDownload =>
      _tileDownloadService ??= TileDownloadService(_httpClient);

  // ==================== ROUTING ====================

  /// Calculates a route between two points with optional waypoints.
  ///
  /// [from] - Starting point coordinates.
  /// [to] - Destination point coordinates.
  /// [waypoints] - Optional intermediate waypoints (max 20).
  /// [mode] - Transport mode (default: car).
  /// [alternatives] - Include alternative routes (default: false).
  /// [steps] - Include step-by-step instructions (default: true).
  /// [language] - Language for instructions: 'en', 'ru' (default: 'en').
  ///
  /// Returns [RouteResponse] with route details including decoded polyline.
  ///
  /// Example without waypoints:
  /// ```dart
  /// final route = await client.route(
  ///   from: Coordinates(lat: 55.7539, lon: 37.6208),
  ///   to: Coordinates(lat: 55.7614, lon: 37.6500),
  ///   mode: TransportMode.car,
  ///   language: 'ru',
  /// );
  /// print('Distance: ${route.formattedDistance}');
  /// print('Duration: ${route.formattedDuration}');
  /// ```
  ///
  /// Example with waypoints:
  /// ```dart
  /// final route = await client.route(
  ///   from: Coordinates(lat: 55.7558, lon: 37.6173),
  ///   to: Coordinates(lat: 55.7000, lon: 37.5000),
  ///   waypoints: [
  ///     Coordinates(lat: 55.7400, lon: 37.5800),
  ///     Coordinates(lat: 55.7200, lon: 37.5500),
  ///   ],
  ///   mode: TransportMode.car,
  /// );
  ///
  /// // Track waypoint progress
  /// for (final step in route.steps ?? []) {
  ///   if (step.waypointIndex != null) {
  ///     print('Reached waypoint ${step.waypointIndex! + 1}');
  ///   }
  /// }
  /// ```
  Future<RouteResponse> route({
    required Coordinates from,
    required Coordinates to,
    List<Coordinates>? waypoints,
    TransportMode mode = TransportMode.car,
    bool alternatives = false,
    bool steps = true,
    String language = 'en',
  }) {
    return _routing.getRoute(
      from: from,
      to: to,
      waypoints: waypoints,
      mode: mode,
      alternatives: alternatives,
      steps: steps,
      language: language,
    );
  }

  // ==================== GEOCODING ====================

  /// Converts an address to coordinates.
  ///
  /// [query] - Search query (address, place name, etc.).
  /// [limit] - Maximum number of results (1-20, default: 5).
  /// [language] - Language for results (default: 'en').
  /// [countryCodes] - Filter by country codes (e.g., ['ru', 'kz']).
  /// [userLat] - User's latitude for location-biased results.
  /// [userLon] - User's longitude for location-biased results.
  /// [radiusKm] - Search radius in kilometers (default: 50).
  /// [biasLocation] - Whether to prioritize results near user location.
  ///
  /// Returns [GeocodeResponse] with list of results.
  ///
  /// Example without location bias:
  /// ```dart
  /// final response = await client.geocode(
  ///   query: 'Красная площадь, Москва',
  ///   limit: 3,
  ///   language: 'ru',
  /// );
  /// for (final result in response.results) {
  ///   print('${result.displayName}: ${result.coordinates}');
  /// }
  /// ```
  ///
  /// Example with location bias:
  /// ```dart
  /// final response = await client.geocode(
  ///   query: 'вокзал',
  ///   limit: 5,
  ///   language: 'ru',
  ///   userLat: 53.404935,
  ///   userLon: 58.965423,
  ///   radiusKm: 50,
  ///   biasLocation: true,
  /// );
  /// // Results will be prioritized by proximity to user location
  /// ```
  Future<GeocodeResponse> geocode({
    required String query,
    int limit = 5,
    String language = 'en',
    List<String>? countryCodes,
    double? userLat,
    double? userLon,
    double? radiusKm,
    bool? biasLocation,
  }) {
    return _geocoding.geocode(
      query: query,
      limit: limit,
      language: language,
      countryCodes: countryCodes,
      userLat: userLat,
      userLon: userLon,
      radiusKm: radiusKm,
      biasLocation: biasLocation,
    );
  }

  /// Searches for a single best match.
  ///
  /// Convenience method that returns just the first result.
  /// Returns null if no results found.
  ///
  /// [userLat], [userLon], [radiusKm], [biasLocation] - location bias params.
  Future<GeocodeResult?> search(
    String query, {
    String language = 'en',
    List<String>? countryCodes,
    double? userLat,
    double? userLon,
    double? radiusKm,
    bool? biasLocation,
  }) {
    return _geocoding.search(
      query,
      language: language,
      countryCodes: countryCodes,
      userLat: userLat,
      userLon: userLon,
      radiusKm: radiusKm,
      biasLocation: biasLocation,
    );
  }

  // ==================== REVERSE GEOCODING ====================

  /// Converts coordinates to an address.
  ///
  /// [coordinates] - Location coordinates.
  /// [language] - Language for results (default: 'en').
  ///
  /// Returns [ReverseResponse] with address details.
  ///
  /// Example:
  /// ```dart
  /// final address = await client.reverse(
  ///   coordinates: Coordinates(lat: 55.7539, lon: 37.6208),
  ///   language: 'ru',
  /// );
  /// print('Address: ${address.displayName}');
  /// print('City: ${address.address.city}');
  /// ```
  Future<ReverseResponse> reverse({
    required Coordinates coordinates,
    String language = 'en',
  }) {
    return _reverse.reverse(
      coordinates: coordinates,
      language: language,
    );
  }

  /// Converts latitude/longitude to an address.
  ///
  /// Convenience method using separate lat/lon parameters.
  Future<ReverseResponse> reverseLatLon({
    required double lat,
    required double lon,
    String language = 'en',
  }) {
    return _reverse.reverseLatLon(
      lat: lat,
      lon: lon,
      language: language,
    );
  }

  // ==================== QUOTA & USAGE ====================

  /// Gets current quota information.
  ///
  /// Returns [QuotaResponse] with quota details.
  Future<QuotaResponse> quota() {
    return _quota.getQuota();
  }

  /// Gets usage statistics for a period.
  ///
  /// [period] - Statistics period (default: today).
  ///
  /// Returns [UsageResponse] with usage details.
  Future<UsageResponse> usage({
    UsagePeriod period = UsagePeriod.today,
  }) {
    return _quota.getUsage(period: period);
  }

  // ==================== TILES ====================

  /// Gets the map tile style URL from the server.
  ///
  /// Returns the URL of the map style JSON for MapLibre.
  /// The URL is determined by the server based on API key and bundle ID.
  ///
  /// Example:
  /// ```dart
  /// final styleUrl = await client.tileUrl();
  /// // Use styleUrl with NavigationView or QorviaMapView
  /// ```
  Future<String> tileUrl() async {
    final response = await _tile.getTileUrl();
    return response.tileUrl;
  }

  /// Gets the full tile URL response including metadata.
  ///
  /// Returns [TileUrlResponse] with style URL and request ID.
  Future<TileUrlResponse> tileUrlResponse() {
    return _tile.getTileUrl();
  }

  // ==================== SMART SEARCH ====================

  /// AI-powered natural language search.
  ///
  /// Automatically classifies queries and routes to appropriate provider
  /// (ADDRESS or PLACE). Available only on paid plans with `smart_search` permission.
  ///
  /// [query] - Natural language search query (2-500 characters).
  /// [lat] - User latitude (-90 to 90).
  /// [lon] - User longitude (-180 to 180).
  /// [radiusKm] - Search radius in kilometers (1-50, default: 10).
  /// [limit] - Maximum number of results (1-20, default: 5).
  /// [language] - Response language: 'ru' or 'en' (default: 'ru').
  ///
  /// Returns [SmartSearchResponse] with classified results.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.smartSearch(
  ///   query: 'ближайшая аптека',
  ///   lat: 55.7558,
  ///   lon: 37.6173,
  ///   radiusKm: 5,
  ///   language: 'ru',
  /// );
  ///
  /// print('Query type: ${response.queryType}, provider: ${response.provider}');
  /// for (final result in response.results) {
  ///   print('${result.name} - ${result.distanceM}m');
  ///   if (result.rating != null) {
  ///     print('Rating: ${result.rating}');
  ///   }
  ///   if (result.photoUrl != null) {
  ///     print('Photo: ${result.photoUrl}');
  ///   }
  /// }
  /// ```
  Future<SmartSearchResponse> smartSearch({
    required String query,
    required double lat,
    required double lon,
    int? radiusKm,
    int? limit,
    String? language,
  }) {
    return _smartSearch.smartSearch(
      query: query,
      lat: lat,
      lon: lon,
      radiusKm: radiusKm,
      limit: limit,
      language: language,
    );
  }

  /// Convenience method returning first smart search result or null.
  ///
  /// [query] - Natural language search query (2-500 characters).
  /// [lat] - User latitude.
  /// [lon] - User longitude.
  /// [radiusKm] - Search radius in kilometers (1-50, default: 10).
  /// [language] - Response language: 'ru' or 'en' (default: 'ru').
  ///
  /// Returns first [SmartSearchResult] or null if no results found.
  Future<SmartSearchResult?> smartSearchFirst({
    required String query,
    required double lat,
    required double lon,
    int? radiusKm,
    String? language,
  }) async {
    final response = await smartSearch(
      query: query,
      lat: lat,
      lon: lon,
      radiusKm: radiusKm,
      limit: 1,
      language: language,
    );
    return response.firstResult;
  }

  // ==================== LIFECYCLE ====================

  /// Releases resources used by the client.
  ///
  /// Call this method when you're done using the client.
  void dispose() {
    _httpClient.close();
  }
}
