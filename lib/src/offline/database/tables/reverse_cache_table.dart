import 'package:drift/drift.dart';

/// Table for caching reverse geocoding API responses.
///
/// Uses coordinate bucketing for efficient spatial queries.
class ReverseCacheTable extends Table {
  @override
  String get tableName => 'reverse_cache';

  /// Auto-increment primary key
  IntColumn get id => integer().autoIncrement()();

  /// Rounded latitude for spatial indexing (e.g., 55.75 -> 55.8)
  RealColumn get latBucket => real()();

  /// Rounded longitude for spatial indexing
  RealColumn get lonBucket => real()();

  /// Exact latitude of the request
  RealColumn get lat => real()();

  /// Exact longitude of the request
  RealColumn get lon => real()();

  /// Serialized ReverseResponse as JSON
  TextColumn get responseJson => text()();

  /// Language code (ru, en, etc.)
  TextColumn get language => text().nullable()();

  /// Timestamp when entry was created (milliseconds since epoch)
  IntColumn get createdAt => integer()();

  /// Timestamp when entry expires (milliseconds since epoch)
  IntColumn get expiresAt => integer()();
}
