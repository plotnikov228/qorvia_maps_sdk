import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/geocode/geocode_response.dart';
import '../../navigation/navigation_logger.dart';
import '../config/offline_config.dart';
import '../database/cache_database.dart';
import 'cache_repository.dart';

const _logTag = 'GeocodeCacheRepo';

/// Repository for caching geocoding API responses.
///
/// Stores geocoding results in SQLite with configurable TTL.
/// Uses query hash for efficient lookup.
class GeocodeCacheRepository implements CacheRepository<String, GeocodeResponse> {
  final CacheDatabase _db;
  final OfflineConfig _config;

  GeocodeCacheRepository(this._db, this._config);

  /// Get cached geocoding response by query hash.
  @override
  Future<GeocodeResponse?> get(String queryHash) async {
    try {
      final entry = await _db.getGeocodeCacheByHash(queryHash);

      if (entry == null) {
        NavigationLogger.debug(_logTag, 'Cache MISS', {'hash': queryHash});
        return null;
      }

      // Check if expired
      final now = DateTime.now().millisecondsSinceEpoch;
      if (entry.expiresAt < now) {
        NavigationLogger.debug(_logTag, 'Cache EXPIRED', {
          'hash': queryHash,
          'expiredAt': DateTime.fromMillisecondsSinceEpoch(entry.expiresAt),
        });
        return null;
      }

      final json = jsonDecode(entry.responseJson) as Map<String, dynamic>;
      final response = GeocodeResponse.fromJson(json);

      NavigationLogger.debug(_logTag, 'Cache HIT', {
        'hash': queryHash,
        'query': entry.query,
        'resultsCount': response.results.length,
        'age': '${((now - entry.createdAt) / 1000 / 60).round()}min',
      });

      return response;
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'get() failed', e, stack);
      return null;
    }
  }

  /// Store geocoding response in cache.
  @override
  Future<void> put(String queryHash, GeocodeResponse value, {Duration? ttl}) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final effectiveTtl = ttl ?? _config.geocodeTtl;
      final expiresAt = now + effectiveTtl.inMilliseconds;

      await _db.upsertGeocodeCache(GeocodeCacheTableCompanion(
        queryHash: Value(queryHash),
        query: Value(_extractQueryFromResponse(value)),
        responseJson: Value(jsonEncode(value.toJson())),
        createdAt: Value(now),
        expiresAt: Value(expiresAt),
      ));

      NavigationLogger.debug(_logTag, 'Stored in cache', {
        'hash': queryHash,
        'ttl': effectiveTtl.inHours,
        'resultsCount': value.results.length,
      });

      // Check if we need to enforce max entries limit
      await _enforceMaxEntries();
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'put() failed', e, stack);
    }
  }

  /// Get geocoding response by search parameters.
  ///
  /// Convenience method that generates the hash automatically.
  Future<GeocodeResponse?> getByQuery({
    required String query,
    String? language,
    double? biasLat,
    double? biasLon,
  }) async {
    final hash = CacheKeyGenerator.forGeocode(
      query: query,
      language: language,
      biasLat: biasLat,
      biasLon: biasLon,
    );
    return get(hash);
  }

  /// Store geocoding response by search parameters.
  ///
  /// Convenience method that generates the hash automatically.
  Future<void> putByQuery({
    required String query,
    required GeocodeResponse response,
    String? language,
    double? biasLat,
    double? biasLon,
    Duration? ttl,
  }) async {
    final hash = CacheKeyGenerator.forGeocode(
      query: query,
      language: language,
      biasLat: biasLat,
      biasLon: biasLon,
    );
    await put(hash, response, ttl: ttl);
  }

  @override
  Future<void> remove(String queryHash) async {
    try {
      // For now, we don't have a direct delete by hash method
      // This can be added if needed
      NavigationLogger.debug(_logTag, 'remove() called', {'hash': queryHash});
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'remove() failed', e, stack);
    }
  }

  @override
  Future<void> clear() async {
    try {
      final count = await _db.clearGeocodeCache();
      NavigationLogger.info(_logTag, 'Cache cleared', {'entriesRemoved': count});
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'clear() failed', e, stack);
    }
  }

  @override
  Future<int> cleanup() async {
    try {
      final count = await _db.deleteExpiredGeocodeCache();
      if (count > 0) {
        NavigationLogger.info(_logTag, 'Cleanup completed', {
          'expiredRemoved': count,
        });
      }
      return count;
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'cleanup() failed', e, stack);
      return 0;
    }
  }

  @override
  Future<CacheStats> getStats() async {
    try {
      final count = await _db.countGeocodeCache();
      return CacheStats(entryCount: count);
    } catch (e) {
      return const CacheStats(entryCount: 0);
    }
  }

  /// Enforce maximum entries limit by removing oldest entries.
  Future<void> _enforceMaxEntries() async {
    try {
      final count = await _db.countGeocodeCache();
      if (count > _config.maxGeocodeEntries) {
        // Remove oldest entries to get below limit
        final toRemove = count - _config.maxGeocodeEntries + 10; // Remove 10 extra
        NavigationLogger.debug(_logTag, 'Enforcing max entries', {
          'currentCount': count,
          'maxAllowed': _config.maxGeocodeEntries,
          'toRemove': toRemove,
        });
        // TODO: Implement delete oldest N entries in database
      }
    } catch (e) {
      // Ignore enforcement errors
    }
  }

  /// Extract query string from response for storage.
  String _extractQueryFromResponse(GeocodeResponse response) {
    // Try to extract from first result's display name
    if (response.results.isNotEmpty) {
      return response.results.first.displayName;
    }
    return '';
  }
}
