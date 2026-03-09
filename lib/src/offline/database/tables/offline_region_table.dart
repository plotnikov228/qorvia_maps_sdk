import 'package:drift/drift.dart';

/// Table for storing offline map region metadata.
///
/// Tracks downloaded regions with their bounds, zoom levels, and status.
class OfflineRegionTable extends Table {
  @override
  String get tableName => 'offline_regions';

  /// Auto-increment primary key
  IntColumn get id => integer().autoIncrement()();

  /// Unique region identifier (UUID)
  TextColumn get regionId => text().unique()();

  /// Human-readable region name
  TextColumn get name => text()();

  /// Southwest bound latitude
  RealColumn get swLat => real()();

  /// Southwest bound longitude
  RealColumn get swLon => real()();

  /// Northeast bound latitude
  RealColumn get neLat => real()();

  /// Northeast bound longitude
  RealColumn get neLon => real()();

  /// Minimum zoom level
  RealColumn get minZoom => real()();

  /// Maximum zoom level
  RealColumn get maxZoom => real()();

  /// Style URL used for this region
  TextColumn get styleUrl => text()();

  /// Download status: pending, downloading, paused, completed, failed
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Number of downloaded tiles
  IntColumn get downloadedTiles => integer().withDefault(const Constant(0))();

  /// Total number of tiles to download
  IntColumn get totalTiles => integer().withDefault(const Constant(0))();

  /// Size in bytes
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();

  /// Error message if status is failed
  TextColumn get errorMessage => text().nullable()();

  /// Path to the downloaded .mbtiles file
  TextColumn get filePath => text().nullable()();

  /// ID of the region on the server (for preset regions)
  TextColumn get serverRegionId => text().nullable()();

  /// Type of region: 'custom' or 'preset'
  TextColumn get regionType =>
      text().withDefault(const Constant('custom'))();

  /// Timestamp when region was created (milliseconds since epoch)
  IntColumn get createdAt => integer()();

  /// Timestamp when region was last updated (milliseconds since epoch)
  IntColumn get updatedAt => integer()();
}
