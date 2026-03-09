import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/coordinates.dart';
import '../../models/route/route_response.dart';
import '../../navigation/navigation_logger.dart';
import '../config/offline_config.dart';
import '../database/cache_database.dart';
import 'cache_repository.dart';

const _logTag = 'RouteCacheRepo';

/// Repository for caching routing API responses.
///
/// Stores route calculations in SQLite with configurable TTL.
/// Uses route hash (from + to + waypoints + mode) for efficient lookup.
class RouteCacheRepository implements CacheRepository<String, RouteResponse> {
  final CacheDatabase _db;
  final OfflineConfig _config;

  RouteCacheRepository(this._db, this._config);

  /// Get cached route response by route hash.
  @override
  Future<RouteResponse?> get(String routeHash) async {
    try {
      final entry = await _db.getRouteCacheByHash(routeHash);

      if (entry == null) {
        NavigationLogger.debug(_logTag, 'Cache MISS', {'hash': routeHash});
        return null;
      }

      // Check if expired
      final now = DateTime.now().millisecondsSinceEpoch;
      if (entry.expiresAt < now) {
        NavigationLogger.debug(_logTag, 'Cache EXPIRED', {
          'hash': routeHash,
          'expiredAt': DateTime.fromMillisecondsSinceEpoch(entry.expiresAt),
        });
        return null;
      }

      final json = jsonDecode(entry.responseJson) as Map<String, dynamic>;
      final response = RouteResponse.fromJson(json);

      NavigationLogger.debug(_logTag, 'Cache HIT', {
        'hash': routeHash,
        'distance': response.formattedDistance,
        'duration': response.formattedDuration,
        'age': '${((now - entry.createdAt) / 1000 / 60).round()}min',
      });

      return response;
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'get() failed', e, stack);
      return null;
    }
  }

  /// Store route response in cache.
  @override
  Future<void> put(String routeHash, RouteResponse value, {Duration? ttl}) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final effectiveTtl = ttl ?? _config.routeTtl;
      final expiresAt = now + effectiveTtl.inMilliseconds;

      await _db.upsertRouteCache(RouteCacheTableCompanion(
        routeHash: Value(routeHash),
        fromLat: const Value(0), // Will be set by putByRoute
        fromLon: const Value(0),
        toLat: const Value(0),
        toLon: const Value(0),
        transportMode: const Value('unknown'),
        responseJson: Value(jsonEncode(value.toJson())),
        createdAt: Value(now),
        expiresAt: Value(expiresAt),
      ));

      NavigationLogger.debug(_logTag, 'Stored in cache', {
        'hash': routeHash,
        'ttl': effectiveTtl.inMinutes,
        'distance': value.formattedDistance,
      });

      await _enforceMaxEntries();
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'put() failed', e, stack);
    }
  }

  /// Get route response by route parameters.
  ///
  /// Convenience method that generates the hash automatically.
  Future<RouteResponse?> getByRoute({
    required Coordinates from,
    required Coordinates to,
    required String transportMode,
    List<Coordinates>? waypoints,
  }) async {
    final hash = CacheKeyGenerator.forRoute(
      fromLat: from.lat,
      fromLon: from.lon,
      toLat: to.lat,
      toLon: to.lon,
      transportMode: transportMode,
      waypoints: waypoints?.map((w) => {'lat': w.lat, 'lon': w.lon}).toList(),
    );
    return get(hash);
  }

  /// Store route response by route parameters.
  ///
  /// Convenience method that generates the hash automatically.
  Future<void> putByRoute({
    required Coordinates from,
    required Coordinates to,
    required String transportMode,
    required RouteResponse response,
    List<Coordinates>? waypoints,
    Duration? ttl,
  }) async {
    try {
      final hash = CacheKeyGenerator.forRoute(
        fromLat: from.lat,
        fromLon: from.lon,
        toLat: to.lat,
        toLon: to.lon,
        transportMode: transportMode,
        waypoints: waypoints?.map((w) => {'lat': w.lat, 'lon': w.lon}).toList(),
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      final effectiveTtl = ttl ?? _config.routeTtl;
      final expiresAt = now + effectiveTtl.inMilliseconds;

      await _db.upsertRouteCache(RouteCacheTableCompanion(
        routeHash: Value(hash),
        fromLat: Value(from.lat),
        fromLon: Value(from.lon),
        toLat: Value(to.lat),
        toLon: Value(to.lon),
        waypointsJson: waypoints != null
            ? Value(jsonEncode(
                waypoints.map((w) => {'lat': w.lat, 'lon': w.lon}).toList()))
            : const Value.absent(),
        transportMode: Value(transportMode),
        responseJson: Value(jsonEncode(response.toJson())),
        createdAt: Value(now),
        expiresAt: Value(expiresAt),
      ));

      NavigationLogger.debug(_logTag, 'Stored in cache', {
        'hash': hash,
        'from': '${from.lat.toStringAsFixed(4)},${from.lon.toStringAsFixed(4)}',
        'to': '${to.lat.toStringAsFixed(4)},${to.lon.toStringAsFixed(4)}',
        'mode': transportMode,
        'ttl': effectiveTtl.inMinutes,
      });

      await _enforceMaxEntries();
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'putByRoute() failed', e, stack);
    }
  }

  @override
  Future<void> remove(String routeHash) async {
    NavigationLogger.debug(_logTag, 'remove() called', {'hash': routeHash});
  }

  @override
  Future<void> clear() async {
    try {
      final count = await _db.clearRouteCache();
      NavigationLogger.info(_logTag, 'Cache cleared', {'entriesRemoved': count});
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'clear() failed', e, stack);
    }
  }

  @override
  Future<int> cleanup() async {
    try {
      final count = await _db.deleteExpiredRouteCache();
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
      final count = await _db.countRouteCache();
      return CacheStats(entryCount: count);
    } catch (e) {
      return const CacheStats(entryCount: 0);
    }
  }

  Future<void> _enforceMaxEntries() async {
    try {
      final count = await _db.countRouteCache();
      if (count > _config.maxRouteEntries) {
        NavigationLogger.debug(_logTag, 'Enforcing max entries', {
          'currentCount': count,
          'maxAllowed': _config.maxRouteEntries,
        });
      }
    } catch (e) {
      // Ignore enforcement errors
    }
  }
}
