import 'package:flutter/material.dart';

import '../package/models/offline_package.dart';
import '../package/models/package_content.dart';

/// Widget that displays a list of offline packages.
///
/// Shows package name, status, size, and available content types.
/// Supports selection, deletion, and download actions.
///
/// ## Example
///
/// ```dart
/// PackageListWidget(
///   packages: packages,
///   onPackageTap: (package) => showPackageDetails(package),
///   onDownloadTap: (package) => startDownload(package),
///   onDeleteTap: (package) => confirmDelete(package),
/// )
/// ```
class PackageListWidget extends StatelessWidget {
  /// List of packages to display.
  final List<OfflinePackage> packages;

  /// Called when a package is tapped.
  final void Function(OfflinePackage package)? onPackageTap;

  /// Called when download button is tapped.
  final void Function(OfflinePackage package)? onDownloadTap;

  /// Called when delete button is tapped.
  final void Function(OfflinePackage package)? onDeleteTap;

  /// Called when pause button is tapped.
  final void Function(OfflinePackage package)? onPauseTap;

  /// Called when resume button is tapped.
  final void Function(OfflinePackage package)? onResumeTap;

  /// Whether to show action buttons.
  final bool showActions;

  /// Empty state widget to show when list is empty.
  final Widget? emptyWidget;

  /// Custom item builder for more control.
  final Widget Function(BuildContext context, OfflinePackage package)? itemBuilder;

  const PackageListWidget({
    super.key,
    required this.packages,
    this.onPackageTap,
    this.onDownloadTap,
    this.onDeleteTap,
    this.onPauseTap,
    this.onResumeTap,
    this.showActions = true,
    this.emptyWidget,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) {
      return emptyWidget ?? _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final package = packages[index];
        if (itemBuilder != null) {
          return itemBuilder!(context, package);
        }
        return PackageListItem(
          package: package,
          onTap: onPackageTap != null ? () => onPackageTap!(package) : null,
          onDownloadTap: onDownloadTap != null ? () => onDownloadTap!(package) : null,
          onDeleteTap: onDeleteTap != null ? () => onDeleteTap!(package) : null,
          onPauseTap: onPauseTap != null ? () => onPauseTap!(package) : null,
          onResumeTap: onResumeTap != null ? () => onResumeTap!(package) : null,
          showActions: showActions,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No offline packages',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download a region to use maps offline',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single item in the package list.
class PackageListItem extends StatelessWidget {
  final OfflinePackage package;
  final VoidCallback? onTap;
  final VoidCallback? onDownloadTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onPauseTap;
  final VoidCallback? onResumeTap;
  final bool showActions;

  const PackageListItem({
    super.key,
    required this.package,
    this.onTap,
    this.onDownloadTap,
    this.onDeleteTap,
    this.onPauseTap,
    this.onResumeTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: name and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusChip(context),
                      ],
                    ),
                  ),
                  if (showActions) _buildActions(context),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar (if downloading)
              if (package.isDownloading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: package.overallProgress,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Content types row
              Row(
                children: [
                  // Content icons
                  _buildContentIcons(context),
                  const Spacer(),
                  // Size info
                  Text(
                    package.isComplete
                        ? package.totalSizeFormatted
                        : '${package.downloadedSizeFormatted} / ${package.totalSizeFormatted}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // Error message
              if (package.errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          package.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
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

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label, color) = _getStatusInfo(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String, Color) _getStatusInfo(ThemeData theme) {
    switch (package.status) {
      case PackageStatus.pending:
        return (Icons.hourglass_empty, 'Pending', theme.colorScheme.outline);
      case PackageStatus.downloading:
        return (Icons.downloading, package.progressPercentage, theme.colorScheme.primary);
      case PackageStatus.paused:
        return (Icons.pause_circle, 'Paused', theme.colorScheme.tertiary);
      case PackageStatus.completed:
        return (Icons.check_circle, 'Ready', Colors.green);
      case PackageStatus.partiallyComplete:
        return (Icons.warning, 'Partial', theme.colorScheme.tertiary);
      case PackageStatus.failed:
        return (Icons.error, 'Failed', theme.colorScheme.error);
    }
  }

  Widget _buildContentIcons(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      children: package.contentTypes.map((type) {
        final isReady = package.getContentStatus(type) == ContentStatus.ready;
        final icon = _getContentIcon(type);
        final color = isReady
            ? theme.colorScheme.primary
            : theme.colorScheme.outline;

        return Tooltip(
          message: _getContentLabel(type),
          child: Icon(icon, size: 18, color: color),
        );
      }).toList(),
    );
  }

  IconData _getContentIcon(PackageContentType type) {
    switch (type) {
      case PackageContentType.tiles:
        return Icons.map;
      case PackageContentType.routing:
        return Icons.directions;
      case PackageContentType.geocoding:
        return Icons.search;
      case PackageContentType.reverseGeocoding:
        return Icons.location_on;
    }
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

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Download/Resume button
        if (package.canDownload) ...[
          if (package.status == PackageStatus.paused)
            IconButton(
              onPressed: onResumeTap,
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Resume',
              color: theme.colorScheme.primary,
            )
          else
            IconButton(
              onPressed: onDownloadTap,
              icon: const Icon(Icons.download),
              tooltip: 'Download',
              color: theme.colorScheme.primary,
            ),
        ],

        // Pause button
        if (package.isDownloading)
          IconButton(
            onPressed: onPauseTap,
            icon: const Icon(Icons.pause),
            tooltip: 'Pause',
            color: theme.colorScheme.tertiary,
          ),

        // Delete button
        IconButton(
          onPressed: onDeleteTap,
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete',
          color: theme.colorScheme.error,
        ),
      ],
    );
  }
}

/// Compact version of package list item.
class CompactPackageListItem extends StatelessWidget {
  final OfflinePackage package;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CompactPackageListItem({
    super.key,
    required this.package,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: _buildLeadingIcon(context),
      title: Text(package.name),
      subtitle: Text(
        package.isComplete
            ? package.totalSizeFormatted
            : '${package.progressPercentage} - ${package.totalSizeFormatted}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: trailing ?? _buildStatusIcon(context),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.map,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    switch (package.status) {
      case PackageStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case PackageStatus.downloading:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            value: package.overallProgress,
            strokeWidth: 2,
          ),
        );
      case PackageStatus.paused:
        return const Icon(Icons.pause_circle_outline);
      case PackageStatus.failed:
        return Icon(Icons.error, color: Theme.of(context).colorScheme.error);
      default:
        return const Icon(Icons.cloud_download_outlined);
    }
  }
}
