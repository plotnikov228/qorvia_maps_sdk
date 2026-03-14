import 'package:flutter/material.dart';

import '../package/models/package_content.dart';
import '../package/models/package_download_progress.dart';

/// Widget that displays download progress for an offline package.
///
/// Shows overall progress, individual content type progress,
/// and provides pause/cancel controls.
///
/// ## Example
///
/// ```dart
/// PackageDownloadWidget(
///   progress: downloadProgress,
///   onPause: () => manager.pauseDownload(packageId),
///   onCancel: () => manager.cancelDownload(packageId),
///   onResume: () => manager.resumeDownload(packageId),
/// )
/// ```
class PackageDownloadWidget extends StatelessWidget {
  /// Current download progress.
  final PackageDownloadProgress progress;

  /// Called when pause button is pressed.
  final VoidCallback? onPause;

  /// Called when cancel button is pressed.
  final VoidCallback? onCancel;

  /// Called when resume button is pressed.
  final VoidCallback? onResume;

  /// Whether the download is paused.
  final bool isPaused;

  /// Whether to show content type breakdown.
  final bool showContentBreakdown;

  /// Custom title (defaults to "Downloading...").
  final String? title;

  const PackageDownloadWidget({
    super.key,
    required this.progress,
    this.onPause,
    this.onCancel,
    this.onResume,
    this.isPaused = false,
    this.showContentBreakdown = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),

          const SizedBox(height: 16),

          // Overall progress
          _buildOverallProgress(context),

          // Content breakdown
          if (showContentBreakdown && progress.contentProgress.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildContentBreakdown(context),
          ],

          // Error message
          if (progress.hasError) ...[
            const SizedBox(height: 12),
            _buildError(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Status icon
        _buildStatusIcon(context),
        const SizedBox(width: 12),
        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? _getTitle(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getSubtitle(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Control buttons
        _buildControls(context),
      ],
    );
  }

  String _getTitle() {
    if (progress.isComplete) return 'Download complete';
    if (progress.hasError) return 'Download failed';
    if (isPaused) return 'Download paused';
    return 'Downloading...';
  }

  String _getSubtitle() {
    if (progress.currentlyDownloading != null) {
      return 'Downloading ${_getContentLabel(progress.currentlyDownloading!)}';
    }
    return '${progress.completedContentCount}/${progress.totalContentCount} content types';
  }

  Widget _buildStatusIcon(BuildContext context) {
    final theme = Theme.of(context);

    if (progress.isComplete) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.green, size: 28),
      );
    }

    if (progress.hasError) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.error_outline,
          color: theme.colorScheme.error,
          size: 28,
        ),
      );
    }

    if (isPaused) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.pause,
          color: theme.colorScheme.tertiary,
          size: 28,
        ),
      );
    }

    // Downloading - show animated progress
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.overallProgress,
            strokeWidth: 4,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          Text(
            '${progress.overallPercent}%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final theme = Theme.of(context);

    if (progress.isComplete) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPaused)
          IconButton(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Resume',
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.primary,
            ),
          )
        else if (!progress.hasError)
          IconButton(
            onPressed: onPause,
            icon: const Icon(Icons.pause),
            tooltip: 'Pause',
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onCancel,
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildOverallProgress(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.overallProgress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        // Size info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              progress.downloadedSizeFormatted,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              progress.totalSizeFormatted,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentBreakdown(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...progress.contentProgress.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ContentProgressRow(
              type: entry.key,
              progress: entry.value,
              isCurrentlyDownloading: entry.key == progress.currentlyDownloading,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              progress.errorMessage ?? 'Download failed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getContentLabel(PackageContentType type) {
    switch (type) {
      case PackageContentType.tiles:
        return 'map tiles';
      case PackageContentType.routing:
        return 'routing data';
      case PackageContentType.geocoding:
        return 'address search';
      case PackageContentType.reverseGeocoding:
        return 'location lookup';
    }
  }
}

/// Row showing progress for a single content type.
class _ContentProgressRow extends StatelessWidget {
  final PackageContentType type;
  final ContentProgress progress;
  final bool isCurrentlyDownloading;

  const _ContentProgressRow({
    required this.type,
    required this.progress,
    required this.isCurrentlyDownloading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Icon
        Icon(
          _getIcon(),
          size: 18,
          color: _getIconColor(theme),
        ),
        const SizedBox(width: 8),
        // Label
        Expanded(
          child: Text(
            _getLabel(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isCurrentlyDownloading ? FontWeight.w600 : null,
            ),
          ),
        ),
        // Status
        _buildStatus(context),
      ],
    );
  }

  IconData _getIcon() {
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

  String _getLabel() {
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

  Color _getIconColor(ThemeData theme) {
    if (progress.isComplete) return Colors.green;
    if (progress.hasFailed) return theme.colorScheme.error;
    if (isCurrentlyDownloading) return theme.colorScheme.primary;
    return theme.colorScheme.outline;
  }

  Widget _buildStatus(BuildContext context) {
    final theme = Theme.of(context);

    if (progress.isComplete) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            progress.totalFormatted,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.check, size: 16, color: Colors.green),
        ],
      );
    }

    if (progress.hasFailed) {
      return Icon(
        Icons.error,
        size: 16,
        color: theme.colorScheme.error,
      );
    }

    if (isCurrentlyDownloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.progress,
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${progress.percent}%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      );
    }

    // Pending
    return Text(
      progress.totalFormatted,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.outline,
      ),
    );
  }
}

/// Compact version of package download progress.
class CompactPackageDownloadWidget extends StatelessWidget {
  final PackageDownloadProgress progress;
  final VoidCallback? onTap;

  const CompactPackageDownloadWidget({
    super.key,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Progress indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: progress.overallProgress,
                strokeWidth: 3,
                backgroundColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Downloading...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${progress.overallPercent}% - ${progress.downloadedSizeFormatted}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Stream-based package download progress widget.
class StreamPackageDownloadWidget extends StatelessWidget {
  /// Stream of download progress events.
  final Stream<PackageDownloadEvent> eventStream;

  /// Initial progress.
  final PackageDownloadProgress? initialProgress;

  /// Callbacks.
  final VoidCallback? onPause;
  final VoidCallback? onCancel;
  final VoidCallback? onResume;
  final VoidCallback? onComplete;
  final void Function(String error)? onError;

  /// Whether currently paused.
  final bool isPaused;

  const StreamPackageDownloadWidget({
    super.key,
    required this.eventStream,
    this.initialProgress,
    this.onPause,
    this.onCancel,
    this.onResume,
    this.onComplete,
    this.onError,
    this.isPaused = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PackageDownloadEvent>(
      stream: eventStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          onError?.call(snapshot.error.toString());
        }

        final event = snapshot.data;
        final progress = event?.progress ?? initialProgress;

        if (progress == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (event?.type == PackageDownloadEventType.completed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onComplete?.call();
          });
        }

        if (event?.type == PackageDownloadEventType.failed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onError?.call(progress.errorMessage ?? 'Download failed');
          });
        }

        return PackageDownloadWidget(
          progress: progress,
          onPause: onPause,
          onCancel: onCancel,
          onResume: onResume,
          isPaused: isPaused,
        );
      },
    );
  }
}
