import 'package:flutter/material.dart';

import '../../models/coordinates.dart';
import '../tiles/offline_region.dart';

/// Overlay widget for selecting a rectangular region on the map.
///
/// Shows a draggable/resizable rectangle that the user can adjust
/// to select the area they want to download for offline use.
///
/// ## Example
///
/// ```dart
/// Stack(
///   children: [
///     QorviaMapView(...),
///     RegionSelectionOverlay(
///       onBoundsChanged: (bounds) => setState(() => selectedBounds = bounds),
///       onConfirm: (bounds) => createRegion(bounds),
///       onCancel: () => setState(() => isSelecting = false),
///     ),
///   ],
/// )
/// ```
class RegionSelectionOverlay extends StatefulWidget {
  /// Called when the selected bounds change.
  final void Function(OfflineBounds bounds)? onBoundsChanged;

  /// Called when user confirms the selection.
  final void Function(OfflineBounds bounds)? onConfirm;

  /// Called when user cancels the selection.
  final VoidCallback? onCancel;

  /// Initial bounds to show.
  final OfflineBounds? initialBounds;

  /// Color of the selection rectangle border.
  final Color? borderColor;

  /// Color of the selection rectangle fill.
  final Color? fillColor;

  /// Width of the selection rectangle border.
  final double borderWidth;

  /// Minimum size of the selection in pixels.
  final double minSize;

  /// Whether to show corner resize handles.
  final bool showHandles;

  /// Whether to show the confirm/cancel buttons.
  final bool showButtons;

  /// Function to convert screen position to coordinates.
  /// Required for actual coordinate calculation.
  final Future<Coordinates?> Function(Offset screenPosition)? screenToCoordinates;

  const RegionSelectionOverlay({
    super.key,
    this.onBoundsChanged,
    this.onConfirm,
    this.onCancel,
    this.initialBounds,
    this.borderColor,
    this.fillColor,
    this.borderWidth = 2,
    this.minSize = 50,
    this.showHandles = true,
    this.showButtons = true,
    this.screenToCoordinates,
  });

  @override
  State<RegionSelectionOverlay> createState() => _RegionSelectionOverlayState();
}

class _RegionSelectionOverlayState extends State<RegionSelectionOverlay> {
  late Rect _selectionRect;

  @override
  void initState() {
    super.initState();
    // Initialize with a centered rectangle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelection();
    });
  }

  void _initializeSelection() {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    final rectSize = size.shortestSide * 0.6;

    setState(() {
      _selectionRect = Rect.fromCenter(
        center: center,
        width: rectSize,
        height: rectSize,
      );
    });

    _notifyBoundsChanged();
  }

  Future<void> _notifyBoundsChanged() async {
    if (widget.screenToCoordinates == null) return;

    final sw = await widget.screenToCoordinates!(
      Offset(_selectionRect.left, _selectionRect.bottom),
    );
    final ne = await widget.screenToCoordinates!(
      Offset(_selectionRect.right, _selectionRect.top),
    );

    if (sw != null && ne != null) {
      final bounds = OfflineBounds(southwest: sw, northeast: ne);
      widget.onBoundsChanged?.call(bounds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = widget.borderColor ?? theme.colorScheme.primary;
    final fillColor = widget.fillColor ??
        theme.colorScheme.primary.withValues(alpha: 0.1);

    return Stack(
      children: [
        // Dimmed overlay outside selection
        _DimmedOverlay(
          selectionRect: _selectionRect,
          color: Colors.black.withValues(alpha: 0.4),
        ),

        // Selection rectangle
        Positioned.fromRect(
          rect: _selectionRect,
          child: GestureDetector(
            onPanUpdate: (details) {
              _moveSelection(details.delta);
            },
            onPanEnd: (_) {
              _notifyBoundsChanged();
            },
            child: Container(
              decoration: BoxDecoration(
                color: fillColor,
                border: Border.all(
                  color: borderColor,
                  width: widget.borderWidth,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.open_with,
                  color: borderColor.withValues(alpha: 0.5),
                  size: 32,
                ),
              ),
            ),
          ),
        ),

        // Resize handles
        if (widget.showHandles) ...[
          _buildHandle(_DragHandle.topLeft, borderColor),
          _buildHandle(_DragHandle.topRight, borderColor),
          _buildHandle(_DragHandle.bottomLeft, borderColor),
          _buildHandle(_DragHandle.bottomRight, borderColor),
        ],

        // Control buttons
        if (widget.showButtons)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: _buildButtons(context, borderColor),
          ),

        // Instructions
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: _buildInstructions(context),
        ),
      ],
    );
  }

  Widget _buildHandle(_DragHandle handle, Color color) {
    const handleSize = 24.0;
    Offset position;

    switch (handle) {
      case _DragHandle.topLeft:
        position = _selectionRect.topLeft;
      case _DragHandle.topRight:
        position = _selectionRect.topRight;
      case _DragHandle.bottomLeft:
        position = _selectionRect.bottomLeft;
      case _DragHandle.bottomRight:
        position = _selectionRect.bottomRight;
    }

    return Positioned(
      left: position.dx - handleSize / 2,
      top: position.dy - handleSize / 2,
      child: GestureDetector(
        onPanUpdate: (details) => _resizeSelection(handle, details.delta),
        onPanEnd: (_) => _notifyBoundsChanged(),
        child: Container(
          width: handleSize,
          height: handleSize,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cancel button
        ElevatedButton.icon(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.close),
          label: const Text('Cancel'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(width: 16),
        // Confirm button
        ElevatedButton.icon(
          onPressed: _handleConfirm,
          icon: const Icon(Icons.check),
          label: const Text('Select Region'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Drag to move, use corners to resize',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  void _moveSelection(Offset delta) {
    setState(() {
      _selectionRect = _selectionRect.shift(delta);
    });
  }

  void _resizeSelection(_DragHandle handle, Offset delta) {
    setState(() {
      Rect newRect;

      switch (handle) {
        case _DragHandle.topLeft:
          newRect = Rect.fromLTRB(
            _selectionRect.left + delta.dx,
            _selectionRect.top + delta.dy,
            _selectionRect.right,
            _selectionRect.bottom,
          );
        case _DragHandle.topRight:
          newRect = Rect.fromLTRB(
            _selectionRect.left,
            _selectionRect.top + delta.dy,
            _selectionRect.right + delta.dx,
            _selectionRect.bottom,
          );
        case _DragHandle.bottomLeft:
          newRect = Rect.fromLTRB(
            _selectionRect.left + delta.dx,
            _selectionRect.top,
            _selectionRect.right,
            _selectionRect.bottom + delta.dy,
          );
        case _DragHandle.bottomRight:
          newRect = Rect.fromLTRB(
            _selectionRect.left,
            _selectionRect.top,
            _selectionRect.right + delta.dx,
            _selectionRect.bottom + delta.dy,
          );
      }

      // Enforce minimum size
      if (newRect.width >= widget.minSize && newRect.height >= widget.minSize) {
        _selectionRect = newRect;
      }
    });
  }

  Future<void> _handleConfirm() async {
    if (widget.screenToCoordinates == null) {
      // Return dummy bounds if no converter provided
      widget.onConfirm?.call(OfflineBounds(
        southwest: const Coordinates(lat: 0, lon: 0),
        northeast: const Coordinates(lat: 0, lon: 0),
      ));
      return;
    }

    final sw = await widget.screenToCoordinates!(
      Offset(_selectionRect.left, _selectionRect.bottom),
    );
    final ne = await widget.screenToCoordinates!(
      Offset(_selectionRect.right, _selectionRect.top),
    );

    if (sw != null && ne != null) {
      final bounds = OfflineBounds(southwest: sw, northeast: ne);
      widget.onConfirm?.call(bounds);
    }
  }
}

enum _DragHandle { topLeft, topRight, bottomLeft, bottomRight }

/// Paints a dimmed overlay outside the selection rectangle.
class _DimmedOverlay extends StatelessWidget {
  final Rect selectionRect;
  final Color color;

  const _DimmedOverlay({
    required this.selectionRect,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _DimmedOverlayPainter(
        selectionRect: selectionRect,
        color: color,
      ),
    );
  }
}

class _DimmedOverlayPainter extends CustomPainter {
  final Rect selectionRect;
  final Color color;

  _DimmedOverlayPainter({
    required this.selectionRect,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final fullRect = Offset.zero & size;

    // Draw the dimmed area using path subtraction
    final path = Path()
      ..addRect(fullRect)
      ..addRect(selectionRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DimmedOverlayPainter oldDelegate) {
    return selectionRect != oldDelegate.selectionRect ||
        color != oldDelegate.color;
  }
}

/// Simple bounds display widget.
///
/// Shows the selected bounds information.
class BoundsInfoWidget extends StatelessWidget {
  final OfflineBounds bounds;
  final double? estimatedTiles;
  final String? estimatedSize;

  const BoundsInfoWidget({
    super.key,
    required this.bounds,
    this.estimatedTiles,
    this.estimatedSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Selected Area',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildCoordRow(
            'SW',
            '${bounds.southwest.lat.toStringAsFixed(4)}, '
            '${bounds.southwest.lon.toStringAsFixed(4)}',
          ),
          _buildCoordRow(
            'NE',
            '${bounds.northeast.lat.toStringAsFixed(4)}, '
            '${bounds.northeast.lon.toStringAsFixed(4)}',
          ),
          if (estimatedTiles != null || estimatedSize != null) ...[
            const Divider(height: 16),
            if (estimatedTiles != null)
              _buildCoordRow('Tiles', '~${estimatedTiles!.toStringAsFixed(0)}'),
            if (estimatedSize != null)
              _buildCoordRow('Size', '~$estimatedSize'),
          ],
        ],
      ),
    );
  }

  Widget _buildCoordRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
