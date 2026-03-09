import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

import '../../app/theme/app_colors.dart';

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
  List<OfflineRegion> _regions = [];
  List<TileRegion> _serverRegions = [];
  final Map<String, DownloadProgress> _activeDownloads = {};
  final Map<String, StreamSubscription<DownloadProgress>> _downloadSubs = {};
  bool _isLoading = true;
  bool _isLoadingServerRegions = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initManager();
  }

  Future<void> _initManager() async {
    _log('Initializing offline tile manager');
    try {
      _tileManager = QorviaMapsSDK.offlineManager;

      if (_tileManager == null) {
        setState(() {
          _error = 'Офлайн-менеджер недоступен.\n'
              'Убедитесь, что SDK инициализирован с offlineConfig.';
          _isLoading = false;
        });
        return;
      }

      if (!_tileManager!.isInitialized) {
        await _tileManager!.initialize();
      }

      await _loadRegions();
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
    _log('Downloading server preset via native MapLibre', {
      'id': serverRegion.id,
      'name': serverRegion.name,
      'sizeMb': serverRegion.sizeMb,
    });

    try {
      final styleUrl = await QorviaMapsSDK.instance.getTileUrl();
      _log('Got style URL', {'styleUrl': styleUrl});

      // Use native MapLibre download instead of server mbtiles
      await _downloadNative(
        bounds: serverRegion.bounds,
        minZoom: serverRegion.minZoom,
        maxZoom: serverRegion.maxZoom,
        regionName: serverRegion.name,
        styleUrl: styleUrl,
      );
    } catch (e) {
      _log('Error downloading server region', {'error': e.toString()});
      _showSnackBar('Ошибка скачивания региона: $e');
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

    _showSnackBar('Скачивание региона "$regionName"...');

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
        _showSnackBar('Регион "$regionName" скачан');
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка скачивания'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Не удалось скачать регион:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(fontSize: 12),
              ),
              if (isDatabaseError) ...[
                const SizedBox(height: 16),
                const Text(
                  'Похоже, база данных MapLibre повреждена. '
                  'Попробуйте сбросить её и перезапустить приложение.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (isDatabaseError)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _resetDatabase();
              },
              child: const Text('Сбросить базу'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
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

    if (deleted) {
      _showSnackBar('База данных удалена. Перезапустите приложение.');
    } else {
      // Also try the SDK method as fallback
      final sdkDeleted = await _tileManager?.resetNativeDatabase() ?? false;
      if (sdkDeleted) {
        _showSnackBar('База данных сброшена. Перезапустите приложение.');
      } else {
        _showSnackBar('База данных не найдена');
      }
    }
  }

  void _showResetDatabaseConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить базу данных?'),
        content: const Text(
          'Это удалит все скачанные офлайн карты MapLibre.\n\n'
          'Используйте эту опцию если скачивание не работает '
          'из-за ошибки "no such table: regions".\n\n'
          'После сброса нужно перезапустить приложение.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetDatabase();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Сбросить'),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статус базы данных'),
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
                    exists ? 'База данных существует' : 'База данных не найдена',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Путь: ${dbPath ?? "неизвестно"}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Если скачивание не работает с ошибкой "no such table", '
              'попробуйте удалить базу и перезапустить приложение.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          if (exists)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _resetDatabase();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Удалить базу'),
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
    } catch (e) {
      _log('Error creating region', {'error': e.toString()});
      _showSnackBar('Ошибка создания региона: $e');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Офлайн карты'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRegions,
            tooltip: 'Обновить',
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
              const PopupMenuItem(
                value: 'check',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Проверить базу'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Сбросить базу', style: TextStyle(color: Colors.red)),
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
              label: const Text('Добавить регион'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initManager,
                child: const Text('Повторить'),
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
                'Сохранённые карты',
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
            'Нет сохраненных карт',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Скачайте карты для использования\nбез интернета',
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
            label: const Text('Добавить регион'),
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
                'Доступные регионы',
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
              'Нет доступных регионов',
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
              Text(
                '${region.tilesCount} тайлов',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Download button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Скачать'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
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
              'Расчёт размера...',
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
                  'Предварительная оценка',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_estimate!.sizeFormatted} • ${_estimate!.tilesCount} тайлов',
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
                  'Новый регион',
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
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Например: Москва центр',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Уровень масштабирования: ${_minZoom.toInt()} - ${_maxZoom.toInt()}',
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
              'Чем выше масштаб, тем больше размер загрузки',
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
                    child: const Text('Отмена'),
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
                        : const Text('Создать'),
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

          // Top bar with estimate info
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 16,
            right: 16,
            child: _buildEstimateBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateBar() {
    if (_selectedBounds == null && !_isEstimating && _estimate == null) {
      return const SizedBox.shrink();
    }

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
              'Расчёт размера...',
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
              '${_estimate!.tilesCount} тайлов',
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
                  'Область выбрана',
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
              decoration: const InputDecoration(
                labelText: 'Название региона',
                hintText: 'Например: Москва центр',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Zoom slider
            Text(
              'Уровень масштабирования: ${_minZoom.toInt()} - ${_maxZoom.toInt()}',
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
                      'Пересчёт...',
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
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCreating ? null : _onCreate,
                    icon: _isCreating
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: const Text('Скачать'),
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
