import 'package:flutter/material.dart';

import '../package/models/offline_package.dart';
import '../package/models/package_content.dart';
import '../package/models/package_download_progress.dart';

/// Widget that displays detailed information about an offline package.
///
/// Shows package name, status, bounds, content types with their status,
/// size information, and provides action controls.
///
/// ## Example
///
/// ```dart
/// PackageDetailWidget(
///   package: offlinePackage,
///   onDownload: () => manager.downloadPackage(package.id),
///   onPause: () => manager.pauseDownload(package.id),
///   onResume: () => manager.resumeDownload(package.id),
///   onDelete: () => confirmAndDelete(package),
/// )
/// ```
class PackageDetailWidget extends StatelessWidget {
  /// The package to display.
  final OfflinePackage package;

  /// Current download progress (if downloading).
  final PackageDownloadProgress? progress;

  /// Called when download button is pressed.
  final VoidCallback? onDownload;

  /// Called when pause button is pressed.
  final VoidCallback? onPause;

  /// Called when resume button is pressed.
  final VoidCallback? onResume;

  /// Called when delete button is pressed.
  final VoidCallback? onDelete;

  /// Called when retry failed content button is pressed.
  final VoidCallback? onRetryFailed;

  /// Whether to show the map preview of the region bounds.
  final bool showMapPreview;

  /// Custom map preview widget builder.
  final Widget Function(OfflinePackage package)? mapPreviewBuilder;

  const PackageDetailWidget({
    super.key,
    required this.package,
    this.progress,
    this.onDownload,
    this.onPause,
    this.onResume,
    this.onDelete,
    this.onRetryFailed,
    this.showMapPreview = false,
    this.mapPreviewBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and status
          _buildHeader(context),

          const SizedBox(height: 24),

          // Map preview (if enabled)
          if (showMapPreview) ...[
            _buildMapPreview(context),
            const SizedBox(height: 24),
          ],

          // Download progress (if downloading)
          if (package.isDownloading && progress != null) ...[
            _buildDownloadProgress(context),
            const SizedBox(height: 24),
          ],

          // Content types section
          _buildContentSection(context),

          const SizedBox(height: 24),

          // Size and storage info
          _buildStorageInfo(context),

          const SizedBox(height: 24),

          // Region bounds info
          _buildBoundsInfo(context),

          const SizedBox(height: 24),

          // Metadata (created, updated)
          _buildMetadata(context),

          // Error message (if any)
          if (package.errorMessage != null) ...[
            const SizedBox(height: 24),
            _buildError(context),
          ],

          const SizedBox(height: 32),

          // Action buttons
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status icon
        _buildStatusIcon(context),
        const SizedBox(width: 16),
        // Name and status text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                package.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusChip(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = _getStatusIconAndColor(theme);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }

  (IconData, Color) _getStatusIconAndColor(ThemeData theme) {
    switch (package.status) {
      case PackageStatus.pending:
        return (Icons.cloud_download_outlined, theme.colorScheme.outline);
      case PackageStatus.downloading:
        return (Icons.downloading, theme.colorScheme.primary);
      case PackageStatus.paused:
        return (Icons.pause_circle_outline, theme.colorScheme.tertiary);
      case PackageStatus.completed:
        return (Icons.check_circle, Colors.green);
      case PackageStatus.partiallyComplete:
        return (Icons.warning_amber, theme.colorScheme.tertiary);
      case PackageStatus.failed:
        return (Icons.error_outline, theme.colorScheme.error);
    }
  }

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = _getStatusLabelAndColor(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color) _getStatusLabelAndColor(ThemeData theme) {
    switch (package.status) {
      case PackageStatus.pending:
        return ('Ready to download', theme.colorScheme.outline);
      case PackageStatus.downloading:
        return ('Downloading ${package.progressPercentage}', theme.colorScheme.primary);
      case PackageStatus.paused:
        return ('Paused', theme.colorScheme.tertiary);
      case PackageStatus.completed:
        return ('Ready to use', Colors.green);
      case PackageStatus.partiallyComplete:
        return ('Partially downloaded', theme.colorScheme.tertiary);
      case PackageStatus.failed:
        return ('Download failed', theme.colorScheme.error);
    }
  }

  Widget _buildMapPreview(BuildContext context) {
    if (mapPreviewBuilder != null) {
      return mapPreviewBuilder!(package);
    }

    final theme = Theme.of(context);

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'Map preview',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadProgress(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.downloading,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Downloading...',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${progress!.overallPercent}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress!.overallProgress,
              backgroundColor: theme.colorScheme.surface,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress!.downloadedSizeFormatted,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                progress!.totalSizeFormatted,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (progress!.currentlyDownloading != null) ...[
            const SizedBox(height: 8),
            Text(
              'Currently: ${_getContentLabel(progress!.currentlyDownloading!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...package.contents.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ContentTypeCard(
              type: entry.key,
              content: entry.value,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStorageInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Storage',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StorageItem(
                label: 'Downloaded',
                value: package.downloadedSizeFormatted,
                icon: Icons.download_done,
              ),
              _StorageItem(
                label: 'Total',
                value: package.totalSizeFormatted,
                icon: Icons.folder,
              ),
              _StorageItem(
                label: 'Progress',
                value: package.progressPercentage,
                icon: Icons.pie_chart,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoundsInfo(BuildContext context) {
    final theme = Theme.of(context);
    final bounds = package.bounds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.crop_square,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Region bounds',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BoundsRow(
            label: 'Southwest',
            lat: bounds.southwest.lat,
            lon: bounds.southwest.lon,
          ),
          const SizedBox(height: 8),
          _BoundsRow(
            label: 'Northeast',
            lat: bounds.northeast.lat,
            lon: bounds.northeast.lon,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.zoom_in,
                size: 16,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Text(
                'Zoom: ${package.minZoom.toInt()} - ${package.maxZoom.toInt()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetadataItem(
            icon: Icons.calendar_today,
            label: 'Created',
            value: _formatDate(package.createdAt),
          ),
        ),
        Expanded(
          child: _MetadataItem(
            icon: Icons.update,
            label: 'Updated',
            value: _formatDate(package.updatedAt),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  package.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary action button
        if (package.canDownload && package.status != PackageStatus.paused)
          FilledButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          )
        else if (package.status == PackageStatus.paused)
          FilledButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
          )
        else if (package.isDownloading)
          FilledButton.tonalIcon(
            onPressed: onPause,
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
          ),

        // Retry failed button
        if (package.status == PackageStatus.partiallyComplete &&
            package.failedContentTypes.isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetryFailed,
            icon: const Icon(Icons.refresh),
            label: Text('Retry failed (${package.failedContentTypes.length})'),
          ),
        ],

        const SizedBox(height: 12),

        // Delete button
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          label: Text(
            'Delete package',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.colorScheme.error),
          ),
        ),
      ],
    );
  }

  String _getContentLabel(PackageContentType type) {
    switch (type) {
      case PackageContentType.tiles:
        return 'Map tiles';
      case PackageContentType.routing:
        return 'Routing';
      case PackageContentType.geocoding:
        return 'Address search';
      case PackageContentType.reverseGeocoding:
        return 'Location lookup';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Card showing content type status and info.
class _ContentTypeCard extends StatelessWidget {
  final PackageContentType type;
  final PackageContent content;

  const _ContentTypeCard({
    required this.type,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label) = _getTypeInfo();
    final (statusIcon, statusColor) = _getStatusInfo(theme);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          // Label and size
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content.sizeFormatted,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  _getStatusLabel(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String) _getTypeInfo() {
    switch (type) {
      case PackageContentType.tiles:
        return (Icons.map, 'Map tiles');
      case PackageContentType.routing:
        return (Icons.directions, 'Routing');
      case PackageContentType.geocoding:
        return (Icons.search, 'Address search');
      case PackageContentType.reverseGeocoding:
        return (Icons.location_on, 'Location lookup');
    }
  }

  (IconData, Color) _getStatusInfo(ThemeData theme) {
    switch (content.status) {
      case ContentStatus.notDownloaded:
        return (Icons.cloud_download_outlined, theme.colorScheme.outline);
      case ContentStatus.queued:
        return (Icons.hourglass_empty, theme.colorScheme.outline);
      case ContentStatus.downloading:
        return (Icons.downloading, theme.colorScheme.primary);
      case ContentStatus.ready:
        return (Icons.check_circle, Colors.green);
      case ContentStatus.failed:
        return (Icons.error, theme.colorScheme.error);
      case ContentStatus.updateAvailable:
        return (Icons.update, theme.colorScheme.tertiary);
    }
  }

  String _getStatusLabel() {
    switch (content.status) {
      case ContentStatus.notDownloaded:
        return 'Pending';
      case ContentStatus.queued:
        return 'Queued';
      case ContentStatus.downloading:
        return '${content.progressPercent}%';
      case ContentStatus.ready:
        return 'Ready';
      case ContentStatus.failed:
        return 'Failed';
      case ContentStatus.updateAvailable:
        return 'Update';
    }
  }
}

/// Storage info item widget.
class _StorageItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StorageItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Bounds coordinates row.
class _BoundsRow extends StatelessWidget {
  final String label;
  final double lat;
  final double lon;

  const _BoundsRow({
    required this.label,
    required this.lat,
    required this.lon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

/// Metadata item widget.
class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetadataItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

/// Data source indicator widget.
///
/// Shows whether data came from offline or online source.
class DataSourceIndicator extends StatelessWidget {
  /// Whether the data is from offline source.
  final bool isOffline;

  /// Optional label (defaults to 'Offline'/'Online').
  final String? label;

  /// Size of the indicator.
  final DataSourceIndicatorSize size;

  const DataSourceIndicator({
    super.key,
    required this.isOffline,
    this.label,
    this.size = DataSourceIndicatorSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final displayLabel = label ?? (isOffline ? 'Offline' : 'Online');
    final color = isOffline ? theme.colorScheme.tertiary : Colors.green;
    final icon = isOffline ? Icons.cloud_off : Icons.cloud_done;

    final (padding, iconSize, textStyle) = _getSizeParams(theme);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size == DataSourceIndicatorSize.small ? 4 : 8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            displayLabel,
            style: textStyle?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  (EdgeInsets, double, TextStyle?) _getSizeParams(ThemeData theme) {
    switch (size) {
      case DataSourceIndicatorSize.small:
        return (
          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          12.0,
          theme.textTheme.labelSmall,
        );
      case DataSourceIndicatorSize.medium:
        return (
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          16.0,
          theme.textTheme.labelMedium,
        );
      case DataSourceIndicatorSize.large:
        return (
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          20.0,
          theme.textTheme.labelLarge,
        );
    }
  }
}

/// Size options for DataSourceIndicator.
enum DataSourceIndicatorSize {
  small,
  medium,
  large,
}
