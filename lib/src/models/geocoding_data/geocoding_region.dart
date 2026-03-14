import '../../offline/tiles/offline_region.dart';

/// Type of geocoding data content.
enum GeocodingDataType {
  /// Forward geocoding (address text → coordinates).
  forward,

  /// Reverse geocoding (coordinates → address).
  reverse,

  /// Combined forward and reverse geocoding.
  combined,
}

/// Extension methods for [GeocodingDataType].
extension GeocodingDataTypeX on GeocodingDataType {
  /// Converts type to API string.
  String toApiString() => name;

  /// Parses type from API string.
  static GeocodingDataType fromString(String value) {
    return GeocodingDataType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => GeocodingDataType.combined,
    );
  }
}

/// Represents a geocoding data region available on the server.
///
/// These are geographic regions with precomputed geocoding databases
/// (SQLite + FTS5) that can be downloaded for offline address search.
class GeocodingRegion {
  /// Unique identifier for this region on the server.
  final String id;

  /// Human-readable name for the region.
  final String name;

  /// Optional description of the region.
  final String? description;

  /// Geographic bounds of the region.
  final OfflineBounds bounds;

  /// Estimated size of the geocoding database in megabytes.
  final double sizeMb;

  /// Type of geocoding data available.
  final GeocodingDataType dataType;

  /// Number of addresses/POIs in the database.
  final int addressCount;

  /// Supported languages for search (ISO 639-1 codes).
  final List<String> languages;

  /// Version identifier for update checking.
  final String version;

  /// Data source date (ISO 8601 format).
  final String? dataDate;

  /// SHA-256 checksum for file verification.
  final String checksum;

  const GeocodingRegion({
    required this.id,
    required this.name,
    this.description,
    required this.bounds,
    required this.sizeMb,
    required this.dataType,
    required this.addressCount,
    required this.languages,
    required this.version,
    this.dataDate,
    required this.checksum,
  });

  /// Creates a GeocodingRegion from JSON data.
  factory GeocodingRegion.fromJson(Map<String, dynamic> json) {
    // Handle server format with bbox (east/north/south/west)
    final bboxJson = json['bbox'] as Map<String, dynamic>?;
    final boundsJson = json['bounds'] as Map<String, dynamic>?;

    late final OfflineBounds bounds;
    if (bboxJson != null) {
      bounds = OfflineBounds.fromCoordinates(
        swLat: (bboxJson['south'] as num).toDouble(),
        swLon: (bboxJson['west'] as num).toDouble(),
        neLat: (bboxJson['north'] as num).toDouble(),
        neLon: (bboxJson['east'] as num).toDouble(),
      );
    } else if (boundsJson != null) {
      bounds = OfflineBounds.fromCoordinates(
        swLat: (boundsJson['sw_lat'] as num).toDouble(),
        swLon: (boundsJson['sw_lon'] as num).toDouble(),
        neLat: (boundsJson['ne_lat'] as num).toDouble(),
        neLon: (boundsJson['ne_lon'] as num).toDouble(),
      );
    } else {
      throw ArgumentError('GeocodingRegion.fromJson: missing bbox or bounds');
    }

    // Parse languages
    final languagesJson = json['languages'] as List<dynamic>? ?? ['en'];
    final languages = languagesJson.map((l) => l as String).toList();

    return GeocodingRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      bounds: bounds,
      sizeMb:
          (json['size_mb'] as num? ?? json['estimated_size_mb'] as num? ?? 0)
              .toDouble(),
      dataType: GeocodingDataTypeX.fromString(
          json['data_type'] as String? ?? 'combined'),
      addressCount: json['address_count'] as int? ?? 0,
      languages: languages,
      version: json['version'] as String? ?? '1.0',
      dataDate: json['data_date'] as String?,
      checksum: json['checksum'] as String? ?? '',
    );
  }

  /// Converts this region to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'bounds': {
          'sw_lat': bounds.southwest.lat,
          'sw_lon': bounds.southwest.lon,
          'ne_lat': bounds.northeast.lat,
          'ne_lon': bounds.northeast.lon,
        },
        'size_mb': sizeMb,
        'data_type': dataType.toApiString(),
        'address_count': addressCount,
        'languages': languages,
        'version': version,
        if (dataDate != null) 'data_date': dataDate,
        'checksum': checksum,
      };

  /// Human-readable size string.
  String get sizeFormatted {
    if (sizeMb < 1) return '${(sizeMb * 1024).toStringAsFixed(0)} KB';
    if (sizeMb < 1024) return '${sizeMb.toStringAsFixed(1)} MB';
    return '${(sizeMb / 1024).toStringAsFixed(2)} GB';
  }

  /// Human-readable address count.
  String get addressCountFormatted {
    if (addressCount < 1000) return '$addressCount';
    if (addressCount < 1000000) {
      return '${(addressCount / 1000).toStringAsFixed(1)}K';
    }
    return '${(addressCount / 1000000).toStringAsFixed(1)}M';
  }

  /// Human-readable languages list.
  String get languagesFormatted => languages.join(', ');

  /// Whether forward geocoding is supported.
  bool get supportsForward =>
      dataType == GeocodingDataType.forward ||
      dataType == GeocodingDataType.combined;

  /// Whether reverse geocoding is supported.
  bool get supportsReverse =>
      dataType == GeocodingDataType.reverse ||
      dataType == GeocodingDataType.combined;

  @override
  String toString() => 'GeocodingRegion(id: $id, name: $name, '
      'size: $sizeFormatted, addresses: $addressCountFormatted)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeocodingRegion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Response from version check API.
class GeocodingVersionInfo {
  /// Region ID.
  final String regionId;

  /// Current version on server.
  final String currentVersion;

  /// Whether an update is available.
  final bool updateAvailable;

  /// Size of the update in megabytes (if available).
  final double? updateSizeMb;

  /// Number of new addresses in update.
  final int? newAddressCount;

  /// Changelog or update notes.
  final String? changelog;

  const GeocodingVersionInfo({
    required this.regionId,
    required this.currentVersion,
    required this.updateAvailable,
    this.updateSizeMb,
    this.newAddressCount,
    this.changelog,
  });

  /// Creates from JSON.
  factory GeocodingVersionInfo.fromJson(Map<String, dynamic> json) {
    return GeocodingVersionInfo(
      regionId: json['region_id'] as String,
      currentVersion: json['current_version'] as String,
      updateAvailable: json['update_available'] as bool? ?? false,
      updateSizeMb: (json['update_size_mb'] as num?)?.toDouble(),
      newAddressCount: json['new_address_count'] as int?,
      changelog: json['changelog'] as String?,
    );
  }
}

/// Response from geocoding data download request.
class GeocodingDownloadInfo {
  /// Download URL for the SQLite database file.
  final String downloadUrl;

  /// File size in bytes.
  final int sizeBytes;

  /// SHA-256 checksum for verification.
  final String checksum;

  /// URL expiration time (if pre-signed).
  final DateTime? expiresAt;

  const GeocodingDownloadInfo({
    required this.downloadUrl,
    required this.sizeBytes,
    required this.checksum,
    this.expiresAt,
  });

  /// Creates from JSON.
  factory GeocodingDownloadInfo.fromJson(Map<String, dynamic> json) {
    return GeocodingDownloadInfo(
      downloadUrl: json['download_url'] as String,
      sizeBytes: json['size_bytes'] as int? ?? 0,
      checksum: json['checksum'] as String? ?? '',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  /// File size formatted as human-readable string.
  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
