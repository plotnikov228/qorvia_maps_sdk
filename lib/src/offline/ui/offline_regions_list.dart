import 'package:flutter/material.dart';

import '../tiles/download_progress.dart';
import '../tiles/offline_region.dart';
import 'download_progress_widget.dart';

/// Widget that displays a list of offline regions.
///
/// Shows each region's name, status, size, and provides
/// actions for downloading, pausing, resuming, and deleting.
///
/// ## Example
///
/// ```dart
/// OfflineRegionsList(
///   regions: regions,
///   activeDownloads: activeDownloads,
///   onDownload: (region) => manager.downloadRegion(region.id),
///   onDelete: (region) => manager.deleteRegion(region.id),
///   onTap: (region) => showRegionDetails(region),
/// )
/// ```
class OfflineRegionsList extends StatelessWidget {
  /// List of offline regions to display.
  final List<OfflineRegion> regions;

  /// Map of active download progress by region ID.
  final Map<String, DownloadProgress> activeDownloads;

  /// Called when download button is pressed.
  final void Function(OfflineRegion region)? onDownload;

  /// Called when pause button is pressed.
  final void Function(OfflineRegion region)? onPause;

  /// Called when resume button is pressed.
  final void Function(OfflineRegion region)? onResume;

  /// Called when delete button is pressed.
  final void Function(OfflineRegion region)? onDelete;

  /// Called when a region item is tapped.
  final void Function(OfflineRegion region)? onTap;

  /// Widget to show when list is empty.
  final Widget? emptyWidget;

  /// Whether to show the delete confirmation dialog.
  final bool confirmDelete;

  const OfflineRegionsList({
    super.key,
    required this.regions,
    this.activeDownloads = const {},
    this.onDownload,
    this.onPause,
    this.onResume,
    this.onDelete,
    this.onTap,
    this.emptyWidget,
    this.confirmDelete = true,
  });

  @override
  Widget build(BuildContext context) {
    if (regions.isEmpty) {
      return emptyWidget ?? const _EmptyRegionsWidget();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: regions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final region = regions[index];
        final activeProgress = activeDownloads[region.id];

        return OfflineRegionCard(
          region: region,
          activeProgress: activeProgress,
          onDownload: onDownload != null ? () => onDownload!(region) : null,
          onPause: onPause != null ? () => onPause!(region) : null,
          onResume: onResume != null ? () => onResume!(region) : null,
          onDelete: onDelete != null
              ? () => _handleDelete(context, region)
              : null,
          onTap: onTap != null ? () => onTap!(region) : null,
        );
      },
    );
  }

  Future<void> _handleDelete(BuildContext context, OfflineRegion region) async {
    if (!confirmDelete) {
      onDelete?.call(region);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Region'),
        content: Text(
          'Are you sure you want to delete "${region.name}"? '
          'This will remove all downloaded tiles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onDelete?.call(region);
    }
  }
}

/// Card widget for a single offline region.
class OfflineRegionCard extends StatelessWidget {
  final OfflineRegion region;
  final DownloadProgress? activeProgress;
  final VoidCallback? onDownload;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const OfflineRegionCard({
    super.key,
    required this.region,
    this.activeProgress,
    this.onDownload,
    this.onPause,
    this.onResume,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status icon
                  _StatusIcon(status: region.status),
                  const SizedBox(width: 12),
                  // Name and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          region.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getStatusText(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(theme),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action button
                  _buildActionButton(context),
                ],
              ),

              // Progress bar for downloading/active
              if (activeProgress != null || region.isDownloading) ...[
                const SizedBox(height: 12),
                CompactDownloadProgress(
                  progress: activeProgress ??
                      DownloadProgress(
                        regionId: region.id,
                        completedTiles: region.downloadedTiles,
                        totalTiles: region.totalTiles,
                        downloadedBytes: region.sizeBytes,
                      ),
                ),
              ],

              // Info row for completed regions
              if (region.isComplete) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.zoom_in,
                      label: 'Zoom ${region.minZoom.toInt()}-${region.maxZoom.toInt()}',
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.storage,
                      label: region.sizeFormatted,
                    ),
                    const Spacer(),
                    // Delete button
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        color: theme.colorScheme.error,
                        iconSize: 20,
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],

              // Error message
              if (region.status == OfflineRegionStatus.failed &&
                  region.errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          region.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final theme = Theme.of(context);

    switch (region.status) {
      case OfflineRegionStatus.pending:
        return IconButton(
          onPressed: onDownload,
          icon: const Icon(Icons.download),
          color: theme.colorScheme.primary,
          tooltip: 'Download',
        );

      case OfflineRegionStatus.downloading:
        return IconButton(
          onPressed: onPause,
          icon: const Icon(Icons.pause),
          color: theme.colorScheme.primary,
          tooltip: 'Pause',
        );

      case OfflineRegionStatus.paused:
        return IconButton(
          onPressed: onResume,
          icon: const Icon(Icons.play_arrow),
          color: theme.colorScheme.primary,
          tooltip: 'Resume',
        );

      case OfflineRegionStatus.completed:
        return Icon(
          Icons.check_circle,
          color: theme.colorScheme.primary,
        );

      case OfflineRegionStatus.failed:
        return IconButton(
          onPressed: onDownload,
          icon: const Icon(Icons.refresh),
          color: theme.colorScheme.error,
          tooltip: 'Retry',
        );
    }
  }

  String _getStatusText() {
    switch (region.status) {
      case OfflineRegionStatus.pending:
        return 'Ready to download';
      case OfflineRegionStatus.downloading:
        return 'Downloading... ${region.progressPercentage}';
      case OfflineRegionStatus.paused:
        return 'Paused at ${region.progressPercentage}';
      case OfflineRegionStatus.completed:
        return 'Downloaded';
      case OfflineRegionStatus.failed:
        return 'Failed';
    }
  }

  Color _getStatusColor(ThemeData theme) {
    switch (region.status) {
      case OfflineRegionStatus.pending:
        return theme.colorScheme.onSurfaceVariant;
      case OfflineRegionStatus.downloading:
        return theme.colorScheme.primary;
      case OfflineRegionStatus.paused:
        return theme.colorScheme.tertiary;
      case OfflineRegionStatus.completed:
        return theme.colorScheme.primary;
      case OfflineRegionStatus.failed:
        return theme.colorScheme.error;
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final OfflineRegionStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    Color backgroundColor;

    switch (status) {
      case OfflineRegionStatus.pending:
        icon = Icons.cloud_download_outlined;
        color = theme.colorScheme.onSurfaceVariant;
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
      case OfflineRegionStatus.downloading:
        icon = Icons.downloading;
        color = theme.colorScheme.primary;
        backgroundColor = theme.colorScheme.primaryContainer;
      case OfflineRegionStatus.paused:
        icon = Icons.pause_circle_outline;
        color = theme.colorScheme.tertiary;
        backgroundColor = theme.colorScheme.tertiaryContainer;
      case OfflineRegionStatus.completed:
        icon = Icons.offline_pin;
        color = theme.colorScheme.primary;
        backgroundColor = theme.colorScheme.primaryContainer;
      case OfflineRegionStatus.failed:
        icon = Icons.error_outline;
        color = theme.colorScheme.error;
        backgroundColor = theme.colorScheme.errorContainer;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRegionsWidget extends StatelessWidget {
  const _EmptyRegionsWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No offline regions',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download map regions for offline use',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
