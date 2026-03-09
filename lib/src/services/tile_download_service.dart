import 'dart:async';

import 'package:dio/dio.dart';

import '../client/http_client.dart';
import '../models/tile_download/tile_download.dart';
import '../offline/tiles/offline_region.dart';

/// Progress information for file downloads.
class FileDownloadProgress {
  /// Number of bytes received so far.
  final int receivedBytes;

  /// Total number of bytes to receive (may be -1 if unknown).
  final int totalBytes;

  /// Progress as a value between 0.0 and 1.0.
  final double progress;

  const FileDownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
    required this.progress,
  });

  @override
  String toString() =>
      'FileDownloadProgress(received: $receivedBytes, total: $totalBytes, progress: ${(progress * 100).toStringAsFixed(1)}%)';
}

/// Service for downloading offline map tiles from the server.
///
/// Provides access to server-side tile extraction and download functionality:
/// - List available predefined regions
/// - Estimate download size for custom bounds
/// - Extract tiles by bounds or region ID
/// - Download mbtiles files with progress tracking
///
/// Example:
/// ```dart
/// final service = TileDownloadService(httpClient);
///
/// // Get available regions
/// final regions = await service.getRegions();
///
/// // Estimate custom region size
/// final estimate = await service.estimate(
///   bounds: myBounds,
///   minZoom: 10,
///   maxZoom: 16,
/// );
///
/// // Extract and download
/// final extract = await service.extractByBounds(
///   bounds: myBounds,
///   minZoom: 10,
///   maxZoom: 16,
/// );
///
/// await for (final progress in service.downloadFile(
///   extract.downloadUrl,
///   '/path/to/save.mbtiles',
/// )) {
///   print('Download: ${(progress.progress * 100).toStringAsFixed(0)}%');
/// }
/// ```
class TileDownloadService {
  final QorviaMapsHttpClient _client;

  /// Active cancel tokens for in-progress downloads.
  final Map<String, CancelToken> _cancelTokens = {};

  TileDownloadService(this._client);

  /// Gets the list of predefined tile regions available on the server.
  ///
  /// Returns a list of [TileRegion] objects that users can download.
  ///
  /// Endpoint: GET /v1/mobile/tiles/regions
  Future<List<TileRegion>> getRegions() async {
    final data = await _client.get('/v1/mobile/tiles/regions');
    final regionsJson = data['regions'] as List<dynamic>;
    return regionsJson
        .map((json) => TileRegion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Estimates the size and tile count for a custom region.
  ///
  /// [bounds] - Geographic bounds of the region.
  /// [minZoom] - Minimum zoom level.
  /// [maxZoom] - Maximum zoom level.
  ///
  /// Returns [TileEstimateResponse] with size and tile count.
  ///
  /// Endpoint: POST /v1/mobile/tiles/estimate
  Future<TileEstimateResponse> estimate({
    required OfflineBounds bounds,
    required int minZoom,
    required int maxZoom,
  }) async {
    final data = await _client.post(
      '/v1/mobile/tiles/estimate',
      data: {
        'bounds': {
          'sw_lat': bounds.southwest.lat,
          'sw_lon': bounds.southwest.lon,
          'ne_lat': bounds.northeast.lat,
          'ne_lon': bounds.northeast.lon,
        },
        'min_zoom': minZoom,
        'max_zoom': maxZoom,
      },
    );
    return TileEstimateResponse.fromJson(data);
  }

  /// Extracts tiles for a custom region by bounds.
  ///
  /// [bounds] - Geographic bounds of the region.
  /// [minZoom] - Minimum zoom level.
  /// [maxZoom] - Maximum zoom level.
  ///
  /// Returns [TileExtractResponse] with download URL and metadata.
  ///
  /// Endpoint: POST /v1/mobile/tiles/extract
  Future<TileExtractResponse> extractByBounds({
    required OfflineBounds bounds,
    required int minZoom,
    required int maxZoom,
  }) async {
    final data = await _client.post(
      '/v1/mobile/tiles/extract',
      data: {
        'bounds': {
          'sw_lat': bounds.southwest.lat,
          'sw_lon': bounds.southwest.lon,
          'ne_lat': bounds.northeast.lat,
          'ne_lon': bounds.northeast.lon,
        },
        'min_zoom': minZoom,
        'max_zoom': maxZoom,
      },
    );
    return TileExtractResponse.fromJson(data);
  }

  /// Extracts tiles for a predefined region by its server ID.
  ///
  /// [regionId] - Server-side region ID.
  /// [minZoom] - Optional minimum zoom override.
  /// [maxZoom] - Optional maximum zoom override.
  ///
  /// Returns [TileExtractResponse] with download URL and metadata.
  ///
  /// Endpoint: POST /v1/mobile/tiles/regions/{id}/extract
  Future<TileExtractResponse> extractRegion(
    String regionId, {
    int? minZoom,
    int? maxZoom,
  }) async {
    final Map<String, dynamic> body = {};
    if (minZoom != null) body['min_zoom'] = minZoom;
    if (maxZoom != null) body['max_zoom'] = maxZoom;

    final data = await _client.post(
      '/v1/mobile/tiles/regions/$regionId/extract',
      data: body.isNotEmpty ? body : null,
    );
    return TileExtractResponse.fromJson(data);
  }

  /// Downloads the mbtiles file from the given URL.
  ///
  /// [downloadUrl] - URL to download the file from.
  /// [savePath] - Local path to save the downloaded file.
  ///
  /// Returns a stream of [FileDownloadProgress] updates.
  /// The stream completes when the download finishes successfully.
  /// On error, the stream emits an error event.
  ///
  /// Use [cancelDownload] to cancel an in-progress download.
  Stream<FileDownloadProgress> downloadFile(
    String downloadUrl,
    String savePath,
  ) {
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
    cancelToken?.cancel('Download cancelled by user');
  }

  Future<void> _executeDownload(
    String downloadUrl,
    String savePath,
    StreamController<FileDownloadProgress> controller,
    CancelToken cancelToken,
  ) async {
    try {
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
        },
        cancelToken: cancelToken,
      );

      // Download completed successfully
      _cancelTokens.remove(savePath);

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
          controller.addError('Download cancelled');
        } else {
          controller.addError(e);
        }
        await controller.close();
      }
    }
  }

  /// Disposes resources.
  ///
  /// Cancels all in-progress downloads.
  void dispose() {
    for (final token in _cancelTokens.values) {
      token.cancel('Service disposed');
    }
    _cancelTokens.clear();
  }
}
