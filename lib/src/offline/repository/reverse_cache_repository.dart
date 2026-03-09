import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/reverse/reverse_response.dart';
import '../../navigation/navigation_logger.dart';
import '../config/offline_config.dart';
import '../database/cache_database.dart';
import 'cache_repository.dart';

const _logTag = 'ReverseCacheRepo';

/// Repository for caching reverse geocoding API responses.
///
/// Stores reverse geocoding results in SQLite with spatial bucketing
/// for efficient coordinate-based lookups.
class ReverseCacheRepository implements CacheRepository<String, ReverseResponse> {
  final CacheDatabase _db;
  final OfflineConfig _config;

  ReverseCacheRepository(this._db, this._config);

  /// Get cached reverse geocoding response by coordinate hash.
  @override
  Future<ReverseResponse?> get(String key) async {
    // For reverse geocoding, we use coordinates directly instead of hash
    // This method is for interface compliance
    NavigationLogger.debug(_logTag, 'get() called with key', {'key': key});
    return null;
  }

  /// Get reverse geocoding response by coordinates.
  ///
  /// Uses spatial bucketing for efficient lookup.
  Future<ReverseResponse?> getByCoordinates({
    required double lat,
    required double lon,
    String? language,
    double tolerance = 0.0001, // ~10m tolerance
  }) async {
    try {
      final latBucket = CacheKeyGenerator.toBucket(lat);
      final lonBucket = CacheKeyGenerator.toBucket(lon);

      final entry = await _db.getReverseCacheByBucket(
        latBucket,
        lonBucket,
        lat,
        lon,
        tolerance: tolerance,
      );

      if (entry == null) {
        NavigationLogger.debug(_logTag, 'Cache MISS', {
          'lat': lat,
          'lon': lon,
        });
        return null;
      }

      // Check if expired
      final now = DateTime.now().millisecondsSinceEpoch;
      if (entry.expiresAt < now) {
        NavigationLogger.debug(_logTag, 'Cache EXPIRED', {
          'lat': lat,
          'lon': lon,
          'expiredAt': DateTime.fromMillisecondsSinceEpoch(entry.expiresAt),
        });
        return null;
      }

      // Check language if specified
      if (language != null && entry.language != language) {
        NavigationLogger.debug(_logTag, 'Cache MISS (language mismatch)', {
          'requested': language,
          'cached': entry.language,
        });
        return null;
      }

      final json = jsonDecode(entry.responseJson) as Map<String, dynamic>;
      final response = ReverseResponse.fromJson(json);

      NavigationLogger.debug(_logTag, 'Cache HIT', {
        'lat': lat,
        'lon': lon,
        'displayName': response.displayName,
        'age': '${((now - entry.createdAt) / 1000 / 60).round()}min',
      });

      return response;
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'getByCoordinates() failed', e, stack);
      return null;
    }
  }

  @override
  Future<void> put(String key, ReverseResponse value, {Duration? ttl}) async {
    // For reverse geocoding, we use putByCoordinates directly
    // This method is for interface compliance
    await putByCoordinates(
      lat: value.coordinates.lat,
      lon: value.coordinates.lon,
      response: value,
      ttl: ttl,
    );
  }

  /// Store reverse geocoding response by coordinates.
  Future<void> putByCoordinates({
    required double lat,
    required double lon,
    required ReverseResponse response,
    String? language,
    Duration? ttl,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final effectiveTtl = ttl ?? _config.reverseTtl;
      final expiresAt = now + effectiveTtl.inMilliseconds;

      final latBucket = CacheKeyGenerator.toBucket(lat);
      final lonBucket = CacheKeyGenerator.toBucket(lon);

      await _db.insertReverseCache(ReverseCacheTableCompanion(
        latBucket: Value(latBucket),
        lonBucket: Value(lonBucket),
        lat: Value(lat),
        lon: Value(lon),
        responseJson: Value(jsonEncode(response.toJson())),
        language: Value(language),
        createdAt: Value(now),
        expiresAt: Value(expiresAt),
      ));

      NavigationLogger.debug(_logTag, 'Stored in cache', {
        'lat': lat,
        'lon': lon,
        'ttl': effectiveTtl.inHours,
        'displayName': response.displayName,
      });

      await _enforceMaxEntries();
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'putByCoordinates() failed', e, stack);
    }
  }

  @override
  Future<void> remove(String key) async {
    NavigationLogger.debug(_logTag, 'remove() called', {'key': key});
  }

  @override
  Future<void> clear() async {
    try {
      final count = await _db.clearReverseCache();
      NavigationLogger.info(_logTag, 'Cache cleared', {'entriesRemoved': count});
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'clear() failed', e, stack);
    }
  }

  @override
  Future<int> cleanup() async {
    try {
      final count = await _db.deleteExpiredReverseCache();
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
      final count = await _db.countReverseCache();
      return CacheStats(entryCount: count);
    } catch (e) {
      return const CacheStats(entryCount: 0);
    }
  }

  Future<void> _enforceMaxEntries() async {
    try {
      final count = await _db.countReverseCache();
      if (count > _config.maxReverseEntries) {
        NavigationLogger.debug(_logTag, 'Enforcing max entries', {
          'currentCount': count,
          'maxAllowed': _config.maxReverseEntries,
        });
      }
    } catch (e) {
      // Ignore enforcement errors
    }
  }
}
