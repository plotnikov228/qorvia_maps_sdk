import 'package:drift/drift.dart';

import 'offline_package_table.dart';

/// Table for storing individual content types within an offline package.
///
/// Each package can have multiple content types (tiles, routing, geocoding, etc.).
/// This table tracks the download status and metadata for each content type.
class PackageContentTable extends Table {
  @override
  String get tableName => 'package_contents';

  /// Auto-increment primary key
  IntColumn get id => integer().autoIncrement()();

  /// Package ID (foreign key to OfflinePackageTable)
  TextColumn get packageId => text().references(OfflinePackageTable, #packageId)();

  /// Content type: tiles, routing, geocoding, reverseGeocoding
  TextColumn get contentType => text()();

  /// Content status: notDownloaded, queued, downloading, ready, failed, updateAvailable
  TextColumn get status => text().withDefault(const Constant('notDownloaded'))();

  /// Path to the downloaded file
  TextColumn get filePath => text().nullable()();

  /// Total size of this content in bytes
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();

  /// Downloaded bytes for this content
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();

  /// Version identifier for this content
  TextColumn get version => text().nullable()();

  /// SHA-256 checksum for verification
  TextColumn get checksum => text().nullable()();

  /// Error message if status is failed
  TextColumn get errorMessage => text().nullable()();

  /// Timestamp when content was created (milliseconds since epoch)
  IntColumn get createdAt => integer()();

  /// Timestamp when content was last updated (milliseconds since epoch)
  IntColumn get updatedAt => integer()();

  @override
  List<Set<Column>>? get uniqueKeys => [
        {packageId, contentType},
      ];
}
