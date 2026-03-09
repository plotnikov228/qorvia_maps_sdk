import 'package:flutter/material.dart';

import '../../models/coordinates.dart';
import '../tiles/offline_region.dart';
import '../tiles/offline_tile_manager.dart';
import 'region_selection_overlay.dart';

/// Complete widget for picking and creating an offline region.
///
/// Provides a dialog or full-screen UI for:
/// - Selecting region bounds on the map
/// - Setting zoom levels
/// - Naming the region
/// - Creating and starting download
///
/// ## Example
///
/// ```dart
/// // Show as dialog
/// final region = await OfflineRegionPicker.showDialog(
///   context: context,
///   manager: offlineTileManager,
///   styleUrl: currentStyleUrl,
/// );
///
/// if (region != null) {
///   // Start downloading
///   manager.downloadRegion(region.id).listen(...);
/// }
/// ```
class OfflineRegionPicker extends StatefulWidget {
  /// Offline tile manager instance.
  final OfflineTileManager manager;

  /// Map style URL for the region.
  final String styleUrl;

  /// Initial center coordinates.
  final Coordinates? initialCenter;

  /// Initial zoom level.
  final double initialZoom;

  /// Minimum zoom level for download (default: 0).
  final double defaultMinZoom;

  /// Maximum zoom level for download (default: 16).
  final double defaultMaxZoom;

  /// Called when region is created successfully.
  final void Function(OfflineRegion region)? onRegionCreated;

  /// Called when picker is cancelled.
  final VoidCallback? onCancel;

  /// Function to convert screen position to coordinates.
  final Future<Coordinates?> Function(Offset screenPosition)? screenToCoordinates;

  /// Custom map widget builder.
  /// If null, only the selection overlay is shown.
  final Widget Function(
    BuildContext context,
    void Function(Future<Coordinates?> Function(Offset) converter) setConverter,
  )? mapBuilder;

  const OfflineRegionPicker({
    super.key,
    required this.manager,
    required this.styleUrl,
    this.initialCenter,
    this.initialZoom = 10,
    this.defaultMinZoom = 10,
    this.defaultMaxZoom = 16,
    this.onRegionCreated,
    this.onCancel,
    this.screenToCoordinates,
    this.mapBuilder,
  });

  /// Shows the region picker as a modal bottom sheet.
  static Future<OfflineRegion?> showAsBottomSheet({
    required BuildContext context,
    required OfflineTileManager manager,
    required String styleUrl,
    Coordinates? initialCenter,
    double initialZoom = 10,
  }) {
    return showModalBottomSheet<OfflineRegion>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => OfflineRegionPicker(
          manager: manager,
          styleUrl: styleUrl,
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          onRegionCreated: (region) => Navigator.pop(context, region),
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  /// Shows the region picker as a full-screen dialog.
  static Future<OfflineRegion?> showFullScreen({
    required BuildContext context,
    required OfflineTileManager manager,
    required String styleUrl,
    Coordinates? initialCenter,
    double initialZoom = 10,
  }) {
    return Navigator.of(context).push<OfflineRegion>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          body: OfflineRegionPicker(
            manager: manager,
            styleUrl: styleUrl,
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            onRegionCreated: (region) => Navigator.pop(context, region),
            onCancel: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  @override
  State<OfflineRegionPicker> createState() => _OfflineRegionPickerState();
}

class _OfflineRegionPickerState extends State<OfflineRegionPicker> {
  OfflineBounds? _selectedBounds;
  double _minZoom = 10;
  double _maxZoom = 16;
  bool _isCreating = false;
  String? _error;
  Future<Coordinates?> Function(Offset)? _screenToCoordinates;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _minZoom = widget.defaultMinZoom;
    _maxZoom = widget.defaultMaxZoom;
    _screenToCoordinates = widget.screenToCoordinates;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map area with selection overlay
        Expanded(
          child: Stack(
            children: [
              // Map (if builder provided)
              if (widget.mapBuilder != null)
                widget.mapBuilder!(
                  context,
                  (converter) => _screenToCoordinates = converter,
                ),

              // Placeholder if no map
              if (widget.mapBuilder == null)
                Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Text('Map view'),
                  ),
                ),

              // Selection overlay
              RegionSelectionOverlay(
                screenToCoordinates: _screenToCoordinates,
                onBoundsChanged: (bounds) {
                  setState(() => _selectedBounds = bounds);
                },
                onConfirm: (bounds) {
                  setState(() => _selectedBounds = bounds);
                  _showConfigSheet();
                },
                onCancel: widget.onCancel,
                showButtons: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showConfigSheet() {
    if (_selectedBounds == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ConfigSheet(
        bounds: _selectedBounds!,
        nameController: _nameController,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        isCreating: _isCreating,
        error: _error,
        onMinZoomChanged: (value) => setState(() => _minZoom = value),
        onMaxZoomChanged: (value) => setState(() => _maxZoom = value),
        onConfirm: _createRegion,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _createRegion() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a region name');
      return;
    }

    if (_selectedBounds == null) {
      setState(() => _error = 'Please select a region');
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final region = await widget.manager.createRegion(
        CreateOfflineRegionParams(
          name: name,
          bounds: _selectedBounds!,
          minZoom: _minZoom,
          maxZoom: _maxZoom,
        ),
        styleUrl: widget.styleUrl,
      );

      if (mounted) {
        Navigator.pop(context); // Close config sheet
        widget.onRegionCreated?.call(region);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCreating = false;
      });
    }
  }
}

/// Configuration sheet for region details.
class _ConfigSheet extends StatelessWidget {
  final OfflineBounds bounds;
  final TextEditingController nameController;
  final double minZoom;
  final double maxZoom;
  final bool isCreating;
  final String? error;
  final void Function(double) onMinZoomChanged;
  final void Function(double) onMaxZoomChanged;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ConfigSheet({
    required this.bounds,
    required this.nameController,
    required this.minZoom,
    required this.maxZoom,
    required this.isCreating,
    this.error,
    required this.onMinZoomChanged,
    required this.onMaxZoomChanged,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Create Offline Region',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Region name
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Region Name',
              hintText: 'e.g., Downtown Area',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label_outline),
            ),
            textCapitalization: TextCapitalization.words,
            enabled: !isCreating,
          ),
          const SizedBox(height: 20),

          // Bounds info
          BoundsInfoWidget(
            bounds: bounds,
            estimatedTiles: _estimateTileCount(),
          ),
          const SizedBox(height: 20),

          // Zoom range
          Text(
            'Zoom Levels',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ZoomSelector(
                  label: 'Min',
                  value: minZoom,
                  onChanged: isCreating ? null : onMinZoomChanged,
                  min: 0,
                  max: maxZoom,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ZoomSelector(
                  label: 'Max',
                  value: maxZoom,
                  onChanged: isCreating ? null : onMaxZoomChanged,
                  min: minZoom,
                  max: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Higher zoom levels require more storage space',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          // Error
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
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
                      error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isCreating ? null : onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isCreating ? null : onConfirm,
                  icon: isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(isCreating ? 'Creating...' : 'Create Region'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _estimateTileCount() {
    // Simple estimation based on zoom levels and bounds size
    final latDiff = (bounds.northeast.lat - bounds.southwest.lat).abs();
    final lonDiff = (bounds.northeast.lon - bounds.southwest.lon).abs();
    final area = latDiff * lonDiff;

    double totalTiles = 0;
    for (int z = minZoom.toInt(); z <= maxZoom.toInt(); z++) {
      // At each zoom level, tiles = 4^z for the whole world
      // Scale by area proportion
      final tilesAtZoom = (1 << z) * (1 << z) * area / (360 * 180);
      totalTiles += tilesAtZoom;
    }

    return totalTiles.clamp(1, 100000);
  }
}

class _ZoomSelector extends StatelessWidget {
  final String label;
  final double value;
  final void Function(double)? onChanged;
  final double min;
  final double max;

  const _ZoomSelector({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value.toInt().toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Simple dialog for quickly naming a region.
class QuickRegionNameDialog extends StatefulWidget {
  final String? suggestedName;

  const QuickRegionNameDialog({
    super.key,
    this.suggestedName,
  });

  static Future<String?> show(BuildContext context, {String? suggestedName}) {
    return showDialog<String>(
      context: context,
      builder: (context) => QuickRegionNameDialog(
        suggestedName: suggestedName,
      ),
    );
  }

  @override
  State<QuickRegionNameDialog> createState() => _QuickRegionNameDialogState();
}

class _QuickRegionNameDialogState extends State<QuickRegionNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.suggestedName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Name this region'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'e.g., Home Area',
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.words,
        onSubmitted: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _submit(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit(String value) {
    final name = value.trim();
    if (name.isNotEmpty) {
      Navigator.pop(context, name);
    }
  }
}
