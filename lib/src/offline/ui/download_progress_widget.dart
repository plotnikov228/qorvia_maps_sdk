import 'package:flutter/material.dart';

import '../tiles/download_progress.dart';

/// Widget that displays download progress for an offline region.
///
/// Shows a progress bar with percentage, downloaded size,
/// and tile count information.
///
/// ## Example
///
/// ```dart
/// DownloadProgressWidget(
///   progress: downloadProgress,
///   onPause: () => manager.pauseDownload(regionId),
///   onCancel: () => manager.cancelDownload(regionId),
/// )
/// ```
class DownloadProgressWidget extends StatelessWidget {
  /// Current download progress.
  final DownloadProgress progress;

  /// Called when pause button is pressed.
  final VoidCallback? onPause;

  /// Called when cancel button is pressed.
  final VoidCallback? onCancel;

  /// Called when resume button is pressed (shown when paused).
  final VoidCallback? onResume;

  /// Whether the download is paused.
  final bool isPaused;

  /// Custom progress bar color.
  final Color? progressColor;

  /// Custom background color for progress bar.
  final Color? backgroundColor;

  /// Whether to show the cancel button.
  final bool showCancelButton;

  /// Whether to show the pause/resume button.
  final bool showPauseButton;

  /// Whether to show detailed info (tiles, size).
  final bool showDetails;

  const DownloadProgressWidget({
    super.key,
    required this.progress,
    this.onPause,
    this.onCancel,
    this.onResume,
    this.isPaused = false,
    this.progressColor,
    this.backgroundColor,
    this.showCancelButton = true,
    this.showPauseButton = true,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveProgressColor =
        progressColor ?? theme.colorScheme.primary;
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with percentage and controls
          Row(
            children: [
              // Progress percentage
              Text(
                '${progress.progressPercent}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: effectiveProgressColor,
                ),
              ),
              const Spacer(),
              // Control buttons
              if (showPauseButton) ...[
                if (isPaused)
                  IconButton(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Resume',
                    color: effectiveProgressColor,
                  )
                else
                  IconButton(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    tooltip: 'Pause',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
              if (showCancelButton)
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel',
                  color: theme.colorScheme.error,
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: effectiveBackgroundColor,
              valueColor: AlwaysStoppedAnimation(effectiveProgressColor),
              minHeight: 8,
            ),
          ),

          if (showDetails) ...[
            const SizedBox(height: 12),

            // Details row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tiles info
                _DetailChip(
                  icon: Icons.grid_view,
                  label: '${progress.completedTiles}/${progress.totalTiles}',
                  subtitle: 'tiles',
                ),
                // Size info
                _DetailChip(
                  icon: Icons.storage,
                  label: progress.sizeFormatted,
                  subtitle: 'downloaded',
                ),
                // Remaining
                _DetailChip(
                  icon: Icons.hourglass_empty,
                  label: '${progress.remainingTiles}',
                  subtitle: 'remaining',
                ),
              ],
            ),
          ],

          // Error message
          if (progress.hasError) ...[
            const SizedBox(height: 12),
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
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Compact version of download progress indicator.
///
/// Shows only the progress bar and percentage in a single line.
class CompactDownloadProgress extends StatelessWidget {
  final DownloadProgress progress;
  final Color? progressColor;

  const CompactDownloadProgress({
    super.key,
    required this.progress,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = progressColor ?? theme.colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${progress.progressPercent}%',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Stream-based download progress widget.
///
/// Automatically updates as download progresses.
class StreamDownloadProgress extends StatelessWidget {
  /// Stream of download progress updates.
  final Stream<DownloadProgress> progressStream;

  /// Initial progress (shown before first stream event).
  final DownloadProgress? initialProgress;

  /// Called when download completes.
  final VoidCallback? onComplete;

  /// Called when download fails.
  final void Function(String error)? onError;

  /// Whether to use compact mode.
  final bool compact;

  const StreamDownloadProgress({
    super.key,
    required this.progressStream,
    this.initialProgress,
    this.onComplete,
    this.onError,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DownloadProgress>(
      stream: progressStream,
      initialData: initialProgress,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          onError?.call(snapshot.error.toString());
          return _buildError(context, snapshot.error.toString());
        }

        final progress = snapshot.data;
        if (progress == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (progress.isComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onComplete?.call();
          });
        }

        if (progress.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onError?.call(progress.errorMessage ?? 'Unknown error');
          });
        }

        if (compact) {
          return CompactDownloadProgress(progress: progress);
        }

        return DownloadProgressWidget(progress: progress);
      },
    );
  }

  Widget _buildError(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
