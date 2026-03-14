import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/coordinates.dart';
import '../../models/geocode/address.dart';
import '../../models/geocode/geocode_response.dart';
import '../../models/geocode/geocode_result.dart';
import '../../models/reverse/reverse_response.dart';

/// Service for offline geocoding using SQLite with FTS5 (Full-Text Search).
///
/// **Note:** Offline geocoding data is not yet available from the server.
/// This service is planned for future releases. Currently, geocoding works online only.
///
/// The service loads SQLite databases containing geocoding data for regions.
/// Databases are typically downloaded using [GeocodingDataService].
///
/// Features:
/// - Forward geocoding (address search) using FTS5
/// - Reverse geocoding (coordinates to address)
/// - Location-biased search results
/// - Multi-region support
///
/// Example:
/// ```dart
/// final service = OfflineGeocodingService();
///
/// // Load a database for a region
/// await service.loadDatabase('moscow', '/path/to/moscow.db');
///
/// // Forward geocoding
/// final results = await service.geocode(
///   regionId: 'moscow',
///   query: 'Кремль',
///   userLat: 55.7558,
///   userLon: 37.6173,
/// );
///
/// // Reverse geocoding
/// final address = await service.reverse(
///   regionId: 'moscow',
///   coordinates: Coordinates(lat: 55.7539, lon: 37.6208),
/// );
///
/// // Unload when done
/// service.unloadDatabase('moscow');
/// ```
@Deprecated('Offline geocoding data not yet available. Use online geocoding instead.')
class OfflineGeocodingService {
  /// UUID generator for request IDs.
  final Uuid _uuid = const Uuid();

  /// Logger callback.
  final void Function(String message)? _logger;

  /// Loaded databases by region ID.
  final Map<String, _LoadedDatabase> _loadedDatabases = {};

  /// Creates an OfflineGeocodingService.
  ///
  /// [logger] - Optional callback for debug logging.
  OfflineGeocodingService({
    void Function(String message)? logger,
  }) : _logger = logger;

  void _log(String message) {
    _logger?.call('[OfflineGeocodingService] $message');
    debugPrint('[OfflineGeocodingService] $message');
  }

  // MARK: - Database Management

  /// Loads a geocoding database.
  ///
  /// [regionId] - Unique identifier for this database.
  /// [databasePath] - Absolute path to the SQLite database file.
  ///
  /// Throws [OfflineGeocodingException] on failure.
  Future<void> loadDatabase(String regionId, String databasePath) async {
    _log('Loading database: $regionId from $databasePath');

    try {
      final file = File(databasePath);
      if (!await file.exists()) {
        throw OfflineGeocodingException('Database file not found: $databasePath');
      }

      // Validate SQLite header
      final bytes = await file.openRead(0, 16).first;
      final header = String.fromCharCodes(bytes.take(15));
      if (header != 'SQLite format 3') {
        throw OfflineGeocodingException('Invalid SQLite database: $databasePath');
      }

      // Store database info
      _loadedDatabases[regionId] = _LoadedDatabase(
        regionId: regionId,
        path: databasePath,
        loadedAt: DateTime.now(),
      );

      _log('Database loaded: $regionId');
    } catch (e) {
      _log('Error loading database: $e');
      if (e is OfflineGeocodingException) rethrow;
      throw OfflineGeocodingException('Failed to load database: $e');
    }
  }

  /// Unloads a geocoding database.
  ///
  /// [regionId] - The region ID used when loading the database.
  void unloadDatabase(String regionId) {
    _log('Unloading database: $regionId');
    _loadedDatabases.remove(regionId);
  }

  /// Checks if a database is currently loaded.
  bool isDatabaseLoaded(String regionId) {
    return _loadedDatabases.containsKey(regionId);
  }

  /// Gets the list of loaded database region IDs.
  List<String> getLoadedDatabases() {
    return _loadedDatabases.keys.toList();
  }

  /// Gets information about a loaded database.
  OfflineDatabaseInfo? getDatabaseInfo(String regionId) {
    final db = _loadedDatabases[regionId];
    if (db == null) return null;

    return OfflineDatabaseInfo(
      regionId: db.regionId,
      path: db.path,
      loadedAt: db.loadedAt,
    );
  }

  // MARK: - Forward Geocoding

  /// Searches for addresses matching a query.
  ///
  /// [regionId] - The loaded database region to search.
  /// [query] - Search query (address, place name, etc.).
  /// [limit] - Maximum results to return (default: 5).
  /// [userLat], [userLon] - User location for biased results.
  /// [radiusKm] - Search radius in kilometers.
  /// [language] - Language for results (default: 'en').
  ///
  /// Returns [GeocodeResponse] compatible with the online API.
  Future<GeocodeResponse> geocode({
    required String regionId,
    required String query,
    int limit = 5,
    double? userLat,
    double? userLon,
    double? radiusKm,
    String language = 'en',
  }) async {
    final db = _loadedDatabases[regionId];
    if (db == null) {
      throw OfflineGeocodingException('Database not loaded: $regionId');
    }

    _log('Geocoding: "$query" in $regionId (limit: $limit)');

    try {
      // Normalize query
      final normalizedQuery = _normalizeQuery(query);
      if (normalizedQuery.isEmpty) {
        return GeocodeResponse(
          requestId: _uuid.v4(),
          results: [],
          provider: 'offline',
          units: 0,
        );
      }

      // Execute search using native SQLite
      final results = await _executeSearch(
        db.path,
        normalizedQuery,
        limit: limit,
        userLat: userLat,
        userLon: userLon,
        radiusKm: radiusKm,
      );

      _log('Found ${results.length} results for "$query"');

      return GeocodeResponse(
        requestId: _uuid.v4(),
        results: results,
        provider: 'offline',
        units: 0,
      );
    } catch (e) {
      _log('Geocoding error: $e');
      throw OfflineGeocodingException('Geocoding failed: $e');
    }
  }

  /// Searches for a single best match.
  Future<GeocodeResult?> search(
    String regionId,
    String query, {
    double? userLat,
    double? userLon,
    String language = 'en',
  }) async {
    final response = await geocode(
      regionId: regionId,
      query: query,
      limit: 1,
      userLat: userLat,
      userLon: userLon,
      language: language,
    );
    return response.firstResult;
  }

  // MARK: - Reverse Geocoding

  /// Converts coordinates to an address.
  ///
  /// [regionId] - The loaded database region to search.
  /// [coordinates] - Location coordinates.
  /// [radiusMeters] - Maximum search radius (default: 100).
  /// [language] - Language for results (default: 'en').
  ///
  /// Returns [ReverseResponse] compatible with the online API.
  Future<ReverseResponse> reverse({
    required String regionId,
    required Coordinates coordinates,
    double radiusMeters = 100,
    String language = 'en',
  }) async {
    final db = _loadedDatabases[regionId];
    if (db == null) {
      throw OfflineGeocodingException('Database not loaded: $regionId');
    }

    _log('Reverse geocoding: ${coordinates.lat}, ${coordinates.lon} in $regionId');

    try {
      final result = await _executeReverseSearch(
        db.path,
        coordinates,
        radiusMeters: radiusMeters,
      );

      if (result == null) {
        _log('No address found for coordinates');
        return ReverseResponse(
          requestId: _uuid.v4(),
          coordinates: coordinates,
          displayName: '',
          address: const Address(),
          provider: 'offline',
          units: 0,
        );
      }

      _log('Found: ${result.displayName}');

      return ReverseResponse(
        requestId: _uuid.v4(),
        coordinates: coordinates,
        displayName: result.displayName,
        address: result.address,
        provider: 'offline',
        units: 0,
      );
    } catch (e) {
      _log('Reverse geocoding error: $e');
      throw OfflineGeocodingException('Reverse geocoding failed: $e');
    }
  }

  // MARK: - Private Methods

  /// Normalizes search query for FTS5.
  String _normalizeQuery(String query) {
    // Trim and convert to lowercase
    var normalized = query.trim().toLowerCase();

    // Remove special characters that might break FTS5
    normalized = normalized.replaceAll(RegExp(r'[^\w\s\-.,]'), ' ');

    // Collapse multiple spaces
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }

  /// Executes FTS5 search query.
  ///
  /// Note: This is a placeholder implementation.
  /// In production, use drift or sqlite3 package for actual database queries.
  Future<List<GeocodeResult>> _executeSearch(
    String dbPath,
    String query,
    {
    int limit = 5,
    double? userLat,
    double? userLon,
    double? radiusKm,
  }) async {
    // TODO: Implement actual SQLite FTS5 query using drift or sqlite3 package
    //
    // Example FTS5 query:
    // SELECT * FROM places_fts WHERE places_fts MATCH ?
    // ORDER BY rank
    // LIMIT ?
    //
    // With location bias:
    // SELECT *, (lat - ?) * (lat - ?) + (lon - ?) * (lon - ?) AS dist_sq
    // FROM places_fts WHERE places_fts MATCH ?
    // ORDER BY dist_sq ASC, rank DESC
    // LIMIT ?

    _log('TODO: Execute FTS5 search for "$query" (limit: $limit)');

    // Return empty results for now - actual implementation requires
    // SQLite integration which should be done in the SDK integration phase
    return [];
  }

  /// Executes reverse geocoding search.
  ///
  /// Note: This is a placeholder implementation.
  /// In production, use drift or sqlite3 package for actual database queries.
  Future<GeocodeResult?> _executeReverseSearch(
    String dbPath,
    Coordinates coordinates, {
    double radiusMeters = 100,
  }) async {
    // TODO: Implement actual SQLite query using drift or sqlite3 package
    //
    // Find nearest address using bounding box + Haversine:
    // SELECT * FROM places
    // WHERE lat BETWEEN ? AND ?
    //   AND lon BETWEEN ? AND ?
    // ORDER BY (lat - ?) * (lat - ?) + (lon - ?) * (lon - ?)
    // LIMIT 1

    _log('TODO: Execute reverse search for ${coordinates.lat}, ${coordinates.lon}');

    // Return null for now - actual implementation requires SQLite integration
    return null;
  }

  /// Calculates Haversine distance between two points.
  double _haversineDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  /// Disposes resources.
  void dispose() {
    _log('Disposing OfflineGeocodingService');
    _loadedDatabases.clear();
  }
}

/// Internal class for loaded database info.
class _LoadedDatabase {
  final String regionId;
  final String path;
  final DateTime loadedAt;

  _LoadedDatabase({
    required this.regionId,
    required this.path,
    required this.loadedAt,
  });
}

/// Information about a loaded geocoding database.
class OfflineDatabaseInfo {
  final String regionId;
  final String path;
  final DateTime loadedAt;

  const OfflineDatabaseInfo({
    required this.regionId,
    required this.path,
    required this.loadedAt,
  });

  @override
  String toString() {
    return 'OfflineDatabaseInfo(regionId: $regionId, path: $path)';
  }
}

/// Exception thrown by offline geocoding operations.
class OfflineGeocodingException implements Exception {
  final String message;

  const OfflineGeocodingException(this.message);

  @override
  String toString() => 'OfflineGeocodingException: $message';
}
