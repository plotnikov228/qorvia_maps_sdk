import 'package:drift/drift.dart';

/// Table for storing offline package metadata.
///
/// A package is a collection of offline content (tiles, routing, geocoding)
/// for a specific geographic region. This table stores the master record,
/// while PackageContentTable stores the individual content types.
class OfflinePackageTable extends Table {
  @override
  String get tableName => 'offline_packages';

  /// Auto-increment primary key
  IntColumn get id => integer().autoIncrement()();

  /// Unique package identifier (UUID)
  TextColumn get packageId => text().unique()();

  /// Human-readable package name
  TextColumn get name => text()();

  /// Southwest bound latitude
  RealColumn get swLat => real()();

  /// Southwest bound longitude
  RealColumn get swLon => real()();

  /// Northeast bound latitude
  RealColumn get neLat => real()();

  /// Northeast bound longitude
  RealColumn get neLon => real()();

  /// Minimum zoom level (for tiles)
  RealColumn get minZoom => real().withDefault(const Constant(0))();

  /// Maximum zoom level (for tiles)
  RealColumn get maxZoom => real().withDefault(const Constant(16))();

  /// Map style URL (for tiles)
  TextColumn get styleUrl => text().nullable()();

  /// Package status: pending, downloading, paused, completed, partiallyComplete, failed
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Total size of all content in bytes
  IntColumn get totalSizeBytes => integer().withDefault(const Constant(0))();

  /// Total downloaded bytes across all content
  IntColumn get downloadedSizeBytes => integer().withDefault(const Constant(0))();

  /// Error message if status is failed
  TextColumn get errorMessage => text().nullable()();

  /// Server region ID (for preset packages)
  TextColumn get serverRegionId => text().nullable()();

  /// Timestamp when package was created (milliseconds since epoch)
  IntColumn get createdAt => integer()();

  /// Timestamp when package was last updated (milliseconds since epoch)
  IntColumn get updatedAt => integer()();
}
