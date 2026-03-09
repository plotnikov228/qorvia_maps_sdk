import 'package:drift/drift.dart';

/// Table for caching smart search API responses.
///
/// Smart search results are cached by query, location, and radius.
class SmartSearchCacheTable extends Table {
  @override
  String get tableName => 'smart_search_cache';

  /// Auto-increment primary key
  IntColumn get id => integer().autoIncrement()();

  /// SHA-256 hash of search parameters for fast lookup
  TextColumn get queryHash => text().unique()();

  /// Original search query
  TextColumn get query => text()();

  /// Search center latitude
  RealColumn get locationLat => real()();

  /// Search center longitude
  RealColumn get locationLon => real()();

  /// Search radius in kilometers
  RealColumn get radiusKm => real()();

  /// Language code (ru, en, etc.)
  TextColumn get language => text().nullable()();

  /// Serialized SmartSearchResponse as JSON
  TextColumn get responseJson => text()();

  /// Timestamp when entry was created (milliseconds since epoch)
  IntColumn get createdAt => integer()();

  /// Timestamp when entry expires (milliseconds since epoch)
  IntColumn get expiresAt => integer()();
}
