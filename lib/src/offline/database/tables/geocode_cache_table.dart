import 'package:drift/drift.dart';

/// Table for caching geocoding API responses.
///
/// Stores geocoding results with TTL support for offline access.
class GeocodeCacheTable extends Table {
  @override
  String get tableName => 'geocode_cache';

  /// Auto-increment primary key
  IntColumn get id => integer().autoIncrement()();

  /// SHA-256 hash of query parameters for fast lookup
  TextColumn get queryHash => text().unique()();

  /// Original search query
  TextColumn get query => text()();

  /// Serialized GeocodeResponse as JSON
  TextColumn get responseJson => text()();

  /// Language code (ru, en, etc.)
  TextColumn get language => text().nullable()();

  /// Location bias latitude (if used)
  RealColumn get biasLat => real().nullable()();

  /// Location bias longitude (if used)
  RealColumn get biasLon => real().nullable()();

  /// Timestamp when entry was created (milliseconds since epoch)
  IntColumn get createdAt => integer()();

  /// Timestamp when entry expires (milliseconds since epoch)
  IntColumn get expiresAt => integer()();
}
