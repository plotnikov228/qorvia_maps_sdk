import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../navigation/navigation_logger.dart';
import '../../services/tile_download_service.dart';
import '../database/cache_database.dart';
import '../tiles/offline_region.dart';
import 'models/offline_package.dart';
import 'models/package_content.dart';
import 'models/package_download_progress.dart';
import 'services/geocoding_data_service.dart';
import 'services/routing_data_service.dart';

const _logTag = 'OfflinePackageManager';

/// Central manager for unified offline packages.
///
/// Orchestrates downloading of all content types (tiles, routing, geocoding)
/// into a single package for a geographic region.
///
/// ## Example
///
/// ```dart
/// final manager = OfflinePackageManager(
///   database: cacheDatabase,
///   tileService: tileDownloadService,
///   routingService: routingDataService,
///   geocodingService: geocodingDataService,
/// );
/// await manager.initialize();
///
/// // Create a package
/// final package = await manager.createPackage(
///   CreatePackageParams(
///     name: 'Moscow',
///     bounds: myBounds,
///     contentTypes: {
///       PackageContentType.tiles,
///       PackageContentType.routing,
///       PackageContentType.geocoding,
///     },
///   ),
/// );
///
/// // Download with progress tracking
/// manager.downloadPackage(package.id).listen((event) {
///   print('Progress: ${event.progress.overallPercent}%');
///   print('Currently downloading: ${event.progress.currentlyDownloading}');
/// });
/// ```
class OfflinePackageManager {
  final CacheDatabase _database;
  final TileDownloadService _tileService;
  final RoutingDataService _routingService;
  final GeocodingDataService _geocodingService;
  final String _defaultStyleUrl;

  bool _initialized = false;

  /// Directory where offline package files are stored.
  late final String _packagesDirectory;

  /// Active download streams by package ID.
  final Map<String, StreamController<PackageDownloadEvent>> _downloadStreams =
      {};

  /// Cached packages for quick access.
  final Map<String, OfflinePackage> _cachedPackages = {};

  /// UUID generator for package IDs.
  static const _uuid = Uuid();

  /// Creates an offline package manager.
  ///
  /// [database] is used to persist package metadata.
  /// [tileService] downloads map tiles.
  /// [routingService] downloads routing data.
  /// [geocodingService] downloads geocoding data.
  /// [defaultStyleUrl] is used for tiles when no style URL is specified.
  OfflinePackageManager({
    required CacheDatabase database,
    required TileDownloadService tileService,
    required RoutingDataService routingService,
    required GeocodingDataService geocodingService,
    String defaultStyleUrl = '',
  })  : _database = database,
        _tileService = tileService,
        _routingService = routingService,
        _geocodingService = geocodingService,
        _defaultStyleUrl = defaultStyleUrl;

  /// Whether the manager is initialized.
  bool get isInitialized => _initialized;

  /// Initializes the package manager.
  ///
  /// Must be called before any other operations.
  /// Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;

    NavigationLogger.info(_logTag, 'Initializing offline package manager');

    try {
      // Create packages directory
      final appDir = await getApplicationDocumentsDirectory();
      _packagesDirectory = path.join(appDir.path, 'offline_packages');
      await Directory(_packagesDirectory).create(recursive: true);

      NavigationLogger.debug(_logTag, 'Packages directory', {
        'path': _packagesDirectory,
      });

      // Load existing packages from database
      await _loadPackagesFromDatabase();

      // Sync with actual files on disk
      await _syncWithFiles();

      _initialized = true;
      NavigationLogger.info(_logTag, 'Offline package manager initialized', {
        'cachedPackages': _cachedPackages.length,
        'packagesDirectory': _packagesDirectory,
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
        'OfflinePackageManager is not initialized. Call initialize() first.',
      );
    }
  }

  /// Loads packages from database into cache.
  Future<void> _loadPackagesFromDatabase() async {
    final dbPackages = await _database.getAllPackages();

    for (final dbPackage in dbPackages) {
      final contents = await _database.getPackageContents(dbPackage.packageId);
      final package = _dbToPackage(dbPackage, contents);
      _cachedPackages[package.id] = package;
    }

    NavigationLogger.debug(_logTag, 'Loaded packages from database', {
      'count': dbPackages.length,
    });
  }

  /// Syncs our database with actual files on disk.
  Future<void> _syncWithFiles() async {
    for (final package in _cachedPackages.values.toList()) {
      var needsUpdate = false;

      for (final content in package.contents.values) {
        if (content.filePath != null && content.isReady) {
          final file = File(content.filePath!);
          if (!await file.exists()) {
            NavigationLogger.warn(_logTag, 'Content file missing', {
              'packageId': package.id,
              'contentType': content.type.name,
              'filePath': content.filePath,
            });

            // Mark content as failed
            await _database.updatePackageContent(
              package.id,
              content.type.toStorageString(),
              PackageContentTableCompanion(
                status: const Value('failed'),
                errorMessage: const Value('File not found'),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
            needsUpdate = true;
          }
        }
      }

      if (needsUpdate) {
        // Reload package from database
        final result = await _database.getPackageWithContents(package.id);
        if (result != null) {
          _cachedPackages[package.id] = _dbToPackage(result.$1, result.$2);
        }
      }
    }
  }

  /// Converts database models to domain model.
  OfflinePackage _dbToPackage(
    OfflinePackageTableData dbPackage,
    List<PackageContentTableData> dbContents,
  ) {
    final contents = <PackageContentType, PackageContent>{};

    for (final dbContent in dbContents) {
      final type = PackageContentTypeX.fromString(dbContent.contentType);
      contents[type] = PackageContent(
        type: type,
        status: ContentStatusX.fromString(dbContent.status),
        filePath: dbContent.filePath,
        sizeBytes: dbContent.sizeBytes,
        downloadedBytes: dbContent.downloadedBytes,
        version: dbContent.version,
        checksum: dbContent.checksum,
        errorMessage: dbContent.errorMessage,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(dbContent.updatedAt),
      );
    }

    return OfflinePackage(
      id: dbPackage.packageId,
      name: dbPackage.name,
      bounds: OfflineBounds.fromCoordinates(
        swLat: dbPackage.swLat,
        swLon: dbPackage.swLon,
        neLat: dbPackage.neLat,
        neLon: dbPackage.neLon,
      ),
      minZoom: dbPackage.minZoom,
      maxZoom: dbPackage.maxZoom,
      status: PackageStatusX.fromString(dbPackage.status),
      contents: contents,
      totalSizeBytes: dbPackage.totalSizeBytes,
      downloadedSizeBytes: dbPackage.downloadedSizeBytes,
      errorMessage: dbPackage.errorMessage,
      createdAt: DateTime.fromMillisecondsSinceEpoch(dbPackage.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(dbPackage.updatedAt),
      serverRegionId: dbPackage.serverRegionId,
      styleUrl: dbPackage.styleUrl,
    );
  }

  // ============================================================
  // Package Operations
  // ============================================================

  /// Creates a new offline package.
  ///
  /// The package is saved to the database but content is not downloaded yet.
  /// Call [downloadPackage] to start downloading.
  Future<OfflinePackage> createPackage(CreatePackageParams params) async {
    _ensureInitialized();
    params.validate();

    final packageId = _uuid.v4();
    final now = DateTime.now();
    final effectiveStyleUrl = params.styleUrl ?? _defaultStyleUrl;

    NavigationLogger.info(_logTag, 'Creating package', {
      'name': params.name,
      'bounds': params.bounds.toString(),
      'contentTypes': params.contentTypes.map((t) => t.name).toList(),
    });

    // Estimate sizes for content types
    final estimatedSize = params.estimateDownloadSize();

    // Save package to database
    await _database.insertPackage(
      OfflinePackageTableCompanion(
        packageId: Value(packageId),
        name: Value(params.name),
        swLat: Value(params.bounds.southwest.lat),
        swLon: Value(params.bounds.southwest.lon),
        neLat: Value(params.bounds.northeast.lat),
        neLon: Value(params.bounds.northeast.lon),
        minZoom: Value(params.minZoom),
        maxZoom: Value(params.maxZoom),
        styleUrl: Value(effectiveStyleUrl.isNotEmpty ? effectiveStyleUrl : null),
        status: const Value('pending'),
        totalSizeBytes: Value(estimatedSize),
        downloadedSizeBytes: const Value(0),
        createdAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );

    // Save content entries to database
    final contents = <PackageContentType, PackageContent>{};
    for (final type in params.contentTypes) {
      final contentNow = DateTime.now();
      await _database.insertPackageContent(
        PackageContentTableCompanion(
          packageId: Value(packageId),
          contentType: Value(type.toStorageString()),
          status: const Value('notDownloaded'),
          sizeBytes: const Value(0),
          downloadedBytes: const Value(0),
          createdAt: Value(contentNow.millisecondsSinceEpoch),
          updatedAt: Value(contentNow.millisecondsSinceEpoch),
        ),
      );

      contents[type] = PackageContent.notDownloaded(type: type);
    }

    final package = OfflinePackage(
      id: packageId,
      name: params.name,
      bounds: params.bounds,
      minZoom: params.minZoom,
      maxZoom: params.maxZoom,
      status: PackageStatus.pending,
      contents: contents,
      totalSizeBytes: estimatedSize,
      downloadedSizeBytes: 0,
      createdAt: now,
      updatedAt: now,
      styleUrl: effectiveStyleUrl.isNotEmpty ? effectiveStyleUrl : null,
    );

    _cachedPackages[packageId] = package;

    NavigationLogger.info(_logTag, 'Package created', {
      'id': packageId,
      'name': params.name,
      'estimatedSize': package.totalSizeFormatted,
    });

    return package;
  }

  /// Gets a package by ID.
  Future<OfflinePackage?> getPackage(String packageId) async {
    _ensureInitialized();

    // Check cache first
    if (_cachedPackages.containsKey(packageId)) {
      return _cachedPackages[packageId];
    }

    // Load from database
    final result = await _database.getPackageWithContents(packageId);
    if (result != null) {
      final package = _dbToPackage(result.$1, result.$2);
      _cachedPackages[packageId] = package;
      return package;
    }

    return null;
  }

  /// Gets all offline packages.
  Future<List<OfflinePackage>> getAllPackages() async {
    _ensureInitialized();

    // Refresh from database
    await _loadPackagesFromDatabase();

    return _cachedPackages.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Gets all packages with a specific status.
  Future<List<OfflinePackage>> getPackagesByStatus(PackageStatus status) async {
    _ensureInitialized();

    return _cachedPackages.values
        .where((p) => p.status == status)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Gets packages that cover a specific location.
  Future<List<OfflinePackage>> getPackagesForLocation(
    double lat,
    double lon, {
    bool readyOnly = true,
  }) async {
    _ensureInitialized();

    return _cachedPackages.values.where((p) {
      if (readyOnly && !p.hasUsableContent) return false;
      return p.bounds.southwest.lat <= lat &&
          p.bounds.northeast.lat >= lat &&
          p.bounds.southwest.lon <= lon &&
          p.bounds.northeast.lon >= lon;
    }).toList();
  }

  /// Deletes a package and all its downloaded content.
  Future<void> deletePackage(String packageId) async {
    _ensureInitialized();

    NavigationLogger.info(_logTag, 'Deleting package', {'packageId': packageId});

    final package = _cachedPackages[packageId];

    // Close any active download stream
    final controller = _downloadStreams.remove(packageId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }

    // Delete content files
    if (package != null) {
      for (final content in package.contents.values) {
        if (content.filePath != null) {
          try {
            final file = File(content.filePath!);
            if (await file.exists()) {
              await file.delete();
              NavigationLogger.debug(_logTag, 'Deleted content file', {
                'type': content.type.name,
                'path': content.filePath,
              });
            }
          } catch (e) {
            NavigationLogger.warn(_logTag, 'Failed to delete content file', {
              'type': content.type.name,
              'path': content.filePath,
              'error': e.toString(),
            });
          }
        }
      }

      // Delete package directory if exists
      final packageDir = path.join(_packagesDirectory, packageId);
      try {
        final dir = Directory(packageDir);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (e) {
        NavigationLogger.warn(_logTag, 'Failed to delete package directory', {
          'path': packageDir,
          'error': e.toString(),
        });
      }
    }

    // Delete from database (cascade deletes contents)
    await _database.deletePackage(packageId);

    // Remove from cache
    _cachedPackages.remove(packageId);

    NavigationLogger.info(_logTag, 'Package deleted', {'packageId': packageId});
  }

  // ============================================================
  // Download Operations
  // ============================================================

  /// Starts downloading a package.
  ///
  /// Returns a stream of [PackageDownloadEvent] updates.
  /// The stream completes when download finishes or fails.
  Stream<PackageDownloadEvent> downloadPackage(String packageId) {
    _ensureInitialized();

    final package = _cachedPackages[packageId];
    if (package == null) {
      throw StateError('Package not found: $packageId');
    }

    if (package.isDownloading) {
      // Return existing stream if already downloading
      final existingStream = _downloadStreams[packageId];
      if (existingStream != null) {
        return existingStream.stream;
      }
    }

    if (!package.canDownload) {
      throw StateError(
        'Cannot download package with status: ${package.status}',
      );
    }

    NavigationLogger.info(_logTag, 'Starting package download', {
      'packageId': packageId,
      'name': package.name,
      'contentTypes': package.contentTypes.map((t) => t.name).toList(),
    });

    // Create stream controller
    final controller = StreamController<PackageDownloadEvent>.broadcast();
    _downloadStreams[packageId] = controller;

    // Start download asynchronously
    _startDownload(package, controller);

    return controller.stream;
  }

  /// Internal method to orchestrate the download.
  Future<void> _startDownload(
    OfflinePackage package,
    StreamController<PackageDownloadEvent> controller,
  ) async {
    final packageId = package.id;

    try {
      // Update status to downloading
      await _updatePackageStatus(packageId, PackageStatus.downloading);

      // Create package directory
      final packageDir = path.join(_packagesDirectory, packageId);
      await Directory(packageDir).create(recursive: true);

      // Initialize progress tracking
      final contentSizes = <PackageContentType, int>{};
      for (final type in package.contentTypes) {
        contentSizes[type] = package.contents[type]?.sizeBytes ?? 0;
      }

      var progress = PackageDownloadProgress.started(
        packageId: packageId,
        contentSizes: contentSizes,
      );

      // Emit started event
      controller.add(PackageDownloadEvent.started(progress));

      // Download each content type sequentially
      final contentOrder = _getDownloadOrder(package.contentTypes);

      for (final contentType in contentOrder) {
        if (controller.isClosed) break;

        NavigationLogger.debug(_logTag, 'Starting content download', {
          'packageId': packageId,
          'contentType': contentType.name,
        });

        // Update progress with current content type
        progress = PackageDownloadProgress.update(
          packageId: packageId,
          contentProgress: progress.contentProgress,
          currentlyDownloading: contentType,
        );
        controller.add(PackageDownloadEvent.contentStarted(progress, contentType));

        // Download the content
        try {
          final result = await _downloadContent(
            package,
            contentType,
            packageDir,
            (downloaded, total) {
              if (controller.isClosed) return;

              // Update progress
              final newContentProgress = ContentProgress(
                type: contentType,
                downloadedBytes: downloaded,
                totalBytes: total,
              );

              progress = progress.copyWithContentProgress(
                contentType,
                newContentProgress,
              );

              controller.add(PackageDownloadEvent.progress(progress));

              // Update database periodically
              _updateContentProgressInDb(packageId, contentType, downloaded, total);
            },
          );

          // Mark content as complete
          final completedProgress = ContentProgress.completed(
            contentType,
            result.sizeBytes,
          );
          progress = progress.copyWithContentProgress(
            contentType,
            completedProgress,
          );

          // Update database with completion
          await _markContentReady(
            packageId,
            contentType,
            result.filePath,
            result.sizeBytes,
            result.version,
            result.checksum,
          );

          controller.add(PackageDownloadEvent.contentCompleted(progress, contentType));

          NavigationLogger.info(_logTag, 'Content download completed', {
            'packageId': packageId,
            'contentType': contentType.name,
            'sizeBytes': result.sizeBytes,
          });
        } catch (e) {
          // Mark content as failed
          final failedProgress = ContentProgress.failed(
            contentType,
            e.toString(),
          );
          progress = progress.copyWithContentProgress(
            contentType,
            failedProgress,
          );

          await _markContentFailed(packageId, contentType, e.toString());

          NavigationLogger.error(_logTag, 'Content download failed', {
            'packageId': packageId,
            'contentType': contentType.name,
            'error': e.toString(),
          });

          // Continue with other content types
        }
      }

      // Determine final status
      final allComplete = progress.contentProgress.values.every((p) => p.isComplete);
      final anyFailed = progress.contentProgress.values.any((p) => p.hasFailed);
      final anyComplete = progress.contentProgress.values.any((p) => p.isComplete);

      PackageStatus finalStatus;
      if (allComplete) {
        finalStatus = PackageStatus.completed;
      } else if (anyFailed && anyComplete) {
        finalStatus = PackageStatus.partiallyComplete;
      } else if (anyFailed) {
        finalStatus = PackageStatus.failed;
      } else {
        finalStatus = PackageStatus.completed;
      }

      await _updatePackageStatus(packageId, finalStatus);

      // Emit completion event
      if (!controller.isClosed) {
        if (finalStatus == PackageStatus.completed) {
          final completedProgress = PackageDownloadProgress.completed(
            packageId: packageId,
            contentProgress: progress.contentProgress,
          );
          controller.add(PackageDownloadEvent.completed(completedProgress));
        } else {
          final errorProgress = PackageDownloadProgress.error(
            packageId: packageId,
            errorMessage: 'Some content failed to download',
            contentProgress: progress.contentProgress,
          );
          controller.add(PackageDownloadEvent.failed(errorProgress));
        }
        await controller.close();
      }

      _downloadStreams.remove(packageId);

      NavigationLogger.info(_logTag, 'Package download finished', {
        'packageId': packageId,
        'status': finalStatus.name,
      });
    } catch (e, stack) {
      NavigationLogger.error(_logTag, 'Package download failed', e, stack);

      await _updatePackageStatus(
        packageId,
        PackageStatus.failed,
        errorMessage: e.toString(),
      );

      if (!controller.isClosed) {
        final errorProgress = PackageDownloadProgress.error(
          packageId: packageId,
          errorMessage: e.toString(),
          contentProgress: {},
        );
        controller.add(PackageDownloadEvent.failed(errorProgress));
        await controller.close();
      }

      _downloadStreams.remove(packageId);
    }
  }

  /// Gets the preferred download order for content types.
  List<PackageContentType> _getDownloadOrder(Set<PackageContentType> types) {
    // Download in this order: tiles, routing, geocoding, reverseGeocoding
    final order = <PackageContentType>[];
    if (types.contains(PackageContentType.tiles)) {
      order.add(PackageContentType.tiles);
    }
    if (types.contains(PackageContentType.routing)) {
      order.add(PackageContentType.routing);
    }
    if (types.contains(PackageContentType.geocoding)) {
      order.add(PackageContentType.geocoding);
    }
    if (types.contains(PackageContentType.reverseGeocoding)) {
      order.add(PackageContentType.reverseGeocoding);
    }
    return order;
  }

  /// Downloads a specific content type.
  Future<_ContentDownloadResult> _downloadContent(
    OfflinePackage package,
    PackageContentType contentType,
    String packageDir,
    void Function(int downloaded, int total) onProgress,
  ) async {
    switch (contentType) {
      case PackageContentType.tiles:
        return _downloadTiles(package, packageDir, onProgress);
      case PackageContentType.routing:
        return _downloadRouting(package, packageDir, onProgress);
      case PackageContentType.geocoding:
        return _downloadGeocoding(package, packageDir, onProgress);
      case PackageContentType.reverseGeocoding:
        return _downloadReverseGeocoding(package, packageDir, onProgress);
    }
  }

  /// Downloads map tiles.
  Future<_ContentDownloadResult> _downloadTiles(
    OfflinePackage package,
    String packageDir,
    void Function(int downloaded, int total) onProgress,
  ) async {
    // Request extract from server
    final extractResponse = await _tileService.extractByBounds(
      bounds: package.bounds,
      minZoom: package.minZoom.toInt(),
      maxZoom: package.maxZoom.toInt(),
    );

    final filePath = path.join(packageDir, extractResponse.filename);
    var lastReportedProgress = 0;

    // Download the mbtiles file
    await for (final progress in _tileService.downloadFile(
      extractResponse.downloadUrl,
      filePath,
    )) {
      final downloaded = progress.receivedBytes;
      final total = progress.totalBytes > 0 ? progress.totalBytes : extractResponse.sizeBytes;

      // Throttle progress updates
      final currentProgress = (progress.progress * 100).round();
      if (currentProgress != lastReportedProgress) {
        lastReportedProgress = currentProgress;
        onProgress(downloaded, total);
      }
    }

    return _ContentDownloadResult(
      filePath: filePath,
      sizeBytes: extractResponse.sizeBytes,
      version: null,
      checksum: null,
    );
  }

  /// Downloads routing data.
  Future<_ContentDownloadResult> _downloadRouting(
    OfflinePackage package,
    String packageDir,
    void Function(int downloaded, int total) onProgress,
  ) async {
    // Find matching routing region
    NavigationLogger.info(_logTag, 'Searching routing regions for bounds', {
      'packageId': package.id,
      'bounds': '${package.bounds.southwest.lat},${package.bounds.southwest.lon} - ${package.bounds.northeast.lat},${package.bounds.northeast.lon}',
    });

    final regions = await _routingService.getRegionsForBounds(package.bounds);

    NavigationLogger.info(_logTag, 'Routing regions search result', {
      'packageId': package.id,
      'regionsFound': regions.length,
      'regionNames': regions.map((r) => r.name).toList(),
    });

    if (regions.isEmpty) {
      throw StateError('No routing data available for this region. '
          'The server does not have routing data for these coordinates. '
          'Try downloading a preset region from the "Available regions" list.');
    }

    final region = regions.first;
    final downloadInfo = await _routingService.getDownloadInfo(region.id);

    final filePath = path.join(packageDir, '${package.id}_routing.ghz');
    var lastReportedProgress = 0;

    // Download the routing file
    await for (final progress in _routingService.downloadRoutingData(
      downloadInfo.downloadUrl,
      filePath,
    )) {
      final downloaded = progress.receivedBytes;
      final total = progress.totalBytes > 0 ? progress.totalBytes : downloadInfo.sizeBytes;

      final currentProgress = (progress.progress * 100).round();
      if (currentProgress != lastReportedProgress) {
        lastReportedProgress = currentProgress;
        onProgress(downloaded, total);
      }
    }

    // Validate checksum
    if (downloadInfo.checksum.isNotEmpty) {
      final isValid = await _routingService.validateChecksum(
        filePath,
        downloadInfo.checksum,
      );
      if (!isValid) {
        await File(filePath).delete();
        throw StateError('Routing data checksum mismatch');
      }
    }

    return _ContentDownloadResult(
      filePath: filePath,
      sizeBytes: downloadInfo.sizeBytes,
      version: region.version,
      checksum: downloadInfo.checksum,
    );
  }

  /// Downloads geocoding data.
  Future<_ContentDownloadResult> _downloadGeocoding(
    OfflinePackage package,
    String packageDir,
    void Function(int downloaded, int total) onProgress,
  ) async {
    // Find matching geocoding region
    NavigationLogger.info(_logTag, 'Searching geocoding regions for bounds', {
      'packageId': package.id,
      'bounds': '${package.bounds.southwest.lat},${package.bounds.southwest.lon} - ${package.bounds.northeast.lat},${package.bounds.northeast.lon}',
    });

    final regions = await _geocodingService.getRegionsForBounds(package.bounds);

    NavigationLogger.info(_logTag, 'Geocoding regions search result', {
      'packageId': package.id,
      'regionsFound': regions.length,
      'regionNames': regions.map((r) => r.name).toList(),
    });

    if (regions.isEmpty) {
      throw StateError('No geocoding data available for this region. '
          'The server does not have geocoding data for these coordinates.');
    }

    final region = regions.first;
    final downloadInfo = await _geocodingService.getDownloadInfo(region.id);

    final filePath = path.join(packageDir, '${package.id}_geocoding.db');
    var lastReportedProgress = 0;

    // Download the geocoding database
    await for (final progress in _geocodingService.downloadGeocodingData(
      downloadInfo.downloadUrl,
      filePath,
    )) {
      final downloaded = progress.receivedBytes;
      final total = progress.totalBytes > 0 ? progress.totalBytes : downloadInfo.sizeBytes;

      final currentProgress = (progress.progress * 100).round();
      if (currentProgress != lastReportedProgress) {
        lastReportedProgress = currentProgress;
        onProgress(downloaded, total);
      }
    }

    // Validate checksum
    if (downloadInfo.checksum.isNotEmpty) {
      final isValid = await _geocodingService.validateChecksum(
        filePath,
        downloadInfo.checksum,
      );
      if (!isValid) {
        await File(filePath).delete();
        throw StateError('Geocoding data checksum mismatch');
      }
    }

    // Validate database integrity
    final isValidDb = await _geocodingService.validateDatabaseIntegrity(filePath);
    if (!isValidDb) {
      await File(filePath).delete();
      throw StateError('Geocoding database is corrupted');
    }

    return _ContentDownloadResult(
      filePath: filePath,
      sizeBytes: downloadInfo.sizeBytes,
      version: region.version,
      checksum: downloadInfo.checksum,
    );
  }

  /// Downloads reverse geocoding data.
  Future<_ContentDownloadResult> _downloadReverseGeocoding(
    OfflinePackage package,
    String packageDir,
    void Function(int downloaded, int total) onProgress,
  ) async {
    // For now, reverse geocoding shares the same database as forward geocoding
    // In future implementations, this could be a separate database optimized
    // for spatial queries

    // Find matching geocoding region
    final regions = await _geocodingService.getRegionsForBounds(package.bounds);
    if (regions.isEmpty) {
      throw StateError('No reverse geocoding data available for this region');
    }

    final region = regions.first;

    // Check if it supports reverse geocoding
    if (!region.supportsReverse) {
      throw StateError('Region does not support reverse geocoding');
    }

    final downloadInfo = await _geocodingService.getDownloadInfo(region.id);

    final filePath = path.join(packageDir, '${package.id}_reverse.db');
    var lastReportedProgress = 0;

    // Download the database
    await for (final progress in _geocodingService.downloadGeocodingData(
      downloadInfo.downloadUrl,
      filePath,
    )) {
      final downloaded = progress.receivedBytes;
      final total = progress.totalBytes > 0 ? progress.totalBytes : downloadInfo.sizeBytes;

      final currentProgress = (progress.progress * 100).round();
      if (currentProgress != lastReportedProgress) {
        lastReportedProgress = currentProgress;
        onProgress(downloaded, total);
      }
    }

    // Validate checksum
    if (downloadInfo.checksum.isNotEmpty) {
      final isValid = await _geocodingService.validateChecksum(
        filePath,
        downloadInfo.checksum,
      );
      if (!isValid) {
        await File(filePath).delete();
        throw StateError('Reverse geocoding data checksum mismatch');
      }
    }

    return _ContentDownloadResult(
      filePath: filePath,
      sizeBytes: downloadInfo.sizeBytes,
      version: region.version,
      checksum: downloadInfo.checksum,
    );
  }

  // ============================================================
  // Database Update Helpers
  // ============================================================

  Future<void> _updatePackageStatus(
    String packageId,
    PackageStatus status, {
    String? errorMessage,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _database.updatePackageById(
      packageId,
      OfflinePackageTableCompanion(
        status: Value(status.toStorageString()),
        errorMessage: Value(errorMessage),
        updatedAt: Value(now),
      ),
    );

    // Update cache
    final cached = _cachedPackages[packageId];
    if (cached != null) {
      _cachedPackages[packageId] = cached.copyWith(
        status: status,
        errorMessage: errorMessage,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );
    }
  }

  void _updateContentProgressInDb(
    String packageId,
    PackageContentType contentType,
    int downloaded,
    int total,
  ) {
    // Fire and forget - don't await to avoid blocking progress updates
    _database.updateContentProgress(
      packageId,
      contentType.toStorageString(),
      downloadedBytes: downloaded,
    );
  }

  Future<void> _markContentReady(
    String packageId,
    PackageContentType contentType,
    String filePath,
    int sizeBytes,
    String? version,
    String? checksum,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _database.updatePackageContent(
      packageId,
      contentType.toStorageString(),
      PackageContentTableCompanion(
        status: const Value('ready'),
        filePath: Value(filePath),
        sizeBytes: Value(sizeBytes),
        downloadedBytes: Value(sizeBytes),
        version: Value(version),
        checksum: Value(checksum),
        updatedAt: Value(now),
      ),
    );

    // Update cache
    final cached = _cachedPackages[packageId];
    if (cached != null) {
      _cachedPackages[packageId] = cached.copyWithContent(
        contentType,
        PackageContent.ready(
          type: contentType,
          filePath: filePath,
          sizeBytes: sizeBytes,
          version: version,
          checksum: checksum,
        ),
      );
    }
  }

  Future<void> _markContentFailed(
    String packageId,
    PackageContentType contentType,
    String errorMessage,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _database.updatePackageContent(
      packageId,
      contentType.toStorageString(),
      PackageContentTableCompanion(
        status: const Value('failed'),
        errorMessage: Value(errorMessage),
        updatedAt: Value(now),
      ),
    );

    // Update cache
    final cached = _cachedPackages[packageId];
    if (cached != null) {
      _cachedPackages[packageId] = cached.copyWithContent(
        contentType,
        PackageContent.failed(
          type: contentType,
          errorMessage: errorMessage,
        ),
      );
    }
  }

  // ============================================================
  // Pause/Resume/Cancel
  // ============================================================

  /// Pauses a download.
  ///
  /// Note: Currently cancels the download. Resuming will restart from beginning.
  Future<void> pauseDownload(String packageId) async {
    _ensureInitialized();

    NavigationLogger.info(_logTag, 'Pausing download', {'packageId': packageId});

    // Close the stream
    final controller = _downloadStreams.remove(packageId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }

    await _updatePackageStatus(packageId, PackageStatus.paused);
  }

  /// Resumes a paused download.
  ///
  /// Note: This restarts the download from the beginning.
  Stream<PackageDownloadEvent> resumeDownload(String packageId) {
    _ensureInitialized();

    final package = _cachedPackages[packageId];
    if (package == null) {
      throw StateError('Package not found: $packageId');
    }

    if (package.status != PackageStatus.paused &&
        package.status != PackageStatus.failed &&
        package.status != PackageStatus.partiallyComplete) {
      throw StateError('Cannot resume package with status: ${package.status}');
    }

    NavigationLogger.info(_logTag, 'Resuming download', {'packageId': packageId});

    return downloadPackage(packageId);
  }

  /// Cancels a download and deletes the package.
  Future<void> cancelDownload(String packageId) async {
    _ensureInitialized();

    NavigationLogger.info(_logTag, 'Cancelling download', {'packageId': packageId});

    await deletePackage(packageId);
  }

  // ============================================================
  // Stats and Info
  // ============================================================

  /// Gets the total size of all downloaded packages in bytes.
  Future<int> getTotalDownloadedSize() async {
    _ensureInitialized();

    int totalSize = 0;
    for (final package in _cachedPackages.values) {
      totalSize += package.downloadedSizeBytes;
    }
    return totalSize;
  }

  /// Gets the number of completed packages.
  int get completedPackagesCount {
    return _cachedPackages.values
        .where((p) => p.status == PackageStatus.completed)
        .length;
  }

  /// Checks if there are any completed offline packages.
  bool get hasOfflinePackages => completedPackagesCount > 0;

  /// Gets all packages with completed tiles.
  List<OfflinePackage> get packagesWithTiles {
    return _cachedPackages.values
        .where((p) => p.hasTilesReady)
        .toList();
  }

  /// Gets all packages with completed routing.
  List<OfflinePackage> get packagesWithRouting {
    return _cachedPackages.values
        .where((p) => p.hasRoutingReady)
        .toList();
  }

  /// Gets all packages with completed geocoding.
  List<OfflinePackage> get packagesWithGeocoding {
    return _cachedPackages.values
        .where((p) => p.hasGeocodingReady)
        .toList();
  }

  /// Finds a package suitable for offline routing between two points.
  OfflinePackage? findPackageForRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    for (final package in packagesWithRouting) {
      if (package.bounds.southwest.lat <= fromLat &&
          package.bounds.northeast.lat >= fromLat &&
          package.bounds.southwest.lon <= fromLon &&
          package.bounds.northeast.lon >= fromLon &&
          package.bounds.southwest.lat <= toLat &&
          package.bounds.northeast.lat >= toLat &&
          package.bounds.southwest.lon <= toLon &&
          package.bounds.northeast.lon >= toLon) {
        return package;
      }
    }
    return null;
  }

  /// Disposes resources.
  Future<void> dispose() async {
    NavigationLogger.debug(_logTag, 'Disposing offline package manager');

    // Close all download streams
    for (final controller in _downloadStreams.values) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    _downloadStreams.clear();

    // Dispose services
    _routingService.dispose();
    _geocodingService.dispose();

    _cachedPackages.clear();
    _initialized = false;
  }
}

/// Result of downloading a content type.
class _ContentDownloadResult {
  final String filePath;
  final int sizeBytes;
  final String? version;
  final String? checksum;

  const _ContentDownloadResult({
    required this.filePath,
    required this.sizeBytes,
    this.version,
    this.checksum,
  });
}
