import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Abstract repository interface for cache operations.
///
/// Provides common cache operations like get, put, remove, and cleanup.
/// Implementations handle specific data types and storage mechanisms.
abstract class CacheRepository<K, V> {
  /// Retrieve a value from the cache by key.
  ///
  /// Returns null if the key doesn't exist or the entry has expired.
  Future<V?> get(K key);

  /// Store a value in the cache with an optional TTL.
  ///
  /// If [ttl] is not specified, a default TTL is used.
  Future<void> put(K key, V value, {Duration? ttl});

  /// Remove a specific entry from the cache.
  Future<void> remove(K key);

  /// Clear all entries from this cache.
  Future<void> clear();

  /// Remove expired entries from the cache.
  ///
  /// Returns the number of entries removed.
  Future<int> cleanup();

  /// Get statistics about the cache.
  Future<CacheStats> getStats();
}

/// Statistics about a cache.
class CacheStats {
  /// Number of entries in the cache.
  final int entryCount;

  /// Total size in bytes (approximate).
  final int sizeBytes;

  /// Number of entries that are expired but not yet cleaned up.
  final int expiredCount;

  const CacheStats({
    required this.entryCount,
    this.sizeBytes = 0,
    this.expiredCount = 0,
  });

  @override
  String toString() =>
      'CacheStats(entries: $entryCount, size: ${(sizeBytes / 1024).toStringAsFixed(1)}KB, expired: $expiredCount)';
}

/// Utility functions for cache key generation.
class CacheKeyGenerator {
  /// Generate a SHA-256 hash from a string.
  static String hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate a cache key from query parameters.
  ///
  /// Combines multiple parameters into a single hash.
  static String fromParams(Map<String, dynamic> params) {
    // Sort keys for consistent hashing
    final sortedKeys = params.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in sortedKeys) {
      final value = params[key];
      if (value != null) {
        buffer.write('$key=$value|');
      }
    }
    return hash(buffer.toString());
  }

  /// Generate a cache key for geocoding requests.
  static String forGeocode({
    required String query,
    String? language,
    double? biasLat,
    double? biasLon,
  }) {
    return fromParams({
      'query': query.toLowerCase().trim(),
      'language': language,
      'biasLat': biasLat?.toStringAsFixed(4),
      'biasLon': biasLon?.toStringAsFixed(4),
    });
  }

  /// Generate a cache key for reverse geocoding requests.
  static String forReverse({
    required double lat,
    required double lon,
    String? language,
  }) {
    return fromParams({
      'lat': lat.toStringAsFixed(6),
      'lon': lon.toStringAsFixed(6),
      'language': language,
    });
  }

  /// Generate a cache key for routing requests.
  static String forRoute({
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
    required String transportMode,
    List<Map<String, double>>? waypoints,
  }) {
    return fromParams({
      'fromLat': fromLat.toStringAsFixed(5),
      'fromLon': fromLon.toStringAsFixed(5),
      'toLat': toLat.toStringAsFixed(5),
      'toLon': toLon.toStringAsFixed(5),
      'transportMode': transportMode,
      'waypoints': waypoints != null ? jsonEncode(waypoints) : null,
    });
  }

  /// Generate a cache key for smart search requests.
  static String forSmartSearch({
    required String query,
    required double lat,
    required double lon,
    required double radiusKm,
    String? language,
  }) {
    return fromParams({
      'query': query.toLowerCase().trim(),
      'lat': lat.toStringAsFixed(4),
      'lon': lon.toStringAsFixed(4),
      'radiusKm': radiusKm.toStringAsFixed(1),
      'language': language,
    });
  }

  /// Round a coordinate to a bucket for spatial indexing.
  ///
  /// Uses a grid of approximately 100m cells.
  static double toBucket(double coord, {double precision = 0.001}) {
    return (coord / precision).round() * precision;
  }
}
