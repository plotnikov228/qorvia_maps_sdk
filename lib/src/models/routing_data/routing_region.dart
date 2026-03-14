import '../../offline/tiles/offline_region.dart';

/// Routing profile available for offline routing.
enum RoutingProfile {
  /// Standard car/automobile routing.
  car,

  /// Bicycle routing with bike-friendly paths.
  bike,

  /// Pedestrian/walking routing.
  foot,
}

/// Extension methods for [RoutingProfile].
extension RoutingProfileX on RoutingProfile {
  /// Converts profile to API string.
  String toApiString() => name;

  /// Parses profile from API string.
  static RoutingProfile fromString(String value) {
    return RoutingProfile.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => RoutingProfile.car,
    );
  }
}

/// Represents a routing data region available on the server.
///
/// These are geographic regions with precomputed routing graphs
/// that can be downloaded for offline route calculation.
class RoutingRegion {
  /// Unique identifier for this region on the server.
  final String id;

  /// Human-readable name for the region.
  final String name;

  /// Optional description of the region.
  final String? description;

  /// Geographic bounds of the region.
  final OfflineBounds bounds;

  /// Estimated size of the routing data in megabytes.
  final double sizeMb;

  /// Supported routing profiles for this region.
  final List<RoutingProfile> profiles;

  /// Version identifier for update checking.
  final String version;

  /// OpenStreetMap data date (ISO 8601 format).
  final String? osmDate;

  /// SHA-256 checksum for file verification.
  final String checksum;

  const RoutingRegion({
    required this.id,
    required this.name,
    this.description,
    required this.bounds,
    required this.sizeMb,
    required this.profiles,
    required this.version,
    this.osmDate,
    required this.checksum,
  });

  /// Creates a RoutingRegion from JSON data.
  factory RoutingRegion.fromJson(Map<String, dynamic> json) {
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
      throw ArgumentError('RoutingRegion.fromJson: missing bbox or bounds');
    }

    // Parse routing profiles
    final profilesJson = json['profiles'] as List<dynamic>? ?? ['car'];
    final profiles = profilesJson
        .map((p) => RoutingProfileX.fromString(p as String))
        .toList();

    return RoutingRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      bounds: bounds,
      sizeMb:
          (json['size_mb'] as num? ?? json['estimated_size_mb'] as num? ?? 0)
              .toDouble(),
      profiles: profiles,
      version: json['version'] as String? ?? '1.0',
      osmDate: json['osm_date'] as String?,
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
        'profiles': profiles.map((p) => p.toApiString()).toList(),
        'version': version,
        if (osmDate != null) 'osm_date': osmDate,
        'checksum': checksum,
      };

  /// Human-readable size string.
  String get sizeFormatted {
    if (sizeMb < 1) return '${(sizeMb * 1024).toStringAsFixed(0)} KB';
    if (sizeMb < 1024) return '${sizeMb.toStringAsFixed(1)} MB';
    return '${(sizeMb / 1024).toStringAsFixed(2)} GB';
  }

  /// Human-readable profiles list.
  String get profilesFormatted => profiles.map((p) => p.name).join(', ');

  /// Checks if a specific profile is supported.
  bool supportsProfile(RoutingProfile profile) => profiles.contains(profile);

  @override
  String toString() => 'RoutingRegion(id: $id, name: $name, '
      'size: $sizeFormatted, profiles: $profilesFormatted)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutingRegion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Response from version check API.
class RoutingVersionInfo {
  /// Region ID.
  final String regionId;

  /// Current version on server.
  final String currentVersion;

  /// Whether an update is available.
  final bool updateAvailable;

  /// Size of the update in megabytes (if available).
  final double? updateSizeMb;

  /// Changelog or update notes.
  final String? changelog;

  const RoutingVersionInfo({
    required this.regionId,
    required this.currentVersion,
    required this.updateAvailable,
    this.updateSizeMb,
    this.changelog,
  });

  /// Creates from JSON.
  factory RoutingVersionInfo.fromJson(Map<String, dynamic> json) {
    return RoutingVersionInfo(
      regionId: json['region_id'] as String,
      currentVersion: json['current_version'] as String,
      updateAvailable: json['update_available'] as bool? ?? false,
      updateSizeMb: (json['update_size_mb'] as num?)?.toDouble(),
      changelog: json['changelog'] as String?,
    );
  }
}

/// Response from routing data download request.
class RoutingDownloadInfo {
  /// Download URL for the .ghz file.
  final String downloadUrl;

  /// File size in bytes.
  final int sizeBytes;

  /// SHA-256 checksum for verification.
  final String checksum;

  /// URL expiration time (if pre-signed).
  final DateTime? expiresAt;

  const RoutingDownloadInfo({
    required this.downloadUrl,
    required this.sizeBytes,
    required this.checksum,
    this.expiresAt,
  });

  /// Creates from JSON.
  factory RoutingDownloadInfo.fromJson(Map<String, dynamic> json) {
    return RoutingDownloadInfo(
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
