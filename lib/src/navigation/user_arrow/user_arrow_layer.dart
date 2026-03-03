import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/coordinates.dart';
import '../navigation_logger.dart';
import '../navigation_options.dart';

/// Source and layer IDs for the user arrow.
const _kSourceId = 'nav-user-arrow-source';
const _kLayerId = 'nav-user-arrow-layer';
const _kAccuracySourceId = 'nav-user-accuracy-source';
const _kAccuracyLayerId = 'nav-user-accuracy-layer';
const _kCustomIconName = 'nav-user-arrow-icon';
const _kDefaultIconImage = 'triangle-11';

/// Public layer ID for the user arrow — used by other components
/// to place their layers below the arrow via MapLibre `belowLayerId`.
const kUserArrowLayerId = _kLayerId;

/// Manages user position arrow on map via GeoJSON source.
///
/// Creates and updates a GeoJSON point with rotation property
/// for the user direction arrow. Uses MapLibre symbol layer with
/// icon-rotation-alignment: map for bearing-aligned rendering.
class UserArrowLayer {
  MaplibreMapController? _mapController;
  final NavigationOptions options;

  bool _layerAdded = false;
  DateTime? _lastUpdate;
  static const _throttleMs = 16; // ~60fps for map source updates

  UserArrowLayer({required this.options});

  /// Attaches the MapLibre controller and sets up map layers.
  Future<void> attach(MaplibreMapController controller) async {
    _mapController = controller;
    await _addLayers();
    NavigationLogger.info('UserArrowLayer', 'Attached');
  }

  /// Detaches from the map controller.
  void detach() {
    _mapController = null;
    _layerAdded = false;
  }

  /// Updates the user arrow position and bearing.
  ///
  /// [position] geographic coordinates
  /// [bearing] heading in degrees (0-360)
  /// [accuracy] GPS accuracy in meters (for accuracy circle)
  Future<void> update(
    Coordinates position,
    double bearing, {
    double accuracy = 0,
  }) async {
    if (_mapController == null || !_layerAdded) return;

    // Throttle updates
    final now = DateTime.now();
    if (_lastUpdate != null &&
        now.difference(_lastUpdate!).inMilliseconds < _throttleMs) {
      return;
    }
    _lastUpdate = now;

    try {
      // Update arrow source
      final arrowGeoJson = _buildArrowGeoJson(position, bearing);
      await _mapController!.setGeoJsonSource(_kSourceId, arrowGeoJson);

      // Update accuracy circle if enabled
      if (options.showAccuracyCircle && accuracy > 5) {
        final accuracyGeoJson = _buildAccuracyGeoJson(position, accuracy);
        await _mapController!.setGeoJsonSource(
            _kAccuracySourceId, accuracyGeoJson);
      }

    } catch (e) {
      NavigationLogger.error('UserArrowLayer', 'Update failed', e);
    }
  }

  /// Removes layers from map.
  Future<void> remove() async {
    if (_mapController == null || !_layerAdded) return;

    try {
      await _mapController!.removeLayer(_kLayerId);
      await _mapController!.removeSource(_kSourceId);
      if (options.showAccuracyCircle) {
        await _mapController!.removeLayer(_kAccuracyLayerId);
        await _mapController!.removeSource(_kAccuracySourceId);
      }
      _layerAdded = false;
      NavigationLogger.info('UserArrowLayer', 'Layers removed');
    } catch (e) {
      NavigationLogger.error('UserArrowLayer', 'Remove failed', e);
    }
  }

  /// Resets state.
  void reset() {
    _lastUpdate = null;
  }

  /// Disposes resources.
  void dispose() {
    _mapController = null;
    _layerAdded = false;
  }

  // --- Private ---

  Future<void> _addLayers() async {
    if (_mapController == null) return;

    try {
      // Accuracy circle (bottom layer)
      if (options.showAccuracyCircle) {
        await _mapController!.addGeoJsonSource(
          _kAccuracySourceId,
          _buildAccuracyGeoJson(
            const Coordinates(lat: 0, lon: 0),
            0,
          ),
        );
        await _mapController!.addCircleLayer(
          _kAccuracySourceId,
          _kAccuracyLayerId,
          CircleLayerProperties(
            circleRadius: 20,
            circleColor: '#6366F1',
            circleOpacity: 0.1,
            circleStrokeColor: '#6366F1',
            circleStrokeWidth: 1,
            circleStrokeOpacity: 0.3,
          ),
        );
      }

      // Register custom arrow icon if using default icon
      String iconImageName = options.userLocationIconImage;
      if (iconImageName == _kDefaultIconImage) {
        final arrowBytes = await _generateArrowImage();
        if (arrowBytes != null) {
          await _mapController!.addImage(_kCustomIconName, arrowBytes);
          iconImageName = _kCustomIconName;
          NavigationLogger.info('UserArrowLayer', 'Custom arrow icon registered');
        }
      }

      // User arrow (top layer)
      await _mapController!.addGeoJsonSource(
        _kSourceId,
        _buildArrowGeoJson(
          const Coordinates(lat: 0, lon: 0),
          0,
        ),
      );
      await _mapController!.addSymbolLayer(
        _kSourceId,
        _kLayerId,
        SymbolLayerProperties(
          iconImage: iconImageName,
          iconSize: options.userLocationIconSize,
          iconRotate: [Expressions.get, 'bearing'],
          iconRotationAlignment: 'map',
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          iconColor: options.userLocationIconColor != null
              ? '#${options.userLocationIconColor!.value.toRadixString(16).substring(2)}'
              : null,
        ),
      );

      _layerAdded = true;
      NavigationLogger.info('UserArrowLayer', 'Layers added');
    } catch (e) {
      NavigationLogger.error('UserArrowLayer', 'Add layers failed', e);
    }
  }

  /// Generates a navigation arrow PNG image programmatically.
  ///
  /// Creates a directional arrow pointing up (north = 0°) that will be
  /// rotated by MapLibre via the `icon-rotate` property.
  Future<Uint8List?> _generateArrowImage() async {
    const scale = 2.0;
    const canvasSize = 48.0 * scale;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final fillColor = options.cursorColor ??
        options.userArrowStyle.color;
    final borderColor = options.cursorBorderColor ??
        options.userArrowStyle.borderColor;

    final centerX = canvasSize / 2;
    final centerY = canvasSize / 2;
    final arrowSize = canvasSize * 0.4;

    // Arrow path pointing up
    final path = Path()
      ..moveTo(centerX, centerY - arrowSize)
      ..lineTo(centerX - arrowSize * 0.6, centerY + arrowSize * 0.5)
      ..lineTo(centerX, centerY + arrowSize * 0.2)
      ..lineTo(centerX + arrowSize * 0.6, centerY + arrowSize * 0.5)
      ..close();

    // Shadow
    canvas.drawPath(
      path.shift(const Offset(1.5 * scale, 1.5 * scale)),
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0 * scale),
    );

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Border
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale,
    );

    // Center dot
    canvas.drawCircle(
      Offset(centerX, centerY),
      canvasSize * 0.05,
      Paint()..color = borderColor,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Map<String, dynamic> _buildArrowGeoJson(
      Coordinates position, double bearing) {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [position.lon, position.lat],
          },
          'properties': {
            'bearing': bearing,
          },
        },
      ],
    };
  }

  Map<String, dynamic> _buildAccuracyGeoJson(
      Coordinates position, double accuracy) {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [position.lon, position.lat],
          },
          'properties': {
            'accuracy': accuracy,
          },
        },
      ],
    };
  }
}
