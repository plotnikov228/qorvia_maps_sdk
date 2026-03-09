import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import '../../navigation/navigation_logger.dart';
import 'tables/geocode_cache_table.dart';
import 'tables/reverse_cache_table.dart';
import 'tables/route_cache_table.dart';
import 'tables/smart_search_cache_table.dart';
import 'tables/offline_region_table.dart';

part 'cache_database.g.dart';

const _logTag = 'CacheDatabase';

/// Database for offline caching of API responses.
///
/// Uses Drift (SQLite) for persistent storage with automatic migrations.
/// Supports caching of:
/// - Geocoding results
/// - Reverse geocoding results
/// - Route calculations
/// - Smart search results
/// - Offline map region metadata
@DriftDatabase(tables: [
  GeocodeCacheTable,
  ReverseCacheTable,
  RouteCacheTable,
  SmartSearchCacheTable,
  OfflineRegionTable,
])
class CacheDatabase extends _$CacheDatabase {
  /// Creates database with default file-based storage.
  CacheDatabase() : super(_openConnection());

  /// Creates database with custom query executor (for testing).
  CacheDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          NavigationLogger.info(_logTag, 'Creating database schema', {
            'version': schemaVersion,
          });
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          NavigationLogger.info(_logTag, 'Migrating database', {
            'from': from,
            'to': to,
          });

          // Migration from v1 to v2: add tile download fields to offline_regions
          if (from < 2) {
            await customStatement('''
              ALTER TABLE offline_regions
              ADD COLUMN file_path TEXT
            ''');
            await customStatement('''
              ALTER TABLE offline_regions
              ADD COLUMN server_region_id TEXT
            ''');
            await customStatement('''
              ALTER TABLE offline_regions
              ADD COLUMN region_type TEXT NOT NULL DEFAULT 'custom'
            ''');
            NavigationLogger.info(_logTag, 'Migrated to v2: added tile download fields');
          }
        },
        beforeOpen: (details) async {
          NavigationLogger.debug(_logTag, 'Opening database', {
            'wasCreated': details.wasCreated,
            'versionBefore': details.versionBefore,
            'versionNow': details.versionNow,
          });

          // Enable foreign keys for data integrity
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ============================================================
  // Geocode Cache Operations
  // ============================================================

  /// Insert or update geocode cache entry.
  Future<int> upsertGeocodeCache(GeocodeCacheTableCompanion entry) async {
    return into(geocodeCacheTable).insertOnConflictUpdate(entry);
  }

  /// Get geocode cache entry by query hash.
  Future<GeocodeCacheTableData?> getGeocodeCacheByHash(String queryHash) async {
    return (select(geocodeCacheTable)
          ..where((t) => t.queryHash.equals(queryHash)))
        .getSingleOrNull();
  }

  /// Delete expired geocode cache entries.
  Future<int> deleteExpiredGeocodeCache() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (delete(geocodeCacheTable)..where((t) => t.expiresAt.isSmallerThanValue(now)))
        .go();
  }

  /// Delete all geocode cache entries.
  Future<int> clearGeocodeCache() async {
    return delete(geocodeCacheTable).go();
  }

  /// Count geocode cache entries.
  Future<int> countGeocodeCache() async {
    final count = geocodeCacheTable.id.count();
    final query = selectOnly(geocodeCacheTable)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============================================================
  // Reverse Cache Operations
  // ============================================================

  /// Insert or update reverse cache entry.
  Future<int> insertReverseCache(ReverseCacheTableCompanion entry) async {
    return into(reverseCacheTable).insert(entry);
  }

  /// Get reverse cache entry by coordinate bucket.
  Future<ReverseCacheTableData?> getReverseCacheByBucket(
    double latBucket,
    double lonBucket,
    double lat,
    double lon, {
    double tolerance = 0.0001, // ~10m tolerance
  }) async {
    return (select(reverseCacheTable)
          ..where((t) =>
              t.latBucket.equals(latBucket) &
              t.lonBucket.equals(lonBucket) &
              (t.lat - Variable(lat)).abs().isSmallerOrEqualValue(tolerance) &
              (t.lon - Variable(lon)).abs().isSmallerOrEqualValue(tolerance)))
        .getSingleOrNull();
  }

  /// Delete expired reverse cache entries.
  Future<int> deleteExpiredReverseCache() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (delete(reverseCacheTable)..where((t) => t.expiresAt.isSmallerThanValue(now)))
        .go();
  }

  /// Delete all reverse cache entries.
  Future<int> clearReverseCache() async {
    return delete(reverseCacheTable).go();
  }

  /// Count reverse cache entries.
  Future<int> countReverseCache() async {
    final count = reverseCacheTable.id.count();
    final query = selectOnly(reverseCacheTable)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============================================================
  // Route Cache Operations
  // ============================================================

  /// Insert or update route cache entry.
  Future<int> upsertRouteCache(RouteCacheTableCompanion entry) async {
    return into(routeCacheTable).insertOnConflictUpdate(entry);
  }

  /// Get route cache entry by route hash.
  Future<RouteCacheTableData?> getRouteCacheByHash(String routeHash) async {
    return (select(routeCacheTable)..where((t) => t.routeHash.equals(routeHash)))
        .getSingleOrNull();
  }

  /// Delete expired route cache entries.
  Future<int> deleteExpiredRouteCache() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (delete(routeCacheTable)..where((t) => t.expiresAt.isSmallerThanValue(now)))
        .go();
  }

  /// Delete all route cache entries.
  Future<int> clearRouteCache() async {
    return delete(routeCacheTable).go();
  }

  /// Count route cache entries.
  Future<int> countRouteCache() async {
    final count = routeCacheTable.id.count();
    final query = selectOnly(routeCacheTable)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============================================================
  // Smart Search Cache Operations
  // ============================================================

  /// Insert or update smart search cache entry.
  Future<int> upsertSmartSearchCache(SmartSearchCacheTableCompanion entry) async {
    return into(smartSearchCacheTable).insertOnConflictUpdate(entry);
  }

  /// Get smart search cache entry by query hash.
  Future<SmartSearchCacheTableData?> getSmartSearchCacheByHash(
      String queryHash) async {
    return (select(smartSearchCacheTable)
          ..where((t) => t.queryHash.equals(queryHash)))
        .getSingleOrNull();
  }

  /// Delete expired smart search cache entries.
  Future<int> deleteExpiredSmartSearchCache() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (delete(smartSearchCacheTable)
          ..where((t) => t.expiresAt.isSmallerThanValue(now)))
        .go();
  }

  /// Delete all smart search cache entries.
  Future<int> clearSmartSearchCache() async {
    return delete(smartSearchCacheTable).go();
  }

  /// Count smart search cache entries.
  Future<int> countSmartSearchCache() async {
    final count = smartSearchCacheTable.id.count();
    final query = selectOnly(smartSearchCacheTable)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============================================================
  // Offline Region Operations
  // ============================================================

  /// Insert offline region.
  Future<int> insertOfflineRegion(OfflineRegionTableCompanion entry) async {
    return into(offlineRegionTable).insert(entry);
  }

  /// Update offline region by region ID.
  Future<int> updateOfflineRegionById(
    String regionId,
    OfflineRegionTableCompanion entry,
  ) async {
    return (update(offlineRegionTable)
          ..where((t) => t.regionId.equals(regionId)))
        .write(entry);
  }

  /// Get offline region by ID.
  Future<OfflineRegionTableData?> getOfflineRegion(String regionId) async {
    return (select(offlineRegionTable)
          ..where((t) => t.regionId.equals(regionId)))
        .getSingleOrNull();
  }

  /// Get all offline regions.
  Future<List<OfflineRegionTableData>> getAllOfflineRegions() async {
    return select(offlineRegionTable).get();
  }

  /// Delete offline region.
  Future<int> deleteOfflineRegion(String regionId) async {
    return (delete(offlineRegionTable)
          ..where((t) => t.regionId.equals(regionId)))
        .go();
  }

  /// Update offline region progress.
  Future<void> updateRegionProgress(
    String regionId, {
    required int downloadedTiles,
    required int sizeBytes,
    String? status,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(offlineRegionTable)
          ..where((t) => t.regionId.equals(regionId)))
        .write(OfflineRegionTableCompanion(
      downloadedTiles: Value(downloadedTiles),
      sizeBytes: Value(sizeBytes),
      status: status != null ? Value(status) : const Value.absent(),
      updatedAt: Value(now),
    ));
  }

  // ============================================================
  // Utility Operations
  // ============================================================

  /// Delete all expired entries from all cache tables.
  Future<Map<String, int>> cleanupExpiredEntries() async {
    NavigationLogger.info(_logTag, 'Cleaning up expired cache entries');

    final geocodeDeleted = await deleteExpiredGeocodeCache();
    final reverseDeleted = await deleteExpiredReverseCache();
    final routeDeleted = await deleteExpiredRouteCache();
    final smartSearchDeleted = await deleteExpiredSmartSearchCache();

    final result = {
      'geocode': geocodeDeleted,
      'reverse': reverseDeleted,
      'route': routeDeleted,
      'smartSearch': smartSearchDeleted,
    };

    NavigationLogger.info(_logTag, 'Cleanup completed', result);
    return result;
  }

  /// Get total count of all cached entries.
  Future<Map<String, int>> getCacheStats() async {
    return {
      'geocode': await countGeocodeCache(),
      'reverse': await countReverseCache(),
      'route': await countRouteCache(),
      'smartSearch': await countSmartSearchCache(),
    };
  }

  /// Clear all cache tables.
  Future<void> clearAllCaches() async {
    NavigationLogger.info(_logTag, 'Clearing all caches');
    await clearGeocodeCache();
    await clearReverseCache();
    await clearRouteCache();
    await clearSmartSearchCache();
  }

  /// Get database file size in bytes.
  Future<int> getDatabaseSize() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'qorvia_cache.db'));
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      NavigationLogger.error(_logTag, 'Failed to get database size', e);
    }
    return 0;
  }
}

/// Opens SQLite database connection.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'qorvia_cache.db'));

      NavigationLogger.info(_logTag, 'Opening database', {
        'path': file.path,
      });

      return NativeDatabase.createInBackground(file);
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'Failed to open database', e, stack);
      rethrow;
    }
  });
}

/// Creates an in-memory database for testing.
CacheDatabase createInMemoryDatabase() {
  return CacheDatabase.forTesting(
    NativeDatabase.memory(),
  );
}
