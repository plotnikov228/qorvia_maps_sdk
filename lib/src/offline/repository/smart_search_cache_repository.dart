import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/smart_search/smart_search_response.dart';
import '../../navigation/navigation_logger.dart';
import '../config/offline_config.dart';
import '../database/cache_database.dart';
import 'cache_repository.dart';

const _logTag = 'SmartSearchCacheRepo';

/// Repository for caching smart search API responses.
///
/// Stores smart search results in SQLite with configurable TTL.
/// Uses query hash (query + location + radius) for efficient lookup.
class SmartSearchCacheRepository
    implements CacheRepository<String, SmartSearchResponse> {
  final CacheDatabase _db;
  final OfflineConfig _config;

  SmartSearchCacheRepository(this._db, this._config);

  /// Get cached smart search response by query hash.
  @override
  Future<SmartSearchResponse?> get(String queryHash) async {
    try {
      final entry = await _db.getSmartSearchCacheByHash(queryHash);

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
      final response = SmartSearchResponse.fromJson(json);

      NavigationLogger.debug(_logTag, 'Cache HIT', {
        'hash': queryHash,
        'query': entry.query,
        'resultsCount': response.results.length,
        'queryType': response.queryType,
        'age': '${((now - entry.createdAt) / 1000 / 60).round()}min',
      });

      return response;
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'get() failed', e, stack);
      return null;
    }
  }

  /// Store smart search response in cache.
  @override
  Future<void> put(String queryHash, SmartSearchResponse value,
      {Duration? ttl}) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final effectiveTtl = ttl ?? _config.smartSearchTtl;
      final expiresAt = now + effectiveTtl.inMilliseconds;

      await _db.upsertSmartSearchCache(SmartSearchCacheTableCompanion(
        queryHash: Value(queryHash),
        query: const Value(''), // Will be set by putByQuery
        locationLat: const Value(0),
        locationLon: const Value(0),
        radiusKm: const Value(10),
        responseJson: Value(jsonEncode(value.toJson())),
        createdAt: Value(now),
        expiresAt: Value(expiresAt),
      ));

      NavigationLogger.debug(_logTag, 'Stored in cache', {
        'hash': queryHash,
        'ttl': effectiveTtl.inHours,
        'resultsCount': value.results.length,
      });

      await _enforceMaxEntries();
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'put() failed', e, stack);
    }
  }

  /// Get smart search response by search parameters.
  ///
  /// Convenience method that generates the hash automatically.
  Future<SmartSearchResponse?> getByQuery({
    required String query,
    required double lat,
    required double lon,
    required double radiusKm,
    String? language,
  }) async {
    final hash = CacheKeyGenerator.forSmartSearch(
      query: query,
      lat: lat,
      lon: lon,
      radiusKm: radiusKm,
      language: language,
    );
    return get(hash);
  }

  /// Store smart search response by search parameters.
  ///
  /// Convenience method that generates the hash automatically.
  Future<void> putByQuery({
    required String query,
    required double lat,
    required double lon,
    required double radiusKm,
    required SmartSearchResponse response,
    String? language,
    Duration? ttl,
  }) async {
    try {
      final hash = CacheKeyGenerator.forSmartSearch(
        query: query,
        lat: lat,
        lon: lon,
        radiusKm: radiusKm,
        language: language,
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      final effectiveTtl = ttl ?? _config.smartSearchTtl;
      final expiresAt = now + effectiveTtl.inMilliseconds;

      await _db.upsertSmartSearchCache(SmartSearchCacheTableCompanion(
        queryHash: Value(hash),
        query: Value(query),
        locationLat: Value(lat),
        locationLon: Value(lon),
        radiusKm: Value(radiusKm),
        language: Value(language),
        responseJson: Value(jsonEncode(response.toJson())),
        createdAt: Value(now),
        expiresAt: Value(expiresAt),
      ));

      NavigationLogger.debug(_logTag, 'Stored in cache', {
        'hash': hash,
        'query': query,
        'location': '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}',
        'radiusKm': radiusKm,
        'ttl': effectiveTtl.inHours,
      });

      await _enforceMaxEntries();
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'putByQuery() failed', e, stack);
    }
  }

  @override
  Future<void> remove(String queryHash) async {
    NavigationLogger.debug(_logTag, 'remove() called', {'hash': queryHash});
  }

  @override
  Future<void> clear() async {
    try {
      final count = await _db.clearSmartSearchCache();
      NavigationLogger.info(_logTag, 'Cache cleared', {'entriesRemoved': count});
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'clear() failed', e, stack);
    }
  }

  @override
  Future<int> cleanup() async {
    try {
      final count = await _db.deleteExpiredSmartSearchCache();
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
      final count = await _db.countSmartSearchCache();
      return CacheStats(entryCount: count);
    } catch (e) {
      return const CacheStats(entryCount: 0);
    }
  }

  Future<void> _enforceMaxEntries() async {
    try {
      final count = await _db.countSmartSearchCache();
      if (count > _config.maxSmartSearchEntries) {
        NavigationLogger.debug(_logTag, 'Enforcing max entries', {
          'currentCount': count,
          'maxAllowed': _config.maxSmartSearchEntries,
        });
      }
    } catch (e) {
      // Ignore enforcement errors
    }
  }
}
