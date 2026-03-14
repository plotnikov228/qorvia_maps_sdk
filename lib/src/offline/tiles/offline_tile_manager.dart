import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../navigation/navigation_logger.dart';
import '../../models/tile_download/tile_download.dart';
import '../../services/tile_download_service.dart';
import '../database/cache_database.dart';
import 'download_progress.dart';
import 'offline_region.dart';

const _logTag = 'OfflineTileManager';

/// Manager for offline map tile downloads.
///
/// **DEPRECATED**: Use [OfflinePackageManager] for new implementations.
/// This manager handles only tiles, while [OfflinePackageManager] provides
/// unified packages with tiles, routing, and geocoding in one download.
///
/// ## Migration Guide
///
/// Replace [OfflineTileManager] with [OfflinePackageManager]:
///
/// ```dart
/// // Old way (deprecated):
/// final tileManager = OfflineTileManager(database: db, downloadService: svc);
/// final region = await tileManager.createRegion(params, styleUrl: url);
/// tileManager.downloadRegion(region.id).listen((progress) { ... });
///
/// // New way (recommended):
/// final packageManager = QorviaMapsSDK.packageManager;
/// final package = await packageManager.createPackage(
///   CreatePackageParams(
///     name: 'Moscow',
///     bounds: bounds,
///     contentTypes: {PackageContentType.tiles}, // or add routing, geocoding
///   ),
/// );
/// packageManager.downloadPackage(package.id).listen((event) { ... });
/// ```
///
/// ## Features
///
/// Provides functionality to:
/// - Create and manage offline map regions
/// - Download map tiles for offline use via server API
/// - Monitor download progress
/// - Pause, resume, and cancel downloads
/// - Delete offline regions
///
/// This manager uses a server-side API for tile extraction and downloads
/// mbtiles files that are installed into MapLibre's cache.
///
/// ## Example
///
/// ```dart
/// final manager = OfflineTileManager(
///   database: cacheDatabase,
///   downloadService: tileDownloadService,
/// );
/// await manager.initialize();
///
/// // Get available server regions
/// final serverRegions = await manager.getServerRegions();
///
/// // Estimate size before downloading
/// final estimate = await manager.estimateRegion(params);
/// print('Estimated size: ${estimate.sizeFormatted}');
///
/// // Create a region
/// final region = await manager.createRegion(
///   CreateOfflineRegionParams(
///     name: 'Moscow Center',
///     bounds: OfflineBounds(
///       southwest: Coordinates(lat: 55.70, lon: 37.55),
///       northeast: Coordinates(lat: 55.80, lon: 37.70),
///     ),
///     minZoom: 10,
///     maxZoom: 16,
///   ),
///   styleUrl: 'https://maps.example.com/style.json',
/// );
///
/// // Download with progress updates
/// manager.downloadRegion(region.id).listen((progress) {
///   print('Downloaded: ${progress.progressPercent}%');
/// });
/// ```
///
/// @Deprecated('Use OfflinePackageManager instead for unified offline packages')
@Deprecated('Use OfflinePackageManager instead for unified offline packages')
class OfflineTileManager {
  final CacheDatabase _database;
  final TileDownloadService _downloadService;
  final String _defaultStyleUrl;

  bool _initialized = false;

  /// Directory where mbtiles files are stored.
  late final String _tilesDirectory;

  /// Active download streams by region ID.
  final Map<String, StreamController<DownloadProgress>> _downloadStreams = {};

  /// Cached regions for quick access.
  final Map<String, OfflineRegion> _cachedRegions = {};

  /// UUID generator for region IDs.
  static const _uuid = Uuid();

  /// Creates an offline tile manager.
  ///
  /// [database] is used to persist region metadata.
  /// [downloadService] is used to communicate with the server API.
  /// [defaultStyleUrl] is used when creating regions without a specific style.
  OfflineTileManager({
    required CacheDatabase database,
    required TileDownloadService downloadService,
    String defaultStyleUrl = '',
  })  : _database = database,
        _downloadService = downloadService,
        _defaultStyleUrl = defaultStyleUrl;

  /// Whether the manager is initialized.
  bool get isInitialized => _initialized;

  /// Initializes the offline manager.
  ///
  /// Must be called before any other operations.
  /// Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;

    NavigationLogger.info(_logTag, 'Initializing offline tile manager');

    try {
      // Create tiles directory
      final appDir = await getApplicationDocumentsDirectory();
      _tilesDirectory = path.join(appDir.path, 'offline_tiles');
      await Directory(_tilesDirectory).create(recursive: true);

      NavigationLogger.debug(_logTag, 'Tiles directory', {
        'path': _tilesDirectory,
      });

      // Load existing regions from database
      await _loadRegionsFromDatabase();

      // Sync with actual files on disk
      await _syncWithFiles();

      _initialized = true;
      NavigationLogger.info(_logTag, 'Offline tile manager initialized', {
        'cachedRegions': _cachedRegions.length,
        'tilesDirectory': _tilesDirectory,
      });
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'Failed to initialize', e, stack);
      rethrow;
    }
  }

  /// Ensures the manager is initialized.
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'OfflineTileManager is not initialized. Call initialize() first.',
      );
    }
  }

  /// Loads regions from database into cache.
  Future<void> _loadRegionsFromDatabase() async {
    final dbRegions = await _database.getAllOfflineRegions();

    for (final dbRegion in dbRegions) {
      final region = _dbRegionToModel(dbRegion);
      _cachedRegions[region.id] = region;
    }

    NavigationLogger.debug(_logTag, 'Loaded regions from database', {
      'count': dbRegions.length,
    });
  }

  /// Syncs our database with actual files on disk.
  ///
  /// Marks regions as failed if their files don't exist.
  Future<void> _syncWithFiles() async {
    for (final region in _cachedRegions.values.toList()) {
      if (region.filePath != null && region.status == OfflineRegionStatus.completed) {
        final file = File(region.filePath!);
        if (!await file.exists()) {
          NavigationLogger.warn(_logTag, 'Region file missing', {
            'regionId': region.id,
            'filePath': region.filePath,
          });

          // Mark as failed since file is missing
          await _updateRegionStatus(
            region.id,
            OfflineRegionStatus.failed,
            errorMessage: 'Tiles file not found',
          );
        }
      }
    }
  }

  /// Converts database model to domain model.
  OfflineRegion _dbRegionToModel(OfflineRegionTableData data) {
    return OfflineRegion(
      id: data.regionId,
      name: data.name,
      bounds: OfflineBounds.fromCoordinates(
        swLat: data.swLat,
        swLon: data.swLon,
        neLat: data.neLat,
        neLon: data.neLon,
      ),
      minZoom: data.minZoom,
      maxZoom: data.maxZoom,
      styleUrl: data.styleUrl,
      status: OfflineRegionStatusX.fromString(data.status),
      downloadedTiles: data.downloadedTiles,
      totalTiles: data.totalTiles,
      sizeBytes: data.sizeBytes,
      errorMessage: data.errorMessage,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data.updatedAt),
      filePath: data.filePath,
      serverRegionId: data.serverRegionId,
      regionType: data.regionType,
    );
  }

  /// Gets the list of predefined regions available on the server.
  ///
  /// These are pre-configured regions that can be downloaded without
  /// specifying custom bounds.
  Future<List<TileRegion>> getServerRegions() async {
    _ensureInitialized();
    return _downloadService.getRegions();
  }

  /// Estimates the size and tile count for a region.
  ///
  /// [params] contains the region bounds and zoom levels.
  ///
  /// Returns [TileEstimateResponse] with estimated size and tile count.
  Future<TileEstimateResponse> estimateRegion(
    CreateOfflineRegionParams params,
  ) async {
    _ensureInitialized();
    params.validate();

    return _downloadService.estimate(
      bounds: params.bounds,
      minZoom: params.minZoom.toInt(),
      maxZoom: params.maxZoom.toInt(),
    );
  }

  /// Creates a new offline region.
  ///
  /// The region is saved to the database but tiles are not downloaded yet.
  /// Call [downloadRegion] to start downloading tiles.
  ///
  /// [params] contains the region configuration.
  /// [styleUrl] is the map style URL. If null, uses the default style.
  /// [serverRegionId] if provided, creates a preset region linked to the server.
  ///
  /// Returns the created [OfflineRegion].
  Future<OfflineRegion> createRegion(
    CreateOfflineRegionParams params, {
    String? styleUrl,
    String? serverRegionId,
  }) async {
    _ensureInitialized();
    params.validate();

    final regionId = _uuid.v4();
    final now = DateTime.now();
    final effectiveStyleUrl = styleUrl ?? _defaultStyleUrl;
    final regionType = serverRegionId != null ? 'preset' : 'custom';

    if (effectiveStyleUrl.isEmpty) {
      throw ArgumentError('Style URL is required');
    }

    NavigationLogger.info(_logTag, 'Creating offline region', {
      'name': params.name,
      'bounds': params.bounds.toString(),
      'zoom': '${params.minZoom}-${params.maxZoom}',
      'type': regionType,
      'serverRegionId': serverRegionId,
    });

    // Save to database
    await _database.insertOfflineRegion(
      OfflineRegionTableCompanion(
        regionId: Value(regionId),
        name: Value(params.name),
        swLat: Value(params.bounds.southwest.lat),
        swLon: Value(params.bounds.southwest.lon),
        neLat: Value(params.bounds.northeast.lat),
        neLon: Value(params.bounds.northeast.lon),
        minZoom: Value(params.minZoom),
        maxZoom: Value(params.maxZoom),
        styleUrl: Value(effectiveStyleUrl),
        status: const Value('pending'),
        downloadedTiles: const Value(0),
        totalTiles: const Value(0),
        sizeBytes: const Value(0),
        createdAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
        serverRegionId: Value(serverRegionId),
        regionType: Value(regionType),
      ),
    );

    final region = OfflineRegion(
      id: regionId,
      name: params.name,
      bounds: params.bounds,
      minZoom: params.minZoom,
      maxZoom: params.maxZoom,
      styleUrl: effectiveStyleUrl,
      status: OfflineRegionStatus.pending,
      downloadedTiles: 0,
      totalTiles: 0,
      sizeBytes: 0,
      createdAt: now,
      updatedAt: now,
      serverRegionId: serverRegionId,
      regionType: regionType,
    );

    _cachedRegions[regionId] = region;

    NavigationLogger.info(_logTag, 'Offline region created', {
      'id': regionId,
      'name': params.name,
    });

    return region;
  }

  /// Creates a region from a server preset.
  ///
  /// [serverRegion] is the preset region from [getServerRegions].
  /// [styleUrl] is the map style URL.
  ///
  /// Returns the created [OfflineRegion].
  Future<OfflineRegion> createRegionFromPreset(
    TileRegion serverRegion, {
    required String styleUrl,
  }) async {
    return createRegion(
      CreateOfflineRegionParams(
        name: serverRegion.name,
        bounds: serverRegion.bounds,
        minZoom: serverRegion.minZoom.toDouble(),
        maxZoom: serverRegion.maxZoom.toDouble(),
      ),
      styleUrl: styleUrl,
      serverRegionId: serverRegion.id,
    );
  }

  /// Gets a region by ID.
  ///
  /// Returns null if not found.
  Future<OfflineRegion?> getRegion(String regionId) async {
    _ensureInitialized();

    // Check cache first
    if (_cachedRegions.containsKey(regionId)) {
      return _cachedRegions[regionId];
    }

    // Load from database
    final dbRegion = await _database.getOfflineRegion(regionId);
    if (dbRegion != null) {
      final region = _dbRegionToModel(dbRegion);
      _cachedRegions[regionId] = region;
      return region;
    }

    return null;
  }

  /// Gets all offline regions.
  Future<List<OfflineRegion>> getAllRegions() async {
    _ensureInitialized();

    // Refresh from database
    await _loadRegionsFromDatabase();

    return _cachedRegions.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Starts downloading tiles for a region.
  ///
  /// Returns a stream of [DownloadProgress] updates.
  /// The stream completes when download finishes or fails.
  ///
  /// [regionId] is the ID of the region to download.
  ///
  /// Throws [StateError] if region is not found or already downloading.
  Stream<DownloadProgress> downloadRegion(String regionId) {
    _ensureInitialized();

    final region = _cachedRegions[regionId];
    if (region == null) {
      throw StateError('Region not found: $regionId');
    }

    if (region.isDownloading) {
      // Return existing stream if already downloading
      final existingStream = _downloadStreams[regionId];
      if (existingStream != null) {
        return existingStream.stream;
      }
    }

    if (!region.canDownload) {
      throw StateError(
        'Cannot download region with status: ${region.status}',
      );
    }

    NavigationLogger.info(_logTag, 'Starting download', {
      'regionId': regionId,
      'name': region.name,
      'type': region.regionType,
    });

    // Create stream controller
    final controller = StreamController<DownloadProgress>.broadcast();
    _downloadStreams[regionId] = controller;

    // Start download asynchronously
    _startDownload(region, controller);

    return controller.stream;
  }

  /// Internal method to start the download process.
  Future<void> _startDownload(
    OfflineRegion region,
    StreamController<DownloadProgress> controller,
  ) async {
    try {
      // Update status to downloading
      await _updateRegionStatus(region.id, OfflineRegionStatus.downloading);

      // Emit started event
      controller.add(DownloadProgress.started(regionId: region.id));

      // 1. Request extract from server
      NavigationLogger.debug(_logTag, 'Requesting tile extract', {
        'regionId': region.id,
        'serverRegionId': region.serverRegionId,
      });

      final TileExtractResponse extractResponse;
      if (region.serverRegionId != null) {
        // Use server preset region
        extractResponse = await _downloadService.extractRegion(
          region.serverRegionId!,
          minZoom: region.minZoom.toInt(),
          maxZoom: region.maxZoom.toInt(),
        );
      } else {
        // Use custom bounds
        extractResponse = await _downloadService.extractByBounds(
          bounds: region.bounds,
          minZoom: region.minZoom.toInt(),
          maxZoom: region.maxZoom.toInt(),
        );
      }

      NavigationLogger.debug(_logTag, 'Extract response received', {
        'regionId': region.id,
        'filename': extractResponse.filename,
        'sizeMb': extractResponse.sizeMb,
        'tilesCount': extractResponse.tilesCount,
      });

      // Update total tiles count
      _cachedRegions[region.id] = region.copyWith(
        totalTiles: extractResponse.tilesCount,
      );
      await _database.updateRegionProgress(
        region.id,
        downloadedTiles: 0,
        sizeBytes: 0,
        status: 'downloading',
      );
      await _database.updateOfflineRegionById(
        region.id,
        OfflineRegionTableCompanion(
          totalTiles: Value(extractResponse.tilesCount),
        ),
      );

      // 2. Download the mbtiles file
      final filePath = path.join(_tilesDirectory, extractResponse.filename);

      NavigationLogger.debug(_logTag, 'Starting file download', {
        'regionId': region.id,
        'url': extractResponse.downloadUrl,
        'savePath': filePath,
      });

      await for (final fileProgress in _downloadService.downloadFile(
        extractResponse.downloadUrl,
        filePath,
      )) {
        if (controller.isClosed) break;

        final completedTiles =
            (fileProgress.progress * extractResponse.tilesCount).round();

        final progress = DownloadProgress.update(
          regionId: region.id,
          completedTiles: completedTiles,
          totalTiles: extractResponse.tilesCount,
          downloadedBytes: fileProgress.receivedBytes,
        );

        controller.add(progress);

        // Update database periodically (every 10%)
        final progressPercent = (fileProgress.progress * 100).round();
        if (progressPercent % 10 == 0) {
          await _database.updateRegionProgress(
            region.id,
            downloadedTiles: completedTiles,
            sizeBytes: fileProgress.receivedBytes,
          );

          _cachedRegions[region.id] = _cachedRegions[region.id]!.copyWith(
            downloadedTiles: completedTiles,
            sizeBytes: fileProgress.receivedBytes,
          );
        }
      }

      // 3. Install in MapLibre - try mergeOfflineRegions first, fallback to installOfflineMapTiles
      NavigationLogger.debug(_logTag, 'Installing tiles in MapLibre', {
        'regionId': region.id,
        'filePath': filePath,
      });

      try {
        // mergeOfflineRegions works better with mbtiles format
        final mergedRegions = await maplibre.mergeOfflineRegions(filePath);
        NavigationLogger.info(_logTag, 'Merged offline regions', {
          'count': mergedRegions.length,
          'regions': mergedRegions.map((r) => r.id).toList(),
        });
      } catch (e) {
        NavigationLogger.warn(_logTag, 'mergeOfflineRegions failed, trying installOfflineMapTiles', {
          'error': e.toString(),
        });
        // Fallback to installOfflineMapTiles
        await maplibre.installOfflineMapTiles(filePath);
      }

      // 4. Update database with completion
      await _updateRegionWithFile(
        region.id,
        filePath,
        extractResponse.sizeMb,
        extractResponse.tilesCount,
      );

      NavigationLogger.info(_logTag, 'Download completed', {
        'regionId': region.id,
        'filePath': filePath,
        'sizeMb': extractResponse.sizeMb,
      });

      // Emit completion
      if (!controller.isClosed) {
        controller.add(DownloadProgress.completed(
          regionId: region.id,
          totalTiles: extractResponse.tilesCount,
          downloadedBytes: extractResponse.sizeBytes,
        ));
        await controller.close();
      }
      _downloadStreams.remove(region.id);
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'Download failed', e, stack);

      // Update status to failed
      await _updateRegionStatus(
        region.id,
        OfflineRegionStatus.failed,
        errorMessage: e.toString(),
      );

      // Emit error
      if (!controller.isClosed) {
        controller.add(DownloadProgress.error(
          regionId: region.id,
          message: e.toString(),
        ));
        await controller.close();
      }
      _downloadStreams.remove(region.id);
    }
  }

  /// Updates region with downloaded file information.
  Future<void> _updateRegionWithFile(
    String regionId,
    String filePath,
    double sizeMb,
    int tilesCount,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final sizeBytes = (sizeMb * 1024 * 1024).round();

    await _database.updateOfflineRegionById(
      regionId,
      OfflineRegionTableCompanion(
        status: const Value('completed'),
        filePath: Value(filePath),
        downloadedTiles: Value(tilesCount),
        totalTiles: Value(tilesCount),
        sizeBytes: Value(sizeBytes),
        updatedAt: Value(now),
      ),
    );

    final cached = _cachedRegions[regionId];
    if (cached != null) {
      _cachedRegions[regionId] = cached.copyWith(
        status: OfflineRegionStatus.completed,
        filePath: filePath,
        downloadedTiles: tilesCount,
        totalTiles: tilesCount,
        sizeBytes: sizeBytes,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );
    }
  }

  /// Pauses a download.
  ///
  /// Note: The current implementation cancels the download.
  /// Calling [resumeDownload] will restart from the beginning.
  Future<void> pauseDownload(String regionId) async {
    _ensureInitialized();

    NavigationLogger.info(_logTag, 'Pausing download', {'regionId': regionId});

    // Cancel the file download
    final region = _cachedRegions[regionId];
    if (region?.filePath != null) {
      _downloadService.cancelDownload(
        path.join(_tilesDirectory, '${regionId}_temp.mbtiles'),
      );
    }

    // Close the stream
    final controller = _downloadStreams.remove(regionId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }

    await _updateRegionStatus(regionId, OfflineRegionStatus.paused);
  }

  /// Resumes a paused download.
  ///
  /// Note: This restarts the download from the beginning.
  ///
  /// Returns a stream of [DownloadProgress] updates.
  Stream<DownloadProgress> resumeDownload(String regionId) {
    _ensureInitialized();

    final region = _cachedRegions[regionId];
    if (region == null) {
      throw StateError('Region not found: $regionId');
    }

    if (region.status != OfflineRegionStatus.paused &&
        region.status != OfflineRegionStatus.failed) {
      throw StateError(
        'Cannot resume region with status: ${region.status}',
      );
    }

    NavigationLogger.info(_logTag, 'Resuming download', {
      'regionId': regionId,
    });

    // Reset progress
    _cachedRegions[regionId] = region.copyWith(
      status: OfflineRegionStatus.pending,
      downloadedTiles: 0,
    );

    return downloadRegion(regionId);
  }

  /// Cancels a download and removes the region.
  ///
  /// This deletes all downloaded tiles for the region.
  Future<void> cancelDownload(String regionId) async {
    _ensureInitialized();

    NavigationLogger.info(_logTag, 'Cancelling download', {
      'regionId': regionId,
    });

    // Cancel the file download
    _downloadService.cancelDownload(
      path.join(_tilesDirectory, '${regionId}_temp.mbtiles'),
    );

    // Close stream
    final controller = _downloadStreams.remove(regionId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }

    // Delete region
    await deleteRegion(regionId);
  }

  /// Deletes an offline region and all its downloaded tiles.
  Future<void> deleteRegion(String regionId) async {
    _ensureInitialized();

    NavigationLogger.info(_logTag, 'Deleting region', {'regionId': regionId});

    final region = _cachedRegions[regionId];

    // Close any active download stream
    final controller = _downloadStreams.remove(regionId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }

    // Delete native MapLibre region if this is a native download
    if (region?.regionType == 'native' && region?.serverRegionId != null) {
      try {
        // serverRegionId format: 'native_123'
        final nativeIdStr = region!.serverRegionId!.replaceFirst('native_', '');
        final nativeId = int.tryParse(nativeIdStr);
        if (nativeId != null) {
          final nativeRegions = await maplibre.getListOfRegions();
          final nativeRegion = nativeRegions.cast<maplibre.OfflineRegion?>().firstWhere(
            (r) => r?.id == nativeId,
            orElse: () => null,
          );
          if (nativeRegion != null) {
            await maplibre.deleteOfflineRegion(nativeId);
            NavigationLogger.debug(_logTag, 'Deleted native MapLibre region', {
              'nativeId': nativeId,
            });
          }
        }
      } catch (e) {
        NavigationLogger.warn(
          _logTag,
          'Failed to delete native MapLibre region',
          {'regionId': regionId, 'error': e.toString()},
        );
      }
    }

    // Delete the mbtiles file
    if (region?.filePath != null) {
      try {
        final file = File(region!.filePath!);
        if (await file.exists()) {
          await file.delete();
          NavigationLogger.debug(_logTag, 'Deleted tiles file', {
            'path': region.filePath,
          });
        }
      } catch (e) {
        NavigationLogger.warn(
          _logTag,
          'Failed to delete tiles file',
          {'regionId': regionId, 'filePath': region?.filePath, 'error': e.toString()},
        );
      }
    }

    // Delete from database
    await _database.deleteOfflineRegion(regionId);

    // Remove from cache
    _cachedRegions.remove(regionId);

    NavigationLogger.info(_logTag, 'Region deleted', {'regionId': regionId});
  }

  /// Updates region status in database and cache.
  Future<void> _updateRegionStatus(
    String regionId,
    OfflineRegionStatus status, {
    String? errorMessage,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _database.updateOfflineRegionById(
      regionId,
      OfflineRegionTableCompanion(
        status: Value(status.toStorageString()),
        errorMessage: Value(errorMessage),
        updatedAt: Value(now),
      ),
    );

    // Update cache
    final cached = _cachedRegions[regionId];
    if (cached != null) {
      _cachedRegions[regionId] = cached.copyWith(
        status: status,
        errorMessage: errorMessage,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );
    }
  }

  /// Gets the total size of all downloaded regions in bytes.
  Future<int> getTotalDownloadedSize() async {
    _ensureInitialized();

    int totalSize = 0;
    for (final region in _cachedRegions.values) {
      totalSize += region.sizeBytes;
    }
    return totalSize;
  }

  /// Gets the number of completed regions.
  int get completedRegionsCount {
    return _cachedRegions.values
        .where((r) => r.status == OfflineRegionStatus.completed)
        .length;
  }

  /// Checks if there are any completed offline regions available.
  bool get hasOfflineRegions => completedRegionsCount > 0;

  /// Gets all completed offline regions.
  List<OfflineRegion> get completedRegions {
    return _cachedRegions.values
        .where((r) => r.status == OfflineRegionStatus.completed && r.filePath != null)
        .toList();
  }

  /// Generates an offline style URL for MapLibre.
  ///
  /// This creates a style JSON file that points to local mbtiles sources,
  /// allowing MapLibre to use downloaded tiles when the server is unavailable.
  ///
  /// Returns the path to the generated style JSON file, or null if no
  /// completed regions are available.
  ///
  /// The generated style uses `mbtiles://` protocol which MapLibre
  /// supports for reading tiles from local SQLite databases.
  Future<String?> generateOfflineStyleUrl() async {
    _ensureInitialized();

    final regions = completedRegions;
    if (regions.isEmpty) {
      NavigationLogger.debug(_logTag, 'No completed regions for offline style');
      return null;
    }

    NavigationLogger.info(_logTag, 'Generating offline style', {
      'regionsCount': regions.length,
    });

    try {
      // Collect all mbtiles sources
      final sources = <String, Map<String, dynamic>>{};
      OfflineBounds? combinedBounds;

      for (final region in regions) {
        if (region.filePath == null) continue;

        final file = File(region.filePath!);
        if (!await file.exists()) {
          NavigationLogger.warn(_logTag, 'Skipping missing file', {
            'regionId': region.id,
            'filePath': region.filePath,
          });
          continue;
        }

        // Add source for this region's mbtiles
        final sourceId = 'offline_${region.id.replaceAll('-', '_')}';
        sources[sourceId] = {
          'type': 'raster',
          'tiles': ['mbtiles://${region.filePath}'],
          'tileSize': 256,
          'minzoom': region.minZoom.toInt(),
          'maxzoom': region.maxZoom.toInt(),
        };

        // Expand combined bounds
        if (combinedBounds == null) {
          combinedBounds = region.bounds;
        } else {
          combinedBounds = OfflineBounds.fromCoordinates(
            swLat: combinedBounds.southwest.lat < region.bounds.southwest.lat
                ? combinedBounds.southwest.lat
                : region.bounds.southwest.lat,
            swLon: combinedBounds.southwest.lon < region.bounds.southwest.lon
                ? combinedBounds.southwest.lon
                : region.bounds.southwest.lon,
            neLat: combinedBounds.northeast.lat > region.bounds.northeast.lat
                ? combinedBounds.northeast.lat
                : region.bounds.northeast.lat,
            neLon: combinedBounds.northeast.lon > region.bounds.northeast.lon
                ? combinedBounds.northeast.lon
                : region.bounds.northeast.lon,
          );
        }
      }

      if (sources.isEmpty) {
        NavigationLogger.warn(_logTag, 'No valid mbtiles sources found');
        return null;
      }

      // Create layers for each source
      final layers = <Map<String, dynamic>>[];
      for (final sourceId in sources.keys) {
        layers.add({
          'id': '${sourceId}_layer',
          'type': 'raster',
          'source': sourceId,
        });
      }

      // Build the style JSON
      final style = {
        'version': 8,
        'name': 'Offline Style',
        'sources': sources,
        'layers': layers,
        if (combinedBounds != null)
          'bounds': [
            combinedBounds.southwest.lon,
            combinedBounds.southwest.lat,
            combinedBounds.northeast.lon,
            combinedBounds.northeast.lat,
          ],
      };

      // Write style to file
      final styleJson = jsonEncode(style);
      final stylePath = path.join(_tilesDirectory, 'offline_style.json');
      await File(stylePath).writeAsString(styleJson);

      NavigationLogger.info(_logTag, 'Offline style generated', {
        'path': stylePath,
        'sources': sources.length,
      });

      return stylePath;
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'Failed to generate offline style', e, stack);
      return null;
    }
  }

  /// Checks if offline mode should be used.
  ///
  /// Returns true if there are completed regions and the style file exists.
  Future<bool> shouldUseOfflineMode() async {
    if (!_initialized) return false;
    if (!hasOfflineRegions) return false;

    final stylePath = path.join(_tilesDirectory, 'offline_style.json');
    return File(stylePath).exists();
  }

  /// Gets the existing offline style URL if available.
  ///
  /// Unlike [generateOfflineStyleUrl], this doesn't regenerate the style
  /// file, it just returns the path if it exists.
  Future<String?> getOfflineStyleUrl() async {
    _ensureInitialized();

    if (!hasOfflineRegions) return null;

    final stylePath = path.join(_tilesDirectory, 'offline_style.json');
    if (await File(stylePath).exists()) {
      return stylePath;
    }

    // Generate if not exists
    return generateOfflineStyleUrl();
  }

  /// Sets the maximum number of tiles that can be downloaded.
  ///
  /// Default is 6000 tiles. Set to null for unlimited.
  Future<void> setTileCountLimit(int? limit) async {
    _ensureInitialized();

    if (limit != null) {
      await maplibre.setOfflineTileCountLimit(limit);
      NavigationLogger.debug(_logTag, 'Tile count limit set', {'limit': limit});
    }
  }

  /// Gets all MapLibre native regions.
  ///
  /// Useful for debugging or advanced use cases.
  Future<List<maplibre.OfflineRegion>> getNativeRegions() async {
    return maplibre.getListOfRegions();
  }

  /// Resets the MapLibre offline database by deleting it.
  ///
  /// This can fix "no such table: regions" errors caused by a corrupted
  /// database. The database will be recreated when the app restarts
  /// and displays a map.
  ///
  /// **Warning:** This will delete all downloaded offline regions!
  ///
  /// Returns true if the database was deleted, false if it didn't exist.
  Future<bool> resetNativeDatabase() async {
    NavigationLogger.warn(_logTag, 'Resetting native MapLibre database');

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final appSupportDir = await getApplicationSupportDirectory();

      // On Android, MapLibre stores the database in context.getFilesDir()
      // which corresponds to /data/data/<package>/files/
      // On iOS, it's in the app support directory
      final possiblePaths = [
        // Android: files directory
        path.join(appDir.parent.path, 'files', 'mbgl-offline.db'),
        // iOS: app support directory
        path.join(appSupportDir.path, 'mbgl-offline.db'),
        // Alternative locations
        path.join(appDir.path, 'mbgl-offline.db'),
        path.join(appDir.parent.path, 'databases', 'mbgl-offline.db'),
      ];

      NavigationLogger.debug(_logTag, 'Searching for database in paths', {
        'paths': possiblePaths,
      });

      bool deleted = false;
      for (final dbPath in possiblePaths) {
        final dbFile = File(dbPath);
        if (await dbFile.exists()) {
          await dbFile.delete();
          NavigationLogger.info(_logTag, 'Deleted MapLibre database', {
            'path': dbPath,
          });
          deleted = true;
        }
      }

      if (!deleted) {
        // List all files in the files directory to help debug
        final filesDir = Directory(path.join(appDir.parent.path, 'files'));
        if (await filesDir.exists()) {
          final files = await filesDir.list().toList();
          NavigationLogger.debug(_logTag, 'Files in app files directory', {
            'files': files.map((f) => f.path).toList(),
          });
        }
      }

      // Also reset our verification flag
      _nativeDatabaseVerified = false;

      return deleted;
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'Failed to reset native database', e, stack);
      return false;
    }
  }

  /// Installs pre-packaged offline tiles from an mbtiles database.
  ///
  /// [tilesDbPath] is the path to the mbtiles file.
  /// This copies the tiles to MapLibre's cache directory.
  Future<void> installOfflineTiles(String tilesDbPath) async {
    NavigationLogger.info(_logTag, 'Installing offline tiles', {
      'path': tilesDbPath,
    });

    await maplibre.installOfflineMapTiles(tilesDbPath);

    NavigationLogger.info(_logTag, 'Offline tiles installed');
  }

  /// Flag to track if native database has been verified
  bool _nativeDatabaseVerified = false;

  /// Ensures MapLibre's offline database is initialized and valid.
  ///
  /// This must be called before using [downloadRegionNative] if no map
  /// has been displayed yet. The database is created on first access.
  ///
  /// If the database is corrupted, this method will attempt to fix it
  /// by deleting and recreating it.
  Future<void> _ensureNativeDatabaseInitialized() async {
    if (_nativeDatabaseVerified) return;

    try {
      // Setting tile count limit should trigger offline manager initialization
      NavigationLogger.debug(_logTag, 'Setting offline tile count limit...');
      await maplibre.setOfflineTileCountLimit(10000);

      // Then try to list regions - this verifies the database schema exists
      NavigationLogger.debug(_logTag, 'Listing existing regions...');
      final existingRegions = await maplibre.getListOfRegions();
      NavigationLogger.debug(_logTag, 'Found existing regions', {
        'count': existingRegions.length,
      });

      _nativeDatabaseVerified = true;
      NavigationLogger.info(_logTag, 'Native offline database verified');
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'Failed to verify native database', e, stack);

      // Check if this is a "no such table" error - database is corrupted
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('no such table') || errorStr.contains('database')) {
        NavigationLogger.warn(_logTag, 'Database appears corrupted, attempting to fix...');

        // Try to delete the corrupted database
        final deleted = await resetNativeDatabase();
        if (deleted) {
          NavigationLogger.info(_logTag, 'Corrupted database deleted');
          // Throw an error asking user to restart
          throw StateError(
            'База данных MapLibre была повреждена и удалена. '
            'Пожалуйста, перезапустите приложение и попробуйте снова.',
          );
        }
      }

      _nativeDatabaseVerified = true; // Don't retry
    }
  }

  /// Finds the path to the MapLibre offline database.
  Future<String?> _findNativeDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();

    // On Android, MapLibre stores the database in context.getFilesDir()
    final possiblePaths = [
      path.join(appDir.parent.path, 'files', 'mbgl-offline.db'),
      path.join(appDir.path, 'mbgl-offline.db'),
    ];

    for (final dbPath in possiblePaths) {
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        return dbPath;
      }
    }

    return null;
  }

  /// Checks if the MapLibre offline database exists and has valid schema.
  Future<bool> isNativeDatabaseValid() async {
    final dbPath = await _findNativeDatabasePath();
    if (dbPath == null) {
      NavigationLogger.debug(_logTag, 'Native database file not found');
      return false;
    }

    NavigationLogger.debug(_logTag, 'Found native database', {'path': dbPath});

    // Check file size - empty or very small files are likely corrupted
    final dbFile = File(dbPath);
    final size = await dbFile.length();
    if (size < 1024) {
      NavigationLogger.warn(_logTag, 'Database file is too small', {
        'size': size,
      });
      return false;
    }

    return true;
  }

  /// Downloads a region using MapLibre's native offline download.
  ///
  /// This is an alternative to [downloadRegion] that uses MapLibre's
  /// built-in offline functionality instead of server-side mbtiles extraction.
  ///
  /// [styleUrl] must be a valid MapLibre style URL.
  /// [bounds] defines the geographic area to download.
  /// [minZoom] and [maxZoom] define the zoom range.
  /// [onProgress] is called with download progress (0.0 to 1.0).
  ///
  /// Returns the MapLibre [OfflineRegion] after download completes.
  Future<maplibre.OfflineRegion> downloadRegionNative({
    required String styleUrl,
    required OfflineBounds bounds,
    required int minZoom,
    required int maxZoom,
    String? regionName,
    void Function(double progress)? onProgress,
  }) async {
    _ensureInitialized();

    // Ensure native offline database is initialized
    await _ensureNativeDatabaseInitialized();

    final name = regionName ?? 'Offline Region';
    final regionId = _uuid.v4();

    NavigationLogger.info(_logTag, 'Starting native MapLibre download', {
      'regionId': regionId,
      'styleUrl': styleUrl,
      'bounds': bounds.toString(),
      'zoom': '$minZoom-$maxZoom',
    });

    final definition = maplibre.OfflineRegionDefinition(
      bounds: maplibre.LatLngBounds(
        southwest: maplibre.LatLng(bounds.southwest.lat, bounds.southwest.lon),
        northeast: maplibre.LatLng(bounds.northeast.lat, bounds.northeast.lon),
      ),
      mapStyleUrl: styleUrl,
      minZoom: minZoom.toDouble(),
      maxZoom: maxZoom.toDouble(),
    );

    final now = DateTime.now();
    final metadata = <String, dynamic>{
      'name': name,
      'regionId': regionId,
      'createdAt': now.toIso8601String(),
    };

    // Save to our database first (as downloading)
    await _database.insertOfflineRegion(
      OfflineRegionTableCompanion(
        regionId: Value(regionId),
        name: Value(name),
        swLat: Value(bounds.southwest.lat),
        swLon: Value(bounds.southwest.lon),
        neLat: Value(bounds.northeast.lat),
        neLon: Value(bounds.northeast.lon),
        minZoom: Value(minZoom.toDouble()),
        maxZoom: Value(maxZoom.toDouble()),
        styleUrl: Value(styleUrl),
        status: const Value('downloading'),
        downloadedTiles: const Value(0),
        totalTiles: const Value(0),
        sizeBytes: const Value(0),
        createdAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
        regionType: const Value('native'),
      ),
    );

    _cachedRegions[regionId] = OfflineRegion(
      id: regionId,
      name: name,
      bounds: bounds,
      minZoom: minZoom.toDouble(),
      maxZoom: maxZoom.toDouble(),
      styleUrl: styleUrl,
      status: OfflineRegionStatus.downloading,
      downloadedTiles: 0,
      totalTiles: 0,
      sizeBytes: 0,
      createdAt: now,
      updatedAt: now,
      regionType: 'native',
    );

    try {
      final region = await maplibre.downloadOfflineRegion(
        definition,
        metadata: metadata,
        onEvent: (event) {
          if (event is maplibre.InProgress) {
            NavigationLogger.debug(_logTag, 'Native download progress', {
              'progress': event.progress,
            });
            onProgress?.call(event.progress);
          } else if (event is maplibre.Success) {
            NavigationLogger.info(_logTag, 'Native download completed');
          } else if (event is maplibre.Error) {
            NavigationLogger.error(_logTag, 'Native download error', event.cause);
          }
        },
      );

      // Update database with completion
      await _database.updateOfflineRegionById(
        regionId,
        OfflineRegionTableCompanion(
          status: const Value('completed'),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          serverRegionId: Value('native_${region.id}'),
        ),
      );

      _cachedRegions[regionId] = _cachedRegions[regionId]!.copyWith(
        status: OfflineRegionStatus.completed,
        serverRegionId: 'native_${region.id}',
        updatedAt: DateTime.now(),
      );

      NavigationLogger.info(_logTag, 'Native region downloaded', {
        'id': region.id,
        'regionId': regionId,
      });

      return region;
    } catch (e, stack) {
      // Update database with failure
      await _updateRegionStatus(
        regionId,
        OfflineRegionStatus.failed,
        errorMessage: e.toString(),
      );

      NavigationLogger.error(_logTag, 'Native download failed', e, stack);
      rethrow;
    }
  }

  /// Merges regions from another offline database.
  ///
  /// [databasePath] is the path to the secondary MapLibre database.
  /// Returns the list of merged regions.
  Future<List<maplibre.OfflineRegion>> mergeOfflineRegions(
    String databasePath,
  ) async {
    NavigationLogger.info(_logTag, 'Merging offline regions', {
      'path': databasePath,
    });

    final mergedRegions = await maplibre.mergeOfflineRegions(databasePath);

    NavigationLogger.info(_logTag, 'Merged regions', {
      'count': mergedRegions.length,
    });

    return mergedRegions;
  }

  /// Disposes resources.
  ///
  /// Closes all active download streams.
  Future<void> dispose() async {
    NavigationLogger.debug(_logTag, 'Disposing offline tile manager');

    // Cancel all active downloads
    _downloadService.dispose();

    for (final controller in _downloadStreams.values) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    _downloadStreams.clear();
    _cachedRegions.clear();
    _initialized = false;
  }
}
