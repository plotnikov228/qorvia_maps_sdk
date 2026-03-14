import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../../client/http_client.dart';
import '../../../models/geocoding_data/geocoding_region.dart';
import '../../../services/tile_download_service.dart';
import '../../tiles/offline_region.dart';

/// Service for downloading offline geocoding data from the server.
///
/// **Note:** Offline geocoding data is not yet available from the server.
/// This service is planned for future releases.
///
/// Provides access to SQLite databases with FTS5 for offline address search:
/// - List available geocoding regions
/// - Check for updates to existing regions
/// - Download geocoding data with progress tracking
/// - Validate downloaded files with checksums
///
/// Example:
/// ```dart
/// final service = GeocodingDataService(httpClient);
///
/// // Get available regions
/// final regions = await service.getAvailableRegions();
///
/// // Check for updates
/// final versionInfo = await service.checkVersion('moscow', '1.0');
///
/// // Download geocoding data
/// final downloadInfo = await service.getDownloadInfo('moscow');
/// await for (final progress in service.downloadGeocodingData(
///   downloadInfo.downloadUrl,
///   '/path/to/geocoding/moscow.db',
/// )) {
///   print('Download: ${(progress.progress * 100).toStringAsFixed(0)}%');
/// }
///
/// // Validate checksum
/// final isValid = await service.validateChecksum(
///   '/path/to/geocoding/moscow.db',
///   downloadInfo.checksum,
/// );
/// ```
@Deprecated('Offline geocoding data not yet available from server.')
class GeocodingDataService {
  final QorviaMapsHttpClient _client;

  /// Active cancel tokens for in-progress downloads.
  final Map<String, CancelToken> _cancelTokens = {};

  /// Logger callback for verbose logging.
  final void Function(String message)? _logger;

  GeocodingDataService(
    this._client, {
    void Function(String message)? logger,
  }) : _logger = logger;

  void _log(String message) {
    _logger?.call('[GeocodingDataService] $message');
  }

  /// Gets the list of available geocoding regions from the server.
  ///
  /// Returns a list of [GeocodingRegion] objects that users can download.
  ///
  /// Endpoint: GET /v1/mobile/geocoding/regions
  Future<List<GeocodingRegion>> getAvailableRegions() async {
    _log('Fetching available geocoding regions...');

    final data = await _client.get('/v1/mobile/geocoding/regions');
    final regionsJson = data['regions'] as List<dynamic>;

    final regions = regionsJson
        .map((json) => GeocodingRegion.fromJson(json as Map<String, dynamic>))
        .toList();

    _log('Found ${regions.length} available geocoding regions');
    return regions;
  }

  /// Gets geocoding regions that cover the specified bounds.
  ///
  /// [bounds] - Geographic bounds to search within.
  ///
  /// Returns regions that intersect with or contain the specified bounds.
  ///
  /// Endpoint: POST /v1/mobile/geocoding/regions/search
  Future<List<GeocodingRegion>> getRegionsForBounds(OfflineBounds bounds) async {
    _log('Searching geocoding regions for bounds: $bounds');

    final data = await _client.post(
      '/v1/mobile/geocoding/regions/search',
      data: {
        'bounds': {
          'sw_lat': bounds.southwest.lat,
          'sw_lon': bounds.southwest.lon,
          'ne_lat': bounds.northeast.lat,
          'ne_lon': bounds.northeast.lon,
        },
      },
    );

    final regionsJson = data['regions'] as List<dynamic>;
    final regions = regionsJson
        .map((json) => GeocodingRegion.fromJson(json as Map<String, dynamic>))
        .toList();

    _log('Found ${regions.length} regions covering bounds');
    return regions;
  }

  /// Checks if a newer version is available for a region.
  ///
  /// [regionId] - Server-side region ID.
  /// [currentVersion] - Currently downloaded version.
  ///
  /// Returns [GeocodingVersionInfo] with update availability.
  ///
  /// Endpoint: GET /v1/mobile/geocoding/version/{id}
  Future<GeocodingVersionInfo> checkVersion(
    String regionId,
    String currentVersion,
  ) async {
    _log('Checking version for region: $regionId (current: $currentVersion)');

    final data = await _client.get(
      '/v1/mobile/geocoding/version/$regionId',
      queryParameters: {'current_version': currentVersion},
    );

    final versionInfo = GeocodingVersionInfo.fromJson(data);
    _log('Update available: ${versionInfo.updateAvailable}');

    return versionInfo;
  }

  /// Gets download information for a geocoding region.
  ///
  /// [regionId] - Server-side region ID.
  /// [dataType] - Optional specific data type to include.
  /// [languages] - Optional specific languages to include.
  ///
  /// Returns [GeocodingDownloadInfo] with download URL and metadata.
  ///
  /// Endpoint: POST /v1/mobile/geocoding/download/{id}
  Future<GeocodingDownloadInfo> getDownloadInfo(
    String regionId, {
    GeocodingDataType? dataType,
    List<String>? languages,
  }) async {
    _log('Getting download info for region: $regionId');

    final Map<String, dynamic> body = {};
    if (dataType != null) {
      body['data_type'] = dataType.toApiString();
    }
    if (languages != null && languages.isNotEmpty) {
      body['languages'] = languages;
    }

    final data = await _client.post(
      '/v1/mobile/geocoding/download/$regionId',
      data: body.isNotEmpty ? body : null,
    );

    final downloadInfo = GeocodingDownloadInfo.fromJson(data);
    _log('Download URL obtained, size: ${downloadInfo.sizeFormatted}');

    return downloadInfo;
  }

  /// Downloads the geocoding database file from the given URL.
  ///
  /// [downloadUrl] - URL to download the SQLite database from.
  /// [savePath] - Local path to save the downloaded file.
  ///
  /// Returns a stream of [FileDownloadProgress] updates.
  /// The stream completes when the download finishes successfully.
  /// On error, the stream emits an error event.
  ///
  /// Use [cancelDownload] to cancel an in-progress download.
  Stream<FileDownloadProgress> downloadGeocodingData(
    String downloadUrl,
    String savePath,
  ) {
    _log('Starting download to: $savePath');

    final controller = StreamController<FileDownloadProgress>();
    final cancelToken = CancelToken();

    // Store cancel token for potential cancellation
    _cancelTokens[savePath] = cancelToken;

    _executeDownload(
      downloadUrl,
      savePath,
      controller,
      cancelToken,
    );

    return controller.stream;
  }

  /// Cancels an in-progress download.
  ///
  /// [savePath] - The save path used when starting the download.
  void cancelDownload(String savePath) {
    final cancelToken = _cancelTokens.remove(savePath);
    if (cancelToken != null) {
      _log('Cancelling download: $savePath');
      cancelToken.cancel('Download cancelled by user');
    }
  }

  /// Validates the checksum of a downloaded file.
  ///
  /// [filePath] - Path to the downloaded file.
  /// [expectedChecksum] - Expected SHA-256 checksum.
  ///
  /// Returns true if the checksum matches.
  Future<bool> validateChecksum(
    String filePath,
    String expectedChecksum,
  ) async {
    _log('Validating checksum for: $filePath');

    if (expectedChecksum.isEmpty) {
      _log('No checksum provided, skipping validation');
      return true;
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _log('File not found: $filePath');
        return false;
      }

      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      final actualChecksum = digest.toString();

      final isValid =
          actualChecksum.toLowerCase() == expectedChecksum.toLowerCase();
      _log('Checksum ${isValid ? "valid" : "INVALID"}: '
          'expected=$expectedChecksum, actual=$actualChecksum');

      return isValid;
    } catch (e) {
      _log('Checksum validation error: $e');
      return false;
    }
  }

  /// Calculates the SHA-256 checksum of a file.
  ///
  /// [filePath] - Path to the file.
  ///
  /// Returns the checksum as a hex string, or null on error.
  Future<String?> calculateChecksum(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      _log('Error calculating checksum: $e');
      return null;
    }
  }

  /// Verifies that a downloaded database is valid SQLite.
  ///
  /// [filePath] - Path to the database file.
  ///
  /// Returns true if the file is a valid SQLite database.
  Future<bool> validateDatabaseIntegrity(String filePath) async {
    _log('Validating database integrity: $filePath');

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _log('File not found: $filePath');
        return false;
      }

      // Check SQLite header magic bytes: "SQLite format 3\000"
      final bytes = await file.openRead(0, 16).first;
      final header = String.fromCharCodes(bytes.take(15));
      final isValid = header == 'SQLite format 3';

      _log('Database ${isValid ? "valid" : "INVALID"} SQLite format');
      return isValid;
    } catch (e) {
      _log('Database validation error: $e');
      return false;
    }
  }

  Future<void> _executeDownload(
    String downloadUrl,
    String savePath,
    StreamController<FileDownloadProgress> controller,
    CancelToken cancelToken,
  ) async {
    try {
      // Ensure parent directory exists
      final file = File(savePath);
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        _log('Created directory: ${dir.path}');
      }

      await _client.downloadFile(
        downloadUrl,
        savePath,
        onProgress: (received, total) {
          if (controller.isClosed) return;

          final progress = total > 0 ? received / total : 0.0;
          controller.add(FileDownloadProgress(
            receivedBytes: received,
            totalBytes: total,
            progress: progress,
          ));

          // Log progress at 10% intervals
          final percent = (progress * 100).floor();
          if (percent % 10 == 0) {
            _log('Download progress: $percent%');
          }
        },
        cancelToken: cancelToken,
      );

      // Download completed successfully
      _cancelTokens.remove(savePath);
      _log('Download completed: $savePath');

      if (!controller.isClosed) {
        controller.add(const FileDownloadProgress(
          receivedBytes: 0,
          totalBytes: 0,
          progress: 1.0,
        ));
        await controller.close();
      }
    } catch (e) {
      _cancelTokens.remove(savePath);

      if (!controller.isClosed) {
        if (e is DioException && e.type == DioExceptionType.cancel) {
          _log('Download cancelled: $savePath');
          controller.addError('Download cancelled');
        } else {
          _log('Download error: $e');
          controller.addError(e);
        }
        await controller.close();
      }
    }
  }

  /// Deletes a downloaded geocoding database file.
  ///
  /// [filePath] - Path to the file to delete.
  ///
  /// Returns true if deleted successfully or file didn't exist.
  Future<bool> deleteGeocodingData(String filePath) async {
    _log('Deleting geocoding data: $filePath');

    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _log('Deleted: $filePath');
      }
      return true;
    } catch (e) {
      _log('Error deleting file: $e');
      return false;
    }
  }

  /// Gets the size of a downloaded geocoding database file in bytes.
  ///
  /// Returns null if the file doesn't exist or on error.
  Future<int?> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Disposes resources.
  ///
  /// Cancels all in-progress downloads.
  void dispose() {
    _log('Disposing GeocodingDataService');
    for (final entry in _cancelTokens.entries) {
      entry.value.cancel('Service disposed');
    }
    _cancelTokens.clear();
  }
}
