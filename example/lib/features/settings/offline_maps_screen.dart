import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

import '../../app/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';

/// Screen for managing offline map regions.
///
/// Displays a list of downloaded regions with options to:
/// - Download new regions
/// - Pause/resume downloads
/// - Delete existing regions
class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  OfflineTileManager? _tileManager;
  OfflinePackageManager? _packageManager;
  List<OfflineRegion> _regions = [];
  List<TileRegion> _serverRegions = [];
  List<OfflinePackage> _packages = [];
  final Map<String, DownloadProgress> _activeDownloads = {};
  final Map<String, StreamSubscription<DownloadProgress>> _downloadSubs = {};
  final Map<String, StreamSubscription<PackageDownloadEvent>> _packageDownloadSubs = {};
  bool _isLoading = true;
  bool _isLoadingServerRegions = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initManager();
  }

  Future<void> _initManager() async {
    _log('Initializing offline managers');
    try {
      _tileManager = QorviaMapsSDK.offlineManager;
      _packageManager = QorviaMapsSDK.packageManager;

      if (_tileManager == null) {
        setState(() {
          _error = 'offlineManagerUnavailable';
          _isLoading = false;
        });
        return;
      }

      if (!_tileManager!.isInitialized) {
        await _tileManager!.initialize();
      }

      await _loadRegions();
      await _loadPackages();
      // Load server regions in parallel (non-blocking)
      _loadServerRegions();
    } catch (e) {
      _log('Error initializing', {'error': e.toString()});
      setState(() {
        _error = 'Ошибка инициализации: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPackages() async {
    if (_packageManager == null) {
      _log('Package manager not available');
      return;
    }

    _log('Loading offline packages');
    try {
      final packages = await _packageManager!.getAllPackages();
      setState(() {
        _packages = packages;
      });
      _log('Loaded packages', {'count': packages.length});
    } catch (e) {
      _log('Error loading packages', {'error': e.toString()});
    }
  }

  Future<void> _loadRegions() async {
    _log('Loading regions');
    try {
      final regions = await _tileManager?.getAllRegions() ?? [];
      setState(() {
        _regions = regions;
        _isLoading = false;
        _error = null;
      });
      _log('Loaded regions', {'count': regions.length});
    } catch (e) {
      _log('Error loading regions', {'error': e.toString()});
      setState(() {
        _error = 'Ошибка загрузки регионов: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadServerRegions() async {
    _log('Loading server regions');
    if (_tileManager == null) {
      _log('Cannot load server regions - manager is null');
      return;
    }

    setState(() {
      _isLoadingServerRegions = true;
    });

    try {
      final serverRegions = await _tileManager!.getServerRegions();
      _log('Loaded server regions', {'count': serverRegions.length});

      if (mounted) {
        setState(() {
          _serverRegions = serverRegions;
          _isLoadingServerRegions = false;
        });
      }
    } catch (e) {
      _log('Error loading server regions', {'error': e.toString()});
      if (mounted) {
        setState(() {
          _isLoadingServerRegions = false;
        });
      }
      // Non-critical error, don't show to user
    }
  }

  void _onDownload(OfflineRegion region) {
    _log('Starting download', {'regionId': region.id, 'name': region.name});

    final stream = _tileManager?.downloadRegion(region.id);
    if (stream == null) return;

    _downloadSubs[region.id] = stream.listen(
      (progress) {
        setState(() {
          _activeDownloads[region.id] = progress;
        });
      },
      onDone: () {
        _log('Download completed', {'regionId': region.id});
        _activeDownloads.remove(region.id);
        _downloadSubs.remove(region.id);
        _loadRegions();
      },
      onError: (e) {
        _log('Download error', {'regionId': region.id, 'error': e.toString()});
        _activeDownloads.remove(region.id);
        _downloadSubs.remove(region.id);
        _loadRegions();
      },
    );
  }

  void _onPause(OfflineRegion region) async {
    _log('Pausing download', {'regionId': region.id});
    await _tileManager?.pauseDownload(region.id);
    _activeDownloads.remove(region.id);
    await _downloadSubs[region.id]?.cancel();
    _downloadSubs.remove(region.id);
    await _loadRegions();
  }

  void _onResume(OfflineRegion region) {
    _log('Resuming download', {'regionId': region.id});
    final stream = _tileManager?.resumeDownload(region.id);
    if (stream == null) return;

    _downloadSubs[region.id] = stream.listen(
      (progress) {
        setState(() {
          _activeDownloads[region.id] = progress;
        });
      },
      onDone: () {
        _activeDownloads.remove(region.id);
        _downloadSubs.remove(region.id);
        _loadRegions();
      },
      onError: (e) {
        _activeDownloads.remove(region.id);
        _downloadSubs.remove(region.id);
        _loadRegions();
      },
    );
  }

  void _onDelete(OfflineRegion region) async {
    _log('Deleting region', {'regionId': region.id, 'name': region.name});
    await _tileManager?.deleteRegion(region.id);
    await _loadRegions();
  }

  Future<void> _onDownloadServerRegion(TileRegion serverRegion) async {
    _log('Downloading server preset', {
      'id': serverRegion.id,
      'name': serverRegion.name,
      'sizeMb': serverRegion.sizeMb,
    });

    final styleUrl = await QorviaMapsSDK.instance.getTileUrl();
    _log('Got style URL', {'styleUrl': styleUrl});

    // Download tiles via native MapLibre
    try {
      await _downloadNative(
        bounds: serverRegion.bounds,
        minZoom: serverRegion.minZoom,
        maxZoom: serverRegion.maxZoom,
        regionName: serverRegion.name,
        styleUrl: styleUrl,
      );
    } catch (e) {
      _log('Native tile download failed', {'error': e.toString()});
      _showSnackBar('Tile download failed: $e');
    }

    // Note: Offline routing/geocoding data is not yet available.
    // Routing and geocoding will work online only.
  }

  /// Downloads a full offline package including routing and geocoding data.
  Future<void> _downloadFullPackage({
    required String name,
    required OfflineBounds bounds,
    required int minZoom,
    required int maxZoom,
  }) async {
    if (_packageManager == null) {
      _log('Package manager not available, skipping full package download');
      return;
    }

    _log('Creating full offline package', {
      'name': name,
      'bounds': '${bounds.southwest.lat},${bounds.southwest.lon} - ${bounds.northeast.lat},${bounds.northeast.lon}',
    });

    try {
      // Create package with all content types
      final package = await _packageManager!.createPackage(
        CreatePackageParams(
          name: name,
          bounds: bounds,
          minZoom: minZoom.toDouble(),
          maxZoom: maxZoom.toDouble(),
          contentTypes: {
            PackageContentType.routing,
            PackageContentType.geocoding,
          },
        ),
      );

      _log('Package created, starting download', {'packageId': package.id});
      _showSnackBar('Downloading routing data for "$name"...');

      // Start download
      final subscription = _packageManager!.downloadPackage(package.id).listen(
        (event) {
          _log('Package download event', {
            'type': event.type.name,
            'progress': event.progress.overallPercent.toStringAsFixed(1),
            'currentlyDownloading': event.progress.currentlyDownloading?.name,
          });

          // Show error details if any content failed
          for (final content in event.progress.contentProgress.values) {
            if (content.hasFailed) {
              _log('Content failed', {
                'type': content.type.name,
                'error': content.errorMessage,
              });
              // Show user-friendly error
              _showSnackBar('${content.type.name} download failed: ${content.errorMessage}');
            }
          }
        },
        onDone: () async {
          _log('Package download completed');

          // Check what was actually downloaded
          final updatedPackage = await _packageManager!.getPackage(package.id);
          if (updatedPackage != null) {
            final hasRouting = updatedPackage.hasRoutingReady;
            final hasGeocoding = updatedPackage.hasGeocodingReady;

            _log('Package final status', {
              'hasRouting': hasRouting,
              'hasGeocoding': hasGeocoding,
              'status': updatedPackage.status.name,
            });

            if (hasRouting && hasGeocoding) {
              _showSnackBar('Offline data fully downloaded for "$name"');
            } else if (hasRouting || hasGeocoding) {
              final missing = <String>[];
              if (!hasRouting) missing.add('routing');
              if (!hasGeocoding) missing.add('geocoding');
              _showSnackBar('Partial download for "$name". Missing: ${missing.join(', ')}');
            } else {
              _showSnackBar('No offline routing/geocoding data available for "$name". Server may not support this region.');
            }
          } else {
            _showSnackBar('Routing data downloaded for "$name"');
          }

          _loadPackages();
        },
        onError: (e, stack) {
          _log('Package download error', {'error': e.toString(), 'stack': stack.toString()});
          _showSnackBar('Routing download failed: $e');
          _loadPackages();
        },
      );

      _packageDownloadSubs[package.id] = subscription;
    } catch (e, stack) {
      _log('Error creating package', {'error': e.toString(), 'stack': stack.toString()});
      _showSnackBar('Failed to create offline package: $e');
    }
  }

  /// Downloads a region using native MapLibre offline functionality.
  /// This properly caches tiles for offline use.
  Future<void> _downloadNative({
    required OfflineBounds bounds,
    required int minZoom,
    required int maxZoom,
    required String regionName,
    required String styleUrl,
  }) async {
    _log('Starting native MapLibre download', {
      'name': regionName,
      'bounds': bounds.toString(),
      'zoom': '$minZoom-$maxZoom',
    });

    _showSnackBar('${AppLocalizations.of(context).downloadingRegion} "$regionName"...');

    try {
      final nativeRegion = await _tileManager?.downloadRegionNative(
        styleUrl: styleUrl,
        bounds: bounds,
        minZoom: minZoom,
        maxZoom: maxZoom,
        regionName: regionName,
        onProgress: (progress) {
          _log('Native download progress', {'progress': progress});
          // Could show progress in UI if needed
        },
      );

      if (nativeRegion != null) {
        _log('Native download completed', {'id': nativeRegion.id});
        _showSnackBar('${AppLocalizations.of(context).regionDownloaded}: "$regionName"');
        await _loadRegions();
      }
    } catch (e) {
      _log('Native download error', {'error': e.toString()});
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String error) {
    final isDatabaseError = error.contains('no such table') ||
        error.contains('database') ||
        error.contains('Database');
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.downloadErrorTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.failedToDownloadRegion,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(fontSize: 12),
              ),
              if (isDatabaseError) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.databaseCorrupted,
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (isDatabaseError)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _resetDatabase();
              },
              child: Text(l10n.resetDatabaseButton),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _resetDatabase() async {
    _log('Resetting MapLibre database (native)');

    // Use native Android method to delete the database
    final deleted = await MapLibreNativeHelper.deleteOfflineDatabase();
    _log('Native database delete result', {'deleted': deleted});

    final l10n = AppLocalizations.of(context);
    if (deleted) {
      _showSnackBar(l10n.databaseDeleted);
    } else {
      // Also try the SDK method as fallback
      final sdkDeleted = await _tileManager?.resetNativeDatabase() ?? false;
      if (sdkDeleted) {
        _showSnackBar(l10n.databaseReset);
      } else {
        _showSnackBar(l10n.databaseNotFound);
      }
    }
  }

  void _showResetDatabaseConfirmation() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetDatabaseConfirmTitle),
        content: Text(l10n.resetDatabaseConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _resetDatabase();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.resetDatabase),
          ),
        ],
      ),
    );
  }

  Future<void> _checkDatabaseStatus() async {
    _log('Checking database status (native)');

    final exists = await MapLibreNativeHelper.checkDatabaseExists();
    final dbPath = await MapLibreNativeHelper.getDatabasePath();

    _log('Database status', {'exists': exists, 'path': dbPath});

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.databaseStatusTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  exists ? Icons.check_circle : Icons.error,
                  color: exists ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exists ? l10n.databaseExists : l10n.databaseNotFoundStatus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.path}: ${dbPath ?? l10n.unknown}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.downloadNotWorkingHint,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.close),
          ),
          if (exists)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _resetDatabase();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.deleteDatabase),
            ),
        ],
      ),
    );
  }

  void _showCreateRegionDialog() {
    _log('Opening region selection screen');
    Navigator.push<OfflineBounds>(
      context,
      MaterialPageRoute(
        builder: (context) => _RegionSelectionScreen(
          tileManager: _tileManager!,
          onCreateRegion: _createRegion,
        ),
      ),
    );
  }

  Future<void> _createRegion(CreateOfflineRegionParams params) async {
    _log('Creating region via native MapLibre', {'name': params.name});

    try {
      final styleUrl = await QorviaMapsSDK.instance.getTileUrl();

      // Use native MapLibre download
      await _downloadNative(
        bounds: params.bounds,
        minZoom: params.minZoom.toInt(),
        maxZoom: params.maxZoom.toInt(),
        regionName: params.name,
        styleUrl: styleUrl,
      );

      // Also download full package with routing/geocoding
      await _downloadFullPackage(
        name: params.name,
        bounds: params.bounds,
        minZoom: params.minZoom.toInt(),
        maxZoom: params.maxZoom.toInt(),
      );
    } catch (e) {
      _log('Error creating region', {'error': e.toString()});
      _showSnackBar('${AppLocalizations.of(context).regionCreationError}: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[OfflineMapsScreen] $message$dataStr');
  }

  @override
  void dispose() {
    for (final sub in _downloadSubs.values) {
      sub.cancel();
    }
    _downloadSubs.clear();
    for (final sub in _packageDownloadSubs.values) {
      sub.cancel();
    }
    _packageDownloadSubs.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.offlineMapsTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRegions,
            tooltip: l10n.refresh,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                _showResetDatabaseConfirmation();
              } else if (value == 'check') {
                _checkDatabaseStatus();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'check',
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.checkDatabase),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(l10n.resetDatabase, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _tileManager != null
          ? FloatingActionButton.extended(
              onPressed: _showCreateRegionDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(l10n.addRegion),
            )
          : null,
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      // Resolve error key to localized string
      String errorText;
      if (_error == 'offlineManagerUnavailable') {
        errorText = l10n.offlineManagerUnavailable;
      } else if (_error!.startsWith('Ошибка инициализации') || _error!.contains('initialization')) {
        errorText = '${l10n.initializationError}: ${_error!.replaceFirst(RegExp(r'^.*?:\s*'), '')}';
      } else if (_error!.startsWith('Ошибка загрузки') || _error!.contains('loading')) {
        errorText = '${l10n.loadingRegionsError}: ${_error!.replaceFirst(RegExp(r'^.*?:\s*'), '')}';
      } else {
        errorText = _error!;
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                errorText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initManager,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    // Build combined content with server regions section
    return CustomScrollView(
      slivers: [
        // Server regions section
        if (_serverRegions.isNotEmpty || _isLoadingServerRegions)
          SliverToBoxAdapter(
            child: _ServerRegionsSection(
              regions: _serverRegions,
              isLoading: _isLoadingServerRegions,
              onDownload: _onDownloadServerRegion,
            ),
          ),

        // Saved regions section header
        if (_regions.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l10n.savedMaps,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),

        // Saved regions list
        if (_regions.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final region = _regions[index];
                  final activeProgress = _activeDownloads[region.id];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OfflineRegionCard(
                      region: region,
                      activeProgress: activeProgress,
                      onDownload:
                          region.canDownload ? () => _onDownload(region) : null,
                      onPause: region.isDownloading
                          ? () => _onPause(region)
                          : null,
                      onResume: region.status == OfflineRegionStatus.paused
                          ? () => _onResume(region)
                          : null,
                      onDelete: () => _onDelete(region),
                    ),
                  );
                },
                childCount: _regions.length,
              ),
            ),
          ),

        // Empty state
        if (_regions.isEmpty && _serverRegions.isEmpty && !_isLoadingServerRegions)
          SliverFillRemaining(
            child: _buildEmptyState(),
          ),

        // Bottom padding for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 80,
            color: AppColors.outline,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noSavedMaps,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.downloadMapsDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showCreateRegionDialog,
            icon: const Icon(Icons.add),
            label: Text(l10n.addRegion),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section displaying available server regions for download.
class _ServerRegionsSection extends StatelessWidget {
  final List<TileRegion> regions;
  final bool isLoading;
  final void Function(TileRegion region) onDownload;

  const _ServerRegionsSection({
    required this.regions,
    required this.isLoading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.cloud_download_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.availableRegions,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              if (isLoading) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (regions.isEmpty && !isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.noAvailableRegions,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: regions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final region = regions[index];
                return _ServerRegionCard(
                  region: region,
                  onDownload: () => onDownload(region),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        const Divider(height: 1),
      ],
    );
  }
}

/// Card for a single server region.
class _ServerRegionCard extends StatelessWidget {
  final TileRegion region;
  final VoidCallback onDownload;

  const _ServerRegionCard({
    required this.region,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Region name
          Text(
            region.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Description if available
          if (region.description != null)
            Text(
              region.description!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const Spacer(),
          // Size and tiles info
          Row(
            children: [
              Icon(
                Icons.storage,
                size: 14,
                color: AppColors.outline,
              ),
              const SizedBox(width: 4),
              Text(
                region.sizeFormatted,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(
                    '${region.tilesCount} ${l10n.tiles}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.outline,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Download button
          SizedBox(
            width: double.infinity,
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download, size: 16),
                  label: Text(l10n.download),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for creating a new offline region.
class _CreateRegionSheet extends StatefulWidget {
  final Future<void> Function(CreateOfflineRegionParams params) onCreateRegion;
  final OfflineTileManager? tileManager;

  const _CreateRegionSheet({
    required this.onCreateRegion,
    required this.tileManager,
  });

  @override
  State<_CreateRegionSheet> createState() => _CreateRegionSheetState();
}

class _CreateRegionSheetState extends State<_CreateRegionSheet> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Default to Moscow region
  double _swLat = 55.55;
  double _swLon = 37.35;
  double _neLat = 55.95;
  double _neLon = 37.85;
  double _minZoom = 10;
  double _maxZoom = 16;

  bool _isCreating = false;
  bool _isEstimating = false;
  TileEstimateResponse? _estimate;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Initial estimate
    _scheduleEstimate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _scheduleEstimate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _estimateRegion);
  }

  Future<void> _estimateRegion() async {
    if (widget.tileManager == null) return;

    developer.log('[_CreateRegionSheet._estimateRegion] Estimating',
        name: 'OfflineMaps');

    setState(() {
      _isEstimating = true;
    });

    try {
      final params = CreateOfflineRegionParams(
        name: 'estimate',
        bounds: OfflineBounds.fromCoordinates(
          swLat: _swLat,
          swLon: _swLon,
          neLat: _neLat,
          neLon: _neLon,
        ),
        minZoom: _minZoom,
        maxZoom: _maxZoom,
      );

      final estimate = await widget.tileManager!.estimateRegion(params);

      developer.log(
        '[_CreateRegionSheet._estimateRegion] Estimate result',
        name: 'OfflineMaps',
        error: {'sizeMb': estimate.sizeMb, 'tilesCount': estimate.tilesCount},
      );

      if (mounted) {
        setState(() {
          _estimate = estimate;
          _isEstimating = false;
        });
      }
    } catch (e) {
      developer.log(
        '[_CreateRegionSheet._estimateRegion] Error',
        name: 'OfflineMaps',
        error: e.toString(),
      );

      if (mounted) {
        setState(() {
          _isEstimating = false;
        });
      }
    }
  }

  Future<void> _onCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final params = CreateOfflineRegionParams(
        name: _nameController.text.trim(),
        bounds: OfflineBounds.fromCoordinates(
          swLat: _swLat,
          swLon: _swLon,
          neLat: _neLat,
          neLon: _neLon,
        ),
        minZoom: _minZoom,
        maxZoom: _maxZoom,
      );

      await widget.onCreateRegion(params);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Widget _buildEstimateInfo() {
    final l10n = AppLocalizations.of(context);
    if (_isEstimating) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.calculatingSize,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_estimate == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.preliminaryEstimate,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_estimate!.sizeFormatted} • ${_estimate!.tilesCount} ${l10n.tiles}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.map, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  l10n.newRegion,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.regionName,
                hintText: l10n.regionNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.enterName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n.zoomLevel}: ${_minZoom.toInt()} - ${_maxZoom.toInt()}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            RangeSlider(
              values: RangeValues(_minZoom, _maxZoom),
              min: 0,
              max: 20,
              divisions: 20,
              labels: RangeLabels(
                _minZoom.toInt().toString(),
                _maxZoom.toInt().toString(),
              ),
              onChanged: (values) {
                setState(() {
                  _minZoom = values.start;
                  _maxZoom = values.end;
                });
                _scheduleEstimate();
              },
            ),
            const SizedBox(height: 8),
            Text(
              l10n.higherZoomLargerSize,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 16),
            // Estimate info
            _buildEstimateInfo(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCreating ? null : () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _onCreate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.create),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen region selection with interactive map.
class _RegionSelectionScreen extends StatefulWidget {
  final OfflineTileManager tileManager;
  final Future<void> Function(CreateOfflineRegionParams params) onCreateRegion;

  const _RegionSelectionScreen({
    required this.tileManager,
    required this.onCreateRegion,
  });

  @override
  State<_RegionSelectionScreen> createState() => _RegionSelectionScreenState();
}

class _RegionSelectionScreenState extends State<_RegionSelectionScreen> {
  QorviaMapController? _mapController;
  OfflineBounds? _selectedBounds;
  TileEstimateResponse? _estimate;
  bool _isEstimating = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[_RegionSelectionScreen] $message$dataStr');
  }

  void _onBoundsChanged(OfflineBounds bounds) {
    _log('Bounds changed', {
      'sw': '${bounds.southwest.lat.toStringAsFixed(4)}, ${bounds.southwest.lon.toStringAsFixed(4)}',
      'ne': '${bounds.northeast.lat.toStringAsFixed(4)}, ${bounds.northeast.lon.toStringAsFixed(4)}',
    });

    setState(() {
      _selectedBounds = bounds;
    });

    _scheduleEstimate();
  }

  void _scheduleEstimate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _estimateRegion);
  }

  Future<void> _estimateRegion() async {
    if (_selectedBounds == null) return;

    _log('Estimating region');

    setState(() {
      _isEstimating = true;
    });

    try {
      final params = CreateOfflineRegionParams(
        name: 'estimate',
        bounds: _selectedBounds!,
        minZoom: 10,
        maxZoom: 16,
      );

      final estimate = await widget.tileManager.estimateRegion(params);

      _log('Estimate result', {
        'sizeMb': estimate.sizeMb,
        'tilesCount': estimate.tilesCount,
      });

      if (mounted) {
        setState(() {
          _estimate = estimate;
          _isEstimating = false;
        });
      }
    } catch (e) {
      _log('Estimate error', {'error': e.toString()});
      if (mounted) {
        setState(() {
          _isEstimating = false;
        });
      }
    }
  }

  void _onConfirm(OfflineBounds bounds) {
    _log('Region confirmed', {
      'sw': '${bounds.southwest.lat}, ${bounds.southwest.lon}',
      'ne': '${bounds.northeast.lat}, ${bounds.northeast.lon}',
    });

    _showConfigSheet(bounds);
  }

  void _showConfigSheet(OfflineBounds bounds) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RegionConfigSheet(
        bounds: bounds,
        estimate: _estimate,
        tileManager: widget.tileManager,
        onCreateRegion: (params) async {
          Navigator.pop(context); // Close sheet
          await widget.onCreateRegion(params);
          if (mounted) {
            Navigator.pop(this.context); // Close selection screen
          }
        },
      ),
    );
  }

  Future<Coordinates?> _screenToCoordinates(Offset screenPosition) async {
    if (_mapController == null) return null;

    try {
      return await _mapController!.toCoordinates(screenPosition);
    } catch (e) {
      _log('Screen to coords error', {'error': e.toString()});
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          QorviaMapView(
            options: MapOptions(
              initialCenter: const Coordinates(lat: 55.7539, lon: 37.6208),
              initialZoom: 10,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _log('Map created');
            },
          ),

          // Region selection overlay
          RegionSelectionOverlay(
            onBoundsChanged: _onBoundsChanged,
            onConfirm: _onConfirm,
            onCancel: () => Navigator.pop(context),
            screenToCoordinates: _screenToCoordinates,
            showButtons: true,
            showHandles: true,
          ),

          // Top bar with estimate info (IgnorePointer allows map gestures)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: _buildEstimateBar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateBar() {
    if (_selectedBounds == null && !_isEstimating && _estimate == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_isEstimating) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.calculatingSize,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ] else if (_estimate != null) ...[
            Icon(
              Icons.storage,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _estimate!.sizeFormatted,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.grid_view,
              size: 18,
              color: AppColors.outline,
            ),
            const SizedBox(width: 4),
            Text(
              '${_estimate!.tilesCount} ${l10n.tiles}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Config sheet after region selection.
class _RegionConfigSheet extends StatefulWidget {
  final OfflineBounds bounds;
  final TileEstimateResponse? estimate;
  final OfflineTileManager tileManager;
  final Future<void> Function(CreateOfflineRegionParams params) onCreateRegion;

  const _RegionConfigSheet({
    required this.bounds,
    this.estimate,
    required this.tileManager,
    required this.onCreateRegion,
  });

  @override
  State<_RegionConfigSheet> createState() => _RegionConfigSheetState();
}

class _RegionConfigSheetState extends State<_RegionConfigSheet> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _minZoom = 10;
  double _maxZoom = 16;
  bool _isCreating = false;
  TileEstimateResponse? _estimate;
  bool _isEstimating = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _estimate = widget.estimate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _scheduleEstimate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _estimateRegion);
  }

  Future<void> _estimateRegion() async {
    setState(() {
      _isEstimating = true;
    });

    try {
      final params = CreateOfflineRegionParams(
        name: 'estimate',
        bounds: widget.bounds,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
      );

      final estimate = await widget.tileManager.estimateRegion(params);

      if (mounted) {
        setState(() {
          _estimate = estimate;
          _isEstimating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEstimating = false;
        });
      }
    }
  }

  Future<void> _onCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final params = CreateOfflineRegionParams(
        name: _nameController.text.trim(),
        bounds: widget.bounds,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
      );

      await widget.onCreateRegion(params);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 12),
                Text(
                  l10n.areaSelected,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bounds info
            BoundsInfoWidget(
              bounds: widget.bounds,
              estimatedTiles: _estimate?.tilesCount.toDouble(),
              estimatedSize: _estimate?.sizeFormatted,
            ),
            const SizedBox(height: 16),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.regionName,
                hintText: l10n.regionNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.enterName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Zoom slider
            Text(
              '${l10n.zoomLevel}: ${_minZoom.toInt()} - ${_maxZoom.toInt()}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            RangeSlider(
              values: RangeValues(_minZoom, _maxZoom),
              min: 0,
              max: 20,
              divisions: 20,
              labels: RangeLabels(
                _minZoom.toInt().toString(),
                _maxZoom.toInt().toString(),
              ),
              onChanged: (values) {
                setState(() {
                  _minZoom = values.start;
                  _maxZoom = values.end;
                });
                _scheduleEstimate();
              },
            ),

            // Updated estimate
            if (_isEstimating)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.recalculating,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCreating ? null : () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCreating ? null : _onCreate,
                    icon: _isCreating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(l10n.download),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

